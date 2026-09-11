# NaijaMove Rider App

Flutter implementation of the rider UI specified in [`../rider_app_prompt.md`](../rider_app_prompt.md)
(11 flows, 48 screens). UI-complete with mock data and a simulated trip state machine; the
backend in [`../server`](../server) plugs in behind the repositories later.

## Run

```bash
flutter pub get
flutter run                                   # starts at Splash
flutter run --dart-define=START_ROUTE=/home    # jump straight to a screen (signed-in session)
flutter test                                  # widget tests for the main flows
```

`START_ROUTE` accepts any path from `lib/app/routes.dart` — handy for demos and screenshots.

## Structure

```
lib/
  main.dart                 ProviderScope + START_ROUTE bootstrap
  app/
    app.dart                MaterialApp.router, light/dark theme, theme mode
    router.dart             go_router config (4-tab StatefulShellRoute + root routes)
    routes.dart             every path constant — referenced, never retyped
    shell.dart              bottom navigation: Home · Trips · Wallet · Profile
    state/app_state.dart    Riverpod notifiers: session, ride draft, active trip, rating, case draft
    theme/app_colors.dart   THE colour palette (light + dark tokens) — the only place a hex lives
    theme/app_theme.dart    typography (bundled Inter), radii, spacing, ThemeData
  core/
    utils/format.dart       ₦ formatting, dates, relative times
    widgets/                buttons, inputs, chips, badges, sheet, toast, skeleton, star rating,
                            map_canvas (stylised Lagos map — Mapbox stand-in), brand mark
  data/
    models.dart             enums mirror the server schema (vehicle_category, trip_status, …)
    mock_data.dart          the spec's "Sample Data" table
  features/
    onboarding/  splash, carousel, phone, OTP, profile setup           (Flow 1)
    home/        home map, destination search                          (Flow 2)
    ride/        ride options, confirm, schedule, negotiate            (Flows 2, 8)
    trip/        searching → matched → arriving → arrived → in progress → SOS → completed, cancelled (Flow 3)
    wallet/      wallet & payment methods, top up, transactions, add card (Flow 4)
    trips/       trip history, receipt                                 (Flow 5)
    profile/     profile, saved places, emergency contacts, promos, notifications, WhatsApp (Flows 6, 7, 9)
    rating/      post-trip rating, tip, confirmation, pending card, driver profile, my rating, report (Flow 10)
    support/     help home, category, form, submitted, my cases, case chat, resolved, driver chat, FAQ (Flow 11)
```

## Conventions

- **Colours**: import `app/theme/app_theme.dart` and use `AppColors.*` for brand tokens or the
  theme-aware `context.bg / surface / border / textPrimary / textSecondary / tint` accessors.
  No `Color(0x…)` or `Colors.<name>` outside `app_colors.dart` (white/black/transparent excepted).
- **Fonts**: Inter is bundled under `assets/fonts` (SIL OFL) — works offline, no runtime download.
- **Map**: `MapCanvas` takes normalised `Offset(0..1)` positions for pins/route/drivers. Replace its
  internals with `mapbox_maps_flutter` when keys are available; callers don't change.
- **State**: prototype flows are driven by `activeTripProvider` (timers simulate matching and
  progress). Swap the notifier bodies for WebSocket events from `/ws/trip/:id/rider`.

## Not yet wired

Real auth/OTP, Mapbox, Paystack, push notifications, deep links, localisation.
