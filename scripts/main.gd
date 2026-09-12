extends Node2D

const W := 1280.0
const H := 720.0
const MATCH_LENGTH := 180.0
const PLAYER_SPEED := 250.0
const SPRINT_SPEED := 360.0
const BALL_SPEED := 650.0
const PASS_SPEED := 430.0

class Player:
 var pos: Vector2
 var home: Vector2
 var team: int
 var role: int
 var pname: String
 var active := false
 func _init(p: Vector2, t: int, r: int, n: String):
  pos=p; home=p; team=t; role=r; pname=n

var pakistan: Array[Player] = []
var opponents: Array[Player] = []
var controlled: Player
var ball_pos := Vector2(W/2.0,H/2.0)
var ball_vel := Vector2.ZERO
var owner: Player = null
var score := [0,0]
var time_left := MATCH_LENGTH
var finished := false
var touch_start := Vector2.ZERO
var touch_dir := Vector2.ZERO
var touch_active := false
var message := ""
var message_time := 0.0

func _ready() -> void:
 reset_match()
 queue_redraw()

func reset_match() -> void:
 score=[0,0]; time_left=MATCH_LENGTH; finished=false; message=""; pakistan.clear(); opponents.clear()
 var pp=[Vector2(300,360),Vector2(390,250),Vector2(390,470)]
 var nn=["Hamza","Daniyal","Shahzaib"]
 for i in 3: pakistan.append(Player.new(pp[i],0,i,nn[i]))
 var op=[Vector2(980,360),Vector2(890,250),Vector2(890,470)]
 for i in 3: opponents.append(Player.new(op[i],1,i,"Opponent %d"%(i+1)))
 controlled=pakistan[0]; controlled.active=true; ball_pos=Vector2(W/2.0,H/2.0); ball_vel=Vector2.ZERO; owner=null

func _process(delta: float) -> void:
 if finished: queue_redraw(); return
 time_left=max(0.0,time_left-delta)
 if time_left<=0.0: finished=true; message="FULL TIME"
 else:
  update_human(delta); update_ai(delta); update_ball(delta); check_goal()
 message_time=max(0.0,message_time-delta); queue_redraw()

func input_dir() -> Vector2:
 var d:=Input.get_vector("ui_left","ui_right","ui_up","ui_down")
 if touch_active and touch_dir.length()>0.1: d=touch_dir
 return d.normalized() if d.length()>1.0 else d

func update_human(delta: float) -> void:
 var d:=input_dir(); var speed:=SPRINT_SPEED if Input.is_key_pressed(KEY_SHIFT) else PLAYER_SPEED
 if d.length()>0.05:
  controlled.pos+=d*speed*delta
  controlled.pos.x=clamp(controlled.pos.x,70.0,W-70.0); controlled.pos.y=clamp(controlled.pos.y,120.0,H-70.0)
  if owner==controlled: ball_pos=controlled.pos+d*34.0
 if owner==null and controlled.pos.distance_to(ball_pos)<42.0: owner=controlled

func update_ai(delta: float) -> void:
 var all:=pakistan+opponents
 for p in all:
  if p==controlled: continue
  var target:=p.home
  var nearest:=closest_player(p.team)
  if owner!=null and owner.team==p.team:
   if p!=owner: target=p.home.lerp(owner.pos,0.35)
  else:
   if nearest==p: target=ball_pos
   elif p.role==1: target=p.home.lerp(ball_pos,0.18)
   elif p.role==0: target=p.home.lerp(ball_pos,0.30)
   else: target=p.home.lerp(ball_pos,0.10)
  p.pos+=p.pos.direction_to(target)*(185.0 if p.team==0 else 200.0)*delta
  p.pos.x=clamp(p.pos.x,70.0,W-70.0); p.pos.y=clamp(p.pos.y,120.0,H-70.0)
  if owner==null and p.pos.distance_to(ball_pos)<38.0: owner=p
  if owner==p:
   var goal:=Vector2(W-35,H/2.0) if p.team==0 else Vector2(35,H/2.0)
   ball_pos=p.pos+p.pos.direction_to(goal)*30.0
   if p.pos.distance_to(goal)<330.0 and randf()<delta*0.8: ball_vel=p.pos.direction_to(goal)*BALL_SPEED; owner=null

func closest_player(team: int) -> Player:
 var arr:=pakistan if team==0 else opponents
 var best: Player=arr[0]; var dist: float=best.pos.distance_to(ball_pos)
 for p in arr:
  var d: float=p.pos.distance_to(ball_pos)
  if d<dist: dist=d; best=p
 return best

func update_ball(delta: float) -> void:
 if owner!=null: return
 ball_pos+=ball_vel*delta; ball_vel=ball_vel.move_toward(Vector2.ZERO,900.0*delta)
 if ball_pos.y<105.0 or ball_pos.y>H-45.0: ball_vel.y*=-0.8
 if ball_pos.x<35.0 or ball_pos.x>W-35.0: ball_vel.x*=-0.8
 ball_pos.y=clamp(ball_pos.y,105.0,H-45.0); ball_pos.x=clamp(ball_pos.x,35.0,W-35.0)

func check_goal() -> void:
 if ball_pos.x<28.0 and abs(ball_pos.y-H/2.0)<120.0: score[1]+=1; kickoff("OPPONENT SCORES")
 elif ball_pos.x>W-28.0 and abs(ball_pos.y-H/2.0)<120.0: score[0]+=1; kickoff("PAKISTAN SCORES!")

func kickoff(text: String) -> void:
 message=text; message_time=2.0; ball_pos=Vector2(W/2.0,H/2.0); ball_vel=Vector2.ZERO; owner=null
 for p in pakistan: p.pos=p.home
 for p in opponents: p.pos=p.home

func _input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_SPACE: shoot()
  elif event.keycode==KEY_E: pass_ball()
  elif event.keycode==KEY_TAB: switch_player()
  elif event.keycode==KEY_R and finished: reset_match()
 if event is InputEventScreenTouch:
  touch_active=event.pressed
  if event.pressed: touch_start=event.position
  else: touch_dir=Vector2.ZERO
 if event is InputEventScreenDrag and touch_active: touch_dir=(event.position-touch_start).limit_length(80.0)/80.0

func shoot() -> void:
 if owner==controlled:
  var d:=input_dir(); if d.length()<0.1: d=Vector2.RIGHT
  ball_vel=d*BALL_SPEED; owner=null

func pass_ball() -> void:
 if owner!=controlled: return
 var mate:=nearest_teammate()
 if mate!=null: ball_vel=controlled.pos.direction_to(mate.pos)*PASS_SPEED; owner=null

func nearest_teammate() -> Player:
 var best: Player=null; var dist: float=INF
 for p in pakistan:
  if p==controlled: continue
  var d: float=controlled.pos.distance_to(p.pos)
  if d<dist: dist=d; best=p
 return best

func switch_player() -> void:
 var idx:=pakistan.find(controlled); controlled.active=false; idx=(idx+1)%pakistan.size(); controlled=pakistan[idx]; controlled.active=true
 if owner!=null and owner.team==0: owner=controlled

func _draw() -> void:
 draw_rect(Rect2(0,0,W,H),Color("111111")); draw_rect(Rect2(35,105,W-70,H-145),Color("246b45")); draw_rect(Rect2(35,105,W-70,H-145),Color.WHITE,false,5)
 draw_line(Vector2(W/2,105),Vector2(W/2,H-40),Color.WHITE,3); draw_circle(Vector2(W/2,(H+65)/2),90,Color(1,1,1,0.03)); draw_arc(Vector2(W/2,(H+65)/2),90,0,TAU,64,Color.WHITE,3)
 draw_rect(Rect2(35,245,120,210),Color.WHITE,false,3); draw_rect(Rect2(W-155,245,120,210),Color.WHITE,false,3)
 for p in pakistan: draw_player(p,Color("16a34a"))
 for p in opponents: draw_player(p,Color("d43b3b"))
 draw_circle(ball_pos,11,Color.WHITE)
 draw_string(ThemeDB.fallback_font,Vector2(42,48),"STREET FOOTBALL: PAKISTAN",HORIZONTAL_ALIGNMENT_LEFT,-1,26,Color.WHITE)
 draw_string(ThemeDB.fallback_font,Vector2(570,52),"%d  -  %d"%[score[0],score[1]],HORIZONTAL_ALIGNMENT_LEFT,-1,34,Color.WHITE)
 draw_string(ThemeDB.fallback_font,Vector2(1090,48),format_time(time_left),HORIZONTAL_ALIGNMENT_LEFT,-1,26,Color.WHITE)
 draw_string(ThemeDB.fallback_font,Vector2(42,78),"WASD / ARROWS Move   SHIFT Sprint   SPACE Shoot   E Pass   TAB Switch",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color(0.8,0.8,0.8))
 if OS.has_feature("mobile") or touch_active:
  draw_circle(Vector2(125,600),78,Color(0,0,0,0.45)); draw_circle(Vector2(125,600)+touch_dir*45,30,Color(0.3,0.7,1,0.8)); draw_circle(Vector2(1110,590),48,Color(0.8,0.15,0.1,0.65)); draw_string(ThemeDB.fallback_font,Vector2(1080,598),"SHOOT",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)
 if message_time>0 or finished:
  draw_rect(Rect2(340,280,600,120),Color(0,0,0,0.72)); draw_string(ThemeDB.fallback_font,Vector2(450,350),message,HORIZONTAL_ALIGNMENT_LEFT,-1,32,Color.WHITE)
  if finished: draw_string(ThemeDB.fallback_font,Vector2(450,385),"Press R to play again",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color(0.8,0.8,0.8))

func draw_player(p: Player,c: Color) -> void:
 draw_circle(p.pos+Vector2(0,4),23,Color(0,0,0,0.35)); draw_circle(p.pos,20,c); draw_circle(p.pos+Vector2(0,-15),9,Color("f2c29b"))
 if p.active: draw_arc(p.pos,28,0,TAU,32,Color.WHITE,4)
 draw_string(ThemeDB.fallback_font,p.pos+Vector2(-30,38),p.pname,HORIZONTAL_ALIGNMENT_CENTER,60,12,Color.WHITE)

func format_time(t: float) -> String:
 return "%02d:%02d"%[int(t)/60,int(t)%60]
