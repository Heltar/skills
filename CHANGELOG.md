# Changelog

All notable changes to Heltar Skills are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versioning follows [SemVer](https://semver.org/).

## [0.1.0] - Unreleased

### Added

- Initial skill set covering all 11 public API surfaces:
  - `heltar-authentication`
  - `heltar-messaging`
  - `heltar-templates`
  - `heltar-campaigns`
  - `heltar-chatbots`
  - `heltar-webhooks`
  - `heltar-contacts`
  - `heltar-calls`
  - `heltar-groups`
  - `heltar-code-editor`
  - `heltar-schedule`
- DRY sync: each skill's `references/api-reference.md` is a symlink to `../../../../docs/api-reference/<entity>.md` (internal to the bundled `public/` repo), keeping skill references locked to the docs.
- `scripts/sync-check.sh` for symlink + reference + frontmatter validation.
