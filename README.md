# AppLocalizer

macOS app (SwiftUI, macOS 27+) for localizing apps faster through the App Store Connect API:

- **Subscription pricing:** per-territory prices for every subscription, from one base price.
- **Store page:** the App Store listing's text in every locale.

It works with a team API key. The design brief for the full feature set is in `DESIGN_PROMPT.md`.

## Connecting an API key

1. In App Store Connect, open **Users and Access → Integrations → App Store Connect API → Team Keys**.
2. Generate a key with the **Admin** or **App Manager** role. Prices and metadata can't be edited with less.
3. In the app, enter the **Issuer ID** and **Key ID**, then drop in the downloaded `AuthKey_<KEYID>.p8`. The Key ID fills itself in from the file name.

"Connect" signs one `GET /v1/apps?limit=1` before saving anything. The key is stored as one generic-password item in the login Keychain (`KeychainCredentialsStore`). Every request carries a freshly signed ES256 JWT (`AppStoreConnectJWT`), so the `.p8` itself never leaves the Mac. Remove the key in Settings → Account.

## Architecture

It follows Bruma's patterns (`~/Projects/ios/Bruma`).

- **Folders:**
  - `SupportFiles/`: the app entry point and assets.
  - `Managers/`: shared services: the App Store Connect client, the credentials store and `AppSession`.
  - `Models/`: shared models.
  - `Screens/<Feature>/`: the view and view model, plus `Model/` (pure logic and the services protocol), `Services/` (live implementations) and `Components/`.
  - `DesignSystem/`: tokens (`Palette`) and shared components.
  - `Debug/`: DEBUG-only scenes and fakes.
- **One top-level type per file.** Extensions go in `Type+Topic.swift`.
- **State:** `@MainActor @Observable final class` view models with `private(set)` state.
  - Each feature talks to the outside world through a `@MainActor protocol <Feature>Services` with a `Live…` implementation. Tests and DEBUG scenes swap in fakes.
  - Views have two inits: a live one, and `init(viewModel:)` for previews and DEBUG scenes.
- **API client:** `AppStoreConnectClient` builds URLs, signs requests, maps HTTP errors (`AppStoreConnectError`) and follows `links.next` pagination. Each resource's endpoints go in their own extension, e.g. `AppStoreConnectClient+Apps.swift`. Requests go through `HTTPTransport`, so unit tests never reach Apple.
- **Swift 6** language mode, strict concurrency, nonisolated by default (like Bruma).

### DEBUG scenes

In a Debug build, launch with `-AppLocalizerDebugScene <id>` to open one state with canned data. A scene never contacts App Store Connect or the Keychain. The scenes:

- `connect`
- `connect-key` (a `.p8` already imported)
- `connect-rejected`
- `apps`
- `apps-empty`
- `apps-error`

The UI tests run through these scenes. The list lives in `Debug/DebugSceneView.swift`.

## Tests

- **Unit tests:** `AppLocalizerTests`, written with Swift Testing. They cover:
  - JWT signing and verification;
  - the client's requests, pagination and errors;
  - credentials validation;
  - the Keychain round trip, under a throwaway service name;
  - the session and the view models.
- **UI tests:** `AppLocalizerUITests`, written with XCUITest, run against the DEBUG scenes.

Run everything with `xcodebuild -scheme AppLocalizer -destination 'platform=macOS' test`.

## Lint & formatting

The project is kept warning-free.

- Install the tools once: `brew install swiftlint swiftformat`.
- The `AppLocalizer` target's **Lint** build phase runs `swiftformat --lint` and `swiftlint lint` on every local build.
  - Findings show up as Xcode warnings.
  - The phase is skipped on Xcode Cloud, where the tools aren't installed.
- Format everything with `swiftformat .` from the repo root. The configs are `.swiftformat` and `.swiftlint.yml`, the same rules as Bruma.

### Build settings worth knowing

- `ENABLE_USER_SCRIPT_SANDBOXING = NO` on the `AppLocalizer` target lets the Lint phase read the sources.
- The App Sandbox is on, with two exceptions:
  - outgoing connections (`ENABLE_OUTGOING_NETWORK_CONNECTIONS`), for the API;
  - user-selected files, read-only (`ENABLE_USER_SELECTED_FILES`), to import the `.p8`.
- `LM_SKIP_METADATA_EXTRACTION = YES` (project level) silences Xcode's "Metadata extraction skipped, no AppIntents.framework dependency found" warning. **Remove it if the app ever adopts App Intents.**
