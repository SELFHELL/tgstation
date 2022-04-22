
/mob/living/simple_animal/slime
	var/AIproc = 0 // determines if the AI loop is activated
	var/Atkcool = 0 // attack cooldown
	var/Discipline = 0 // if a slime has been hit with a freeze gun, or wrestled/attacked off a human, they become disciplined and don't attack anymore for a while


/mob/living/simple_animal/slime/Life(delta_time = SSMOBS_DT, times_fired)
	if (notransform)
		return
	. = ..()
	if(!.)
		return

	if(!slime_color) //If we SOMEHOW lost our color, be it BYOND wizardry, shitcode or adminbus, we become error slimes because it's extremely important to have one
		set_color(/datum/slime_color)

	if(buckled)
		handle_feeding(delta_time, times_fired)
	if(stat) // Slimes in stasis don't lose nutrition, don't change mood and don't respond to speech
		return
	handle_nutrition(delta_time, times_fired)
	if(QDELETED(src)) // Stop if the slime split during handle_nutrition()
		return
	reagents.remove_all(0.5 * REAGENTS_METABOLISM * reagents.reagent_list.len * delta_time) //Slimes are such snowflakes
	handle_targets(delta_time, times_fired)
	handle_digestion(delta_time, times_fired)
	slime_color.Life(delta_time, times_fired)
	if(accessory)
		accessory.on_life(delta_time, times_fired)
	if(ckey)
		return
	handle_mood(delta_time, times_fired)
	handle_speech(delta_time, times_fired)


// Unlike most of the simple animals, slimes support UNCONSCIOUS. This is an ugly hack.
/mob/living/simple_animal/slime/update_stat()
	switch(stat)
		if(UNCONSCIOUS, HARD_CRIT)
			if(health > 0)
				return
	return ..()


/mob/living/simple_animal/slime/proc/AIprocess()  // the master AI process

	if(AIproc || stat || client)
		return

	var/hungry = 0

	AIproc = 1

	while(AIproc && stat != DEAD && (attacked || hungry || rabid || buckled || Target))

		if(!(mobility_flags & MOBILITY_MOVE)) //also covers buckling. Not sure why buckled is in the while condition if we're going to immediately break, honestly
			stop_moveloop()
			break

		if(!Target || client)
			stop_moveloop()
			break

		if(isliving(Target))
			var/mob/living/victim = Target
			if(victim.health <= -70 || victim.stat == DEAD)
				set_target(null)
				AIproc = 0
				break

		if (nutrition < get_starve_nutrition())
			hungry = 2
		else if (nutrition < get_grow_nutrition() && prob(25) || nutrition < get_hunger_nutrition())
			hungry = 1

		if(Target)
			if(locate(/mob/living/simple_animal/slime) in Target.buckled_mobs)
				set_target(null)
				AIproc = 0
				break
			if(!AIproc)
				stop_moveloop()
				break
			if(Target in view(1,src))
				if(!CanFeedon(Target)) //If they're not able to be fed upon, ignore them.
					if(!Atkcool)
						Atkcool = TRUE
						addtimer(VARSET_CALLBACK(src, Atkcool, FALSE), 4.5 SECONDS)
						if(Target.Adjacent(src))
							attack_target(Target)
				else if(isliving(Target))
					var/mob/living/victim = Target
					if((victim.body_position == STANDING_UP) && prob(80))
						if(victim.client && victim.health >= 20)
							if(!Atkcool)
								Atkcool = TRUE
								addtimer(VARSET_CALLBACK(src, Atkcool, FALSE), 4.5 SECONDS)

								if(victim.Adjacent(src))
									attack_target(victim)

						else
							if(!Atkcool && victim.Adjacent(src))
								Feedon(victim)
					else
						if(!Atkcool && victim.Adjacent(src))
							Feedon(victim)
				else
					gobble_up(Target)

			else if(get_dist(Target, src) <= 9) //Previously this used view which is extremely expensive. Also you can no longer make slimes forget about your existence by just hiding behind the corner
				if(!Target.Adjacent(src)) // Bug of the month candidate: slimes were attempting to move to target only if it was directly next to them, which caused them to target things, but not approach them
					start_moveloop(Target)
			else
				set_target(null)
				AIproc = 0
				break
		sleep(5)

	AIproc = 0


/mob/living/simple_animal/slime/proc/attack_target(atom/attack_target)
	if(SEND_SIGNAL(src, COMSIG_SLIME_ATTACK_TARGET, attack_target) & COLOR_SLIME_NO_ATTACK)
		return

	attack_target.attack_slime(src)

/mob/living/simple_animal/slime/proc/start_moveloop(atom/move_target)
	if(move_target == current_loop_target)
		return

	var/sleeptime = cached_multiplicative_slowdown
	if(sleeptime <= 0)
		sleeptime = 0

	stop_moveloop()
	current_loop_target = move_target

	var/datum/move_loop/has_target/jps/move_loop = SSmove_manager.jps_move(moving = src,
																		   chasing = move_target,
																		   delay = sleeptime,
																		   repath_delay = 2 SECONDS,
																		   max_path_length = AI_MAX_PATH_LENGTH,
																		   minimum_distance = 1,
																		   simulated_only = TRUE,
																		   //additional_checks = list(.proc/jps_check = src)
																		   )
	RegisterSignal(move_loop, COMSIG_PARENT_QDELETING, .proc/loop_ended)

/mob/living/simple_animal/slime/proc/loop_ended()
	current_loop_target = null

/mob/living/simple_animal/slime/proc/stop_moveloop()
	if(!current_loop_target)
		return
	SSmove_manager.stop_looping(src)
	current_loop_target = null

/mob/living/simple_animal/slime/proc/jps_check(turf/cur_turf, turf/next_turf) // !cur_turf.LinkBlockedWithAccess(next,caller, id)
	if(!next_turf || next_turf.density || SSpathfinder.space_type_cache[next_turf.type]) //CAN_STEP will handle it
		return

	var/list/check_result = cur_turf.LinkBlockedWithAccess(next_turf, src, null)
	if(!check_result || !LAZYLEN(check_result)) //We don't need to interfere if the path is already open
		return

	for(var/obj/machinery/door/window/windoor in check_result) //If we have airlock/windoor/whatever here it means that they're already closed, rotated towards us and non-public access so we don't need to check for that
		if(!windoor.powered())
			check_result -= windoor

	for(var/obj/machinery/door/airlock/airlock in check_result)
		if(!airlock.locked)
			check_result -= airlock

	for(var/obj/machinery/door/firedoor/firelock in check_result)
		check_result -= firelock

	if(LAZYLEN(check_result)) //There's something else blocking our way, aborting
		return

	return list(TRUE, JPS_CHECK_OVERRIDE)

	/*

	if(!Adjacent(step_target))
		step_target = get_step(get_turf(src), get_dir(src, step_target))

	var/obj/machinery/door/airlock/airlock = locate(/obj/machinery/door/airlock) in get_turf(step_target)
	var/obj/machinery/door/firedoor/firedoor = locate(/obj/machinery/door/firedoor) in get_turf(step_target)
	var/obj/machinery/door/window/windoor = locate(/obj/machinery/door/window) in get_turf(step_target)

	var/can_squeese = TRUE
	var/should_squeese = FALSE
	var/squeese_target

	if(windoor && windoor.density)
		should_squeese = TRUE
		squeese_target = windoor
		if(windoor.powered())
			can_squeese = FALSE

	if(firedoor && firedoor.density)
		squeese_target = firedoor
		should_squeese = TRUE

	if(airlock && airlock.density)
		should_squeese = TRUE
		squeese_target = airlock
		if(airlock.locked)
			can_squeese = FALSE

	var/turf/squeese_turf = get_step(get_turf(step_target), get_dir(src, step_target))
	if(squeese_turf.is_blocked_turf_ignore_climbable())
		can_squeese = FALSE

	if(can_squeese && should_squeese)
		visible_message(span_warning("[src] squeeses through [squeese_target]!"))
		forceMove(squeese_turf)
	else
		step_to(src, step_target)

	*/

/mob/living/simple_animal/slime/handle_environment(datum/gas_mixture/environment, delta_time, times_fired)
	var/loc_temp = get_temperature(environment)
	var/divisor = 10 /// The divisor controls how fast body temperature changes, lower causes faster changes

	var/temp_delta = loc_temp - bodytemperature
	if(abs(temp_delta) > 50) // If the difference is great, reduce the divisor for faster stabilization
		divisor = 5

	if(temp_delta < 0) // It is cold here
		if(!on_fire) // Do not reduce body temp when on fire
			adjust_bodytemperature(clamp((temp_delta / divisor) * delta_time, temp_delta, 0))
	else // This is a hot place
		adjust_bodytemperature(clamp((temp_delta / divisor) * delta_time, 0, temp_delta))

	if(bodytemperature < (slime_color.temperature_modifier + 5)) // start calculating temperature damage etc
		if(bodytemperature <= (slime_color.temperature_modifier - 40)) // stun temperature
			ADD_TRAIT(src, TRAIT_IMMOBILIZED, SLIME_COLD)
		else
			REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, SLIME_COLD)

		if(bodytemperature <= (slime_color.temperature_modifier - 50)) // hurt temperature
			if(bodytemperature <= 50) // sqrting negative numbers is bad
				adjustBruteLoss(100 * delta_time)
			else
				adjustBruteLoss(round(sqrt(bodytemperature)) * delta_time)
	else
		REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, SLIME_COLD)

	if(stat != DEAD)
		var/bz_percentage =0
		if(environment.gases[/datum/gas/bz])
			bz_percentage = environment.gases[/datum/gas/bz][MOLES] / environment.total_moles()
		var/stasis = (bz_percentage >= 0.05 && bodytemperature < (slime_color.temperature_modifier + 100) && !(slime_color.slime_tags & SLIME_BZ_IMMUNE)) || force_stasis

		switch(stat)
			if(CONSCIOUS)
				if(stasis)
					to_chat(src, span_danger("Nerve gas in the air has put you in stasis!"))
					set_stat(UNCONSCIOUS)
					powerlevel = 0
					rabid = FALSE
					set_target(null)
					regenerate_icons()
			if(UNCONSCIOUS, HARD_CRIT)
				if(!stasis)
					to_chat(src, span_notice("You wake up from the stasis."))
					set_stat(CONSCIOUS)
					regenerate_icons()

	updatehealth()


/mob/living/simple_animal/slime/handle_status_effects(delta_time, times_fired)
	..()
	if(!stat && DT_PROB(16, delta_time))
		adjustBruteLoss(-0.5 * delta_time)

/mob/living/simple_animal/slime/proc/handle_feeding(delta_time, times_fired)
	if(!ismob(buckled))
		return
	var/mob/M = buckled

	if(layer < M.layer) //Because mobs change their layers when standing up/lying down
		layer = M.layer + 0.01 //appear above the target mob

	if(stat)
		Feedstop(silent = TRUE)

	if(M.stat == DEAD) // our victim died
		if(!client)
			if(!rabid && !attacked)
				var/mob/last_to_hurt = M.LAssailant?.resolve()
				if(last_to_hurt && last_to_hurt != M)
					if(DT_PROB(30, delta_time))
						add_friendship(last_to_hurt, 1)
		else
			to_chat(src, "<i>This subject does not have a strong enough life energy anymore...</i>")

		if(M.client && ishuman(M))
			if(DT_PROB(61, delta_time))
				rabid = 1 //we go rabid after finishing to feed on a human with a client.

		Feedstop()
		return

	var/food_multiplier = 1

	if(iscarbon(M))
		var/mob/living/carbon/C = M
		var/damage_mod = max(1 - (C.getarmor(type = BIO) * 0.25 * 0.01 + HAS_TRAIT(C, TRAIT_SLIME_RESISTANCE) * 0.25), 0.50)
		C.adjustCloneLoss(rand(2, 4) * damage_mod * delta_time) //Biosuits reduce damage
		C.adjustToxLoss(rand(1, 2) * damage_mod * delta_time)
		food_multiplier *= damage_mod

		if(DT_PROB(5, delta_time) && C.client)
			to_chat(C, "<span class='userdanger'>[pick("You can feel your body becoming weak!", \
			"You feel like you're about to die!", \
			"You feel every part of your body screaming in agony!", \
			"A low, rolling pain passes through your body!", \
			"Your body feels as if it's falling apart!", \
			"You feel extremely weak!", \
			"A sharp, deep pain bathes every inch of your body!")]</span>")

		if(ishuman(C))
			var/mob/living/carbon/human/human_victim = C
			if(human_victim.dna)
				var/food_type
				for(var/food in slime_color.food_types)
					if(istype(human_victim.dna.species, food))
						food_type = food
						break

				if(food_type)
					food_multiplier *= slime_color.food_types[food_type]

	else if(isanimal(M))
		var/mob/living/simple_animal/SA = M
		var/damage_mod = max(1 - (SA.damage_coeff[CLONE] * 0.25 + HAS_TRAIT(SA, TRAIT_SLIME_RESISTANCE) * 0.25), 0.50)
		food_multiplier *= damage_mod

		var/food_type
		for(var/food in slime_color.food_types)
			if(istype(M, food))
				food_type = food
				break

		if(food_type)
			food_multiplier *= slime_color.food_types[food_type]

		var/totaldamage = 0 //total damage done to this unfortunate animal
		totaldamage += SA.adjustCloneLoss(rand(2, 4) * damage_mod * 0.75 * delta_time)
		totaldamage += SA.adjustToxLoss(rand(1, 2) * damage_mod * 0.75 * delta_time)

		if(totaldamage <= 0) //if we did no(or negative!) damage to it, stop
			Feedstop(0, 0)
			return

	else
		Feedstop(0, 0)
		return

	add_nutrition(rand(7, 15) * 0.5 * delta_time * CONFIG_GET(number/damage_multiplier)* food_multiplier)

	//Heal yourself.
	adjustBruteLoss(-1.5 * delta_time)

/mob/living/simple_animal/slime/proc/handle_nutrition(delta_time, times_fired)

	if(docile) //God as my witness, I will never go hungry again
		set_nutrition(700) //fuck you for using the base nutrition var
		return

	if(cores < max_cores && !stat && nutrition >= get_grow_nutrition() && slime_color.fitting_environment)
		if(core_generation >= SLIME_MAX_CORE_GENERATION)
			cores += 1
			regenerate_icons()
			core_generation = 0
		else
			var/coregen_speed = 1
			if(mood_level > SLIME_MOOD_LEVEL_HAPPY)
				coregen_speed = 1.5
			else if(mood_level < SLIME_MOOD_LEVEL_POUT)
				coregen_speed = 0.5
			core_generation += coregen_speed * delta_time
			adjust_nutrition(-1 * (1 + is_adult) * delta_time)

	if(DT_PROB(65, delta_time)) //So about 1.3 nutrition per second for a child and 2.6 for adult, that's around 12.8 minutes of nutrition for a child and around 7.7 + 12.8 = 20.5 minutes for an adult
		adjust_nutrition(-2 * (1 + is_adult)) //Why the fuck was it multiplied by delta time second time, that's not how this shit is supposed to work

	if(nutrition <= 0)
		set_nutrition(0)
		if(DT_PROB(50, delta_time))
			adjustBruteLoss(rand(0,5))

	else if (nutrition >= get_grow_nutrition() && amount_grown < SLIME_EVOLUTION_THRESHOLD && cores >= max_cores)
		adjust_nutrition(-10 * delta_time)
		amount_grown++
		update_action_buttons_icon()

	if(amount_grown >= SLIME_EVOLUTION_THRESHOLD && cores >= max_cores && !buckled && !Target && !ckey)
		if(is_adult && loc.AllowDrop())
			Reproduce()
		else
			Evolve()

/mob/living/simple_animal/slime/proc/add_nutrition(nutrition_to_add = 0)
	set_nutrition(min((nutrition + nutrition_to_add), get_max_nutrition()))
	if(nutrition >= get_grow_nutrition())
		if(powerlevel<10)
			if(prob(30-powerlevel*2))
				powerlevel++
	else if(nutrition >= get_hunger_nutrition() + 100) //can't get power levels unless you're a bit above hunger level.
		if(powerlevel<5)
			if(prob(25-powerlevel*5))
				powerlevel++




/mob/living/simple_animal/slime/proc/handle_targets(delta_time, times_fired)
	if(attacked > 50)
		attacked = 50

	if(attacked > 0)
		attacked--

	if(Discipline > 0)

		if(Discipline >= 5 && rabid)
			if(DT_PROB(37, delta_time))
				rabid = 0

		if(DT_PROB(5, delta_time))
			Discipline--

	if(!client)
		if(!(mobility_flags & MOBILITY_MOVE))
			stop_moveloop()
			return

		if(buckled)
			stop_moveloop()
			return // if it's eating someone already, continue eating!

		if(Target)
			--target_patience
			if (target_patience <= 0 || IsStun() || Discipline || attacked || docile) // Tired of chasing or something draws out attention
				target_patience = 0
				set_target(null)

		if(AIproc && IsStun())
			stop_moveloop()
			return

		var/hungry = 0 // determines if the slime is hungry

		if (nutrition < get_starve_nutrition())
			hungry = 2
		else if (nutrition < get_grow_nutrition() && DT_PROB((mood_level < SLIME_MOOD_LEVEL_POUT ? 25 : 13), delta_time) || nutrition < get_hunger_nutrition())
			hungry = 1

		if(!Target)
			if(will_hunt() && hungry || attacked || rabid) // Only add to the list if we need to
				var/list/targets = list()

				for(var/mob/living/L in view(7,src))
					if(L == src)
						continue

					if(isslime(L) && !(slime_color.slime_tags & SLIME_ATTACK_SLIMES)) // Don't attack other slimes unless your color allows it
						continue

					if(L.stat == DEAD) // Ignore dead mobs
						continue

					if(L in Friends) // No eating friends!
						continue

					var/ally = FALSE
					for(var/F in faction)
						if(F == "neutral") //slimes are neutral so other mobs not target them, but they can target neutral mobs
							continue
						if(F == "slime" && (slime_color.slime_tags & SLIME_ATTACK_SLIMES)) //Allows slimes with attack_slimes tag to attack other slimes
							continue
						if(F in L.faction)
							ally = TRUE
							break
					if(ally)
						continue

					if(issilicon(L) && (rabid || attacked)) // They can't eat silicons, but they can glomp them in defence
						targets += L // Possible target found!
						continue

					if(locate(/mob/living/simple_animal/slime) in L.buckled_mobs) // Only one slime can latch on at a time.
						continue

					targets += L // Possible target found!

				for(var/obj/possible_food in view(7,src))
					if(CanFeedon(possible_food, TRUE, slimeignore = (slime_color.slime_tags & SLIME_ATTACK_SLIMES), distignore = TRUE))
						targets += possible_food

				if(targets.len > 0)
					if(attacked || rabid)
						set_target(targets[1]) // I am attacked and am fighting back or so hungry
					else if(hungry == 2)
						for(var/possible_target in targets)
							if(CanFeedon(possible_target, TRUE, slimeignore = (slime_color.slime_tags & SLIME_ATTACK_SLIMES), distignore = TRUE))
								set_target(possible_target)
								break
					else
						for(var/mob/living/possible_target in targets)
							if(!istype(possible_target) || !CanFeedon(possible_target, TRUE, slimeignore = TRUE, distignore = TRUE))
								continue

							if(!Discipline && DT_PROB((mood_level < SLIME_MOOD_LEVEL_POUT ? 7.5 : 2.5), delta_time))
								if(ishuman(possible_target) || isalienadult(possible_target))
									set_target(possible_target)
									break

							if(islarva(possible_target) || ismonkey(possible_target) || (isslime(possible_target) && (slime_color.slime_tags & SLIME_ATTACK_SLIMES)))
								set_target(possible_target)
								break

						if(!Target)
							var/nearest_food
							var/food_dist = -1
							for(var/obj/possible_food in targets)
								if(get_dist(src, possible_food) < food_dist || food_dist == -1)
									food_dist = get_dist(src, possible_food)
									nearest_food = possible_food

							if(nearest_food)
								set_target(nearest_food)

			if (Target)
				target_patience = rand(5, 7)
				if (is_adult)
					target_patience += 3

		if(!Target) // If we have no target, we are wandering or following orders
			if (Leader)
				if(holding_still)
					holding_still = max(holding_still - (0.5 * delta_time), 0)
				else if(!HAS_TRAIT(src, TRAIT_IMMOBILIZED) && isturf(loc))
					start_moveloop(Leader)

			else if(hungry)
				if (holding_still)
					holding_still = max(holding_still - (0.5 * hungry * delta_time), 0)
				else if(!HAS_TRAIT(src, TRAIT_IMMOBILIZED) && isturf(loc) && DT_PROB(50, delta_time))
					var/picked_dir = pick(GLOB.alldirs)
					Move(get_step(src, picked_dir), picked_dir)

			else
				handle_boredom(delta_time, times_fired)

	if(Target && !AIproc)
		INVOKE_ASYNC(src, .proc/AIprocess)

/mob/living/simple_animal/slime/handle_automated_movement()
	return //slime random movement is currently handled in handle_targets()

/mob/living/simple_animal/slime/handle_automated_speech()
	return //slime random speech is currently handled in handle_speech()

/mob/living/simple_animal/slime/proc/handle_boredom(delta_time, times_fired)
	if(holding_still)
		holding_still = max(holding_still - (0.5 * delta_time), 0)
		return
	else if (docile && pulledby)
		holding_still = 10
		return

	if(HAS_TRAIT(src, TRAIT_IMMOBILIZED) || !isturf(loc))
		return

	if(!DT_PROB(SLIME_POI_INTERACT_CHANCE, delta_time))
		if(DT_PROB(25, delta_time))
			var/picked_dir = pick(GLOB.alldirs)
			Move(get_step(src, picked_dir), picked_dir)
		return

	var/list/points_of_interest = list()
	for(var/obj/possible_interest in view(5, get_turf(src)))
		if(istype(possible_interest, /obj/item/giant_slime_plushie))
			if(mood_level < SLIME_MOOD_LEVEL_HAPPY && DT_PROB((SLIME_MOOD_LEVEL_HAPPY - mood_level) / 3.75 + 15, delta_time))
				points_of_interest += possible_interest

	if(!LAZYLEN(points_of_interest))
		return

	set_target(pick(points_of_interest))

/mob/living/simple_animal/slime/proc/handle_mood(delta_time, times_fired)
	if(mood_level < 0)
		mood_level = 0
	else if(mood_level > SLIME_MOOD_MAXIMUM)
		mood_level = SLIME_MOOD_MAXIMUM

	var/newmood = ""
	if (rabid || attacked)
		newmood = "angry"
	else if(mood_level > SLIME_MOOD_LEVEL_HAPPY)
		newmood = pick(":3", ":33")
	else if(mood_level < SLIME_MOOD_LEVEL_POUT)
		newmood = "pout"
	else if(mood_level < SLIME_MOOD_LEVEL_SAD)
		newmood = "sad"
	else if (docile)
		newmood = pick(":3", ":33")
	else if (Target)
		newmood = "mischievous"

	if (!newmood)
		if (Discipline && DT_PROB(13, delta_time))
			newmood = "pout"
		else if (DT_PROB(0.5, delta_time))
			newmood = pick("sad", ":3", ":33", "pout")

	if ((mood == "sad" || mood == ":3" || mood == "pout") && !newmood)
		if(DT_PROB(50, delta_time))
			newmood = mood

	if (newmood != mood) // This is so we don't redraw them every time
		mood = newmood
		regenerate_icons()

	if(!slime_color.fitting_environment && !(slime_color.slime_tags & SLIME_NO_REQUIREMENT_MOOD_LOSS))
		mood_level -= SLIME_MOOD_REQUIREMENTS_LOSS * delta_time
	else if(nutrition < get_starve_nutrition())
		mood_level -= SLIME_MOOD_STARVING_LOSS * delta_time
	else if(nutrition < get_hunger_nutrition())
		mood_level -= SLIME_MOOD_HUNGRY_LOSS * delta_time
	else if(mood_level < SLIME_MOOD_PASSIVE_LEVEL + rand(-SLIME_MOOD_PASSIVE_LEVEL_OFFSET, SLIME_MOOD_PASSIVE_LEVEL_OFFSET))
		mood_level += SLIME_MOOD_PASSIVE_GAIN * delta_time

	if(mood_level < SLIME_MOOD_LEVEL_POUT)
		if(Discipline && DT_PROB(2, delta_time)) //Faster discipline loss
			Discipline -= 1

	if(mood_level < SLIME_MOOD_LEVEL_SAD)
		if(Friends.len > 0 && DT_PROB(3, delta_time)) //Lose friends when sad
			var/mob/nofriend = pick(Friends)
			add_friendship(nofriend, -1)
		if(!rabid && !docile && DT_PROB(0.05, delta_time)) //Very low chance to become rabid when sad
			rabid = TRUE

/mob/living/simple_animal/slime/proc/handle_speech(delta_time, times_fired)
	//Speech understanding starts here
	var/to_say
	if (speech_buffer.len > 0)
		var/who = speech_buffer[1] // Who said it?
		var/phrase = speech_buffer[2] // What did they say?
		if ((findtext(phrase, num2text(number)) || findtext(phrase, "slimes"))) // Talking to us
			if (findtext(phrase, "hello") || findtext(phrase, "hi"))
				to_say = pick("Hello...", "Hi...")
			else if (findtext(phrase, "follow"))
				if (Leader)
					if (Leader == who) // Already following him
						to_say = pick("Yes...", "Lead...", "Follow...")
					else if (Friends[who] > Friends[Leader]) // VIVA
						set_leader(who)
						to_say = "Yes... I follow [who]..."
					else
						to_say = "No... I follow [Leader]..."
				else
					if (Friends[who] >= SLIME_FRIENDSHIP_FOLLOW)
						set_leader(who)
						to_say = "I follow..."
					else // Not friendly enough
						to_say = pick("No...", "I no follow...")
			else if (findtext(phrase, "stop"))
				if (buckled) // We are asked to stop feeding
					if (Friends[who] >= SLIME_FRIENDSHIP_STOPEAT)
						Feedstop()
						set_target(null)
						if (Friends[who] < SLIME_FRIENDSHIP_STOPEAT_NOANGRY)
							add_friendship(who, -1)
							to_say = "Grrr..." // I'm angry but I do it
						else
							to_say = "Fine..."
				else if (Target) // We are asked to stop chasing
					if (Friends[who] >= SLIME_FRIENDSHIP_STOPCHASE)
						set_target(null)
						if (Friends[who] < SLIME_FRIENDSHIP_STOPCHASE_NOANGRY)
							add_friendship(who, -1)
							to_say = "Grrr..." // I'm angry but I do it
						else
							to_say = "Fine..."
				else if (Leader) // We are asked to stop following
					if (Leader == who)
						to_say = "Yes... I stay..."
						set_leader(null)
					else
						if (Friends[who] > Friends[Leader])
							set_leader(null)
							to_say = "Yes... I stop..."
						else
							to_say = "No... keep follow..."
			else if (findtext(phrase, "stay"))
				if (Leader)
					if (Leader == who)
						holding_still = Friends[who] * 10
						to_say = "Yes... stay..."
					else if (Friends[who] > Friends[Leader])
						holding_still = (Friends[who] - Friends[Leader]) * 10
						to_say = "Yes... stay..."
					else
						to_say = "No... keep follow..."
				else
					if (Friends[who] >= SLIME_FRIENDSHIP_STAY)
						holding_still = Friends[who] * 10
						to_say = "Yes... stay..."
					else
						to_say = "No... won't stay..."
			else if (findtext(phrase, "attack"))
				if (rabid && prob(20))
					set_target(who)
					AIprocess() //Wake up the slime's Target AI, needed otherwise this doesn't work
					to_say = "ATTACK!?!?"
				else if (Friends[who] >= SLIME_FRIENDSHIP_ATTACK)
					for (var/mob/living/L in view(7,src)-list(src,who))
						if (findtext(phrase, lowertext(L.name)))
							if (isslime(L))
								to_say = "NO... [L] slime friend"
								add_friendship(who, -1) //Don't ask a slime to attack its friend
							else if(!Friends[L] || Friends[L] < 1)
								set_target(L)
								AIprocess()//Wake up the slime's Target AI, needed otherwise this doesn't work
								if(isliving(Target))
									to_say = "Ok... I attack [Target]"
								else
									to_say = "Ok... I eat [Target]"
							else
								to_say = "No... like [L] ..."
								add_friendship(who, -1) //Don't ask a slime to attack its friend
							break
				else
					to_say = "No... no listen"

		speech_buffer = list()

	//Speech starts here
	if (to_say)
		say (to_say)
	else if(DT_PROB(0.5, delta_time))
		emote(pick("bounce","sway","light","vibrate","jiggle"))
	else
		var/t = 10
		var/slimes_near = 0
		var/dead_slimes = 0
		var/friends_near = list()
		for (var/mob/living/L in view(7,src))
			if(isslime(L) && L != src)
				++slimes_near
				if (L.stat == DEAD)
					++dead_slimes
			if (L in Friends)
				t += 20
				friends_near += L
		if (nutrition < get_hunger_nutrition())
			t += 10
		if (nutrition < get_starve_nutrition())
			t += 10
		if (DT_PROB(1, delta_time) && prob(t))
			var/phrases = list()
			if (Target)
				phrases += "[Target]... look yummy..."
			if (nutrition < get_starve_nutrition())
				phrases += "So... hungry..."
				phrases += "Very... hungry..."
				phrases += "Need... food..."
				phrases += "Must... eat..."
			else if (nutrition < get_hunger_nutrition())
				phrases += "Hungry..."
				phrases += "Where food?"
				phrases += "I want to eat..."
			phrases += "Rawr..."
			phrases += "Blop..."
			phrases += "Blorble..."
			if (rabid || attacked)
				phrases += "Hrr..."
				phrases += "Nhuu..."
				phrases += "Unn..."
			if (mood == ":3")
				phrases += "Purr..."
			if (attacked)
				phrases += "Grrr..."
			if (bodytemperature < slime_color.temperature_modifier)
				phrases += "Cold..."
			if (bodytemperature < slime_color.temperature_modifier - 30)
				phrases += "So... cold..."
				phrases += "Very... cold..."
			if (bodytemperature < slime_color.temperature_modifier - 50)
				phrases += "..."
				phrases += "C... c..."
			if (buckled || Digesting)
				phrases += "Nom..."
				phrases += "Yummy..."
			if (powerlevel > 3)
				phrases += "Bzzz..."
			if (powerlevel > 5)
				phrases += "Zap..."
			if (powerlevel > 8)
				phrases += "Zap... Bzz..."
			if (mood == "sad")
				phrases += "Bored..."
			if (slimes_near)
				phrases += "Slime friend..."
			if (slimes_near > 1)
				phrases += "Slime friends..."
			if (dead_slimes)
				phrases += "What happened?"
			if (!slimes_near)
				phrases += "Lonely..."
			for (var/M in friends_near)
				phrases += "[M]... friend..."
				if (nutrition < get_hunger_nutrition())
					phrases += "[M]... feed me..."
			if(!stat)
				say (pick(phrases))

/mob/living/simple_animal/slime/proc/handle_digestion(delta_time, times_fired)
	if(!Digesting)
		return

	var/food
	for(var/food_type in slime_color.food_types)
		if(istype(Digesting, food_type))
			food = food_type
			break

	digestion_progress += delta_time * SLIME_DIGESTION_SPEED * slime_color.food_types[food]
	adjust_nutrition(SLIME_DIGESTION_NUTRITION * delta_time)

	if(digestion_progress >= 100)
		cut_overlay(digestion_overlay)
		to_chat(src, span_notice("<i>You finish digesting [Digesting].</i>"))
		slime_color.finished_digesting(Digesting)
		QDEL_NULL(digestion_overlay)
		QDEL_NULL(Digesting)
		return

	if(0.7 * (100 - digestion_progress) / 100 < next_overlay_scale) //Not so smooth but it won't cause lag
		cut_overlay(digestion_overlay)
		digestion_overlay.transform = matrix().Scale(0.7 * (100 - digestion_progress) / 100)
		add_overlay(digestion_overlay)
		next_overlay_scale -= 0.1

/mob/living/simple_animal/slime/proc/get_max_nutrition() // Can't go above it
	if (is_adult)
		return 1200
	else
		return 1000

/mob/living/simple_animal/slime/proc/get_grow_nutrition() // Above it we grow, below it we can eat
	if (is_adult)
		return 1000
	else
		return 800

/mob/living/simple_animal/slime/proc/get_hunger_nutrition() // Below it we will always eat
	if (is_adult)
		return nutrition_control ? 600 : (get_max_nutrition() + 1)
	else
		return nutrition_control ? 500 : (get_max_nutrition() + 1)

/mob/living/simple_animal/slime/proc/get_starve_nutrition() // Below it we will eat before everything else
	if(is_adult)
		return 300
	else
		return 200

/mob/living/simple_animal/slime/proc/will_hunt(hunger = -1) // Check for being stopped from feeding and chasing
	if (docile)
		return FALSE
	if (hunger == 2 || rabid || attacked)
		return TRUE
	if (Leader)
		return FALSE
	if (holding_still)
		return FALSE
	return TRUE
