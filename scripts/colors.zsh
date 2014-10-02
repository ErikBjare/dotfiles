#!/usr/bin/zsh


for COLOR in $(seq 0 255)
do
    LINE=""
    for STYLE in "38;5"
    do
        TAG="\033[${STYLE};${COLOR}m"
        STR="${STYLE};${COLOR}"
        LINE="${LINE}${TAG}${STR}${NONE}  "
    done
        echo -ne "${LINE}"
    echo
done
