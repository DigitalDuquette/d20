# Tap d20

A d20 dice roller PWA served from GitHub Pages (https://digitalduquette.github.io/d20/), now growing a Campaign Mode: an AI game master for solo role-play.

## Where the plan lives

- Design for Campaign Mode: `docs/campaign/README.md`. It's the source of truth; update it when a decision changes.
- Native iPhone app plan: `docs/ios/README.md`.
- Work items: GitHub issues. Campaign Mode is tracking issue #32 with sub-issues #33–#58 (label `campaign`, phase labels `campaign: 0 foundations` to `campaign: 5 apple`). The iPhone plan is #1–#31 (label `ios`, `phase: 1 setup` to `phase: 8 ship`). Each issue has a "Done when" checklist; tick it as work lands.
- Milestones group issues by phase (`Campaign 0 · Foundations` … `Campaign 5 · Apple Intelligence`, `iOS 1 · Setup` … `iOS 8 · Ship`).
- Issue #33 is the plan sign-off. Don't start building Campaign Mode until it's closed.

## How the app is built

- No build step. `index.html` is the dice app; three.js is vendored in `vendor/`. Campaign Mode code goes in ES modules under `campaign/`, and third-party code is vendored the same way.
- `sw.js` is the offline cache. Bump `VERSION` and update `FILES` whenever a cached file is added or changed, or installed copies keep the old version. Navigations are network-first; other same-origin GETs are cache-first.
- Run locally: `python3 -m http.server 8000`, then open http://localhost:8000.
- Tests (once #36 lands): `node --test`, no dependencies.

## Rules for Campaign Mode

- The code owns the dice, the rules, turn state and saving. The AI narrates and proposes; every AI reply is validated before anything is saved.
- One roll per check id. Save the roll before calling the AI, and re-send the same roll on retry.
- The AI never writes the player character's speech, thoughts, feelings or choices.
- The API key is user-supplied and stays on the device. Never put it in campaign data, exports, logs, error messages or the service-worker cache. Never commit a key.
- Public issues, docs and test fixtures use made-up examples only. The owner's real campaigns and characters stay out of the repo.

## Working conventions

- Work on a branch and open a pull request; `main` deploys to the live site.
- Before pushing: run the tests, and load the page locally to check nothing broke (dice roll, offline cache update).
- Write plainly in docs, issues and UI copy: conclusion first, short sentences, no em dashes, no emoji, no filler words.
