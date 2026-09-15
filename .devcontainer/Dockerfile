ARG RUBY_VERSION=4.0.6
FROM ghcr.io/rails/devcontainer/images/ruby:${RUBY_VERSION}

USER root
# chromium: headless browser for the cuprite system specs.
RUN apt-get update && apt-get install -y \
    chromium \
    neovim \
    ripgrep \
    fd-find \
    && rm -rf /var/lib/apt/lists/*
# Debian ships fd as fdfind; give it the name every doc and muscle memory uses.
RUN ln -sf "$(which fdfind)" /usr/local/bin/fd
USER vscode

ENV LANG=C.UTF-8
