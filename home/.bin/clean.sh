#!/bin/bash

set -xe

echo "Storage before clean:"
df -h || true

rm -rf ~/.cache/pip/http
rm -rf ~/.cache/pip/wheels
rm -rf ~/.cache/pipenv/http
rm -rf ~/.cache/pypoetry/artifacts
rm -rf ~/.cache/yarn
rm -rf ~/.cargo/registry

pushd ~/Downloads
DOWNLOADS_SIZE=$(ls-by-size | head -1 | cut -f 1)
echo "Size of ~/Downloads: $DOWNLOADS_SIZE"
popd

# Redundant since also done by `yay -Scc`
#sudo pacman -Sc --noconfirm

yay -Scc

echo "Storage after clean:"
df -h
