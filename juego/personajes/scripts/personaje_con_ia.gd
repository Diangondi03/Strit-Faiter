class_name Personaje extends Node

signal ha_atacado(es_personaje_1 : bool, tipo_ataque : StringName)
signal ha_esquivado(es_personaje_1 : bool)
signal ha_bloqueado(es_personaje_1 : bool)
signal escudo_roto(es_personaje_1 : bool)

signal ataque_especial_activado(es_personaje_1 : bool)
signal salud_acabada(es_personaje_1 : bool)

const SALUD_MAXIMA : int = 200

var salud : int = SALUD_MAXIMA

const PODER_MAXIMO : int = 100
var poder : int = 100

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player : AnimationPlayer = $AnimationPlayer

# voltea graficos y animaciones en caso de ser jugador 2
@export var es_personaje_1 : bool = false 
@export var es_ia : bool = false
# @export var spriteframe_personaje : SpriteFrames # Cambia sprites de personaje 
var nombre_personaje : String

var frame_actual_de_animacion : int # Información debug

var PAUSADO : bool = false

# Indicativo de la acción que se está realizando
var ESTADO_ACTUAL : StringName = "idle"

# Indica si es vulnerable o no en el frame actual
var PUEDE_SER_ATACADO : bool = true

# Indica si puede tomar input en el frame actual
var PUEDE_RECIBIR_INPUT : bool = true

var input_buffer : StringName = "vacio"
var ataque_buffer : StringName = "vacio"

var input_action_ataque_debil = "ataque_debil"
var input_action_ataque_fuerte = "ataque_fuerte"
var input_action_esquivar = "esquivar"
var input_action_bloquear = "bloquear"
var sufijo_personaje : String = "_p1"

var delay_esquivar = 0
var delay_final = 0

var dificultad_partida = ConfigPartida.dificultad_ia

# Debuggin 
func _process(_delta: float) -> void:
	if PAUSADO : return
	actualizar_debug_info()
	if es_personaje_1:
		ConfigPartida.salud_p1 = salud

	if es_ia and ConfigPartida.tiempo>0 and ConfigPartida.salud_p1>0 and salud>0:
		comportamiento_ia()

	if ConfigPartida.salud_p1<=0 or salud<=0 or ConfigPartida.tiempo<=0:
		
		delay_final = 15
		
	if delay_final>0:
		delay_final-=1
		if delay_final==0:
	
			pausar()
	
		

# Inicia parametros necesarios para la partida
func _ready() -> void:
	animation_player.connect("animation_finished", _on_animation_finished)
	sprite.connect("frame_changed", _on_frame_changed)
	sprite.connect("animation_finished", _on_sprite_animation_finished)

	# Carga sprites del personaje
	#set_personaje(nombre_personaje)

	# Cambia al estado inicial
	reset()

	# Voltea sprite del personaje si esta en la parte derecha de la pantalla
	if not es_personaje_1:
		sufijo_personaje = "_p2"
		voltear_sprite()
	
	input_action_ataque_debil += sufijo_personaje
	input_action_ataque_fuerte += sufijo_personaje
	input_action_esquivar += sufijo_personaje
	input_action_bloquear += sufijo_personaje

func comportamiento_ia():
	#se encarga de aumentar la dificultad en el ultimo tramo de la partida
	if ConfigPartida.tiempo==15:
		if dificultad_partida=="facil":
			dificultad_partida="medio"
		if dificultad_partida=="medio":
			dificultad_partida="dificil"
		
	if delay_esquivar>0:
		delay_esquivar-=1
		if delay_esquivar==0:
			input_buffer = "esquivar"
	else:
		if PUEDE_RECIBIR_INPUT:
			if Input.is_action_just_pressed("A_p1"):
				asignar_probabilidad([10,10,25,25],[25,15,40,15],[55,10,35,5])
				
			elif Input.is_action_just_pressed("B_p1"):
				asignar_probabilidad([10,25,25,25],[20,10,30,30],[10,5,40,40])
			elif Input.is_action_just_pressed("X_p1"):
				asignar_probabilidad([25,20,20,20],[15,35,20,20],[5,60,15,15])
			elif Input.is_action_just_pressed("Y_p1"):
				asignar_probabilidad([25,20,20,20],[15,35,20,20],[5,60,15,15])
					
					
			else:
				var rango_accion
				match ConfigPartida.dificultad_ia:
					"facil":
						rango_accion = 100
					"medio":
						rango_accion = 30
					"dificil":
						rango_accion = 15
						
				if randi_range(1, rango_accion) == 1: 
					
					accion_ia(40,40,10,10)
						
func asignar_probabilidad(p_facil,p_medio,p_dificil):
	match ConfigPartida.dificultad_ia:
		"facil":
			accion_ia(p_facil[0],p_facil[1],p_facil[2],p_facil[3])
		"medio":
			accion_ia(p_medio[0],p_medio[1],p_medio[2],p_medio[3])
		"dificil":
			accion_ia(p_dificil[0],p_dificil[1],p_dificil[2],p_dificil[3])

#recibe la probabilidad de las 4 acciones del personaje
func accion_ia(p_a,p_b,p_x,p_y):
	var p_ataque_debil = p_a
	var p_ataque_fuerte = p_a+p_b
	var p_esquivar = p_a+p_b+p_x
	var p_bloquear = p_a+p_b+p_x+p_y
	var probabilidad = randi_range(1,100)
	
	if probabilidad>=0 and probabilidad<=p_ataque_debil: 
		input_buffer = "ataque_debil"
	elif probabilidad>p_ataque_debil and probabilidad<=p_ataque_fuerte:
		input_buffer = "ataque_fuerte"
	elif probabilidad>p_ataque_fuerte and probabilidad<=p_esquivar:
		if Input.is_action_just_pressed("A_p1"):
			delay_esquivar = 15
		else:
			input_buffer = "esquivar"
			
	elif probabilidad>p_esquivar and probabilidad<=p_bloquear:
		input_buffer = "bloquear"

func _unhandled_input(event: InputEvent) -> void:
	if es_ia:
		return
	if event.is_action(input_action_ataque_debil):
		input_buffer = "ataque_debil"
	elif event.is_action(input_action_ataque_fuerte):
		input_buffer = "ataque_fuerte"
	elif event.is_action(input_action_esquivar):
		input_buffer = "esquivar"
	elif event.is_action(input_action_bloquear):
		input_buffer = "bloquear"
	
func set_personaje(_nombre_personaje : String) -> void:
	nombre_personaje = _nombre_personaje
	sprite.sprite_frames = load("res://juego/personajes/assets/animaciones/" + nombre_personaje + ".tres")
	sprite.play()
	print("Sprites cambiados a: %s" % nombre_personaje)

func set_es_ia(_es_ia : bool) -> void:
	es_ia = _es_ia
#-----------------# Funciones que cambian el estado del personaje #-----------------#

func reset() -> void:
	set_estado("idle")
	play_animacion("idle")
	print("Reseteado")

func set_estado(estado : StringName) -> void:
	ESTADO_ACTUAL = estado

func set_puede_ser_atacado(valor : bool) -> void:
	PUEDE_SER_ATACADO = valor

func set_puede_recibir_input(valor : bool) -> void:
	PUEDE_RECIBIR_INPUT = valor


#-----------------# Funciones para debug #-----------------#

# Actualiza textos en pantalla con información del personaje
func actualizar_debug_info() -> void:
	$Debug/Estado.text = ESTADO_ACTUAL
	$Debug/Atacado.text = "PUEDE SER ATACADO = " + str(PUEDE_SER_ATACADO).to_upper()
	$Debug/Input.text = "PUEDE RECIBIR INPUT = " + str(PUEDE_RECIBIR_INPUT).to_upper()
	$Debug/Salud.text = "Salud = " + str(salud)


#-----------------# Funciones que cambian sprites y animaciones #-----------------#

# Cambia animación del sprite según la acción a realizar
func play_animacion(accion : StringName) -> void:
	print("Animación a reproducirse: %s" % accion)
	if ESTADO_ACTUAL == "herido" or ESTADO_ACTUAL == "ataque_especial" and salud > 0:
		animation_player.play("RESET")
		await animation_player.animation_finished
	
	
	var animacion : StringName
	match accion:
		"ataque_debil":
			# elige una animacion de golpe random
			if randi_range(1, 2) == 1: 
				animacion = "ataque_debil_1"
			else:
				animacion = "ataque_debil_2"

		# Hay dos animaciones de esquivo según la posicion del personaje en pantalla
		"esquivar": 
			animacion = "esquivar"
			if not es_personaje_1:
				animacion += "_volteado"

		"ataque_especial":
			animacion = "ataque_especial"
			if not es_personaje_1:
				animacion += "_volteado"

		"herido":
			animacion = "herido"

		_:
			# Las demás animaciones tienen el mismo nombre que las acciones
			animacion = accion
	
	# Reproduce la animación de la accion solicitada
	if salud > 0:
		animation_player.play(animacion)

# Se explica solo
func voltear_sprite() -> void:
	sprite.flip_h = true # voltea sprite
	%Burbuja.voltear() # Voltea escudo burbuja

	# Ajusta la posicion de la burbuja para quedar más al centro del sprite
	$AnimatedSprite2D/PosMitadSprite.position = Vector2(15, 0)

func set_spriteframe(_spriteframe : SpriteFrames) -> void:
	sprite.sprite_frames = _spriteframe

#-----------------# Funciones que se activan con signals #-----------------#

# Devuelve al estado inicial cuando se acaba una animación
func _on_sprite_animation_finished() -> void:
	if ESTADO_ACTUAL != "bloquear":
		pass # reset()

func _on_animation_finished(_animation : String) -> void:
	print("Animacion finalizada")
	if salud > 0:
		reset()

# Solo se procesa la logica del juego con cada cambio de frame
func _on_frame_changed() -> void:
	procesar_input_buffer()
	procesar_ataque_buffer()
	borrar_buffers()

func cargar_poder(_poder : int) -> void:
	if (poder + _poder) > PODER_MAXIMO:
		poder = PODER_MAXIMO
	elif (poder + _poder) < 0:
		poder = 0
	else:
		poder += _poder

func cargar_salud(_salud : int) -> void:
	var nueva_salud := salud + _salud
	if nueva_salud > SALUD_MAXIMA:
		salud = SALUD_MAXIMA
	elif nueva_salud <= 0:
		salud = 0
		emit_signal("salud_acabada", es_personaje_1)
		print("emitida señal salud acabada")
	else:
		salud += _salud

# Al ser atacado un personaje guarda el ataque recibido en el buffer
func ataque_a_buffer(tipo_ataque : StringName) -> void:
	ataque_buffer = tipo_ataque
	if es_personaje_1:
		ConfigPartida.input_p1 = input_buffer

#-----------------# Funciones que procesan los buffers #-----------------#

# Toma la acción solicitada y activa animación, de poderse
func procesar_input_buffer() -> void:
	if PAUSADO: return
	if PUEDE_RECIBIR_INPUT and input_buffer != "vacio":
		print("Procesando input: %s" % input_buffer)
		match ESTADO_ACTUAL:
			"ataque_fuerte":
				if input_buffer == "ataque_debil" and poder == PODER_MAXIMO:
					cargar_poder(-100)
					emit_signal("ataque_especial_activado", es_personaje_1)
					play_animacion("ataque_especial")
			_:
				play_animacion(input_buffer)

# Toma el ataque recibido y calcula la reaccion y el daño, de poderse
func procesar_ataque_buffer() -> void:
	print("Procesando ataque: %s" % ataque_buffer)
	match ataque_buffer:

		"ataque_debil":
			
			if ESTADO_ACTUAL == "bloquear":
				emit_signal("ha_bloqueado", es_personaje_1)

			elif ESTADO_ACTUAL == "esquivar" and not PUEDE_SER_ATACADO:
				emit_signal("ha_esquivado", es_personaje_1)

			else:
				cargar_salud(-20)
				#cargar_poder(-10)
				play_animacion("herido")
				
				

		"ataque_fuerte":
			if ESTADO_ACTUAL == "esquivar" and not PUEDE_SER_ATACADO:
				emit_signal("ha_esquivado", es_personaje_1)

			elif ESTADO_ACTUAL == "bloquear":
				emit_signal("escudo_roto", es_personaje_1)
				play_animacion("herido")
				cargar_salud(-10)

			else:
				cargar_salud(-30)
				#cargar_poder(-20)
				play_animacion("herido")

		
		"ataque_especial":
			if ESTADO_ACTUAL == "esquivar" and not PUEDE_SER_ATACADO:
				emit_signal("ha_esquivado", es_personaje_1)

			elif ESTADO_ACTUAL == "bloquear":
				emit_signal("escudo_roto", es_personaje_1)
				cargar_salud(-60)
				cargar_poder(-20)
				play_animacion("herido")

			else:
				cargar_salud(-70)
				#cargar_poder(-20)
				play_animacion("herido")
		_:
			pass

# Reinicia los buffers
func borrar_buffers() -> void:
	input_buffer = "vacio"
	ataque_buffer = "vacio"
	

#-----------------# Funciones que controlan la ejecucion del personaje #-----------------#

# Pausa la animacion, como la logica se procesa con cada cambio de frame
# pausar la lógica un personaje es tan simple como pausar la animación.
func pausar() -> void:
	print("pausado")
	PAUSADO = true
	sprite.pause()
	animation_player.pause()

# Reanuda animación, por ende, la ejecución
func reanudar() -> void:
	print("reanudado")
	PAUSADO = false
	sprite.play()
	animation_player.play()

# Emite señal de ataque
func atacar() -> void:
	ha_atacado.emit(es_personaje_1, ESTADO_ACTUAL)
	
# Inicia animación de escudo roto, no he podido abstraer esta función
# fuera del personaje ya que funciona de forma muy específica.
func romper_escudo() -> void:
	%Burbuja.romper_escudo()
