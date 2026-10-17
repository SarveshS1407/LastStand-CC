class_name SettingsDialog
extends Control

## Settings dialog for Audio and Display configurations.

@onready var master_slider: HSlider = $CenterContainer/Panel/Margin/VBox/MasterRow/MasterSlider
@onready var master_val_label: Label = $CenterContainer/Panel/Margin/VBox/MasterRow/ValLabel

@onready var sfx_slider: HSlider = $CenterContainer/Panel/Margin/VBox/SfxRow/SfxSlider
@onready var sfx_val_label: Label = $CenterContainer/Panel/Margin/VBox/SfxRow/ValLabel

@onready var shake_check: CheckBox = $CenterContainer/Panel/Margin/VBox/ShakeRow/ShakeCheck
@onready var fullscreen_check: CheckBox = $CenterContainer/Panel/Margin/VBox/FullscreenRow/FullscreenCheck

@onready var back_button: Button = $CenterContainer/Panel/Margin/VBox/BackButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_populate_values()
	
	master_slider.value_changed.connect(_on_master_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	shake_check.toggled.connect(_on_shake_toggled)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	back_button.pressed.connect(_on_back_pressed)


func _populate_values() -> void:
	var sm = get_node_or_null("/root/SettingsManager")
	if sm:
		master_slider.value = sm.master_volume * 100.0
		master_val_label.text = str(int(master_slider.value)) + "%"
		
		sfx_slider.value = sm.sfx_volume * 100.0
		sfx_val_label.text = str(int(sfx_slider.value)) + "%"
		
		shake_check.button_pressed = sm.screen_shake_enabled
		fullscreen_check.button_pressed = sm.is_fullscreen


func _on_master_changed(val: float) -> void:
	master_val_label.text = str(int(val)) + "%"
	var sm = get_node_or_null("/root/SettingsManager")
	if sm:
		sm.set_master_volume(val / 100.0)


func _on_sfx_changed(val: float) -> void:
	sfx_val_label.text = str(int(val)) + "%"
	var sm = get_node_or_null("/root/SettingsManager")
	if sm:
		sm.set_sfx_volume(val / 100.0)


func _on_shake_toggled(enable: bool) -> void:
	var sm = get_node_or_null("/root/SettingsManager")
	if sm:
		sm.set_screen_shake(enable)


func _on_fullscreen_toggled(enable: bool) -> void:
	var sm = get_node_or_null("/root/SettingsManager")
	if sm:
		sm.set_fullscreen(enable)


func _on_back_pressed() -> void:
	visible = false
