#!/bin/bash

IFS=$'\n'

git_files="$(git ls-files)"

for line in $(ls -l); do
    file=${line:40}
    echo $file
    #echo $git_files | grep -- "$file" && echo "in git"
done;
