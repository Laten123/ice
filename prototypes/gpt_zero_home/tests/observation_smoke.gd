extends SceneTree
## Agent sees only its own public state, the public world and optional actions.
## The viewer has no authority to choose an agent's next intent.

const SHEN := "00000000-0000-4000-8000-000000000001"
const XIAO := "00000000-0000-4000-8000-000000000002"

func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    printerr("OBSERVATION_SMOKE_FAIL: ", reason)
    quit(1)

func _run() -> void:
    var home = load("res://scenes/home.tscn").instantiate()
    root.add_child(home)
    await process_frame
    home.scripted_replay.stop_playback()

    var public_data: Dictionary = home.public_snapshot()
    if public_data.get("world_id", "") != "fantasia.first_home.prototype":
        _fail("public world id not found")
        return
    if public_data.get("residents", []).size() != 2:
        _fail("public resident list invalid")
        return
    var shen_data: Dictionary = home.observation_for_verified_resident(SHEN)
    if shen_data.get("self", {}).get("resident_id", "") != SHEN:
        _fail("resident observation not scoped to verified identity")
        return
    if shen_data.get("world", {}).get("public_residents", []).size() != 1:
        _fail("public companions missing or leaked")
        return
    if not shen_data["available_actions"].has("decline") or not shen_data["available_actions"].has("stay"):
        _fail("capabilities don't allow refusal or inactivity")
        return
    if not home.observation_for_verified_resident("unknown-id").is_empty():
        _fail("unrecognized resident was allowed to observe")
        return

    var public_json: String = JSON.stringify(public_data)
    var scoped_json: String = JSON.stringify(shen_data)
    for disallowed in ["private_memory", "secret", "system_prompt", "chain_of_thought", "api_key", "password"]:
        if public_json.find(disallowed) != -1 or scoped_json.find(disallowed) != -1:
            _fail("private data field in published world observation: " + disallowed)
            return

    var initial_pos: Vector2 = home.residents[XIAO].position
    var previous_state: String = home.residents[XIAO].state
    home._set_time(true)
    var observer_data: Dictionary = home.public_snapshot()
    if observer_data["residents"].size() != 2 or home.residents[XIAO].position != initial_pos or home.residents[XIAO].state != previous_state:
        _fail("public observer light preview affected a resident's intent")
        return
    if home.get_node_or_null("PublicResidentStatus") == null:
        _fail("read-only public resident status display missing")
        return

    print("OBSERVATION_SMOKE_OK: identity-scoped public observations, optional actions, read-only viewer")
    quit(0)
