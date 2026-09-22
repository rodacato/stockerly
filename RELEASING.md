# Releasing Stockerly

## Versioning

Stockerly follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html):

```
MAJOR.MINOR.PATCH
```

| Component | When to bump |
|-----------|-------------|
| **MAJOR** | Breaking changes to the database schema, API, or core architecture |
| **MINOR** | New features, bounded contexts, or integrations |
| **PATCH** | Bug fixes, performance improvements, dependency updates |

### Pre-release suffixes are retired

`v0.1.0-alpha` and `v0.1.0-rc1` were cut by hand. The Release workflow offers `patch`, `minor`
and `major` and nothing else, so a version it produces never carries a suffix — `0.1.0-rc1`
released as `0.2.0`, not as `0.2.0-beta`.

The publish step still honours one: a version written into the manifest with a `-suffix` is
published as a GitHub pre-release. Nothing in the flow puts one there.

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

Releases are cut by [`.github/workflows/release.yml`](.github/workflows/release.yml) from a
dispatch. No step below tags by hand or pushes to `master`, and releasing is still independent of
deploying: tagging does not deploy, and deploying does not tag ([docs/ops/deploy.md](docs/ops/deploy.md)).

### 1. Run the Release workflow

From the Actions tab, pick the bump (`patch`, `minor` or `major`). It bumps
`lib/stockerly/version.rb`, generates the `CHANGELOG.md` entry from the commits since the last
`v*` tag, and pushes a `release/vX.Y.Z` branch.

### 2. Open the pull request yourself

From the link in the run summary. The workflow stops short of opening it: letting Actions open
pull requests needs a repository setting that also lets it *approve* them, and a token-authored
pull request runs no CI — opening it by hand is what gives the release branch its five required
checks.

### 3. Read the entry on the branch before merging

The generator reads [Conventional Commits](https://www.conventionalcommits.org/) and nothing else.
Two things to check, both fixed on the branch rather than after publication:

- **Breaking Changes** only holds commits written as `type!:`. A missed marker belongs there by
  hand.
- The run summary lists every commit the entry does not carry — a subject with no prefix, or a
  `design:` commit, whose history is its flow's `Log` frame and [design/DECISIONS.md](design/DECISIONS.md).
  Paste what belongs in the entry.

`script/release_changelog.rb <bump> --dry-run` prints the same entry locally and writes nothing.

### 4. Merge it

That push to `master` carries a version with no tag yet, which is what makes the workflow create
`vX.Y.Z` and publish the GitHub Release with that changelog section as its notes. The suite is not
re-run: `master` only takes pull requests whose required checks passed on a branch that was up to
date with it.

### If the publish step fails

The tag is pushed before the release is created, so a failure can leave a tag with no release.
Nothing is lost — the notes come from a section that is already on `master`:

```bash
v=0.2.0
awk -v h="## [$v]" 'index($0, h) == 1 { f = 1; next } f && /^## \[/ { exit } f' CHANGELOG.md > /tmp/notes.md
gh release create "v$v" --verify-tag --title "v$v" --notes-file /tmp/notes.md
```

If the tag itself is missing, re-running the workflow is not the path — it dispatches `prepare`,
not `publish`. Tag the commit that is already on `master` and push only the tag:

```bash
git fetch origin
git tag -a "v$v" origin/master -m "Stockerly v$v"
git push origin "refs/tags/v$v"
```

Never `git push origin master --tags`: it pushes to the protected branch and publishes every local
tag at once.


## Release Cadence

There is no fixed schedule. Releases happen when a meaningful set of changes is ready:

- **Minor releases** (`0.X.0`): after a set of related features, or a slice of the redesign
- **Patch releases** (`0.x.Y`): for urgent bug fixes or security patches
- **Major milestones**: when the scope of a major version is done. The 2.0 pivot is recorded in [ADR-0010](docs/architecture/adr/0010-pivot-to-self-hosted-single-user-tracker.md).

## Mapping Roadmap Phases to Versions

| Version | Roadmap Phases | Theme |
|---------|---------------|-------|
| `v0.1.0-alpha` | 0-22 | All core features: DDD architecture, trading, alerts, market data |
| `v0.1.0-rc1` | — | Hardening for public deployment |
| `v0.2.0` | — | The 2.0 pivot: self-hosted single-user tracker (see the `[Unreleased]` section of the changelog) |

`lib/stockerly/version.rb` is the manifest: it is what the workflow bumps, what `publish` reads to
decide whether there is a tag to cut, and what `/admin/settings` reports.

## Hotfix Process

A hotfix is a normal change on `master`: a PR with the fix and its tests, then a patch release from
step 1. There are no branches cut from a tag, and no tag on a commit that is not on `master`. To put
the fix in production, promote `master` as [docs/ops/deploy.md](docs/ops/deploy.md) describes.

## Tags that are not releases

Only `v*` tags are releases. A tag that marks a point in history, such as `pre-2.0-evolve`, has no
GitHub Release and no changelog section — and the generator asks for `--match 'v*'` so a marker tag
can never become the boundary the changelog range is read from.

`v0.1.0-alpha` is an exception to fix rather than a rule to follow: it has a tag but no GitHub
Release, and it does not hang off `master` at all, having survived a history rewrite of the
pre-2.0 era.

## Docker Images

Releases do not produce images. `kamal deploy` builds and pushes the production image to
`ghcr.io/<owner>/stockerly`, tagged with the deployed commit's SHA and with `latest`, which is
whatever was deployed last, not the latest release. There is no `:vX.Y.Z` image.
