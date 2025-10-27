#!/bin/bash

# HTB Academy Module Structure Fetcher for Obsidian
#
# Automatically creates organized Markdown files for HTB Academy modules
# Perfect for structured note-taking in Obsidian (https://obsidian.md/)
#
# Dependencies: html2text, col, iconv
#
# Installation:
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
TEMPLATE="**Main tag:** #main_tag\n*Specific tags:* #spec_tag\n\n---\n---"

# REQUIRED: Configure these variables before running
root_obs_dir=""  # Your Obsidian vault directory (e.g., /home/user/Obsidian/HTB)
module_url=""    # HTB module URL (e.g., https://academy.hackthebox.com/module/details/143)
session_key=""   # Your htb_academy_session cookie value from browser

# Optional: Prefix for folder names (e.g., "17.) " to include module number)
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

echo -e "\n[*] Module URL: $module_url"

# Verify session key is valid
status_code=$(curl -I "$module_url" -b "htb_academy_session=$session_key" -s 2>/dev/null | grep  "HTTP" | cut -d" " -f2)
if [[ "$status_code" != "200" ]]; then
        echo -e "[!] Invalid session_key or something wrong!"
        exit 1
fi

# Fetch and parse module structure
curl "$module_url" -b "htb_academy_session=$session_key" -s | html2text | col -b | iconv -f UTF-8 -t ASCII//TRANSLIT |grep "*"  |awk '/\*\*\*\* Module Sections \*\*\*\*/ {flag=1; next} /\*\*\*\* Relevant Paths \*\*\*\*/ {flag=0} flag' |sed -E 's/^\s*\*\s*//; s/\s*$//' |grep -n . |sed 's/\//-/g' |sed 's/:/. /'> "$TMP_FILE_PATH"      

# Extract module name
module_name=$(curl "$module_url" -b "htb_academy_session=$session_key" -s | html2text | col -b | iconv -f UTF-8 -t ASCII//TRANSLIT  | grep "*" | grep -E '^\*{3} .* \*{3}$' | sed "s/*//g" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]\+$//')
full_module_path="$root_obs_dir/$header_prefix$module_name"

# List mode: Display structure without creating files
if [[ "$ACTION" == "list" ]]; then
    echo -e "\nModule: $module_name\n"
    cat "$TMP_FILE_PATH"
    exit 1
fi

# Make mode: Create directory and markdown files
if [[ "$ACTION" == "make" ]]; then
        echo "[*] Module Path: $full_module_path"
        echo "[*] Module Name: $module_name"
        if [[ -n "header_prfix" ]]; then
            echo -e "[*] Module w/ prefix: $header_prefix$module_name\n"
        else
            echo -e "\n"
        fi

        # Create directory if it doesn't exist
        if ! (ls -la "$full_module_path" 2>/dev/null 1>&2); then
                echo -e "[*] Module Path Don\`t exists. Creating..."
                mkdir "$full_module_path"
                cd "$full_module_path"
                # Create .md file for each section
                while Iter= read -r line; do
                        md_file_path="$line.md"
                        touch "$md_file_path"
                        echo -e "$TEMPLATE" > "$md_file_path"
                done <  "$TMP_FILE_PATH"
        else
                echo -e "[*] Module Path exists. Skip!"
        fi
fi
