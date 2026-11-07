# XPBarNone

## Unreleased

### Fixed
- Auto-watch reputation works without floating combat text for reputation,
  and also finds factions under collapsed headers
- [KTL] counts only kill XP, so quests and exploration no longer skew it
- [KTL] uses the median of the last ten kills without rested bonus, accounts
  for the rested pool, adapts when the mobs change, updates right after each
  kill and keeps its history across /reload
- [KTL] no longer counts existing XP as a kill after login, and shows "?"
  instead of NaN before the first kill
- Secret reputation values on WoW Forever no longer raise errors
- The bar keeps its position when another addon changes the UI scale
  (e.g. EllesmereUI)

## 100002-9 (2026-11-06)

### Added
- WoW Forever support (interface 16001), contributed by Rob Freyder (@freyder)
  - Reputation functions emulated on top of `C_Reputation`
  - Retail-only features (Azerite, guild rep, paragon, renown) stay disabled

### Fixed
- Texture and font dropdowns no longer depend on AceGUI-3.0-SharedMediaWidgets
  being loaded by another addon
- `/xpbn` and Shift-Right-Click open the options via the settings category ID

## [100002-1](https://github.com/phyber/XPBarNone/tree/100002-1) (2022-12-03)
[Full Changelog](https://github.com/phyber/XPBarNone/commits/100002-1) [Previous Releases](https://github.com/phyber/XPBarNone/releases)

- Update luacheckrc  
