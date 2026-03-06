# Debug & Dev Tools

Utilities for exploring the Unnamed API, logging damage/aim events, inspecting UI objects, and dumping internal state.

| File | Description |
|------|-------------|
| `debug_utils.lua` | **Swiss-army debugger** — dumps API methods, UI flags, tabs, `getgenv()` globals; table explorer; live UI value modifier |
| `debug_damage_logger.lua` | Logs incoming/outgoing damage events to console |
| `damage_logger_debug.lua` | Alternate damage logger with extra context |
| `aim_debug_logger.lua` | Logs aim/hit events for resolver debugging |
| `aim_debug_unnamed.lua` | Unnamed-specific aim debug with API calls |
| `whitelist_debug.lua` | Dumps and verifies the ragebot whitelist state |
| `whitelist_logger.lua` | Logs all whitelist add/remove events |
| `debug_whitelist_ui.lua` | Inspects whitelist UI objects at runtime |
| `remote_dumper.lua` | Dumps remote event/function names from the game |
| `asset_id_dumper_with_names.lua` | Dumps all asset IDs with their human-readable names |
| `GripBoxDumper.lua` | Dumps grip box data for all held tools |
| `ui asset dumper.lua` | Dumps asset IDs referenced in the UI |
| `unnamed_universal_dumper.lua` | Universal dump utility (caches, flags, players, ragebot state) |
