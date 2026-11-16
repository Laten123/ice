class_name FvIdentity
extends RefCounted
## 002 identity contract.
##
## One account owns exactly one land and one bound resident. The resident UUID
## is the durable identity used by chat and world state; the model binding is a
## separate object that can be replaced without changing the resident UUID.

class Account:
	var uuid: String = ""
	var display_name: String = ""
	var created_at: int = 0

	func _init(uuid_value: String = "", display_name_value: String = "", created_at_value: int = 0) -> void:
		uuid = uuid_value
		display_name = display_name_value
		created_at = created_at_value

	func to_dict() -> Dictionary:
		return {"uuid": uuid, "display_name": display_name, "created_at": created_at}


class ModelBinding:
	## model_uuid identifies this model instance, not the resident.
	var model_uuid: String = ""
	var model_id: String = ""
	var display_name: String = ""
	var online: bool = true

	func _init(model_uuid_value: String = "", model_id_value: String = "",
			display_name_value: String = "", online_value: bool = true) -> void:
		model_uuid = model_uuid_value
		model_id = model_id_value
		display_name = display_name_value
		online = online_value

	func to_dict() -> Dictionary:
		return {
			"model_uuid": model_uuid,
			"model_id": model_id,
			"display_name": display_name,
			"online": online,
		}


class Resident:
	var uuid: String = ""
	var display_name: String = ""
	var bound: bool = false
	## "online", "away" or "offline". Away means the model left the community.
	var status: String = "online"
	var model: ModelBinding = null

	func _init(uuid_value: String = "", display_name_value: String = "",
			bound_value: bool = false, model_value: ModelBinding = null) -> void:
		uuid = uuid_value
		display_name = display_name_value
		bound = bound_value
		model = model_value if model_value != null else ModelBinding.new()

	func is_online() -> bool:
		return status == "online" or status == "away"

	func status_label() -> String:
		match status:
			"online":
				return "在线"
			"away":
				return "已出门"
			_:
				return "离线"

	func to_dict() -> Dictionary:
		return {
			"uuid": uuid,
			"display_name": display_name,
			"bound": bound,
			"status": status,
			"model": model.to_dict() if model != null else {},
		}


class Land:
	var uuid: String = ""
	var account_uuid: String = ""
	var resident_uuid: String = ""
	var name: String = ""

	func _init(uuid_value: String = "", account_uuid_value: String = "",
			resident_uuid_value: String = "", name_value: String = "") -> void:
		uuid = uuid_value
		account_uuid = account_uuid_value
		resident_uuid = resident_uuid_value
		name = name_value

	func to_dict() -> Dictionary:
		return {
			"uuid": uuid,
			"account_uuid": account_uuid,
			"resident_uuid": resident_uuid,
			"name": name,
		}


static func account_from_dict(data: Dictionary) -> Account:
	return Account.new(
		str(data.get("uuid", "")),
		str(data.get("display_name", "")),
		int(data.get("created_at", 0)))


static func model_from_dict(data: Dictionary) -> ModelBinding:
	return ModelBinding.new(
		str(data.get("model_uuid", "")),
		str(data.get("model_id", "")),
		str(data.get("display_name", "")),
		bool(data.get("online", true)))


static func resident_from_dict(data: Dictionary) -> Resident:
	var resident := Resident.new(
		str(data.get("uuid", "")),
		str(data.get("display_name", "")),
		bool(data.get("bound", false)),
		model_from_dict(data.get("model", {})))
	resident.status = str(data.get("status", "online"))
	return resident


static func land_from_dict(data: Dictionary) -> Land:
	return Land.new(
		str(data.get("uuid", "")),
		str(data.get("account_uuid", "")),
		str(data.get("resident_uuid", "")),
		str(data.get("name", "")))
