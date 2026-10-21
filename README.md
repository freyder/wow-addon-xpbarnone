# XPBarNone Forever

XPBarNone Forever is a compatibility port of XPBarNone for World of Warcraft:
Forever. It supplies a compact, configurable experience and reputation bar
while retaining the behavior and saved-variable format of the upstream addon.

This port targets Forever interface `16001`, whose vanilla game content runs
on Blizzard's modern 12.1 UI engine. That combination requires compatibility
work beyond simply changing the interface number.

## Installation

Extract the release archive into:

`World of Warcraft/_classic_beta_/Interface/AddOns/`

The installed directory must be named `XPBarNone`. Configure the addon with
`/xpbn`, or Shift-right-click its bar. Existing `XPBarNoneDB` profiles remain
compatible.

## Forever compatibility

The port:

- detects Forever separately from Retail and the older Classic clients;
- translates removed legacy reputation APIs to `C_Reputation`;
- avoids Retail-only Azerite, paragon, major-faction, and friendship paths;
- opens configuration through the modern Settings category API;
- repairs the General page for current Ace3 and Blizzard checkbox APIs; and
- includes the Prototype font as an optional LibSharedMedia selection.

No new XP or reputation tracking system was added. The underlying XPBarNone
behavior remains upstream's; most changes are compatibility adapters. Fresh
profiles do use the tested TBC-style XP text and enable ten bubble markers by
default. Both are ordinary settings and can be changed in `/xpbn`.

Technical details and the reasoning for every change are in
[FOREVER-PORT.md](FOREVER-PORT.md).

## Credits and license

- Original XPBarNone author: phyber
- Upstream maintainer: Michael Malura
- WoW Forever port: OpenAI Codex
- Direction, assistance, and prompting: Rob Freyder

XPBarNone and this derivative are distributed under the Apache License 2.0;
see [LICENSE](LICENSE) and [NOTICE](NOTICE). The bundled Prototype font was
created by Justin Callaghan and has separate redistribution terms in
`Fonts/Prototype.txt`.

## Upstream project and feature reference

<!-- links:start -->
[![Support me on Ko-fi](https://malura.de/assets/badge/kofi.svg)](https://malura.de/go/kofi?ref=wow-addon-xpbarnone)
[![Check out my page](https://malura.de/assets/badge/malura.svg)](https://malura.de/go/site?ref=wow-addon-xpbarnone)
[![CurseForge](https://malura.de/badge/curseforge/xpbarnone-tbc.svg)](https://www.curseforge.com/wow/addons/xpbarnone-tbc)
<!-- links:end -->

_XPBarNone_ is an XP bar addon for [World of Warcraft]. The bar can switch
between XP, Reputation, and [Heart of Azeroth] progress depending on your
settings.

## Experience Bar

The Forever port's default string used to create the XP Bar is:
`Level [pLVL]   XP=[curXP]/[maxXP]     Rest=[restXP]/[restPC]         [curPC] to lvl [nLVL]        [needXP] XP to Ding!`

This can be replaced with any combination of the tokens below. The upstream
default, for example, includes `[KTL]`; that estimate can be inaccurate after
quest or exploration XP, so the Forever default omits it.

The available replacements are:

Token      | Description
-----------|------------
`[curXP]`  | Current amount of XP.
`[maxXP]`  | XP  needed to progress to the next level.
`[restXP]` | Amount of rested XP.
`[restPC]` | Amount of rested XP displayed as a percentage, the maximum amount of rested XP is 150%.
`[curPC]`  | Your progress through the current level, displayed as a percentage.
`[needPC]` | The amount of XP you need to progress to the next level.  As a percentage.
`[pLVL]`   | Your current level.
`[nLVL]`   | The next level.
`[mLVL]`   | Maximum level.
`[needXP]` | The amount of XP remaining until you level.
`[KTL]`    | The amount of kills needed to level. (Can be inaccurate, for example, if you just got 10000 XP for handing a quest in)
`[BTL]`    | Bars/Bubbles to level.  Since some people like to announce their progress this way.

## Reputation Bar

The default string used to create the Reputation bar is:
`Rep: [faction] ([standing]) [curRep]/[maxRep] :: [repPC]`

This would be displayed as something like the following:
`Rep: Sporeggar (Honored) 9000/12000 :: 75.0%`

The available replacements are:

Token        | Description
-------------|------------
`[faction]`  | Name of the current watched faction, eg.  Stormwing City, Sporeggar, The Consortium
`[standing]` | Current standing with the watched faction, eg. Hated, Friendly, Exalted.
`[curRep]`   | Amount of reputation you have earned at the current standing.
`[maxRep]`   | Reputation needed to progress to the next level.
`[repPC]`    | Your progress through the current standing, displayed as a percentage.
`[needRep]`  | Shows how many more rep points you need for the next rep level.
`[needPC]`   | Shows how much more reputation you need to progress to the next level as a percentage.

## Azerite Bar (Heart of Azeroth)

The default string used to create the Azerite Bar is:
`[name]: [curXP]/[maxXP] :: [curPC] through level [pLVL] :: [needXP] AP left`

This would be displayed as the following:
`Heart of Azeroth: 30/6,730 :: 0.4% through level 48 :: 6,700 AP left`

The available replacements are:

Token      | Description
-----------|------------
`[name]`   | Localized item name for the [Heart of Azeroth]
`[curXP]`  | Current amount of XP.
`[maxXP]`  | XP  needed to progress to the next level.
`[curPC]`  | Your progress through the current level, displayed as a percentage.
`[needPC]` | The amount of XP you need to progress to the next level.  As a percentage.
`[pLVL]`   | Current Heart of Azeroth level.
`[nLVL]`   | Next Heart of Azeroth level.
`[needXP]` | The amount of XP remaining until the next level.

<!-- Document links -->
[Heart of Azeroth]: https://www.wowhead.com/item=158075/heart-of-azeroth
[World of Warcraft]: https://worldofwarcraft.com/
