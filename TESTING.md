# Running the Swift tests

On a Mac with Xcode 16 or newer (Swift 6):

```sh
swift test --package-path BusScheduleCore --enable-code-coverage
```

The tests use isolated UserDefaults suites, a fake notification service and explicit
Gregorian/Hong Kong calendars for the new date regressions. They do not access the
real App Group container, request notification permission, or contact a paired Watch.

The Swift tests workflow also builds the iOS app and extensions with the runner's
Xcode. Building the current UI requires Xcode 26 or newer.

Important behavior covered by the regressions:

- Complication timelines renew at their last entry and include departure, loop-start,
  loop-end and midnight boundaries.
- A manual day-type override expires at midnight; tomorrow's first bus uses the
  automatic day type.
- Reminder scheduling rechecks time after every asynchronous system operation.
  Replacing a reminder preserves the previous request when authorization or add fails.
  Cancellation and overlapping operations cannot leave extra pending reminders.
- Incoming preference messages preserve revision ordering even after expiration;
  changing override expiration invalidates widget timelines.

System delivery of notifications and WidgetKit's actual refresh scheduling still
require a simulator/device check; tests verify the requests and timelines we submit.
