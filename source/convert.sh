for file in *.v; do iconv -f gb2312 -t utf-8 "$file" -o "$file.utf8"; mv "$file.utf8" "$file"; done