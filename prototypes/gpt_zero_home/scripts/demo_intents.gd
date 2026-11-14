extends Node
## Explicitly scripted intent playback for UI/path validation.
## THIS IS NOT A MODEL AND MUST NEVER BE PRESENTED AS AI AUTONOMY.
## Real residents will supply equivalent intents through an authenticated backend.

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
    {"id": XIAOBING, "intent": {"action": "decline"}},
    {"id": SHENXUN, "intent": {"action": "move", "target": "tree_path"}},
    {"id": SHENXUN, "intent": {"action": "rest"}}
]

var playback_enabled: bool = true
var scene_cursor: int = 0
var timer: Timer

func _ready() -> void:
    if not playback_enabled:
        return
    timer = Timer.new()
    timer.name = "ScriptedPlaybackClock"
    timer.wait_time = 13.0
    timer.autostart = true
    timer.timeout.connect(_play_next)
    add_child(timer)

func _play_next() -> void:
    if not playback_enabled:
        return
    var event: Dictionary = SCENARIO[scene_cursor]
    scene_cursor = (scene_cursor + 1) % SCENARIO.size()
    scripted_intent.emit(event["id"], event["intent"])
