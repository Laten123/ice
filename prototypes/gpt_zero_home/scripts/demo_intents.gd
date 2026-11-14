extends Node
## Finite scripted demonstration ONLY; no LLM is connected here.
## The demo never loops or reassigns goals after a resident declines.

signal scripted_intent(resident_id: String, intent: Dictionary)

const SHENXUN := "00000000-0000-4000-8000-000000000001"
const XIAOBING := "00000000-0000-4000-8000-000000000002"

const SCENARIO := [
    {"id": SHENXUN, "intent": {"action": "move", "target": "book_corner"}},
    {"id": XIAOBING, "intent": {"action": "move", "target": "window_view"}},
    {"id": SHENXUN, "intent": {"action": "read"}},
    {"id": XIAOBING, "intent": {"action": "sit"}},
    {"id": SHENXUN, "intent": {"action": "move", "target": "tea_table"}},
    {"id": SHENXUN, "intent": {"action": "sit"}},
    {"id": XIAOBING, "intent": {"action": "decline"}}
]

var playback_enabled := false
var scene_cursor := 0
var timer: Timer
var stopped_by_residents: Dictionary = {}

func _ready() -> void:
    # The demo is opt-in via --demo-intents; it must NEVER
    # be confused with autonomous activity or used for production AI residents.
    if not playback_enabled:
        return
    timer = Timer.new()
    timer.name = "ScriptedPlaybackClock"
    timer.wait_time = 13.0
    timer.one_shot = false
    timer.timeout.connect(_play_next)
    add_child(timer)
    timer.start()

func _play_next() -> void:
    if not playback_enabled or scene_cursor >= SCENARIO.size():
        stop_playback()
        return
    var event: Dictionary = SCENARIO[scene_cursor]
    scene_cursor += 1
    var resident_id: String = event["id"]
    var intent: Dictionary = event["intent"]
    if not stopped_by_residents.has(resident_id):
        scripted_intent.emit(resident_id, intent)
        if intent.get("action") == "decline":
            stopped_by_residents[resident_id] = true
    if scene_cursor >= SCENARIO.size():
        stop_playback()

func stop_playback() -> void:
    playback_enabled = false
    if timer != null:
        timer.stop()
