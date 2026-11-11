# Security Policy

## Reporting a vulnerability

Please report suspected vulnerabilities privately, using the **Report a vulnerability** button on the Security tab of this repository. If that button is not there, or you would rather not go through GitHub, email david.anderson@excelano.com instead. I aim to respond within seven days.

Please do not open public issues for security problems.

## Supported versions

The latest release receives security fixes. Older versions are not supported. A fix ships in a new App Store release.

## What Bogenplan can access

Bogenplan makes no network request, opens no socket and links no networking or analytics code.

With permission, it reads the device's calendars through EventKit while it is on screen, and keeps no copy of an event. It creates an event only when you set a moment, and changes or deletes one only when you save or delete it in its details or in the system's event editor.

It reads approximate location only with permission and only while the app is on screen. Withdrawing the permission discards the stored coordinates.

## What Bogenplan stores

The app's own preferences hold the coordinates in use, the identifiers of hidden calendars and the display settings, on the device. Removing the app removes them.
