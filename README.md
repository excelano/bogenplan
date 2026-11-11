# Bogenplan

Bogenplan is an iPhone and iPad calendar that shows the calendars already on the device,
read through EventKit, laid out in Bogenzeit: time read as position on the Sun's
arc, in spans from solar noon (☉) or solar midnight (○), with sunrise (△) and
sunset (▽) between. The standard, its reference implementation and its test
vectors live at https://github.com/excelano/bogenzeit. Its Linux desktop port is
[bogenplan-desktop](https://github.com/excelano/bogenplan-desktop).

A day runs from one ○ to the next and every span has the same height, so
sunrise, noon and sunset sit at fixed places and the events move with the
season. On iPad, as many days as fit sit side by side and share one gutter of
span marks, their horizons lined up. Pressing and holding the day reads any moment
on it, and holding still sets that moment as a zero-length event with an alert.
An event's start and end can be set in Bogenzeit from its details, and the system's
event editor, opened from there, changes the rest or deletes it.
`docs/concept.md` describes the design.

## What is here

The engine and the drawn glyphs come from
https://github.com/excelano/bogenzeit-swift. `Bogenplan.xcodeproj` builds the
universal app from `Bogenplan/`. `packaging/` holds the store listing, the release
notes, the privacy entry and the screenshot recipe the release apps read.

## Building

The app builds with Xcode from the project at the root, which fetches the
engine package on first build. A Debug build launched with `--demo` shows a
made-up week in Houston in place of the device's calendars and location;
`Bogenplan/Demo.swift` reads the other launch arguments.

## License

MIT. See [LICENSE](LICENSE).
