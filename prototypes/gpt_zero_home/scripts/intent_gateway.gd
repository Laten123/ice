extends RefCounted
## LOCAL boundary for trusted resident intent messages; no network listener/auth yet.
## The caller_identity argument MUST come from server-verified credentials in
## production. Never trust an identity copied from a client JSON payload.

signal public_receipt(receipt: Dictionary)

const ALLOWED_ACTIONS := ["move", "sit", "read", "rest", "stay", "decline"]
const ALLOWED_KEYS := ["event_id", "resident_id", "action", "target"]
const MAX_EVENT_ID_CHARS := 96

var actors: Dictionary = {}
var seen_event_ids: Dictionary = {}
var pending_moves: Dictionary = {}

func configure(resident_actors: Dictionary) -> void:
    actors = resident_actors
    for resident_id in actors.keys():
        var actor = actors[resident_id]
        actor.destination_reached.connect(_on_arrival)

func _receipt(event_id: String, resident_id: String, status: String, details: String) -> Dictionary:
    # Nothing from private model thoughts, messages or memory is echoed here.
    var data := {
        "event_id": event_id,
        "resident_id": resident_id,
        "status": status,
        "detail": details
    }
    public_receipt.emit(data)
    return data

func dispatch_verified(event: Dictionary, verified_resident_id: String) -> Dictionary:
    ## This method is for use ONLY after a trusted gateway has authenticated a
    ## resident; an arbitrary viewer/web client must never be allowed to call it.
    var event_id: String = str(event.get("event_id", ""))
    var claimed_id: String = str(event.get("resident_id", ""))
    var action: String = str(event.get("action", ""))
    if event_id.is_empty() or event_id.length() > MAX_EVENT_ID_CHARS:
        return _receipt(event_id, claimed_id, "rejected", "invalid_event_id")
    if seen_event_ids.has(event_id):
        return _receipt(event_id, claimed_id, "rejected", "duplicate_event_id")

    # Remember this ID even when an event is rejected: rejecting then replaying
    # a tampered request must not become a new opportunity to act.
    seen_event_ids[event_id] = true

    if verified_resident_id.is_empty() or claimed_id != verified_resident_id:
        return _receipt(event_id, claimed_id, "rejected", "identity_mismatch")
    if not actors.has(claimed_id):
        return _receipt(event_id, claimed_id, "rejected", "unknown_resident")
    if not ALLOWED_ACTIONS.has(action):
        return _receipt(event_id, claimed_id, "rejected", "unsupported_action")
    for key in event.keys():
        if not ALLOWED_KEYS.has(str(key)):
            return _receipt(event_id, claimed_id, "rejected", "unsupported_field")
    if action == "move":
        if not event.has("target") or typeof(event["target"]) != TYPE_STRING:
            return _receipt(event_id, claimed_id, "rejected", "missing_target")
    elif event.has("target"):
        return _receipt(event_id, claimed_id, "rejected", "unnecessary_target")

    var actor = actors[claimed_id]
    var intent := {"action": action}
    if action == "move":
        intent["target"] = event["target"]
    if not actor.accept_intent(intent):
        return _receipt(event_id, claimed_id, "rejected", "invalid_location_or_action")

    # A new authenticated intention from the SAME resident can replace its
    # earlier walk; nobody else is given that power by this interface.
    if pending_moves.has(claimed_id):
        var superseded_id: String = pending_moves[claimed_id]
        pending_moves.erase(claimed_id)
        _receipt(superseded_id, claimed_id, "interrupted", "resident_changed_mind")

    if action == "move":
        pending_moves[claimed_id] = event_id
        return _receipt(event_id, claimed_id, "accepted", "moving")
    var result: Dictionary = _receipt(event_id, claimed_id, "accepted", action)
    _receipt(event_id, claimed_id, "completed", action)
    return result

func _on_arrival(resident_id: String, target_zone: String) -> void:
    if not pending_moves.has(resident_id):
        return
    var event_id: String = pending_moves[resident_id]
    pending_moves.erase(resident_id)
    _receipt(event_id, resident_id, "completed", target_zone)
