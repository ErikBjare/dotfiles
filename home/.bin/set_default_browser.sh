#!/bin/bash

BROWSER="firefox.desktop"

MIMES="
text/html
application/pdf
x-scheme-handler/http
x-scheme-handler/https
x-scheme-handler/about
"


for mime in $MIMES; do
    echo "Setting $BROWSER for $mime"
    xdg-mime default $BROWSER $mime
done
