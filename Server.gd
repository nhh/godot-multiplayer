extends Node # Extending node to use event loop

class_name Server

enum OpCodes {
	HANDSHAKE,
	PLAYER_UPDATE,
}

signal player_connected
signal player_disconnected
signal player_message

@onready var connection = ENetConnection.new()
@onready var peers: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	print("Binding port...")
	connection.create_host_bound("127.0.0.1", 9999)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Waits for events on the host specified and shuttles packets between the host and its peers. 
	# The returned Array will have 4 elements. 
	# An EventType, the ENetPacketPeer which generated the event, the event associated data (if any), the event associated channel (if any). If the generated event is EVENT_RECEIVE, the received packet will be queued to the associated ENetPacketPeer.
	var event: Array = connection.service()
	
	if (event == null):
		return
	#var type event[0]	
	#var peer = event[1]
	
	match event[0]:
		# Create player ID, register peer with ID and send ID BACK
		ENetConnection.EVENT_CONNECT:
			var id = randi()
			peers[ event[1] ] = id
			print("Client connected with id " + str(id))			
			var message = PackedInt32Array([OpCodes.HANDSHAKE, id])
			event[1].send(0, var_to_bytes(message), 0)
		ENetConnection.EVENT_DISCONNECT:
			peers.erase(event[1])
		ENetConnection.EVENT_RECEIVE:
			broadcast(event[1])
			pass
		_:
			pass

# To all
func broadcast(origin_peer):
	var packet = origin_peer.get_packet()
	for peer in peers.keys():
		if peer == origin_peer:
			continue
		
		peer.send_bytes(packet)
	pass
