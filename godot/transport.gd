class_name DroneTransport
extends RefCounted

# ENet transport, explicitly polled by DroneSession (also while menus are open).
# Variant objects are never enabled; compressed payloads have a hard size limit.
const WIRE_VERSION := 2
const PORT := 24568
const MAX_PLAYERS := 8
const MAX_PACKET := 65536
const MAX_UNPACKED := 262144
var peer: ENetMultiplayerPeer
var is_host := false
var connected := false
var incoming: Array[Dictionary] = []
var joined: Array[int] = []
var departed: Array[int] = []
var bytes_sent := 0
var bytes_received := 0
var packet_serial := 0
var fragments: Dictionary = {}
const FRAGMENT_BYTES := 1150
const HEADER_BYTES := 12
const VOICE_CHANNEL := 3
const VOICE_MAGIC := 0x454C5652
const VOICE_HEADER := 28
const VOICE_BYTES := 640

func start_host(port: int) -> Error:
 close()
 peer=ENetMultiplayerPeer.new()
 var result := peer.create_server(port,MAX_PLAYERS-1,4)
 if result!=OK:
  peer=null
  return result
 is_host=true
 connected=true
 connect_signals()
 return OK

func start_client(address: String,port: int) -> Error:
 close()
 peer=ENetMultiplayerPeer.new()
 var result := peer.create_client(address,port,4)
 if result!=OK:
  peer=null
  return result
 is_host=false
 connect_signals()
 return OK

func connect_signals() -> void:
 peer.peer_connected.connect(on_joined)
 peer.peer_disconnected.connect(on_departed)

func on_joined(id: int) -> void:
 joined.append(id)
 if not is_host and id==1:
  connected=true

func on_departed(id: int) -> void:
 departed.append(id)
 if not is_host and id==1:
  connected=false

func poll() -> void:
 if peer==null:
  return
 peer.poll()
 # Bound work per tick so a peer cannot monopolize the simulation thread.
 for i in range(mini(peer.get_available_packet_count(),256)):
  var channel := peer.get_packet_channel()
  var sender := peer.get_packet_peer()
  var packet := peer.get_packet()
  bytes_received+=packet.size()
  if channel==VOICE_CHANNEL:
   if packet.size()==VOICE_HEADER+VOICE_BYTES and packet.decode_u32(0)==VOICE_MAGIC:
    incoming.append({"sender":sender,"message":{"type":"voice","speaker":packet.decode_u32(4),"sequence":packet.decode_u32(8),"sector":Vector3i(packet.decode_s32(12),packet.decode_s32(16),packet.decode_s32(20)),"stream":packet.decode_u32(24),"pcm":packet.slice(VOICE_HEADER)}})
   continue
  if packet.size()<HEADER_BYTES or packet.size()>HEADER_BYTES+FRAGMENT_BYTES:
   continue
  var unpacked_size := packet.decode_u32(0)
  var serial := packet.decode_u32(4)
  var index := packet.decode_u16(8)
  var count := packet.decode_u16(10)
  if unpacked_size<1 or unpacked_size>MAX_UNPACKED or count<1 or count>64 or index>=count:
   continue
  var key := "%d:%d" % [sender,serial]
  if not fragments.has(key):
   if fragments.size()>=64:
    fragments.erase(fragments.keys()[0])
   fragments[key]={"size":unpacked_size,"count":count,"parts":{},"at":Time.get_ticks_msec()}
  var assembly: Dictionary=fragments[key]
  if assembly.size!=unpacked_size or assembly.count!=count:
   continue
  assembly.parts[index]=packet.slice(HEADER_BYTES)
  if assembly.parts.size()!=count:
   continue
  var compressed := PackedByteArray()
  for part in range(count):
   compressed.append_array(assembly.parts[part])
  fragments.erase(key)
  if compressed.size()>MAX_PACKET: continue
  var payload := compressed.decompress(unpacked_size,FileAccess.COMPRESSION_ZSTD)
  if payload.size()!=unpacked_size:
   continue
  var message: Variant=bytes_to_var(payload)
  if message is Dictionary and message.get("wire",0)==WIRE_VERSION and message.get("type",null) is String:
   incoming.append({"sender":sender,"message":message})
 for key in fragments.keys():
  if Time.get_ticks_msec()-fragments[key].at>2000:
   fragments.erase(key)

func send(target: int,message: Dictionary,reliable: bool=true,channel: int=0) -> Error:
 if peer==null or not connected:
  return ERR_UNCONFIGURED
 message["wire"]=WIRE_VERSION
 var raw := var_to_bytes(message)
 if raw.size()>MAX_UNPACKED:
  return ERR_INVALID_DATA
 var compressed := raw.compress(FileAccess.COMPRESSION_ZSTD)
 if compressed.size()>MAX_PACKET:
  return ERR_INVALID_DATA
 packet_serial=(packet_serial+1)%4294967295
 var count := ceili(float(compressed.size())/FRAGMENT_BYTES)
 peer.set_target_peer(target)
 peer.transfer_channel=channel
 # Independent unreliable chunks can all be partially dropped by ENet's
 # throttle, preventing any snapshot from completing. Protect multi-chunk
 # updates on their existing channel (snapshots: 2); movement on channel 1
 # and reliable commands on channel 0 remain independent.
 var use_reliable := reliable or count>1
 peer.transfer_mode=MultiplayerPeer.TRANSFER_MODE_RELIABLE if use_reliable else MultiplayerPeer.TRANSFER_MODE_UNRELIABLE
 for index in range(count):
  var packet := PackedByteArray()
  packet.resize(HEADER_BYTES)
  packet.encode_u32(0,raw.size())
  packet.encode_u32(4,packet_serial)
  packet.encode_u16(8,index)
  packet.encode_u16(10,count)
  packet.append_array(compressed.slice(index*FRAGMENT_BYTES,(index+1)*FRAGMENT_BYTES))
  var result := peer.put_packet(packet)
  if result!=OK:
   return result
  bytes_sent+=packet.size()
 return OK

func send_voice(target: int,message: Dictionary) -> Error:
 if peer==null or not connected: return ERR_UNCONFIGURED
 var pcm: PackedByteArray=message.pcm
 if pcm.size()!=VOICE_BYTES: return ERR_INVALID_DATA
 var packet := PackedByteArray()
 packet.resize(VOICE_HEADER)
 packet.encode_u32(0,VOICE_MAGIC)
 packet.encode_u32(4,int(message.speaker))
 packet.encode_u32(8,int(message.sequence))
 packet.encode_s32(12,message.sector.x)
 packet.encode_s32(16,message.sector.y)
 packet.encode_s32(20,message.sector.z)
 packet.encode_u32(24,int(message.get("stream",0)))
 packet.append_array(pcm)
 peer.set_target_peer(target)
 peer.transfer_channel=VOICE_CHANNEL
 peer.transfer_mode=MultiplayerPeer.TRANSFER_MODE_UNRELIABLE
 var result := peer.put_packet(packet)
 if result==OK: bytes_sent+=packet.size()
 return result

func disconnect_peer(id: int) -> void:
 if peer!=null:
  peer.disconnect_peer(id)

func close() -> void:
 if peer!=null:
  peer.close()
 peer=null
 connected=false
 is_host=false
 incoming.clear()
 joined.clear()
 departed.clear()
 fragments.clear()
