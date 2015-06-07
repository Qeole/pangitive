#!/bin/sh

articles_dir=`git config --get pangitive.articles-dir`
pages_dir=`git config --get pangitive.pages-dir`

article_exists="0"
for f in "$articles_dir"/* "$pages_dir"/*; do
  if [ "$f" = "$articles_dir"'/*' ]; then continue; fi
  if [ "$f" = "$pages_dir"'/*' ]; then break; fi
  ts=`git log --format="%at" -- "$f" | tail -1`
  if [ "$ts" != "" ]; then
    article_exists="1"
    break
  fi
done
non_tracked=`git status --porcelain | grep -E '^(A|R)' | grep "$articles_dir\|$pages_dir"`

if [ "$article_exists" = "0" -a "$non_tracked" = "" ]; then
  echo -n "[fugitive] ERROR: need at least one article (you can use " >&2
  echo '`git commit --no-verify` to bypass), aborting.' >&2
  exit 1
fi
