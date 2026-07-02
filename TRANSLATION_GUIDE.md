# Translation Guide

Open Recorder currently localizes two user-facing surfaces:

- the native macOS app
- the Next.js landing page

English remains the source language. Simplified Chinese (`zh-Hans` / `zh-CN`) is the first localized version.

## macOS App

macOS localization files live in:

```text
apps/macos/Resources/<locale>.lproj/
```

For Simplified Chinese:

- `apps/macos/Resources/zh-Hans.lproj/Localizable.strings`
- `apps/macos/Resources/zh-Hans.lproj/InfoPlist.strings`

The packaging script copies every `apps/macos/Resources/*.lproj` directory into the final `.app/Contents/Resources` folder. Keep `CFBundleLocalizations` in `apps/macos/Resources/Info.plist` aligned with the bundled locales.

Most simple SwiftUI literals such as `Text("Settings")`, `Button("Cancel")`, and `Label("Export Video", systemImage: ...)` resolve through `Localizable.strings` when the packaged app runs under a matching system language. UI text that is passed through variables should use `L10n.string(...)` before display.

## Landing Page

The English landing page is:

```text
apps/landing/src/app/page.tsx
```

The Simplified Chinese landing page is:

```text
apps/landing/src/app/zh-cn/page.tsx
```

Both pages should keep the same sections, proof points, workflow steps, and calls to action unless a locale-specific change is intentional.

## Validation

Validate macOS string files:

```bash
plutil -lint apps/macos/Resources/zh-Hans.lproj/Localizable.strings apps/macos/Resources/zh-Hans.lproj/InfoPlist.strings
```

Validate the native app:

```bash
make test-macos
```

Validate the landing page:

```bash
pnpm --dir apps/landing lint
pnpm --dir apps/landing build
```

## Contributor Rules

- Keep English keys stable in `.strings` files.
- Prefer exact English UI text as the localization key.
- Use `%@` and `%d` placeholders for formatted Swift strings.
- Do not translate file names, device names, project titles, paths, or user-entered text.
- If a SwiftUI string comes from a variable and should be localized, wrap it with `L10n.string(...)`.
