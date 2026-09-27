# Patient storage

`patient_database.dart` saves patient registrations to the Firestore `patients`
collection and loads them after staff or doctor sign-in. New document IDs are reserved
using a Firestore transaction on `counters/patients`: `PT-01`, `PT-02`, and so on.
Existing IDs are retained. Interrupted registrations can leave gaps; retries within
the same form reuse their reserved ID. Never reset the counter in a populated database.
The model in `../model/patient.dart` contains the registration fields
and serialization. Dates are stored as ISO 8601 strings; consent uses a server
timestamp. Symptoms belong to the optional consultation ticket.

Vaccination status supports Yes, No, and Unknown. Yes requires vaccine names.
Laboratory images are stored as byte blobs in `patients/{id}/labAttachments/{index}`,
with filenames in the patient document. A batch commits both the patient and images
atomically. Images are loaded only when opened in the profile; patient lists do not
download their bytes. Registration accepts five images of up to 750,000 bytes each.
The picker resizes images to at most 2,000 pixels wide at 85% quality where supported;
staff should check legibility in the preview. Camera capture is available on mobile,
and depends on browser/device support on web. Desktop supports choosing image files.

Publish the root `firestore.rules` in the Firebase console before using this
flow. The signed-in account must have a `staff/{uid}` or `doctor/{uid}` profile
matching the selected workspace. Doctor profiles are provisioned by an
administrator; login never creates or upgrades a profile. Patient reads and
registration writes are restricted to those accounts.

If sign-in succeeds but loading patients returns `permission-denied`, check the
Firebase project identified by `project_info.project_id` in
`android/app/google-services.json`. In that project's **Firestore Database**:

1. Publish the root `firestore.rules` under **Rules**. Local rule edits do not
   change the deployed rules.
2. Under **Data**, confirm the account has a document at
   `staff/{uid}` or `doctor/{uid}`, using the exact UID from **Authentication > Users** as the
   document ID. An administrator can create the document with `uid` (string),
   `email` (string), and `createdAt` (timestamp).
3. Retry sign-in. Creating an Authentication user in the console does not create
   the staff document, and the app's `signIn` method does not provision it.

These are Cloud Firestore rules and documents, not Realtime Database rules or
data. If both checks pass, verify the active deployed rules and any enforced
App Check configuration before changing access permissions.

The live app starts without sample patients or tickets. Tests explicitly inject
sample data and a fake database. Consultation tickets are persisted separately by
`ticket_database.dart`.
