extends Node
# Global game state: flags, inventory, relationships

var flags := {}
var inventory := []
var relationships := {}

func set_flag(flag_name: String) -> void:
	flags[flag_name] = true

func get_flag(flag_name: String) -> bool:
	return flags.get(flag_name, false)

func has_flag(flag_name: String) -> bool:
	return flags.get(flag_name, false)

func add_item(item_name: String) -> void:
	if item_name not in inventory:
		inventory.append(item_name)

func has_item(item_name: String) -> bool:
	return item_name in inventory

func get_inventory_count(opening_items: Array = []) -> int:
	if opening_items.is_empty():
		return inventory.size()
	var count := 0
	for item in inventory:
		if item in opening_items:
			count += 1
	return count

func change_relationship(npc: String, amount: int) -> void:
	relationships[npc] = relationships.get(npc, 0) + amount

func get_relationship(npc: String) -> int:
	return relationships.get(npc, 0)

func reset() -> void:
	flags.clear()
	inventory.clear()
	relationships.clear()
