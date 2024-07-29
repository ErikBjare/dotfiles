#!/bin/bash

set -e  # exit on error
#set -x  # print commands

# get current free space on /
FREE_SPACE=$(df / | tail -1 | awk '{print $4}')
FREE_SPACE_H=$(numfmt --to=iec $((1000 * $FREE_SPACE)))
echo "Storage before clean: $FREE_SPACE_H"

echo
echo "Checking size of commonly large folders:"
pushd ~/Downloads > /dev/null
DOWNLOADS_SIZE=$(ls-by-size | head -1 | cut -f 1)
echo -e "\nSize of ~/Downloads: $DOWNLOADS_SIZE"
popd > /dev/null

echo
echo "Cleaning select folders in ~/.cache"
rm -rf ~/.cache/pip/http*
rm -rf ~/.cache/pip/wheels
rm -rf ~/.cache/pipenv/http
rm -rf ~/.cache/pypoetry/artifacts
rm -rf ~/.cache/pypoetry/*cache
rm -rf ~/.cache/yarn
rm -rf ~/.cargo/registry

# if we have yay
if command -v yay; then
  echo -e "\n# Yay found! Cleaning pacman cache"
  yay -Scc --noconfirm
fi

# if we have docker, clean up dangling images
if (command -v docker > /dev/null); then
  echo -e "\n# Docker found!"

  echo -e "## Dangling images:"
  docker images -f dangling=true | true

  echo ""
  read -p "Do you want to prune dangling images? (y/N): " -n 1 -r
  echo ""

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "# Pruning dangling images"
    docker image prune -f | true
  fi
fi

# get current free space and calculate how much was freed
FREE_SPACE_AFTER=$(df / | tail -1 | awk '{print $4}')
FREE_SPACE_AFTER_H=$(numfmt --to=iec $((1000 * $FREE_SPACE_AFTER)))
FREED_SPACE=$(($FREE_SPACE_AFTER - $FREE_SPACE))
FREED_SPACE_H=$(numfmt --to=iec $((1000 * $FREED_SPACE)))

echo
echo "Free space after clean: $FREE_SPACE_AFTER_H"

# if zero or negative, print no freed space
if [ $FREED_SPACE -le 0 ]; then
    echo "No space was freed"
else
    echo "Freed space: $FREED_SPACE_H"
fi
