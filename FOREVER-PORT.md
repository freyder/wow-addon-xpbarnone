# XPBarNone WoW Forever port

This document records every intentional difference between XPBarNone Forever
and its upstream baseline, and explains why each difference exists.

## Provenance

- Upstream repository: <https://github.com/maluramichael/wow-addon-xpbarnone>
- Baseline commit: `93e5f850a655ce2ed3ddea6a4cf904f237116f80`
- Baseline date: 2026-09-28
- Upstream lineage: originally written by phyber and later maintained by
  Michael Malura
- WoW Forever port: OpenAI Codex
- Direction, assistance, and prompting: Rob Freyder
- Forever interface tested: `16001`

The installed folder and add-on identity remain `XPBarNone`. The saved-variable
database remains `XPBarNoneDB`, allowing existing profiles to carry forward.

## Why a port is necessary

WoW Forever combines two characteristics that upstream XPBarNone did not
model together:

1. Its gameplay and progression resemble vanilla WoW.
2. Its UI runtime is derived from the modern 12.1 client.

Treating Forever as Retail enables systems that do not belong in Forever,
while treating it as an old Classic client calls global APIs that the modern
runtime removed. Changing the TOC interface number alone allows the addon to
load but does not make it function correctly.

## Code and metadata changes

### Forever client detection

`Core.lua` recognizes interface versions from 16000 through 19999 as Forever.
`IsRetailContent()` distinguishes actual Retail gameplay from a modern runtime
hosting Forever content.

Reason: `WOW_PROJECT_ID` alone does not accurately describe this combination
of engine and content. A separate predicate prevents entry into Retail-only
code.

### Reputation API adapter

The following removed global APIs are wrapped:

- `GetNumFactions`
- `GetFactionInfo`
- `GetFactionInfoByID`
- `GetWatchedFactionInfo`
- `SetWatchedFactionIndex`
- `CollapseFactionHeader`
- `ExpandFactionHeader`

When the original globals exist, XPBarNone still calls them. On Forever, the
wrappers use `C_Reputation` and translate its table-shaped results into the
legacy return tuples expected by the rest of XPBarNone.

Reason: translating at one boundary is smaller and safer than rewriting every
consumer in the mature upstream code, and retains compatibility with older
clients.

### Retail-only feature gating

Azerite, guild-reputation, friendship, paragon, and major-faction paths now use
`IsRetailContent()` rather than assuming every modern runtime is Retail.

Reason: those systems are absent from Forever. Calling them can produce nil
accesses, irrelevant settings pages, or incorrect bar selection.

### Maximum-level selection

Forever prefers the engine-provided maximum-level helper and falls back to 60.
Unknown Classic-like flavors receive the same safe fallback.

Reason: the old Classic expansion table does not reliably describe Forever,
while a hard failure during initialization would prevent the bar from loading.

### Number separator compatibility

The non-Retail formatter accepts both the historical misspelling
`LARGE_NUMBER_SEPERATOR` and the corrected `LARGE_NUMBER_SEPARATOR`, with a
comma as the final fallback.

Reason: global naming differs across Blizzard runtime generations.

### Modern Settings navigation

The category ID returned by AceConfigDialog is retained and passed to
`Settings.OpenToCategory` for `/xpbn` and Shift-right-click.

Reason: the modern Settings API no longer reliably opens an addon category by
its display title, particularly when the title contains color markup.

### General-page media selectors

The font and status-bar selectors build their choices directly from
`LibSharedMedia-3.0`.

Reason: upstream referenced the global `AceGUIWidgetLSMlists`, which belongs to
a separate widget package that XPBarNone did not ship. The General page
therefore crashed unless another addon happened to define it first. Standard
AceConfig dropdowns remove that hidden load-order dependency.

### AceGUI checkbox compatibility

The packaged AceGUI CheckBox widget is version 27. It uses
`Texture:SetDesaturated()` instead of the removed global `SetDesaturation()`.

Reason: version 26 generated an error for every toggle on the General page,
leaving the page incomplete even after the media-selector failure was fixed.
Release packaging must use an Ace3 version containing widget version 27 or
newer.

### Prototype font

`Fonts/Prototype.ttf` is registered as `Prototype` with LibSharedMedia.

Reason: this makes the preferred font available without relying on EllesmereUI
or another addon to register it first. It is an optional presentation choice,
not an XPBarNone logic change. The font is by Justin Callaghan, is not covered
by Apache-2.0, and must be accompanied by `Fonts/Prototype.txt` whenever it is
redistributed.

### Fresh-profile defaults

Fresh profiles enable XP bubble markers and use this XP display string:

`Level [pLVL]   XP=[curXP]/[maxXP]     Rest=[restXP]/[restPC]         [curPC] to lvl [nLVL]        [needXP] XP to Ding!`

Reason: these settings were recovered from the known-good TBC/Anniversary
profile used during the port. They are intentional default-setting changes,
not new functionality. Users can change both in `/xpbn`, and existing profiles
are not overwritten.

### TOC and attribution metadata

The TOC targets interface 16001, identifies the package as the Forever port,
retains phyber and Michael Malura's credits, and adds OpenAI Codex and Rob
Freyder attribution. The upstream CurseForge project ID is deliberately absent.

Reason: a derivative package must not identify itself as the upstream
maintainer's CurseForge project. A new ID can be added after this fork receives
its own CurseForge listing.

## Things deliberately not changed

- XP calculation and token replacement logic
- Reputation progress calculation
- Bar dragging, sizing, coloring, texture, and profile behavior
- Saved-variable database name and schema
- Slash command name
- Localization structure

The port is a compatibility layer with two intentional default changes, not a
redesign.

## Validation performed

- Addon loads on Forever interface 16001.
- XP bar renders and updates in game.
- `/xpbn` opens the registered Settings category.
- General, XP, reputation, color, menu, and profile categories render.
- General-page toggles no longer trigger the obsolete checkbox error.
- Font and texture dropdowns populate without an undeclared widget package.
- Prototype appears as a selectable font.
- Existing `XPBarNoneDB` settings remain usable.

## Release requirements

1. Package the directory as `XPBarNone`, not `XPBarNone-Forever`.
2. Include `LICENSE`, `NOTICE`, and `Fonts/Prototype.txt`.
3. Include current embedded Ace3, LibQTip, and LibSharedMedia libraries.
4. Verify that the embedded AceGUI CheckBox widget is version 27 or newer.
5. Mark the release for WoW Forever interface/game version 16001/1.60.1.
6. Do not reuse the upstream CurseForge project ID.
