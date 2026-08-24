# Monitor Profiles (Display)

This is a second, separate Omarchy plugin bundled inside the
[Monitor Profiles](../README.md) repo, not a subdirectory of it as far as
Omarchy's plugin system is concerned.

## Why a separate plugin instead of one plugin with two kinds

The natural first attempt is one plugin declaring both `"panel"` and
`"bar-widget"` in `kinds`. That builds and runs, but Omarchy's shell
(`shell.qml`, `isBarWidgetPanelPlugin`) deliberately routes every
toggle/summon/hide for a plugin that's *also* a panel/overlay/menu kind to
the panel, never the bar widget:

```js
// Plugins that are also panel/overlay/menu kinds are owned by the
// panel loader (e.g. omarchy.menu); let that path handle them.
```

`SUPER+CTRL+D` is bound to `omarchy-shell shell toggle omarchy.monitor`.
With one dual-kind plugin, that keybind (and clicking the bar icon through
the same summon path) ends up opening the full switcher/editor instead of
the Display-style dropdown — confirmed live, not theoretical. Being a
genuinely separate plugin id, with only `"bar-widget"` in its own `kinds`,
is what makes the routing land correctly.

## How it gets installed

Nobody runs `omarchy plugin add` on this subfolder directly. The main
plugin's setup banner ("Take over the Display widget", optional) copies
this folder into its own real plugin directory —
`~/.config/omarchy/plugins/dev.shantzware.monitor-profiles-display/` —
and enables it from there, the same way `omarchy plugin clone` copies a
built-in plugin into an editable one. See `Panel.qml`'s
`wireUpDisplayTakeover()` in the parent repo.

## What's in here

- `manifest.json` — `kinds: ["bar-widget"]` only, with
  `"omarchy": {"clonedFrom": "omarchy.monitor"}`. That field is the actual
  mechanism (same one `omarchy plugin clone` itself writes) that makes
  enabling this plugin replace Display's slot in the bar rather than add a
  second icon next to it.
- `BarWidget.qml` — built from a real `omarchy plugin clone omarchy.monitor`
  clone of Display's own source. Only the "Displays" list (enable/disable
  a connected monitor) was replaced, with a "Monitor Profiles" list plus a
  trailing "Edit Profiles…" row that opens the parent plugin's full editor
  (`Quickshell.execDetached`, then closes this dropdown). Brightness/
  text-size/scale sections, and all their process/IPC plumbing, are
  untouched Display source.
- `DisplayModel.js` — Display's own `Model.js`, copied verbatim and
  renamed (imported here as `Model`) so it doesn't collide with this
  plugin's own `Model.js` below (imported as `ProfileModel`).
- `Model.js` — a copy of the parent repo's `Model.js` (profile parsing,
  Lua generation, the same `isValidProfileName`/safety helpers). A literal
  copy, not a shared reference: `omarchy-plugin-validate` refuses symlinks
  inside a plugin folder, and this file has to exist inside *this* plugin's
  own installed directory regardless of where the parent plugin ends up.
  `test/model-copy-sync.test.js` in the parent repo fails the moment the
  two drift, so keep them identical by hand.
