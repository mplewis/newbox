#!/usr/bin/env bash

if ! [ -x "$(command -v chef)" ]; then
  echo 'Installing Chef...'
  curl -L https://www.opscode.com/chef/install.sh | sudo bash
  sudo gem install berkshelf

  (
    cd cookbooks/newbox || return
    berks vendor ..
  )
fi

sudo chef-client -z -o newbox
