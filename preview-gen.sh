#!/bin/sh
# vim:set cc=80 ts=2 sw=2 et:
added_files=`git status --porcelain | grep -E '^ ?A' | \
  cut -f2`
modified_files=`git status --porcelain | grep -E '^ ?M' | \
  cut -f2`
deleted_files=`git status --porcelain | grep -E '^ ?D' | \
  cut -f2`
if [ "$1" != "-a" -a "$1" != "--all" ]; then
  preview="true"
fi

