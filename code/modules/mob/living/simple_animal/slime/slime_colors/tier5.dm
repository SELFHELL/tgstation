/datum/slime_color/cerulean
	color = "cerulean"
	coretype = /obj/item/slime_extract/cerulean
	mutations = null
	slime_tags = SLIME_DISCHARGER_WEAKENED | SLIME_BLUESPACE_CONNECTION
	environmental_req = "Subject requires starlight to function and is able to use to it to manipulate matter."
	var/blueprint_charge = 0

/datum/slime_color/cerulean/New(slime)
	. = ..()
	blueprint_charge = CERULEAN_SLIME_MAX_CHARGE / 2
	RegisterSignal(slime, COMSIG_SLIME_ATTACK_ATOM, .proc/slime_attack)

/datum/slime_color/cerulean/remove()
	UnregisterSignal(slime, COMSIG_SLIME_ATTACK_ATOM)

/datum/slime_color/cerulean/proc/turf_starlight_check(turf/target, direction, iteration = 0)
	if(iteration > CERULEAN_SLIME_STARLIGHT_RANGE)
		return FALSE

	if(isspaceturf(target))
		return TRUE

	var/area/target_area = get_area(target)
	if(target_area.outdoors)
		return TRUE

	if(direction == ZTRAIT_UP)
		var/turf/second_target = target.above()

		if(!second_target)
			return FALSE

		if(!istransparentturf(second_target) && !isopenturf(second_target))
			return FALSE

		return starlight_check(second_target, direction, iteration + 1)
	else
		if(!istransparentturf(target) && !isopenturf(target))
			return FALSE

		var/turf/second_target = target.below()

		if(!second_target)
			return TRUE
		else
			return starlight_check(second_target, direction, iteration + 1)

/datum/slime_color/cerulean/proc/starlight_check() //Because range is 2, you want to put a glass tile in the center of the pen or something
	var/starlight_turfs = 0
	for(var/turf/target in view(CERULEAN_SLIME_STARLIGHT_RANGE, get_turf(slime)))
		if(turf_starlight_check(target, ZTRAIT_UP) || turf_starlight_check(target, ZTRAIT_DOWN))
			starlight_turfs += 1

	return starlight_turfs

/datum/slime_color/cerulean/Life(delta_time, times_fired)
	. = ..()
	var/starlight_turfs = starlight_check()
	if(starlight_turfs)
		blueprint_charge = min(delta_time * (CERULEAN_SLIME_CHARGE_PER_SECOND + (starlight_turfs - 1) * CERULEAN_SLIME_CHARGE_PER_STARLIGHT), CERULEAN_SLIME_MAX_CHARGE)
		fitting_environment = TRUE
		return

	fitting_environment = FALSE
	slime.adjustBruteLoss(1)

/datum/slime_color/cerulean/proc/slime_attack(datum/source, atom/movable/attack_target)
	SIGNAL_HANDLER

	if(isliving(attack_target))
		var/mob/living/victim = attack_target
		if(!prob(CERULEAN_SLIME_WALL_PROBABILITY) || !victim.client) //Don't spawn walls when feeding on clientless mobs
			return

		for(var/obj/effect/cerulean_wall/wall in range(1, slime)) //No wall spam
			if(istype(wall))
				return

		var/turf/target_turf = get_turf(victim)
		var/atom/throw_target = get_edge_target_turf(target_turf, get_dir(slime, victim))
		victim.throw_at(throw_target, 1, 1, slime)
		new /obj/effect/cerulean_wall(target_turf)
		return COLOR_SLIME_NO_ATTACK

	if(fitting_environment || slime.rabid) //When angry, celerulean slimes just straight up tear shit down, which can lead to horrible outbreaks if they're hungry/rabid
		return

	attack_target.attack_generic(slime, CERULEAN_SLIME_UNHAPPY_OBJECT_DAMAGE, BRUTE, MELEE, 1)
	return COLOR_SLIME_NO_ATTACK

/obj/effect/cerulean_wall
	name = "blueprint wall"
	desc = "This wall looks like it's made out of blueprint paper."
	icon_state = ""
	anchored = TRUE
	density = TRUE
	opacity = TRUE
	pass_flags_self = PASSCLOSEDTURF
	layer = ABOVE_ALL_MOB_LAYER
	plane = ABOVE_GAME_PLANE

/obj/effect/cerulean_wall/Initialize(mapload)
	. = ..()
	new /obj/effect/temp_visual/cerulean_wall_construction(get_turf(src))
	sleep(2.775)
	icon_state = "cerulean_wall"
	update_icon()
	addtimer(CALLBACK(src, .proc/tear_apart), 10 SECONDS)

/obj/effect/cerulean_wall/proc/tear_apart()
	new /obj/effect/temp_visual/cerulean_wall_construction/reverse(get_turf(src))
	sleep(2.4)
	qdel(src)

/obj/effect/temp_visual/cerulean_wall_construction
	icon = 'icons/effects/effects_rcd.dmi'
	icon_state = "rcd_cerulean"
	layer = FLY_LAYER
	plane = ABOVE_GAME_PLANE
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	duration = 6

/obj/effect/temp_visual/cerulean_wall_construction/reverse
	icon_state = "rcd_cerulean_reverse"

/datum/slime_color/sepia
	color = "sepia"
	coretype = /obj/item/slime_extract/sepia
	mutations = null
	environmental_req = "Subject has time-manipulating capabilities that can be supressed by hydrogen."
	slime_tags = SLIME_BLUESPACE_CONNECTION
	var/can_timestop = TRUE

/datum/slime_color/sepia/New(mob/living/simple_animal/slime/slime)
	. = ..()
	RegisterSignal(slime, COMSIG_SLIME_ATTACK_ATOM, .proc/timestop_attack)

/datum/slime_color/sepia/remove()
	UnregisterSignal(slime, COMSIG_SLIME_ATTACK_ATOM)

/datum/slime_color/sepia/proc/timestop_attack(datum/source, atom/attack_target)
	SIGNAL_HANDLER

	if(!can_timestop || !prob(SEPIA_SLIME_ATTACK_TIMESTOP_CHANCE) || !isliving(attack_target) || !fitting_environment)
		return

	new /obj/effect/timestop/small_effect(get_turf(attack_target), 1, SEPIA_SLIME_TIMESTOP_DURATION, list(src))
	can_timestop = FALSE
	addtimer(CALLBACK(src, .proc/recover_from_timestop), SEPIA_SLIME_TIMESTOP_DURATION + SEPIA_SLIME_TIMESTOP_RECOVERY)

/datum/slime_color/sepia/Life(delta_time, times_fired)
	. = ..()
	var/turf/our_turf = get_turf(slime)
	var/datum/gas_mixture/our_mix = our_turf.return_air()
	if(our_mix.gases[/datum/gas/hydrogen] && our_mix.gases[/datum/gas/hydrogen][MOLES] > SEPIA_SLIME_HYDROGEN_REQUIRED)
		fitting_environment = TRUE
		if(!HAS_TRAIT(slime, TRAIT_TIMESTOP_IMMUNE))
			ADD_TRAIT(slime, TRAIT_TIMESTOP_IMMUNE, XENOBIO_TRAIT)
		return

	fitting_environment = FALSE
	slime.adjustBruteLoss(3)
	if(HAS_TRAIT(slime, TRAIT_TIMESTOP_IMMUNE))
		REMOVE_TRAIT(slime, TRAIT_TIMESTOP_IMMUNE, XENOBIO_TRAIT)

	if(!can_timestop)
		return

	if(DT_PROB(SEPIA_SLIME_TIMESTOP_CHANCE, delta_time))
		can_timestop = FALSE
		new /obj/effect/timestop/small_effect(get_turf(slime), 1, SEPIA_SLIME_TIMESTOP_DURATION, list()) //Freezes the slime as well
		addtimer(CALLBACK(src, .proc/recover_from_timestop), SEPIA_SLIME_TIMESTOP_DURATION + SEPIA_SLIME_TIMESTOP_RECOVERY)

/datum/slime_color/sepia/proc/recover_from_timestop()
	can_timestop = TRUE

/datum/slime_color/pyrite /// I think you can farm these without pyrite launchers, but having a burn chamber in xenobio is not really a great idea
	color = "pyrite"
	coretype = /obj/item/slime_extract/pyrite
	mutations = null
	environmental_req = "Subject requires high temperatures(above 480° Celsius) or active fires to survive. If subject dies in low temperatures it will freeze and become unrevivable."
	slime_tags = SLIME_HOT_LOVING

/datum/slime_color/pyrite/New(mob/living/simple_animal/slime/slime)
	. = ..()
	RegisterSignal(slime, COMSIG_LIVING_DEATH, .proc/possible_freeze)

/datum/slime_color/pyrite/remove()
	UnregisterSignal(slime, COMSIG_LIVING_DEATH)

/datum/slime_color/pyrite/proc/possible_freeze(mob/living/simple_animal/slime/dead_body)
	SIGNAL_HANDLER

	var/turf/our_turf = get_turf(slime)
	var/datum/gas_mixture/our_mix = our_turf.return_air()
	if(our_mix?.temperature >= PYRITE_SLIME_COMFORTABLE_TEMPERATURE || (locate(/obj/effect/hotspot) in our_turf))
		return

	slime.name = "frozen [slime.name]"
	slime.add_atom_colour(GLOB.freon_color_matrix, TEMPORARY_COLOUR_PRIORITY)
	slime.alpha -= 25
	ADD_TRAIT(slime, TRAIT_NO_REVIVE, XENOBIO_TRAIT)

/datum/slime_color/pyrite/Life(delta_time, times_fired)
	. = ..()
	var/turf/our_turf = get_turf(slime)
	var/datum/gas_mixture/our_mix = our_turf.return_air()
	if(our_mix?.temperature >= PYRITE_SLIME_COMFORTABLE_TEMPERATURE || (locate(/obj/effect/hotspot) in our_turf))
		fitting_environment = TRUE
		return

	fitting_environment = FALSE
	slime.adjustBruteLoss(5)

/datum/slime_color/bluespace
	color = "bluespace"
	coretype = /obj/item/slime_extract/bluespace
	mutations = null
	environmental_req = "Subject is spartially unstable and will phase through obstacles unless forcefully anchored in bluespace."

/datum/slime_color/bluespace/New(mob/living/simple_animal/slime/slime)
	. = ..()
	RegisterSignal(slime, COMSIG_SLIME_TAKE_STEP, .proc/teleport)

/datum/slime_color/bluespace/remove()
	UnregisterSignal(slime, COMSIG_SLIME_TAKE_STEP)

/datum/slime_color/bluespace/proc/teleport(datum/source, atom/step_target)
	SIGNAL_HANDLER

	if(!prob(BLUESPACE_SLIME_TELEPORT_CHANCE))
		return

	var/turf/slime_turf = get_turf(slime)
	if(HAS_TRAIT(slime_turf, TRAIT_NO_SLIME_TELEPORTATION))
		return

	var/turf/possible_tele_turf = slime_turf
	var/iter = 1
	for(var/turf/tele_turf in get_line(slime_turf, get_turf(step_target)))
		if(iter > BLUESPACE_SLIME_TELEPORT_DISTANCE)
			break

		tele_turf = get_step(tele_turf, get_dir(slime, step_target))
		if(is_safe_turf(tele_turf, no_teleport = TRUE) && !tele_turf.is_blocked_turf_ignore_climbable(exclude_mobs = TRUE) && !HAS_TRAIT(tele_turf, TRAIT_NO_SLIME_TELEPORTATION))
			possible_tele_turf = tele_turf

		iter += 1

	slime_turf.Beam(possible_tele_turf, "bluespace_phase", time = 12)
	do_teleport(slime, possible_tele_turf, channel = TELEPORT_CHANNEL_BLUESPACE)
	return COLOR_SLIME_NO_STEP
