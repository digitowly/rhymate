# Rhymate

Rhymate is a Swift-based app for songwriters and lyricists. It helps you organize lyrics, find rhymes and synonyms, and enhance your writing.

### Features

- Organize and manage your lyrics in dedicated projects
- Instantly find rhymes, synonyms, and related words
- Save and access your favorite rhymes for quick reference
- View detailed Wiktionary definitions and word information
- Seamlessly sync across iOS, iPadOS, and macOS devices

### Supported Platforms

| Platform | Status       |
| -------- | ------------ |
| iOS      | ✅ Supported |
| iPadOS   | ✅ Supported |
| macOS    | ✅ Supported |

### Screenshots

Screenshots are generated with [fastlane snapshot](https://docs.fastlane.tools/actions/snapshot/) and require [Bundler](https://bundler.io/) (`gem install bundler`).

**App Store screenshots** — light and dark mode, captured for iPhone 16 Pro Max and iPad Pro 13-inch:

```sh
bundle exec fastlane screenshots
```

Output lands in `fastlane/screenshots/light/` and `fastlane/screenshots/dark/`.

**Visual regression screenshots** — covers every major app flow for manual review:

```sh
bundle exec fastlane test_screenshots
```

Output lands in `fastlane/test_screenshots/`.
