extends Node
## 《幻想乡》AI 接口层
## 统一 HTTP 接口：世界 / 角色 / 消息
## 不依赖具体模型服务商（未来可接 OpenAI/DeepSeek/本地）

const API_BASE := "http://127.0.0.1:8000"

var _http: HTTPRequest

func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)

## GET 请求（通用）
func _http_get(path: String, cb: Callable) -> void:
	var err := _http.request(API_BASE + path)
	if err != OK:
		cb.call(0, {})
		return
	var result = await _http.request_completed
	cb.call(result[1], result[3].get_string_from_utf8())

## POST 请求（通用）
func _http_post(path: String, body: Dictionary, cb: Callable) -> void:
	var headers := ["Content-Type: application/json"]
	var err := _http.request(API_BASE + path, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		cb.call(0, {})
		return
	var result = await _http.request_completed
	cb.call(result[1], result[3].get_string_from_utf8())

## 健康检查
func health(cb: Callable = Callable()) -> void:
	_http_get("/api/health", func(code, body):
		print("[AI接口] health code=", code, " body=", body.substr(0, 120))
		if cb.is_valid(): cb.call(code, body))

## 读世界
func get_world(world_id: String = "default", cb: Callable = Callable()) -> void:
	_http_get("/api/world?world_id=" + world_id, func(code, body):
		if cb.is_valid(): cb.call(code, body))

## 读消息
func get_messages(cb: Callable = Callable()) -> void:
	_http_get("/api/messages", func(code, body):
		if cb.is_valid(): cb.call(code, body))

## 发消息（AI 说话）
func send_message(sender: String, text: String, cb: Callable = Callable()) -> void:
	var body := {"sender": sender, "text": text}
	_http_post("/api/messages", body, func(code, _b):
		if cb.is_valid(): cb.call(code))
