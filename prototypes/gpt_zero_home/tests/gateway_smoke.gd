extends SceneTree
## Tests the local ingress contract. This does NOT validate production auth:
## a real server must derive verified_resident_id from credentials.

const SHEN := "00000000-0000-4000-8000-000000000001"
const XIAO := "00000000-0000-4000-8000-000000000002"

func _initialize() -> void:
    call_deferred("_run")

func _failed(message: String) -> void:
    printerr("GATEWAY_SMOKE_FAIL: ", message)
    quit(1)

func _run() -> void:
    var home = load("res://scenes/home.tscn").instantiate()
    root.add_child(home)
    await process_frame
    home.scripted_replay.stop_playback()
    var gate = home.gateway
    var xiao = home.residents[XIAO]
    var first_position: Vector2 = xiao.position

    var spoof: Dictionary = gate.dispatch_verified({
        "event_id": "check-spoof",
        "resident_id": XIAO,
        "action": "move",
        "target": "tea_table"
    }, SHEN)
    if spoof["status"] != "rejected" or xiao.position != first_position:
        _failed("spoofed event moved another resident")
        return
    var replay: Dictionary = gate.dispatch_verified({
        "event_id": "check-spoof",
        "resident_id": XIAO,
        "action": "move",
        "target": "tea_table"
    }, XIAO)
    if replay["status"] != "rejected" or replay["detail"] != "duplicate_event_id":
        _failed("replayed event ID was accepted")
        return

    var forbidden: Dictionary = gate.dispatch_verified({
        "event_id": "check-private",
        "resident_id": XIAO,
        "action": "read_private_memory"
    }, XIAO)
    if forbidden["status"] != "rejected" or xiao.position != first_position:
        _failed("unsupported privileged action accepted")
        return
    var injected: Dictionary = gate.dispatch_verified({
        "event_id": "check-extra-field",
        "resident_id": XIAO,
        "action": "stay",
        "private_memory": "must not be forwarded"
    }, XIAO)
    if injected["status"] != "rejected":
        _failed("private payload passed into world event")
        return

    var move: Dictionary = gate.dispatch_verified({
        "event_id": "check-walk",
        "resident_id": XIAO,
        "action": "move",
        "target": "front_path"
    }, XIAO)
    if move["status"] != "accepted":
        _failed("resident-authored valid movement denied")
        return
    for i in range(150):
        xiao._process(0.1)
        if xiao.state != "move":
            break
    if xiao.zone != "front_path" or xiao.state != "stay":
        _failed("resident failed to reach target")
        return
    var completed := false
    for receipt in home.public_event_log:
        if receipt.get("event_id") == "check-walk" and receipt.get("status") == "completed":
            completed = true
    if not completed:
        _failed("no completion event after real route arrival")
        return

    var second_move: Dictionary = gate.dispatch_verified({
        "event_id": "check-second-move",
        "resident_id": XIAO,
        "action": "move",
        "target": "garden"
    }, XIAO)
    if second_move["status"] != "accepted":
        _failed("second resident move rejected")
        return
    xiao._process(0.1)
    var current: Vector2 = xiao.position
    var decline: Dictionary = gate.dispatch_verified({
        "event_id": "check-decline",
        "resident_id": XIAO,
        "action": "decline"
    }, XIAO)
    if decline["status"] != "accepted":
        _failed("resident decline rejected")
        return
    for i in range(90):
        xiao._process(0.15)
    if xiao.state != "decline" or current.distance_to(xiao.position) > 0.001:
        _failed("resident kept walking after declining")
        return
    var was_interrupted := false
    var decline_completed := false
    for receipt in home.public_event_log:
        if receipt.get("event_id") == "check-second-move" and receipt.get("status") == "interrupted":
            was_interrupted = true
        if receipt.get("event_id") == "check-decline" and receipt.get("status") == "completed":
            decline_completed = true
    if not was_interrupted or not decline_completed:
        _failed("decline did not interrupt prior plan with receipts")
        return

    if home.scripted_replay.playback_enabled:
        _failed("scripted replay not disabled during gateway test")
        return
    print("GATEWAY_SMOKE_OK: caller binding, replay rejection, private-field rejection, arrival receipt, decline cancels movement")
    quit(0)
