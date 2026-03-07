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

Stockerly reaches `v1.0.0` when:
- Deployed to production with real users
- Database schema is stable (migrations are additive, not destructive)
- All 6 bounded contexts are battle-tested
- SSL end-to-end is configured
- Backup and recovery strategy is verified

## Release Process

### 1. Prepare the release

```bash
# Ensure all tests pass
bundle exec rspec

# Ensure no linting issues
bin/rubocop

# Run security checks
bin/ci
```

### 2. Bump the version

Update `lib/stockerly/version.rb` with the new version:

```ruby
module Stockerly
  VERSION = "0.2.0-alpha"
end
```

This version is used by Honeybadger to track releases in error reporting.

### 3. Update CHANGELOG.md

Move entries from `[Unreleased]` to the new version section. The `[Unreleased]` section
must be empty (or removed) — this ensures the changelog is always up to date before tagging.

```markdown
## [Unreleased]

## [0.2.0-alpha] - 2026-XX-XX

### Added
- ...
```

Update the comparison links at the bottom of the file:

```markdown
[Unreleased]: https://github.com/rodacato/stockerly/compare/v0.2.0-alpha...HEAD
[0.2.0-alpha]: https://github.com/rodacato/stockerly/compare/v0.1.0-alpha...v0.2.0-alpha
[0.1.0-alpha]: https://github.com/rodacato/stockerly/releases/tag/v0.1.0-alpha
```

### 4. Commit the release

```bash
git add lib/stockerly/version.rb CHANGELOG.md
git commit -m "Bump version to v0.2.0-alpha"
```

### 5. Create the tag

```bash
git tag -a v0.2.0-alpha -m "Release v0.2.0-alpha"
```

### 6. Push

```bash
git push origin master --tags
```

### 7. Create GitHub Release

```bash
gh release create v0.2.0-alpha \
  --title "v0.2.0-alpha" \
  --notes-file - <<'EOF'
## Highlights

- Feature 1
- Feature 2

See [CHANGELOG.md](CHANGELOG.md) for the full list of changes.
EOF
```

Or use the GitHub web UI: **Releases > Draft a new release > Choose the tag**.

## Release Cadence

There is no fixed schedule. Releases happen when a meaningful set of changes is ready:

- **Alpha releases** (`0.x.0-alpha`): after completing a roadmap phase or a set of related features
- **Patch releases** (`0.x.Y`): for urgent bug fixes or security patches
- **Major milestones**: aligned with the [ROADMAP.md](ROADMAP.md)

## Mapping Roadmap Phases to Versions

| Version | Roadmap Phases | Theme |
|---------|---------------|-------|
| `v0.1.0-alpha` | 0-22 | All core features: DDD architecture, trading, alerts, market data, AI intelligence |
| `v0.2.0-alpha` | TBD | Next phase |

## Hotfix Process

For critical bugs or security issues on a released version:

1. Create a branch from the tag: `git checkout -b hotfix/description v0.1.0-alpha`
2. Fix the issue with tests
3. Update CHANGELOG.md under the new patch version
4. Tag and release: `v0.1.1-alpha`
5. Cherry-pick or merge back to `master`

## Docker Images

Each release should have a corresponding Docker image tagged in GitHub Container Registry:

```
ghcr.io/rodacato/stockerly:v0.1.0-alpha
ghcr.io/rodacato/stockerly:latest
```

The CI/CD pipeline handles image building and pushing on deploy.
