#!/bin/bash
set -e

if [ -f "Gemfile" ]; then
  bundle install
  bin/setup --skip-server
else
  gem install rails --no-document
fi
