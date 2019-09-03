#!/usr/bin/env bash

if ! [ -x "$(command -v chef)" ]; then
  echo 'Installing Chef...'
  curl -L https://www.opscode.com/chef/install.sh | sudo bash
fi

(
  cd cookbooks/newbox
  berks vendor ..
)

sudo chef-client -z -o newbox
