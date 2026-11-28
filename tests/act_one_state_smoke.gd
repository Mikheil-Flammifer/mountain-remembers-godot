extends SceneTree

const Story = preload("res://scripts/systems/story/act_one_state.gd")


func _initialize() -> void:
	for choice in [Story.HandChoice.SPARE, Story.HandChoice.CUT]:
		var story = Story.new()
		assert(not story.defeat_brother())
		assert(not story.meet_sanata())
		assert(story.receive_raid_report())
		assert(story.inspect_trail(&"hoofprints"))
		assert(story.visit_river() and story.meet_sanata())
		assert(story.reach_crags() and story.defeat_brother())
		assert(story.break_cover() and story.powder_horn_destroyed)
		assert(story.wound_mutsal())
		assert(not story.record_thrown_rifle())
		assert(story.record_final_shot() and story.record_thrown_rifle())
		assert(not story.finish_aftermath())
		assert(story.decide_hand(choice))
		assert(not story.decide_hand(Story.HandChoice.SPARE))
		assert(story.finish_aftermath())
		assert(story.brother_arm_taken and story.mutsal_weapons_left and story.body_covered)
		assert(story.phase == Story.Phase.COMPLETE and story.hand_choice == choice)
	print("PASS: Act 1 sequence, detour and both hand outcomes.")
	quit(0)
