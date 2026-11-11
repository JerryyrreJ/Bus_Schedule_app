# Widget countdown layout verification

Countdowns in widgets use `CountdownFormatter.widgetString`: `9m`, `59m`,
`1h45m`, `10h02m`. Positive waits round up to a minute; waits below a minute use
`<1m`. The `h` suffix keeps durations distinguishable from departure clock times.
The app's detailed second formatter is unchanged.

- Home widgets retain a large departure time. The caption yields to the countdown
  when space is tight. Small-widget follow-up times stay on one line; their
  redundant caption can disappear. Medium secondary cards show departure times
  without a second competing countdown.
- Rectangular lock widgets show route, departure time, then a compact countdown.
- Inline widgets show route and countdown; they omit the redundant clock time.
- Watch rectangles use the full width for the countdown, with departure time in
  the header. Circular complications put hours and minutes on separate lines.
- Corner complications use only the compact countdown in the system's curved
  label; this still needs inspection in a real WidgetKit watch-face host.

## Automated format checks

```sh
cd BusScheduleCore
swift test
```

The tests check transition boundaries and every second from 1 through 86,400.
They verify a six-character maximum for positive waits within a day, no ambiguous
clock-style colon, and rounding that never understates the remaining time.
These tests do not claim to prove visual layout or system-specific clipping.

## Reusable visual cases

`WidgetLayoutPreview` defines 11 shared cases: now, under one minute, 1, 9, 10,
59 minutes, 1h, 1h45m, 9h59m, 10h02m, and 23h59m. Synthetic waits are DEBUG-only;
Release builds contain neither injected countdowns nor the fixture factory.

In Xcode, open `CountdownBoundaryPreviews.swift` for iPhone widgets or the
`Watch*Previews.swift` files for Watch. Each **Countdown boundaries** preview has
a timeline containing all 11 cases. Existing loop, last-bus, and service-ended
previews remain available. Select a compact iPhone and a 40 mm Watch first,
then check a larger device, both languages, and light/dark or vibrant rendering.
A separate preview for every minute is unnecessary.

Check complete digits and units, no ellipsis, no wrapped clock times, and no
collision with a circle or card boundary. SwiftUI ImageRenderer sheets can
batch-check the content at fixed sizes, but do not reproduce the system's
curved corner label, tinting, or WidgetKit margins. Finish those checks in
Xcode/Device Hub with the real widget host.

## Build checks

From the repository root:

```sh
xcodebuild -project Bus_Schedule.xcodeproj -scheme Bus_Schedule \
  -configuration Debug -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/WidgetLayoutCheck CODE_SIGNING_ALLOWED=NO build
```

The app scheme also builds the embedded Watch app and its widget extension.
Use the destination instead of overriding `-sdk` globally: the graph contains
both iOS and watchOS targets. Repeat with `-configuration Release` to verify that
preview fixtures cannot leak into the production configuration.
