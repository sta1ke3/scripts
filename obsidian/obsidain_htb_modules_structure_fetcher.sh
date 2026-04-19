#!/bin/bash
#
# HTB Academy Module Structure Fetcher for Obsidian
#
#
# Automatically creates organized Markdown files for HTB Academy modules
# Perfect for structured note-taking in Obsidian (https://obsidian.md/)
#
#   Debian/Ubuntu: apt install html2text util-linux libc-bin
#   Arch Linux:    pacman -S html2text util-linux glibc
#   Fedora/RHEL:   dnf install html2text util-linux glibc
#
# Example Output Structure:
#/opt/obsidian-vault/vault/SQL Injection Fundamentals/
#├── 1. Introduction.md
#├── 2. Intro to Databases.md
#├── 3. Types of Databases.md
#├── 4. Intro to MySQL.md
#├── 5. SQL Statements.md
#├── 6. Query Results.md
#├── 7. SQL Operators.md
#├── 8. Intro to SQL Injections.md
#├── 9. Subverting Query Logic.md
#├── 10. Using Comments.md
#├── 11. Union Clause.md
#├── 12. Union Injection.md
#├── 13. Database Enumeration.md
#├── 14. Reading Files.md
#├── 15. Writing Files.md
#├── 16. Mitigating SQL Injection.md
#└── 17. Skills Assessment - SQL Injection Fundamentals.md
#


TMP_FILE_PATH=$(mktemp)
ACTION="$1"

# Custom template added to every .md file (optional)
MODULE_NAME="Web Fuzzing"
TAG_NAME="HTB_module/Web_Fuzzing"
HTB_PATH="Web Penetration Tester - CWES"

TEMPLATE="---\nNote Type: HTB Module\nPath: $HTB_PATH \nModule Name: $MODULE_NAME\ntags:\n  - $TAG_NAME\n---\n---\n---\n"

# REQUIRED: Configure these variables before running
root_obs_dir="/home/kali/Desktop"  # Your Obsidian vault directory (e.g., /home/user/Obsidian/HTB)
module_number="280"    # HTB Module URL Number (e.g., https://academy.hackthebox.com/app/module/280 -> 280)
session_key=""    # Value of "htb_academy_session" Cookie

# Optional: Prefix for folder names (e.g., "17. " to include module number)
header_prefix=""

# Display help information
if [ -z "$1" ] || [[ "$1" == "help" ]] || [[ "$1" == "--help" ]]|| [[ "$1" == "-h" ]]; then
    echo -e "Usage: $0 list/make\n"
        echo "[+] 'list' will only fetchs module\`s name and structure."
        echo "[+] 'make' fetchs module\`s structure and create .md files in $root_obs_dir/<module_name> directory."
    exit 1
fi

# Validate argument
if ! [[ "$1" == "list" || "$1" == "make" ]]; then
    echo "Argument must be 'list' or 'make'."
    exit 1
fi

# Verify session key is valid
status_code=$(curl -I -L -s "https://academy.hackthebox.com/api/v3/modules/$module_number/sections" -H 'accept: application/json' -H 'referer: https://academy.hackthebox.com/'  -H "cookie: htb_academy_session=$session_key" -s 2>/dev/null | grep  "HTTP" | cut -d" " -f2)
if [[ "$status_code" != "200" ]]; then
        echo -e "[!] Invalid session_key or something wrong!"
        exit 1
fi

# Fetch and parse module structure
module_name=$(curl -s https://academy.hackthebox.com/api/v2/modules/280 -H 'accept: application/json' -H 'referer: https://academy.hackthebox.com/'  -H "cookie: htb_academy_session=$session_key" | jq -r '."data"."name"' |  tr " " "_")
mapfile -t section_name < <(curl -s "https://academy.hackthebox.com/api/v3/modules/$module_number/sections" -H 'accept: application/json' -H 'referer: https://academy.hackthebox.com/' -H "cookie: htb_academy_session=$session_key" | jq -r '.data[].sections[].title')

full_module_path="$root_obs_dir/$header_prefix$module_name"

# List mode: Display structure without creating files
if [[ "$ACTION" == "list" ]]; then
    echo -e "\n[*] Module: $module_name\n"
    itter=0
    for sec in "${section_name[@]}"; do
        ((itter++))
        echo -e "\t$itter.) $sec"
    done
    exit 1
fi

# Make mode: Create directory and markdown files
if [[ "$ACTION" == "make" ]]; then
        echo "[*] Module Path: $full_module_path"
        echo "[*] Module Name: $module_name"
        if [[ -n "$header_prefix" ]]; then
            echo -e "[*] Module w/ prefix: $header_prefix$module_name\n"
        else
            echo -e "\n"
        fi
	echo -e "[*] Template:\n$TEMPLATE\n"

        # Create directory if it doesn't exist
        if ! (ls -la "$full_module_path" 2>/dev/null 1>&2); then
                echo -e "[*] Module Path Don\`t exists. Creating..."
                mkdir "$full_module_path"
                cd "$full_module_path"
		itrrr=0
                for section_file in "${section_name[@]}"; do
        	   ((itter++))
                   md_file_path="$itter. $section_file.md"
                   touch "$md_file_path"
                   echo -e "$TEMPLATE" > "$md_file_path"
    		done
        else
                echo -e "[*] Module Path exists. Skip!"
        fi
fi
