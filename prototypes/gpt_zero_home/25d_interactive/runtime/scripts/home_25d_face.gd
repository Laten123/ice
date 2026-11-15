extends Node2D
## Optional closed-eye overlay for the supplied woodland test skin.
var facing := "front"
var skin_color := Color("#e1cea3")
var eye_color := Color("#335846")

func _draw() -> void:
    var eye_x: Array[int] = [-4, 2]
    if facing == "back":
        return
    if facing == "left":
        eye_x = [-5]
    elif facing == "right":
        eye_x = [4]
    for x in eye_x:
        draw_rect(Rect2(x, -6, 3, 3), skin_color)
        draw_rect(Rect2(x, -5, 3, 1), eye_color)
