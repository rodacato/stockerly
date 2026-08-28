# Non-secret environment Kamal needs to render config/deploy.yml locally.
# Real secrets never live here: a deploy runs in GitHub Actions, which injects
# them from the "production" GitHub Environment.

: "${STOCKERLY_ROOT:=$(git rev-parse --show-toplevel 2>/dev/null)}"
[ -n "${STOCKERLY_ROOT:-}" ] || return 0 2>/dev/null || exit 0

if [ -z "${GITHUB_REPOSITORY:-}" ]; then
  _kamal_slug="$(git -C "$STOCKERLY_ROOT" config --get remote.origin.url 2>/dev/null |
    sed -E 's#^(git@[^:]+:|https?://[^/]+/)##; s#\.git$##')"
  [ -n "$_kamal_slug" ] && export GITHUB_REPOSITORY="$_kamal_slug"
  unset _kamal_slug
fi

[ -z "${GITHUB_ACTOR:-}" ] && [ -n "${GITHUB_REPOSITORY:-}" ] &&
  export GITHUB_ACTOR="${GITHUB_REPOSITORY%%/*}"

if [ -r "$STOCKERLY_ROOT/.devcontainer/local.env" ]; then
  set -a
  . "$STOCKERLY_ROOT/.devcontainer/local.env"
  set +a
fi
