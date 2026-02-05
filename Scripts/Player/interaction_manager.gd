extends Area2D
class_name InteractionHandler

var target_node: Node2D = null

func get_best_target() -> Node2D:
	var targets = get_overlapping_bodies() + get_overlapping_areas()
	var closest_dist = INF
	var best_target = null
	
	for obj in targets:
		if obj == owner: continue 
		
		# Critérios para ser um alvo válido
		var can_interact = obj.has_method("interact")
		var can_damage = obj.is_in_group("inimigos") or obj.has_method("take_damage")
		
		if can_interact or can_damage:
			var dist = global_position.distance_to(obj.global_position)
			if dist < closest_dist:
				closest_dist = dist
				best_target = obj
	
	target_node = best_target
	return target_node

func execute_interaction():
	if not target_node: return
	
	if target_node.has_method("interact"):
		target_node.interact()
	elif target_node.has_method("take_damage"):
		target_node.take_damage()
