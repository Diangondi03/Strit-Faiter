extends Button

signal boton_presionado(nombre_boton)

@export var input_key : StringName

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(input_key):
		emit_signal("boton_presionado", text)

func _on_pressed() -> void:
	emit_signal("boton_presionado", text)
