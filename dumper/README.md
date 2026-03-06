# UE Dumper Suite

Full Unnamed Executor state dumper — exports everything to timestamped files in `UE_Dumps/`.

| File | Description |
|------|-------------|
| `UE_Dumper.lua` | **Main dumper** — dumps flags, caches, players, ragebot/desync state to separate files |
| `UE_Linoria_Dumper.lua` | Linoria-UI–integrated dumper with toggle controls inside the Unnamed menu |

## Output Files (written to `UE_Dumps/`)

| Filename | Contents |
|----------|----------|
| `UE_Dump_full_<timestamp>.txt` | Complete API snapshot |
| `UE_Dump_flags_<timestamp>.txt` | All UI flags (options & toggles) with current values |
| `UE_Dump_caches_<timestamp>.txt` | Internal cache state |
| `UE_Dump_players_<timestamp>.txt` | Current player list with metadata |
| `UE_Dump_ragebot_desync_<timestamp>.txt` | Ragebot + desync configuration snapshot |

## Usage

1. Load `UE_Dumper.lua` as an addon
2. Open the **Dumper** tab in the Unnamed menu
3. Click the dump button — files appear in your `UE_Dumps/` workspace folder
