#!/bin/bash

# This script fetches the structure of a specific HTB Academy module for Obsidian(https://obsidian.md/)
# 	and generates corresponding .md (Markdown) files for each section.
# All files  are created inside a directory which name will be the module name.
# The TEMPLATE variable is added as the initial content in each .md file.
# Dependencies: html2text,col,iconv.
# For installation dependencies: 
#	debiana -> apt install html2text util-linux libc-bin
#	arch    -> pacman -S html2text util-linux glibc
#	fedora  -> dnf install html2text util-linux glibc

TMP_FILE_PATH=$(mktemp)
ACTION="$1"

TEMPLATE="**Main tag:**\n*Specific tags:*\n\n---\n---"  #(Optional) String(markdown format) which adds all .md file(Template).

root_obs_dir=""  #(Change THIS) Root directory where must create module folder. like -> /tmp/cpts 
module_url=""    #(Change THIS) Module URL which structure to fetches.          like -> "https://academy.hackthebox.com/module/details/143".
session_key=""   #(Change THIS) htb_academy_session value which is stored under cookies when log on HTB academy.

if [ -z "$1" ] || [[ "$1" == "help" ]] || [[ "$1" == "--help" ]]|| [[ "$1" == "-h" ]]; then
    echo -e "Usage: $0 list/make\n"
	echo "[+] 'list' will only fetchs module\`s name and structure."
	echo "[+] 'make' fetchs module\`s structure and create .md files in $root_obs_dir/<module_name> directory."
    exit 1
fi
if ! [[ "$1" == "list" || "$1" == "make" ]]; then
    echo "Argument must be 'list' or 'make'."
    exit 1
fi

echo -e "\n[*] Module URL: $module_url"

status_code=$(curl -I "$module_url" -b "htb_academy_session=$session_key" -s 2>/dev/null | grep  "HTTP" | cut -d" " -f2)
if [[ "$status_code" != "200" ]]; then
	echo -e "[!] Invalid session_key or something wrong!"
	exit 1
fi

curl "$module_url" -b "htb_academy_session=$session_key" -s | html2text | col -b | iconv -f UTF-8 -t ASCII//TRANSLIT |grep "*"  |awk '/\*\*\*\* Module Sections \*\*\*\*/ {flag=1; next} /\*\*\*\* Relevant Paths \*\*\*\*/ {flag=0} flag' |sed -E 's/^\s*\*\s*//; s/\s*$//' |grep -n . |sed 's/\//-/g' |sed 's/:/. /'> "$TMP_FILE_PATH"

module_name=$(curl "$module_url" -b "htb_academy_session=$session_key" -s | html2text | col -b | iconv -f UTF-8 -t ASCII//TRANSLIT  | grep "*" | grep -E '^\*{3} .* \*{3}$' | sed "s/*//g" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]\+$//')
full_module_path="$root_obs_dir/$module_name"

if [[ "$ACTION" == "list" ]]; then
    echo -e "\nModule: $module_name\n"
    cat "$TMP_FILE_PATH"
    exit 1
fi

if [[ "$ACTION" == "make" ]]; then
	echo "[*] Module Path: \"$full_module_path\""
	if ! (ls -la "$full_module_path" 2>/dev/null 1>&2); then
        	echo -e "[*] Module Path Don\`t exists. Creating..."
        	mkdir "$full_module_path"
        	cd "$full_module_path"
        	while Iter= read -r line; do
            		md_file_path="$full_module_path/$line.md"
            		touch "$md_file_path"
            		echo -e "$TEMPLATE" > "$md_file_path"
        	done <  "$TMP_FILE_PATH"
	else
		echo -e "[*] Module Path exists. Skip!"
	fi
fi
