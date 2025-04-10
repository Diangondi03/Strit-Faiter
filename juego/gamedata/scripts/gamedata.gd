# GameData.gd
extends Node

var path_partida : String = "res://juego/gameplay/escenas/partida.tscn"

var nombre_personaje_1: String = "Knuckles"
var nombre_personaje_2: String = "Kirby"
var escenario_seleccionado: String = "Caricuao"

var otra_variable: int = 0 # Si tienes alguna otra variable
var tiempo = 60 # para guadar el tiempo de partida en la bd correctamente

var input_p1 : String = "vacio"
var salud_p1 : int = 200


var dificultad_ia : String = "facil"

var modo_juego_actual: ModoJuego = ModoJuego.VS_JUGADOR
var partida_queue : Array[Array] = [["Goku", "Gojo", "dbz"]]

# Partida = {"Sonic", "Gojo", "Caricuao"}  
# siguiendo formato {"nombrePersonaje1", "nombrePersonaje2", "nombreEscenario"}

enum ModoJuego {
	VS_JUGADOR, # 0
	VS_IA, # 1
	ARCADE # 2
}

func _ready():
	print("Singleton GameData inicializado")

func set_modo_juego(modo : ModoJuego) -> void:
	dificultad_ia='dificil'
	modo_juego_actual = modo
	if modo_juego_actual==2:
		dificultad_ia='facil'

func agregar_a_partida_queue(personaje_1 : String, personaje_2 : String, escenario : String) -> void:
	partida_queue.push_back([personaje_1, personaje_2, escenario])

func limpiar_queue() -> void:
	partida_queue.clear()

func obtener_partida_actual() -> Array:
	nombre_personaje_1 = partida_queue.front()[0]
	nombre_personaje_2 = partida_queue.front()[1]
	escenario_seleccionado = partida_queue.front()[2]
	return partida_queue.front().duplicate()

func siguiente_partida() -> void:
	partida_queue.pop_front()
	if dificultad_ia=='facil':
		dificultad_ia='medio'
	if dificultad_ia=='medio':
		dificultad_ia=='dificil'
		
	

func queue_partida_vacio() -> bool:
	return partida_queue.is_empty()
