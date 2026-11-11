# Bogenplan — concept

Bogenplan is a calendar for iPhone and iPad that shows the calendars the person already keeps,
read through EventKit, in Bogenzeit: positions in spans or kiloseconds from solar noon
(☉) and solar midnight (○), with sunrise (△) and sunset (▽) between. Apple Calendar
is a good calendar and a useful point of comparison, but Bogenplan is not a copy of
it. Once the axis is the Sun instead of the clock, how a day is presented is open,
and that is where the app can be inventive.

The standard is defined in excelano/bogenzeit (`docs/bogenzeit-spec.md`, normative).
Nothing here redefines it; where this document and the spec disagree, the spec wins.

## What it does

Bogenplan shows the events in the calendars on the device, lets the person move
between days, jump to today, choose which calendars are shown, and open an event to
see its details with its civil times. The one event it makes itself is a moment. In an
event's details, tapping its start or end opens a sheet that sets either by typing a
reading or a step at a time in Bogenzeit, as a moment is set, with the Bogenzeit day
chosen beside it to move the event to the same reading on another day, or in civil
time; moving the start
keeps the event's length, and the end cannot go before the start. Edit Details opens the
system's event editor, where everything else about the event is changed or the event
is deleted. For a repeating event both ask whether the change is for this occurrence
or for the ones after it. Bogenplan does not answer invitations.

The Linux desktop app also opens iCalendar files, so it can be the desktop's
calendar application and take the invitations a mail client hands it. The file's
events are shown in Bogenzeit and added to a calendar the person chooses, each as
the person's own copy without its organizer and attendees, so the server sends
nothing and the invitation stays unanswered. An event already in a calendar with
the same UID is replaced, and a cancellation removes it.

## Moments

Pressing and holding an empty part of a day draws a line across it with the reading
at that point, and the civil time beside it when civil time is shown; sliding moves
the line, and letting go removes it. This is also the converter between the clock
and Bogenzeit. A quarter of a second's hold separates it from a scroll or a swipe
between days: movement before then scrolls, movement after it moves the line.

Holding still for another half second turns the line gold with a firmer tap, and
letting go then opens a sheet to set the moment precisely, by typing a reading (a
number, before or after, and ○, △, ☉ or ▽) or a step at a time at the scale and
precision in Settings, or in civil time. Adding it saves a zero-length
event to the default calendar for new events with an alert at its start. The alert
is the calendar's own, so it reaches every device that has the calendar, the watch
included, and needs nothing from Bogenplan afterwards. The instant is computed once,
for where the person is when setting it, and rounded up to the whole second so that
a calendar that drops fractions cannot show it a step early. Its default title is the
reading in words, since a calendar shows titles in a font and the glyphs are drawn
only in the app.

## The day on the arc

A clock-time day view gives every hour the same height, so daylight is a band that
grows and shrinks with the season and drifts against the grid. This view gives every
span the same height instead. A Bogenzeit day runs from one ○ to the next and holds
400 spans: 100 from ○ to sunrise, 200 across the Tagbogen, 100 from sunset to ○
(spec §3.8, "place in the day"). Daylight therefore always fills the middle half of
the column, sunrise and sunset sit at fixed heights, and ☉ is always at the center.
What moves with the seasons is the events: in Houston a 17:00 meeting sits in the
middle of the afternoon in June and just before sunset in December.

Events come from EventKit in civil time and are placed by computing their place in
the day at the person's location. An event's height is the spans it covers, so an
hour of daylight is taller in winter than in summer, and an hour of night the
reverse. Civil times stay available, on the event and optionally along the edge,
because the people the person meets keep clock time.

The Bogenzeit date changes at solar midnight, not at civil midnight (spec §5.1). The
view pages by Bogenzeit day, so an event at 00:30 can belong to the previous day's
column.

On a polar day or polar night there are no spans (spec §3.5). The axis falls back to
kiloseconds from ○, a day of about 86.4 ks laid out evenly.

At an even height per span a short event at high latitude would be a sliver, so
the column scrolls and pinches to zoom, out as far as the whole day fitting the
screen, and every event is drawn at least a minimum height. All-day events sit in a strip
above the column. An event that crosses ○ is drawn in each day for the part of it
that falls there. The edge of the column carries span marks, and civil times
appear on the events when Show civil time is on in Settings.

## Platform and data

iPhone and iPad from the same SwiftUI views. The iPhone shows one day; the iPad
shows as many days as fit side by side, sharing one gutter of span marks, since
every day puts sunrise, ☉ and sunset at the same heights, with each day's clock
times for sunrise and sunset in its header. Swift and SwiftUI; the project file
names the minimum iOS version. Reading events needs full access
(`requestFullAccessToEvents`, `NSCalendarsFullAccessUsageDescription`); write-only
access cannot read the day.

Location is the other input. Bogenplan asks for approximate location only
(`NSLocationDefaultAccuracyReduced`), reads it while the app is open, and keeps the
coordinates on the device, since the error of an approximate location moves solar
noon and sunrise by tens of seconds at most, well under a span. There is one place,
the latest fix, and every day, future ones included, is drawn at it. Without the
permission the app explains what it needs instead of drawing a day, and withdrawing
the permission discards the stored coordinates.

The privacy posture follows the other Excelano apps: no backend, no analytics, no
third-party SDKs, no network at all. Calendar data stays in EventKit and the location
stays on the device. The privacy entry on excelano.com/legal and an App Privacy of
"Data Not Collected" follow from that.

## Building blocks

The engine is the Swift package excelano/bogenzeit-swift, depended on by URL; the
project file names the version range. `Bogenzeit` gives `Reading` (an instant's position,
anchor, eighth and offset), `SolarDay` (noon, sunrise, sunset, the midnights,
twilights), `Reading.placeInDay` (the 0 to 400 axis above), `SolarDuration` (spans
and kiloseconds between two instants), and the display forms `DisplayedPosition`,
`Scale` and `Precision`. `BogenzeitUI` draws ☉, ○, △ and ▽ from one SwiftUI
definition; the glyphs are drawn, never set from a font, because no font draws the
two anchors at matching sizes. Anything the calendar needs that is a property of the
standard (a new computation, a new form) goes into the spec and the Python reference
first, then the package, so every app agrees.

Bogentag, whose face spec is in excelano/bogentag, is the reference for how
Bogenzeit looks on Apple platforms.

Releases go through the apps in excelano/shipping, from a gitignored `ship.toml`;
development builds go through `xcremote` from the Debian box to the Mac. The bundle
identifier and anything else stored outside the app are persisted identifiers and do
not change.
