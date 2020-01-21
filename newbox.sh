#!/usr/bin/env bash

if ! [ -x "$(command -v chef)" ]; then
  echo 'Installing Chef...'
  curl -L https://www.opscode.com/chef/install.sh | sudo bash
  ./vendor.sh
fi

export SUDO_ASKPASS="$(which ssh-askpass)"
sudo chef-client -z -o newbox --config config.rb
