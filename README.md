# AppLocalizer

macOS app (SwiftUI, macOS 27+) for localizing apps faster through the App Store Connect API:

- **Pricing:** per-territory prices for every subscription and in-app purchase, from one base price. Custom prices,
  scheduled changes, the map and the histogram, and the results of past changes.
- **Store page:** the App Store listing's text in every locale, with import, Find and Replace, and translation by Apple
  Translation, an AI provider (Anthropic or OpenAI, with your own API key) or your assistant.
- **Localized screenshots:** one template, captions per locale, imported captures, and renders checked for fit before
  they're pushed. Review & Push uploads them, keeps the screenshots they replace on this Mac, and Activity puts those
  back.
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
- **Suggestions and assistant setup:** the overview before and after connecting, `ov-first` and `ov-connected`; the
  Assistant popover, `asst-pop`; the setup sheet, `setup-1` to `setup-4` and `setup-done`; the Store Page with
  built-in suggestions only, `sp-builtin`, with Claude Code's, `sp-cc`, asking, `sp-ask`, receiving, `sp-streaming`,
  after accepting and dismissing, `sp-accepted`, Use and Edit, `sp-edit`, and German and Japanese, `sp-de` and
  `sp-ja`; App Information's General and App Review, `in-general` and `in-review` (`SuggestionsDebugScenes`).
- **API key and code answers:** the setup sheet with a key, `setup-key-1`, `setup-key-2`, `setup-key-bad`,
  `setup-key-3` and `setup-key-done`; the Store Page with a key, `sp-key`, and Generate Suggestions… open,
  `sp-key-ask`; the Assistant popover with a key, `asst-pop-key`; Age Rating's suggested answers, `in-age`, accepted,
  `in-age-done`, and with a key, `in-key`; Accessibility's for Apple Watch and iPhone, `in-ax` and `in-ax-iphone`
  (`AssistDebugScenes`).
- **Review & Push:** `review`, `review-assistant`, `push-progress`, `push-partial`, `push-conflict`, `activity`, the
  `banner-*` scenes, and more (`ReviewPushDebugScenes`).
- **Pricing** (`PricingDebugScenes`) and **Store Page** (`StorePageDebugScenes`): one scene per design screenshot.
- **App Information:** `info-*`, `a11y-*` and, for App Privacy, `priv-*` (`AppInformationDebugScenes`).
- **Screenshots:** `sets*`, `viewer*` and `scope`; the Template editor, `tpl*` and `starter`; Captions, `cap*`
  (`ScreenshotsDebugScenes`). Captures, `capt*`, and assistants' proposals, `prop-*`
  (`ScreenshotsProposalsDebugScenes`). Pushing them, `shots-review`, `shots-push`, `shots-push-partial`, and
  restoring them from Activity, `shots-act` and `shots-act-restore` (`ScreenshotsPushDebugScenes`).

The UI tests run through these scenes.

## Translation providers

Settings → Translation picks who translates: Apple Translation on this Mac, an AI provider, or the assistant connected
over MCP. The AI provider's key is kept in the Keychain and sent only to that provider (`Managers/AIProvider/`).
The tab checks the saved key when it opens, after a key is saved and when the vendor changes, with a `GET` for the
model translations use (no tokens spent), and says under the field whether it's saved and connected, rejected, or
couldn't be checked. Anthropic is called through the Messages API (`claude-opus-5-5`, low effort, with Anthropic's default fallback if a
request is declined); OpenAI through Chat Completions (`OpenAIChatAPI.model`); Google Gemini through
`generateContent` (`GeminiGenerateAPI.model`). Each field is asked for with its purpose
and limit, the tone, and glossary terms swapped for placeholders, so brand names are never sent for translation.

## Field suggestions

A suggestion is a proposed value for one field, in one Store Page language or one App Information page (General, Age
Rating, Accessibility per device, and App Review), with a reason. It never changes the field by itself: it shows under the field with Dismiss, Use and Edit
and Accept, and accepting queues an unpushed change tagged with who suggested it (`Managers/Suggestions/`,
`Screens/Suggestions/`).

- **Sources:** built-in checks that need nothing else (keywords that repeat the name or subtitle, empty URLs other
  languages fill, a copyright with last year, contact details the previous version had, no advertising when App
  Privacy's scan found none); the assistant connected over MCP (`suggest_fields`); an API key; and the AI provider.
- **An API key** (Anthropic, OpenAI or Google Gemini), set up from the same sheet or Settings → AI Assistants, lets
  AppLocalizer ask the model itself, without an assistant (`Managers/KeyAssistant/`). Generate Suggestions… on a Store
  Page first lists what it will send and about how many tokens: the language's texts with their limits, and, when
  allowed, the commit messages since the last release tag and CHANGELOG.md's section from the project folder (git
  runs from Xcode's or the Command Line Tools' binary, else HEAD's reflog is read) and one page of the latest App Store
  reviews. Source code is never sent. The answer is checked like an edit and its suggestions are tagged with the
  key's API ("Anthropic API"). App Information's answers come from the code, so with only a key those pages say how
  many need an MCP assistant. While an assistant is connected, it suggests instead of the key. The key is kept in the
  Keychain apart from Settings → Translation's, which can use it too.
- **The bar** above each language or page counts them, filters by source, and offers Ask (copying the prompt, since
  AppLocalizer can't start the assistant), Dismiss All, Accept All and Accept All in Every Language. Accept All asks
  nothing first; its toast, and Edit → Undo, put everything back.
- **Where they show:** the language picker and App Information's page column count them, and Overview's Suggestions
  card sums them by area and source. Built-in ones are counted once their page has loaded.
- Suggestions and decisions are kept on this Mac (`FileFieldSuggestionPersistence`), and DEBUG scenes keep them in
  memory.

## AI assistants (MCP)

Settings → AI Assistants turns on a Streamable HTTP MCP server at `http://127.0.0.1:47321/mcp`. It's off by default,
only accepts connections from this Mac, and runs only while the app is open (`Managers/MCP/`). "Set Up Your AI
Assistant" (from the toolbar's Assistant button, the overview or a suggestion bar) walks through choosing a client,
turning the server on with Suggest only or Suggest and edit drafts, adding AppLocalizer to the client, and a first
call.

- **Pairing:** each assistant gets its own bearer token from the "Pair an assistant" sheet, stored in the Keychain.
  Revoking it in Settings ends its sessions.
- **Tools:**
  - Store text: `list_apps`, `get_listing`, `list_missing_translations` and `propose_listing_text`.
  - Field suggestions: `get_store_page` and `get_app_information` read the fields, their limits and the suggestions
    already open; `suggest_fields` sends suggestions per item (queued, unchanged, replaced, or refused with a code:
    `over_limit`, `unknown_field`, `unknown_locale`, `locked`, `not_permitted`, `invalid_value`). With Suggest and
    edit drafts, `"apply": true` queues the values as changes instead. Store Page items need the store text
    permission, App Information items the app information one. `total` drives the bar's progress while the
    assistant sends them.
  - Prices: `get_prices`, `get_price_points` and `propose_prices`. Proceeds use the commission from Settings →
    General. Every price proposal is refused for apps set to Keep my prices, and a price that isn't a price point is
    refused with the two nearest ones.
  - App Information: `get_privacy_questionnaire` and `propose_privacy_answers` fill the App Privacy worksheet as
    unreviewed suggestions (App Store Connect has no API for App Privacy); `get_age_rating` and `propose_age_rating`
    queue answers that wait until the person ticks Confirmed.
  - Screenshots: `get_screenshot_context`, `list_captures`, `get_capture`, `get_template`, `get_captions`,
    `measure_caption` (the same fit engine the renders use), `render_preview`, `propose_template`,
    `propose_captions` and `list_proposals`. `get_capture` and `render_preview` return PNG images. Slots are
    numbered from 1. Screenshot proposals wait in their own Proposals sheet, opened from the toolbar's assistant
    indicator, rather than in Review & Push.
  - Every proposal is validated like a manual edit (limits, URLs, read-only versions), then queued as a change tagged
    with the assistant's name.
  - When a person already changed the same field, both versions are kept and Review & Push asks which to push.
  - Settings decides what assistants may propose, and the log says why a call was refused.
- **Prompts:** `translate_missing`, `whats_new_from_git`, `fill_privacy_from_code`, `fill_age_rating`,
  `translate_captions`, `shorten_overflowing_captions`, `revise_template` and `suggest` (with an optional `area`,
  `store` or `info`). A prompt is offered only while its
  tools are.
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
  - the AI providers' requests and replies;
  - the screenshot fit engine, renders, the push plan and its uploads, backups and restores;
  - the MCP server (HTTP parsing, JSON-RPC, pairing, sessions, tools and prompts) and the stdio bridge;
  - field suggestions: the store, the built-in checks, accepting and undoing on both pages, and the setup sheet;
  - the API key: each vendor's models and requests, the project folder's commits and changelog, the plan and its
    tokens, reading the answer, and adding what passes to the Store Page.
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
