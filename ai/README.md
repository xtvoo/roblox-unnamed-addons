# AI & Resolver Addons

Machine-learning, resolver, and prediction scripts for competitive play.

| File | Description |
|------|-------------|
| `aegis_ai.lua` | **Project Aegis v2.0** — Q-Learning AI that learns optimal HvH strategies (health / distance / enemy-count state space) |
| `hvh_ai_core.lua` | Core AI engine used by Aegis and the HvH helper |
| `hvh_helper.lua` | Full HvH Ragebot Helper: Cyclone/Spiral/Helix3D strafes, random jitter, fake-position detection, stomp, hit sounds |
| `hvh_helper_ultimate.lua` | Extended `hvh_helper` with additional strafe modes and performance HUD |
| `kinetic_resolver.lua` | **Kinetic Resolver** — predicts enemy movement (Linear / Accelerating / Averaged / Spline) with desync overrides |
| `anti-fakepos.lua` | **Anti-FakePos** — detects & corrects players using fake position; auto-resolves ragebot targets |
| `reslover.lua` | Lightweight resolver stub |
| `newtest.lua` | Dev/test build (experimental) |
| `newtest (1).lua` | Dev/test build copy |

### How Q-Learning works in `aegis_ai.lua`

```
State  = (health_bucket, distance_bucket, enemy_count_bucket)
Action = one of the defined HvH strategies
Reward = hit rate after applying the action
Policy = greedy ε-decay exploration → exploitation
```

Data is persisted between sessions so the AI keeps improving.
