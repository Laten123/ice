class_name KenneyAtlas
extends RefCounted
## Minimal runtime loader for the CC0 Kenney packed atlases.
## Loading raw bytes avoids dependency on the Godot editor import cache.

const COLUMNS := 12
const TILE_SIZE := 16

var image: Image
var texture: ImageTexture


func load_atlas(path: String) -> bool:
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		push_error("Cannot read atlas: " + path)
		return false
	image = Image.new()
	var error := image.load_png_from_buffer(bytes)
	if error != OK:
		push_error("Cannot decode atlas: " + path)
		return false
	image.convert(Image.FORMAT_RGBA8)
	texture = ImageTexture.create_from_image(image)
	return texture != null


func is_ready() -> bool:
	return image != null and texture != null


func region(index: int) -> Rect2:
	return Rect2((index % COLUMNS) * TILE_SIZE, (index / COLUMNS) * TILE_SIZE,
		TILE_SIZE, TILE_SIZE)


func blit_tile(target: Image, index: int, destination: Vector2i) -> void:
	if not is_ready():
		return
	target.blit_rect(image, region(index), destination)
