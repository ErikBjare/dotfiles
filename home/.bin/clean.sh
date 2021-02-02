#!/bin/bash

set -xe

echo "Storage before clean:"
df -h || true

rm -rf ~/.cache/pipenv/http
rm -rf ~/.cache/yarn

pushd ~/Downloads
DOWNLOADS_SIZE=$(ls-by-size | head -1 | cut -f 1)
echo "Size of ~/Downloads: $DOWNLOADS_SIZE"
popd

# Redundant since also done by `yay -Scc`
#sudo pacman -Sc --noconfirm

yay -Scc

echo "Storage after clean:"
df -h
