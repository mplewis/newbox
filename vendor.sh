#!/usr/bin/env bash

cd cookbooks/newbox || return
berks install
berks vendor ..
