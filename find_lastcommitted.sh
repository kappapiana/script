find . -path ./.git -prune -o -name '[a-z|A-Z]*'  > /tmp/files
while read p; do git log -n 1 --pretty=format:%H --  ; echo   ; done < /tmp/files
