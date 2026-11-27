extends SceneTree
const Rules=preload("res://dungeon_rules.gd")
func _initialize():
	var ids:Dictionary={}
	var gaits:Dictionary={}
	var moves:Dictionary={}
	for region in range(3):
		assert(Rules.MINION_ROSTER[region].size()==11)
		for row in Rules.MINION_ROSTER[region]:
			assert(not ids.has(row[0]))
			assert(not gaits.has(row[2]))
			assert(not moves.has(row[3]))
			ids[row[0]]=true
			gaits[row[2]]=true
			moves[row[3]]=true
		var d=Rules.new()
		d.setup(region,1,0,false,false,29)
		for e in d.enemies:
			assert(ids.has(e.species) and gaits.has(e.gait) and moves.has(e.signature))
		assert(int(d.enemy_profile(3,99)[4])==3)
	print("VOLNOX_ROSTER_PASS ",ids.size())
	quit()
