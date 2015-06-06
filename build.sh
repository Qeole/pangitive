#!/bin/bash

include_file() {
  f=`echo -n $2 | sed 's#\/#\\\\\/#g'`
  tmp=`mktemp pangitiveXXXXXX`
  cat "$2" | gzip | base64 > "$tmp"
  cat "$1" | sed "/#INCLUDE:$f#/ {
    r $tmp
    d
    }"
  rm "$tmp"
}

cp install.sh pangitive_tmp1
i=1
for f in README.md *-*.sh default-files/*; do
  j=$((1 - i))
  include_file pangitive_tmp$i "$f" > pangitive_tmp$j
  i=$j
done
cp pangitive_tmp$j pangitive
chmod +x pangitive
rm pangitive_tmp0 pangitive_tmp1
