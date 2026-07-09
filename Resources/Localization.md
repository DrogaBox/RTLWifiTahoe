# Localization (i18n) → Crowdin

## Layout

```
Resources/
  en.lproj/Localizable.strings   ← SOURCE (English) for Crowdin
  es.lproj/Localizable.strings   ← Spanish
  <xx>.lproj/Localizable.strings ← future languages from Crowdin
Sources/
  L10n.swift                     ← typed keys + Bundle lookup
crowdin.yml                      ← Crowdin CLI config
```

## Rules

1. **Never** hardcode user-visible UI text in Swift — use `L10n.…` or `L10n.tr("key")`.
2. **Keys** are stable English identifiers (`status.nearby`), not translated phrases.
3. **Source language** for Crowdin is **en** (`en.lproj`).
4. Debug / `rtlog` messages stay English and hard-coded (not for translators).
5. After adding keys: update **both** `en.lproj` and at least `es.lproj`, then `crowdin upload sources`.

## Usage in code

```swift
Text(L10n.Tab.status)
Text(L10n.tr("join.none_in_band", bandFilter.label))
Button(L10n.App.disconnect) { … }
```

## Crowdin workflow

```bash
# Install: https://crowdin.github.io/crowdin-cli/
export CROWDIN_PROJECT_ID=…
export CROWDIN_PERSONAL_TOKEN=…

crowdin upload sources          # push en.lproj
crowdin upload translations     # optional: push existing es
# … translators work in Crowdin UI …
crowdin download                # pulls Resources/<lang>.lproj/
./scripts/build.sh              # bundles all *.lproj into the app
```

## Adding a language manually (without Crowdin yet)

```bash
mkdir -p Resources/pt.lproj
cp Resources/en.lproj/Localizable.strings Resources/pt.lproj/
# translate values, keep keys
```

## Info.plist

`CFBundleDevelopmentRegion` = `en`.  
`CFBundleLocalizations` lists supported codes (updated by `build.sh`).

## Testing a language

```bash
# Launch with Spanish
defaults write com.drogabox.rtlwifitahoe AppleLanguages -array es
open -a "RTL Wi-Fi Tahoe"
# Reset
defaults delete com.drogabox.rtlwifitahoe AppleLanguages
```
