# ============================================================
# AD USER PERMISSIONS AUDIT SCRIPT /w RSAT module(Get-ADuser).
# Purpose: Find all user objects where target_user has permissions.
# Output: Console display + CSV file + formatted text file.
# ============================================================


$domain = "DomainName"
$target_user = "TargetUsername"

Get-ADUser -Filter * | Select-Object -ExpandProperty SamAccountName > $env:TEMP\ad_users.txt
foreach($line in [System.IO.File]::ReadLines("$env:TEMP\ad_users.txt")) {
    Write-Host "Checking permissions for user: $line" -ForegroundColor Yellow
    try {
        $user = Get-ADUser $line.Trim() -ErrorAction Stop
        $acl = Get-ACL "AD:\$($user.DistinguishedName)"
        
         $results = $acl.Access | Where-Object {
            $_.IdentityReference -match "$domain\\$target_user"
        } | Select-Object @{N='UserChecked';E={$line}}, 
                         @{N='WhoHasAccess';E={$_.IdentityReference}}, 
                         @{N='Permission';E={$_.AccessControlType}}, 
                         @{N='Rights';E={$_.ActiveDirectoryRights}}
        
        Write-Host $results
        
         if ($results) {
            Write-Host "MATCH FOUND! Writing to file..." -ForegroundColor Green
            $results | Format-Table | Out-String | Add-Content "ad_permissions_table.txt"
            $results | Export-Csv "ad_permissions_csvmatch.csv" -Append -NoTypeInformation
        } 
    } catch {
        Write-Warning "Failed to process user: $line - $($_.Exception.Message)" 
    }
}
