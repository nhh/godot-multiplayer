extends Node

@onready var main_menu = $CanvasLayer/MainMenu
@onready var address_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry
@onready var hud = $CanvasLayer/HUD
@onready var health_bar = $CanvasLayer/HUD/HealthBar
@onready var server
@onready var client

const Player = preload("res://player.tscn")
const Server = preload("res://Server.gd")
const Client = preload("res://Client.gd")

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

func _on_host_button_pressed():
	server = Server.new()
	get_tree().get_root().add_child(server)
	#multiplayer.peer_packet.connect(on_client_to_server_message)
	
func _on_join_button_pressed():
	client = Client.new()
	get_tree().get_root().add_child(client)
	
	client.connect_to_host(address_entry.text)

	client.connected.connect(self.add_player)

func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	get_tree().get_root().add_child(player)
	if player.is_multiplayer_authority():
		player.health_changed.connect(update_health_bar)

func remove_player(peer_id):
	var player = get_node_or_null("/root/"+str(peer_id))
	if player:
		player.queue_free()

func update_health_bar(health_value):
	health_bar.value = health_value

func _process(delta):
	if(client == null || server != null):
		return
		
	if(client.get_unique_id() == null):
		return
	
	# Todo can be cached
	var player = get_node_or_null("/root/"+str(client.get_unique_id()))
	
	if(player == null):
		return
	
	# Todo ERROR: Trying to send a raw packet via a multiplayer peer which is not connected.
	var content = PackedVector3Array([player.position, player.rotation, player.camera.rotation])
	var packet = var_to_bytes([Server.OpCodes.PLAYER_UPDATE, client.get_unique_id(), content])
	
	client.send(packet)

func on_server_to_client_message(id, message_from_server):
	var data = bytes_to_var_with_objects(message_from_server)
	var player = get_node_or_null("/root/"+str(id))
	
	if(player == null):
		remove_player(id)
		add_player(id)
		return
			
	player.position = data[0]
	player.rotation = data[1]
	player.camera.rotation = data[2]
