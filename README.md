# Kaliel's Tracker Fork for WoW MoP Classic

## Disclaimer

I'm not the original author of this addon. I'm just contributing to fix it.

## Additional feature

- Functionnal quest item bar, with more options to position it.
- More sounds to play on quest completion.

More info in the section **6.0.0** of the [CHANGELOG](!KalielsTracker/CHANGELOG.md).

## Tested Version

- Mist of Pandaria Classic 5.5.4.70032
- - With and without Questie addon

## Development tools

### Task

The project contains a Visual Studio Code task that copy the content of this addon to WoW addon's folder. Be sure it's correctly setup to the relevant path on your computer in the [*tasks.json*](.vscode/tasks.json) file.

### WoW Addon

- Addon [DebugLog](https://www.curseforge.com/wow/addons/debuglog) v1.3.3 by **Expelliarm5s** : used to debug message ingame.
- Addon [BugGrabber](https://www.curseforge.com/wow/addons/bug-grabber) v12.1.0 and [BugSack](https://www.curseforge.com/wow/addons/bugsack) v12.1.2 by **Funkeh** : used to catch lua errors ingame.

### VS Code extension

- [Lua Language Server](https://marketplace.visualstudio.com/items?itemName=sumneko.lua)
- [WoW API](https://marketplace.visualstudio.com/items?itemName=ketho.wow-api)
- [WoW TOC](https://marketplace.visualstudio.com/items?itemName=stanzilla.vscode-wow-toc)