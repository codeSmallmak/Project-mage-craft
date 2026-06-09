class_name LootEntry
extends Resource

enum LootType { SPELL, ENERGY, CHARACTER }

@export var loot_type: LootType = LootType.SPELL
@export var weight: float = 1.0

@export_group("Spell")
@export var spell: SpellData = null

@export_group("Energy")
@export var energy_type: Globals.EnergyType = Globals.EnergyType.FIRE

@export_group("Character")
@export var character_id: int = -1
