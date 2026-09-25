# Screen ownership

Group screens by the roles that can reach them in the current UI:

| Folder | Screens |
| --- | --- |
| `doctor/` | Consultation |
| `staff/` | No exclusive screens yet |
| `shared/` | Startup, login, app shell, dashboard, queue, patient directory, patient profile, registration, ticket form, notifications and settings |

The doctor dashboard opens the patient directory through the recent-patients action. The directory opens registration, and patient profiles open ticket creation, so these screens are shared even though staff have more direct navigation to them. Doctor sign-in is not implemented yet; this organization reflects the existing doctor workspace routes.

Place a new screen in `staff/` or `doctor/` only when it is exclusive to that role. Use `shared/` when both roles use it, including screens with role-specific content. Folder placement does not enforce permissions.
