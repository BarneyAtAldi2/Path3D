@tool
@icon("res://Addons/Trail3D/Icon.png")
extends Node3D

@export var emitting: bool
@export var duration: float = 0.5
@export var snapshotInterval: float = 0.02
@export var width: float = 1
@export var widthCurve: Curve
@export var UVScale: Vector2 = Vector2(1, 1)
@export var material: Material

var snapshotBuffer: Array
var trailMesh: MeshInstance3D

var t: float
var snapshotT: float

func set_width(value: float) -> void:
	width = value

func set_duration(value: float) -> void:
	duration = value

func set_snapshot_interval(value: float) -> void:
	snapshotInterval = value

func set_material(value: Material) -> void:
	material = value

func is_emitting() -> bool:
	return emitting

func start_emitting() -> void:
	emitting = true

func stop_emitting() -> void:
	_init()
	emitting = false

func _init() -> void:
	for child in get_children():
		child.free()

	trailMesh = MeshInstance3D.new()
	add_child(trailMesh)
	trailMesh.mesh = ImmediateMesh.new()

	if trailMesh.mesh is ImmediateMesh:
		trailMesh.mesh.clear_surfaces()

	trailMesh.top_level = true
	t = 0
	snapshotT = 0
	snapshotBuffer = []

func _enter_tree() -> void:
	_init()

func _process(delta: float) -> void:
	if not emitting or not widthCurve:
		return

	if not snapshotBuffer:
		_init()

	if not trailMesh:
		print("[TRAIL3D] TRAIL MESH COULD NOT BE CREATED.")
		emitting = false
		return

	var dt: float = delta
	if snapshotT > snapshotInterval:
		var count: int = snapshotBuffer.size()
		if count > 0:
			if snapshotBuffer[count - 1].position != global_transform.origin:
				_push_snapshot()
			if t - snapshotBuffer[0].time > duration:
				snapshotBuffer.erase(0)
		else:
			_push_snapshot()

	_draw_trail()
	snapshotT = 0

	t += dt
	snapshotT += dt

func _push_snapshot() -> void:
	var TargetSnapshotVar = TargetSnapshot.new()
	TargetSnapshotVar._Basis = global_transform.origin 
	TargetSnapshotVar._Position = global_transform.basis 
	TargetSnapshotVar._Time = t
	snapshotBuffer.append(TargetSnapshotVar)

func _draw_trail() -> void:
	if trailMesh.mesh is ImmediateMesh:
		trailMesh.mesh.clear_surfaces()

	if snapshotBuffer.size() < 2:
		return

	trailMesh.mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)

	for i in range(1, snapshotBuffer.size()):
		_draw_face(i)

	print("---")
	trailMesh.mesh.surface_end()

func _draw_face(index: int) -> void:
	var snapshot = snapshotBuffer[index]
	var previousSnapshot = snapshotBuffer[index - 1]

	var snapX = index / snapshotBuffer.size()
	var snapWidth = widthCurve.interpolate_baked(snapX)

	var prevSnapX = (index - 1) / snapshotBuffer.size()
	var prevSnapWidth = widthCurve.interpolate_baked(prevSnapX)

	var vert1 = previousSnapshot.position + previousSnapshot.basis.y.normalized() * prevSnapWidth * width
	var vert2 = snapshot.position + snapshot.basis.y.normalized() * snapWidth * width
	var vert3 = previousSnapshot.position - previousSnapshot.basis.y.normalized() * prevSnapWidth * width
	var vert4 = snapshot.position - snapshot.basis.y.normalized() * snapWidth * width

	var normal = snapshot.basis.z.normalized()

	var snapUVx = lerp(0, 1, snapX) * UVScale.x
	var prevSnapUVx = lerp(0, 1, prevSnapX) * UVScale.x

	var snapUVy = lerp(0, 1, snapWidth) * UVScale.y
	var prevSnapUVy = lerp(0, 1, prevSnapWidth) * UVScale.y

	var vert1UV = Vector2(prevSnapUVx, 0.5 + prevSnapUVy / 2)
	var vert2UV = Vector2(snapUVx, 0.5 + snapUVy / 2)
	var vert3UV = Vector2(prevSnapUVx, 0.5 - prevSnapUVy / 2)
	var vert4UV = Vector2(snapUVx, 0.5 - snapUVy / 2)
	
	var TriangleVar = Triangle.new()
	
	var tri1UVs = [vert1UV, vert2UV, vert3UV]
	var tri1 = TriangleVar.Triangle([vert1, vert2, vert3], [normal, normal, normal], tri1UVs, t)

	var tri2UVs = [vert4UV, vert3UV, vert2UV]
	var tri2 = TriangleVar.Triangle([vert4, vert3, vert2], [normal, normal, normal], tri2UVs, t)

	for i in range(tri1.Vertices.size()):
		trailMesh.surface_set_uv(tri1.UVs[i])
		trailMesh.surface_set_normal(tri1.Normals[i])
		trailMesh.surface_add_vertex(tri1.Vertices[i])

	for i in range(tri2.Vertices.size()):
		trailMesh.surface_set_uv(tri2.UVs[i])
		trailMesh.surface_set_normal(tri2.Normals[i])
		trailMesh.surface_add_vertex(tri2.Vertices[i])

class Triangle:
	var Vertices : Array
	var Normals : Array
	var UVs : Array
	var TTime : float

	func Triangle(vertices, normals, uvs, time):
		Vertices = vertices
		Normals = normals
		UVs = uvs
		TTime = time

class TargetSnapshot: 
	var _Position : Vector3
	var _Basis : Basis
	var TSTime : float = 0.0

	func TargetSnapshot(position, basis, time):
		_Position = position
		_Basis = basis
		TSTime = time
