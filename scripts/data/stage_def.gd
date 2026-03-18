class_name StageDef
extends Resource

@export var id := ""
@export var display_name := ""
@export var chapter := 1
@export var difficulty := 1
@export var description := ""
@export var tags: Array[String] = []
@export var banned_totem_ids: Array[String] = []
@export var wave_defs: Array[WaveDef] = []