#!/bin/bash

set -xe

echo "Storage before clean:"
df -h

rm -rf ~/.cache/pipenv/http
rm -rf ~/.cache/yarn

sudo pacman -Sc --noconfirm

echo "Storage after clean:"
df -h
