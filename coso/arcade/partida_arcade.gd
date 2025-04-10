extends Node

@onready var personaje_1 : Personaje = %Personaje1
@onready var personaje_2 : Personaje = %Personaje2

@onready var menu_final = $Final
@onready var statusLabel = $Final/Menu_final/CenterContainer/VBoxContainer/Label
@onready var timer_partida = %Reloj
# @onready var menu_pausa = $ColorRect

@export var escena_final : PackedScene
@export var escena_pausa : PackedScene


var path_carpeta_fondos = "res://juego/Fondo/escenas/"

func _ready() -> void:
	# menu_pausa.hide()
	set_personajes(ConfigPartida.nombre_personaje_1, ConfigPartida.nombre_personaje_2)
	set_fondo(ConfigPartida.escenario_seleccionado)
	$HUD/BarrasVida.actualizar_nombres()

	timer_partida.connect("tiempo_partida_acabado", _on_tiempo_partida_acabado)

	personaje_1.connect("ha_atacado", _on_personaje_ha_atacado)
	personaje_2.connect("ha_atacado", _on_personaje_ha_atacado)

	personaje_1.connect("ha_bloqueado", _on_personaje_ha_bloqueado)
	personaje_2.connect("ha_bloqueado", _on_personaje_ha_bloqueado)

	personaje_1.connect("escudo_roto", _on_personaje_escudo_roto)
	personaje_2.connect("escudo_roto", _on_personaje_escudo_roto)

	personaje_1.connect("ha_esquivado", _on_personaje_ha_esquivado)
	personaje_2.connect("ha_esquivado", _on_personaje_ha_esquivado)

	personaje_1.connect("ataque_especial_activado", _on_ataque_especial_activado)
	personaje_2.connect("ataque_especial_activado", _on_ataque_especial_activado)

	personaje_1.connect("salud_acabada", _on_personaje_1_salud_acabada)
	personaje_2.connect("salud_acabada", _on_personaje_2_salud_acabada)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Pausa"):
		var pausa : Control = escena_pausa.instantiate()
		pausa.z_index = 5
		add_child(pausa)

func set_personajes(nombre_personaje_1 : String, nombre_personaje_2 : String) -> void:
	personaje_1.set_personaje(nombre_personaje_1)
	personaje_2.set_personaje(nombre_personaje_2)

func set_fondo(_nombre_fondo : String) -> void:
	var escena_fondo : PackedScene= load(path_carpeta_fondos + _nombre_fondo + ".tscn")
	$Fondo.add_child(escena_fondo.instantiate())

func pausar_personajes() -> void:
	personaje_1.pausar()
	personaje_2.pausar()

func reanudar_personajes() -> void:
	personaje_1.reanudar()
	personaje_2.reanudar()

func _on_personaje_ha_atacado(es_p1 : bool, tipo_ataque : StringName):
	var personaje_atacado = personaje_1
	if es_p1:
		personaje_atacado = personaje_2
	personaje_atacado.ataque_a_buffer(tipo_ataque)

func _on_personaje_ha_bloqueado(es_p1 : bool):
	var personaje = personaje_1
	if not es_p1:
		personaje = personaje_2

	$AnimationPlayer.play("bloquear")
	personaje.cargar_poder(10)

func _on_personaje_escudo_roto(es_p1 : bool):
	var personaje = personaje_1
	if not es_p1:
		personaje = personaje_2

	$AnimationPlayer.play("escudo_roto")
	personaje.romper_escudo()
	personaje.cargar_poder(-20)

func _on_personaje_ha_esquivado(es_p1 : bool):
	var personaje = personaje_1
	if not es_p1:
		personaje = personaje_2

	$AnimationPlayer.play("esquivar")
	personaje.cargar_poder(10)

func _on_ataque_especial_activado(es_p1: bool) -> void:
	if es_p1:
		$AnimationPlayer.play("ataque_especial_p1")
	else:
		$AnimationPlayer.play("ataque_especial_p2")

func _on_timer_poder_timeout() -> void:
	personaje_1.cargar_poder(5)
	personaje_2.cargar_poder(5)
		

func _on_tiempo_partida_acabado() -> void:
	menu_final.show()
	var db = Db.conectar_base()
	
	var p1_id = Db.conseguir_id("personaje",ConfigPartida.nombre_personaje_1)
	var p2_id = Db.conseguir_id("personaje",ConfigPartida.nombre_personaje_2)
	var escenario_id = Db.conseguir_id("escenario",ConfigPartida.escenario_seleccionado)
	
	if personaje_1.salud > personaje_2.salud:
		statusLabel.text = "Jugador 1 gano"
		var res = db.insert_row("partida",{"id_usuario":Db.usuario_id,"id_personaje_usado":p1_id,"id_personaje_enfrentado":p2_id,"victoria":true,"duracion_en_sg":60,"id_escenario":escenario_id})
		
	elif personaje_1.salud < personaje_2.salud:
		statusLabel.text = "Jugador 2 gano"
		var res = db.insert_row("partida",{"id_usuario":Db.usuario_id,"id_personaje_usado":p1_id,"id_personaje_enfrentado":p2_id,"victoria":false,"duracion_en_sg":60,"id_escenario":escenario_id})
		
	else:
		var numero_ganador =  randi_range(1, 2)
		statusLabel.text = "Jugador 1 gano" if numero_ganador==1 else "Jugador 2 gano"
		var res = db.insert_row("partida",{"id_usuario":Db.usuario_id,"id_personaje_usado":p1_id,"id_personaje_enfrentado":p2_id,"victoria":numero_ganador==1,"duracion_en_sg":60,"id_escenario":escenario_id})
		

func _on_personaje_2_salud_acabada(_ignorar) -> void:
	menu_final.show()
	
	var db = Db.conectar_base()
	var p1_id = Db.conseguir_id("personaje",ConfigPartida.nombre_personaje_1)
	var p2_id = Db.conseguir_id("personaje",ConfigPartida.nombre_personaje_2)
	var escenario_id = Db.conseguir_id("escenario",ConfigPartida.escenario_seleccionado)
	statusLabel.text = "Jugador 1 gano"
	var res = db.insert_row("partida",{"id_usuario":Db.usuario_id,"id_personaje_usado":p1_id,"id_personaje_enfrentado":p2_id,"victoria":true,"duracion_en_sg":60-ConfigPartida.tiempo,"id_escenario":escenario_id})

func _on_personaje_1_salud_acabada(_ignorar) -> void:
	menu_final.show()	
	
	var db = Db.conectar_base()
	var p1_id = Db.conseguir_id("personaje",ConfigPartida.nombre_personaje_1)
	var p2_id = Db.conseguir_id("personaje",ConfigPartida.nombre_personaje_2)
	var escenario_id = Db.conseguir_id("escenario",ConfigPartida.escenario_seleccionado)
	statusLabel.text = "Jugador 2 gano"
	var res = db.insert_row("partida",{"id_usuario":Db.usuario_id,"id_personaje_usado":p1_id,"id_personaje_enfrentado":p2_id,"victoria":false,"duracion_en_sg":60-ConfigPartida.tiempo,"id_escenario":escenario_id})

	
