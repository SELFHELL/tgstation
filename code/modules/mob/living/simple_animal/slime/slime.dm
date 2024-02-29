#define SLIME_CARES_ABOUT(to_check) (to_check && (to_check == target || to_check == leader || (to_check in friends)))
/mob/living/simple_animal/slime
	name = "grey baby slime (123)"
	icon = 'icons/mob/slimes.dmi'
	icon_state = "grey"
	pass_flags = PASSTABLE | PASSGRILLE
	gender = NEUTER
	faction = list("slime","neutral")

	hud_possible = list(HEALTH_HUD,STATUS_HUD,ANTAG_HUD,NUTRITION_HUD)

	harm_intent_damage = 5
	icon_living = "grey"
	icon_dead = "grey-dead"
	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "shoos"
	response_disarm_simple = "shoo"
	response_harm_continuous = "stomps on"
	response_harm_simple = "stomp on"
	emote_see = list("jiggles", "bounces in place")
	speak_emote = list("blorbles")
	bubble_icon = "slime"
	initial_language_holder = /datum/language_holder/slime

	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_plas" = 0, "max_plas" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)

	maxHealth = 150
	health = 150
	healable = 0
	melee_damage_lower = 10
	melee_damage_upper = 20
	obj_damage = 5
	see_in_dark = 8
	speed = 0.75 //+1.5 from run speed
	see_in_dark = NIGHTVISION_FOV_RANGE
	maxbodytemp = 0 //Custom handling code
	minbodytemp = 0

	verb_say = "blorbles"
	verb_ask = "inquisitively blorbles"
	verb_exclaim = "loudly blorbles"
	verb_yell = "loudly blorbles"

	status_flags = CANUNCONSCIOUS|CANPUSH|CANSTUN

	footstep_type = FOOTSTEP_MOB_SLIME
	sentience_type = SENTIENCE_SLIME

	var/cores = 0 // the number of /obj/item/slime_extract's the slime has left inside
	var/max_cores = 1 // how much cores can this slime generate
	var/mutation_chance = 30 // Chance of mutating, should be between 25 and 35
	var/core_generation = 0 // Current progress on generating a new core

	var/powerlevel = 0 // 1-10 controls how much electricity they are generating
	var/amount_grown = 0 // controls how long the slime has been overfed, if 10, grows or reproduces
	var/is_adult = FALSE
	var/docile = FALSE

	var/number = 0 // Used to understand when someone is talking to it

	var/atom/movable/target = null // AI variable - tells the slime to hunt this down
	var/atom/movable/digesting = null // AI variable - stores the object that's currently being digested
	var/mob/living/leader = null // AI variable - tells the slime to follow this person
	var/current_loop_target = null // Stores current moveloop target, exists to prevent pointless moveloop creations and deletions
	var/datum/move_loop/move_loop // Stores currently active moveloop

	var/attacked = 0 // Determines if it's been attacked recently. Can be any number, is a cooloff-ish variable
	var/holding_still = 0 // AI variable, cooloff-ish for how long it's going to stay in one place
	var/target_patience = 0 // AI variable, cooloff-ish for how long it's going to follow its target
	var/digestion_progress = 0 // AI variable, starts at 0 and goes to 100
	var/list/moodlets = list() // AI variable, stores all active slime moodlets
	var/mood_level = 45 // AI variable, stores current mood level
	var/will_to_grow = FALSE //AI variable, when TRUE slime will have it's AI on as long as its nutrition is lower than required to grow
	var/list/recent_attackers = list() //AI variable, stores recent attackers.

	var/ai_active = FALSE // determines if the AI loop is activated
	COOLDOWN_DECLARE(attack_cd)
	var/discipline = 0 // if a slime has been hit with a freeze gun, or wrestled/attacked off a human, they become disciplined and don't attack anymore for a while

	var/mutable_appearance/digestion_overlay = null //Used for displaying what slime is digesting right now
	var/next_overlay_scale = 0.6 //Used for optimisation of digestion animation

	var/list/friends = list() // A list of friends; they are not considered targets for feeding; passed down after splitting

	var/list/speech_buffer = list() // Last phrase said near it and person who said it

	var/mood = "" // To show its face
	var/mutator_used = FALSE // So you can't shove a dozen mutators into a single slime

	var/nutrition_control = TRUE // When set to FALSE slime will constantly be hungry regardless of it's nutrition.
	var/obj/item/slime_accessory/accessory // Stores current slime accessory
	var/glittered = FALSE // If slime is covered with G L I T T E R. Fancy!

	var/static/regex/slime_name_regex = new("\\w+ (baby|adult) slime \\(\\d+\\)")
	///////////TIME FOR SUBSPECIES

	var/datum/slime_color/slime_color
	var/default_color

	var/list/slime_colors = list()

/mob/living/simple_animal/slime/proc/setup_colors()
	for(var/possible_slime_color in subtypesof(/datum/slime_color))
		var/datum/slime_color/possible_color = possible_slime_color
		if(initial(possible_color.slime_tags) & SLIME_NO_RANDOM_SPAWN)
			continue
		slime_colors += possible_slime_color

/mob/living/simple_animal/slime/Initialize(mapload, new_color=/datum/slime_color/grey, new_is_adult=FALSE)
	if(!LAZYLEN(slime_colors))
		setup_colors()
	var/datum/action/innate/slime/feed/feed_action = new
	feed_action.Grant(src)
	ADD_TRAIT(src, TRAIT_CANT_RIDE, INNATE_TRAIT)

	is_adult = new_is_adult

	if(is_adult)
		var/datum/action/innate/slime/reproduce/R = new
		R.Grant(src)
		health = 200
		maxHealth = 200
		create_reagents(500)
	else
		var/datum/action/innate/slime/grow_up/E = new
		E.Grant(src)
		create_reagents(250)

	if(default_color)
		new_color = default_color
	else if(!new_color || !ispath(new_color, /datum/slime_color))
		new_color = /datum/slime_color/grey

	set_color(new_color)
	. = ..()
	set_nutrition(700)
	add_cell_sample()

	ADD_TRAIT(src, TRAIT_VENTCRAWLER_ALWAYS, INNATE_TRAIT)
	AddElement(/datum/element/soft_landing)
	var/datum/atom_hud/data/human/medical/advanced/slime/slimehud = GLOB.huds[DATA_HUD_MEDICAL_SLIME]
	slimehud.add_atom_to_hud(src)
	RegisterSignal(src, COMSIG_LIVING_APPLY_WATER, .proc/apply_water)

/mob/living/simple_animal/slime/prepare_data_huds()
	. = ..()
	nutrition_hud_set_nutr()

/mob/living/simple_animal/slime/Destroy()
	for (var/datum/action/slime_action in actions)
		slime_action.Remove(src)
	set_target(null)
	set_leader(null)
	clear_friends()
	UnregisterSignal(src, COMSIG_LIVING_APPLY_WATER)
	return ..()

/mob/living/simple_animal/slime/proc/set_color(new_color)
	if(slime_color)
		slime_color.remove()
		QDEL_NULL(slime_color)
	slime_color = new new_color(src)
	update_name()
	regenerate_icons()

/mob/living/simple_animal/slime/update_name()
	if(slime_name_regex.Find(name))
		number = rand(1, 1000)
		name = "[slime_color.color] [is_adult ? "adult" : "baby"] slime ([number])"
		real_name = name
	return ..()

/mob/living/simple_animal/slime/proc/random_color()
	set_color(pick(slime_colors))

/mob/living/simple_animal/slime/regenerate_icons()
	if(SEND_SIGNAL(src, COMSIG_SLIME_REGENERATE_ICONS) & COMPONENT_SLIME_NO_ICON_REGENERATION)
		return

	cut_overlays()
	var/icon_text = "[slime_color.icon_color][is_adult ? "-adult" : ""]"
	icon_dead = "[icon_text]-dead[cores ? "" : "-nocore"]"
	if(stat != DEAD)
		icon_state = icon_text
		if(mood && !stat)
			var/mutable_appearance/mood_overlay = mutable_appearance(icon, "aslime-[mood]")
			mood_overlay.layer = layer + 0.06
			add_overlay(mood_overlay)
	else
		icon_state = icon_dead
		if(!cores)
			return ..()

	if(digesting)
		add_overlay(digestion_overlay)

	if(accessory)
		var/mutable_appearance/accessory_overlay = mutable_appearance(icon, "[accessory.icon_state][is_adult ? "-adult" : ""][stat == DEAD ? "-dead" : ""]")
		accessory_overlay.layer = layer + 0.05
		add_overlay(accessory_overlay)

	if(glittered)
		var/mutable_appearance/glitter_overlay = mutable_appearance(icon, "glitter[is_adult ? "-adult" : ""][stat == DEAD ? "-dead" : ""]")
		glitter_overlay.layer = layer + 0.04
		add_overlay(glitter_overlay)

	SEND_SIGNAL(src, COMSIG_SLIME_POST_REGENERATE_ICONS)
	return ..()

/mob/living/simple_animal/slime/updatehealth()
	. = ..()
	var/mod = 0
	if(!HAS_TRAIT(src, TRAIT_IGNOREDAMAGESLOWDOWN))
		var/health_deficiency = (maxHealth - health)
		if(health_deficiency >= 45)
			mod += (health_deficiency / 25)
		if(health <= 0)
			mod += 2
	add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/slime_healthmod, multiplicative_slowdown = mod)

/mob/living/simple_animal/slime/adjust_bodytemperature()
	. = ..()
	var/mod = 0
	if(bodytemperature >= slime_color.temperature_modifier + 60) // 135 F or 57.08 C
		mod = -1 // slimes become supercharged at high temperatures
	else if(bodytemperature < slime_color.temperature_modifier + 10)
		mod = ((slime_color.temperature_modifier + 10 - bodytemperature) / 10) * 1.75
	if(mod)
		add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/slime_tempmod, multiplicative_slowdown = mod)

/mob/living/simple_animal/slime/ObjBump(obj/bumpy)
	if(!client && powerlevel > 0)
		if(prob(powerlevel * 5 + max(SLIME_MOOD_LEVEL_HAPPY - mood_level, 0) / SLIME_MOOD_LEVEL_HAPPY * SLIME_MOOD_OBJ_ATTACK_CHANCE))
			if(istype(bumpy, /obj/structure/window) || istype(bumpy, /obj/structure/grille))
				if(nutrition <= get_hunger_nutrition() && COOLDOWN_FINISHED(src, attack_cd) && is_adult)
					attack_target(bumpy)
					COOLDOWN_START(src, attack_cd, slime_color.get_attack_cd(target))

/mob/living/simple_animal/slime/Process_Spacemove(movement_dir = 0, continuous_move = FALSE)
	return 2

/mob/living/simple_animal/slime/get_status_tab_items()
	. = ..()
	if(!docile)
		. += "Nutrition: [nutrition]/[get_max_nutrition()]"
	if(amount_grown >= SLIME_EVOLUTION_THRESHOLD)
		if(is_adult)
			. += "You can reproduce!"
		else
			. += "You can evolve!"

	switch(stat)
		if(HARD_CRIT, UNCONSCIOUS)
			. += "You are knocked out by high levels of BZ!"
		else
			. += "Power Level: [powerlevel]"

/mob/living/simple_animal/slime/adjustFireLoss(amount, updating_health = TRUE, forced = FALSE)
	if(!forced)
		amount = -abs(amount)
	adjust_bodytemperature(amount / 2)
	return ..() //Heals them

/mob/living/simple_animal/slime/bullet_act(obj/projectile/proj, def_zone, piercing_hit = FALSE)
	attacked += 10
	apply_moodlet(/datum/slime_moodlet/attacked)
	if(proj.firer)
		recent_attackers |= proj.firer
	if((proj.damage_type == BURN))
		adjustBruteLoss(-abs(proj.damage)) //fire projectiles heals slimes.
		proj.on_hit(src, 0, piercing_hit)
	else
		. = ..(proj)
	. = . || BULLET_ACT_BLOCK

/mob/living/simple_animal/slime/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	powerlevel = 0 // oh no, the power!

/mob/living/simple_animal/slime/MouseDrop(atom/movable/dropped as mob|obj)
	if(isliving(dropped) && dropped != src && usr == src)
		var/mob/living/food = dropped
		if(can_feed_on(food))
			feed_on(food)
	if(isitem(dropped))
		var/obj/item/food = dropped
		if(can_feed_on(food))
			gobble_up(food)
	return ..()

/mob/living/simple_animal/slime/Moved(atom/old_loc, new_dir)
	. = ..()
	if(QDELETED(src))
		return

	if(buckled && isliving(buckled) && get_turf(src) != get_turf(buckled))
		feed_stop(TRUE)

/mob/living/simple_animal/slime/doUnEquip(obj/item/item, force, newloc, no_move, invdrop = TRUE, silent = FALSE)
	return

/mob/living/simple_animal/slime/start_pulling(atom/movable/pull_attempt, state, force = move_force, supress_message = FALSE)
	return

/mob/living/simple_animal/slime/attack_ui(slot, params)
	return

/mob/living/simple_animal/slime/attack_slime(mob/living/simple_animal/slime/attacker)
	. = ..()
	if(.) //successful slime attack
		if(attacker == src)
			return

		if(buckled && isliving(buckled))
			feed_stop(silent = TRUE)
			visible_message(span_danger("[attacker] pulls [src] off!"), \
				span_danger("You pull [src] off!"))
			return

		attacked += 5
		apply_moodlet(/datum/slime_moodlet/attacked)
		recent_attackers |= attacker
		if(nutrition >= 100) //steal some nutrition. negval handled in life()
			adjust_nutrition(-(50 + (40 * attacker.is_adult)))
			attacker.add_nutrition(50 + (40 * attacker.is_adult))
		if(health > 0)
			attacker.adjustBruteLoss(-10 + (-10 * attacker.is_adult))
			attacker.updatehealth()

/mob/living/simple_animal/slime/attack_animal(mob/living/simple_animal/user, list/modifiers)
	. = ..()
	if(.)
		attacked += 10
		apply_moodlet(/datum/slime_moodlet/attacked)
		recent_attackers |= user

/mob/living/simple_animal/slime/attack_paw(mob/living/carbon/human/user, list/modifiers)
	. = ..()
	if(.) //successful monkey bite.
		attacked += 10
		apply_moodlet(/datum/slime_moodlet/attacked)
		recent_attackers |= user

/mob/living/simple_animal/slime/attack_larva(mob/living/carbon/alien/larva/larva)
	. = ..()
	if(.) //successful larva bite.
		attacked += 10
		apply_moodlet(/datum/slime_moodlet/attacked)
		recent_attackers |= larva

/mob/living/simple_animal/slime/attack_hulk(mob/living/carbon/human/user)
	. = ..()
	if(.)
		attacked += 10
		apply_moodlet(/datum/slime_moodlet/attacked)
		recent_attackers |= user

/mob/living/simple_animal/slime/attack_hand(mob/living/carbon/human/user, list/modifiers)
	if(!buckled || !isliving(buckled) || !LAZYACCESS(modifiers, RIGHT_CLICK))
		if(stat == DEAD && surgeries.len)
			if(!user.combat_mode || LAZYACCESS(modifiers, RIGHT_CLICK))
				for(var/datum/surgery/S in surgeries)
					if(S.next_step(user, modifiers))
						return 1
		. = ..()
		if(.) //successful attack
			attacked += 10
			apply_moodlet(/datum/slime_moodlet/attacked)
			recent_attackers |= user
		return

	user.do_attack_animation(src, ATTACK_EFFECT_DISARM)
	if(buckled == user)
		if(prob(60))
			user.visible_message(span_warning("[user] attempts to wrestle \the [name] off!"), \
				span_danger("You attempt to wrestle \the [name] off!"))
			playsound(loc, 'sound/weapons/punchmiss.ogg', 25, TRUE, -1)
		else
			user.visible_message(span_warning("[user] manages to wrestle \the [name] off!"), \
				span_notice("You manage to wrestle \the [name] off!"))
			playsound(loc, 'sound/weapons/thudswoosh.ogg', 50, TRUE, -1)
			discipline_slime(user)
		return

	if(prob(30))
		buckled.visible_message(span_warning("[user] attempts to wrestle \the [name] off of [buckled]!"), \
			span_warning("[user] attempts to wrestle \the [name] off of you!"))
		playsound(loc, 'sound/weapons/punchmiss.ogg', 25, TRUE, -1)
		return

	buckled.visible_message(span_warning("[user] manages to wrestle \the [name] off of [buckled]!"), \
		span_notice("[user] manage to wrestle \the [name] off of you!"))
	playsound(loc, 'sound/weapons/thudswoosh.ogg', 50, TRUE, -1)
	discipline_slime(user)

/mob/living/simple_animal/slime/attack_alien(mob/living/carbon/alien/humanoid/user, list/modifiers)
	. = ..()
	if(.) //if harm or disarm intent.
		attacked += 10
		apply_moodlet(/datum/slime_moodlet/attacked)
		discipline_slime(user)
		recent_attackers |= user

/mob/living/simple_animal/slime/attackby(obj/item/item, mob/living/user, params)
	if(stat == DEAD && surgeries.len)
		var/list/modifiers = params2list(params)
		if(!user.combat_mode || (LAZYACCESS(modifiers, RIGHT_CLICK)))
			for(var/datum/surgery/surgery in surgeries)
				if(surgery.next_step(user, modifiers))
					return TRUE

	if(istype(item, /obj/item/stack/sheet/mineral/plasma) && !stat) //Let's you feed slimes plasma.
		add_friendship(user, 1)
		to_chat(user, span_notice("You feed the slime the plasma. It chirps happily."))
		var/obj/item/stack/sheet/mineral/plasma/plasma = item
		plasma.use(1)
		return

	if(istype(item, /obj/item/slime_accessory))
		var/obj/item/slime_accessory/new_accessory = item
		if(accessory)
			to_chat(user, span_warning("[src] already has an accessory on!"))
			return
		if(!new_accessory.slime_equipped(src, user))
			to_chat(user, span_warning("You can't put [new_accessory] onto [src]."))
			return
		new_accessory.forceMove(src)
		to_chat(user, span_notice("You put [new_accessory] onto [src]."))
		return

	if(item.force > 0)
		attacked += 10
		apply_moodlet(/datum/slime_moodlet/attacked)
		recent_attackers |= user
		if(prob(15 + (10 * (item.sharpness == SHARP_EDGED))))
			user.do_attack_animation(src)
			user.changeNext_move(CLICK_CD_MELEE)
			to_chat(user, span_danger("[item] passes right through [src]!"))
			return

		if(discipline && prob(50)) // wow, buddy, why am I getting attacked??
			discipline = 0

	if(item.force >= 3)
		var/force_effect = 2 * item.force
		if(is_adult)
			force_effect = round(item.force/2)
		if(prob(10 + force_effect))
			discipline_slime(user)

	. = ..()

/mob/living/simple_animal/slime/AltClick(mob/user)
	. = ..()
	if(!Adjacent(user) || !isliving(user))
		return

	if(!accessory)
		to_chat(user, span_warning("[src] doesn't have any accessory on!"))
		return

	if(!accessory.slime_unequipped(src, user))
		to_chat(user, span_warning("You can't remove [accessory] from [src]."))
		return

	accessory.forceMove(get_turf(src))
	user.put_in_hands(accessory)
	to_chat(user, span_notice("You remove [accessory] from [src]."))
	accessory = null
	regenerate_icons()

/mob/living/simple_animal/slime/proc/apply_water()
	SIGNAL_HANDLER
	if(slime_color.slime_tags & SLIME_WATER_IMMUNITY)
		return

	var/damage_modifier = 1
	if(slime_color.slime_tags & SLIME_WATER_WEAKNESS)
		damage_modifier *= 1.5
	if(slime_color.slime_tags & SLIME_WATER_RESISTANCE)
		damage_modifier *= 0.5

	adjustBruteLoss(rand(15, 20) * damage_modifier)
	if(!client)
		if(target && !HAS_TRAIT(src, TRAIT_SLIME_RABID)) // Like cats
			set_target(null)
			discipline += 1
		apply_moodlet(/datum/slime_moodlet/watered)
	return

/mob/living/simple_animal/slime/examine(mob/user)
	var/examine_text = list()
	examine_text += span_info("*---------*")
	examine_text += span_info("This is [icon2html(src, user)] \a <EM>[src]</EM>!")
	if(stat == DEAD)
		examine_text += span_deadsay("It is limp and unresponsive.")
		examine_text += span_info("*---------*")
		SEND_SIGNAL(src, COMSIG_PARENT_EXAMINE, user, examine_text)
		return examine_text

	if(stat)
		examine_text += span_deadsay("It appears to be alive, but unresponsive.")

	if(HAS_TRAIT(user, TRAIT_RESEARCH_SCANNER))
		examine_text += span_info("*---------*")
		examine_text += span_notice("Nutrition: [nutrition]/[get_max_nutrition()]")
		if (nutrition < get_starve_nutrition())
			examine_text += span_warning("Warning: slime is starving!")
		else if (nutrition < get_hunger_nutrition())
			examine_text += span_warning("Warning: slime is hungry")

		examine_text += span_notice("Electric change strength: [powerlevel]")
		examine_text += span_notice("Health: [round(health / maxHealth, 0.01) * 100]%")
		examine_text += span_notice("Growth progress: [amount_grown]/[SLIME_EVOLUTION_THRESHOLD]")

		SEND_SIGNAL(src, COMSIG_PARENT_EXAMINE, user, examine_text)
		return examine_text

	if(getBruteLoss() >= 40)
		examine_text += span_boldwarning("It has severe punctures and tears in its flesh!")
	else if(getBruteLoss())
		examine_text += span_warning("It has some punctures in its flesh!")

	switch(powerlevel)
		if(2 to 3)
			examine_text += "It is flickering gently with a little electrical activity."
		if(4 to 5)
			examine_text += "It is glowing gently with moderate levels of electrical activity."
		if(6 to 9)
			examine_text += span_warning("It is glowing brightly with high levels of electrical activity.")
		if(10)
			examine_text += span_boldwarning("It is radiating with massive levels of electrical activity!")

	examine_text += span_info("*---------*")

	SEND_SIGNAL(src, COMSIG_PARENT_EXAMINE, user, examine_text)
	return examine_text

/mob/living/simple_animal/slime/proc/discipline_slime(mob/user)
	if(stat)
		return

	if(prob(80) && !client)
		discipline++
		apply_moodlet(/datum/slime_moodlet/disciplined)

		if(!is_adult)
			if(discipline == 1)
				attacked = 0

	set_target(null)
	if(buckled && isliving(buckled))
		feed_stop(silent = TRUE) //we unbuckle the slime from the mob it latched onto.

	Stun(rand(20, 40))
	stop_moveloop()

/mob/living/simple_animal/slime/pet
	docile = TRUE

/mob/living/simple_animal/slime/get_mob_buckling_height(mob/seat)
	. = ..()
	if(.)
		return 3

/mob/living/simple_animal/slime/random/Initialize(mapload, new_color, new_is_adult)
	setup_colors()
	. = ..(mapload, pick(slime_colors), prob(50))

/mob/living/simple_animal/slime/add_cell_sample()
	AddElement(/datum/element/swabable, CELL_LINE_TABLE_SLIME, CELL_VIRUS_TABLE_GENERIC_MOB, 1, 5)

/mob/living/simple_animal/slime/proc/set_target(new_target)
	if(SEND_SIGNAL(src, COMSIG_SLIME_SET_TARGET, target, new_target) & COMPONENT_SLIME_NO_SET_TARGET)
		return
	var/old_target = target
	target = new_target
	if(!new_target)
		stop_moveloop()
	if(old_target && !SLIME_CARES_ABOUT(old_target))
		UnregisterSignal(old_target, COMSIG_PARENT_QDELETING)
	if(target)
		RegisterSignal(target, COMSIG_PARENT_QDELETING, .proc/clear_memories_of, override = TRUE)

/mob/living/simple_animal/slime/proc/set_leader(new_leader)
	var/old_leader = leader
	leader = new_leader
	if(old_leader && !SLIME_CARES_ABOUT(old_leader))
		UnregisterSignal(old_leader, COMSIG_PARENT_QDELETING)
	if(leader)
		RegisterSignal(leader, COMSIG_PARENT_QDELETING, .proc/clear_memories_of, override = TRUE)

/mob/living/simple_animal/slime/proc/add_friendship(new_friend, amount = 1)
	if(!friends[new_friend])
		friends[new_friend] = 0
	friends[new_friend] += amount
	if(friends[new_friend] <= 0)
		remove_friend(new_friend)
		return
	if(new_friend)
		RegisterSignal(new_friend, COMSIG_PARENT_QDELETING, .proc/clear_memories_of, override = TRUE)

/mob/living/simple_animal/slime/proc/set_friendship(new_friend, amount = 1)
	friends[new_friend] = amount
	if(new_friend)
		RegisterSignal(new_friend, COMSIG_PARENT_QDELETING, .proc/clear_memories_of, override = TRUE)

/mob/living/simple_animal/slime/proc/remove_friend(friend)
	friends -= friend
	if(friend && !SLIME_CARES_ABOUT(friend))
		UnregisterSignal(friend, COMSIG_PARENT_QDELETING)

/mob/living/simple_animal/slime/proc/set_friends(new_buds)
	clear_friends()
	for(var/mob/friend as anything in new_buds)
		set_friendship(friend, new_buds[friend])

/mob/living/simple_animal/slime/proc/clear_friends()
	for(var/mob/friend as anything in friends)
		remove_friend(friend)

/mob/living/simple_animal/slime/proc/clear_memories_of(datum/source)
	SIGNAL_HANDLER
	if(source == target)
		set_target(null)
	if(source == leader)
		set_leader(null)
	remove_friend(source)

/mob/living/simple_animal/slime/Destroy()
	if(accessory)
		accessory.slime_unequipped(src, forced = TRUE)
		accessory.forceMove(get_turf(src))
		accessory = null
	. = ..()

/mob/living/simple_animal/slime/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	if(can_feed_on(hit_atom, silent = TRUE))
		feed_on(hit_atom)

/mob/living/simple_animal/slime/death(gibbed)
	if(stat == DEAD)
		return

	if(!gibbed && is_adult)
		var/mob/living/simple_animal/slime/split = new(drop_location(), slime_color.type)
		ADD_TRAIT(split, TRAIT_SLIME_RABID, "slime_death")
		split.regenerate_icons()

		is_adult = FALSE
		maxHealth = 150
		max_cores = max(1, round(max_cores / 2))
		split.max_cores = max_cores
		for(var/datum/action/innate/slime/reproduce/reproduce_action in actions)
			reproduce_action.Remove(src)
		var/datum/action/innate/slime/grow_up/grow_action = new
		grow_action.Grant(src)
		revive(full_heal = TRUE, admin_revive = FALSE)
		regenerate_icons()
		update_name()
		return

	if(buckled && isliving(buckled))
		feed_stop(silent = TRUE) //releases ourselves from the mob we fed on.

	set_stat(DEAD)
	regenerate_icons()
	for(var/mob/living/simple_animal/slime/slime in view(5, get_turf(src)))
		slime.apply_moodlet(/datum/slime_moodlet/dead_slimes)
		if(target) //Likely our killer
			slime.add_friendship(target, -1)
	stop_moveloop()
	return ..(gibbed)

/mob/living/simple_animal/slime/gib()
	death(TRUE)
	qdel(src)

/mob/living/simple_animal/slime/Hear(message, atom/movable/speaker, message_langs, raw_message, radio_freq, spans, list/message_mods = list())
	. = ..()
	if(speaker == src || radio_freq || stat || !(speaker in friends))
		return

	speech_buffer = list()
	speech_buffer += speaker
	speech_buffer += lowertext(raw_message)

/mob/living/simple_animal/slime/proc/apply_moodlet(datum/slime_moodlet/moodlet_type)
	if(moodlet_type in moodlets)
		if(initial(moodlet_type.duration))
			QDEL_NULL(moodlets[moodlet_type])
			moodlets -= moodlet_type
		else
			return

	var/datum/slime_moodlet/new_moodlet = new moodlet_type()
	if(new_moodlet.duration > 0)
		QDEL_IN(new_moodlet, new_moodlet.duration)
	moodlets[moodlet_type] = new_moodlet

/mob/living/simple_animal/slime/proc/remove_moodlet(moodlet_type)
	if(!(moodlet_type in moodlets))
		return

	QDEL_NULL(moodlets[moodlet_type])
	moodlets -= moodlet_type

#undef SLIME_CARES_ABOUT
