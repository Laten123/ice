class_name FvMockCommunityService
extends RefCounted
const AppState = preload("res://scripts/state/app_state.gd")
const Identity = preload("res://scripts/models/identity.gd")
## Deterministic local stand-in for the future world channel / model service.
## It never performs network requests and its replies are explicitly placeholder.



static func world_messages(state: AppState) -> Array[Dictionary]:
	return [
		{
			"sender": state.account.display_name,
			"kind": "owner",
			"text": "我刚回到社区，今天大家怎么样？",
		},
		{
			"sender": state.bound_resident.display_name,
			"kind": "model",
			"text": "院子里很安静，我把长椅擦干净了。",
		},
	]


static func private_reply(text: String, resident: Identity.Resident) -> String:
	var replies := [
		"收到啦，我在广场这边。",
		"好呀，等我把手边的事做完。",
		"嗯，我一直在这里。",
	]
	return replies[text.length() % replies.size()]


static func status_label(status: String) -> String:
	match status:
		"online":
			return "在线"
		"away":
			return "已出门"
		"offline":
			return "离线"
		_:
			return "未知"
