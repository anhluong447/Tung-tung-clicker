---
name: game-dev-methodology
description: >
  Use this skill whenever building, planning, or reviewing a game project. Covers
  the full professional game development pipeline: pre-production (GDD, prototyping),
  production (architecture, game feel/juice, iteration), monetization (ad placement
  strategy, eCPM optimization), and Godot-specific patterns (AutoLoad, scene
  composition, mobile export). Trigger on any task involving game design documents,
  core loop design, scene architecture, ad integration, playtesting, or polish passes.
  Also triggers for: "make this feel better", "add juice", "optimize for mobile",
  "set up save system", "integrate ads", "improve retention".
---

# Game Development Methodology — Professional Pipeline

This skill encodes the professional game development pipeline adapted for
AI coding agents working on mobile games, specifically Godot 4.x.
Sources: GDC, Game Developer Magazine, GameAnalytics, Tenjin Ad Benchmark
Reports 2024–2026, Godot official docs, Vlambeer "Art of Screenshake".

---

## PHASE 0 — BEFORE WRITING ANY CODE: THE NORTH STAR CHECK

Before generating any scene, script, or asset, answer these three questions
from the GDD/plan file provided by the user:

1. **What is the core loop?** (The single repeating action that earns the
   primary resource. Everything else serves this loop.)
2. **What is the first 60-second experience?** (The player should feel
   reward within the first minute. If they don't, retention dies.)
3. **Where do ads appear relative to the loop?** (Ads must sit at natural
   break points — never interrupt the core loop itself.)

If the plan file answers these, proceed. If not, output a 3-question
clarification block and halt.

---

## PHASE 1 — PRE-PRODUCTION

### 1.1 Game Design Document (GDD) Standards

A GDD is the single source of truth. All implementation decisions trace back
to it. Professional practice (Game Developer Magazine, 2024):

- **Keep it living**: GDD updates as the game evolves. Never treat it as
  frozen.
- **Structure required sections**:
  - Core concept (1 paragraph max — the "elevator pitch")
  - Core loop diagram (tap → earn → spend → loop)
  - Player progression path (milestones at minute 1, hour 1, day 1, week 1)
  - Character/content roster with tiers
  - Monetization model (which actions trigger which ad types)
  - Technical constraints (target devices, minimum Android API, FPS target)
  - Art direction (style reference, palette, animation requirements)
  - Audio direction (BGM mood, SFX inventory)
- **Anti-patterns to reject**:
  - Feature lists with no prioritization
  - Mechanics described without player motivation
  - Ad placement described as "show ads sometimes"

### 1.2 Prototyping Principle (Minimum Viable Loop)

Build the core loop first — nothing else. Industry standard (GDC talks,
Vlambeer, Rami Ismail):

> "If the core loop isn't fun with placeholder cubes and no sound, adding
> art won't save it."

**MVP order for a clicker/idle game:**
1. Tap input → number goes up (test this alone first)
2. Number is displayed and updates every frame
3. One idle income source ticks passively
4. One purchase that increases tap power
5. Save/load persists between app restarts

Only after this loop works and *feels satisfying* do you add characters,
UI polish, ads, quests, or audio.

**Vertical slice**: Before full production, build one complete slice of
content — e.g., Tier 1 character fully implemented with all systems working.
Use it as the template for all future content.

---

## PHASE 2 — GODOT 4 ARCHITECTURE PATTERNS

### 2.1 AutoLoad (Singleton) Architecture

AutoLoads are Godot's global singleton system. Use them correctly or the
project will become unmaintainable.

**What to put in AutoLoads (max 5–8 total):**
```
GameManager.gd    — coins, CPS, global state, game loop tick
SaveManager.gd    — read/write user://save.json, auto-save timer
AudioManager.gd   — BGM crossfade, SFX pool playback
AdManager.gd      — AdMob wrapper, ad state, cooldown tracking
SignalBus.gd      — decoupled event bus (see 2.2)
```

**Critical AutoLoad rules** (Godot official docs + community consensus):
- NEVER access AutoLoads in `_init()` — they may not exist yet. Use
  `_ready()` instead.
- NEVER create circular dependencies between AutoLoads (A needs B, B needs
  A = deadlock at splash screen).
- NEVER store scene-specific state in AutoLoads (they persist across scene
  changes — storing "current enemy count" causes leaks).
- NEVER put UI nodes in AutoLoads unless they are truly global (e.g.,
  transition overlay). Popups that belong to one screen stay in that scene.
- MAX 5–10 AutoLoads. More = "God Object" anti-pattern, tight coupling,
  debugging nightmare.

**AutoLoad initialization order matters.** In Project Settings, list them
in dependency order: SignalBus first, then GameManager (which may emit
signals), then SaveManager, then AdManager.

### 2.2 Signal Bus Pattern (Decoupled Communication)

Nodes should NOT hold direct references to other nodes across scenes.
Use a central SignalBus AutoLoad instead:

```gdscript
# SignalBus.gd (AutoLoad)
signal coins_changed(new_amount: float)
signal character_unlocked(character_id: String)
signal ad_reward_granted(reward_type: String)
signal offline_earnings_ready(amount: float)

# Emitter (GameManager.gd)
SignalBus.coins_changed.emit(coins)

# Receiver (HUD.gd — no reference to GameManager needed)
func _ready():
    SignalBus.coins_changed.connect(_on_coins_changed)
```

This pattern allows any scene to be opened standalone in the editor
without crashing due to missing node references.

### 2.3 Scene Composition Rules

Godot's scene system is its superpower. Use it correctly:

- **Every reusable UI element is its own .tscn** (CharacterSlot,
  ShopCard, QuestEntry). Instantiate via code or editor, never duplicate.
- **Scenes should be self-contained**: a CharacterSlot scene should
  work if you open it alone in the editor. No hard-coded paths to
  sibling nodes.
- **Communicate upward via signals, downward via method calls**:
  - Parent calls child method: `$CharacterSlot.set_character(data)`
  - Child reports to parent via signal: `character_tapped.emit(id)`
  - Cross-scene communication via SignalBus only.
- **Separate logic from presentation**: GameManager holds numbers.
  HUD reads numbers and renders them. HUD never modifies numbers.

### 2.4 Resource (.tres) Pattern for Data

Game data (characters, upgrades, items) should be Godot Resources, not
hardcoded in scripts:

```gdscript
# CharacterData.gd
class_name CharacterData
extends Resource

@export var id: String
@export var display_name: String
@export var rarity: int
@export var base_cps: float
@export var tap_bonus: float
@export var unlock_cost: float
@export var merge_result_id: String
@export var idle_animation: String
@export var sfx_tap: AudioStream
@export var description: String
```

Create `.tres` files for each character in `res://resources/characters/`.
Load with `preload()` or `ResourceLoader.load()`. This makes adding new
content a data task, not a code task.

### 2.5 Mobile Performance Targets (Godot 4)

Target minimum spec: mid-range Android 2021 (Snapdragon 680 class).

- **Target 60 FPS** in gameplay. Never drop below 30.
- Use Godot's built-in profiler (Debugger > Profiler) to identify
  bottlenecks before optimizing blindly.
- **_process() vs _physics_process()**:
  - Use `_process(delta)` for: idle income accumulation, UI updates,
    non-physics animations, cooldown timers.
  - Use `_physics_process(delta)` only if you have actual physics.
  - Idle/clicker games need almost no physics — stay in `_process`.
- **Object pooling for particles and floating labels**: Don't
  `instantiate()` and `queue_free()` on every tap. Pre-spawn a pool of
  10–20 nodes and recycle them.
- **Avoid per-frame string operations**: Don't format the coin counter
  string every frame. Update it only when coins actually change (via
  signal).
- **Texture atlases**: Pack small UI sprites into atlases. Reduces
  draw calls significantly on mobile.
- **Audio**: Use `.ogg` for BGM (streamed), `.wav` for short SFX
  (loaded into memory). Limit simultaneous SFX to 8–12 channels.

---

## PHASE 3 — GAME FEEL ("JUICE")

Game feel is the collection of feedback effects that make every player
action feel impactful and satisfying. Industry term: "juice."
Source: Vlambeer "Art of Screenshake" (GDC), GameAnalytics Blog.

> "Juice is what separates a game that feels like clicking a spreadsheet
> from one that feels like popping bubble wrap."

### 3.1 The Juice Stack (apply in this order)

For every major player action (tap, unlock, merge, quest complete):

**Layer 1 — Instant visual feedback (< 1 frame)**
- Sprite scale punch: scale to 1.2 → back to 1.0 over 0.1s
- Color flash: briefly tint white/yellow then restore

**Layer 2 — Particle effect (0–0.3s)**
- Burst of 8–16 particles from tap position
- Coin particles for currency actions
- Star/sparkle for unlock/merge

**Layer 3 — Floating label (0–0.5s)**
- "+1,234" rises from tap point and fades out
- Scale in → float up → fade out (tween)
- Font: bold, large, contrasting color

**Layer 4 — Audio (simultaneous with action)**
- Short SFX (< 0.3s) fires immediately on tap
- Use a pool of 5+ variations, play randomly to avoid repetition fatigue

**Layer 5 — Screen effect (big events only)**
- Screen shake: 0.1–0.2s, amplitude 4–8px, for merge/unlock only
- NOT on every tap — overuse kills the effect
- Godot implementation: offset Camera2D position with noise then lerp back

**Layer 6 — UI animation (for major events)**
- Character bounces when tapped
- Coin counter "punches" scale when value changes
- Unlock panel slides in with overshoot easing

### 3.2 Juice Anti-Patterns to Avoid

- Screen shake on every tap → player goes numb in 30 seconds
- Particles so dense they obscure the UI → accessibility issue
- Floating labels that cover the tap target → frustrating
- SFX with no variation → "why does this game sound like a printer"
- Juice with no core loop → looks good, feels empty after 5 minutes

> "Juice should reinforce your core gameplay, not replace it." — GameAnalytics

### 3.3 Godot Juice Implementation Snippets

**Scale punch (attach to any node):**
```gdscript
func punch_scale(node: Node2D, strength: float = 0.25, duration: float = 0.12):
    var tween = create_tween()
    tween.tween_property(node, "scale", Vector2.ONE * (1.0 + strength), duration * 0.4)\
         .set_ease(Tween.EASE_OUT)
    tween.tween_property(node, "scale", Vector2.ONE, duration * 0.6)\
         .set_ease(Tween.EASE_IN_OUT)
```

**Floating label:**
```gdscript
func spawn_tap_label(pos: Vector2, amount: float):
    var label = tap_label_pool.get()  # get from pool
    label.text = "+%s" % format_number(amount)
    label.position = pos
    label.modulate.a = 1.0
    var tween = label.create_tween()
    tween.tween_property(label, "position:y", pos.y - 80, 0.6)
    tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6)\
         .set_delay(0.2)
    tween.tween_callback(tap_label_pool.recycle.bind(label))
```

**Screen shake (Camera2D):**
```gdscript
var shake_intensity: float = 0.0
var shake_decay: float = 8.0

func shake(intensity: float = 6.0):
    shake_intensity = intensity

func _process(delta):
    if shake_intensity > 0.1:
        offset = Vector2(
            randf_range(-shake_intensity, shake_intensity),
            randf_range(-shake_intensity, shake_intensity)
        )
        shake_intensity = lerp(shake_intensity, 0.0, shake_decay * delta)
    else:
        shake_intensity = 0.0
        offset = Vector2.ZERO
```

---

## PHASE 4 — SAVE SYSTEM STANDARDS

### 4.1 Save Architecture

Use JSON for human-readable saves on mobile. Binary (`PackedByteArray`)
is faster but harder to debug.

```gdscript
# SaveManager.gd (AutoLoad)
const SAVE_PATH = "user://save.json"
const SAVE_VERSION = 1
const AUTO_SAVE_INTERVAL = 30.0  # seconds

var _save_timer: float = 0.0

func _process(delta):
    _save_timer += delta
    if _save_timer >= AUTO_SAVE_INTERVAL:
        _save_timer = 0.0
        save_game()

func save_game() -> void:
    var data = GameManager.get_save_data()
    data["version"] = SAVE_VERSION
    data["timestamp"] = Time.get_unix_time_from_system()
    var json_string = JSON.stringify(data, "\t")
    var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        file.store_string(json_string)
        file.close()

func load_game() -> Dictionary:
    if not FileAccess.file_exists(SAVE_PATH):
        return get_default_save()
    var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not file:
        return get_default_save()
    var json = JSON.new()
    var result = json.parse(file.read_as_text())
    file.close()
    if result != OK:
        push_error("Save file corrupted. Loading defaults.")
        return get_default_save()
    return migrate_save(json.get_data())
```

### 4.2 Save Migration

Always version saves. When you add new fields, migrate old saves:

```gdscript
func migrate_save(data: Dictionary) -> Dictionary:
    var version = data.get("version", 0)
    if version < 1:
        # v0 → v1: add shards field
        data["shards"] = {}
    # future: if version < 2: ...
    data["version"] = SAVE_VERSION
    return fill_missing_with_defaults(data)
```

### 4.3 Offline Earnings Calculation

```gdscript
func calculate_offline_earnings() -> float:
    var last_time = GameManager.save_data.get("timestamp", 0)
    var now = Time.get_unix_time_from_system()
    var offline_seconds = min(now - last_time, 8 * 3600)  # cap at 8h
    return GameManager.total_cps * offline_seconds * 0.5  # 50% efficiency offline
```

---

## PHASE 5 — AD MONETIZATION (Mobile Game Standard)

Sources: Tenjin Ad Benchmark 2024–2026, GameAnalytics, MonetizeMore
AdMob Playbook 2026, MAF Rewarded Ads Report 2026.

### 5.1 Ad Format Hierarchy (by eCPM, highest to lowest)

| Format         | Avg eCPM (US, Android) | Player Sentiment    |
| -------------- | ---------------------- | ------------------- |
| Rewarded Video | $11–20                 | Positive (opt-in)   |
| Interstitial   | $8–14                  | Neutral (tolerated) |
| Banner         | $0.50–2.50             | Negative (ignored)  |

**Key insight**: Players prefer rewarded ads over interstitials 4-to-1.
Rewarded generate 2–3x higher eCPMs than interstitials. Maximize rewarded,
minimize interstitial, never use standalone banners in gameplay.

### 5.2 Rewarded Ad Best Practices

**Placement**: at natural decision points where player wants something.
Best performing triggers (in order):
1. Double offline earnings on app resume
2. Extra lives / continue
3. Temporary multiplier (x2 earnings for 10 min)
4. Free coins pack (refresh every 4 hours)
5. Character shard / unlock assist
6. Daily quest reward doubler

**Frequency**: casual games, cap at 6–10 rewarded views/session, 15–20/day.
Beyond this, completion rates drop and retention suffers.

**Reward sizing**: reward must feel worth the 30-second watch.
- Too small: player ignores the prompt
- Too large: devalues the in-game economy
- Rule: reward ≈ 5–10 minutes of normal play

**Completion rate target**: above 85%. If below, the ad quality or
placement is wrong.
**Opt-in rate target**: above 30%. If below, the reward offer is too weak
or poorly surfaced.

### 5.3 Interstitial Ad Best Practices

**Timing**: only at genuine natural transitions. Best triggers:
1. After unlock celebration animation completes
2. After returning from background (>5 min away)
3. After completing a quest

**Frequency cap**: hard minimum 3 minutes between interstitials.
Never stack two ads back to back.

Poor timing reduces Day 7 retention by 10–25% (MonetizeMore 2026).
An interstitial shown mid-tap session will cause uninstalls.

**Rule**: if the player is in the middle of doing anything, don't show it.

### 5.4 AdManager.gd Architecture

```gdscript
# AdManager.gd (AutoLoad)
# Replace with real AdMob plugin calls. Stub for dev:

signal rewarded_ad_earned(reward_type: String)
signal rewarded_ad_failed
signal interstitial_shown

const MIN_INTERSTITIAL_INTERVAL = 180.0  # 3 minutes
var _last_interstitial_time: float = -999.0
var _rewarded_loaded: bool = false
var _interstitial_loaded: bool = false

func _ready():
    load_rewarded_ad()
    load_interstitial_ad()

func load_rewarded_ad() -> void:
    # AdMob plugin call here
    # On success: _rewarded_loaded = true
    pass

func show_rewarded_ad(reward_type: String) -> void:
    if not _rewarded_loaded:
        rewarded_ad_failed.emit()
        return
    # AdMob plugin show call
    # On reward earned callback: rewarded_ad_earned.emit(reward_type)
    _rewarded_loaded = false
    load_rewarded_ad()  # preload next immediately

func can_show_interstitial() -> bool:
    var now = Time.get_ticks_msec() / 1000.0
    return _interstitial_loaded and (now - _last_interstitial_time) >= MIN_INTERSTITIAL_INTERVAL

func show_interstitial_if_ready() -> void:
    if not can_show_interstitial():
        return
    _last_interstitial_time = Time.get_ticks_msec() / 1000.0
    # AdMob plugin show call
    interstitial_shown.emit()
    _interstitial_loaded = false
    load_interstitial_ad()

func load_interstitial_ad() -> void:
    # AdMob plugin call
    pass
```

### 5.5 Child-Directed App Compliance

If the game may be used by children under 13 (COPPA / Google Play
Families Policy):

```gdscript
# In AdManager._ready(), before any ad requests:
# admob.set_child_directed_treatment(true)
# This enforces family-safe ads — lower eCPM but avoids policy violation
# and app removal from Play Store.
```

Always use test ad unit IDs during development. Never ship with test IDs.

---

## PHASE 6 — RETENTION DESIGN

Industry benchmarks (GameAnalytics 2024):
- D1 retention average: 26–28% (iOS higher than Android)
- D7 retention average: ~8%
- D30 retention average: <3%

Your goal: beat these averages. The levers:

### 6.1 First-Minute Experience (D1 Retention)

The single highest-impact variable. Players who don't feel reward in
minute 1 never reach minute 2.

Checklist for first 60 seconds:
- [ ] Player earns first currency within 5 seconds
- [ ] First unlock/progression happens before 60 seconds
- [ ] At least one "wow" moment (big number, unlock animation, sound)
- [ ] Core loop is demonstrated completely (earn → spend → feel stronger)
- [ ] No tutorial wall before the player can touch anything

### 6.2 Daily Return Hooks (D7 Retention)

- **Offline earnings popup**: the #1 mobile idle game hook. Player sees
  they "earned while sleeping." Always pair with a rewarded ad offer.
- **Daily quests**: 3–5 achievable quests. Complete all → special reward.
  Reset at midnight local time. NOT server time (players notice and hate it).
- **Daily free gift**: small gift every 24h. No ad required. Builds habit.
  The ad offer comes AFTER the free gift, as an upgrade.
- **Streak bonus**: day 3, 7, 14, 30 give escalating rewards. Creates
  loss aversion (don't break the streak).

### 6.3 Long-Term Retention (D30)

- **Content gates**: always have content locked beyond the player's
  current level. The feeling "I want to get there" sustains play.
- **Merge depth**: if the merge chain is 5 steps, player always wants
  the next tier. Never show the final tier's existence until they're
  one step away.
- **Limited events**: weekly character or theme. Creates urgency and
  FOMO. Rotate content regularly.
- **Meta progression**: something that persists across any "reset" —
  total lifetime coins earned, achievements, collection completion %.

---

## PHASE 7 — ITERATION METHODOLOGY (Agile for Solo/Agent Dev)

### 7.1 Sprint Structure

Even for a single agent, work in 2-day sprints:
- Sprint goal: one working feature end-to-end
- Daily check: does the build run? Is the core loop still intact?
- Sprint review: playtest the new feature. Does it feel good?
- Sprint retrospective: what broke? What needs refactoring?

Never spend more than 2 days on anything that isn't the core loop.
If you're polishing UI and the save system doesn't work — stop.

### 7.2 Playtesting Heuristics

After every sprint, run a 5-minute playtest and ask:
1. Is the first 60 seconds rewarding? (Retention)
2. Are the numbers growing fast enough to feel progress? (Pacing)
3. Does each tap feel satisfying? (Game feel)
4. Did I encounter any dead ends (nothing to buy/do)? (Content gaps)
5. Do I want to come back in an hour? (Idle loop quality)

### 7.3 Scope Creep Prevention

The #1 killer of indie games. When a new feature idea appears:
- Ask: does this serve the core loop?
- If yes: add to backlog, prioritize in next sprint planning.
- If no: write it down, defer to post-launch.
- NEVER add features mid-sprint.

---

## QUICK REFERENCE — AGENT DECISION TREE

When implementing any feature, run through this:

```
Is the core loop (tap → earn → spend) working?
    NO → Stop. Fix core loop first.
    YES ↓

Is save/load working and tested?
    NO → Stop. Implement save before any content.
    YES ↓

Am I implementing content (characters, upgrades)?
    YES → Use Resource (.tres) pattern. No hardcoding.
    NO ↓

Am I implementing UI?
    YES → Separate scene. Communicate via signals. No direct refs.
    NO ↓

Am I adding juice/effects?
    YES → Apply the 6-layer juice stack. No screen shake on every tap.
    NO ↓

Am I integrating ads?
    YES → Rewarded first. Interstitial with 3-min cooldown. Child tag if needed.
```

---

## COMMON AGENT MISTAKES TO AVOID

| Mistake                                   | Correct Approach                      |
| ----------------------------------------- | ------------------------------------- |
| Hardcoding character data in scripts      | Use Resource (.tres) files            |
| Direct node references across scenes      | Use SignalBus AutoLoad                |
| Instantiating particles every tap         | Object pool, recycle nodes            |
| Updating coin label every frame           | Update only on coins_changed signal   |
| Saving data on every coin gain            | Auto-save every 30 seconds + on pause |
| Accessing AutoLoad in `_init()`           | Use `_ready()` instead                |
| Showing interstitial mid-tap session      | Only at natural break points          |
| Using `while true:` loops for idle income | Use `_process(delta)` accumulator     |
| Storing scene state in AutoLoads          | Store only persistent global state    |
| Adding art/polish before core loop works  | Core loop → save → content → polish   |