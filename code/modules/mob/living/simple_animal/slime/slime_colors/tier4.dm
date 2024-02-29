/datum/slime_color/red
	color = "red"
	coretype = /obj/item/slime_extract/red
	mutations = list(/datum/slime_color/oil = 1)
	slime_tags = SLIME_BZ_IMMUNE | SLIME_WATER_RESISTANCE | SLIME_SOCIAL
	mutation_modifier = 0.5

	environmental_req = "Subject is quite violent and will become rabid when hungry, causing all red slimes around it to also go rabid."

/datum/slime_color/red/Life(delta_time, times_fired)
	. = ..()
	var/datum/gas_mixture/our_mix = slime.loc.return_air()
	var/bz_percentage =0
	if(our_mix.gases[/datum/gas/bz])
		bz_percentage = our_mix.gases[/datum/gas/bz][MOLES] / our_mix.total_moles()

	var/turf/current_turf = get_turf(slime)
	var/slime_turf = FALSE
	if(istype(current_turf, /turf/closed/wall/slime) || istype(current_turf, /turf/open/misc/slime))
		slime_turf = TRUE

	var/stasis = (bz_percentage >= 0.05 && slime.bodytemperature < (temperature_modifier + 100) && !(slime_tags & SLIME_BZ_IMMUNE) && !slime_turf)
	if(stasis)
		slime.powerlevel = 0
		REMOVE_TRAIT(slime, TRAIT_SLIME_RABID, null) //Can be calmed by BZ but not stasis-ed

	if(DT_PROB(65, delta_time) && slime.nutrition > slime.get_hunger_nutrition() + 100) //Even snowflakier because of hunger
		slime.adjust_nutrition(-1 * (1 + slime.is_adult))

	for(var/mob/living/simple_animal/slime/friend in view(5, get_turf(slime)))
		if(friend.slime_color.type != type)
			continue

		if(friend.nutrition <= friend.get_hunger_nutrition() - 200)
			fitting_environment = FALSE
			if(!slime.docile)
				ADD_TRAIT(slime, TRAIT_SLIME_RABID, "red_slime_environmental")
			return

	if(slime.nutrition > slime.get_hunger_nutrition() - 200) //Both we and our friends are happy
		fitting_environment = TRUE
		REMOVE_TRAIT(slime, TRAIT_SLIME_RABID, "red_slime_environmental")
		return

	fitting_environment = FALSE
	if(!slime.docile)
		ADD_TRAIT(slime, TRAIT_SLIME_RABID, "red_slime_environmental")

/datum/slime_color/green
	color = "green"
	coretype = /obj/item/slime_extract/green
	mutations = list(/datum/slime_color/black = 1)
	slime_tags = SLIME_DISCHARGER_WEAKENED | SLIME_ANTISOCIAL
	mutation_modifier = 0.5
	var/mimicking = FALSE

/datum/slime_color/green/New(mob/living/simple_animal/slime/slime)
	. = ..()
	RegisterSignal(slime, COMSIG_SLIME_REGENERATE_ICONS, .proc/can_regenerate_icons)
	RegisterSignal(slime, COMSIG_SLIME_ATTACK_TARGET, .proc/exit_stealth)

/datum/slime_color/green/remove()
	UnregisterSignal(slime, list(COMSIG_SLIME_REGENERATE_ICONS, COMSIG_SLIME_ATTACK_TARGET))

/datum/slime_color/green/Life(delta_time, times_fired)
	. = ..()
	if(slime.accessory && istype(slime.accessory, /obj/item/slime_accessory/demorpher))
		fitting_environment = TRUE
		if(mimicking)
			exit_stealth()
		return

	fitting_environment = FALSE
	slime.adjustBruteLoss(SLIME_DAMAGE_LOW * delta_time * get_passive_damage_modifier())

	if(mimicking)
		if(DT_PROB(GREEN_SLIME_UNMIMICK_CHANCE, delta_time))
			exit_stealth()
		return

	if(DT_PROB(GREEN_SLIME_MIMICK_CHANCE, delta_time))
		var/possible_mimicks = list()

		for(var/mob/living/possible_target in view(GREEN_SLIME_MIMICK_RANGE, get_turf(slime)))
			if(possible_target.alpha > 0 && possible_target.invisibility <= slime.see_invisible) // No funny ghost/ninja slimes
				possible_mimicks[possible_target] = (iscarbon(possible_target) ? GREEN_SLIME_HUMAN_MIMICK_WEIGHT : 1)

		for(var/obj/possible_target in view(GREEN_SLIME_MIMICK_RANGE, get_turf(slime)))
			if(possible_target.alpha > 0 && possible_target.invisibility <= slime.see_invisible && !(possible_target.bound_width > 32 || possible_target.bound_height > 32)) // And no funny walking xenoflora pods
				possible_mimicks[possible_target] = 1

		enter_stealth(pick_weight(possible_mimicks))

/datum/slime_color/green/proc/enter_stealth(atom/target)
	if(mimicking)
		return
	mimicking = TRUE

	slime.visible_message(span_warning("[slime] suddenly twists and changes shape, becoming a copy of [target]!"), \
					span_notice("You twist your body and assume the form of [target]."))
	slime.appearance = target.appearance
	slime.copy_overlays(target)
	slime.alpha = max(slime.alpha, 150)
	slime.transform = initial(slime.transform)
	slime.pixel_y = slime.base_pixel_y
	slime.pixel_x = slime.base_pixel_x

	slime.melee_damage_lower += GREEN_SLIME_MIMICK_DAMAGE_BOOST
	slime.melee_damage_upper += GREEN_SLIME_MIMICK_DAMAGE_BOOST

/datum/slime_color/green/proc/exit_stealth()
	if(!mimicking)
		return
	mimicking = FALSE
	slime.alpha = initial(slime.alpha)
	slime.color = initial(slime.color)
	slime.desc = initial(slime.desc)
	slime.name = initial(slime.name)
	slime.icon = initial(slime.icon)
	slime.regenerate_icons()
	slime.update_name()

	slime.animate_movement = SLIDE_STEPS
	slime.maptext = null

	slime.visible_message(span_warning("[slime] suddenly collapses in on itself, dissolving into a pile of green slime!"), \
					span_notice("You reform to your normal body."))
	//Baseline stats
	slime.melee_damage_lower = initial(slime.melee_damage_lower)
	slime.melee_damage_upper = initial(slime.melee_damage_upper)

/datum/slime_color/green/proc/can_regenerate_icons(datum/source)
	SIGNAL_HANDLER

	if(mimicking)
		return COMPONENT_SLIME_NO_ICON_REGENERATION

/datum/slime_color/pink
	color = "pink"
	coretype = /obj/item/slime_extract/pink
	mutations = list(/datum/slime_color/light_pink  = 1)
	slime_tags = SLIME_BLUESPACE_CONNECTION | SLIME_NO_REQUIREMENT_MOOD_LOSS
	mutation_modifier = 0.5

/datum/slime_color/pink/Life(delta_time, times_fired)
	. = ..()

	if(SLIME_SHOULD_MISBEHAVE(slime, delta_time))
		new /obj/effect/temp_visual/annoyed/slime(get_turf(slime))
		start_hallucinations()

	var/slime_amount = 0
	for(var/mob/living/simple_animal/slime/other_slime in view(3, get_turf(slime)))
		if(other_slime != slime && istype(other_slime.slime_color, type))
			slime_amount += 1

	var/plushie_amount = 0
	for(var/obj/item/giant_slime_plushie/plush in view(3, get_turf(slime)))
		plushie_amount += 1
		if(plushie_amount >= 1 + round(slime_amount / (2 + (slime.accessory && istype(slime.accessory, /obj/item/slime_accessory/friendship_necklace))))) //Friendship necklace lowers requirements
			fitting_environment = TRUE
			return

	plushie_amount = 0
	for(var/obj/item/toy/plush/plush in view(3, get_turf(slime)))
		if(istype(plush, /obj/item/toy/plush/slimeplushie)) //Twice as fun
			plushie_amount += 2
		else
			plushie_amount += 1

		if(plushie_amount >= (PINK_SLIME_PLUSHIE_REQUIREMENT + slime_amount) / (1 + (slime.accessory && istype(slime.accessory, /obj/item/slime_accessory/friendship_necklace))))
			fitting_environment = TRUE
			return

	slime.adjustBruteLoss(SLIME_DAMAGE_LOW * delta_time * get_passive_damage_modifier())
	new /obj/effect/temp_visual/annoyed/slime(get_turf(slime))
	if(DT_PROB(PINK_SLIME_HALLUCINATION_CHANCE, delta_time))
		start_hallucinations()

/datum/slime_color/pink/proc/start_hallucinations()
	for(var/mob/living/carbon/possible_sentient in view(9, get_turf(slime)))
		if(!possible_sentient.client)
			continue

		possible_sentient.apply_status_effect(/datum/status_effect/slime_hallucinations)

/datum/slime_color/gold
	color = "gold"
	coretype = /obj/item/slime_extract/gold
	mutations = list(/datum/slime_color/adamantine = 1)
	slime_tags = SLIME_DISCHARGER_WEAKENED | SLIME_ATTACK_SLIMES | SLIME_WATER_RESISTANCE | SLIME_SOCIAL
	mutation_modifier = 0.5

	environmental_req = "Subject is extremely territorial and will attack other slimes at will or when hungry. Their psychic abilities also allow them to force other creatures to attack their targets along with them."

/datum/slime_color/gold/New(mob/living/simple_animal/slime/slime)
	. = ..()
	RegisterSignal(slime, COMSIG_SLIME_CAN_FEED, .proc/can_feed)
	RegisterSignal(slime, COMSIG_SLIME_ATTACK_TARGET, .proc/recruit_creatures)

/datum/slime_color/gold/remove()
	UnregisterSignal(slime, list(COMSIG_SLIME_CAN_FEED, COMSIG_SLIME_ATTACK_TARGET))

/datum/slime_color/gold/proc/recruit_creatures(datum/source, atom/attack_target)
	SIGNAL_HANDLER

	var/recruit_range = GOLDEN_SLIME_RECRUIT_RANGE
	if(HAS_TRAIT(slime, TRAIT_SLIME_KING))
		recruit_range = GOLDEN_SLIME_KING_RECRUIT_RANGE

	for(var/mob/living/simple_animal/hostile/hostile in view(recruit_range, get_turf(slime)))
		if(hostile.target == attack_target || hostile == attack_target)
			continue

		if(prob(GOLDEN_SLIME_RECRUIT_CREATURE_CHANCE) || HAS_TRAIT(slime, TRAIT_SLIME_KING)) // 100% mind control if you're a king
			hostile.GiveTarget(attack_target)

	for(var/mob/living/simple_animal/slime/other_slime in view(recruit_range, get_turf(slime)))
		if(other_slime.target == attack_target || other_slime == attack_target)
			continue

		if((prob(GOLDEN_SLIME_RECRUIT_SLIME_CHANCE) || HAS_TRAIT(slime, TRAIT_SLIME_KING)) && !HAS_TRAIT(other_slime, TRAIT_SLIME_KING)) // And 0% if the other slime is a king
			other_slime.set_target(attack_target)
			other_slime.set_leader(slime)

/datum/slime_color/gold/proc/can_feed(datum/source, atom/feed_target)
	SIGNAL_HANDLER

	if(!isslime(feed_target))
		return

	var/mob/living/simple_animal/slime/feed_slime = feed_target
	if(!istype(feed_slime.slime_color, type))
		return

	if(slime.nutrition > slime.get_hunger_nutrition() && slime.mood_level > SLIME_MOOD_LEVEL_POUT)
		return COMPONENT_SLIME_NO_FEED
