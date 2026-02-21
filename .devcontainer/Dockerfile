ARG RUBY_VERSION=3.3.6
FROM ghcr.io/rails/devcontainer/images/ruby:${RUBY_VERSION}

USER root
RUN apt-get update && apt-get install -y \
    git \
    curl \
    neovim \
    ripgrep \
    fd-find \
    && rm -rf /var/lib/apt/lists/*
USER vscode

ENV LANG=C.UTF-8
