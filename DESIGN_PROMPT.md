Design a native macOS app called **AppLocalizer**: a desktop tool for iOS/macOS developers who ship several apps and want to localize two things fast, through the App Store Connect API:

- **subscription prices** for every App Store territory, set to get more people to pay: by each region's purchasing power (the Big Mac Index, World Bank PPP…) rather than a flat currency conversion;
- the **App Store page** (listing text) for every language.

Pricing is **optional**. Someone can use AppLocalizer only to translate and keep every price as it is, look at price suggestions without applying them, or apply the suggested prices in one step. See "Pricing mode" in section 4.

Build the design system and every screen listed below as an interactive prototype, plus a README handoff. The README should cover tokens, components, specs per screen, and the decisions you made where this brief is silent.

## Platform and constraints

- **macOS 27, SwiftUI, Liquid Glass.** The implementation uses native controls:
  - `NavigationSplitView` (sidebar plus detail, with an optional right-hand inspector);
  - `Table`, toolbars, sheets, popovers, menus, segmented pickers and the Settings window.
  - Design within those. No web-dashboard chrome, no custom title bars, no hamburger menus. It should feel like Xcode, System Settings, Numbers or Transporter, and calmer than App Store Connect's web UI.
- **One main window**, plus the Settings window (⌘,). Minimum size 860×560, default 1200×780. Light and dark mode both matter, and Increase Contrast must work.
- **SF Pro and SF Mono only.** Prices, IDs and character counts use tabular digits.
- **A professional tool.** Dense but quiet: many numbers need to be scannable at a glance. Color carries meaning only: increase, decrease, error, warning, machine-translated, unsaved.
- **What already exists:**
  - a **Connect** screen (Issuer ID, Key ID, a `.p8` drop zone, a "Where do I find these?" disclosure and a Connect button);
  - the **main window**: an app list in the sidebar with search, and a toolbar segmented picker for "Subscription Pricing | Store Page" over placeholder content.
  - Treat both as wireframes to redesign.

## Real data to design for

- **175 territories**, each with its own currency.
  - Some currencies have no decimals (JPY, KRW, IDR, VND), and some prices are long strings ("Rp 149.000", "₫ 249.000", "CHF 12.00").
  - Prices must snap to **Apple's fixed price points** per territory (about 800 per currency). There is never a free-form price, only the nearest valid point.
  - Customer price ≠ proceeds (Apple's commission and taxes), so show both where it helps.
- **Price indices are uneven.** None covers all 175 territories, and each has its own edition date:
  - The Economist's **Big Mac Index**: about 55 economies, twice a year (January and July). The euro area is a single entry shared by about 20 territories.
  - The **World Bank** PPP price level: most territories, yearly, published a year or two late.
  - The **IMF** implied PPP rate: most territories, every April and October.
  - So every proposed price needs a visible source, and territories without data need a fallback.
- **Conversion data is partial.** Sales and Trends reports give subscription starts, trial conversions and cancellations per territory, and App Analytics gives product page views and downloads. But they're only there when the key's role can read them, they arrive a day or more late, and small territories sell too little to mean anything. App Store Connect can't A/B test prices.
- **39 App Store locales**, including right-to-left ones (Arabic, Hebrew) and long ones (German, Finnish).
- **Character limits:**
  - App name 30, subtitle 30, promotional text 170, description 4,000, What's New 4,000;
  - keywords 100 (comma-separated);
  - subscription display name 30, subscription description 45.
- **Pushes are slow.** App Store Connect allows about 3,600 requests per hour and applies changes one request at a time, so pushes need visible progress and partial-failure handling.

## Screens and features to map

### 1. Connect (first launch, and after removing the key)

- Fields:
  - Issuer ID (a UUID);
  - Key ID (10 characters);
  - the private key, an `AuthKey_XXXX.p8` file chosen or dropped.
- Drop zone states:
  - empty;
  - drag hover;
  - imported (file name, "stays in this Mac's Keychain", Remove);
  - wrong file.
- Inline field hints for malformed values.
- Help disclosure: where to create a **Team Key** with the Admin or App Manager role, and a link to App Store Connect.
- Connect button states: disabled, checking, error. Errors to cover:
  - 401: key rejected;
  - 403: role too low;
  - offline.
- A trust note: the key never leaves the Mac, and requests are signed locally.
- After success: a first sync ("Loading your apps…") into the library.

### 2. App library (sidebar)

- Each row: app icon (a letter tile when no icon is available), name and bundle ID.
- Row indicators:
  - unpushed changes;
  - store-page locale coverage;
  - pricing status (hidden for apps set to "Keep my prices").
- Search by name, bundle ID or SKU, plus sort options.
- States: loading skeleton, empty account, error with retry.
- **Account switcher**: several saved API keys (teams), plus "Add another key…".

### 3. App overview (landing for the selected app)

- Summary cards:
  - subscription groups and subscriptions;
  - territories with custom vs. equalized prices;
  - the pricing mode and, unless prices are kept, how many territories have a price that likely holds people back, with "Review suggestions";
  - store-page locales and how complete they are;
  - pending changes;
  - last push.
- Quick actions into each section.

### 4. Subscription Pricing

The goal of pricing is **conversion**: more people subscribing or buying, not the highest possible price. And it's optional.

- **Pricing mode**, per app, switchable at any time from the Pricing toolbar. The first time someone opens Pricing for an app, a short sheet asks which mode they want, with "Show suggestions" preselected. The default for new apps lives in Settings.
  - **Keep my prices**, for people who only want to translate. AppLocalizer never proposes a price change: Pricing shows current prices and proceeds read-only, the sidebar and overview drop their pricing indicators, and Review & Push holds text changes only. The only nudge is a quiet "Show price suggestions" link.
  - **Show suggestions.** Each territory shows a suggested price next to the current one, with its reason and confidence, but nothing is queued. "Apply" on a row or a selection turns those suggestions into pending changes.
  - **Apply recommended prices.** One button fills every proposed price with the suggestion and opens Review & Push. Nothing is ever pushed without that review.
- **Recommended price**, per territory: the price most likely to get someone there to pay, without going below the floor or the minimum proceeds. Otherwise "the most conversions" would just mean free.
  - **"Feels like":** what a price means to a local, in base-currency terms. R$ 219,90 is about $40 at market rates but feels like about $80 to someone in Brazil, twice the US price. The suggestion brings it back to feeling like $40: about R$ 109,90.
  - **What it's based on**, from weakest to strongest:
    - purchasing power alone (the price index below), always available;
    - the app's own sales per territory, when the key can read Sales and Trends and App Analytics, e.g. many product page views but few subscriptions where the price feels high;
    - the results of earlier price changes (below).
  - **Reason and confidence** on every suggestion: one line of why ("Feels like 2× the US price") and a confidence badge (low: purchasing power only; medium or high: backed by sales). Never invent conversion rates. Show estimates as directions or ranges, labeled with what they're based on.
  - **Customize…** opens the strategy inspector below. Changing anything there marks the prices as custom rather than recommended, with "Back to recommended".
- **Results tab**, also linked from Activity history. The App Store can't A/B test prices, so compare each changed territory before and after (e.g. 28 days each): subscription starts, conversion from product page views, and proceeds. Say when there's too little data to tell, and offer to restore the old price where results got worse.
- **Subscription browser:** groups → subscriptions. Each shows its name, product ID, duration (1 week / 1 month / 1 year…), review state and base price.
- **Price matrix** for one subscription, a sortable table of 175 rows:
  - flag and territory, region, currency;
  - current price and proceeds;
  - USD equivalent;
  - Apple's equalized price;
  - unless prices are kept: the suggested price, its "feels like" price, reason and confidence;
  - index factor, tier and source (a provenance badge);
  - **proposed price**, edited through a price-point stepper or menu of nearby valid points;
  - change % (a color pill), new USD equivalent;
  - status: unchanged, increase, decrease, recommended, edited manually, scheduled.
  - Filters: region (Americas, Europe, Asia Pacific, Africa & Middle East), "changed only", "increases only", "fallback rows only", and search.
  - Multi-select.
- **Strategy inspector** (Customize…), with the matrix updating live as it changes:
  - base territory and base price;
  - method: Recommended (the default), Apple equalization, a **price index** (below), or custom regional tiers with multipliers;
  - rounding: nearest price point, preferred endings (.99, .90, round numbers for JPY/KRW);
  - "never raise existing prices".
- **Regional pricing by price index.** The engine behind the recommendation, which uses World Bank PPP (the broadest source) at full intensity with the default floor; here it's exposed in full. Apple's equalization only converts currency and taxes: a $39.99 annual plan lands at about R$ 220 in Brazil, far more than most people there pay for an app. The index method sets each territory's price from its local price level instead.
  - **Index picker.** Each source shows its publisher, edition date, coverage ("54 of 175 territories"), a one-line description and a link:
    - **Big Mac Index** (The Economist, the raw index, not the GDP-adjusted one): well known and easy to explain, but few countries and milder discounts;
    - **World Bank PPP price level**: covers most territories and gives deeper discounts in emerging markets, but runs a year or two behind;
    - **IMF implied PPP rate**: broad coverage, updated in April and October;
    - **Custom index**: a CSV of territory code → factor (or a local reference price), with an import preview listing unmatched codes.
  - **One formula for every source**, shown in the inspector and documented in the README:
    1. factor = the territory's price level ÷ the base territory's (illustrative: Brazil ≈ 0.75 on the Big Mac Index, ≈ 0.5 on World Bank PPP);
    2. target = Apple's equalized local price × (1 − intensity + intensity × factor). Starting from the equalized price keeps Apple's tax handling;
    3. clamp between the floor and the ceiling;
    4. snap to the nearest price point with the preferred ending.
  - **Controls:**
    - an intensity slider, from 0% (equalized) to 100% (the full index);
    - a floor and ceiling relative to base, in USD (e.g. never below 30% of base), plus an optional minimum proceeds per territory;
    - **discount only**, on by default: never go above the equalized price, even where the factor is above 1 (Switzerland, Norway). Turning it off allows premiums;
    - **tiers**, optional: bucket territories into a few tiers by factor (e.g. 100%, 80%, 60%, 40%) with editable thresholds, so similar markets get the same discount;
    - exclude selected territories from the index so they stay equalized, e.g. Japan, where a weak yen makes the Big Mac Index suggest a deep discount in a market that already pays well for apps.
  - **Coverage and fallback:** an ordered fallback chain (e.g. Big Mac → World Bank → region median → equalized) fills the gaps. Every row shows a provenance badge (source and edition, marked as a fallback when it isn't the chosen index).
  - **Price breakdown popover** on every proposed price, one line per step: "R$ 219,90 equalized × 0.75 = R$ 164,93 → above floor → R$ 164,90".
  - **Compare sources** for the selected territory: current, equalized and each source's suggestion side by side as small bars, with "Use this" to override the row (it then shows as edited manually).
  - **Data freshness:** the app ships a snapshot of each index, so it works offline. Flag an edition older than a year, or a newer one being available, with "Update index data".
- **Visualizations:**
  - a world map heat view (% vs. base, USD equivalent, "feels like" price, or index factor) with hover details;
  - a distribution histogram.
- **Bulk actions:**
  - apply the suggested price to the selection;
  - multiply the selection, or set its price;
  - reset to equalized;
  - copy from another subscription;
  - apply the strategy to the whole group, keeping ratios between durations (e.g. annual = 10× monthly).
- **Schedule and subscribers:**
  - a start date (now or later);
  - "keep current price for existing subscribers";
  - warnings for increases that need subscriber consent, with counts per territory.
- **Offers tab:**
  - introductory, promotional and win-back offers, and offer codes;
  - an offer list and one editor, with per-territory offer prices derived from the subscription's local price.
- **In-app purchases (non-subscription):** the same matrix pattern, shown briefly.

### 5. Store Page

- **Context bar:**
  - an app version picker: the editable "1.4 — Prepare for Submission" vs. the read-only live "1.3 — Ready for Distribution";
  - app-level vs. version-level fields, made clear. Name, subtitle and privacy URL are app-level; the rest are per version.
- **Coverage grid:**
  - rows are locales, columns are fields;
  - cells show missing, filled, over the limit, machine-translated (not yet reviewed), or edited (not pushed);
  - add or remove locales.
- **Locale editor**, side by side:
  - the source locale (the primary one, read-only) next to the target locale (editable), field by field;
  - live character counters with an over-limit state;
  - RTL text handling;
  - URL validation.
- **Keyword editor:**
  - tokens with a byte counter;
  - duplicate detection;
  - words already in the name or subtitle flagged as wasted;
  - comma/space optimization.
- **Translation:**
  - "Translate missing" per field, locale or everything;
  - provider: on-device Apple Translation, or an AI provider with App Store-optimized keyword suggestions;
  - a glossary of "do not translate" brand terms, and a tone setting;
  - suggestions shown against current text, accepted or rejected per field;
  - batch progress;
  - accepted text stays tagged "machine translated" until reviewed.
- **Fill helpers:**
  - copy from a sibling locale (en-US → en-GB/AU/CA, es-ES → es-MX, pt-PT ↔ pt-BR, fr-FR → fr-CA);
  - send What's New to every locale;
  - find and replace across locales.
- **In-app product texts:**
  - subscription display names and descriptions, subscription group names, and in-app purchase names, per locale;
  - in a matrix with the same counters.
- **Screenshots and previews:** a read-only strip per locale and device size, with missing ones flagged.
- **Import/export:** CSV, XLIFF or JSON for translators. Importing shows a diff before applying.

### 6. Review & Push (cross-cutting)

- A toolbar button showing the pending-change count opens a **review sheet**:
  - changes grouped by app → section → territory or locale;
  - each shown as old → new, with per-row discard;
  - push all, or push selected.
- **Push progress:**
  - each change moves through queued → sending → done or failed;
  - a rate-limit meter;
  - retry failed, cancel the rest.
- **Conflicts:** when a value changed in App Store Connect since the last fetch, show both and let the person choose.
- **Activity history:** timestamped pushes with a "Restore previous values" action.

### 7. Settings window

- **Account:**
  - saved keys (issuer ID, key ID, a role check);
  - test the connection;
  - remove a key, add a key.
- **Pricing defaults:**
  - pricing mode for new apps: Keep my prices, Show suggestions (the default) or Apply recommended prices;
  - use sales data (Sales and Trends, App Analytics) for suggestions, on when the key can read it;
  - base territory;
  - rounding style;
  - price index: default source, fallback chain, intensity and discount-only defaults;
  - index data: the bundled snapshot's date, automatic or manual updates, saved custom indices;
  - floor and ceiling;
  - never-raise default.
- **Translation:**
  - provider and its API key;
  - glossary;
  - default source locale.
- **General:** confirmations before pushing.

### 8. System states and polish

- Skeletons for tables.
- Banners: offline, rate-limited, API error (with Apple's detail text), and partial failure.
- Empty states:
  - no subscriptions;
  - no editable version;
  - a locale with no content;
  - no sales data (the key's role can't read reports, or too few sales), so suggestions rest on purchasing power alone;
  - too little data yet for a territory's results.
- Menu bar commands and shortcuts:
  - ⌘R refresh;
  - ⌘F search;
  - ⌘1/⌘2/⌘3 switch sections;
  - ⌘⇧P review & push.
- VoiceOver labels for table cells and status pills.

## Deliverables

1. **Design system:**
   - color tokens, named by role, with light and dark values;
   - a type scale on SF Pro and SF Mono;
   - spacing and corner radii;
   - components: territory row, price cell, delta pill, price-point stepper, status badges, pricing mode picker, suggestion cell ("feels like" price, reason, confidence badge), index source row, provenance badge, tier chip, price breakdown popover, source comparison bars, locale chip with flag, character counter, keyword token, coverage cell, drop zone, inline message, banner, inspector section, review row, progress row.
2. **Every screen and state above**, including the empty, loading, error and over-limit states, in light and dark.
3. **An interactive prototype of the main flows:**
   - connect → library;
   - translation only: "Keep my prices" → translating missing locales → reviewing (text changes only) → pushing;
   - "Show suggestions" → reading Brazil's reason and "feels like" price → "Apply recommended prices" → reviewing → pushing → the Results tab weeks later;
   - Customize…: picking the Big Mac Index (with World Bank as fallback), tuning intensity and floor, checking Brazil's breakdown and excluding Japan → reviewing → pushing.
4. **A README:** per-screen specs, the pricing formula with a worked example, how the recommendation is computed and what it can't know, the decisions you made, and anything native SwiftUI on macOS can't do as drawn.
