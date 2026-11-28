extends Node2D
## One decorative backdrop band (sky gradient or rolling ridge) drawn inside a
## Parallax2D so it scrolls slower than the world. Never creates collision.


var painter: Script
var kind: StringName = &"ridge"
var width: float = 2400.0
var ground_y: float = 650.0
var base_y: float = 0.0
var amplitude: float = 0.0
var wavelength: float = 400.0
var phase: float = 0.0
var tint: Color = Color.WHITE

func _draw() -> void:
	if kind == &"sky":
		painter.draw_sky(self, width, ground_y)
	else:
		painter.draw_ridge_band(self, width, ground_y, base_y, amplitude, wavelength, phase, tint)
