extends Node

enum EnergyType {
	NONE      = 0,
	FIRE      = 1,
	ICE       = 2,
	LIGHTNING = 3,
	NATURE    = 4,
	WATER     = 5,
	WIND      = 6,
	LIGHT     = 7,
	DARKNESS  = 8,
	BLOOD     = 9
}

enum FXType {
	IMPACT1 = 0,
	IMPACT2 = 1,
	IMPACT3 = 2,
}

const FX_SCENE = preload("res://FX/fx.tscn")

const FX_MAP = {
	FXType.IMPACT1: {
		"frames": "res://FX/fx art/impact1.tres",
		"anim": "impact"
	},
	FXType.IMPACT2: {
		"frames": "res://FX/fx art/impact2.tres",
		"anim": "impact"
	},
	FXType.IMPACT3: {
		"frames": "res://FX/fx art/impact3.tres",
		"anim": "impact"
	},
}

func spawn_fx(parent: Node, pos: Vector2, fx_type: FXType) -> Node:
	var fx_data = FX_MAP.get(fx_type)
	if fx_data == null:
		push_error("FX type not found: " + str(fx_type))
		return
	
	var sprite_frames = load(fx_data["frames"]) as SpriteFrames
	if sprite_frames == null:
		push_error("Could not load FX frames: " + fx_data["frames"])
		return
	
	var fx = FX_SCENE.instantiate()
	fx.position = pos
	parent.add_child(fx)
	fx.setup(sprite_frames)
	return fx
