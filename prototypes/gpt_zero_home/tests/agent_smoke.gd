extends SceneTree
## AI-first contract: world moves only in response to resident-origin events.
## This is a deterministic engine test, not proof of AI cognition or API auth.

func _initialize() -> void:
    call_deferred("_run_test")

func _fail(message: String) -> void:
    printerr("AGENT_SMOKE_FAIL: ", message)
    quit(1)

func _run_test() -> void:
    var scene: PackedScene = load("res://scenes/home.tscn")
    var home = scene.instantiate()
    root.add_child(home)
    await process_frame

    if home.get_node_or_null("ResidentLayer") == null:
        _fail("missing non-player resident rendering layer")
        return
    var graph = home.walk_graph
    var walk_route: PackedVector2Array = graph.route_between("book_corner", "tea_table")
    if walk_route.size() < 2:
        _fail("graph does not connect reading corner to tea table")
        return
    if graph.route_between("porch", "riverbank").is_empty():
        _fail("graph cannot reach riverbank from house")
        return
    if not graph.route_between("porch", "river").is_empty():
        _fail("accepted invalid out-of-bounds destination")
        return

    var shen = home.residents["00000000-0000-4000-8000-000000000001"]
    var xiao = home.residents["00000000-0000-4000-8000-000000000002"]
    if shen == null or xiao == null:
        _fail("missing resident instances")
        return
    var original_pos: Vector2 = shen.position
    if not shen.accept_intent({"action": "move", "target": "tea_table"}):
        _fail("valid resident move denied")
        return
    for n in range(220):
        shen._process(0.1)
        if shen.state == "stay":
            break
    if shen.position.distance_to(graph.zone_position("tea_table")) > 1.5:
        _fail("agent did not walk to its own tea-table destination")
        return
    if shen.position.distance_to(original_pos) < 15.0:
        _fail("agent never moved")
        return
    if not shen.accept_intent({"action": "sit"}):
        _fail("agent cannot sit at designated tea table")
        return
    var anchor: Vector2 = shen.position
    if shen.accept_intent({"action": "move", "target": "river_outside_map"}):
        _fail("invalid destination was accepted")
        return
    if shen.accept_intent({"action": "read_private_memory"}):
        _fail("arbitrary privileged action was accepted")
        return
    if not shen.accept_intent({"action": "decline"}):
        _fail("resident rejection event was denied")
        return
    for n in range(30):
        shen._process(0.15)
    if shen.state != "decline" or shen.position.distance_to(anchor) > 0.01:
        _fail("decline was overridden by movement")
        return

    if xiao.accept_intent({"action": "sit"}):
        _fail("resident can sit remotely, without reaching a permitted point")
        return

    # Human UI changes only viewer lighting. No human movement/action interface.
    var xiao_pos: Vector2 = xiao.position
    home._set_time(true)
    if not home.is_dusk or xiao.position.distance_to(xiao_pos) > 0.01:
        _fail("viewer light switch moved or controlled an AI resident")
        return

    print("AGENT_SMOKE_OK: routes, consent/refusal, independent actor events and read-only viewer")
    quit(0)
