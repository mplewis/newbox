#!/usr/bin/env bash

if ! [ -x "$(command -v chef)" ]; then
  sudo gem install berkshelf
fi

cd cookbooks/newbox || return
berks install
berks vendor ..
