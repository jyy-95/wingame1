class_name EnemyDef
extends Resource

@export var id := ""
@export var display_name := ""
@export var color := Color.WHITE
@export var max_hp := 60.0
@export var speed := 90.0
@export var armor := 0.0
@export var reward := 4
@export var contact_damage := 1
@export var is_boss := false
@export var tags: Array[String] = []