# Doctor ticket notifications

Staff choose a username loaded from `doctor`; the document ID must be the
doctor's Firebase Authentication UID. Profiles without a nonempty `username`
are excluded. Tickets store both `doctor` (username) and `doctorUid`.

Creating a ticket with `status: sent` invokes `notifyDoctorOnTicket`. Drafts
do not notify. Each sent ticket creates one persistent inbox document at
`doctor/{uid}/notifications/{ticketId}` and sends a generic FCM alert to that
doctor's registered devices. Patient details are not included in push payloads.
The inbox works even when push permission is denied or no device is registered.

Android supports foreground, background, and terminated-app push notifications.
The doctor must sign in to the updated app and allow notification permission.
Tapping a notification opens the inbox after doctor sign-in; tapping an inbox
item refreshes and opens the assigned queue. Settings can disable push alerts
on this installation. Sign-out removes the device registration and FCM token.
Web and desktop currently support the live inbox only; iOS push needs separate
APNs configuration and client setup.

Dependencies: `firebase_messaging`, `flutter_local_notifications`, and
`shared_preferences` (the per-account, per-installation push preference).

The function uses a dedicated `clinic-notifications` codebase to preserve
existing admin functions. Deploy with:

```
firebase deploy --only functions:clinic-notifications:notifyDoctorOnTicket,firestore:rules --project clinic-86788
```

Inbox IDs are idempotent. Completed push attempts are skipped on retries, invalid
tokens are removed, and transient delivery failures are retried. FCM and
Firestore triggers provide at-least-once delivery, so duplicate push delivery
is still possible after a crash or simultaneous trigger retry; Android uses a
stable notification tag to replace the same ticket's background notification.

Validation: Flutter ticket/registration/responsive tests, backend tests in
`functions/test/notifications.test.js`, and Firestore emulator checks in
`tool/test_ticket_rules.mjs`. A real end-to-end delivery check requires a doctor
signed in with permission enabled and a staff user sending a new ticket.
