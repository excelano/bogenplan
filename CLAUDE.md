# CLAUDE.md

Bogenplan is an iPhone and iPad calendar that shows the calendars on the device, read through EventKit, laid
out in Bogenzeit. `docs/concept.md` is the concept; the Bogenzeit spec in excelano/bogenzeit is
normative. The engine, the display forms and the drawn glyphs come from the Swift package
excelano/bogenzeit-swift, depended on by URL; a change to any of them is made there and released
as a new tag. The only events Bogenplan creates are moments, zero-length events with an alert at
their start, set from the day column; it does not edit or delete events.

## Commands

    xcremote build      # the app for the iPhone simulator
    xcremote phone      # onto David's iPhone, as ~/notes/shipping.md says

`ship.toml` (gitignored) carries the API key xcremote signs with. Signing is automatic; the app
uses no capabilities, so nothing is registered by hand in the developer portal.

The app icons (light, dark, tinted) are drawn in `Icon/AppIcon.svg`, `Icon/AppIcon-dark.svg` and
`Icon/AppIcon-tinted.svg`; change one there and render it into
`Bogenplan/Assets.xcassets/AppIcon.appiconset/` with
`rsvg-convert -w 1024 -h 1024 <svg> | magick - -alpha off -strip PNG24:<png>`.

## Rules

The day view gives every span the same height, from the starting ○ to the ending ○ (spec §3.8),
and falls back to an even ○-to-○ axis on a polar day. Displayed positions are the floor of the
signed value. ☉, ○, △ and ▽ in anything rendered are drawn from `BogenzeitUI`, never from a font,
so no glyph characters in UI strings. Calendar data and the location stay on the device; no
network. Don't commit, push or publish unless David asks.
