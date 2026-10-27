ARG RUBY_VERSION=4.0.9
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

# Vulnerability scanners for code-vulns. Versions and SHA-256 are pinned here, not read from the
# release: a checksum file published next to a compromised binary vouches for it. Bump both together.
ARG TRIVY_VERSION=0.75.0
ARG TRIVY_SHA256_AMD64=c6e65abddb348e25f10549df887045629cf28cc72453cd1c63acb717316b3f3f
ARG TRIVY_SHA256_ARM64=a1ee9f6ffb7d112b64ff726a2a0717c21175c1114361391f4a132956751a13b3
ARG OSV_SCANNER_VERSION=2.7.0
ARG OSV_SCANNER_SHA256_AMD64=160c6253e2922e9e0a6a9771c5c4c40a4b3c6090b34a3cdd5e80c96cc2e4218b
ARG OSV_SCANNER_SHA256_ARM64=4061ef4c021ed3c47f203b818f337e351336cc5cd67c0274fc36bd1dfc728dd7
RUN set -eu; \
    case "$(dpkg --print-architecture)" in \
      amd64) trivy_arch=64bit; osv_arch=amd64; trivy_sha="$TRIVY_SHA256_AMD64"; osv_sha="$OSV_SCANNER_SHA256_AMD64" ;; \
      arm64) trivy_arch=ARM64; osv_arch=arm64; trivy_sha="$TRIVY_SHA256_ARM64"; osv_sha="$OSV_SCANNER_SHA256_ARM64" ;; \
      *) echo "unsupported architecture" >&2; exit 1 ;; \
    esac; \
    cd /tmp; \
    curl -fsSLo trivy.tar.gz "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-${trivy_arch}.tar.gz"; \
    echo "${trivy_sha}  trivy.tar.gz" | sha256sum -c -; \
    tar -xzf trivy.tar.gz trivy && install -m 0755 trivy /usr/local/bin/trivy; \
    curl -fsSLo osv-scanner "https://github.com/google/osv-scanner/releases/download/v${OSV_SCANNER_VERSION}/osv-scanner_linux_${osv_arch}"; \
    echo "${osv_sha}  osv-scanner" | sha256sum -c -; \
    install -m 0755 osv-scanner /usr/local/bin/osv-scanner; \
    rm -f trivy trivy.tar.gz osv-scanner
USER vscode

ENV LANG=C.UTF-8
