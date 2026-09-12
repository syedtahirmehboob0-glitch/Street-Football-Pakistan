extends Node3D

const FIELD_X := 22.0
const FIELD_Z := 12.0
const MATCH_LENGTH := 180.0
const PLAYER_SPEED := 6.0
const SPRINT_SPEED := 8.5
const BALL_SPEED := 14.0
const PASS_SPEED := 10.0
const GOAL_Z := 3.2

class Player:
 var pos := Vector3.ZERO
 var home := Vector3.ZERO
 var team := 0
 var role := 0
 var pname := "Player"
 var node: Node3D
 var active := false
 var velocity := Vector3.ZERO
 var cooldown := 0.0
 func _init(p: Vector3, t: int, r: int, n: String):
  pos=p; home=p; team=t; role=r; pname=n

var pakistan: Array[Player] = []
var opponents: Array[Player] = []
var controlled: Player
var ball_pos := Vector3.ZERO
var ball_velocity := Vector3.ZERO
var owner: Player = null
var score := [0, 0]
var time_left := MATCH_LENGTH
var finished := false
var message := ""
var message_time := 0.0
var camera: Camera3D
var camera_target := Vector3.ZERO
var ui: CanvasLayer
var score_label: Label
var timer_label: Label
var message_label: Label
var controls_label: Label
var joystick_center := Vector2(120, 600)
var joystick_vector := Vector2.ZERO
var joystick_active := false
var shoot_button := Rect2(1080, 535, 130, 90)
var pass_button := Rect2(930, 610, 110, 70)
var ball_node: MeshInstance3D
var rng := RandomNumberGenerator.new()

func _ready() -> void:
 rng.randomize()
 create_world()
 reset_match()

func create_world() -> void:
 var env := WorldEnvironment.new()
 var environment := Environment.new()
 environment.background_mode = Environment.BG_COLOR
 environment.background_color = Color("#102030")
 environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 environment.ambient_light_color = Color("#c7d8ff")
 environment.ambient_light_energy = 0.65
 environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 env.environment = environment
 add_child(env)

 var sun := DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-55, -25, 0)
 sun.light_energy = 1.2
 sun.shadow_enabled = true
 add_child(sun)

 camera = Camera3D.new()
 camera.position = Vector3(0, 18, 18)
 camera.rotation_degrees = Vector3(-48, 0, 0)
 camera.current = true
 add_child(camera)

 create_field()
 create_stands()
 create_ui()

func material(color: Color, metallic := 0.0, roughness := 0.7) -> StandardMaterial3D:
 var m := StandardMaterial3D.new()
 m.albedo_color = color
 m.metallic = metallic
 m.roughness = roughness
 return m

func box(size: Vector3, color: Color, parent: Node3D, pos: Vector3) -> MeshInstance3D:
 var n := MeshInstance3D.new()
 var mesh := BoxMesh.new()
 mesh.size = size
 n.mesh = mesh
 n.material_override = material(color)
 n.position = pos
 parent.add_child(n)
 return n

func create_field() -> void:
 box(Vector3(48, 0.25, 30), Color("#142018"), self, Vector3(0,-0.3,0))
 box(Vector3(42, 0.18, 24), Color("#1d7a42"), self, Vector3(0,0,0))

 var white := material(Color.WHITE)
 box(Vector3(42,0.05,0.12), Color.WHITE, self, Vector3(0,0,12))
 box(Vector3(42,0.05,0.12), Color.WHITE, self, Vector3(0,0,-12))
 box(Vector3(0.12,0.05,24), Color.WHITE, self, Vector3(-21,0,0))
 box(Vector3(0.12,0.05,24), Color.WHITE, self, Vector3(21,0,0))
 box(Vector3(0.10,0.05,24), Color.WHITE, self, Vector3(0,0,0))

 var circle := MeshInstance3D.new()
 var cyl := CylinderMesh.new()
 cyl.top_radius = 4.0
 cyl.bottom_radius = 4.0
 cyl.height = 0.06
 cyl.radial_segments = 64
 circle.mesh = cyl
 circle.material_override = material(Color("#ffffff"))
 circle.position = Vector3(0,0.04,0)
 circle.scale = Vector3(1,1,1)
 add_child(circle)

 # Centre grass overlay keeps the line visible as a thin ring.
 var center_disc := MeshInstance3D.new()
 var disc := CylinderMesh.new()
 disc.top_radius = 3.85
 disc.bottom_radius = 3.85
 disc.height = 0.07
 disc.radial_segments = 64
 center_disc.mesh = disc
 center_disc.material_override = material(Color("#1d7a42"))
 center_disc.position = Vector3(0,0.08,0)
 add_child(center_disc)

 # Penalty boxes and goals.
 box(Vector3(7.0,0.06,0.10),Color.WHITE,self,Vector3(-14,0.06,0))
 box(Vector3(7.0,0.06,0.10),Color.WHITE,self,Vector3(14,0.06,0))
 box(Vector3(0.10,0.06,12),Color.WHITE,self,Vector3(-17.5,0.06,0))
 box(Vector3(0.10,0.06,12),Color.WHITE,self,Vector3(17.5,0.06,0))
 create_goal(Vector3(-21.7,0,0),-1)
 create_goal(Vector3(21.7,0,0),1)

func create_goal(p: Vector3, direction: int) -> void:
 var post_color := Color("#e8e8e8")
 box(Vector3(0.25,2.4,0.25),post_color,self,p+Vector3(0,1.2,-3.2))
 box(Vector3(0.25,2.4,0.25),post_color,self,p+Vector3(0,1.2,3.2))
 box(Vector3(0.25,0.25,6.5),post_color,self,p+Vector3(0,2.4,0))

func create_stands() -> void:
 for z in [-15.0,15.0]:
  box(Vector3(48,1.4,2.0),Color("#30343d"),self,Vector3(0,0.5,z))
  for x in range(-20,21,4):
   box(Vector3(2.4,0.8,0.8),Color("#d7a62b"),self,Vector3(x,1.5,z))

func create_ui() -> void:
 ui=CanvasLayer.new(); add_child(ui)
 var panel:=ColorRect.new(); panel.color=Color(0.02,0.04,0.07,0.78); panel.position=Vector2(0,0); panel.size=Vector2(1280,90); ui.add_child(panel)
 score_label=Label.new(); score_label.position=Vector2(565,18); score_label.add_theme_font_size_override("font_size",34); ui.add_child(score_label)
 timer_label=Label.new(); timer_label.position=Vector2(1100,24); timer_label.add_theme_font_size_override("font_size",28); ui.add_child(timer_label)
 var title:=Label.new(); title.text="STREET FOOTBALL: PAKISTAN  •  3D"; title.position=Vector2(28,24); title.add_theme_font_size_override("font_size",23); ui.add_child(title)
 controls_label=Label.new(); controls_label.position=Vector2(28,92); controls_label.text="WASD / ARROWS  Move    SHIFT  Sprint    SPACE  Shoot    E  Pass    TAB  Switch"; controls_label.add_theme_font_size_override("font_size",15); ui.add_child(controls_label)
 message_label=Label.new(); message_label.position=Vector2(405,310); message_label.size=Vector2(470,120); message_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; message_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; message_label.add_theme_font_size_override("font_size",32); ui.add_child(message_label)

 var shoot:=Button.new(); shoot.text="SHOOT"; shoot.position=Vector2(1080,535); shoot.size=Vector2(130,90); shoot.add_theme_font_size_override("font_size",20); shoot.pressed.connect(shoot_ball); ui.add_child(shoot)
 var pass:=Button.new(); pass.text="PASS"; pass.position=Vector2(930,610); pass.size=Vector2(110,70); pass.add_theme_font_size_override("font_size",18); pass.pressed.connect(pass_ball); ui.add_child(pass)
 var switch_b:=Button.new(); switch_b.text="SWITCH"; switch_b.position=Vector2(800,610); switch_b.size=Vector2(110,70); switch_b.add_theme_font_size_override("font_size",16); switch_b.pressed.connect(switch_player); ui.add_child(switch_b)
 var joy:=Label.new(); joy.text="◉\nMOVE"; joy.position=Vector2(78,555); joy.add_theme_font_size_override("font_size",18); joy.modulate=Color(0.8,0.9,1); ui.add_child(joy)

func clear_players() -> void:
 for p in pakistan + opponents:
  if is_instance_valid(p.node): p.node.queue_free()
 pakistan.clear(); opponents.clear()

func reset_match() -> void:
 clear_players()
 score=[0,0]; time_left=MATCH_LENGTH; finished=false; message=""; message_time=0
 var pp=[Vector3(-12,0,0),Vector3(-7,0,-5),Vector3(-7,0,5)]
 var nn=["Hamza","Daniyal","Shahzaib"]
 for i in 3:
  var p:=Player.new(pp[i],0,i,nn[i]); pakistan.append(p); p.node=create_player_visual(p)
 var op=[Vector3(12,0,0),Vector3(7,0,-5),Vector3(7,0,5)]
 for i in 3:
  var p:=Player.new(op[i],1,i,"Opponent %d"%(i+1)); opponents.append(p); p.node=create_player_visual(p)
 controlled=pakistan[0]; controlled.active=true
 ball_pos=Vector3.ZERO; ball_velocity=Vector3.ZERO; owner=null
 if is_instance_valid(ball_node): ball_node.queue_free()
 ball_node=MeshInstance3D.new()
 var sphere:=SphereMesh.new(); sphere.radius=0.42; sphere.height=0.84; sphere.radial_segments=24; sphere.rings=12
 ball_node.mesh=sphere; ball_node.material_override=material(Color("#f4f4f4"),0.05,0.3); add_child(ball_node)
 update_visuals()

func create_player_visual(p: Player) -> Node3D:
 var root:=Node3D.new(); add_child(root)
 var body:=MeshInstance3D.new(); var capsule:=CapsuleMesh.new(); capsule.radius=0.55; capsule.height=1.6; capsule.radial_segments=16; body.mesh=capsule; body.material_override=material(Color("#178a4a") if p.team==0 else Color("#c73838")); body.position.y=0.9; root.add_child(body)
 var head:=MeshInstance3D.new(); var s:=SphereMesh.new(); s.radius=0.32; s.height=0.64; head.mesh=s; head.material_override=material(Color("#d99a72")); head.position.y=1.95; root.add_child(head)
 var shadow:=MeshInstance3D.new(); var sh:=CylinderMesh.new(); sh.top_radius=0.75; sh.bottom_radius=0.75; sh.height=0.03; shadow.mesh=sh; shadow.material_override=material(Color(0,0,0,0.25)); shadow.position.y=0.03; root.add_child(shadow)
 root.position=p.pos
 return root

func _process(delta: float) -> void:
 if finished:
  update_hud(); update_visuals(); return
 time_left=max(0.0,time_left-delta)
 if time_left<=0:
  finished=true; message="FULL TIME"
 else:
  update_human(delta)
  update_ai(delta)
  update_ball(delta)
  check_goal()
 message_time=max(0.0,message_time-delta)
 update_hud(); update_visuals()

func get_move_dir() -> Vector3:
 var d:=Input.get_vector("ui_left","ui_right","ui_up","ui_down")
 if joystick_active and joystick_vector.length()>0.1: d=joystick_vector
 return Vector3(d.x,0,d.y).normalized() if d.length()>0.05 else Vector3.ZERO

func update_human(delta: float) -> void:
 var d:=get_move_dir()
 var speed:=SPRINT_SPEED if Input.is_key_pressed(KEY_SHIFT) else PLAYER_SPEED
 if d.length()>0:
  controlled.velocity=d*speed; controlled.pos+=controlled.velocity*delta
  controlled.pos.x=clamp(controlled.pos.x,-20.0,20.0); controlled.pos.z=clamp(controlled.pos.z,-10.5,10.5)
  if owner==controlled: ball_pos=controlled.pos+d*1.1
 if owner==null and controlled.pos.distance_to(ball_pos)<1.25: owner=controlled

func update_ai(delta: float) -> void:
 var all:=pakistan+opponents
 for p in all:
  if p==controlled: continue
  p.cooldown=max(0.0,p.cooldown-delta)
  var target:=p.home
  var nearest:=closest_player(p.team)
  if owner!=null and owner.team==p.team:
   if p!=owner: target=p.home.lerp(owner.pos,0.3)
  elif nearest==p:
   target=ball_pos
  elif p.role==0:
   target=p.home.lerp(ball_pos,0.25)
  elif p.role==1:
   target=p.home.lerp(ball_pos,0.16)
  else:
   target=p.home.lerp(ball_pos,0.08)
  var dir:=p.pos.direction_to(target); var speed:=5.1 if p.team==0 else 5.4
  p.pos+=dir*speed*delta
  p.pos.x=clamp(p.pos.x,-20.0,20.0); p.pos.z=clamp(p.pos.z,-10.5,10.5)
  if owner==null and p.pos.distance_to(ball_pos)<1.1: owner=p
  if owner==p:
   var goal:=Vector3(21.5,0,0) if p.team==0 else Vector3(-21.5,0,0)
   ball_pos=p.pos+p.pos.direction_to(goal)*1.0
   if p.pos.distance_to(goal)<9.0 and p.cooldown<=0:
    ball_velocity=p.pos.direction_to(goal)*BALL_SPEED; owner=null; p.cooldown=1.4

func closest_player(team:int) -> Player:
 var arr:=pakistan if team==0 else opponents
 var best:Player=arr[0]; var dist:float=best.pos.distance_to(ball_pos)
 for p in arr:
  var d:float=p.pos.distance_to(ball_pos)
  if d<dist: dist=d; best=p
 return best

func update_ball(delta:float) -> void:
 if owner!=null: return
 ball_pos+=ball_velocity*delta
 ball_velocity=ball_velocity.move_toward(Vector3.ZERO,20.0*delta)
 if abs(ball_pos.z)>11.6: ball_velocity.z*=-0.75
 ball_pos.z=clamp(ball_pos.z,-11.6,11.6)

func check_goal() -> void:
 if ball_pos.x<-22.0 and abs(ball_pos.z)<3.2:
  score[1]+=1; kickoff("OPPONENT SCORES")
 elif ball_pos.x>22.0 and abs(ball_pos.z)<3.2:
  score[0]+=1; kickoff("PAKISTAN SCORES!")
 elif abs(ball_pos.x)>23.5:
  ball_velocity.x*=-0.8; ball_pos.x=clamp(ball_pos.x,-23.5,23.5)

func kickoff(text:String) -> void:
 message=text; message_time=2.0; ball_pos=Vector3.ZERO; ball_velocity=Vector3.ZERO; owner=null
 for p in pakistan: p.pos=p.home
 for p in opponents: p.pos=p.home

func shoot_ball() -> void:
 if owner!=controlled: return
 var d:=get_move_dir()
 if d.length()<0.1: d=Vector3.RIGHT
 ball_velocity=d*BALL_SPEED; owner=null

func pass_ball() -> void:
 if owner!=controlled: return
 var mate:=nearest_teammate()
 if mate!=null:
  ball_velocity=controlled.pos.direction_to(mate.pos)*PASS_SPEED; owner=null

func nearest_teammate()->Player:
 var best:Player=null; var dist:float=INF
 for p in pakistan:
  if p==controlled: continue
  var d:=controlled.pos.distance_to(p.pos)
  if d<dist: dist=d; best=p
 return best

func switch_player() -> void:
 var idx:=pakistan.find(controlled)
 controlled.active=false; idx=(idx+1)%pakistan.size(); controlled=pakistan[idx]; controlled.active=true

func _input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_SPACE: shoot_ball()
  elif event.keycode==KEY_E: pass_ball()
  elif event.keycode==KEY_TAB: switch_player()
  elif event.keycode==KEY_R and finished: reset_match()
 if event is InputEventScreenTouch:
  if event.position.distance_to(joystick_center)<120:
   joystick_active=event.pressed
   if not event.pressed: joystick_vector=Vector2.ZERO
   else: joystick_vector=(event.position-joystick_center).limit_length(80)/80
 if event is InputEventScreenDrag and joystick_active:
  joystick_vector=(event.position-joystick_center).limit_length(80)/80

func update_visuals()->void:
 for p in pakistan+opponents:
  if is_instance_valid(p.node):
   p.node.position=p.pos
   p.node.scale=Vector3.ONE*(1.08 if p.active else 1.0)
   if p.active: p.node.rotation.y=sin(Time.get_ticks_msec()/180.0)*0.03
 if is_instance_valid(ball_node):
  ball_node.position=ball_pos+Vector3(0,0.42,0)
  ball_node.rotate_z(0.08)

func update_hud()->void:
 score_label.text="%d  -  %d"%[score[0],score[1]]
 timer_label.text=format_time(time_left)
 if finished:
  message_label.text="FULL TIME\n%d - %d\nPress R to play again"%[score[0],score[1]]
 elif message_time>0:
  message_label.text=message
 else:
  message_label.text=""

func format_time(t:float)->String:
 return "%02d:%02d"%[int(t)/60,int(t)%60]
