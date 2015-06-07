#!/bin/sh

blog_url=`git config --get pangitive.blog-url`
if [ "$blog_url" = "" ]; then
  echo -n "[pangitive] ERROR: git config pangitive.blog-url is empty and" >&2
  echo -n " should not be, please set it with " >&2
  echo -n '`git config pangitive.blog-url "<url>"` ' >&2
  echo "on the remote repository, aborting." >&2
  exit 1
fi
