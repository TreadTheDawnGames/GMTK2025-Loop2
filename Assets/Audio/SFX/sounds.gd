extends Node
class_name Sound

@export var Pullback : AudioStream
@export var Launch : AudioStream = preload("res://Assets/Audio/SFX/LaunchSFX.wav")
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
@export var PingHigh : AudioStream = preload("res://Assets/Audio/SFX/PingHighSFX2.wav")
@export var PingLow : AudioStream = preload("res://Assets/Audio/SFX/PingLowSFX2.wav")
@export var ShipCrash : AudioStream = preload("res://Assets/Audio/SFX/CrashSFX2.wav")
@export var GetPOints : AudioStream = preload("res://Assets/Audio/SFX/GetPointsSFX2.wav")
