# Changelog

## 1.1.0 — 2026-09-10

- Rebuilt specifically for TBC Anniversary 2.5.6.
- Updated TOC interface from 20505 to 20506.
- Added optional load ordering for ElvUI and Eltruism.
- Changed quest-row resolution to prefer the button's actual quest-log index.
- Added FauxScrollFrame and HybridScrollFrame fallbacks.
- Added delayed post-login initialization for Eltruism-created rows.
- Added `/qlvl debug` diagnostics.
- Scans up to 40 rows while supporting Eltruism's 24-row TBC layout.
- Removed title caching from the prior prototype.
- Keeps the addon API-safe: no override of `GetQuestLogTitle()`.

## 1.0.1

- Initial TBC-specific prototype.
