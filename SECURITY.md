# Security Policy

## Reporting a vulnerability

Please report suspected vulnerabilities privately through GitHub Security Advisories at https://github.com/excelano/bogenplan/security/advisories/new. If you would rather not use GitHub, email david.anderson@excelano.com instead. I aim to respond within seven days.

Please do not open public issues for security problems.

## Supported versions

The latest release receives fixes. A security fix ships through `main` in a new release on GitHub and, where the app is listed on the App Store, through it; there are no maintained release branches.

## Security model

**Bogenplan has no network surface.** The app makes no network request, opens no socket and links no networking or analytics code.

**Calendars are read, never written.** With permission, the app reads the device's calendars through EventKit while it is on screen. It keeps no copy of an event and cannot create, change or delete one.

**Location is read only with permission and only while the app is on screen.** The coordinates in use are kept on the device; withdrawing the permission discards them.

**What it keeps stays on your device.** The app's own preferences hold the coordinates in use, the identifiers of hidden calendars and the display settings. Removing the app removes them.
