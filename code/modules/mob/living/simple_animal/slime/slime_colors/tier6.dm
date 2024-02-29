/datum/slime_color/oil
	color = "oil"
	coretype = /obj/item/slime_extract/oil
	slime_tags = SLIME_WATER_RESISTANCE | SLIME_ANTISOCIAL
	environmental_req = "Subject's slime is highly flammable and will leave a trail of oil behind it. You can stabilize the subject using high pressure. Fireproof equipment recommended."
	COOLDOWN_DECLARE(oil_throw_cooldown)

/datum/slime_color/oil/New(mob/living/simple_animal/slime/slime)
	. = ..()
	RegisterSignal(slime, COMSIG_MOVABLE_MOVED, .proc/on_moved)
	RegisterSignal(slime, COMSIG_SLIME_ATTACK_TARGET, .proc/drench_in_oil)
	RegisterSignal(slime, COMSIG_SLIME_ATTEMPT_RANGED_ATTACK, .proc/throw_oil)
	ADD_TRAIT(slime, TRAIT_BOMBIMMUNE, ROUNDSTART_TRAIT) //Kinda their whole deal

/datum/slime_color/oil/remove()
	UnregisterSignal(slime, list(COMSIG_MOVABLE_MOVED, COMSIG_SLIME_ATTACK_TARGET, COMSIG_SLIME_ATTEMPT_RANGED_ATTACK))
	REMOVE_TRAIT(slime, TRAIT_BOMBIMMUNE, ROUNDSTART_TRAIT)

/datum/slime_color/oil/Life(delta_time, times_fired)
	. = ..()
	var/datum/gas_mixture/our_mix = slime.loc.return_air()
	if(SLIME_SHOULD_MISBEHAVE(slime, delta_time))
		explosion(get_turf(slime), devastation_range = -1, heavy_impact_range = -1, light_impact_range = rand(0, 1), flame_range = rand(1, 2), flash_range = rand(1, 2)) //Ignites the oil and possibly damages the pen windows.

	if(our_mix.return_pressure() > OIL_SLIME_REQUIRED_PRESSURE)
		fitting_environment = TRUE
		return

	fitting_environment = FALSE
	slime.adjustBruteLoss(SLIME_DAMAGE_HIGH * delta_time * get_passive_damage_modifier())

/datum/slime_color/oil/proc/on_moved(datum/source, old_loc)
	SIGNAL_HANDLER
	if(!isturf(slime.loc)) //No locker abuse
		return

	new /obj/effect/decal/cleanable/fuel_pool/oil(slime.loc)

/datum/slime_color/oil/proc/drench_in_oil(datum/source, atom/attack_target)
	SIGNAL_HANDLER
	if(!isliving(attack_target))
		return
	var/mob/living/victim = attack_target
	if(victim.fire_stacks < OIL_SLIME_OIL_LIMIT)
		victim.adjust_fire_stacks(OIL_SLIME_STACKS_PER_ATTACK, /datum/status_effect/fire_handler/fire_stacks/oil)

/datum/slime_color/oil/proc/throw_oil(datum/source, atom/target)
	SIGNAL_HANDLER

	if(!COOLDOWN_FINISHED(src, oil_throw_cooldown) || !isliving(target) || !COOLDOWN_FINISHED(slime, attack_cd))
		return

	if(get_dist(slime, target) <= 1)
		return

	COOLDOWN_START(src, oil_throw_cooldown, OIL_SLIME_PROJECTILE_COOLDOWN)
	COOLDOWN_START(slime, attack_cd, get_attack_cd(target))
	var/obj/projectile/our_projectile = new /obj/projectile/oil(get_turf(slime))
	our_projectile.firer = slime
	our_projectile.original = target
	INVOKE_ASYNC(our_projectile, /obj/projectile.proc/fire)

/obj/projectile/oil
	name = "glob of oil"
	icon_state = "oil_glob"
	damage = 0
	speed = 2
	nodamage = TRUE

/obj/projectile/oil/on_hit(atom/target, blocked, pierce_hit)
	. = ..()
	if(!isliving(target))
		new /obj/effect/decal/cleanable/fuel_pool/oil(get_turf(src))
		return
	var/mob/living/victim = target
	victim.adjust_fire_stacks(OIL_SLIME_STACKS_PER_ATTACK, /datum/status_effect/fire_handler/fire_stacks/oil)

/obj/effect/decal/cleanable/fuel_pool/oil
	name = "pool of oil"
	desc = "A pool of flammable oil. It's probably wise to clean this off before something ignites it..."
	hotspot_type = /obj/effect/hotspot/oil

/obj/effect/decal/cleanable/fuel_pool/oil/ignite()
	if(burning)
		return
	burning = TRUE
	addtimer(CALLBACK(src, .proc/ignite_others), 0.2 SECONDS) //Spreads MUCH faster
	burn_process()

/datum/slime_color/black
	color = "black"
	coretype = /obj/item/slime_extract/black
	environmental_req = "Subject has an ability to terraform it's surroundings into slime-like turfs. This ability can be neutered by making the pen look like a natural habitat."
	slime_tags = SLIME_WATER_RESISTANCE | SLIME_SOCIAL
	var/list/required_turfs

/datum/slime_color/black/New(slime)
	. = ..()
	if(!required_turfs)
		required_turfs = typecacheof(list(
			/turf/open/misc/asteroid,
			/turf/open/misc/ashplanet,
			/turf/open/misc/dirt,
			/turf/open/floor/fakebasalt,
		))

/datum/slime_color/black/Life(delta_time, times_fired)
	. = ..()

	if(SLIME_SHOULD_MISBEHAVE(slime, delta_time) && DT_PROB(BLACK_SLIME_CHANGE_TURF_CHANCE, delta_time))
		convert_turf()

	var/turf/our_turf = get_turf(slime)
	if(is_type_in_typecache(our_turf, required_turfs))
		fitting_environment = TRUE
		return

	fitting_environment = FALSE
	slime.adjustBruteLoss(SLIME_DAMAGE_MED * delta_time * get_passive_damage_modifier())

	if(DT_PROB(BLACK_SLIME_CHANGE_TURF_CHANCE, delta_time))
		convert_turf()

/datum/slime_color/black/proc/convert_turf()

	var/list/convertable_turfs = list()
	for(var/turf/possible_target in circle_range_turfs(get_turf(slime), BLACK_SLIME_TURF_CHANGE_RANGE))
		if(istype(possible_target, /turf/open/misc/slime) || istype(possible_target, /turf/closed/wall/slime))
			continue

		if(isfloorturf(possible_target) || istype(possible_target, /turf/open/misc) || ismineralturf(possible_target))
			convertable_turfs[possible_target] = BLACK_SLIME_TURF_CHANGE_RANGE + 3 - get_dist(slime, possible_target) //Floors have a bit higher chance to be converted
		else if(iswallturf(possible_target))
			var/turf/closed/wall/target_wall = possible_target
			if(!prob(min(100, target_wall.hardness * 2)))
				continue
			convertable_turfs[possible_target] = BLACK_SLIME_TURF_CHANGE_RANGE + 1 - get_dist(slime, possible_target)

	var/turf/target_turf = pick_weight(convertable_turfs)
	if(isclosedturf(target_turf))
		target_turf.ChangeTurf(/turf/closed/wall/slime, flags = CHANGETURF_INHERIT_AIR)
	else if(locate(/obj/structure/window) in target_turf)
		for(var/obj/structure/window/window in target_turf)
			window.deconstruct(FALSE)
		target_turf.ChangeTurf(/turf/closed/wall/slime, flags = CHANGETURF_INHERIT_AIR)
	else
		target_turf.ChangeTurf(/turf/open/misc/slime, flags = CHANGETURF_INHERIT_AIR)

	var/obj/structure/grille/grille = locate() in target_turf
	if(grille)
		grille.deconstruct(FALSE)

/datum/slime_color/adamantine
	color = "adamantine"
	coretype = /obj/item/slime_extract/adamantine
	slime_tags = SLIME_WATER_IMMUNITY
	environmental_req = "Subject appears to posess a fist. Fisting is 300 bucks."
	var/fist_out = FALSE
	var/next_move_type
	var/exercise_cooldown = 0

/datum/slime_color/adamantine/New(slime)
	. = ..()
	RegisterSignal(slime, COMSIG_SLIME_ATTACK_TARGET, .proc/melee_attack)
	RegisterSignal(slime, COMSIG_SLIME_POST_REGENERATE_ICONS, .proc/icon_regen)
	RegisterSignal(slime, COMSIG_SLIME_CAN_TARGET_POI, .proc/can_target_poi)

/datum/slime_color/adamantine/remove()
	. = ..()
	UnregisterSignal(slime, list(COMSIG_SLIME_ATTEMPT_RANGED_ATTACK, COMSIG_SLIME_ATTACK_TARGET, COMSIG_SLIME_POST_REGENERATE_ICONS))

/datum/slime_color/adamantine/proc/icon_regen()
	SIGNAL_HANDLER

	if(slime.stat == DEAD || !fist_out)
		return

	var/mutable_appearance/fisting = mutable_appearance('icons/mob/big_slimes.dmi', "[slime.icon_state]-arm", slime.layer + 0.03, slime.plane)
	fisting.pixel_x = -8
	fisting.pixel_y = -8
	slime.add_overlay(fisting)

/datum/slime_color/adamantine/Life(delta_time, times_fired)
	. = ..()

	if(slime.nutrition < (slime.get_starve_nutrition() * 0.5 + slime.get_hunger_nutrition() * 0.5) && fist_out && DT_PROB(25, delta_time)) //Can't maintain fist if too hungry
		fist_out = FALSE
		slime.regenerate_icons()
	else if(!fist_out && (slime.target || DT_PROB(2.5, delta_time)))
		fist_out = TRUE
		slime.regenerate_icons()

	if(exercise_cooldown + ADAMANTINE_SLIME_EXERCISE_TOLERANCE > world.time)
		fitting_environment = TRUE
		return

	fitting_environment = FALSE
	slime.adjustBruteLoss(SLIME_DAMAGE_MED * delta_time * get_passive_damage_modifier())
	slime.adjust_nutrition(-2 * delta_time)

/datum/slime_color/adamantine/proc/can_target_poi(atom/possible_interest)
	SIGNAL_HANDLER

	if(exercise_cooldown > world.time)
		return

	if(istype(possible_interest, /obj/structure/punching_bag))
		return COMPONENT_SLIME_TARGET_POI

	if(istype(possible_interest, /obj/structure/weightmachine))
		var/obj/structure/weightmachine/machine = possible_interest
		if(machine.obj_flags & IN_USE)
			return
		return COMPONENT_SLIME_TARGET_POI

/datum/slime_color/adamantine/proc/use_punchbag(obj/structure/punching_bag/target)
	if(!fist_out)
		fist_out = TRUE
		slime.regenerate_icons()

	flick("[target.icon_state]-punch", target)
	playsound(target, pick(target.hit_sounds), 50, TRUE, -1)
	playsound(target, 'sound/effects/bamf.ogg', 50, TRUE)
	next_move_type = ADAMANTINE_SLIME_MOVE_SLAM
	exercise_cooldown = world.time + ADAMANTINE_SLIME_EXERCISE_COOLDOWN

/datum/slime_color/adamantine/proc/use_lifter(obj/structure/weightmachine/stacklifter/target)
	if(!fist_out)
		fist_out = TRUE
		slime.regenerate_icons()

	exercise_cooldown = INFINITY
	target.start_using(slime)
	next_move_type = ADAMANTINE_SLIME_MOVE_SUPLEX
	exercise_cooldown = world.time + ADAMANTINE_SLIME_EXERCISE_COOLDOWN

/datum/slime_color/adamantine/proc/use_bench(obj/structure/weightmachine/weightlifter/target)
	if(!fist_out)
		fist_out = TRUE
		slime.regenerate_icons()

	exercise_cooldown = INFINITY
	target.start_using(slime)
	next_move_type = ADAMANTINE_SLIME_MOVE_GROUND_STRIKE
	exercise_cooldown = world.time + ADAMANTINE_SLIME_EXERCISE_COOLDOWN

/datum/slime_color/adamantine/proc/melee_attack(atom/target)
	SIGNAL_HANDLER

	if(istype(target, /obj/structure/punching_bag))
		if(isliving(slime.target) || slime.attacked || HAS_TRAIT(slime, TRAIT_SLIME_RABID))
			return
		INVOKE_ASYNC(src, .proc/use_punchbag, target)
		return COMPONENT_SLIME_NO_ATTACK

	if(istype(target, /obj/structure/weightmachine/stacklifter))
		if(isliving(slime.target) || slime.attacked || HAS_TRAIT(slime, TRAIT_SLIME_RABID))
			return
		INVOKE_ASYNC(src, .proc/use_lifter, target)
		return COMPONENT_SLIME_NO_ATTACK

	if(istype(target, /obj/structure/weightmachine/weightlifter))
		if(isliving(slime.target) || slime.attacked || HAS_TRAIT(slime, TRAIT_SLIME_RABID))
			return
		INVOKE_ASYNC(src, .proc/use_bench, target)
		return COMPONENT_SLIME_NO_ATTACK

	if(!fist_out || !ismovable(target))
		return

	var/atom/movable/movable_target = target
	if(movable_target.anchored)
		return

	if(!next_move_type)
		if(!prob(ADAMANTINE_SLIME_RANDOM_ATTACK))
			return
		next_move_type = pick(ADAMANTINE_SLIME_MOVE_SLAM, ADAMANTINE_SLIME_MOVE_SUPLEX, ADAMANTINE_SLIME_MOVE_GROUND_STRIKE)

	switch(next_move_type)
		if(ADAMANTINE_SLIME_MOVE_SLAM)
			next_move_type = null
			INVOKE_ASYNC(src, .proc/slam_attack, movable_target)
			return COMPONENT_SLIME_NO_ATTACK
		if(ADAMANTINE_SLIME_MOVE_SUPLEX)
			var/turf/center_turf = get_turf(slime)
			var/list/suplex_turfs = RANGE_TURFS(1, center_turf)
			suplex_turfs -= center_turf
			suplex_turfs -= get_turf(target)
			for(var/turf/suplex in suplex_turfs)
				if(suplex.is_blocked_turf_ignore_climbable())
					suplex_turfs -= suplex
			if(!LAZYLEN(suplex_turfs))
				return
			next_move_type = null
			INVOKE_ASYNC(src, .proc/suplex_attack, movable_target, suplex_turfs)
			return COMPONENT_SLIME_NO_ATTACK
		if(ADAMANTINE_SLIME_MOVE_GROUND_STRIKE)
			INVOKE_ASYNC(src, .proc/ground_strike_attack, movable_target)
			next_move_type = null
			return COMPONENT_SLIME_NO_ATTACK

/datum/slime_color/adamantine/proc/slam_attack(atom/movable/target)
	slime.do_attack_animation(target, ATTACK_EFFECT_SMASH)
	target.visible_message(span_warning("[slime] slams [target], sending [target.p_them()] flying through the air!"), span_userdanger("[slime] slams you, sending you flying through the air!"))
	playsound(target, 'sound/effects/meteorimpact.ogg', 50, TRUE)
	playsound(target, 'sound/effects/bamf.ogg', 75, TRUE)
	var/turf/throwtarget = get_edge_target_turf(target, get_dir(slime, target))
	target.throw_at(throwtarget, 4, 2, slime)
	if(isliving(target))
		var/mob/living/victim = target
		victim.Paralyze(15)
		victim.apply_damage(ADAMANTINE_SLIME_SLAM_DAMAGE * victim.getarmor(type = MELEE), BRUTE)

	if(iscarbon(target))
		shock_target(target)

/datum/slime_color/adamantine/proc/suplex_attack(atom/movable/target, list/suplex_turfs)
	var/turf/suplex_turf = pick(suplex_turfs)
	target.forceMove(suplex_turf)
	playsound(target, 'sound/effects/meteorimpact.ogg', 50, TRUE)
	playsound(target, 'sound/effects/bamf.ogg', 75, TRUE)
	slime.do_attack_animation(target, ATTACK_EFFECT_SMASH)
	target.visible_message(span_warning("[slime] suplexes [target], pinning [target.p_them()] down to the ground!"), span_userdanger("[slime] suplexes you, pinning you down to the ground!"))
	if(isliving(target))
		var/mob/living/victim = target
		victim.Paralyze(25)
		victim.apply_damage(ADAMANTINE_SLIME_SUPLEX_DAMAGE * victim.getarmor(type = MELEE), BRUTE)

	if(iscarbon(target))
		shock_target(target)

/datum/slime_color/adamantine/proc/ground_strike_attack(atom/movable/target)
	playsound(target, 'sound/effects/meteorimpact.ogg', 50, TRUE)
	playsound(target, 'sound/effects/bamf.ogg', 75, TRUE)
	slime.do_attack_animation(target, ATTACK_EFFECT_SMASH)
	slime.visible_message(span_warning("[slime] strikes the ground beneath [target], sending [target.p_them()] and everybody around flying!"))
	var/turf/center_turf = get_turf(target)
	for(var/i in 0 to 2)
		var/list/cascade_turfs = RANGE_TURFS(i, center_turf)
		if(i > 0)
			cascade_turfs -= RANGE_TURFS(i - 1, center_turf)

		for(var/turf/open/cascade_turf in cascade_turfs)
			new /obj/effect/temp_visual/small_smoke/halfsecond(cascade_turf)
			for(var/atom/movable/cascade_victim in cascade_turf)
				if(cascade_victim.anchored || isslime(cascade_victim))
					continue

				INVOKE_ASYNC(src, .proc/up_into_the_air, cascade_victim)
		sleep(3)

/datum/slime_color/adamantine/proc/up_into_the_air(atom/movable/cascade_victim)
	cascade_victim.anchored = TRUE
	ADD_TRAIT(cascade_victim, TRAIT_IMMOBILIZED, XENOBIO_TRAIT)
	if(isliving(cascade_victim))
		var/mob/living/victim = cascade_victim
		victim.Paralyze(17)

	new /obj/effect/temp_visual/item_shadow(get_turf(cascade_victim))
	animate(cascade_victim, pixel_z = 64, time = 15, easing = CUBIC_EASING | EASE_OUT, flags = ANIMATION_PARALLEL)
	to_chat(cascade_victim, span_userdanger("You are launched into the air by [slime]'s attack!"))
	sleep(15)
	animate(cascade_victim, pixel_z = 0, time = 2, easing = LINEAR_EASING, flags = ANIMATION_PARALLEL)
	sleep(2)
	playsound(cascade_victim, 'sound/effects/meteorimpact.ogg', 50, TRUE)
	new /obj/effect/temp_visual/small_smoke/halfsecond(get_turf(cascade_victim))
	if(isliving(cascade_victim))
		var/mob/living/victim = cascade_victim
		victim.apply_damage(ADAMANTINE_SLIME_GROUND_STRIKE_DAMAGE * victim.getarmor(type = MELEE), BRUTE)

/datum/slime_color/adamantine/proc/shock_target(mob/living/carbon/victim)
	if(slime.powerlevel <= 0)
		return

	var/stunprob = slime.powerlevel * 7 + 10  // 17 at level 1, 80 at level 10
	if(!prob(stunprob))
		return

	do_sparks(5, TRUE, victim)
	var/power = slime.powerlevel + rand(0,3)
	victim.Paralyze(power * 2 SECONDS)
	victim.set_timed_status_effect(power * 2 SECONDS, /datum/status_effect/speech/stutter, only_if_higher = TRUE)
	if (prob(stunprob) && slime.powerlevel >= 8)
		victim.adjustFireLoss(slime.powerlevel * rand(6, 10))
	slime.powerlevel -= 3
	if(slime.powerlevel < 0)
		slime.powerlevel = 0

/datum/slime_color/light_pink
	color = "light pink"
	icon_color = "light_pink"
	coretype = /obj/item/slime_extract/light_pink
	slime_tags = SLIME_DISCHARGER_WEAKENED
	environmental_req = "Subject can mind-control whoever it latches onto and requires a host to survive."
	food_types = list(/datum/species/human = 0.8, /datum/species/lizard = 1, /datum/species/moth = 1.2, /datum/species/ethereal = 1.4)
	var/mind_control_timer
	var/mob/living/carbon/human/puppet
	var/mutable_appearance/goop_overlay
	var/full_control = FALSE
	var/mob/living/slime_mind_holder/mind_holder
	var/datum/move_loop/move_loop
	var/obj/item/new_weapon_targeting
	var/list/blacklisted_targets = list()
	var/list/initial_puppet_faction = list()
	var/previous_ai_status = AI_STATUS_ON

/datum/slime_color/light_pink/New(slime)
	. = ..()
	RegisterSignal(slime, COMSIG_SLIME_FEEDON, .proc/start_feeding)
	RegisterSignal(slime, COMSIG_SLIME_FEEDSTOP, .proc/stop_feeding)
	RegisterSignal(slime, COMSIG_SLIME_BUCKLED_AI, .proc/allow_buckled_ai)
	RegisterSignal(slime, COMSIG_SLIME_START_MOVE_LOOP, .proc/start_moveloop)
	RegisterSignal(slime, COMSIG_SLIME_STOP_MOVE_LOOP, .proc/stop_moveloop)
	RegisterSignal(slime, COMSIG_SLIME_CAN_FEEDON, .proc/can_feed)
	RegisterSignal(slime, COMSIG_SLIME_ATTEMPT_SAY, .proc/attempt_say)
	RegisterSignal(slime, COMSIG_SLIME_SET_TARGET, .proc/set_target)
	RegisterSignal(slime, COMSIG_SLIME_ATTACK_TARGET, .proc/attempt_attack)

	blacklisted_targets = typecacheof(list(/obj/machinery/atmospherics/components/unary/vent_pump,
										   /obj/machinery/atmospherics/components/unary/vent_scrubber,
										   /obj/item/giant_slime_plushie,
										   ))

/datum/slime_color/light_pink/remove()
	UnregisterSignal(slime, list(COMSIG_SLIME_FEEDON, COMSIG_SLIME_FEEDSTOP, COMSIG_SLIME_BUCKLED_AI,
								 COMSIG_SLIME_START_MOVE_LOOP, COMSIG_SLIME_STOP_MOVE_LOOP, COMSIG_SLIME_CAN_FEEDON,
								 COMSIG_SLIME_ATTEMPT_SAY, COMSIG_SLIME_SET_TARGET, COMSIG_SLIME_ATTACK_TARGET))

/datum/slime_color/light_pink/Life(delta_time, times_fired)
	. = ..()
	if(slime.buckled && isliving(slime.buckled))
		fitting_environment = TRUE
		if(full_control)
			handle_puppet(delta_time, times_fired)
		return

	fitting_environment = FALSE
	slime.adjustBruteLoss(SLIME_DAMAGE_MED * delta_time * get_passive_damage_modifier())

/datum/slime_color/light_pink/get_attack_cd(atom/attack_target)
	if(full_control)
		if(isliving(attack_target) && HAS_TRAIT(attack_target, TRAIT_CRITICAL_CONDITION))
			return 4.5 SECONDS
		return 0.8 SECONDS
	return ..()

/datum/slime_color/light_pink/proc/handle_puppet(delta_time, times_fired)
	var/best_force = 5
	var/obj/item/main_item = puppet.get_active_held_item()
	var/obj/item/secondary_item = puppet.get_inactive_held_item()
	if(main_item)
		if(secondary_item)
			if(secondary_item.force > max(best_force, main_item.force))
				puppet.swap_hand(puppet.get_inactive_hand_index())
				best_force = secondary_item.force
			else if(main_item.force > best_force)
				best_force = main_item.force
			else
				puppet.drop_all_held_items()
		else
			if(main_item.force > best_force)
				best_force = main_item.force
			else
				puppet.drop_all_held_items()
	else if(secondary_item)
		if(secondary_item.force > best_force)
			best_force = secondary_item.force
			puppet.swap_hand(puppet.get_inactive_hand_index())
		else
			puppet.drop_all_held_items()

	var/obj/item/new_weapon
	var/weapon_range = 7
	if(slime.target && isliving(slime.target))
		weapon_range = 3
	for(var/obj/item/possible_weapon in view(weapon_range, get_turf(puppet)))
		var/actual_force = possible_weapon.force
		var/datum/component/two_handed/wielding = possible_weapon.GetComponent(/datum/component/two_handed)
		if(wielding)
			if(wielding.force_wielded)
				actual_force = wielding.force_wielded
			else if(wielding.force_multiplier)
				actual_force *= wielding.force_multiplier
		else
			var/datum/component/transforming/transforming = possible_weapon.GetComponent(/datum/component/transforming)
			if(transforming)
				actual_force = transforming.force_on
		if(possible_weapon.force <= best_force)
			continue

		if(!get_step_to(puppet, possible_weapon))
			continue

		best_force = actual_force
		new_weapon = possible_weapon

	if(!new_weapon)
		return

	new_weapon_targeting = new_weapon
	slime.set_target(new_weapon_targeting)
	slime.target_patience = 10

/datum/slime_color/light_pink/proc/attempt_attack(datum/source, atom/attack_target)
	SIGNAL_HANDLER

	if(!full_control)
		return

	if(attack_target == new_weapon_targeting)
		var/obj/item/new_weapon = attack_target
		puppet.drop_all_held_items()
		puppet.put_in_active_hand(new_weapon)
		var/datum/component/two_handed/wielding = new_weapon.GetComponent(/datum/component/two_handed)
		if(wielding)
			wielding.wield(puppet)
		else
			var/datum/component/transforming/transforming = new_weapon.GetComponent(/datum/component/transforming)
			if(transforming)
				transforming.set_active(new_weapon)
		stop_moveloop()
		slime.set_target(null)
		return COMPONENT_SLIME_NO_ATTACK

	if(isliving(attack_target) && HAS_TRAIT(attack_target, TRAIT_CRITICAL_CONDITION)) //If target is critted, the slime itself finishes itself and yoinks some nutrition.
		slime.adjust_nutrition(LIGHT_PINK_SLIME_FINISHER_NUTRITION)
		return

	if(isliving(attack_target))
		var/mob/living/victim = attack_target
		var/turf/shove_turf = get_step(attack_target, get_dir(slime, attack_target))
		if(shove_turf.is_blocked_turf() && !victim.IsKnockdown())
			INVOKE_ASYNC(puppet, /mob.proc/UnarmedAttack, attack_target, TRUE, list(RIGHT_CLICK = "1"))
			return COMPONENT_SLIME_NO_ATTACK
		if(victim.IsKnockdown() && !victim.IsParalyzed() && prob(65) && !victim.stat) //Don't want horrible stunlocks
			INVOKE_ASYNC(puppet, /mob.proc/UnarmedAttack, attack_target, TRUE, list(RIGHT_CLICK = "1"))
			return COMPONENT_SLIME_NO_ATTACK

	if(puppet.get_active_held_item())
		var/obj/item/weapon = puppet.get_active_held_item()
		if(weapon.throwforce > weapon.force * 2)
			puppet.throw_mode_on(THROW_MODE_TOGGLE)
			puppet.throw_item(attack_target)
			return COMPONENT_SLIME_NO_ATTACK

		puppet.throw_mode_off(THROW_MODE_TOGGLE)
		INVOKE_ASYNC(weapon, /obj/item.proc/melee_attack_chain, puppet, attack_target)
		return COMPONENT_SLIME_NO_ATTACK

	INVOKE_ASYNC(puppet, /mob.proc/UnarmedAttack, attack_target, TRUE)
	return COMPONENT_SLIME_NO_ATTACK

/datum/slime_color/light_pink/proc/set_target(datum/source, atom/old_target, atom/new_target)
	SIGNAL_HANDLER

	if(puppet && is_type_in_typecache(new_target, blacklisted_targets))
		return COMPONENT_SLIME_NO_SET_TARGET

/datum/slime_color/light_pink/proc/attempt_say(datum/source, to_say)
	SIGNAL_HANDLER

	if(puppet && full_control)
		INVOKE_ASYNC(puppet, /atom/movable.proc/say, to_say)
		return COMPONENT_SLIME_NO_SAY

/datum/slime_color/light_pink/proc/can_feed(datum/source, atom/feed_target)
	SIGNAL_HANDLER

	if(puppet)
		if(isliving(feed_target) && HAS_TRAIT(feed_target, TRAIT_CRITICAL_CONDITION) && COOLDOWN_FINISHED(slime, attack_cd))
			slime.attack_target(feed_target)
		return COMPONENT_SLIME_NO_FEEDON

/datum/slime_color/light_pink/proc/start_feeding(datum/source, atom/target)
	SIGNAL_HANDLER

	if(puppet)
		if(isliving(target) && COOLDOWN_FINISHED(slime, attack_cd))
			slime.attack_target(target)
		return COMPONENT_SLIME_NO_FEEDON

	if(!ishuman(target) || HAS_TRAIT(target, TRAIT_SLIME_RESISTANCE))
		return

	start_puppeteering(target)

/datum/slime_color/light_pink/proc/start_puppeteering(mob/living/carbon/human/new_puppet)
	puppet = new_puppet
	goop_overlay = mutable_appearance('icons/effects/effects.dmi', "light_pink_slime_goop")
	puppet.add_overlay(goop_overlay)
	slime.alpha = 1
	to_chat(puppet, span_userdanger("You feel [slime]'s tendrils entering thgough your mouth and ears and start connecting to your brain!"))
	mind_control_timer = addtimer(CALLBACK(src, .proc/start_control), LIGHT_PINK_SLIME_MIND_CONTROL_TIMER, TIMER_STOPPABLE)
	puppet.overlay_fullscreen("slime_control", /atom/movable/screen/fullscreen/slime_control, 0)

/datum/slime_color/light_pink/proc/stop_feeding(datum/source, atom/target)
	SIGNAL_HANDLER

	if(!isliving(target) || target != puppet) //SOMEHOW
		return

	stop_puppeteering()

/datum/slime_color/light_pink/proc/stop_puppeteering()
	puppet.clear_fullscreen("slime_control")
	puppet.faction = initial_puppet_faction.Copy()
	if(full_control)
		to_chat(mind_holder, span_notice("You feel [slime] losing control over your body as your senses return to you!"))
		if(mind_holder.mind)
			mind_holder.mind.transfer_to(puppet)
		QDEL_NULL(mind_holder)
		stop_moveloop()
		UnregisterSignal(puppet, list(COMSIG_PARENT_ATTACKBY, COMSIG_ATOM_HULK_ATTACK, COMSIG_ATOM_ATTACK_HAND,
									  COMSIG_ATOM_ATTACK_PAW, COMSIG_ATOM_HITBY, COMSIG_ATOM_BULLET_ACT))

	puppet.cut_overlay(goop_overlay)
	QDEL_NULL(goop_overlay)
	full_control = FALSE
	slime.alpha = initial(slime.alpha)
	if(mind_control_timer)
		deltimer(mind_control_timer)
	if(puppet.ai_controller)
		puppet.ai_controller.set_ai_status(previous_ai_status)
	puppet = null

/datum/slime_color/light_pink/proc/start_control()
	full_control = TRUE
	mind_holder = new(puppet, src)
	mind_holder.overlay_fullscreen("slime_control", /atom/movable/screen/fullscreen/slime_control, 0)
	to_chat(puppet, span_userdanger("You feel a terrible headache as your consiousness is being forced out of your body!"))
	puppet.combat_mode = TRUE
	initial_puppet_faction = puppet.faction.Copy()
	puppet.faction = list("slime", "neutral")
	if(puppet.mind)
		puppet.mind.transfer_to(mind_holder)

	if(puppet.ai_controller)
		previous_ai_status = puppet.ai_controller.ai_status
		puppet.ai_controller.set_ai_status(AI_STATUS_OFF)

	RegisterSignal(puppet, COMSIG_PARENT_ATTACKBY, .proc/puppet_parent_attack)
	RegisterSignal(puppet, COMSIG_ATOM_HULK_ATTACK, .proc/puppet_hulk_attack)
	RegisterSignal(puppet, COMSIG_ATOM_ATTACK_HAND, .proc/puppet_hand_attack)
	RegisterSignal(puppet, COMSIG_ATOM_ATTACK_PAW, .proc/puppet_paw_attack)
	RegisterSignal(puppet, COMSIG_ATOM_HITBY, .proc/puppet_throw_impact)
	RegisterSignal(puppet, COMSIG_ATOM_BULLET_ACT, .proc/puppet_bullet_act)

/datum/slime_color/light_pink/proc/puppet_parent_attack(datum/source, obj/item/I, mob/attacker)
	SIGNAL_HANDLER

	if(isslime(attacker))
		return

	slime.attacked += 10
	slime.apply_moodlet(/datum/slime_moodlet/attacked)

/datum/slime_color/light_pink/proc/puppet_hulk_attack(datum/source, mob/attacker)
	SIGNAL_HANDLER

	if(isslime(attacker))
		return

	slime.attacked += 10
	slime.apply_moodlet(/datum/slime_moodlet/attacked)

/datum/slime_color/light_pink/proc/puppet_hand_attack(datum/source, mob/living/attacker)
	SIGNAL_HANDLER

	if(isslime(attacker))
		return

	slime.attacked += 10
	slime.apply_moodlet(/datum/slime_moodlet/attacked)

/datum/slime_color/light_pink/proc/puppet_paw_attack(datum/source, mob/living/attacker)
	SIGNAL_HANDLER

	if(isslime(attacker))
		return

	slime.attacked += 10
	slime.apply_moodlet(/datum/slime_moodlet/attacked)

/datum/slime_color/light_pink/proc/puppet_throw_impact(datum/source, atom/movable/thrown_movable, skipcatch = FALSE, hitpush = TRUE, blocked = FALSE, datum/thrownthing/throwingdatum)
	SIGNAL_HANDLER
	if(istype(thrown_movable, /obj/item))
		var/obj/item/thrown_item = thrown_movable
		var/mob/thrown_by = thrown_item.thrownby?.resolve()

		if(isslime(thrown_by) || !thrown_item.force)
			return

		slime.attacked += 10
		slime.apply_moodlet(/datum/slime_moodlet/attacked)

/datum/slime_color/light_pink/proc/puppet_bullet_act(datum/participant, obj/projectile/proj)
	SIGNAL_HANDLER

	if(isslime(proj.firer))
		return

	slime.attacked += 10
	slime.apply_moodlet(/datum/slime_moodlet/attacked)

/datum/slime_color/light_pink/get_feed_damage_modifier()
	if(slime.health >= slime.maxHealth)
		return 0.025 //About 15 minutes to finish a host off
	else if(slime.health < slime.maxHealth * 0.5)
		return 0.2
	return 0.075

/datum/slime_color/light_pink/proc/allow_buckled_ai()
	if(full_control)
		return COMPONENT_SLIME_ALLOW_BUCKLED_AI

/datum/slime_color/light_pink/proc/start_moveloop(datum/source, atom/move_target)
	if(!full_control || slime.current_loop_target == move_target)
		return

	var/sleeptime = puppet.cached_multiplicative_slowdown + 1.5 //Slower than a normal human
	if(sleeptime <= 0)
		sleeptime = 0

	stop_moveloop()
	slime.current_loop_target = move_target

	move_loop = SSmove_manager.mixed_move(puppet,
										  slime.current_loop_target,
										  sleeptime,
										  repath_delay = 0.5 SECONDS,
										  max_path_length = AI_MAX_PATH_LENGTH,
										  minimum_distance = 1,
										  id = puppet.get_idcard()
										  )

	RegisterSignal(move_loop, COMSIG_PARENT_QDELETING, .proc/loop_ended)

	return COMPONENT_SLIME_NO_MOVE_LOOP_START

/datum/slime_color/light_pink/proc/stop_moveloop()
	qdel(move_loop)
	if(slime.current_loop_target == new_weapon_targeting)
		new_weapon_targeting = null
	slime.current_loop_target = null

/datum/slime_color/light_pink/proc/loop_ended()
	slime.current_loop_target = null
	move_loop = null

/mob/living/slime_mind_holder
	name = "slime mind holder"
	var/mob/living/carbon/body
	var/datum/slime_color/light_pink/color_holder

/mob/living/slime_mind_holder/Initialize(mapload, color_holder)
	if(ishuman(loc))
		body = loc
		name = body.real_name
		src.color_holder = color_holder
	return ..()

/mob/living/slime_mind_holder/Life(delta_time = SSMOBS_DT, times_fired)
	if(QDELETED(body))
		qdel(src)

	return ..()

/mob/living/slime_mind_holder/say(message, bubble_type, list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null, filterproof = null)
	to_chat(src, span_warning("You attempt to speak, but fail to control your body!"))
	return FALSE

/mob/living/slime_mind_holder/emote(act, m_type = null, message = null, intentional = FALSE, force_silence = FALSE)
	return FALSE

/mob/living/slime_mind_holder/resist()
	set name = "Resist"
	set category = "IC"

	changeNext_move(CLICK_CD_RESIST)
	SEND_SIGNAL(src, COMSIG_LIVING_RESIST, src)
	to_chat(src, span_notice("You start resisting [color_holder.slime]'s control."))
	if(!do_after(src, LIGHT_PINK_SLIME_RESIST_TIME, target = body, timed_action_flags = (IGNORE_USER_LOC_CHANGE|IGNORE_TARGET_LOC_CHANGE), extra_checks = CALLBACK(src, .proc/can_resist_control)))
		return
	to_chat(src, span_notice("You break free from [color_holder.slime]'s control!"))
	color_holder.slime.feed_stop(TRUE)

/mob/living/slime_mind_holder/proc/can_resist_control()
	if(QDELETED(color_holder) || color_holder.slime.buckled != body)
		return FALSE
	return TRUE
