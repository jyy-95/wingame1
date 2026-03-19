extends Node

# 音效播放器
var sfx_player: AudioStreamPlayer
var coin_player: AudioStreamPlayer
var merge_player: AudioStreamPlayer
var upgrade_player: AudioStreamPlayer

# 音效缓存
var _sfx_cache: Dictionary = {}

# 音量设置 (0.0 - 1.0)
var master_volume: float = 0.8
var sfx_volume: float = 0.6

func _ready() -> void:
	_add_bus_if_missing()
	_setup_players()
	_preload_sfx()

func _add_bus_if_missing() -> void:
	# 确保音效总线存在
	var master_idx := AudioServer.get_bus_index("Master")
	if master_idx == -1:
		AudioServer.add_bus(0)
		AudioServer.set_bus_name(0, "Master")

	var sfx_idx := AudioServer.get_bus_index("SFX")
	if sfx_idx == -1:
		AudioServer.add_bus(1)
		AudioServer.set_bus_name(1, "SFX")

func _setup_players() -> void:
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "SFX"
	add_child(sfx_player)

	coin_player = AudioStreamPlayer.new()
	coin_player.bus = "SFX"
	add_child(coin_player)

	merge_player = AudioStreamPlayer.new()
	merge_player.bus = "SFX"
	add_child(merge_player)

	upgrade_player = AudioStreamPlayer.new()
	upgrade_player.bus = "SFX"
	add_child(upgrade_player)

	_update_volumes()

func _preload_sfx() -> void:
	# 预加载音效 (如果文件存在)
	var sfx_paths := {
		"button_click": "res://assets/audio/sfx/button_click.wav",
		"coin_collect": "res://assets/audio/sfx/coin_collect.wav",
		"merge": "res://assets/audio/sfx/merge.wav",
		"upgrade": "res://assets/audio/sfx/upgrade.wav",
		"attack": "res://assets/audio/sfx/attack.wav",
	}

	for key in sfx_paths.keys():
		if ResourceLoader.exists(sfx_paths[key]):
			_sfx_cache[key] = load(sfx_paths[key])

func _update_volumes() -> void:
	# 转换分贝 (Godot 使用 dB)
	sfx_player.volume_db = linear_to_db(master_volume * sfx_volume)
	coin_player.volume_db = linear_to_db(master_volume * sfx_volume)
	merge_player.volume_db = linear_to_db(master_volume * sfx_volume)
	upgrade_player.volume_db = linear_to_db(master_volume * sfx_volume)

func play_button_click() -> void:
	_play_one_shot(sfx_player, _sfx_cache.get("button_click"))

func play_coin_collect() -> void:
	_play_one_shot(coin_player, _sfx_cache.get("coin_collect"))

func play_merge() -> void:
	_play_one_shot(merge_player, _sfx_cache.get("merge"))

func play_upgrade() -> void:
	_play_one_shot(upgrade_player, _sfx_cache.get("upgrade"))

func play_attack() -> void:
	_play_one_shot(sfx_player, _sfx_cache.get("attack"))

func _play_one_shot(player: AudioStreamPlayer, stream: AudioStream) -> void:
	if stream == null:
		return
	if player.playing:
		player.stop()
	player.stream = stream
	player.play()

func set_master_volume(volume: float) -> void:
	master_volume = clampf(volume, 0.0, 1.0)
	_update_volumes()

func set_sfx_volume(volume: float) -> void:
	sfx_volume = clampf(volume, 0.0, 1.0)
	_update_volumes()
