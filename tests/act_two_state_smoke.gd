extends SceneTree
## ActTwoState: locked without a finished Act I, strict order, the duel only
## adds rounds when attacked, and only the dagger action records the dream.

const Story = preload("res://scripts/systems/story/act_two_state.gd")


func _initialize() -> void:
	var locked = Story.new()
	assert(not locked.begin(0, true))
	assert(not locked.begin(1, false))
	assert(locked.phase == Story.Phase.LOCKED)
	assert(not locked.tend_fire())

	for hand in [Story.HAND_SPARE, Story.HAND_CUT]:
		for dream in [Story.DreamChoice.LOWER_DAGGER, Story.DreamChoice.STRIKE]:
			var s = Story.new()
			assert(s.begin(hand, true))
			assert(not s.begin(hand, true))
			assert(not s.check_weapon())
			assert(s.tend_fire() and s.check_weapon() and s.keep_watch())
			assert(not s.face_mutsal())
			assert(s.sleep())
			assert(not s.face_mutsal())
			assert(s.witness_feast() and s.face_mutsal())
			assert(not s.decide_dream(dream))
			assert(s.strike_in_duel() and s.duel_rounds_remaining == 4)
			for i in range(10):
				s.strike_in_duel()
			assert(s.duel_rounds_remaining == Story.DUEL_MAX_ROUNDS)
			assert(s.dream_choice == Story.DreamChoice.UNDECIDED)
			for i in range(Story.DUEL_MAX_ROUNDS):
				assert(s.parry())
			assert(s.phase == Story.Phase.DREAM_DAGGER)
			assert(s.dream_choice == Story.DreamChoice.UNDECIDED)
			assert(not s.decide_dream(Story.DreamChoice.UNDECIDED))
			assert(s.decide_dream(dream))
			assert(not s.decide_dream(dream))
			assert(s.dream_choice == dream and s.hand_choice == hand)
			assert(not s.break_camp())
			assert(s.reflect() and s.break_camp())
			assert(s.phase == Story.Phase.COMPLETE)
	print("PASS: Act II state order, lock, duel rounds and explicit dream decision.")
	quit(0)
