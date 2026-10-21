# Tap d20

A d20 dice roller PWA on GitHub Pages
(https://digitalduquette.github.io/d20/). It is growing a Campaign Mode: an AI
game master for solo role-play.

## Plans and work items

- Campaign Mode design: `docs/campaign/README.md`. It is the source of truth.
  Update it when a decision changes.
- iPhone app plan: `docs/ios/README.md`.
- Work items are GitHub issues, labeled `campaign` or `ios` and grouped by
  milestone. Tick each issue's "Done when" checklist as work lands.
- Issue #33 is the Campaign Mode plan sign-off. Do not build Campaign Mode
  until it is closed.
- GitHub Project #3 ("d20", owner DigitalDuquette) tracks the issues. Use the
  `gh` CLI. The token needs the project scope: `gh auth refresh -s project`.

## How the app is built

- No build step. `index.html` is the dice app. Third-party code is vendored in
  `vendor/`. Campaign Mode code goes in ES modules under `campaign/`.
- `sw.js` is the offline cache. Bump `VERSION` and update `FILES` when a cached
  file is added or changed.
- Run locally: `python3 -m http.server 8000`, then open http://localhost:8000.
- Tests: `node --test`, no dependencies.

## Rules for Campaign Mode

- The code owns the dice, rules, turn state and saving. The AI narrates and
  proposes. Validate every AI reply before saving anything.
- One roll per check id. Save the roll before calling the AI. Re-send the same
  roll on retry.
- The AI never writes the player character's speech, thoughts, feelings or
  choices.
- The API key is user-supplied and stays on the device. Never put it in
  campaign data, exports, logs, error messages or the cache. Never commit a key.
- Public issues, docs and fixtures use made-up examples only.
- No D&D trademarks or other companies' setting content. Write mechanics in our
  own words. Copied SRD text needs CC-BY-4.0 credit (see the design doc).

## Working conventions

- Work on a branch and open a pull request. `main` deploys to the live site.
- Before pushing: run the tests and load the page locally (dice roll, offline
  cache update).
- Write plainly: conclusion first, short sentences, no em dashes, no emoji.
