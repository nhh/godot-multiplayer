extends Node

@onready var main_menu = $CanvasLayer/MainMenu
@onready var address_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry
@onready var hud = $CanvasLayer/HUD
@onready var health_bar = $CanvasLayer/HUD/HealthBar


const Player = preload("res://player.tscn")
const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()

func _ready():
	multiplayer.server_relay = false
	
func _unhandled_input(event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

func _on_host_button_pressed():
	#main_menu.hide()
	#hud.show()
	
	enet_peer.create_server(PORT)
	
	multiplayer.multiplayer_peer = enet_peer
	
	# Todo broadcast these messages so the scene can populate correctly
	#multiplayer.peer_connected.connect(add_player)
	#multiplayer.peer_disconnected.connect(remove_player)
	
	multiplayer.peer_packet.connect(on_client_to_server_message)
	
func _on_join_button_pressed():
	main_menu.hide()
	hud.show()
	
	enet_peer.set_target_peer(1)
	enet_peer.create_client(address_entry.text, PORT)
	
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_packet.connect(on_server_to_client_message)
	
	add_player(multiplayer.get_unique_id())

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
	if(enet_peer.get_connection_status() == 0):
		return
		
	if(multiplayer.get_unique_id() == 1):
		return
		
	var player = get_node_or_null("/root/"+str(multiplayer.get_unique_id()))
	if(player == null):
		return
	
	# Todo ERROR: Trying to send a raw packet via a multiplayer peer which is not connected.
	var array = PackedVector3Array([player.position, player.rotation, player.camera.rotation])
	multiplayer.send_bytes(var_to_bytes(array))

# Will only be called on the server
func on_client_to_server_message(id, message):
	for client_id in multiplayer.get_peers():
		if (client_id == multiplayer.get_unique_id() || client_id == id):
			continue
		
		# Just route all messages to every other peers
		var tunnel = enet_peer.get_peer(client_id) as ENetPacketPeer
		tunnel.send(0, message, 0)

func on_server_to_client_message(id, message_from_server):
	if(id == multiplayer.get_unique_id()):
		return

	var data = bytes_to_var_with_objects(message_from_server)
	var player = get_node_or_null("/root/"+str(id))
	
	if(player == null):
		remove_player(id)
		add_player(id)
		return
			
	player.position = data[0]
	player.rotation = data[1]
	player.camera.rotation = data[2]
