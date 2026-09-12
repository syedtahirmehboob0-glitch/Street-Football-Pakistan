extends Node3D

const MATCH_TIME: float = 180.0
const PLAYER_SPEED: float = 6.0
const SPRINT_SPEED: float = 9.0
const AI_SPEED: float = 5.0
const BALL_SPEED: float = 18.0
const PASS_SPEED: float = 15.0
const FIELD_X: float = 23.0
const FIELD_Z: float = 14.0
const LEVELS: Array[String] = ["LAHORE STREET", "KARACHI ROOFTOP", "PESHAWAR NIGHT", "ISLAMABAD CUP", "PAKISTAN FINAL"]
const LANDMARKS: Array[String] = ["BADSHAHI MOSQUE • LAHORE", "CLIFTON ROOFTOP • KARACHI", "BALA HISAR • PESHAWAR", "FAISAL MOSQUE • ISLAMABAD", "MINAR-E-PAKISTAN • LAHORE"]

class Player:
	var pos: Vector3
	var home: Vector3
	var team: int
	var pname: String
	var node: Node3D
	var facing: Vector3 = Vector3.RIGHT
	var role: String = "MID"
	func _init(p: Vector3, t: int, n: String, r: String = "MID") -> void:
		pos = p
		home = p
		team = t
		pname = n
		role = r

var home: Array = []
var away: Array = []
var controlled: Player
var selected: int = 0
var ball_pos: Vector3 = Vector3.ZERO
var ball_velocity: Vector3 = Vector3.ZERO
var ball_owner: Player = null
var ball_node: MeshInstance3D
var score: Array[int] = [0, 0]
var time_left: float = MATCH_TIME
var finished: bool = false
var sprinting: bool = false
var touch_dir: Vector2 = Vector2.ZERO
var switch_lock: float = 0.0
var world: Node3D
var camera: Camera3D
var ui: Control
var score_label: Label
var time_label: Label
var location_label: Label
var landmark_label: Label
var message_label: Label
var coins_label: Label
var level_index: int = 0
var coins: int = 0
var match_number: int = 1
var message_time: float = 0.0

func _ready() -> void:
	build_world()
	build_ui()
	reset_match(false)

func mat(c: Color, rough: float = 0.8) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m

func box(s: Vector3, c: Color, p: Vector3) -> MeshInstance3D:
	var n: MeshInstance3D = MeshInstance3D.new()
	var m: BoxMesh = BoxMesh.new()
	m.size = s
	n.mesh = m
	n.material_override = mat(c)
	n.position = p
	world.add_child(n)
	return n

func cyl(r: float, h: float, c: Color, p: Vector3) -> MeshInstance3D:
	var n: MeshInstance3D = MeshInstance3D.new()
	var m: CylinderMesh = CylinderMesh.new()
	m.top_radius = r
	m.bottom_radius = r
	m.height = h
	n.mesh = m
	n.material_override = mat(c)
	n.position = p
	world.add_child(n)
	return n

func build_world() -> void:
	world = Node3D.new()
	world.name = "GameWorld"
	add_child(world)
	var env_node: WorldEnvironment = WorldEnvironment.new()
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#789fbd")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.85
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env_node.environment = env
	world.add_child(env_node)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -30.0, 0.0)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	world.add_child(sun)
	camera = Camera3D.new()
	camera.position = Vector3(0.0, 25.0, 27.0)
	camera.fov = 54.0
	world.add_child(camera)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	camera.current = true
	build_pitch()
	build_scenery()
	make_ball()

func build_pitch() -> void:
	box(Vector3(60.0, 0.5, 42.0), Color("#101713"), Vector3(0.0, -0.5, 0.0))
	box(Vector3(46.0, 0.2, 28.0), Color("#168247"), Vector3.ZERO)
	box(Vector3(46.0, 0.05, 0.14), Color.WHITE, Vector3(0.0, 0.14, -14.0))
	box(Vector3(46.0, 0.05, 0.14), Color.WHITE, Vector3(0.0, 0.14, 14.0))
	box(Vector3(0.14, 0.05, 28.0), Color.WHITE, Vector3(-23.0, 0.14, 0.0))
	box(Vector3(0.14, 0.05, 28.0), Color.WHITE, Vector3(23.0, 0.14, 0.0))
	box(Vector3(0.12, 0.05, 28.0), Color.WHITE, Vector3(0.0, 0.14, 0.0))
	var circle: MeshInstance3D = MeshInstance3D.new()
	var cm: CylinderMesh = CylinderMesh.new()
	cm.top_radius = 4.2
	cm.bottom_radius = 4.2
	cm.height = 0.04
	cm.radial_segments = 48
	circle.mesh = cm
	circle.material_override = mat(Color.WHITE)
	circle.position = Vector3(0.0, 0.17, 0.0)
	world.add_child(circle)
	for x: float in [-23.5, 23.5]:
		box(Vector3(0.28, 2.8, 0.28), Color.WHITE, Vector3(x, 1.4, -3.4))
		box(Vector3(0.28, 2.8, 0.28), Color.WHITE, Vector3(x, 1.4, 3.4))
		box(Vector3(0.28, 0.28, 6.8), Color.WHITE, Vector3(x, 2.8, 0.0))
	for z: float in [-17.0, 17.0]:
		box(Vector3(58.0, 1.8, 2.0), Color("#303943"), Vector3(0.0, 0.8, z))
		for x: int in range(-25, 26, 4):
			box(Vector3(2.0, 0.7, 0.8), Color("#e1b83e"), Vector3(float(x), 2.0, z))

func build_scenery() -> void:
	box(Vector3(14.0, 5.0, 2.0), Color("#b88758"), Vector3(0.0, 2.5, -20.0))
	for x: float in [-7.0, 7.0]:
		cyl(0.8, 9.0, Color("#b88758"), Vector3(x, 4.5, -20.0))
	box(Vector3(5.0, 4.0, 2.0), Color("#69757d"), Vector3(-18.0, 2.0, -20.0))
	box(Vector3(5.0, 6.0, 2.0), Color("#955a3b"), Vector3(18.0, 3.0, -20.0))
	for x: float in [-28.0, 28.0]:
		cyl(0.22, 12.0, Color("#6b7378"), Vector3(x, 6.0, -8.0))
		cyl(0.8, 0.12, Color("#f6f0c8"), Vector3(x, 11.8, -8.0))

func build_ui() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	var hud: ColorRect = ColorRect.new()
	hud.color = Color(0.015, 0.035, 0.06, 0.88)
	hud.size = Vector2(1280.0, 76.0)
	ui.add_child(hud)
	location_label = make_label(Vector2(20.0, 9.0), 20, Color.WHITE)
	ui.add_child(location_label)
	landmark_label = make_label(Vector2(20.0, 39.0), 11, Color("#a9bfd5"))
	ui.add_child(landmark_label)
	score_label = make_label(Vector2(480.0, 8.0), 31, Color.WHITE)
	score_label.size = Vector2(320.0, 48.0)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(score_label)
	time_label = make_label(Vector2(1100.0, 14.0), 22, Color.WHITE)
	time_label.size = Vector2(150.0, 40.0)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui.add_child(time_label)
	coins_label = make_label(Vector2(960.0, 12.0), 13, Color("#f3d66a"))
	coins_label.size = Vector2(130.0, 24.0)
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui.add_child(coins_label)
	message_label = make_label(Vector2(390.0, 285.0), 32, Color.WHITE)
	message_label.size = Vector2(500.0, 65.0)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(message_label)

func make_label(p: Vector2, font_size: int, c: Color) -> Label:
	var l: Label = Label.new()
	l.position = p
	l.size = Vector2(300.0, 42.0)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", c)
	return l

func reset_match(advance_level: bool = false) -> void:
	if advance_level:
		level_index = (level_index + 1) % LEVELS.size()
		match_number += 1
	for p: Player in home:
		if is_instance_valid(p.node):
			p.node.queue_free()
	for p: Player in away:
		if is_instance_valid(p.node):
			p.node.queue_free()
	home.clear()
	away.clear()
	score = [0, 0]
	time_left = MATCH_TIME
	finished = false
	selected = 0
	var hp: Array[Vector3] = [Vector3(-12.0, 0.0, 0.0), Vector3(-7.0, 0.0, -6.0), Vector3(-7.0, 0.0, 6.0)]
	var hn: Array[String] = ["Hamza", "Daniyal", "Shahzaib"]
	var hr: Array[String] = ["CAPTAIN", "WINGER", "MID"]
	for i: int in range(3):
		var p: Player = Player.new(hp[i], 0, hn[i], hr[i])
		p.node = create_player(p, Color("#12a95b"))
		home.append(p)
	var ap: Array[Vector3] = [Vector3(12.0, 0.0, 0.0), Vector3(7.0, 0.0, -6.0), Vector3(7.0, 0.0, 6.0)]
	for i: int in range(3):
		var p: Player = Player.new(ap[i], 1, "Opponent %d" % (i + 1), "DEF")
		p.node = create_player(p, Color("#d83b3b"))
		away.append(p)
	controlled = home[0]
	ball_owner = controlled
	ball_pos = controlled.pos
	ball_velocity = Vector3.ZERO
	update_hud()
	show_message("KICK OFF!", 1.5)
	update_visuals()

func create_player(p: Player, c: Color) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = p.pname
	world.add_child(root)
	var body: MeshInstance3D = MeshInstance3D.new()
	var cm: CapsuleMesh = CapsuleMesh.new()
	cm.radius = 0.62
	cm.height = 1.9
	body.mesh = cm
	body.material_override = mat(c)
	body.position.y = 1.0
	root.add_child(body)
	var head: MeshInstance3D = MeshInstance3D.new()
	var sm: SphereMesh = SphereMesh.new()
	sm.radius = 0.35
	sm.height = 0.7
	head.mesh = sm
	head.material_override = mat(Color("#d79a73"))
	head.position.y = 2.18
	root.add_child(head)
	root.position = p.pos
	return root

func make_ball() -> void:
	ball_node = MeshInstance3D.new()
	var sm: SphereMesh = SphereMesh.new()
	sm.radius = 0.43
	sm.height = 0.86
	ball_node.mesh = sm
	ball_node.material_override = mat(Color.WHITE, 0.45)
	world.add_child(ball_node)

func _process(delta: float) -> void:
	if message_time > 0.0:
		message_time -= delta
		if message_time <= 0.0 and not finished:
			message_label.text = ""
	if finished:
		update_hud()
		update_visuals()
		return
	time_left = maxf(0.0, time_left - delta)
	switch_lock = maxf(0.0, switch_lock - delta)
	update_human(delta)
	update_ai(delta)
	update_ball(delta)
	check_goal()
	update_visuals()
	update_hud()
	if time_left <= 0.0:
		finish_match()

func move_direction() -> Vector3:
	var x: float = Input.get_axis("ui_left", "ui_right")
	var z: float = Input.get_axis("ui_up", "ui_down")
	if touch_dir.length() > 0.05:
		x = touch_dir.x
		z = touch_dir.y
	var d: Vector3 = Vector3(x, 0.0, z)
	return d.normalized() if d.length() > 0.05 else Vector3.ZERO

func update_human(delta: float) -> void:
	if controlled == null:
		return
	var d: Vector3 = move_direction()
	var speed: float = SPRINT_SPEED if sprinting or Input.is_key_pressed(KEY_SHIFT) else PLAYER_SPEED
	if d != Vector3.ZERO:
		controlled.pos += d * speed * delta
		controlled.facing = d
		controlled.pos.x = clampf(controlled.pos.x, -FIELD_X + 1.0, FIELD_X - 1.0)
		controlled.pos.z = clampf(controlled.pos.z, -FIELD_Z + 1.0, FIELD_Z - 1.0)
	if ball_owner == null and controlled.pos.distance_to(ball_pos) < 1.35:
		claim_ball(controlled)
	if ball_owner == controlled:
		var carry: Vector3 = d if d != Vector3.ZERO else controlled.facing
		ball_pos = controlled.pos + carry * 1.0 + Vector3(0.0, 0.35, 0.0)

func update_ai(delta: float) -> void:
	if ball_owner == null:
		var closest: Player = nearest_to_ball(away)
		var closest_home: Player = nearest_to_ball(home)
		if closest_home != null and closest_home.pos.distance_to(ball_pos) < 1.5:
			claim_ball(closest_home)
		elif closest != null and closest.pos.distance_to(ball_pos) < 1.4:
			claim_ball(closest)
	for p: Player in away:
		var target: Vector3
		if ball_owner == p:
			target = Vector3(-FIELD_X + 1.5, 0.0, 0.0)
		else:
			var marker: int = away.find(p)
			var z_home: float = [-6.0, 6.0, 0.0][marker]
			target = Vector3(3.0, 0.0, z_home)
			if ball_owner != null and ball_owner.team == 0:
				target = ball_owner.pos + Vector3(2.0, 0.0, 0.0)
		var dir: Vector3 = p.pos.direction_to(target)
		if dir.length() > 0.05:
			p.pos += dir * AI_SPEED * delta
			p.facing = dir
		p.pos.x = clampf(p.pos.x, -FIELD_X + 1.0, FIELD_X - 1.0)
		p.pos.z = clampf(p.pos.z, -FIELD_Z + 1.0, FIELD_Z - 1.0)
		if ball_owner == p:
			ball_pos = p.pos + p.facing * 1.0 + Vector3(0.0, 0.35, 0.0)
			if p.pos.x < -14.0 and absf(p.pos.z) < 7.0:
				ball_velocity = p.pos.direction_to(Vector3(-FIELD_X - 2.0, 0.0, 0.0)) * BALL_SPEED
				ball_owner = null
	for p: Player in home:
		if p == controlled or p == ball_owner:
			continue
		var home_target: Vector3 = p.home
		if ball_owner != null and ball_owner.team == 0:
			home_target = ball_owner.pos + Vector3(-3.0, 0.0, float(home.find(p) - 1) * 4.0)
		elif ball_owner != null and ball_owner.team == 1:
			home_target = ball_owner.pos + Vector3(3.0, 0.0, float(home.find(p) - 1) * 2.5)
		p.pos = p.pos.lerp(home_target, minf(1.0, delta * 1.8))

func nearest_to_ball(players: Array) -> Player:
	var best: Player = null
	var best_distance: float = 9999.0
	for p: Player in players:
		var d: float = p.pos.distance_to(ball_pos)
		if d < best_distance:
			best_distance = d
			best = p
	return best

func claim_ball(p: Player) -> void:
	ball_owner = p
	ball_velocity = Vector3.ZERO
	ball_pos = p.pos + p.facing * 0.8 + Vector3(0.0, 0.35, 0.0)

func update_ball(delta: float) -> void:
	if ball_owner != null:
		return
	ball_pos += ball_velocity * delta
	ball_velocity = ball_velocity.move_toward(Vector3.ZERO, 13.0 * delta)
	if absf(ball_pos.z) > FIELD_Z:
		ball_pos.z = clampf(ball_pos.z, -FIELD_Z, FIELD_Z)
		ball_velocity.z *= -0.72

func shoot_ball() -> void:
	if finished or controlled == null or ball_owner != controlled:
		return
	var d: Vector3 = move_direction()
	if d == Vector3.ZERO:
		d = Vector3.RIGHT
	ball_velocity = d * BALL_SPEED
	ball_owner = null
	show_message("SHOOT!", 0.55)

func pass_ball() -> void:
	if finished or controlled == null or ball_owner != controlled:
		return
	var target: Player = nearest_teammate()
	if target == null:
		return
	ball_velocity = controlled.pos.direction_to(target.pos) * PASS_SPEED
	ball_owner = null
	show_message("PASS", 0.55)

func switch_player() -> void:
	if switch_lock > 0.0 or home.is_empty():
		return
	selected = (selected + 1) % home.size()
	controlled = home[selected]
	switch_lock = 0.35
	show_message("%s • %s" % [controlled.pname, controlled.role], 0.65)

func nearest_teammate() -> Player:
	var best: Player = null
	var best_distance: float = 9999.0
	for p: Player in home:
		if p == controlled:
			continue
		var d: float = controlled.pos.distance_to(p.pos)
		if d < best_distance:
			best_distance = d
			best = p
	return best

func check_goal() -> void:
	if ball_pos.x > FIELD_X + 1.0 and absf(ball_pos.z) < 3.4:
		score[0] += 1
		coins += 50
		show_message("GOAL! PAKISTAN +1", 1.8)
		kickoff_after_goal()
	elif ball_pos.x < -FIELD_X - 1.0 and absf(ball_pos.z) < 3.4:
		score[1] += 1
		show_message("GOAL AGAINST", 1.8)
		kickoff_after_goal()

func kickoff_after_goal() -> void:
	ball_velocity = Vector3.ZERO
	for i: int in range(home.size()):
		home[i].pos = home[i].home
	for i: int in range(away.size()):
		away[i].pos = away[i].home
	controlled = home[selected]
	ball_owner = controlled
	ball_pos = controlled.pos

func finish_match() -> void:
	finished = true
	if score[0] > score[1]:
		coins += 100
		show_message("FULL TIME • WIN!  +100 COINS", 999.0)
	elif score[0] == score[1]:
		coins += 25
		show_message("FULL TIME • DRAW  +25 COINS", 999.0)
	else:
		show_message("FULL TIME • TRY AGAIN", 999.0)

func update_visuals() -> void:
	for p: Player in home:
		if is_instance_valid(p.node):
			p.node.position = p.pos
			p.node.rotation.y = atan2(p.facing.x, p.facing.z)
	for p: Player in away:
		if is_instance_valid(p.node):
			p.node.position = p.pos
			p.node.rotation.y = atan2(p.facing.x, p.facing.z)
	if is_instance_valid(ball_node):
		ball_node.position = ball_pos
		ball_node.rotation.x += 0.12

func update_hud() -> void:
	if not is_instance_valid(score_label):
		return
	location_label.text = "%s  •  MATCH %02d" % [LEVELS[level_index], match_number]
	landmark_label.text = LANDMARKS[level_index]
	score_label.text = "%d   —   %d" % [score[0], score[1]]
	var seconds: int = int(ceil(time_left))
	time_label.text = "%02d:%02d" % [seconds / 60, seconds % 60]
	coins_label.text = "COINS  %d" % coins

func show_message(text: String, duration: float) -> void:
	if is_instance_valid(message_label):
		message_label.text = text
		message_time = duration
