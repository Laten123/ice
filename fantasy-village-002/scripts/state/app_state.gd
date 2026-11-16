class_name FvAppState
extends RefCounted
const Identity = preload("res://scripts/models/identity.gd")
## Local-only 002 state. No account server, model service or network calls.
##
## Invariants enforced here:
## - one account, one land, one bound resident;
## - resident.uuid never changes when the model binding is replaced;
## - resident UUIDs and model UUIDs are each unique;
## - community_models contains the bound resident exactly once, as the same
##   object that FvAppState exposes as bound_resident.

const SAVE_PATH := "user://fv002_profile.json"
const SAVE_VERSION := 2
const BOUND_NAME := "小晴"
const NEIGHBOR_NAME := "阿澈"
const DEFAULT_MODEL_ID := "local-fantasy-0.1"
const STATUS_VALUES := ["online", "away", "offline"]

var account: Identity.Account = null
var land: Identity.Land = null
var bound_resident: Identity.Resident = null
var community_models: Array = []
var save_path := SAVE_PATH


func has_identity() -> bool:
	return account != null and land != null and bound_resident != null


func create_identity(display_name: String) -> bool:
	var cleaned := display_name.strip_edges()
	if cleaned.is_empty() or cleaned.length() > 12:
		return false
	var created_at := int(Time.get_unix_time_from_system())
	account = Identity.Account.new(_new_uuid(), cleaned, created_at)
	bound_resident = _new_resident(BOUND_NAME, true, "online")
	var neighbor := _new_resident(NEIGHBOR_NAME, false, "online")
	community_models = [bound_resident, neighbor]
	land = Identity.Land.new(
		"land_" + _new_uuid().substr(0, 8),
		account.uuid,
		bound_resident.uuid,
		cleaned + "的土地")
	return true


func load_identity() -> bool:
	if not FileAccess.file_exists(save_path):
		return false
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return _reject_profile("Cannot open 002 profile")
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		return _reject_profile("002 profile is not valid JSON")
	var parsed: Variant = json.data
	if not (parsed is Dictionary):
		return _reject_profile("002 profile is not a valid JSON object")
	var payload: Dictionary = parsed
	if int(payload.get("version", 0)) != SAVE_VERSION:
		return _reject_profile("Unsupported 002 profile version")
	var account_data: Variant = payload.get("account", null)
	var land_data: Variant = payload.get("land", null)
	var bound_data: Variant = payload.get("bound_resident", null)
	var models_data: Variant = payload.get("community_models", null)
	if not (account_data is Dictionary) or not (land_data is Dictionary) \
			or not (bound_data is Dictionary) or not (models_data is Array):
		return _reject_profile("002 profile is missing required identity sections")
	account = Identity.account_from_dict(account_data)
	land = Identity.land_from_dict(land_data)
	bound_resident = Identity.resident_from_dict(bound_data)
	community_models.clear()
	for entry: Variant in models_data:
		if not (entry is Dictionary):
			return _reject_profile("002 community model entry is not an object")
		community_models.append(Identity.resident_from_dict(entry))
	# Keep a single source of truth: the bound resident must be the same object
	# as the bound entry in the community list, including its model binding.
	if bound_resident == null or bound_resident.model == null:
		return _reject_profile("002 profile has no bound resident model")
	var matched: Identity.Resident = null
	for resident: Identity.Resident in community_models:
		if resident.uuid == bound_resident.uuid:
			if resident.model == null or resident.model.model_uuid != bound_resident.model.model_uuid:
				return _reject_profile("002 bound resident and community entry disagree on the model")
			matched = resident
			break
	if matched == null:
		return _reject_profile("002 bound resident is missing from the community list")
	bound_resident = matched
	if not _is_valid():
		return _reject_profile("002 profile violates the one-account/one-land/one-resident rule")
	return true


func save_identity() -> bool:
	if not _is_valid():
		push_error("Refusing to save an invalid 002 profile")
		return false
	var payload := {
		"version": SAVE_VERSION,
		"account": account.to_dict(),
		"land": land.to_dict(),
		"bound_resident": bound_resident.to_dict(),
		"community_models": [],
	}
	for resident: Identity.Resident in community_models:
		payload["community_models"].append(resident.to_dict())
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write 002 profile: %s" % FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return true


func set_model_binding(binding: Identity.ModelBinding) -> bool:
	if bound_resident == null or binding == null:
		return false
	var resident_uuid := bound_resident.uuid
	bound_resident.model = binding
	for resident: Identity.Resident in community_models:
		if resident.uuid == resident_uuid:
			resident.model = binding
	return bound_resident.uuid == resident_uuid


func model_count() -> int:
	return community_models.size()


func find_model(model_uuid: String) -> Identity.Resident:
	for resident: Identity.Resident in community_models:
		if resident.model != null and resident.model.model_uuid == model_uuid:
			return resident
	return null


func is_bound_model(model_uuid: String) -> bool:
	return bound_resident != null and bound_resident.model != null \
		and bound_resident.model.model_uuid == model_uuid


func clear_identity() -> void:
	account = null
	land = null
	bound_resident = null
	community_models.clear()


static func short_uuid(value: String) -> String:
	if value.length() <= 13:
		return value
	return value.substr(0, 8) + "…" + value.substr(value.length() - 4, 4)


func _new_resident(display_name: String, is_bound: bool, status: String) -> Identity.Resident:
	var model := Identity.ModelBinding.new(
		_new_uuid(), DEFAULT_MODEL_ID, display_name + " 0.1", true)
	var resident := Identity.Resident.new(_new_uuid(), display_name, is_bound, model)
	resident.status = status
	return resident


func _new_uuid() -> String:
	var bytes := Crypto.new().generate_random_bytes(16)
	bytes[6] = (bytes[6] & 0x0f) | 0x40
	bytes[8] = (bytes[8] & 0x3f) | 0x80
	var hex := bytes.hex_encode()
	return "%s-%s-%s-%s-%s" % [
		hex.substr(0, 8), hex.substr(8, 4), hex.substr(12, 4),
		hex.substr(16, 4), hex.substr(20, 12)]


func _reject_profile(message: String) -> bool:
	clear_identity()
	push_warning(message)
	return false


func _is_valid() -> bool:
	if account == null or land == null or bound_resident == null:
		return false
	if account.uuid.is_empty() or account.display_name.strip_edges().is_empty():
		return false
	if account.display_name.length() > 12:
		return false
	if land.uuid.is_empty() or bound_resident.uuid.is_empty():
		return false
	if land.account_uuid != account.uuid or land.resident_uuid != bound_resident.uuid:
		return false
	if not bound_resident.bound:
		return false
	if bound_resident.model == null:
		return false
	if not _model_is_valid(bound_resident.model):
		return false
	if not (bound_resident.status in STATUS_VALUES):
		return false
	var resident_ids := {}
	var model_ids := {}
	var bound_match: Identity.Resident = null
	var bound_count := 0
	for resident: Identity.Resident in community_models:
		if resident == null:
			return false
		if resident.uuid.is_empty() or resident_ids.has(resident.uuid):
			return false
		if resident.display_name.strip_edges().is_empty():
			return false
		if not (resident.status in STATUS_VALUES):
			return false
		resident_ids[resident.uuid] = true
		if resident.model == null or not _model_is_valid(resident.model):
			return false
		if model_ids.has(resident.model.model_uuid):
			return false
		model_ids[resident.model.model_uuid] = true
		if resident.bound:
			bound_count += 1
			if resident.uuid != bound_resident.uuid:
				return false
			bound_match = resident
	if bound_count != 1 or bound_match == null:
		return false
	if bound_match != bound_resident:
		return false
	return resident_ids.has(bound_resident.uuid)


func _model_is_valid(model: Identity.ModelBinding) -> bool:
	return model != null and not model.model_uuid.is_empty() \
		and not model.model_id.is_empty() \
		and not model.display_name.strip_edges().is_empty()
