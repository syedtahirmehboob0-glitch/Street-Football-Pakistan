extends Node3D

const FIELD_X := 22.0
const FIELD_Z := 12.0
const MATCH_LENGTH := 180.0
const PLAYER_SPEED := 6.0
const SPRINT_SPEED := 8.5
const BALL_SPEED := 14.0
const PASS_SPEED := 10.0

class Player:
	var pos := Vector3.ZERO
	var home := Vector3.ZERO
	var team := 0
	var role := 0
	var pname := "Player"
	var node: Node3D
	var active := false
	var cooldown := 0.0

	func _init(start_pos: Vector3, team_id: int, player_role: int, player_name: String) -> void:
		pos = start_pos
		home = start_pos
		team = team_id
		role = player_role
		pname = player_name

var pakistan: Array[Player] = []
var opponents: Array[Player] = []
var controlled: Player
var ball_pos := Vector3.ZERO
var ball_velocity := Vector3.ZERO
var ball_owner: Player = null
var score := [0, 0]
var time_left := MATCH_LENGTH
var finished := false
var message := ""
var message_time := 0.0

var camera: Camera3D
var ui: CanvasLayer
var score_label: Label
var timer_label: Label
var message_label: Label
var ball_node: MeshInstance3D

func _ready() -> void:
	create_world()
	reset_match()

func make_material(color: Color, metallic := 0.0, roughness := 0.7) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	return mat

func make_box(size: Vector3, color: Color, parent: Node3D, pos: Vector3) -> MeshInstance3D:
	var mesh_node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_node.mesh = mesh
	mesh_node.material_override = make_material(color)
	mesh_node.position = pos
	parent.add_child(mesh_node)
	return mesh_node

func create_world() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#102030")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#c7d8ff")
	env.ambient_light_energy = 0.7
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -25.0, 0.0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)

	camera = Camera3D.new()
	camera.position = Vector3(0.0, 19.0, 19.0)
	camera.rotation_degrees = Vector3(-48.0, 0.0, 0.0)
	camera.current = true
	add_child(camera)

	create_field()
	create_stands()
	create_ui()

func create_field() -> void:
	make_box(Vector3(48.0, 0.25, 30.0), Color("#142018"), self, Vector3(0.0, -0.3, 0.0))
	make_box(Vector3(42.0, 0.18, 24.0), Color("#1d7a42"), self, Vector3.ZERO)

	make_box(Vector3(42.0, 0.05, 0.12), Color.WHITE, self, Vector3(0.0, 0.1, -12.0))
	make_box(Vector3(42.0, 0.05, 0.12), Color.WHITE, self, Vector3(0.0, 0.1, 12.0))
	make_box(Vector3(0.12, 0.05, 24.0), Color.WHITE, self, Vector3(-21.0, 0.1, 0.0))
	make_box(Vector3(0.12, 0.05, 24.0), Color.WHITE, self, Vector3(21.0, 0.1, 0.0))
	make_box(Vector3(0.10, 0.05, 24.0), Color.WHITE, self, Vector3(0.0, 0.1, 0.0))

	var circle_outer := MeshInstance3D.new()
	var outer_mesh := CylinderMesh.new()
	outer_mesh.top_radius = 4.0
	outer_mesh.bottom_radius = 4.0
	outer_mesh.height = 0.06
	outer_mesh.radial_segments = 64
	circle_outer.mesh = outer_mesh
	circle_outer.material_override = make_material(Color.WHITE)
	circle_outer.position = Vector3(0.0, 0.08, 0.0)
	add_child(circle_outer)

	var circle_inner := MeshInstance3D.new()
	var inner_mesh := CylinderMesh.new()
	inner_mesh.top_radius = 3.84
	inner_mesh.bottom_radius = 3.84
	inner_mesh.height = 0.08
	inner_mesh.radial_segments = 64
	circle_inner.mesh = inner_mesh
	circle_inner.material_override = make_material(Color("#1d7a42"))
	circle_inner.position = Vector3(0.0, 0.13, 0.0)
	add_child(circle_inner)

	make_box(Vector3(7.0, 0.06, 0.10), Color.WHITE, self, Vector3(-17.5, 0.11, -3.2))
	make_box(Vector3(7.0, 0.06, 0.10), Color.WHITE, self, Vector3(-17.5, 0.11, 3.2))
	make_box(Vector3(7.0, 0.06, 0.10), Color.WHITE, self, Vector3(17.5, 0.11, -3.2))
	make_box(Vector3(7.0, 0.06, 0.10), Color.WHITE, self, Vector3(17.5, 0.11, 3.2))
	make_box(Vector3(0.10, 0.06, 6.4), Color.WHITE, self, Vector3(-14.0, 0.11, 0.0))
	make_box(Vector3(0.10, 0.06, 6.4), Color.WHITE, self, Vector3(14.0, 0.11, 0.0))

	create_goal(Vector3(-21.7, 0.0, 0.0))
	create_goal(Vector3(21.7, 0.0, 0.0))

func create_goal(pos: Vector3) -> void:
	var goal_color := Color("#e8e8e8")
	make_box(Vector3(0.25, 2.4, 0.25), goal_color, self, pos + Vector3(0.0, 1.2, -3.2))
	make_box(Vector3(0.25, 2.4, 0.25), goal_color, self, pos + Vector3(0.0, 1.2, 3.2))
	make_box(Vector3(0.25, 0.25, 6.5), goal_color, self, pos + Vector3(0.0, 2.4, 0.0))

func create_stands() -> void:
	for z in [-15.0, 15.0]:
		make_box(Vector3(48.0, 1.4, 2.0), Color("#30343d"), self, Vector3(0.0, 0.5, z))
		for x in range(-20, 21, 4):
			make_box(Vector3(2.4, 0.8, 0.8), Color("#d7a62b"), self, Vector3(float(x), 1.5, z))

func create_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)

	var top_panel := ColorRect.new()
	top_panel.color = Color(0.02, 0.04, 0.07, 0.82)
	top_panel.position = Vector2.ZERO
	top_panel.size = Vector2(1280, 90)
	ui.add_child(top_panel)

	var title := Label.new()
	title.text = "STREET FOOTBALL: PAKISTAN  •  3D"
	title.position = Vector2(28, 24)
	title.add_theme_font_size_override("font_size", 23)
	ui.add_child(title)

	score_label = Label.new()
	score_label.position = Vector2(565, 18)
	score_label.add_theme_font_size_override("font_size", 34)
	ui.add_child(score_label)

	timer_label = Label.new()
	timer_label.position = Vector2(1100, 24)
	timer_label.add_theme_font_size_override("font_size", 28)
	ui.add_child(timer_label)

	var controls := Label.new()
	controls.text = "WASD / ARROWS Move    SHIFT Sprint    SPACE Shoot    E Pass    TAB Switch    R Restart"
	controls.position = Vector2(28, 94)
	controls.add_theme_font_size_override("font_size", 15)
	ui.add_child(controls)

	message_label = Label.new()
	message_label.position = Vector2(390, 300)
	message_label.size = Vector2(500, 130)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 32)
	ui.add_child(message_label)

	var shoot_button := Button.new()
	shoot_button.text = "SHOOT"
	shoot_button.position = Vector2(1080, 535)
	shoot_button.size = Vector2(130, 90)
	shoot_button.add_theme_font_size_override("font_size", 20)
	shoot_button.pressed.connect(shoot_ball)
	ui.add_child(shoot_button)

	var pass_button_ui := Button.new()
	pass_button_ui.text = "PASS"
	pass_button_ui.position = Vector2(930, 610)
	pass_button_ui.size = Vector2(110, 70)
	pass_button_ui.add_theme_font_size_override("font_size", 18)
	pass_button_ui.pressed.connect(pass_ball)
	ui.add_child(pass_button_ui)

	var switch_button := Button.new()
	switch_button.text = "SWITCH"
	switch_button.position = Vector2(800, 610)
	switch_button.size = Vector2(110, 70)
	switch_button.add_theme_font_size_override("font_size", 16)
	switch_button.pressed.connect(switch_player)
	ui.add_child(switch_button)

	var move_label := Label.new()
	move_label.text = "◉\nMOVE"
	move_label.position = Vector2(78, 555)
	move_label.add_theme_font_size_override("font_size", 18)
	ui.add_child(move_label)

func reset_match() -> void:
	clear_players()
	score = [0, 0]
	time_left = MATCH_LENGTH
	finished = false
	message = ""
	message_time = 0.0

	var pakistan_positions := [Vector3(-12, 0, 0), Vector3(-7, 0, -5), Vector3(-7, 0, 5)]
	var pakistan_names := ["Hamza", "Daniyal", "Shahzaib"]
	for i in 3:
		var player := Player.new(pakistan_positions[i], 0, i, pakistan_names[i])
		pakistan.append(player)
		player.node = create_player_visual(player)

	var opponent_positions := [Vector3(12, 0, 0), Vector3(7, 0, -5), Vector3(7, 0, 5)]
	for i in 3:
		var opponent := Player.new(opponent_positions[i], 1, i, "Opponent %d" % (i + 1))
		opponents.append(opponent)
		opponent.node = create_player_visual(opponent)

	controlled = pakistan[0]
	controlled.active = true
	ball_pos = Vector3.ZERO
	ball_velocity = Vector3.ZERO
	ball_owner = null

	if is_instance_valid(ball_node):
		ball_node.queue_free()
	ball_node = MeshInstance3D.new()
	var ball_mesh := SphereMesh.new()
	ball_mesh.radius = 0.42
	ball_mesh.height = 0.84
	ball_mesh.radial_segments = 24
	ball_mesh.rings = 12
	ball_node.mesh = ball_mesh
	ball_node.material_override = make_material(Color("#f4f4f4"), 0.05, 0.3)
	add_child(ball_node)
	update_visuals()

func clear_players() -> void:
	for player in pakistan:
		if is_instance_valid(player.node):
			player.node.queue_free()
	for player in opponents:
		if is_instance_valid(player.node):
			player.node.queue_free()
	pakistan.clear()
	opponents.clear()

func create_player_visual(player: Player) -> Node3D:
	var root := Node3D.new()
	add_child(root)

	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.55
	body_mesh.height = 1.6
	body_mesh.radial_segments = 16
	body.mesh = body_mesh
	body.material_override = make_material(Color("#178a4a") if player.team == 0 else Color("#c73838"))
	body.position.y = 0.9
	root.add_child(body)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.32
	head_mesh.height = 0.64
	head.mesh = head_mesh
	head.material_override = make_material(Color("#d99a72"))
	head.position.y = 1.95
	root.add_child(head)

	var shadow := MeshInstance3D.new()
	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius = 0.75
	shadow_mesh.bottom_radius = 0.75
	shadow_mesh.height = 0.03
	shadow.mesh = shadow_mesh
	shadow.material_override = make_material(Color(0, 0, 0, 0.25))
	shadow.position.y = 0.03
	root.add_child(shadow)

	root.position = player.pos
	return root

func _process(delta: float) -> void:
	if finished:
		if Input.is_key_pressed(KEY_R):
			reset_match()
		update_hud()
		update_visuals()
		return

	time_left = max(0.0, time_left - delta)
	if time_left <= 0.0:
		finished = true
		message = "FULL TIME"
	else:
		update_human(delta)
		update_ai(delta)
		update_ball(delta)
		check_goal()

	message_time = max(0.0, message_time - delta)
	update_hud()
	update_visuals()

func get_move_dir() -> Vector3:
	var x := Input.get_axis("ui_left", "ui_right")
	var z := Input.get_axis("ui_up", "ui_down")
	var direction := Vector3(x, 0.0, z)
	return direction.normalized() if direction.length() > 0.05 else Vector3.ZERO

func update_human(delta: float) -> void:
	var direction := get_move_dir()
	var speed := SPRINT_SPEED if Input.is_key_pressed(KEY_SHIFT) else PLAYER_SPEED
	if direction != Vector3.ZERO:
		controlled.pos += direction * speed * delta
		controlled.pos.x = clamp(controlled.pos.x, -20.0, 20.0)
		controlled.pos.z = clamp(controlled.pos.z, -10.5, 10.5)
		if ball_owner == controlled:
			ball_pos = controlled.pos + direction * 1.1
	if ball_owner == null and controlled.pos.distance_to(ball_pos) < 1.25:
		ball_owner = controlled

func update_ai(delta: float) -> void:
	var all_players := pakistan + opponents
	for player in all_players:
		if player == controlled:
			continue

		player.cooldown = max(0.0, player.cooldown - delta)
		var target := player.home
		var nearest := closest_player(player.team)

		if ball_owner != null and ball_owner.team == player.team:
			if player != ball_owner:
				target = player.home.lerp(ball_owner.pos, 0.3)
		elif nearest == player:
			target = ball_pos
		elif player.role == 0:
			target = player.home.lerp(ball_pos, 0.25)
		elif player.role == 1:
			target = player.home.lerp(ball_pos, 0.16)
		else:
			target = player.home.lerp(ball_pos, 0.08)

		var direction := player.pos.direction_to(target)
		var speed := 5.1 if player.team == 0 else 5.4
		player.pos += direction * speed * delta
		player.pos.x = clamp(player.pos.x, -20.0, 20.0)
		player.pos.z = clamp(player.pos.z, -10.5, 10.5)

		if ball_owner == null and player.pos.distance_to(ball_pos) < 1.1:
			ball_owner = player

		if ball_owner == player:
			var goal := Vector3(21.5, 0.0, 0.0) if player.team == 0 else Vector3(-21.5, 0.0, 0.0)
			ball_pos = player.pos + player.pos.direction_to(goal) * 1.0
			if player.pos.distance_to(goal) < 9.0 and player.cooldown <= 0.0:
				ball_velocity = player.pos.direction_to(goal) * BALL_SPEED
				ball_owner = null
				player.cooldown = 1.4

func closest_player(team_id: int) -> Player:
	var players := pakistan if team_id == 0 else opponents
	var best: Player = players[0]
	var best_distance := best.pos.distance_to(ball_pos)
	for player in players:
		var distance := player.pos.distance_to(ball_pos)
		if distance < best_distance:
			best_distance = distance
			best = player
	return best

func nearest_teammate() -> Player:
	var best: Player = null
	var best_distance := INF
	for player in pakistan:
		if player != controlled:
			var distance := player.pos.distance_to(controlled.pos)
			if distance < best_distance:
				best_distance = distance
				best = player
	return best

func update_ball(delta: float) -> void:
	if ball_owner != null:
		return
	ball_pos += ball_velocity * delta
	ball_velocity = ball_velocity.move_toward(Vector3.ZERO, 20.0 * delta)
	if abs(ball_pos.z) > 11.6:
		ball_velocity.z *= -0.75
	ball_pos.z = clamp(ball_pos.z, -11.6, 11.6)

func check_goal() -> void:
	if ball_pos.x < -22.0 and abs(ball_pos.z) < 3.2:
		score[1] += 1
		kickoff("OPPONENT SCORES")
	elif ball_pos.x > 22.0 and abs(ball_pos.z) < 3.2:
		score[0] += 1
		kickoff("PAKISTAN SCORES!")
	elif abs(ball_pos.x) > 23.5:
		ball_velocity.x *= -0.8
		ball_pos.x = clamp(ball_pos.x, -23.5, 23.5)

func kickoff(text: String) -> void:
	message = text
	message_time = 2.0
	ball_pos = Vector3.ZERO
	ball_velocity = Vector3.ZERO
	ball_owner = null
	for player in pakistan:
		player.pos = player.home
	for player in opponents:
		player.pos = player.home

func shoot_ball() -> void:
	if ball_owner != controlled:
		return
	var direction := get_move_dir()
	if direction == Vector3.ZERO:
		direction = Vector3.RIGHT
	ball_velocity = direction * BALL_SPEED
	ball_owner = null

func pass_ball() -> void:
	if ball_owner != controlled:
		return
	var teammate := nearest_teammate()
	if teammate == null:
		return
	var direction := controlled.pos.direction_to(teammate.pos)
	ball_velocity = direction * PASS_SPEED
	ball_owner = null

func switch_player() -> void:
	if pakistan.is_empty():
		return
	var current_index := pakistan.find(controlled)
	if current_index < 0:
		current_index = 0
	controlled.active = false
	for offset in range(1, pakistan.size() + 1):
		var next_index := (current_index + offset) % pakistan.size()
		if pakistan[next_index].pos.distance_to(ball_pos) < 12.0 or offset == pakistan.size():
			controlled = pakistan[next_index]
			controlled.active = true
			break

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			shoot_ball()
		elif event.keycode == KEY_E:
			pass_ball()
		elif event.keycode == KEY_TAB:
			switch_player()

func update_hud() -> void:
	if score_label != null:
		score_label.text = "PAKISTAN  %d  -  %d  OPPONENT" % [score[0], score[1]]
	if timer_label != null:
		var total_seconds := int(ceil(time_left))
		var minutes := total_seconds / 60
		var seconds := total_seconds % 60
		timer_label.text = "%02d:%02d" % [minutes, seconds]
	if message_label != null:
		message_label.text = message if message_time > 0.0 or finished else ""

func update_visuals() -> void:
	for player in pakistan:
		if is_instance_valid(player.node):
			player.node.position = player.pos
	for player in opponents:
		if is_instance_valid(player.node):
			player.node.position = player.pos
	if is_instance_valid(ball_node):
		ball_node.position = ball_pos + Vector3(0.0, 0.42, 0.0)
