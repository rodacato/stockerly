#!/bin/bash
set -e

# Headless Chrome for the cuprite system specs. Without it those specs fail with
# a ferrum process timeout that reads like a config problem rather than a
# missing browser.
if ! command -v chromium >/dev/null 2>&1; then
  sudo apt-get update -qq && sudo apt-get install -y -qq chromium
fi

if [ -f "Gemfile" ]; then
  bundle install
  bin/setup --skip-server
  bin/setup-hooks
else
  gem install rails --no-document
fi
