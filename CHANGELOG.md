# Changelog

All notable changes to Heltar Skills are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versioning follows [SemVer](https://semver.org/).

## [0.1.0] - Unreleased

### Added

- Initial skill set covering the public API surfaces plus the embeddable web widget:
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
  - `heltar-web-widget`
- DRY sync: each skill's `references/api-reference.md` is a symlink into the bundled `public/docs/` (most to `docs/api-reference/<entity>.md`; `heltar-web-widget` to `docs/integrations/web-widget.md`), keeping skill references locked to the docs.
- `scripts/sync-check.sh` for symlink + reference + frontmatter validation.
