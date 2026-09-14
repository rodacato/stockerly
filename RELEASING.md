# Releasing Stockerly

## Versioning

Stockerly follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html):

```
MAJOR.MINOR.PATCH[-pre-release]
```

| Component | When to bump |
|-----------|-------------|
| **MAJOR** | Breaking changes to the database schema, API, or core architecture |
| **MINOR** | New features, bounded contexts, or integrations |
| **PATCH** | Bug fixes, performance improvements, dependency updates |

### Pre-release Tags

| Tag | Meaning |
|-----|---------|
| `alpha` | Feature-complete for the phase, but not production-hardened |
| `beta` | Production-tested, collecting feedback |
| `rc.N` | Release candidate, no known issues |

Examples: `v0.1.0-alpha`, `v0.2.0-beta`, `v1.0.0-rc.1`, `v1.0.0`

### What counts as 1.0.0?

Stockerly is a self-hosted single-user tracker ([ADR-0010](docs/architecture/adr/0010-pivot-to-self-hosted-single-user-tracker.md)),
so "real users" is not the bar. It reaches `v1.0.0` when:
- Running in production as the maintainer's daily driver
- A third party can clone, stand it up, and load their first asset without a manual
- Database schema is stable (migrations are additive, not destructive)
- All 6 bounded contexts are battle-tested
- SSL end-to-end is configured
- Backup and recovery strategy is verified

## Release Process

A release is an annotated tag on a commit that is already on `master`. Releasing and deploying are
independent: tagging does not deploy, and deploying does not tag ([docs/ops/deploy.md](docs/ops/deploy.md)).

### 1. Open the release PR

On a branch from `master`, bump `lib/stockerly/version.rb`:

```ruby
module Stockerly
  VERSION = "0.2.0-alpha"
end
```

Error tracking runs inside the instance ([ADR-020](docs/architecture/adr/0020-internal-error-tracker.md)):
unhandled exceptions land in `error_events` and are read at `/admin/errors`. There is no external
error service and no release marker to publish. `lib/stockerly/version.rb` is the human-facing
version used for tags and the changelog.

In `CHANGELOG.md`, rename `## [Unreleased]` to `## [0.2.0-alpha] - YYYY-MM-DD`, add a new empty
`## [Unreleased]` above it, and update the comparison links at the bottom:

```markdown
[Unreleased]: https://github.com/rodacato/stockerly/compare/v0.2.0-alpha...HEAD
[0.2.0-alpha]: https://github.com/rodacato/stockerly/compare/v0.1.0-rc1...v0.2.0-alpha
```

The PR runs the same required checks as any other change. Merge it.

### 2. Tag the merged commit

```bash
git fetch origin
sha=$(git rev-parse origin/master)   # or the merge commit of the release PR
git merge-base --is-ancestor "$sha" origin/master && git tag -a v0.2.0-alpha "$sha" -m "Release v0.2.0-alpha"
```

### 3. Publish the tag, and only the tag

```bash
git push origin v0.2.0-alpha
```

Never `git push origin master --tags`: it pushes to the protected branch and publishes every local
tag at once.

### 4. Create the GitHub Release

Every `v*` tag has one. The notes are the version's section of the changelog:

```bash
v=0.2.0-alpha
awk -v h="## [$v]" 'index($0, h) == 1 { f = 1; next } f && /^## \[/ { exit } f' CHANGELOG.md > /tmp/notes.md
gh release create "v$v" --verify-tag --title "v$v" --notes-file /tmp/notes.md --prerelease
```

Drop `--prerelease` for a version without a pre-release suffix.

## Release Cadence

There is no fixed schedule. Releases happen when a meaningful set of changes is ready:

- **Alpha releases** (`0.x.0-alpha`): after completing a roadmap phase or a set of related features
- **Patch releases** (`0.x.Y`): for urgent bug fixes or security patches
- **Major milestones**: when the scope of a major version is done. Product history is summarized in [docs/1.0-retrospective.md](docs/1.0-retrospective.md).

## Mapping Roadmap Phases to Versions

| Version | Roadmap Phases | Theme |
|---------|---------------|-------|
| `v0.1.0-alpha` | 0-22 | All core features: DDD architecture, trading, alerts, market data |
| `v0.1.0-rc1` | — | Hardening for public deployment (current `lib/stockerly/version.rb`) |
| `v0.2.0` | — | The 2.0 pivot: self-hosted single-user tracker (see the `[Unreleased]` section of the changelog) |

## Hotfix Process

A hotfix is a normal change on `master`: a PR with the fix and its tests, then a patch release from
step 1. There are no branches cut from a tag, and no tag on a commit that is not on `master`. To put
the fix in production, promote `master` as [docs/ops/deploy.md](docs/ops/deploy.md) describes.

## Tags that are not releases

Only `v*` tags are releases. A tag that marks a point in history, such as `pre-2.0-evolve`, has no
GitHub Release and no changelog section.

## Docker Images

Releases do not produce images. `kamal deploy` builds and pushes the production image to
`ghcr.io/<owner>/stockerly`, tagged with the deployed commit's SHA and with `latest`, which is
whatever was deployed last, not the latest release. There is no `:vX.Y.Z` image.
