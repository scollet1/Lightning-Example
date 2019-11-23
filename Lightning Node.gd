extends Node2D

onready var Branch = preload("res://Branch.tscn")

# product of inherited object conductivity and decay_rate
onready var heat = 1.0
onready var heat_decay_rate = 0.5

onready var radius = 100
onready var angle_direction = 270
onready var rayscan_step_length = 90

onready var neighbors = {}

func get_point_on_arc(angle):
	var x = position.x + radius * cos(angle)
	var y = position.y + radius * sin(angle)
	return Vector2(x, y)

func find_conductive_surface(source, destination):
	var raycast = RayCast2D.new()
	raycast.position = source
	raycast.cast_to = destination
	# cannot return x || y :(
	var collided = raycast.get_collider()
	if collided: return collided
	return raycast

func distance_to_ground_from_root():
	var distance = get_parent().get_node("Lightning Source").position.distance_to(
		get_parent().get_node("Ground").position
	)
	if distance: return distance
	return 1

func transfer_heat(angle):
	var distance_to_ground = abs(position.distance_to(
		get_parent().get_node("Ground").position
	))

	return heat * (
		(distance_to_ground / distance_to_ground_from_root())
#		* (angle / 360)
		* randf()
	)

func create_branch(target, heat):
	var branch = Branch.instance()
	branch.position = position
	branch.width = heat * 10
	branch.add_point(target)
	branch.add_point(position)
	get_parent().add_child(branch)
	return branch

func find_neighbor_candidates():
	var start = angle_direction - 90
	var end = angle_direction + 90
	# find the furthest object out by
	# casting towards the current node
	var raycast_destination = position

	while start < end:
		var raycast_source = get_point_on_arc(start)
		var candidate = find_conductive_surface(
			raycast_source, raycast_destination
		)
		var transfered_heat = transfer_heat(start)
		if (
			not at_ground(candidate.position)
			and transfered_heat > 0.5
			and get_parent().get_child_count() <= 16
		):
			neighbors[[candidate.position, transfered_heat]] = create_branch(
				candidate.position, transfered_heat
			)
			start += rayscan_step_length
	return neighbors

func at_ground(pos):
	if pos.y > get_parent().get_node("Ground").position.y: return true
	return false

func on_screen():
	return true
#	return get_node("Notifier").is_on_screen()

func spawn():
	print_debug("spawned new lightning node")

func _ready():
	print("created new lightning")

func _process(delta):
	heat -= delta * heat_decay_rate
	for child in get_children():
		child.set_width(heat)

	if heat <= 0:
		for child in get_children():
			child.queue_free()
		queue_free()