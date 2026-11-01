# AppLocalizer

macOS app (SwiftUI, macOS 27+) for localizing apps faster through the App Store Connect API:

- **Pricing:** per-territory prices for every subscription and in-app purchase, from one base price. Custom prices,
  scheduled changes, the map and the histogram, and the results of past changes.
- **Store page:** the App Store listing's text in every locale, with import, Find and Replace, and translation by Apple
  Translation, an AI provider (Anthropic or OpenAI, with your own API key) or your assistant.
- **Screenshots (⌘4):** an App Store preview of the live set or the new one, per device, language and appearance;
  one template, captions per locale, imported captures, and renders checked for fit before they're pushed. The
  template gallery (Templates…) offers 12 templates in four styles (Simple, Bold, Elegant, Playful): angled and leaning
  devices, a caption below the device, uppercase, an emphasized first or last line, highlight bars, a slot's own
  background, and decorations per slot (shapes, rating laurels and badges). Their fonts are bundled (SIL Open Font
  License, `Resources/Fonts`), so a template looks the same on every Mac. A laurel or badge must be true: before a
  push, its number is checked against the app's App Store rating in each locale's country (the iTunes Lookup API),
  and a higher one, or one before the app has a rating there, fails the render. Review &
  Push uploads them, keeps the screenshots they replace on this Mac, and Activity puts those back. A live screenshot
  with no image in App Store Connect (its upload never finished, or Apple couldn't process it) has nothing to keep and
  is replaced anyway; one still processing is left for a later push. **Screenshot
  Autopilot** plans the screens, has a connected assistant (Claude Code, Cursor or Codex) capture them in Simulator in
  every language, lets you pick the best captures, gets three design directions (from Claude Design, a Figma file, a
  brand folder or AppLocalizer's starters), then localizes and checks every caption; the new set waits in Review &
  Push. Once the assistant reports the Xcode project (`report_app_support`), or App Store Connect shows it (a build
  with a watch app, from the build's icons; a visionOS version), the plan covers every device the app runs on, iPhone, iPad, Apple Watch (the watch app's own screens, no captions) and Apple Vision Pro (windows of the
  same moments as iPhone, under their captions, pushed to the visionOS version), and every language its string
  catalogs have, including the ones the App Store page doesn't have yet. Unless you keep your own screens, the
  assistant reads the project and picks the screens that show the app best before capturing. **iPhone Duo** (the
  foldable; Apple requires its screenshots from April 2027 for apps built with the iOS 27.1 SDK) is a third set the
  template renders, beside iPhone and iPad, with the same slots and captions, at its inner display's 2007 × 2853
  (`APP_IPHONE_DUO`, not in Apple's published API spec yet). Its cells stay empty, and nothing is pushed, until it has
  captures. App Store Connect's iPhone Duo set takes both displays' sizes (2007 × 2853 and 1398 × 2034, either way
  up), so either display's captures go in; full bleed, an outer-display capture is flagged as scaled too much, and
  Autopilot asks for the inner display's. AppLocalizer treats it as required already: the Sets menu lists it with the
  sizes Apple requires, and every Autopilot plan has it (turned off, it's left to upload by hand). Before capturing,
  the assistant sets Apple's 9:41 status bar on Wi-Fi with no carrier, light appearance, grants the app's permissions
  (`xcrun simctl privacy grant all`) and answers any other prompt, so no alert lands in a capture; each language
  launches in iOS's own language code and its App Store country's formats (`-AppleLanguages (nb) -AppleLocale nb_NO`),
  with its sample data (entries, names, places) in that language too. AppLocalizer reads the text in every capture as it
  arrives (Vision, then Natural Language for the language): one that reads as English or the primary language instead
  of its own, labels cut off with an ellipsis beyond the primary language's, or the app's name in quotes (a permission
  prompt) comes back to the assistant in `report_capture` with what to fix, and a clean attempt ranks above it. The
  ones the set still uses are listed at Pick and Ready as captures to check. The design AI still designs once, from the
  primary language's picks and every language's captions; AppLocalizer renders each language with its own captures.
- **App Information:** general information, the age rating, accessibility declarations and an App Privacy worksheet.
- **AI assistants (optional):** a local MCP server lets Claude Code, Claude Desktop, Cursor or Codex read the
  listing and propose text, prices, privacy answers and screenshots. Proposals wait for review like any other change;
  assistants can't push. With a small helper saved once, AppLocalizer starts the person's own Claude Code itself, so
  nothing needs pasting.

It works with a team API key. The design brief for the full feature set is in `DESIGN_PROMPT.md`.

## Connecting an API key

1. In App Store Connect, open **Users and Access → Integrations → App Store Connect API → Team Keys**.
2. Generate a key with the **Admin** or **App Manager** role. Prices and metadata can't be edited with less.
3. In the app, enter the **Issuer ID** and **Key ID**, then drop in the downloaded `AuthKey_<KEYID>.p8`. The Key ID fills itself in from the file name.

"Connect" signs one `GET /v1/apps?limit=1` before saving anything. The key is stored as one generic-password item in the login Keychain (`KeychainCredentialsStore`). Every request carries a freshly signed ES256 JWT (`AppStoreConnectJWT`), so the `.p8` itself never leaves the Mac. Remove the key in Settings → Account.

The sidebar names the team the way its certificates do: the API has no endpoint for a team's name, but every certificate's subject carries it as the organization (`GET /v1/certificates`). A key whose role can't read certificates shows "App Store Connect team"; renaming the key in Settings → Account always wins. Each app's icon is the one App Store Connect took from its latest build (`iconAssetToken` on `GET /v1/builds`); an app with no processed build keeps its letter. A Mac build's icon comes inside the transparent margin of the Mac's icon grid, which is trimmed (`AppIconMargin`) so every icon fills its tile.

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
App Store Connect or the Keychain, and the MCP server in a scene never opens a port (except `cc-live`, below). Each area keeps its ids in its own
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
- **Suggest Everything:** Overview's entry points, `ev-start`, and the Assistant popover's, `ev-pop`; the prompt
  copied and waiting, `ev-wait`, and while a page's Ask still sends, `ev-busy`; 9 of 18 on Overview, `ev-run`, on
  German's Store Page, `ev-run-store`, on Age Rating, `ev-run-info`, and the Assistant popover's Show Progress,
  `ev-run-pop`; nothing for 3 minutes, `ev-quiet`; the last one arriving, `ev-done`; stopped at 12, `ev-stopped`;
  with only a key, `ev-key`, and with nothing set up, `ev-none` (`EverythingDebugScenes`). `ev-wait` and `ev-busy`
  copy the prompt to the clipboard, as the real button does.
- **New languages:** languages Lumen's project has and its App Store page doesn't (Polish, Turkish, Hebrew), drafted
  by Claude Code: the banner on English (U.S.), `sp-newlang`; Polish's tab before it's added, `sp-newlang-tab`;
  Hebrew added with every draft accepted, `sp-newlang-added`; the languages sheet, `langs-sheet`; Review & Push with
  "Create the Polish page", `review-newlang`; Overview's New languages and Languages lines, `ov-newlang`; and
  Suggest Everything waiting, its scope listing the new pages, `ev-newlang` (`NewLanguagesDebugScenes`).
- **Review & Push:** `review`, `review-assistant`, `push-progress`, `push-partial`, `push-conflict`, `activity`, the
  `banner-*` scenes, and more (`ReviewPushDebugScenes`).
- **Pricing** (`PricingDebugScenes`) and **Store Page** (`StorePageDebugScenes`): one scene per design screenshot.
- **App Information:** `info-*`, `a11y-*` and, for App Privacy, `priv-*` (`AppInformationDebugScenes`).
- **Screenshots:** the Preview page and Autopilot, `st-*` (`StudioDebugScenes`): `st-home`, `st-live-ar`,
  `st-noasst`, `st-design` (Connect a Design Project), one sheet per stage (`st-plan`, `st-wait`, `st-cap`, `st-fail`,
  `st-pick`, `st-des`, `st-choose`, `st-choose-rev`, `st-nodesign`, `st-loc`, `st-ready-sheet`), the strip on the
  page (`st-cap-page`, `st-pick-page`) and the new set (`st-ready`, `st-ready-de`, `st-ready-ar`, `st-ready-ipad`).
  On every device and with the project's new languages: `st-plan-all`, `st-cap-watch`, `st-cap-vision`,
  `st-pick-all`, `st-choose-all`, `st-loc-all`, `st-ready-sheet-all`, `st-live-watch`, `st-live-vision`,
  `st-ready-watch` and `st-ready-vision`. With no project report but a build with a watch app, `st-asc-watch`. A
  Claude Design link nobody has read yet, a long assistant name and a long screen name, `st-plan-link`.
  The Sets matrix, `sets*`, `viewer*` and `scope`; the Template editor, `tpl*` and `starter`; the template gallery,
  `gallery` and `gallery-elegant`, and a few of its templates rendered, `tpl-cinema`, `tpl-highlight-ar`,
  `tpl-market-de`, `tpl-poster-ja` and `tpl-swoosh-deco`; Captions, `cap*`
  (`ScreenshotsDebugScenes`). Captures, `capt*`, and assistants' proposals, `prop-*`
  (`ScreenshotsProposalsDebugScenes`). Pushing them, `shots-review`, `shots-push`, `shots-push-partial`, and
  restoring them from Activity, `shots-act` and `shots-act-restore` (`ScreenshotsPushDebugScenes`).
- **Claude Code started by AppLocalizer:** through a pretend helper (`DebugUnixScriptRunner`), so nothing runs:
  setup's step 3 before and after the helper is saved, `cc-setup` and `cc-setup-installed`, and its test run
  connecting, `cc-setup-test`; Ask working, `cc-ask`; Suggest Everything working, `cc-everything`; Show Output,
  `cc-output`; not logged in, `cc-login`; refused steps, `cc-denied`; Settings, `cc-settings`; the Assistant button
  with two runs, `cc-toolbar`; and Ask without the helper, `cc-hint` (`ClaudeCodeDebugScenes`). `cc-live` is the
  exception: setup's test through the helper really saved in the scripts folder, with your own Claude Code and login,
  and the MCP server on port 47399, away from the real app's. `CC_LIVE_FOLDER` picks the folder and
  `CC_LIVE_STOP_AFTER=<seconds>` stops the run.

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
  nothing first; its toast, and Edit → Undo, put everything back. With Claude Code's helper saved, Ask starts Claude
  Code instead of copying (see [Starting Claude Code](#starting-claude-code-from-applocalizer)).
- **Suggest Everything** (Overview's assistant and Suggestions cards, and the Assistant button) copies one prompt (or,
  with Claude Code's helper saved, starts Claude Code with it) for every field the connected assistant can suggest, listing what it covers page by page: the Store Page's fields
  that can change, General, Age Rating, Accessibility and App Review. While the version is in review only what can
  still change is asked, and App Review says it's locked. The assistant announces its plan with
  `begin_suggestions`, and Overview then shows a card with the run's total, each page's progress and Review, and
  Stop Receiving; pages, languages and devices say what's still coming, with striped placeholders where a
  suggestion will land, and a bar on each page leads back to Overview. When the run ends a toast gives the total;
  Accept All (n) takes what's left from the run and its toast offers Undo. A run that sends nothing for two minutes
  says the assistant stopped sending. With only an API key it generates on the Store Page, and with nothing set up,
  setup opens and says why (`Managers/Suggestions/Run/`, `Screens/Overview/Components/SuggestEverything/`).
- **Where they show:** the language picker and App Information's page column count them, and Overview's Suggestions
  card sums them by area and source. Built-in ones are counted once their page has loaded.
- **New languages:** once the assistant reported the project (`report_app_support`), each language its string
  catalogs have and the App Store page doesn't is a built-in suggestion to create its page: a banner on the App
  Store languages (Review… opens "Languages in the app, not on the App Store", Add All n adds them, with Undo), and
  its own entry in the language picker, marked New, with the fields empty and their suggestions. Not Now stops
  suggesting it; Create Page, or accepting or editing one of its fields, adds it. An added language says its page is
  created when you push, with Don’t Add. Review & Push shows "Create the Polish page" under "Store Page · Polish
  (new)", with its fields under it, checked and discarded together; the page is created even before it has text.
  When App Store Connect has the language by the time it's pushed (added there, or created along with the other
  level), the texts go onto that localization if they overwrite nothing (`ExistingLocalizationUpdate`); otherwise,
  and whenever the Store Page or an assistant reads it again, the queued page becomes edits of what's there.
  Overview's Suggestions card names them under New languages (their drafts aren't counted under Store Page), and the
  Store page card says "10 · 3 more in the app" or "10 · 2 new to push". Suggest Everything asks for them too.
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
    assistant sends them. Both read tools (and `get_listing`) list `languagesNotOnAppStore`, the languages the
    project has and the App Store page doesn't (suggested, added, or said Not Now to), and `get_store_page` lists
    the suggested ones in `locales` with `new: true`. `suggest_fields` takes them as locales: they stay suggestions
    in their own tab, even with `apply`, until the person adds the page.
  - Suggest Everything: `begin_suggestions` takes the plan, one entry per field, and returns the run's id, how
    many AppLocalizer counts, and what it skipped with a code (`changed_by_you`, `locked`, `in_another_request`,
    `already_suggested`, and the `suggest_fields` ones). `suggest_fields` calls carry the run's id, and are refused
    with `run_stopped` once the person stops receiving; `end_suggestions` ends the run.
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
  - Screenshot Autopilot: `get_capture_plan` returns the plan, the simulator commands and an upload URL;
    `update_capture_plan` writes the screens and steps; captures are sent as raw PNG bodies to
    `POST /autopilot/<token>` on the MCP server (the app is sandboxed, so it can't read the assistant's files), which
    returns an upload id for `report_capture`; `report_capture_problem` reports a screen that can't be reached.
    Each locale carries `launchArguments` for the simulator and `testArguments` (`-testLanguage de -testRegion DE`)
    for UI tests, so `xcodebuild test` needs nothing in front of it. A command the session wasn't allowed to run comes
    as `refusedCommand`: its fix is a change to the project, so retrying doesn't add it to the plan's commands.
    So does a fix the assistant marks `changesProject: true`, or one that doesn't read as a command
    (`AutopilotProblem.needsProjectChange`). The plan carries `preflight` checks (`AutopilotPreflight`: identifiers
    rather than visible titles, sample data in each language, no forced `-AppleLanguages`, no `VAR=value`) and a
    `rehearsal` language (another script than the primary's, else German): `next_step` gives every screen on every
    device in those two first (`phase: rehearsal`), then the rest. An open problem holds the same screen on the same
    device in the other languages, so one cause is reported once; problems with one cause share a card
    (`AutopilotProblemGroup`), and reusing the primary capture for a change to the project covers the screen's other
    languages (`primaryCaptureTargets`). `next_step` says what to do next (capture, wait, design, revise, write captions, done). `get_design_brief`,
    `report_design_source`, `propose_direction` and `revise_direction` carry the design stage, and
    `propose_captions` with the run's id shortens captions while localizing. The person plans, picks, chooses and
    pushes in the app; the assistant never pushes. The plan lists each device's screens and how to capture them
    (`devices`), and marks the languages not on the App Store yet (`notOnAppStoreYet`); `update_capture_plan` takes
    `device: watch` or `vision` for those devices' own screens, and `sameMomentAs` for a Vision Pro window. When the
    plan says `chooseScreens`, the assistant picks the screens and sends them with `replace: true`, which puts them
    in place of the plan's on each device it sends, before the first capture.
  - The app's devices and languages: `report_app_support` records the targets and platforms, and the languages in
    the string catalogs with how much of each is translated. Autopilot plans from it, and Store Page suggests pages
    for the languages the App Store doesn't have yet.
  - Every proposal is validated like a manual edit (limits, URLs, read-only versions), then queued as a change tagged
    with the assistant's name.
  - When a person already changed the same field, both versions are kept and Review & Push asks which to push.
  - Settings decides what assistants may propose, and the log says why a call was refused.
- **Prompts:** `translate_missing`, `whats_new_from_git`, `fill_privacy_from_code`, `fill_age_rating`,
  `translate_captions`, `shorten_overflowing_captions`, `revise_template`, `suggest` (with an optional `area`,
  `store` or `info`), `suggest_all`, Suggest Everything's, and `run_screenshots`, Screenshot Autopilot's. A prompt is offered only while its
  tools are.
- **Clients:**
  - Claude Code and Cursor connect over HTTP.
  - Claude Desktop and Codex launch servers as processes, so they run the bundled bridge,
    `AppLocalizer.app/Contents/MacOS/applocalizer-mcp --token <token>`. It forwards stdio to the HTTP endpoint and
    starts a new session on its own when the app relaunches.

### Starting Claude Code from AppLocalizer

The app is sandboxed for the Mac App Store, so it can't start other programs. Instead, the person saves a small helper
once, from a Save panel already in `~/Library/Application Scripts/com.lima.applocalizer/` (setup's step 3, Settings →
AI Assistants, or the "Skip the paste" hints). macOS runs scripts there outside the sandbox with `NSUserUnixTask`, so
no new entitlement is needed (`Managers/ClaudeCodeLauncher/`).

- **The helper** (`ClaudeCodeHelperScript`): `check` prints its version and where `claude` is; `run <folder> --
  <arguments…>` runs Claude Code in the app's project folder, streams its output and prints
  `applocalizer-helper-exit <status>` when it ends. Claude Code writes through pipes of its own that `cat` passes on:
  Node leaves the pipe it writes to non-blocking, which on AppLocalizer's pipe lost a run's last lines and its exit
  line (helper version 1). A line on stdin, or stdin closing, ends Claude Code with SIGTERM (a script's background job
  ignores SIGINT); the session stays resumable. A helper older than `version` asks to be saved again.
- **Each run** (`ClaudeCodeInvocation`) is `claude -p --output-format stream-json --verbose --restricted
  --strict-mcp-config --mcp-config … --settings … --permission-mode dontAsk --tools …`. It knows only AppLocalizer's
  server, with a token made for that run that acts as the paired Claude Code and stops working when the run ends
  (`MCPServerController+Launch`). The person's own settings and allow rules are ignored, and anything not allowed is
  refused and listed. `ClaudeCodePermissions`: setup's test uses only AppLocalizer's tools; suggestions, translations
  and the privacy scan also read the project and run read-only git; Autopilot also runs `xcodebuild`, `xcrun simctl`
  and uploads to AppLocalizer. Each command must start with an allowed program, so `VAR=value xcodebuild …` is
  refused; Autopilot is told so.
- **Where:** Ask on every suggestion bar, Suggest Everything, Screenshot Autopilot, Translate Missing, Translate
  Captions, App Privacy's scan, and setup's test. Each app's project folder is asked for once, and Settings lists
  them. Without the helper, every screen copies its prompt as before.
- **Seeing it:** a status strip where it started, the Assistant button's popover, and Show Output with each step, the
  result, refused steps and Copy Resume Command (`ClaudeCodeRun`). A failure says why (not logged in, no Claude Code,
  folder moved, AppLocalizer unreachable) with the way through: Open in Terminal (Claude Code's `claude-cli://open`
  link), Try Again or Choose Folder…, and Copy Prompt.
- Claude Code uses the person's own login and plan.

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
  - Suggest Everything: what it covers and its prompt, the run's plan, progress and end, Accept All and its Undo,
    and the toasts;
  - the API key: each vendor's models and requests, the project folder's commits and changelog, the plan and its
    tokens, reading the answer, and adding what passes to the Store Page;
  - Screenshot Autopilot: the run's stages, captures, problems and picks, the planner and estimate, caption checks
    and direction pills, brand folders, the MCP tools and the upload endpoint, and the App Store preview and its
    Live/New set summaries; Apple Watch and Apple Vision Pro (their screens, layouts, checks, previews and pushes to
    the visionOS version), iPhone Duo (its sizes, checks, canvas, row and plan) and the project's new languages;
  - Claude Code started by AppLocalizer: the helper's answers and exit line, each run's arguments and permissions,
    reading the stream, failures, the Terminal link, runs through a pretend helper (folders, run tokens, Stop, Try
    Again, login and server problems), and setup's test run.
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
