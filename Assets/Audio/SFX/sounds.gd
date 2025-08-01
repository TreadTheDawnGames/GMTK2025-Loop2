extends Node
class_name Sound

@export var Pullback : AudioStream
@export var Launch : AudioStream
@export var Boost : AudioStream = preload("res://Assets/Audio/SFX/BoostSFX.wav")
@export var EngineExplode : AudioStream
@export var CollectableGet : AudioStream = preload("res://Assets/Audio/SFX/CollectableSFX.wav")
@export var ShipCollide : AudioStream = preload("res://Assets/Audio/SFX/CrashSFX.wav")
@export var ShipVwoom : AudioStream = preload("res://Assets/Audio/SFX/EngineSFX.wav")
@export var OpenShop : AudioStream = preload("res://Assets/Audio/SFX/OpenShopSFX.wav")
@export var UIClick : AudioStream = preload("res://Assets/Audio/SFX/UIClickSFX.wav")
@export var UIHover : AudioStream = preload("res://Assets/Audio/SFX/UIHoverSFX.wav")
@export var UpUIBeep : AudioStream = preload("res://Assets/Audio/SFX/UpBeepUI.wav")
@export var DownUIBeep : AudioStream = preload("res://Assets/Audio/SFX/DownBeepUI.wav")
