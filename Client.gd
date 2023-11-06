extends Node # Extending node to use event loop

class_name Client

signal connected(unique_client_id)
signal disconnected
signal message

@onready var connection = ENetConnection.new()

var peer: ENetPacketPeer
var id

# Called when the node enters the scene tree for the first time.
func _ready():
	connection.create_host()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Waits for events on the host specified and shuttles packets between the host and its peers. 
	# The returned Array will have 4 elements. 
	# An EventType, the ENetPacketPeer which generated the event, the event associated data (if any), the event associated channel (if any). If the generated event is EVENT_RECEIVE, the received packet will be queued to the associated ENetPacketPeer.
	var event: Array = connection.service()
	
	if (event == null):
		return
	#car type event[0]	
	#var peer = event[1]
	
	match event[0]:
		ENetConnection.EVENT_CONNECT:
			# We dont need these events on a client
			pass
		ENetConnection.EVENT_DISCONNECT:
			# We dont need these events on a client
			pass
		ENetConnection.EVENT_RECEIVE:
			var packet: PackedInt32Array = bytes_to_var(event[1].get_packet())
			var opcode: int = packet[0]
			# get verything after opcode
			
			match opcode:
				Server.OpCodes.HANDSHAKE:
					id = packet[1] as int
					connected.emit(id)
				_:
					pass
		_:
			pass
func send(packet):
	if(!peer.is_active()):
		print("WARNING: client peer is not active")
	peer.send(0, packet, 0)

func connect_to_host(ip):
	print("Client: Connecting to: " + str(ip))
	peer = connection.connect_to_host(ip, 9999)

func is_active():
	return id != null

func get_unique_id():
	return id
