extends CanvasLayer

@onready var panel = $MarginContainer/PanelContainer
@onready var label = %LevelNameLabel
@onready var button = %EnterButton
var current_node: MapNode = null

func _ready() -> void:
	var character = get_parent().get_node("CharacterOnMap")
	character.node_entered.connect(_on_node_entered)
	character.node_exited.connect(_on_node_exited)
	panel.visible = false

func _on_node_entered(map_node: MapNode) -> void:
	current_node = map_node
	if map_node.is_level:
		label.text = map_node.level_name
		panel.visible = true
		button.grab_focus()

func _on_node_exited(_map_node: MapNode) -> void:
	panel.visible = false
	current_node = null
	
	
func _on_enter_button_pressed() -> void:
	if current_node != null:
		current_node._enter_level()
