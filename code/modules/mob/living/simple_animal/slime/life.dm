/mob/living/simple_animal/slime/Life(delta_time = SSMOBS_DT, times_fired)
	if (notransform)
		return
	. = ..()
	if(!.)
		return

	if(!slime_color) //If we SOMEHOW lost our color, be it BYOND wizardry, shitcode or adminbus, we become error slimes because it's extremely important to have one
		set_color(/datum/slime_color)

	if(stat) // Slimes in stasis don't lose nutrition, don't change mood and don't respond to speech
		return
	handle_feeding(delta_time, times_fired)
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
	if(health > 0 && (stat == UNCONSCIOUS || stat == HARD_CRIT))
		return
	return ..()

/mob/living/simple_animal/slime/proc/kickstart_ai()
	if(ai_active || stat || client)
		return

	if(nutrition < get_grow_nutrition() && prob(25))
		will_to_grow = TRUE

	ai_active = TRUE
	START_PROCESSING(SSfastprocess, src)

/mob/living/simple_animal/slime/proc/stop_ai()
	if(!ai_active)
		return

	ai_active = FALSE
	will_to_grow = FALSE
	STOP_PROCESSING(SSfastprocess, src)

/mob/living/simple_animal/slime/process(delta_time, times_fired)
	var/hungry = 0
	if(nutrition < get_starve_nutrition())
		hungry = 2
	else if(nutrition < get_hunger_nutrition())
		hungry = 1

	if(!ai_active || stat || !(attacked || hungry || HAS_TRAIT(src, TRAIT_SLIME_RABID) || buckled || target || will_to_grow) || docile)
		stop_ai()
		return

	if(!(mobility_flags & MOBILITY_MOVE) && !(SEND_SIGNAL(src, COMSIG_SLIME_BUCKLED_AI) & COMPONENT_SLIME_ALLOW_BUCKLED_AI)) //also covers buckling. Not sure why buckled is in the while condition if we're going to immediately break, honestly
		if(buckled && !isliving(buckled))
			buckled.unbuckle_mob(src, force = TRUE)
			return

		stop_moveloop()
		stop_ai()
		return

	if(!target || client)
		stop_moveloop()
		stop_ai()
		return

	if(isliving(target))
		var/mob/living/victim = target
		if(victim.health <= -70 || victim.stat == DEAD)
			set_target(null)
			stop_ai()
			return

	if(locate(/mob/living/simple_animal/slime) in target.buckled_mobs)
		set_target(null)
		stop_ai()
		return

	if(!target.Adjacent(src))
		if(get_dist(target, src) > 9 && target_patience < 0)
			set_target(null)
			stop_ai()
			return

		if(is_in_sight(src, target) && COOLDOWN_FINISHED(src, attack_cd))
			SEND_SIGNAL(src, COMSIG_SLIME_ATTEMPT_RANGED_ATTACK, target)
		start_moveloop(target)
		return

	if(!can_feed_on(target))
		if(COOLDOWN_FINISHED(src, attack_cd))
			COOLDOWN_START(src, attack_cd, slime_color.get_attack_cd(target))
			attack_target(target)
		return

	if(!isliving(target))
		gobble_up(target)
		return

	if(!COOLDOWN_FINISHED(src, attack_cd))
		return

	var/mob/living/victim = target
	if(!victim.client || victim.health < 0 || victim.body_position == LYING_DOWN || prob(20))
		feed_on(victim)
		COOLDOWN_START(src, attack_cd, slime_color.get_attack_cd(target))
		return

	COOLDOWN_START(src, attack_cd, slime_color.get_attack_cd(target))
	attack_target(victim)

/mob/living/simple_animal/slime/proc/attack_target(atom/attack_target)
	if(SEND_SIGNAL(src, COMSIG_SLIME_ATTACK_TARGET, attack_target) & COMPONENT_SLIME_NO_ATTACK)
		return

	if(!client)
		if(istype(attack_target, /obj/machinery/atmospherics/components/unary/vent_pump))
			var/obj/machinery/atmospherics/components/unary/vent_pump/vent = attack_target
			if(!vent.welded)
				amogus_style(vent)
				return

		if(istype(attack_target, /obj/machinery/atmospherics/components/unary/vent_scrubber))
			var/obj/machinery/atmospherics/components/unary/vent_scrubber/scrubber = attack_target
			if(!scrubber.welded)
				amogus_style(scrubber)
				return

	attack_target.attack_slime(src)

/mob/living/simple_animal/slime/proc/amogus_style(obj/machinery/atmospherics/components/unary/enter_vent)
	var/datum/pipeline/vent_pipeline = enter_vent.parents[1]
	var/list/possible_exists = list()
	for(var/obj/machinery/atmospherics/components/unary/vent_pump/vent in vent_pipeline.other_atmos_machines)
		if(vent.welded)
			continue

		var/target_amount = 0
		for(var/mob/living/possible_target in view(5, vent))
			target_amount += (possible_target.client ? 3 : 1) //Three times as valuable if the mob has a client

		possible_exists[vent] = target_amount

	for(var/obj/machinery/atmospherics/components/unary/vent_scrubber/scrubber in vent_pipeline.other_atmos_machines)
		if(scrubber.welded)
			continue

		var/target_amount = 0
		for(var/mob/living/possible_target in view(5, scrubber))
			target_amount += (possible_target.client ? 3 : 1)

		possible_exists[scrubber] = target_amount

	var/obj/machinery/atmospherics/components/unary/target_vent = pick_weight(possible_exists)
	visible_message(span_warning("[src] slips into [enter_vent]!"), span_notice("You slip into [enter_vent] and start moving towards [get_area(target_vent)]."))
	forceMove(get_turf(target_vent))
	visible_message(span_warning("[src] emerges from [target_vent]!"))

/mob/living/simple_animal/slime/proc/start_moveloop(atom/move_target)
	if(SEND_SIGNAL(src, COMSIG_SLIME_START_MOVE_LOOP, move_target) & COMPONENT_SLIME_NO_MOVE_LOOP_START)
		return

	if(move_target == current_loop_target)
		return

	var/sleeptime = cached_multiplicative_slowdown
	if(sleeptime <= 0)
		sleeptime = 0

	stop_moveloop()
	current_loop_target = move_target

	move_loop = SSmove_manager.mixed_move(src,
										  current_loop_target,
										  sleeptime,
										  repath_delay = 0.5 SECONDS,
										  max_path_length = AI_MAX_PATH_LENGTH,
										  minimum_distance = 1,
										  )
	RegisterSignal(move_loop, COMSIG_PARENT_QDELETING, .proc/loop_ended)
	RegisterSignal(move_loop, COMSIG_MOVELOOP_POSTPROCESS, .proc/post_move)

/mob/living/simple_animal/slime/proc/loop_ended()
	current_loop_target = null
	move_loop = null

/mob/living/simple_animal/slime/proc/post_move(datum/source, success, visual_delay)
	if(success)
		return

	if(get_step_to(src, current_loop_target))
		return

	var/datum/move_loop/has_target/jps/mixed/mixed_loop = source
	mixed_loop.recalculate_path()
	if(LAZYLEN(mixed_loop.movement_path))
		return

	for(var/path_dir in GLOB.cardinals)
		if(SEND_SIGNAL(src, COMSIG_SLIME_SQUEESING_ATTEMPT, path_dir, source, FALSE) & COMPONENT_SLIME_NO_SQUEESING)
			return

		if(try_squeesing(source, path_dir))
			return

/mob/living/simple_animal/slime/Bump(atom/bumped_into)
	. = ..()
	if(!move_loop)
		return

	if(SEND_SIGNAL(src, COMSIG_SLIME_SQUEESING_ATTEMPT, get_dir(src, bumped_into), move_loop, TRUE) & COMPONENT_SLIME_NO_SQUEESING)
		return

	if(try_squeesing(move_loop, get_dir(src, bumped_into)))
		return

/mob/living/simple_animal/slime/proc/try_squeesing(datum/source, squeese_dir)
	var/our_turf = get_turf(src)
	var/squeese_turf = get_step(our_turf, squeese_dir)

	forceMove(squeese_turf)
	if(!get_step_to(src, current_loop_target) || get_step_to(src, current_loop_target) == our_turf)
		forceMove(our_turf)
		return FALSE

	var/datum/move_loop/has_target/jps/mixed/mixed_loop = source
	mixed_loop.recalculate_path()
	if(!LAZYLEN(mixed_loop.movement_path))
		forceMove(our_turf)
		return FALSE

	forceMove(our_turf)

	var/atom/squeese_through
	var/atom/squeese_airlock

	for(var/atom/possible_directional in our_turf)
		if(possible_directional.dir != squeese_dir)
			continue

		if(istype(possible_directional, /obj/structure/window))
			var/obj/structure/window/window = possible_directional
			if(!window.fulltile && window.density)
				return FALSE

		else if(istype(possible_directional, /obj/structure/railing))
			squeese_through = possible_directional

		else if(istype(possible_directional, /obj/machinery/door/window))
			var/obj/machinery/door/window/windoor = possible_directional
			if(windoor.powered())
				return FALSE
			squeese_through = possible_directional

		else if(istype(possible_directional, /obj/machinery/door/firedoor/border_only))
			var/obj/machinery/door/firedoor/border_only/firelock = possible_directional
			if(firelock.welded)
				return FALSE
			squeese_through = possible_directional

	for(var/atom/squeesie in squeese_turf)
		if(istype(squeesie, /obj/machinery/door/airlock))
			var/obj/machinery/door/airlock/airlock = squeesie
			if(airlock.locked || airlock.welded)
				return FALSE
			squeese_airlock = airlock

		else if(istype(squeesie, /obj/machinery/door/firedoor/border_only))
			var/obj/machinery/door/firedoor/border_only/firelock = squeesie
			if(squeesie.dir == get_dir(squeese_turf, our_turf))
				if(firelock.welded)
					return FALSE
				squeese_through = squeesie

		else if(istype(squeesie, /obj/machinery/door/firedoor))
			var/obj/machinery/door/firedoor/firelock = squeesie
			if(firelock.welded)
				return FALSE
			squeese_airlock = firelock

		else if(istype(squeesie, /obj/structure/railing))
			if(squeesie.dir == get_dir(squeese_turf, our_turf))
				squeese_through = squeesie

		else if(istype(squeesie, /obj/machinery/door/window))
			var/obj/machinery/door/window/windoor = squeesie
			if(windoor.dir != get_dir(squeese_turf, our_turf))
				continue

			if(windoor.powered())
				return FALSE

			squeese_through = squeesie

		else if(istype(squeesie, /obj/structure/window))
			var/obj/structure/window/window = squeesie
			if(!window.fulltile)
				if(window.dir == get_dir(squeese_turf, our_turf) && window.density)
					return FALSE
			else if(window.density)
				return FALSE

		else if(!squeesie.CanPass(src, get_dir(squeese_turf, our_turf)))
			return FALSE

	if(squeese_airlock)
		for(var/atom/squeesie in squeese_turf)
			if(istype(squeesie, /obj/machinery/door/airlock) || istype(squeesie, /obj/machinery/door/firedoor) || istype(squeesie, /obj/structure/railing))
				continue

			if(istype(squeesie, /obj/machinery/door/window))
				var/obj/machinery/door/window/windoor = squeesie
				if(windoor.powered() && windoor.dir == squeese_dir)
					return FALSE

			else if(istype(squeesie, /obj/structure/window))
				var/obj/structure/window/window = squeesie
				if(!window.fulltile)
					if(window.dir == squeese_dir && window.density)
						return FALSE
				else if(window.density)
					return FALSE
			else if(!squeesie.CanPass(src, get_dir(squeese_turf, our_turf)))
				return FALSE

		var/turf/squeese_to = get_step(squeese_turf, squeese_dir)

		for(var/atom/squeesie in squeese_to)
			if(istype(squeesie, /obj/machinery/door/firedoor/border_only))
				var/obj/machinery/door/firedoor/border_only/firelock = squeesie
				if(firelock.dir == get_dir(squeese_to, squeese_turf) && firelock.welded)
					return FALSE

			else if(istype(squeesie, /obj/structure/railing))
				continue

			else if(istype(squeesie, /obj/machinery/door/window))
				var/obj/machinery/door/window/windoor = squeesie
				if(windoor.powered() && windoor.dir == get_dir(squeese_to, squeese_turf))
					return FALSE

			else if(istype(squeesie, /obj/structure/window))
				var/obj/structure/window/window = squeesie
				if(!window.fulltile)
					if(window.dir == get_dir(squeese_to, squeese_turf) && window.density)
						return FALSE
				else if(window.density)
					return FALSE

			else if(!squeesie.CanPass(src, squeese_dir))
				return FALSE

		visible_message(span_warning("[src] squeeses through [squeese_airlock]!"), span_notice("You squeese through [squeese_airlock]."))
		Move(squeese_to)
		return TRUE

	if(squeese_through)
		visible_message(span_warning("[src] squeeses through [squeese_through]!"), span_notice("You squeese through [squeese_through]."))
		Move(squeese_turf)
		return TRUE

	return FALSE

/mob/living/simple_animal/slime/proc/stop_moveloop()
	if(!current_loop_target)
		return
	if(SEND_SIGNAL(src, COMSIG_SLIME_STOP_MOVE_LOOP) & COMPONENT_SLIME_NO_MOVE_LOOP_STOP)
		return
	SSmove_manager.stop_looping(src)
	current_loop_target = null

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

	if(bodytemperature < slime_color.temperature_modifier)
		apply_moodlet(/datum/slime_moodlet/cold)
	else
		remove_moodlet(/datum/slime_moodlet/cold)

	if(bodytemperature <= (slime_color.temperature_modifier - 40)) // stun temperature
		ADD_TRAIT(src, TRAIT_IMMOBILIZED, SLIME_COLD)
		apply_moodlet(/datum/slime_moodlet/very_cold)
		if(bodytemperature <= (slime_color.temperature_modifier - 50)) // hurt temperature
			apply_moodlet(/datum/slime_moodlet/freezing_cold)
			if(bodytemperature <= 50) // sqrting negative numbers is bad
				adjustBruteLoss(100 * delta_time)
			else
				adjustBruteLoss(round(sqrt(bodytemperature)) * delta_time)
		else
			remove_moodlet(/datum/slime_moodlet/freezing_cold)
	else
		REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, SLIME_COLD)
		remove_moodlet(/datum/slime_moodlet/very_cold)

	if(stat != DEAD)
		var/turf/current_turf = get_turf(src)
		var/slime_turf = FALSE
		if(istype(current_turf, /turf/closed/wall/slime) || istype(current_turf, /turf/open/misc/slime))
			adjustBruteLoss(SLIME_TURF_HEALING * delta_time)
			slime_turf = TRUE
			if(!docile)
				attacked = min(attacked + 2, 10) //Not rabid because I want it to decay

		var/bz_percentage =0
		if(environment.gases[/datum/gas/bz])
			bz_percentage = environment.gases[/datum/gas/bz][MOLES] / environment.total_moles()
		var/stasis = (bz_percentage >= 0.05 && bodytemperature < (slime_color.temperature_modifier + 100) && !(slime_color.slime_tags & SLIME_BZ_IMMUNE) && !slime_turf)
		if(stasis)
			ADD_TRAIT(src, TRAIT_SLIME_STASIS, "stasis_bz")

		switch(stat)
			if(CONSCIOUS)
				if(HAS_TRAIT(src, TRAIT_SLIME_STASIS))
					to_chat(src, span_danger("Nerve gas in the air has put you in stasis!"))
					set_stat(UNCONSCIOUS)
					powerlevel = 0
					REMOVE_TRAIT(src, TRAIT_SLIME_RABID, null)
					set_target(null)
					regenerate_icons()
					if(buckled && isliving(buckled))
						feed_stop(silent = TRUE)

			if(UNCONSCIOUS, HARD_CRIT)
				if(!HAS_TRAIT(src, TRAIT_SLIME_STASIS))
					to_chat(src, span_notice("You wake up from the stasis."))
					set_stat(CONSCIOUS)
					regenerate_icons()

	updatehealth()

/mob/living/simple_animal/slime/proc/handle_feeding(delta_time, times_fired)
	if(!buckled || !isliving(buckled))
		remove_moodlet(/datum/slime_moodlet/digesting)
		return

	var/mob/living/victim = buckled

	if(layer < victim.layer) //Because mobs change their layers when standing up/lying down
		layer = victim.layer + 0.01 //appear above the target mob

	if(stat)
		feed_stop(silent = TRUE)
		return

	if(amount_grown >= SLIME_EVOLUTION_THRESHOLD)
		feed_stop(silent = TRUE)
		return

	if(victim.stat == DEAD) // our victim died
		if(!client)
			if(!HAS_TRAIT(src, TRAIT_SLIME_RABID) && !attacked)
				var/mob/last_to_hurt = victim.LAssailant?.resolve()
				if(last_to_hurt && last_to_hurt != victim)
					if(prob(30))
						add_friendship(last_to_hurt, 1)
		else
			to_chat(src, span_warning("This subject does not have a strong enough life energy anymore..."))

		if(victim.client && ishuman(victim) && !docile)
			if(prob(60))
				ADD_TRAIT(src, TRAIT_SLIME_RABID, "feasted_on_player") //we go rabid after finishing to feed on a human with a client.

		SEND_SIGNAL(src, COMSIG_SLIME_DIGESTED, victim)
		feed_stop()
		return

	var/food_multiplier = 1

	if(iscarbon(victim))
		var/mob/living/carbon/carbon_victim = victim
		var/damage_mod = max(1 - (carbon_victim.getarmor(type = BIO) * 0.25 * 0.01 + HAS_TRAIT(carbon_victim, TRAIT_SLIME_RESISTANCE) * 0.25), 0.50) * slime_color.get_feed_damage_modifier()
		carbon_victim.adjustCloneLoss(rand(2, 4) * damage_mod * delta_time) //Biosuits reduce damage
		carbon_victim.adjustToxLoss(rand(1, 2) * damage_mod * delta_time, forced = TRUE)
		food_multiplier *= damage_mod

		if(DT_PROB(5, delta_time) && carbon_victim.client && damage_mod > 0)
			to_chat(carbon_victim, span_userdanger(pick("You can feel your body becoming weak!", \
			"You feel like you're about to die!", \
			"You feel every part of your body screaming in agony!", \
			"A low, rolling pain passes through your body!", \
			"Your body feels as if it's falling apart!", \
			"You feel extremely weak!", \
			"A sharp, deep pain bathes every inch of your body!")))

		if(ishuman(carbon_victim))
			var/mob/living/carbon/human/human_victim = carbon_victim
			if(human_victim.dna)
				var/food_type
				for(var/food in slime_color.food_types)
					if(istype(human_victim.dna.species, food))
						food_type = food
						break

				if(food_type)
					food_multiplier *= slime_color.food_types[food_type]

	else if(isanimal(victim))
		var/mob/living/simple_animal/animal_victim = victim
		var/damage_mod = max(1 - (animal_victim.damage_coeff[CLONE] * 0.25 + HAS_TRAIT(animal_victim, TRAIT_SLIME_RESISTANCE) * 0.25), 0.50) * slime_color.get_feed_damage_modifier()
		food_multiplier *= damage_mod

		var/food_type
		for(var/food in slime_color.food_types)
			if(istype(animal_victim, food))
				food_type = food
				break

		if(food_type)
			food_multiplier *= slime_color.food_types[food_type]

		var/totaldamage = 0 //total damage done to this unfortunate animal
		totaldamage += animal_victim.adjustCloneLoss(rand(2, 4) * damage_mod * delta_time)
		totaldamage += animal_victim.adjustToxLoss(rand(1, 2) * damage_mod * delta_time, forced = TRUE)

		if(totaldamage <= 0 && slime_color.get_feed_damage_modifier() > 0) //if we did no(or negative!) damage to it, stop
			feed_stop(0, 0)
			return

	else
		feed_stop(0, 0)
		return

	add_nutrition(rand(7, 15) * 0.5 * delta_time * CONFIG_GET(number/damage_multiplier) * food_multiplier)

	//Heal yourself.
	adjustBruteLoss(-1.5 * delta_time)
	apply_moodlet(/datum/slime_moodlet/digesting)

/mob/living/simple_animal/slime/proc/handle_nutrition(delta_time, times_fired)
	if(!stat && DT_PROB(16, delta_time))
		adjustBruteLoss(-0.5 * delta_time)

	if(docile) //God as my witness, I will never go hungry again
		set_nutrition(700) //fuck you for using the base nutrition var
		return

	if(cores < max_cores && !stat && nutrition >= get_hunger_nutrition() && slime_color.fitting_environment)
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

	if(amount_grown >= SLIME_EVOLUTION_THRESHOLD && cores >= max_cores && !(buckled && isliving(buckled)) && !target && !ckey)
		if(is_adult && loc.AllowDrop())
			reproduce()
		else
			grow_up()

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

/mob/living/simple_animal/slime/adjust_nutrition(change)
	. = ..()
	nutrition_hud_set_nutr()

/mob/living/simple_animal/slime/proc/handle_targets(delta_time, times_fired)
	if(attacked > 50)
		attacked = 50

	if(attacked > 0)
		attacked -= 1
	else if(LAZYLEN(recent_attackers))
		recent_attackers = list()

	if(discipline > 0)

		if(discipline >= 5 && HAS_TRAIT(src, TRAIT_SLIME_RABID))
			if(DT_PROB(37, delta_time))
				REMOVE_TRAIT(src, TRAIT_SLIME_RABID, null)

		if(DT_PROB(5, delta_time))
			discipline -= 1

	if(client)
		return

	if(!(mobility_flags & MOBILITY_MOVE) && !(SEND_SIGNAL(src, COMSIG_SLIME_BUCKLED_AI) & COMPONENT_SLIME_ALLOW_BUCKLED_AI))
		stop_moveloop()
		return

	if(buckled && !(SEND_SIGNAL(src, COMSIG_SLIME_BUCKLED_AI) & COMPONENT_SLIME_ALLOW_BUCKLED_AI))
		if(!isliving(buckled))
			buckled.unbuckle_mob(src, force = TRUE)
			return

		stop_moveloop()
		return // if it's eating someone already, continue eating!

	if(target)
		if(get_dist(src, target) > 1)
			target_patience -= 1

		if (target_patience <= 0 || IsStun() || discipline || attacked || docile) // Tired of chasing or something draws out attention
			REMOVE_TRAIT(src, TRAIT_SLIME_RABID, null)
			target_patience = 0
			set_target(null)

	if(ai_active && IsStun())
		stop_moveloop()
		return

	var/hungry = 0 // determines if the slime is hungry

	if (nutrition < get_starve_nutrition())
		hungry = 2
	else if (nutrition < get_grow_nutrition() && DT_PROB((mood_level < SLIME_MOOD_LEVEL_POUT ? 25 : 13), delta_time) || nutrition < get_hunger_nutrition())
		hungry = 1

	if(target)
		return

	if(will_hunt(hungry) && hungry || attacked || HAS_TRAIT(src, TRAIT_SLIME_RABID)) // Only add to the list if we need to
		var/list/targets = list()

		for(var/mob/living/possible_target in view(7,src))
			if(possible_target == src)
				continue

			if(isslime(possible_target) && !(possible_target in recent_attackers)) // Don't attack other slimes unless your color allows it or you have been attacked by it
				if(!(slime_color.slime_tags & SLIME_ATTACK_SLIMES))
					continue
				else if(!can_feed_on(possible_target))
					continue

			if(possible_target.stat == DEAD) // Ignore dead mobs
				continue

			if(possible_target in friends) // No eating friends!
				continue

			var/ally = FALSE
			for(var/our_faction in faction)
				if(our_faction == "neutral") //slimes are neutral so other mobs not target them, but they can target neutral mobs
					continue
				if(our_faction == "slime" && ((slime_color.slime_tags & SLIME_ATTACK_SLIMES) || (possible_target in recent_attackers))) //Allows slimes with attack_slimes tag to attack other slimes
					continue
				if(our_faction in possible_target.faction)
					ally = TRUE
					break

			if(ally)
				continue

			if(issilicon(possible_target) && (HAS_TRAIT(src, TRAIT_SLIME_RABID) || (possible_target in recent_attackers))) // They can't eat silicons, but they can glomp them in defence
				targets += possible_target // Possible target found!
				continue

			if(locate(/mob/living/simple_animal/slime) in possible_target.buckled_mobs) // Only one slime can latch on at a time.
				continue

			targets += possible_target // Possible target found!

		for(var/obj/possible_food in view(7, src))
			if(can_feed_on(possible_food, TRUE, slimeignore = (slime_color.slime_tags & SLIME_ATTACK_SLIMES), distignore = TRUE))
				targets += possible_food

		if(targets.len > 0)
			if(HAS_TRAIT(src, TRAIT_SLIME_RABID))
				set_target(targets[1])

			else if(attacked) //Prioritizes mobs that attacked us, if none found then just go for the first one seen
				for(var/possible_target in targets)
					if(!(possible_target in recent_attackers))
						continue

					set_target(possible_target)
					break

				if(!target)
					set_target(targets[1])

			else if(hungry == 2)
				for(var/possible_target in targets)
					if(can_feed_on(possible_target, TRUE, slimeignore = (slime_color.slime_tags & SLIME_ATTACK_SLIMES), distignore = TRUE))
						set_target(possible_target)
						break
			else
				for(var/mob/living/possible_target in targets)
					if(!istype(possible_target) || !can_feed_on(possible_target, TRUE, slimeignore = TRUE, distignore = TRUE))
						continue

					if(ishuman(possible_target) || isalienadult(possible_target))
						if(discipline || !DT_PROB((mood_level < SLIME_MOOD_LEVEL_POUT ? 10 : 3), delta_time))
							continue

					set_target(possible_target)
					break

				if(!target)
					var/nearest_food
					var/food_dist = -1
					for(var/obj/possible_food in targets)
						if(get_dist(src, possible_food) < food_dist || food_dist == -1)
							food_dist = get_dist(src, possible_food)
							nearest_food = possible_food

					if(nearest_food)
						set_target(nearest_food)

	if (target)
		target_patience = rand(5, 7)
		if (is_adult)
			target_patience += 3
		if (hungry == 2)
			target_patience += 3
		if (HAS_TRAIT(src, TRAIT_SLIME_RABID) || attacked)
			target_patience += 3
		if(!ai_active)
			kickstart_ai()
		return

	if(!leader)
		handle_boredom(delta_time, times_fired, hungry)
		return

	if(holding_still)
		holding_still = max(holding_still - (0.5 * delta_time), 0)
	else if(!HAS_TRAIT(src, TRAIT_IMMOBILIZED) && isturf(loc))
		start_moveloop(leader)

/mob/living/simple_animal/slime/handle_automated_movement()
	return //slime random movement is currently handled in handle_targets()

/mob/living/simple_animal/slime/handle_automated_speech()
	return //slime random speech is currently handled in handle_speech()

/mob/living/simple_animal/slime/proc/handle_boredom(delta_time, times_fired, hungry)
	if(holding_still)
		holding_still = max(holding_still - (0.5 * max(hungry, 1) * delta_time), 0)
		return
	else if (docile && pulledby && !hungry)
		holding_still = 10
		return

	if(HAS_TRAIT(src, TRAIT_IMMOBILIZED) || !isturf(loc))
		return

	if(DT_PROB(SLIME_VENTCRAWL_CHANCE * (hungry + 1), delta_time))
		if(attempt_ventcrawl())
			return

	if(DT_PROB(SLIME_POI_INTERACT_CHANCE, delta_time))
		var/list/points_of_interest = list()
		for(var/obj/possible_interest in view(5, get_turf(src)))
			if(istype(possible_interest, /obj/item/giant_slime_plushie))
				if(mood_level < SLIME_MOOD_LEVEL_HAPPY && DT_PROB((SLIME_MOOD_LEVEL_HAPPY - mood_level) / 3.75 + 15, delta_time))
					points_of_interest += possible_interest

			if(SEND_SIGNAL(src, COMSIG_SLIME_CAN_TARGET_POI, possible_interest) & COMPONENT_SLIME_TARGET_POI)
				points_of_interest += possible_interest

		if(LAZYLEN(points_of_interest))
			set_target(pick(points_of_interest))
			return

	if(DT_PROB(25 + (25 * (hungry > 0)), delta_time))
		var/picked_dir = pick(GLOB.alldirs)
		Move(get_step(src, picked_dir), picked_dir)

	if(mood_level < SLIME_MOOD_LEVEL_POUT)
		if(DT_PROB((SLIME_MOOD_LEVEL_POUT - mood_level) / 5, delta_time))
			var/list/grief_targets = list()
			for(var/obj/machinery/light/light in view(9, get_turf(src)))
				if(light.status || light.machine_stat & BROKEN)
					continue

				if(!get_step_to(src, light))
					continue

				grief_targets[light] = 1

			for(var/obj/machinery/power/apc/apc in view(9, get_turf(src)))
				if(apc.machine_stat & BROKEN)
					continue

				if(!get_step_to(src, apc))
					continue

				grief_targets[apc] = 5

			if(LAZYLEN(grief_targets))
				set_target(pick_weight(grief_targets))
				target_patience = 10

	if(!target && DT_PROB(0.5, delta_time))
		apply_moodlet(/datum/slime_moodlet/bored)

/mob/living/simple_animal/slime/proc/attempt_ventcrawl()
	var/list/vents_and_scrubbers = list()
	for(var/obj/machinery/atmospherics/components/unary/vent_pump/vent in view(7, src))
		if(vent.welded)
			continue

		var/datum/pipeline/vent_pipeline = vent.parents[1]
		var/datum/gas_mixture/pipe_gas = vent_pipeline.air
		if(pipe_gas.temperature < slime_color.temperature_modifier) //No vent suicides
			continue

		if(pipe_gas.gases[/datum/gas/bz] && pipe_gas.gases[/datum/gas/bz][MOLES]) //If you pump BZ into vents you can stop slimes from venting
			continue

		if(!get_path_to(src, vent)) //Not easily pathfindable to
			continue

		vents_and_scrubbers += vent

	for(var/obj/machinery/atmospherics/components/unary/vent_scrubber/scrubber in view(7, src))
		if(scrubber.welded)
			continue

		var/datum/pipeline/scrubber_pipeline = scrubber.parents[1]
		var/datum/gas_mixture/pipe_gas = scrubber_pipeline.air
		if(pipe_gas.temperature < slime_color.temperature_modifier)
			continue

		if(pipe_gas.gases[/datum/gas/bz] && pipe_gas.gases[/datum/gas/bz][MOLES])
			continue

		if(!get_path_to(src, scrubber)) //Not easily pathfindable to
			continue

		vents_and_scrubbers += scrubber

	if(!LAZYLEN(vents_and_scrubbers))
		return FALSE

	set_target(pick(vents_and_scrubbers))
	return TRUE

/mob/living/simple_animal/slime/proc/handle_mood(delta_time, times_fired)
	handle_moodlets()

	var/new_face
	var/new_face_priority = 0
	var/supposed_mood_level = SLIME_MOOD_PASSIVE_LEVEL

	for(var/moodlet_type in moodlets)
		var/datum/slime_moodlet/moodlet = moodlets[moodlet_type]
		if(!moodlet)
			moodlets -= moodlet_type
			continue

		supposed_mood_level = min(SLIME_MOOD_MAXIMUM, max(0, supposed_mood_level + moodlet.mood_offset))
		if(!moodlet.special_mood || moodlet.face_priority < new_face_priority)
			continue

		if(!islist(moodlet.special_mood))
			new_face = moodlet.special_mood
			continue

		new_face = pick(moodlet.special_mood)
		new_face_priority = moodlet.face_priority

	mood_level = mood_level + (supposed_mood_level - mood_level) * SLIME_MOOD_GAIN_MODIFIER

	if(mood_level < SLIME_MOOD_LEVEL_POUT)
		if(discipline && DT_PROB(2, delta_time)) //Faster discipline loss
			discipline -= 1

	if(mood_level < SLIME_MOOD_LEVEL_SAD)
		if(friends.len > 0 && DT_PROB(3, delta_time)) //Lose friends when sad
			var/mob/nofriend = pick(friends)
			add_friendship(nofriend, -1)
		if(!HAS_TRAIT(src, TRAIT_SLIME_RABID) && !docile && DT_PROB(0.05, delta_time)) //Very low chance to become rabid when sad
			ADD_TRAIT(src, TRAIT_SLIME_RABID, "bad_slime_mood")

	if(mood_level > SLIME_MOOD_LEVEL_HAPPY)
		REMOVE_TRAIT(src, TRAIT_SLIME_RABID, "bad_slime_mood")

	if(!new_face)
		switch(mood_level)
			if(SLIME_MOOD_LEVEL_HAPPY to SLIME_MOOD_MAXIMUM)
				new_face = pick("owo", "uwu")
			if(SLIME_MOOD_LEVEL_SAD to SLIME_MOOD_LEVEL_POUT)
				new_face = "pout"
			if(0 to SLIME_MOOD_LEVEL_SAD)
				new_face = pick("pout", "sad")

		if(target)
			new_face = "mischievous"

		if(!new_face && DT_PROB(0.5, delta_time))
			new_face = pick("sad", "uwu", "owo", "pout")

	if(!new_face)
		return

	if(new_face == mood)
		return

	mood = new_face
	regenerate_icons()

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
				if (leader)
					if (leader == who) // Already following him
						to_say = pick("Yes...", "Lead...", "Follow...")
					else if (friends[who] > friends[leader]) // VIVA
						set_leader(who)
						to_say = "Yes... I follow [who]..."
					else
						to_say = "No... I follow [leader]..."
				else
					if (friends[who] >= SLIME_FRIENDSHIP_FOLLOW)
						set_leader(who)
						to_say = "I follow..."
					else // Not friendly enough
						to_say = pick("No...", "I no follow...")
			else if (findtext(phrase, "stop"))
				if (buckled && isliving(buckled)) // We are asked to stop feeding
					if (friends[who] >= SLIME_FRIENDSHIP_STOPEAT)
						feed_stop()
						set_target(null)
						if (friends[who] < SLIME_FRIENDSHIP_STOPEAT_NOANGRY)
							add_friendship(who, -1)
							to_say = "Grrr..." // I'm angry but I do it
						else
							to_say = "Fine..."
				else if (target) // We are asked to stop chasing
					if (friends[who] >= SLIME_FRIENDSHIP_STOPCHASE)
						set_target(null)
						if (friends[who] < SLIME_FRIENDSHIP_STOPCHASE_NOANGRY)
							add_friendship(who, -1)
							to_say = "Grrr..." // I'm angry but I do it
						else
							to_say = "Fine..."
				else if (leader) // We are asked to stop following
					if (leader == who)
						to_say = "Yes... I stay..."
						set_leader(null)
					else
						if (friends[who] > friends[leader])
							set_leader(null)
							to_say = "Yes... I stop..."
						else
							to_say = "No... keep follow..."
			else if (findtext(phrase, "stay"))
				if (leader)
					if (leader == who)
						holding_still = friends[who] * 10
						to_say = "Yes... stay..."
					else if (friends[who] > friends[leader])
						holding_still = (friends[who] - friends[leader]) * 10
						to_say = "Yes... stay..."
					else
						to_say = "No... keep follow..."
				else
					if (friends[who] >= SLIME_FRIENDSHIP_STAY)
						holding_still = friends[who] * 10
						to_say = "Yes... stay..."
					else
						to_say = "No... won't stay..."
			else if (findtext(phrase, "attack"))
				if (HAS_TRAIT(src, TRAIT_SLIME_RABID) && prob(20))
					set_target(who)
					kickstart_ai() //Wake up the slime's target AI, needed otherwise this doesn't work
					to_say = "ATTACK!?!?"
				else if (friends[who] >= SLIME_FRIENDSHIP_ATTACK)
					for (var/mob/living/L in view(7,src)-list(src,who))
						if (findtext(phrase, lowertext(L.name)))
							if (isslime(L))
								to_say = "NO... [L] slime friend"
								add_friendship(who, -1) //Don't ask a slime to attack its friend
							else if(!friends[L] || friends[L] < 1)
								set_target(L)
								kickstart_ai()//Wake up the slime's target AI, needed otherwise this doesn't work
								if(isliving(target))
									to_say = "Ok... I attack [target]"
								else
									to_say = "Ok... I eat [target]"
							else
								to_say = "No... like [L] ..."
								add_friendship(who, -1) //Don't ask a slime to attack its friend
							break
				else
					to_say = "No... no listen"

		speech_buffer = list()

	//Speech starts here
	if (to_say)
		if(SEND_SIGNAL(src, COMSIG_SLIME_ATTEMPT_SAY, to_say) & COMPONENT_SLIME_NO_SAY)
			return
		say(to_say)
		return

	if(DT_PROB(0.5, delta_time))
		emote(pick("bounce", "sway", "light", "vibrate", "jiggle"))
		return

	if (!DT_PROB(1, delta_time) || stat)
		return

	var/list/speech_lines = list("Rawr...", "Blop...", "Blorble...")
	for(var/moodlet_type in moodlets)
		var/datum/slime_moodlet/moodlet = moodlets[moodlet_type]
		if(moodlet.special_line)
			speech_lines |= moodlet.special_line

	if (target)
		speech_lines += "[target]... look yummy..."

	for (var/mob/living/possible_friend in view(7, src))
		if(!(possible_friend in friends))
			continue

		speech_lines += "[possible_friend]... friend..."
		if (nutrition < get_hunger_nutrition())
			speech_lines += "[possible_friend]... feed me..."

	to_say = pick(speech_lines)
	if(SEND_SIGNAL(src, COMSIG_SLIME_ATTEMPT_SAY, to_say) & COMPONENT_SLIME_NO_SAY)
		return
	say(to_say)

/mob/living/simple_animal/slime/proc/handle_digestion(delta_time, times_fired)
	if(!digesting)
		remove_moodlet(/datum/slime_moodlet/digesting_food)
		return

	var/food
	for(var/food_type in slime_color.food_types)
		if(istype(digesting, food_type))
			food = food_type
			break

	apply_moodlet(/datum/slime_moodlet/digesting_food)
	digestion_progress += delta_time * slime_color.digestion_speed
	adjust_nutrition(SLIME_DIGESTION_NUTRITION * slime_color.digestion_speed * delta_time * slime_color.food_types[food]) //6 nutrition per second, 300 per item by default

	if(digestion_progress >= 100)
		cut_overlay(digestion_overlay)
		to_chat(src, span_notice("You finish digesting [digesting]."))
		SEND_SIGNAL(src, COMSIG_SLIME_DIGESTED, digesting)
		QDEL_NULL(digestion_overlay)
		QDEL_NULL(digesting)
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
		return nutrition_control ? 1000 : (get_max_nutrition() + 1)
	else
		return nutrition_control ? 800 : (get_max_nutrition() + 1)

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
	if (hunger == 2 || HAS_TRAIT(src, TRAIT_SLIME_RABID) || attacked)
		return TRUE
	if (leader)
		return FALSE
	if (holding_still)
		return FALSE
	return TRUE

/mob/living/simple_animal/slime/proc/handle_moodlets()
	if(!slime_color.fitting_environment && !(slime_color.slime_tags & SLIME_NO_REQUIREMENT_MOOD_LOSS))
		apply_moodlet(/datum/slime_moodlet/req_not_satisfied)
	else
		remove_moodlet(/datum/slime_moodlet/req_not_satisfied)

	if(nutrition < get_starve_nutrition())
		remove_moodlet(/datum/slime_moodlet/hungry)
		apply_moodlet(/datum/slime_moodlet/starving)
	else if(nutrition < get_hunger_nutrition())
		remove_moodlet(/datum/slime_moodlet/starving)
		apply_moodlet(/datum/slime_moodlet/hungry)

	if(HAS_TRAIT(src, TRAIT_SLIME_RABID))
		apply_moodlet(/datum/slime_moodlet/rabid)
	else
		remove_moodlet(/datum/slime_moodlet/rabid)

	if(powerlevel > 3 && powerlevel <= 5)
		apply_moodlet(/datum/slime_moodlet/power_one)
	else
		remove_moodlet(/datum/slime_moodlet/power_one)

	if(powerlevel > 5 && powerlevel <= 8)
		apply_moodlet(/datum/slime_moodlet/power_two)
	else
		remove_moodlet(/datum/slime_moodlet/power_two)

	if(powerlevel > 8)
		apply_moodlet(/datum/slime_moodlet/power_three)
	else
		remove_moodlet(/datum/slime_moodlet/power_three)

	if(docile)
		apply_moodlet(/datum/slime_moodlet/docile)
	else
		remove_moodlet(/datum/slime_moodlet/docile)

	var/other_slimes = 0
	for(var/mob/living/simple_animal/slime in view(5, get_turf(src)))
		if(slime != src)
			other_slimes += 1

	var/lonely_amount = 0
	var/friends_amount = 2
	var/crowded_amount = 5

	if(slime_color.slime_tags & SLIME_SOCIAL)
		lonely_amount = 1
		friends_amount = 4
		crowded_amount = 7
	else if(slime_color.slime_tags & SLIME_ANTISOCIAL)
		lonely_amount = -1
		friends_amount = -1
		crowded_amount = 3

	if(other_slimes > lonely_amount)
		if(lonely_amount != -1)
			apply_moodlet(/datum/slime_moodlet/friend)
		remove_moodlet(/datum/slime_moodlet/lonely)
	else
		remove_moodlet(/datum/slime_moodlet/friend)
		apply_moodlet(/datum/slime_moodlet/lonely)

	if(other_slimes >= friends_amount && friends_amount != -1)
		apply_moodlet(/datum/slime_moodlet/friends)
	else
		remove_moodlet(/datum/slime_moodlet/friends)

	if(other_slimes >= crowded_amount)
		apply_moodlet(/datum/slime_moodlet/crowded)
	else
		remove_moodlet(/datum/slime_moodlet/crowded)
