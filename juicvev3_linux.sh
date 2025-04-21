#!/bin/sh
echo -ne '\033c\033]0;newthingyfor juice\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/juicvev3_linux.x86_64" "$@"
