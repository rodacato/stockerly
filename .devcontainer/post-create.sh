#!/bin/bash
set -e

if [ -f "Gemfile" ]; then
  bundle install
  bin/setup --skip-server
  bin/setup-hooks
else
  gem install rails --no-document
fi
