#define SLIME_CARES_ABOUT(to_check) (to_check && (to_check == Target || to_check == Leader || (to_check in Friends)))
/mob/living/simple_animal/slime
	name = "grey baby slime (123)"
	icon = 'icons/mob/slimes.dmi'
	icon_state = "grey baby slime"
	pass_flags = PASSTABLE | PASSGRILLE
	gender = NEUTER
	var/is_adult = 0
	var/docile = 0
	faction = list("slime","neutral")

	hud_possible = list(HEALTH_HUD,STATUS_HUD,ANTAG_HUD,NUTRITION_HUD)

	harm_intent_damage = 5
	icon_living = "grey baby slime"
	icon_dead = "grey baby slime dead"
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
	melee_damage_lower = 5
	melee_damage_upper = 25
	obj_damage = 5
	see_in_dark = 8
	speed = 0.5 //+1.5 from run speed

	verb_say = "blorbles"
	verb_ask = "inquisitively blorbles"
	verb_exclaim = "loudly blorbles"
	verb_yell = "loudly blorbles"

	// canstun and canknockdown don't affect slimes because they ignore stun and knockdown variables
	// for the sake of cleanliness, though, here they are.
	status_flags = CANUNCONSCIOUS|CANPUSH

	footstep_type = FOOTSTEP_MOB_SLIME

	var/cores = 0 // the number of /obj/item/slime_extract's the slime has left inside
	var/max_cores = 1 // how much cores can this slime generate
	var/mutation_chance = 30 // Chance of mutating, should be between 25 and 35
	var/core_generation = 0 // Current progress on generating a new core

	var/powerlevel = 0 // 1-10 controls how much electricity they are generating
	var/amount_grown = 0 // controls how long the slime has been overfed, if 10, grows or reproduces

	var/number = 0 // Used to understand when someone is talking to it

	var/atom/movable/Target = null // AI variable - tells the slime to hunt this down
	var/atom/movable/Digesting = null // AI variable - stores the object that's currently being digested
	var/mob/living/Leader = null // AI variable - tells the slime to follow this person
	var/current_loop_target = null // Stores current moveloop target, exists to prevent pointless moveloop creations and deletions

	var/attacked = 0 // Determines if it's been attacked recently. Can be any number, is a cooloff-ish variable
	var/rabid = 0 // If set to 1, the slime will attack and eat anything it comes in contact with
	var/holding_still = 0 // AI variable, cooloff-ish for how long it's going to stay in one place
	var/target_patience = 0 // AI variable, cooloff-ish for how long it's going to follow its target
	var/digestion_progress = 0 //AI variable, starts at 0 and goes to 100
	var/mood_level = 50 //AI variable, from 0 to 100, determines slime's mood and it's behaviour

	var/mutable_appearance/digestion_overlay = null //Used for displaying what slime is digesting right now
	var/next_overlay_scale = 0.6 //Used for optimisation of digestion animation

	var/list/Friends = list() // A list of friends; they are not considered targets for feeding; passed down after splitting

	var/list/speech_buffer = list() // Last phrase said near it and person who said it

	var/mood = "" // To show its face
	var/mutator_used = FALSE // So you can't shove a dozen mutators into a single slime
	var/force_stasis = FALSE // When set to TRUE slime will be forcefully put into stasis regardless of BZ concentration

	var/nutrition_control = TRUE // When set to FALSE slime will constantly be hungry regardless of it's nutrition.
	var/obj/item/slime_accessory/accessory // Stores current slime accessory
	var/glittered = FALSE // If slime is covered with G L I T T E R. Fancy!

	var/static/regex/slime_name_regex = new("\\w+ (baby|adult) slime \\(\\d+\\)")
	///////////TIME FOR SUBSPECIES

	var/datum/slime_color/slime_color

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
	var/datum/action/innate/slime/feed/F = new
	F.Grant(src)
	ADD_TRAIT(src, TRAIT_CANT_RIDE, INNATE_TRAIT)

	is_adult = new_is_adult

	if(is_adult)
		var/datum/action/innate/slime/reproduce/R = new
		R.Grant(src)
		health = 200
		maxHealth = 200
	else
		var/datum/action/innate/slime/evolve/E = new
		E.Grant(src)
	create_reagents(100)
	if(!new_color || !ispath(new_color, /datum/slime_color))
		new_color = /datum/slime_color/grey
	set_color(new_color)
	. = ..()
	set_nutrition(700)
	add_cell_sample()

	ADD_TRAIT(src, TRAIT_VENTCRAWLER_ALWAYS, INNATE_TRAIT)
	AddElement(/datum/element/soft_landing)

/mob/living/simple_animal/slime/Destroy()
	for (var/A in actions)
		var/datum/action/AC = A
		AC.Remove(src)
	set_target(null)
	set_leader(null)
	clear_friends()
	return ..()

/mob/living/simple_animal/slime/create_reagents(max_vol, flags)
	. = ..()
	RegisterSignal(reagents, list(COMSIG_REAGENTS_NEW_REAGENT, COMSIG_REAGENTS_DEL_REAGENT), .proc/on_reagent_change)
	RegisterSignal(reagents, COMSIG_PARENT_QDELETING, .proc/on_reagents_del)

/// Handles removing signal hooks incase someone is crazy enough to reset the reagents datum.
/mob/living/simple_animal/slime/proc/on_reagents_del(datum/reagents/reagents)
	SIGNAL_HANDLER
	UnregisterSignal(reagents, list(COMSIG_REAGENTS_NEW_REAGENT, COMSIG_REAGENTS_DEL_REAGENT, COMSIG_PARENT_QDELETING))
	return NONE

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
	if(SEND_SIGNAL(src, COMSIG_SLIME_REGENERATE_ICONS) & COLOR_SLIME_NO_ICON_REGENERATION)
		return

	cut_overlays()
	var/icon_text = "[slime_color.icon_color][is_adult ? "-adult" : ""]"
	icon_dead = "[icon_text]-dead[cores ? "" : "-nocore"]"
	if(stat != DEAD)
		icon_state = icon_text
		if(mood && !stat)
			add_overlay("aslime-[mood]")
	else
		icon_state = icon_dead
		if(!cores)
			return ..()

	if(Digesting)
		add_overlay(digestion_overlay)
	if(accessory)
		var/mutable_appearance/accessory_overlay = mutable_appearance(icon, "[accessory.icon_state][is_adult ? "-adult" : ""][stat == DEAD ? "-dead" : ""]")
		add_overlay(accessory_overlay)
	if(glittered)
		var/mutable_appearance/glitter_overlay = mutable_appearance(icon, "glitter[is_adult ? "-adult" : ""][stat == DEAD ? "-dead" : ""]")
		add_overlay(glitter_overlay)
	return ..()

/**
 * Snowflake handling of reagent movespeed modifiers
 *
 * Should be moved to the reagents at some point in the future. As it is I'm in a hurry.
 */
/mob/living/simple_animal/slime/proc/on_reagent_change(datum/reagents/holder, ...)
	SIGNAL_HANDLER
	remove_movespeed_modifier(/datum/movespeed_modifier/slime_reagentmod)
	var/amount = 0
	if(reagents.has_reagent(/datum/reagent/medicine/morphine)) // morphine slows slimes down
		amount = 2
	if(reagents.has_reagent(/datum/reagent/consumable/frostoil)) // Frostoil also makes them move VEEERRYYYYY slow
		amount = 5
	if(amount)
		add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/slime_reagentmod, multiplicative_slowdown = amount)
	if(reagents.has_reagent(/datum/reagent/glitter))
		glittered = TRUE
	return NONE

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
	if(bodytemperature >= 330.23) // 135 F or 57.08 C
		mod = -1 // slimes become supercharged at high temperatures
	else if(bodytemperature < 283.222)
		mod = ((283.222 - bodytemperature) / 10) * 1.75
	if(mod)
		add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/slime_tempmod, multiplicative_slowdown = mod)

/mob/living/simple_animal/slime/ObjBump(obj/O)
	if(!client && powerlevel > 0)
		if(prob(powerlevel * 5 + max(SLIME_MOOD_LEVEL_HAPPY - mood_level, 0) / SLIME_MOOD_LEVEL_HAPPY * SLIME_MOOD_OBJ_ATTACK_CHANCE))
			if(istype(O, /obj/structure/window) || istype(O, /obj/structure/grille))
				if(nutrition <= get_hunger_nutrition() && !Atkcool && is_adult)
					attack_target(O)
					Atkcool = TRUE
					addtimer(VARSET_CALLBACK(src, Atkcool, FALSE), 4.5 SECONDS)

/mob/living/simple_animal/slime/Process_Spacemove(movement_dir = 0)
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

/mob/living/simple_animal/slime/bullet_act(obj/projectile/Proj, def_zone, piercing_hit = FALSE)
	attacked += 10
	if((Proj.damage_type == BURN))
		adjustBruteLoss(-abs(Proj.damage)) //fire projectiles heals slimes.
		Proj.on_hit(src, 0, piercing_hit)
	else
		. = ..(Proj)
	. = . || BULLET_ACT_BLOCK

/mob/living/simple_animal/slime/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	powerlevel = 0 // oh no, the power!

/mob/living/simple_animal/slime/MouseDrop(atom/movable/A as mob|obj)
	if(isliving(A) && A != src && usr == src)
		var/mob/living/Food = A
		if(CanFeedon(Food))
			Feedon(Food)
	return ..()

/mob/living/simple_animal/slime/doUnEquip(obj/item/I, force, newloc, no_move, invdrop = TRUE, silent = FALSE)
	return

/mob/living/simple_animal/slime/start_pulling(atom/movable/AM, state, force = move_force, supress_message = FALSE)
	return

/mob/living/simple_animal/slime/attack_ui(slot, params)
	return

/mob/living/simple_animal/slime/attack_slime(mob/living/simple_animal/slime/M)
	. = ..()
	if(.) //successful slime attack
		if(M == src)
			return
		if(buckled)
			Feedstop(silent = TRUE)
			visible_message(span_danger("[M] pulls [src] off!"), \
				span_danger("You pull [src] off!"))
			return
		attacked += 5
		if(nutrition >= 100) //steal some nutrition. negval handled in life()
			adjust_nutrition(-(50 + (40 * M.is_adult)))
			M.add_nutrition(50 + (40 * M.is_adult))
		if(health > 0)
			M.adjustBruteLoss(-10 + (-10 * M.is_adult))
			M.updatehealth()

/mob/living/simple_animal/slime/attack_animal(mob/living/simple_animal/user, list/modifiers)
	. = ..()
	if(.)
		attacked += 10


/mob/living/simple_animal/slime/attack_paw(mob/living/carbon/human/user, list/modifiers)
	. = ..()
	if(.) //successful monkey bite.
		attacked += 10

/mob/living/simple_animal/slime/attack_larva(mob/living/carbon/alien/larva/L)
	. = ..()
	if(.) //successful larva bite.
		attacked += 10

/mob/living/simple_animal/slime/attack_hulk(mob/living/carbon/human/user)
	. = ..()
	if(.)
		discipline_slime(user)

/mob/living/simple_animal/slime/attack_hand(mob/living/carbon/human/user, list/modifiers)
	if(buckled)
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

		else
			if(prob(30))
				buckled.visible_message(span_warning("[user] attempts to wrestle \the [name] off of [buckled]!"), \
					span_warning("[user] attempts to wrestle \the [name] off of you!"))
				playsound(loc, 'sound/weapons/punchmiss.ogg', 25, TRUE, -1)

			else
				buckled.visible_message(span_warning("[user] manages to wrestle \the [name] off of [buckled]!"), \
					span_notice("[user] manage to wrestle \the [name] off of you!"))
				playsound(loc, 'sound/weapons/thudswoosh.ogg', 50, TRUE, -1)

				discipline_slime(user)
	else
		if(stat == DEAD && surgeries.len)
			if(!user.combat_mode || LAZYACCESS(modifiers, RIGHT_CLICK))
				for(var/datum/surgery/S in surgeries)
					if(S.next_step(user, modifiers))
						return 1
		. = ..()
		if(.) //successful attack
			attacked += 10

/mob/living/simple_animal/slime/attack_alien(mob/living/carbon/alien/humanoid/user, list/modifiers)
	. = ..()
	if(.) //if harm or disarm intent.
		attacked += 10
		discipline_slime(user)


/mob/living/simple_animal/slime/attackby(obj/item/W, mob/living/user, params)
	if(stat == DEAD && surgeries.len)
		var/list/modifiers = params2list(params)
		if(!user.combat_mode || (LAZYACCESS(modifiers, RIGHT_CLICK)))
			for(var/datum/surgery/S in surgeries)
				if(S.next_step(user, modifiers))
					return 1
	if(istype(W, /obj/item/stack/sheet/mineral/plasma) && !stat) //Let's you feed slimes plasma.
		add_friendship(user, 1)
		to_chat(user, span_notice("You feed the slime the plasma. It chirps happily."))
		var/obj/item/stack/sheet/mineral/plasma/S = W
		S.use(1)
		return
	if(istype(W, /obj/item/slime_accessory))
		var/obj/item/slime_accessory/new_accessory = W
		if(accessory)
			to_chat(user, span_warning("[src] already has an accessory on!"))
			return
		if(!new_accessory.slime_equipped(src, user))
			to_chat(user, span_warning("You can't put [new_accessory] onto [src]."))
			return
		new_accessory.forceMove(src)
		to_chat(user, span_notice("You put [new_accessory] onto [src]."))
		return
	if(W.force > 0)
		attacked += 10
		if(prob(25))
			user.do_attack_animation(src)
			user.changeNext_move(CLICK_CD_MELEE)
			to_chat(user, span_danger("[W] passes right through [src]!"))
			return
		if(Discipline && prob(50)) // wow, buddy, why am I getting attacked??
			Discipline = 0
	if(W.force >= 3)
		var/force_effect = 2 * W.force
		if(is_adult)
			force_effect = round(W.force/2)
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
	if(slime_color.slime_tags & SLIME_WATER_IMMUNITY)
		return

	adjustBruteLoss(rand(15,20))
	if(!client)
		if(Target) // Like cats
			set_target(null)
			++Discipline
		mood_level -= SLIME_MOOD_WATER_LOSS
	return

/mob/living/simple_animal/slime/examine(mob/user)
	. = list("<span class='info'>*---------*\nThis is [icon2html(src, user)] \a <EM>[src]</EM>!")
	if (stat == DEAD)
		. += span_deadsay("It is limp and unresponsive.")
	else
		if (stat == UNCONSCIOUS || stat == HARD_CRIT) // Slime stasis
			. += span_deadsay("It appears to be alive but unresponsive.")
		if (getBruteLoss())
			. += "<span class='warning'>"
			if (getBruteLoss() < 40)
				. += "It has some punctures in its flesh!"
			else
				. += "<B>It has severe punctures and tears in its flesh!</B>"
			. += "</span>\n"

		switch(powerlevel)
			if(2 to 3)
				. += "It is flickering gently with a little electrical activity."

			if(4 to 5)
				. += "It is glowing gently with moderate levels of electrical activity."

			if(6 to 9)
				. += span_warning("It is glowing brightly with high levels of electrical activity.")

			if(10)
				. += span_warning("<B>It is radiating with massive levels of electrical activity!</B>")

	. += "*---------*</span>"

/mob/living/simple_animal/slime/proc/discipline_slime(mob/user)
	if(stat)
		return

	if(prob(80) && !client)
		Discipline++
		mood_level -= SLIME_MOOD_DISCIPLINE_LOSS

		if(!is_adult)
			if(Discipline == 1)
				attacked = 0

	set_target(null)
	if(buckled)
		Feedstop(silent = TRUE) //we unbuckle the slime from the mob it latched onto.

	Stun(rand(20, 40))
	stop_moveloop()

/mob/living/simple_animal/slime/pet
	docile = 1

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
	var/old_target = Target
	Target = new_target
	if(!new_target)
		stop_moveloop()
	if(old_target && !SLIME_CARES_ABOUT(old_target))
		UnregisterSignal(old_target, COMSIG_PARENT_QDELETING)
	if(Target)
		RegisterSignal(Target, COMSIG_PARENT_QDELETING, .proc/clear_memories_of, override = TRUE)

/mob/living/simple_animal/slime/proc/set_leader(new_leader)
	var/old_leader = Leader
	Leader = new_leader
	if(old_leader && !SLIME_CARES_ABOUT(old_leader))
		UnregisterSignal(old_leader, COMSIG_PARENT_QDELETING)
	if(Leader)
		RegisterSignal(Leader, COMSIG_PARENT_QDELETING, .proc/clear_memories_of, override = TRUE)

/mob/living/simple_animal/slime/proc/add_friendship(new_friend, amount = 1)
	if(!Friends[new_friend])
		Friends[new_friend] = 0
	Friends[new_friend] += amount
	if(Friends[new_friend] <= 0)
		remove_friend(new_friend)
		return
	if(new_friend)
		RegisterSignal(new_friend, COMSIG_PARENT_QDELETING, .proc/clear_memories_of, override = TRUE)

/mob/living/simple_animal/slime/proc/set_friendship(new_friend, amount = 1)
	Friends[new_friend] = amount
	if(new_friend)
		RegisterSignal(new_friend, COMSIG_PARENT_QDELETING, .proc/clear_memories_of, override = TRUE)

/mob/living/simple_animal/slime/proc/remove_friend(friend)
	Friends -= friend
	if(friend && !SLIME_CARES_ABOUT(friend))
		UnregisterSignal(friend, COMSIG_PARENT_QDELETING)

/mob/living/simple_animal/slime/proc/set_friends(new_buds)
	clear_friends()
	for(var/mob/friend as anything in new_buds)
		set_friendship(friend, new_buds[friend])

/mob/living/simple_animal/slime/proc/clear_friends()
	for(var/mob/friend as anything in Friends)
		remove_friend(friend)

/mob/living/simple_animal/slime/proc/clear_memories_of(datum/source)
	SIGNAL_HANDLER
	if(source == Target)
		set_target(null)
	if(source == Leader)
		set_leader(null)
	remove_friend(source)

/mob/living/simple_animal/slime/Destroy()
	if(accessory)
		accessory.slime_unequipped(src)
		accessory.forceMove(get_turf(src))
		accessory = null
	. = ..()

#undef SLIME_CARES_ABOUT
