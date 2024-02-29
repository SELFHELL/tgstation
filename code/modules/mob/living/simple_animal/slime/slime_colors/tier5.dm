/datum/slime_color/cerulean
	color = "cerulean"
	coretype = /obj/item/slime_extract/cerulean
	slime_tags = SLIME_BLUESPACE_CONNECTION | SLIME_WATER_RESISTANCE | SLIME_SOCIAL
	environmental_req = "Subject has telekinetic capabilities and requires vacuum to survive."
	var/slime_flying = FALSE
	COOLDOWN_DECLARE(lunge_cooldown)

/datum/slime_color/cerulean/New(slime)
	. = ..()
	RegisterSignal(slime, COMSIG_MOVABLE_IMPACT, .proc/successful_lunge)
	RegisterSignal(slime, COMSIG_SLIME_ATTEMPT_RANGED_ATTACK, .proc/attempt_lunge)

/datum/slime_color/cerulean/remove()
	UnregisterSignal(slime, list(COMSIG_MOVABLE_IMPACT, COMSIG_SLIME_ATTEMPT_RANGED_ATTACK))

/datum/slime_color/cerulean/Life(delta_time, times_fired)
	. = ..()

	var/datum/gas_mixture/our_mix = slime.loc.return_air()
	if(our_mix.return_pressure() < CERULEAN_SLIME_MAX_SAFE_PRESSURE)
		ADD_TRAIT(slime, TRAIT_SPACEWALK, INNATE_TRAIT)
		fitting_environment = TRUE
		temperature_modifier = -11 //Space-walking slimes! -11 because slimes get slowed down on temperature_modifier + 10
		handle_telekinesis(delta_time, times_fired, FALSE)
		slime.adjustBruteLoss(CERULEAN_SLIME_VACUUM_HEALING * delta_time) //Slow spess healing
		return

	REMOVE_TRAIT(slime, TRAIT_SPACEWALK, INNATE_TRAIT)
	temperature_modifier = initial(temperature_modifier) //Or not so much
	slime.adjustBruteLoss(SLIME_DAMAGE_MED * delta_time * get_passive_damage_modifier())
	handle_telekinesis(delta_time, times_fired, TRUE)

/datum/slime_color/cerulean/proc/attempt_lunge(datum/source, atom/target)
	SIGNAL_HANDLER

	if(!COOLDOWN_FINISHED(src, lunge_cooldown) || !isliving(target) || !COOLDOWN_FINISHED(slime, attack_cd))
		return

	if(get_dist(slime, target) <= 1) //No bullshit melee knockdowns
		return

	for(var/turf/lunge_turf in get_line(slime, target))
		if(lunge_turf.is_blocked_turf_ignore_climbable(exclude_mobs = TRUE))
			return

	COOLDOWN_START(src, lunge_cooldown, CERULEAN_SLIME_LUNGE_COOLDOWN)
	COOLDOWN_START(slime, attack_cd, get_attack_cd(target))
	slime.visible_message(span_warning("[slime] lunges at [target]!"), span_notice("You lunge at [target]!"))
	slime.throw_at(target, 7, 1, src, FALSE)

/datum/slime_color/cerulean/proc/successful_lunge(datum/source, atom/hit_atom, datum/thrownthing/throwingdatum)
	SIGNAL_HANDLER

	if(!isliving(hit_atom))
		return

	var/mob/living/victim = hit_atom
	to_chat(victim, span_userdanger("You are knocked down by [src]'s lunge!"))
	victim.Knockdown(8 SECONDS)
	victim.Paralyze(4 SECONDS)

/datum/slime_color/cerulean/proc/handle_telekinesis(delta_time, times_fired, agressive)
	if(!DT_PROB(agressive ? CERULEAN_SLIME_AGRESSIVE_TELEKINESIS_CHANCE : CERULEAN_SLIME_TELEKINESIS_CHANCE, delta_time))
		return

	var/list/openable_airlocks = list()
	for(var/obj/machinery/door/firedoor/firelock in view(9, slime))
		if(!firelock.powered() && !firelock.welded && firelock.density)
			openable_airlocks += firelock

	for(var/obj/machinery/door/window/windoor in view(9, slime))
		if(!windoor.powered() && windoor.density)
			openable_airlocks += windoor

	for(var/obj/machinery/door/airlock/airlock in view(9, slime))
		if(!airlock.powered() && !airlock.welded && !airlock.locked && airlock.density)
			openable_airlocks += airlock

	if(LAZYLEN(openable_airlocks)) //Allows for much more agressive AI targeting and pathfinding
		var/obj/machinery/door/door_to_open = pick(openable_airlocks)
		door_to_open.visible_message(span_warning("[door_to_open] is pried open by an invisible force!"))
		door_to_open.open(2)
		for(var/turf/open/open_turf in range(2, door_to_open))
			if(prob(20))
				new /obj/effect/temp_visual/cerulean_sparkles(open_turf)
		return

	var/list/throwable_objects = list()
	var/list/throwable_weights = list()
	for(var/obj/possible_throw in view(9, get_turf(slime)))
		if(possible_throw.anchored)
			continue

		var/list/possible_targets = list()
		var/target_weight = 0
		for(var/mob/living/possible_target in view(5, get_turf(possible_throw)))
			if(isslime(possible_target))
				continue

			for(var/turf/turf_in_line in get_line(get_turf(possible_throw), get_turf(possible_target)))
				if(turf_in_line.is_blocked_turf_ignore_climbable(exclude_mobs = TRUE))
					continue
				possible_targets[possible_target] = (6 - get_dist(possible_throw, possible_target)) * (2 - !(possible_target.client))
				target_weight += (6 - get_dist(possible_throw, possible_target)) * (2 - !(possible_target.client))

		if(!target_weight)
			continue

		throwable_objects[possible_throw] = possible_targets
		throwable_weights[possible_throw] = target_weight * possible_throw.throwforce

	if(!LAZYLEN(throwable_weights))
		return

	var/obj/throwable = pick_weight(throwable_weights)
	new /obj/effect/temp_visual/cerulean_sparkles(get_turf(throwable))
	throwable.throw_at(pick_weight(throwable_objects[throwable]), 9, 1, slime)

/datum/slime_color/sepia
	color = "sepia"
	coretype = /obj/item/slime_extract/sepia
	environmental_req = "Subject has time-manipulating capabilities that can be supressed by BZ."
	slime_tags = SLIME_BLUESPACE_CONNECTION | SLIME_BZ_IMMUNE
	var/can_timestop = TRUE

/datum/slime_color/sepia/New(mob/living/simple_animal/slime/slime)
	. = ..()
	RegisterSignal(slime, COMSIG_SLIME_ATTACK_TARGET, .proc/timestop_attack)
	ADD_TRAIT(slime, TRAIT_TIMESTOP_IMMUNE, XENOBIO_TRAIT)

/datum/slime_color/sepia/remove()
	UnregisterSignal(slime, COMSIG_SLIME_ATTACK_TARGET)
	REMOVE_TRAIT(slime, TRAIT_TIMESTOP_IMMUNE, XENOBIO_TRAIT)

/datum/slime_color/sepia/proc/timestop_attack(datum/source, atom/attack_target)
	SIGNAL_HANDLER

	if(!can_timestop || !prob(SEPIA_SLIME_ATTACK_TIMESTOP_CHANCE) || !isliving(attack_target) || !fitting_environment)
		return

	new /obj/effect/timestop/small_effect(get_turf(attack_target), 1, SEPIA_SLIME_TIMESTOP_DURATION, list(slime))
	can_timestop = FALSE
	addtimer(CALLBACK(src, .proc/recover_from_timestop), SEPIA_SLIME_TIMESTOP_DURATION + SEPIA_SLIME_TIMESTOP_RECOVERY)

/datum/slime_color/sepia/Life(delta_time, times_fired)
	. = ..()
	var/datum/gas_mixture/our_mix = slime.loc.return_air()

	if(SLIME_SHOULD_MISBEHAVE(slime, delta_time) && can_timestop)
		new /obj/effect/timestop/small_effect(get_turf(slime), 1, SEPIA_SLIME_TIMESTOP_DURATION, list(slime))
		can_timestop = FALSE
		addtimer(CALLBACK(src, .proc/recover_from_timestop), SEPIA_SLIME_TIMESTOP_DURATION + SEPIA_SLIME_TIMESTOP_RECOVERY)

	if(our_mix.gases[/datum/gas/bz] && our_mix.gases[/datum/gas/bz][MOLES] > SEPIA_SLIME_BZ_REQUIRED)
		fitting_environment = TRUE
		our_mix.remove_specific(/datum/gas/bz, SEPIA_SLIME_BZ_CONSUME * delta_time)
		return

	fitting_environment = FALSE
	slime.adjustBruteLoss(SLIME_DAMAGE_HIGH * delta_time * get_passive_damage_modifier())

	if(!can_timestop)
		return

	if(DT_PROB(SEPIA_SLIME_TIMESTOP_CHANCE, delta_time))
		can_timestop = FALSE
		REMOVE_TRAIT(slime, TRAIT_TIMESTOP_IMMUNE, XENOBIO_TRAIT)
		new /obj/effect/timestop/small_effect(get_turf(slime), 1, SEPIA_SLIME_TIMESTOP_DURATION, list()) //Freezes the slime as well
		addtimer(CALLBACK(src, .proc/recover_from_timestop, TRUE), SEPIA_SLIME_TIMESTOP_DURATION + SEPIA_SLIME_TIMESTOP_RECOVERY)

/datum/slime_color/sepia/proc/recover_from_timestop(regain_immunity = FALSE)
	can_timestop = TRUE
	if(regain_immunity)
		ADD_TRAIT(slime, TRAIT_TIMESTOP_IMMUNE, XENOBIO_TRAIT)

/datum/slime_color/pyrite /// I think you can farm these without pyrite launchers, but having a burn chamber in xenobio is not really a great idea
	color = "pyrite"
	coretype = /obj/item/slime_extract/pyrite
	environmental_req = "Subject requires high temperatures(above 480° Celsius) or active fires to survive. If subject dies in low temperatures it will freeze and become unrevivable."
	slime_tags = SLIME_HOT_LOVING | SLIME_WATER_WEAKNESS
	food_types = list(/obj/item/food/xenoflora/pyrite_peach = 0.35)
	var/fiery_charge = PYRITE_SLIME_MAX_FIERY_CHARGE

/datum/slime_color/pyrite/New(mob/living/simple_animal/slime/slime)
	. = ..()
	RegisterSignal(slime, COMSIG_LIVING_DEATH, .proc/possible_freeze)
	RegisterSignal(slime, COMSIG_SLIME_ATTACK_TARGET, .proc/fiery_attack)

/datum/slime_color/pyrite/remove()
	UnregisterSignal(slime, list(COMSIG_LIVING_DEATH, COMSIG_SLIME_ATTACK_TARGET))

/datum/slime_color/pyrite/proc/fiery_attack(datum/source, atom/attack_target)
	SIGNAL_HANDLER

	if(fiery_charge <= 0)
		return

	if(!isliving(attack_target))
		return

	var/mob/living/victim = attack_target
	if(victim.fire_stacks >= 3)
		return

	victim.adjust_fire_stacks(3)
	victim.ignite_mob()

/datum/slime_color/pyrite/proc/possible_freeze(mob/living/simple_animal/slime/dead_body)
	SIGNAL_HANDLER

	var/turf/our_turf = get_turf(slime)
	var/datum/gas_mixture/our_mix = slime.loc.return_air()
	if(our_mix?.temperature >= PYRITE_SLIME_COMFORTABLE_TEMPERATURE || (locate(/obj/effect/hotspot) in our_turf))
		return

	slime.name = "frozen [slime.name]"
	slime.add_atom_colour(GLOB.freon_color_matrix, TEMPORARY_COLOUR_PRIORITY)
	slime.alpha -= 25
	ADD_TRAIT(slime, TRAIT_NO_REVIVE, XENOBIO_TRAIT)

/datum/slime_color/pyrite/Life(delta_time, times_fired)
	. = ..()
	if(SLIME_SHOULD_MISBEHAVE(slime, delta_time) || DT_PROB(5, delta_time))
		for(var/mob/living/victim in range(1, src))
			if(victim.fire_stacks < 2)
				victim.adjust_fire_stacks(2)
				victim.ignite_mob()
				to_chat(victim, span_userdanger("You are set ablaze by [slime]'s heat!"))

	var/turf/our_turf = get_turf(slime)
	var/datum/gas_mixture/our_mix = slime.loc.return_air()
	if(our_mix?.temperature >= PYRITE_SLIME_COMFORTABLE_TEMPERATURE || (locate(/obj/effect/hotspot) in our_turf))
		fitting_environment = TRUE
		fiery_charge = PYRITE_SLIME_MAX_FIERY_CHARGE
		return

	if(fiery_charge > 0)
		fiery_charge = max(0, fiery_charge - delta_time)
		fitting_environment = TRUE
		return

	fitting_environment = FALSE
	slime.adjustBruteLoss(SLIME_DAMAGE_MED * delta_time * get_passive_damage_modifier())

/datum/slime_color/bluespace //These will either kill themselves, get stuck and are generally just hard to contain but don't have any combat abilities so no damage for them.
	color = "bluespace"
	coretype = /obj/item/slime_extract/bluespace
	slime_tags = SLIME_WATER_RESISTANCE
	environmental_req = "Subject is spartially unstable and will phase through obstacles unless forcefully anchored in bluespace."
	food_types = list(/obj/item/food/xenoflora/bluespace_limon = 0.25)

/datum/slime_color/bluespace/New(mob/living/simple_animal/slime/slime)
	. = ..()
	RegisterSignal(slime, COMSIG_SLIME_SQUEESING_ATTEMPT, .proc/handle_teleport)

/datum/slime_color/bluespace/remove()
	UnregisterSignal(slime, COMSIG_SLIME_SQUEESING_ATTEMPT)

/datum/slime_color/bluespace/proc/handle_teleport(datum/source, squeese_direction, datum/move_loop/move_loop, bumped)
	SIGNAL_HANDLER

	var/turf/our_turf = get_turf(slime)
	if(HAS_TRAIT(our_turf, TRAIT_BLUESPACE_SLIME_FIXATION))
		return

	if(bumped && !((squeese_direction & get_dir(slime, slime.current_loop_target)) || (get_dir(slime, slime.current_loop_target) & squeese_direction)))
		return

	var/turf/possible_tele_turf = our_turf
	var/iter = 1
	var/turf/target_edge_turf = get_edge_target_turf(our_turf, squeese_direction)
	for(var/turf/tele_turf in get_line(our_turf, target_edge_turf))
		if(iter > BLUESPACE_SLIME_TELEPORT_DISTANCE)
			break

		slime.forceMove(tele_turf)
		if(!get_step_to(slime, slime.current_loop_target) || get_step_to(slime, slime.current_loop_target) == our_turf)
			slime.forceMove(our_turf)
			iter += 1
			continue

		slime.forceMove(our_turf)

		if(tele_turf != our_turf && is_safe_turf(tele_turf, no_teleport = TRUE) && !tele_turf.is_blocked_turf_ignore_climbable(exclude_mobs = TRUE) && !HAS_TRAIT(tele_turf, TRAIT_BLUESPACE_SLIME_FIXATION))
			var/datum/gas_mixture/air = tele_turf.return_air()
			if(air.gases[/datum/gas/bz] && air.gases[/datum/gas/bz][MOLES])
				iter += 1
				continue
			possible_tele_turf = tele_turf

		iter += 1

	if(possible_tele_turf == our_turf)
		return

	our_turf.Beam(possible_tele_turf, "bluespace_phase", time = 12)
	do_teleport(slime, possible_tele_turf, channel = TELEPORT_CHANNEL_BLUESPACE)
	return COMPONENT_SLIME_NO_SQUEESING
