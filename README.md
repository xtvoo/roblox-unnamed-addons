# UUE Scripts — Da Hood Unnamed Executor Addon Collection

A curated collection of Lua addons for the **Unnamed executor** in Da Hood (Roblox).  
Everything is built against the [Unnamed API](https://ue0-1.gitbook.io/ue-docs).

---

## Folder Map

| Folder | Description |
|--------|-------------|
| [`combat/`](./combat/) | Auto-bag, auto-kill, auto-arrest, stomp & grab mechanics |
| [`movement/`](./movement/) | NaN fling, seat fling, bring, strafe, slide, teleport |
| [`ai/`](./ai/) | Q-learning AI, HvH helper, resolvers, anti-fakepos |
| [`ragebot/`](./ragebot/) | Whitelist manager, desync visuals, crew targeting |
| [`visuals/`](./visuals/) | ESP, chams, china hat, cinematic camera, graphics mods |
| [`utility/`](./utility/) | Loader, AFK farm, music player, avatar tools, misc QoL |
| [`skins/`](./skins/) | Skin changers and skin ID dumpers |
| [`debug/`](./debug/) | API explorers, damage loggers, whitelist debuggers |
| [`dumper/`](./dumper/) | Full UE state dumper suite (flags, caches, players, ragebot) |
| [`_archive/`](./_archive/) | Old drafts, txt notes, disabled/duplicate scripts |

---

## Quick Start

1. Open **Volt** executor
2. Navigate to your workspace → `scripts/<category>/`
3. Load any `.lua` file containing `-- @addon` or drop it into *Addons* tab
4. Addons that require **Linoria UI** auto-create their tabs inside Unnamed's menu

> **Note:** Scripts in `_archive/` are kept for reference only — some may not run.

---

## Resources

- Unnamed API docs: <https://ue0-1.gitbook.io/ue-docs>
- UE Dump files: see `UE_Dumps/` in the parent workspace folder
- GitHub: <https://github.com/xtvoo/uue-docs>
