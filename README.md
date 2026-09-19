# Shrinovva Homeophatic

A responsive Flutter clinic workspace with fictional patient data and in-memory demo state.

## Run

```sh
flutter pub get
flutter run -d chrome
```

Choose Clinic Staff or Doctor on the welcome screen. Credentials are optional for this prototype. Use the sidebar sign-out button or the mobile account menu to switch roles; state survives role changes and resets when the app restarts.

## Client web preview

The workflow in `.github/workflows/deploy.yml` builds the Flutter web app and deploys it to GitHub Pages whenever you push to `main`. You can also run **Deploy UI preview** manually from the repository's **Actions** tab.

1. In GitHub, open **Settings > Pages** and set **Build and deployment > Source** to **GitHub Actions**.
2. Commit and push the project, including the workflow, to `main`.
3. Wait for **Deploy UI preview** to finish in **Actions**, then open the deployment URL.

For the current repository, the default preview URL is https://devajsanpablo.github.io/shrinova_clinic/ . It becomes available after the first successful deployment. The workflow handles the Pages base path and uses Flutter 3.47.0, matching the development SDK. No extra deployment secrets are needed.

Clients can choose Clinic Staff or Doctor without credentials. Demo changes reset on refresh because the prototype uses in-memory data.

## UI

- Inter typography through [google_fonts](https://pub.dev/packages/google_fonts) 8.2.1.
- Short, one-shot entrances through [flutter_animate](https://pub.dev/packages/flutter_animate) 4.5.2; OS reduced-motion preferences are respected.
- A brief branded startup screen with animated dots from [flutter_spinkit](https://pub.dev/packages/flutter_spinkit) 5.2.2 fades into login and respects reduced-motion preferences.
- Original, bundled healthcare SVG illustrations rendered with [flutter_svg](https://pub.dev/packages/flutter_svg) 2.3.0.
- Responsive desktop sidebar, tablet navigation rail, and mobile navigation.
- Searchable patient directory and queue, status filters, visible primary actions, responsive patient summaries, and allergy alerts.
- Fonts and illustrations load from local assets. Google Fonts runtime downloading is disabled.

## Structure

```text
lib/
  core/       # Shared theme and session state
  data/       # Fictional patients and tickets
  models/     # Patient, visit, role and ticket models
  screens/    # Login, navigation, staff and doctor pages
  widgets/    # Reusable cards, summaries, illustrations and motion
assets/
  fonts/          # Bundled Inter font files and SIL Open Font License
  illustrations/  # Original vector artwork
test/             # Smoke and responsive layout checks
tool/             # Optional rendered preview generation
```

## Verify

```sh
flutter analyze
flutter test
flutter build web
```

Generate desktop and phone previews:

```sh
flutter test tool/render_previews_test.dart --update-goldens
```

PNG previews are written to `build/ui-previews/`.

This is a UI prototype, not a clinical record system. No backend, real authentication, or permanent storage is configured. Some settings are visual demo controls.
