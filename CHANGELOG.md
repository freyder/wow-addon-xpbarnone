# XPBarNone

## 100002-8-forever.1 (2026-10-21)

Initial WoW Forever compatibility release.

- Target Forever interface 16001 and distinguish its modern engine from its
  vanilla-content ruleset.
- Adapt the removed legacy reputation functions to `C_Reputation` while
  retaining XPBarNone's internal tuple-based behavior.
- Keep Retail-only Azerite and modern reputation systems disabled on Forever.
- Use the current Settings category ID for `/xpbn` and Shift-right-click.
- Replace the undeclared `AceGUIWidgetLSMlists` dependency with direct
  LibSharedMedia font and status-bar choices.
- Update the bundled AceGUI checkbox widget from version 26 to version 27 for
  the modern `Texture:SetDesaturated` API.
- Add the separately licensed Prototype font as an optional font selection.
- Seed fresh profiles with the recovered TBC-style XP text and bubble markers.
- Preserve the original `XPBarNoneDB` saved-variable name and profile format.

## [100002-1](https://github.com/phyber/XPBarNone/tree/100002-1) (2022-12-03)
[Full Changelog](https://github.com/phyber/XPBarNone/commits/100002-1) [Previous Releases](https://github.com/phyber/XPBarNone/releases)

- Update luacheckrc  
