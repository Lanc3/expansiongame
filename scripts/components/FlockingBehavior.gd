extends Node
class_name FlockingBehavior

## Flocking behavior component that provides separation, alignment, and cohesion
## for natural group movement patterns

@export var separation_weight: float = 1.5
@export var alignment_weight: float = 1.0
@export var cohesion_weight: float = 0.8

@export var separation_radius: float = 50.0
@export var alignment_radius: float = 80.0
@export var cohesion_radius: float = 100.0

@export var max_neighbors: int = 10

var owner_unit: CharacterBody2D = null

func _ready():
	owner_unit = get_parent() as CharacterBody2D
	if not owner_unit:
		push_error("FlockingBehavior must be child of CharacterBody2D")

## Calculate combined flocking force based on nearby units
func calculate_flocking_force(nearby_units: Array) -> Vector2:
	if nearby_units.is_empty() or not owner_unit:
		return Vector2.ZERO
	
	var separation_force = calculate_separation(nearby_units)
	var alignment_force = calculate_alignment(nearby_units)
	var cohesion_force = calculate_cohesion(nearby_units)
	
	var total_force = Vector2.ZERO
	total_force += separation_force * separation_weight
	total_force += alignment_force * alignment_weight
	total_force += cohesion_force * cohesion_weight
	
	return total_force

## Separation: Steer away from nearby units to avoid crowding
func calculate_separation(nearby_units: Array) -> Vector2:
	var separation = Vector2.ZERO
	var count = 0
	
	for unit in nearby_units:
		if not is_instance_valid(unit) or unit == owner_unit:
			continue
		
		var distance = owner_unit.global_position.distance_to(unit.global_position)
		if distance < separation_radius and distance > 0:
			# Push away with force inversely proportional to distance
			var away = (owner_unit.global_position - unit.global_position).normalized()
			var strength = 1.0 - (distance / separation_radius)
			separation += away * strength
			count += 1
	
	if count > 0:
		separation /= count
		separation = separation.normalized()
	
	return separation

## Alignment: Match velocity with nearby units for coordinated movement
func calculate_alignment(nearby_units: Array) -> Vector2:
	var average_velocity = Vector2.ZERO
	var count = 0
	
	for unit in nearby_units:
		if not is_instance_valid(unit) or unit == owner_unit:
			continue
		
		var distance = owner_unit.global_position.distance_to(unit.global_position)
		if distance < alignment_radius:
			average_velocity += unit.velocity
			count += 1
	
	if count > 0:
		average_velocity /= count
		# Return steering force (desired velocity - current velocity)
		var desired = average_velocity.normalized()
		return desired
	
	return Vector2.ZERO

## Cohesion: Steer toward the average position of nearby units
func calculate_cohesion(nearby_units: Array) -> Vector2:
	var center_of_mass = Vector2.ZERO
	var count = 0
	
	for unit in nearby_units:
		if not is_instance_valid(unit) or unit == owner_unit:
			continue
		
		var distance = owner_unit.global_position.distance_to(unit.global_position)
		if distance < cohesion_radius:
			center_of_mass += unit.global_position
			count += 1
	
	if count > 0:
		center_of_mass /= count
		# Steer toward center of mass
		var desired = (center_of_mass - owner_unit.global_position).normalized()
		return desired
	
	return Vector2.ZERO

## Get nearby units within a specified radius
func get_nearby_units(radius: float) -> Array:
	var units: Array = []
	
	if not EntityManager:
		return units
	
	var check_count = 0
	for unit in EntityManager.units:
		if unit != owner_unit and is_instance_valid(unit):
			var distance = owner_unit.global_position.distance_to(unit.global_position)
			if distance < radius:
				units.append(unit)
				check_count += 1
				if check_count >= max_neighbors:
					break
	
	return units

