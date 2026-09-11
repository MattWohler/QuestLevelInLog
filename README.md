# Quest Level in Log — TBC Anniversary

A small addon for **World of Warcraft: The Burning Crusade Classic Anniversary**
that displays a quest's level in square brackets before its name in the main
quest log.

This addon was created as the quest logs' quest level were removed with the new Quest Log UI after installing the ElvUI.

Example:

```text
Alterac Mountains
  [33] Syndicate Assassins
  [34] Letter to Stormpike

Stranglethorn Vale
  [34] Tiger Mastery
```

## Target

This build is specifically for:

- Burning Crusade Classic Anniversary **2.5.6**
- AddOn interface **20506**
- ElvUI **15.26**
- Eltruism **5.1.4**

ElvUI and Eltruism are optional. The addon operates on Blizzard's
`QuestLogTitle` rows and therefore does not edit either addon.

## Installation on macOS

Extract the archive so this exact file exists:

```text
World of Warcraft/_anniversary_/Interface/AddOns/QuestLevelInLog/QuestLevelInLog.toc
```

Do **not** leave an extra directory layer such as:

```text
.../AddOns/QuestLevelInLog-TBC-Anniversary-1.1.0/QuestLevelInLog/...
```

The ZIP is packaged so extracting it directly into `AddOns` creates the
correct `QuestLevelInLog` folder.

At the character-selection screen, open **AddOns** and verify
**Quest Level in Log** is listed and enabled. Then enter the game and run:

```text
/reload
```

## Commands

```text
/qlvl
/qlvl on
/qlvl off
/qlvl status
/qlvl debug
```

`/qlvl debug` prints client/build information and reports whether the quest-log
frames/buttons were found. If levels do not appear, open the Quest Log first,
run `/qlvl debug`, and copy the chat output and create an issue.

## Design

- Uses `## Interface: 20506`.
- Hooks `QuestLog_Update` after Blizzard/Eltruism repaint the log.
- Prefers each `QuestLogTitle` button's actual `GetID()` quest index.
- Falls back to the visible row + scroll offset if needed.
- Leaves zone/category headers alone.
- Does not monkey-patch `GetQuestLogTitle()`.
- Does not alter ElvUI or Eltruism source files.
