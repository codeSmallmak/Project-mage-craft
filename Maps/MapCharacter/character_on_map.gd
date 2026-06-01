extends Node2D

var current_node: MapNode = null
var previous_node: MapNode = null
var goal_node: MapNode = null
var is_moving: bool = false
var move_speed: float = 50.0
var last_position: Vector2 = Vector2.ZERO
signal node_entered(map_node: MapNode)
signal node_exited(map_node: MapNode)
var last_direction: String = "down"

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var anim_player: AnimationPlayer = $SharedCharacterAnimations.get_child(1)
@onready var CharacterTexture =  $SharedCharacterAnimations.get_child(0)


func _ready() -> void:
	if SaveManager.save_data.has("current_node"):
		var node_name = SaveManager.save_data["current_node"]
		if node_name != "":
			var results = get_tree().get_nodes_in_group("map_nodes").filter(
				func(n): return n.name == node_name
			)
			if not results.is_empty():
				global_position = results.front().global_position

	if SaveManager.save_data.has("previous_node"):
		var prev_name = SaveManager.save_data["previous_node"]
		if prev_name != "":
			var results = get_tree().get_nodes_in_group("map_nodes").filter(
				func(n): return n.name == prev_name
			)
			if not results.is_empty():
				previous_node = results.front()

	var char_id = int(SaveManager.save_data.get("character", -1))
	print("char_id on ready: ", char_id)
	if char_id >= 0:
		var char_data = CharacterManager.lookup.get(char_id)
		if char_data != null:
			CharacterTexture.texture = char_data.sprite_sheet

func _on_area_2d_area_entered(area: Area2D) -> void:
	var node = area.get_parent()
	if node is MapNode:
		current_node = node
		node_entered.emit(node)

func _on_area_2d_area_exited(area: Area2D) -> void:
	var node = area.get_parent()
	if node is MapNode:
		node_exited.emit(node)
		if current_node != null and !current_node.is_blocking:
			previous_node = current_node
			SaveManager.save_data["previous_node"] = current_node.name
			print("previous node set to: ", previous_node.name)

func _input(event: InputEvent) -> void:
	if is_moving:
		return
	if current_node == null:
		print("no current node")
		return
	var direction = ""
	if event.is_action_pressed("up"): direction = "up"
	elif event.is_action_pressed("down"): direction = "down"
	elif event.is_action_pressed("left"): direction = "left"
	elif event.is_action_pressed("right"): direction = "right"
	if direction == "":
		return
	print("direction pressed: ", direction)
	var target_id = current_node.get_connection(direction)
	if target_id == "":
		print("no connection in direction: ", direction)
		return
	print("looking for node: ", target_id)
	var target = get_tree().get_nodes_in_group("map_nodes").filter(
		func(n): return n.name == target_id
	).front()
	if target == null:
		print("target node not found: ", target_id)
		return
	if current_node.is_blocking and target != previous_node:
		return
	goal_node = target
	print("goal node set to: ", goal_node.name)
	_move_to_goal()


func _process(delta: float) -> void:
	if goal_node == null:
		return
	if nav_agent.is_navigation_finished():
		return
	var next = nav_agent.get_next_path_position()
	var diff = next - global_position
	global_position = global_position.move_toward(next, move_speed * delta)
	_update_animation(diff)

func _move_to_goal() -> void:
	is_moving = true
	nav_agent.target_position = goal_node.global_position
	nav_agent.target_desired_distance = 1.0
	
	var diff = goal_node.global_position - global_position
	if abs(diff.x) > abs(diff.y):
		if diff.x > 0:
			anim_player.play("WalkRight")
		else:
			anim_player.play("WalkLeft")
	else:
		if diff.y > 0:
			anim_player.play("WalkDown")
		else:
			anim_player.play("WalkUp")

func _update_animation(diff: Vector2) -> void:
	var anim = ""
	if abs(diff.x) > abs(diff.y):
		if diff.x > 0:
			last_direction = "right"
			anim = "WalkRight"
		else:
			last_direction = "left"
			anim = "WalkLeft"
	else:
		if diff.y > 0:
			last_direction = "down"
			anim = "WalkDown"
		else:
			last_direction = "up"
			anim = "WalkUp"
	if anim_player.current_animation != anim:
		anim_player.play(anim)

func _on_navigation_agent_2d_target_reached() -> void:
	print("target reached signal fired")
	is_moving = false
	goal_node = null
	anim_player.play("Idle" + last_direction.capitalize())
	print("arrived at: ", str(current_node.name) if current_node else "unknown")
