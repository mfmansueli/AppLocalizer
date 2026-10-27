# AppLocalizer

macOS app (SwiftUI, macOS 27+) for localizing apps faster through the App Store Connect API:

- **Pricing:** per-territory prices for every subscription and in-app purchase, from one base price. Custom prices,
  scheduled changes, the map and the histogram, and the results of past changes.
- **Store page:** the App Store listing's text in every locale, with import, Find and Replace, and translation by Apple
  Translation, an AI provider (Anthropic or OpenAI, with your own API key) or your assistant.
- **Localized screenshots:** one template, captions per locale, imported captures, and renders checked for fit before
  they're pushed.
- **App Information:** general information, the age rating, accessibility declarations and an App Privacy worksheet.
- **AI assistants (optional):** a local MCP server lets Claude Code, Claude Desktop, Cursor or Codex read the
  listing and propose text, prices, privacy answers and screenshots. Proposals wait for review like any other change;
  assistants can't push.

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
- `MCPBridge/`: the `applocalizer-mcp` command-line tool (see [AI assistants](#ai-assistants-mcp)). `Sources/` is
  compiled into the tool and the unit tests, and `Tool/main.swift` only into the tool.
- **One top-level type per file.** Extensions go in `Type+Topic.swift`.
- **State:** `@MainActor @Observable final class` view models with `private(set)` state.
  - Each feature talks to the outside world through a `@MainActor protocol <Feature>Services` with a `Live…` implementation. Tests and DEBUG scenes swap in fakes.
  - Views have two inits: a live one, and `init(viewModel:)` for previews and DEBUG scenes.
- **API client:** `AppStoreConnectClient` builds URLs, signs requests, maps HTTP errors (`AppStoreConnectError`) and follows `links.next` pagination. Each resource's endpoints go in their own extension, e.g. `AppStoreConnectClient+Apps.swift`. Requests go through `HTTPTransport`, so unit tests never reach Apple.
- **Swift 6** language mode, strict concurrency, nonisolated by default (like Bruma).

### DEBUG scenes

In a Debug build, launch with `-AppLocalizerDebugScene <id>` to open one state with canned data. A scene never contacts
App Store Connect or the Keychain, and the MCP server in a scene never opens a port. Each area keeps its ids in its own
`*DebugScenes` type, and `Debug/DebugSceneView.swift` routes them:

- **Library and overview:** `apps`, `apps-empty`, `apps-error`, `lib-loading`, `overview`, `overview-keep`.
- **Connect:** `connect`, `connect-key`, `connect-checking`, `connect-401`, `connect-403`, `connect-rejected`,
  `connect-offline`, `sync`, and more (`ConnectDebugScenes`).
- **Settings:** `set-account`, `set-pricing`, `set-translation`, `set-general`.
- **AI Assistants settings:** `set-ai-off`, `set-ai-pair`, `set-ai-waiting`, `set-ai-on`, `set-ai-connected`,
  `set-ai-disc`, `set-ai-log`.
- **Assistants at work:** `ai-translate`, `ai-streaming`, `ai-review`, `ai-conflict`, `overview-ai`.
- **Review & Push:** `review`, `review-assistant`, `push-progress`, `push-partial`, `push-conflict`, `activity`, the
  `banner-*` scenes, and more (`ReviewPushDebugScenes`).
- **Pricing** (`PricingDebugScenes`) and **Store Page** (`StorePageDebugScenes`): one scene per design screenshot.
- **App Information:** `info-*`, `a11y-*` and, for App Privacy, `priv-*` (`AppInformationDebugScenes`).
- **Screenshots:** `sets*`, `viewer*` and `scope`; the Template editor, `tpl*` and `starter`; Captions, `cap*`
  (`ScreenshotsDebugScenes`).

The UI tests run through these scenes.

## Translation providers

Settings → Translation picks who translates: Apple Translation on this Mac, an AI provider, or the assistant connected
over MCP. The AI provider's key is kept in the Keychain and sent only to that provider (`Managers/AIProvider/`).
Anthropic is called through the Messages API (`claude-opus-5-5`, low effort, with Anthropic's default fallback if a
request is declined); OpenAI through Chat Completions (`OpenAIChatAPI.model`). Each field is asked for with its purpose
and limit, the tone, and glossary terms swapped for placeholders, so brand names are never sent for translation.

## AI assistants (MCP)

Settings → AI Assistants turns on a Streamable HTTP MCP server at `http://127.0.0.1:47321/mcp`. It's off by default,
only accepts connections from this Mac, and runs only while the app is open (`Managers/MCP/`).

- **Pairing:** each assistant gets its own bearer token from the "Pair an assistant" sheet, stored in the Keychain.
  Revoking it in Settings ends its sessions.
- **Tools:**
  - Store text: `list_apps`, `get_listing`, `list_missing_translations` and `propose_listing_text`.
  - Prices: `get_prices`, `get_price_points` and `propose_prices`. Proceeds use the commission from Settings →
    General. Every price proposal is refused for apps set to Keep my prices, and a price that isn't a price point is
    refused with the two nearest ones.
  - App Information: `get_privacy_questionnaire` and `propose_privacy_answers` fill the App Privacy worksheet as
    unreviewed suggestions (App Store Connect has no API for App Privacy); `get_age_rating` and `propose_age_rating`
    queue answers that wait until the person ticks Confirmed.
  - Every proposal is validated like a manual edit (limits, URLs, read-only versions), then queued as a change tagged
    with the assistant's name.
  - When a person already changed the same field, both versions are kept and Review & Push asks which to push.
  - Settings decides what assistants may propose, and the log says why a call was refused.
- **Prompts:** `translate_missing`, `whats_new_from_git`, `fill_privacy_from_code` and `fill_age_rating`. A prompt is offered only while its tools are.
- **Clients:**
  - Claude Code and Cursor connect over HTTP.
  - Claude Desktop and Codex launch servers as processes, so they run the bundled bridge,
    `AppLocalizer.app/Contents/MacOS/applocalizer-mcp --token <token>`. It forwards stdio to the HTTP endpoint and
    starts a new session on its own when the app relaunches.

## Tests

- **Unit tests:** `AppLocalizerTests`, written with Swift Testing. They cover:
  - JWT signing and verification;
  - the client's requests, pagination and errors;
  - credentials validation;
  - the Keychain round trip, under a throwaway service name;
  - the session and the view models;
  - the MCP server (HTTP parsing, JSON-RPC, pairing, sessions, tools and prompts) and the stdio bridge.
- **UI tests:** `AppLocalizerUITests`, written with XCUITest, run against the DEBUG scenes.

Run everything with `xcodebuild -scheme AppLocalizer -destination 'platform=macOS' test`.

## Lint & formatting

The project is kept warning-free.

- Install the tools once: `brew install swiftlint swiftformat`.
- The `AppLocalizer` target's **Lint** build phase runs `swiftformat --lint` and `swiftlint lint` on every local build.
  - Findings show up as Xcode warnings.
  - The phase is skipped on Xcode Cloud, where the tools aren't installed.
- Format everything with `swiftformat .` from the repo root. `MCPBridge/` is linted too. The configs are `.swiftformat` and `.swiftlint.yml`, the same rules as Bruma.

### Build settings worth knowing

- `ENABLE_USER_SCRIPT_SANDBOXING = NO` on the `AppLocalizer` target lets the Lint phase read the sources.
- The App Sandbox is on, with three exceptions:
  - outgoing connections (`ENABLE_OUTGOING_NETWORK_CONNECTIONS`), for the API and the AI provider;
  - incoming connections (`ENABLE_INCOMING_NETWORK_CONNECTIONS`), for the local MCP server;
  - user-selected files, read and write (`ENABLE_USER_SELECTED_FILES`), to import the `.p8` and listings, and to
    export listings.
- The `applocalizer-mcp` target is sandboxed on its own, with outgoing connections only, because assistants launch it
  without the app.
  - `CREATE_INFOPLIST_SECTION_IN_BINARY` embeds the Info.plist that a sandboxed tool needs.
  - The app's **Embed Command Line Tool** phase copies the tool into `Contents/MacOS` and signs it.
- `LM_SKIP_METADATA_EXTRACTION = YES` (project level) silences Xcode's "Metadata extraction skipped, no AppIntents.framework dependency found" warning. **Remove it if the app ever adopts App Intents.**
