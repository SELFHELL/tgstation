/datum/slime_moodlet
	var/mood_offset = 0
	var/special_line
	var/special_mood
	var/face_priority = 1
	var/duration = -1

/datum/slime_moodlet/starving
	mood_offset = -45
	special_line = list("So... hungry...", "Very... hungry...", "Need... food...", "Must... eat...")

/datum/slime_moodlet/hungry
	mood_offset = -20
	special_line = list("Hungry...", "Where food?", "I want to eat...")

/datum/slime_moodlet/rabid
	mood_offset = -100
	special_line = list("Hrr...", "Nhuu...", "Unn...")
	special_mood = "angry"
	face_priority = 11

/datum/slime_moodlet/attacked
	mood_offset = -35
	special_line = list("Hrr...", "Nhuu...", "Unn...", "Grrr...")
	special_mood = "angry"
	face_priority = 10
	duration = 30 SECONDS

/datum/slime_moodlet/disciplined
	mood_offset = -15
	special_line = list("Hrr...", "Nhuu...", "Unn...")
	duration = 1 MINUTES
	special_mood = "pout"
	face_priority = 9

/datum/slime_moodlet/cuddly
	mood_offset = 10
	special_line = list("Purr...")
	special_mood = "uwu"
	face_priority = 0
	duration = 1 MINUTES

/datum/slime_moodlet/req_not_satisfied
	mood_offset = -25
	special_line = "I want home..."

/datum/slime_moodlet/cold
	mood_offset = -10
	special_line = "Cold..."

/datum/slime_moodlet/very_cold
	mood_offset = -10
	special_line = list("So... cold...", "Very... cold...")

/datum/slime_moodlet/freezing_cold
	mood_offset = -20
	special_line = list("...", "C... c...")

/datum/slime_moodlet/digesting
	mood_offset = 10
	special_line = list("Nom...", "Yummy...")

/datum/slime_moodlet/digesting_food
	mood_offset = 10
	special_line = list("Nom...", "Yummy...")

/datum/slime_moodlet/power_one
	special_line = "Bzzz..."

/datum/slime_moodlet/power_two
	special_line = list("Bzzz...", "Bzt... Bzt...", "Zap...")

/datum/slime_moodlet/power_three
	special_line = list("Bzzz...", "Bzt... Bzt...", "Zap...", "Zap... Bzz...", "Zappy zap...")

/datum/slime_moodlet/bored
	mood_offset = -10
	special_line = "Bored..."
	duration = 30 SECONDS

/datum/slime_moodlet/friend
	mood_offset = 5
	special_line = "Slime friend..."

/datum/slime_moodlet/friends
	mood_offset = 5
	special_line = "Slime friends..."

/datum/slime_moodlet/lonely
	mood_offset = -5
	special_line = "Lonely..."

/datum/slime_moodlet/crowded
	mood_offset = -20
	special_line = "Too much friends..."

/datum/slime_moodlet/dead_slimes
	mood_offset = -35
	special_line = list("What happened?", "No... Don't go...", "Why...")
	duration = 1 MINUTES

/datum/slime_moodlet/watered
	mood_offset = -25
	special_line = "Shhh..."
	duration = 1 MINUTES

/datum/slime_moodlet/plushie_play
	mood_offset = 25
	duration = 20 SECONDS
	special_mood = "owo"
	face_priority = 1

/datum/slime_moodlet/crowned
	mood_offset = 25
	special_line = list("Bow before me...", "Mortals...")
	special_mood = "owo"
	face_priority = 3

/datum/slime_moodlet/friendship_necklace
	mood_offset = 10
	special_line = list("Friend...", "Love...", "Peace...")
	special_mood = "uwu"
	face_priority = 2

/datum/slime_moodlet/docile
	mood_offset = 100
	special_mood = "owo"
	face_priority = 12
