/datum/slime_color/purple
	color = "purple"
	coretype = /obj/item/slime_extract/purple
	mutations = list(/datum/slime_color/dark_blue = 1, /datum/slime_color/dark_purple = 1, /datum/slime_color/green = 1)
	food_types = list(/obj/item/food/xenoflora/broombush = 0.75)
	slime_tags = SLIME_ATTACK_SLIMES | SLIME_SOCIAL

	environmental_req = "Subject requires N2O in the atmosphere and is capable of slowly healing other slimes."

/datum/slime_color/purple/New(mob/living/simple_animal/slime/slime)
	. = ..()
	RegisterSignal(slime, COMSIG_SLIME_CAN_FEED, .proc/can_feed)
	RegisterSignal(slime, COMSIG_SLIME_ATTACK_TARGET, .proc/attempt_heal)

/datum/slime_color/purple/remove()
	UnregisterSignal(slime, list(COMSIG_SLIME_CAN_FEED, COMSIG_SLIME_ATTACK_TARGET))

/datum/slime_color/purple/proc/can_feed(datum/source, atom/feed_target)
	SIGNAL_HANDLER

	if(!isslime(feed_target))
		return

	var/mob/living/simple_animal/slime/heal_slime
	if(heal_slime.health >= heal_slime.maxHealth || heal_slime.docile || fitting_environment)
		return COMPONENT_SLIME_NO_FEED

	if(heal_slime == src)
		return COMPONENT_SLIME_NO_FEED

/datum/slime_color/purple/proc/attempt_heal(datum/source, atom/attack_target)
	SIGNAL_HANDLER

	if(!isslime(attack_target))
		return

	var/mob/living/simple_animal/slime/heal_slime = attack_target

	if(heal_slime.health >= heal_slime.maxHealth)
		return COMPONENT_SLIME_NO_ATTACK

	new /obj/effect/temp_visual/heal(get_turf(heal_slime), "#d737ff")
	heal_slime.adjustBruteLoss(PURPLE_SLIME_HEALING)
	if(prob(PURPLE_SLIME_RABID_INFLICTION))
		ADD_TRAIT(heal_slime, TRAIT_SLIME_RABID, "purple_slime_healing")

/datum/slime_color/purple/Life(delta_time, times_fired)
	. = ..()
	var/datum/gas_mixture/our_mix = slime.loc.return_air()
	if(our_mix.gases[/datum/gas/nitrous_oxide] && our_mix.gases[/datum/gas/nitrous_oxide][MOLES] > PURPLE_SLIME_N2O_REQUIRED)
		REMOVE_TRAIT(slime, TRAIT_SLIME_RABID, "purple_slime_environmental")
		fitting_environment = TRUE
		return

	slime.adjustBruteLoss(SLIME_DAMAGE_HIGH * delta_time * get_passive_damage_modifier())
	if(!slime.docile)
		ADD_TRAIT(slime, TRAIT_SLIME_RABID, "purple_slime_environmental")
	fitting_environment = FALSE

/datum/slime_color/blue
	color = "blue"
	coretype = /obj/item/slime_extract/blue
	mutations = list(/datum/slime_color/dark_blue = 1, /datum/slime_color/silver = 1, /datum/slime_color/pink = 1)
	temperature_modifier = T0C - 40
	food_types = list(/obj/item/food/xenoflora/cubomelon = 3, /obj/item/food/xenoflora/cubomelon_slice = 0.5)
	slime_tags = SLIME_DISCHARGER_WEAKENED | SLIME_WATER_IMMUNITY

	environmental_req = "Subject requires low temperatures ranging from -40° to -10° Celsius."

/datum/slime_color/blue/New(mob/living/simple_animal/slime/slime)
	. = ..()
	RegisterSignal(slime, COMSIG_SLIME_DIGESTED, .proc/finished_digesting)

/datum/slime_color/blue/remove()
	UnregisterSignal(slime, COMSIG_SLIME_DIGESTED)

/datum/slime_color/blue/Life(delta_time, times_fired)
	. = ..()
	var/datum/gas_mixture/our_mix = slime.loc.return_air()
	if(our_mix?.temperature <= BLUE_SLIME_DANGEROUS_TEMP)
		fitting_environment = TRUE
		return

	slime.adjustBruteLoss(SLIME_DAMAGE_LOW * delta_time * get_passive_damage_modifier())
	fitting_environment = FALSE

/datum/slime_color/blue/proc/finished_digesting(atom/target)
	var/datum/gas_mixture/our_mix = slime.loc.return_air()
	our_mix.assert_gas(/datum/gas/water_vapor)
	our_mix.gases[/datum/gas/water_vapor][MOLES] += BLUE_SLIME_PUFF_AMOUNT

/datum/slime_color/metal
	color = "metal"
	coretype = /obj/item/slime_extract/metal
	mutations = list(/datum/slime_color/yellow = 1, /datum/slime_color/silver = 1, /datum/slime_color/gold = 1)
	food_types = list(/mob/living/basic/cockroach/rockroach = 1, /obj/item/rockroach_shell = 0.75)
	environmental_req = "Subject requires CO2 in the atmosphere."
	digestion_speed = SLIME_DIGESTION_SPEED * 2

/datum/slime_color/metal/New(slime)
	. = ..()
	RegisterSignal(slime, COMSIG_SLIME_FEEDON, .proc/start_feeding)

/datum/slime_color/metal/remove()
	UnregisterSignal(slime, COMSIG_SLIME_FEEDON)

/datum/slime_color/metal/Life(delta_time, times_fired)
	. = ..()
	var/datum/gas_mixture/our_mix = slime.loc.return_air()
	if(our_mix.gases[/datum/gas/carbon_dioxide] && our_mix.gases[/datum/gas/carbon_dioxide][MOLES] > METAL_SLIME_CO2_REQUIRED)
		fitting_environment = TRUE
		return

	slime.adjustBruteLoss(SLIME_DAMAGE_LOW * delta_time * get_passive_damage_modifier())
	fitting_environment = FALSE

/datum/slime_color/metal/proc/start_feeding(datum/source, atom/target) //Metals and oranges have this code so they gobble their victims up instead of buckling to them(imagine buckling to a cockroach or a fucking fly)
	SIGNAL_HANDLER

	if(!istype(target, /mob/living/basic/cockroach/rockroach))
		return

	INVOKE_ASYNC(slime, /mob/living/simple_animal/slime.proc/attack_target, target)
	return COMPONENT_SLIME_NO_FEEDON

/datum/slime_color/orange
	color = "orange"
	coretype = /obj/item/slime_extract/orange
	mutations = list(/datum/slime_color/yellow = 1, /datum/slime_color/dark_purple = 1, /datum/slime_color/red = 1)
	food_types = list(/mob/living/simple_animal/xenofauna/greeblefly = 1, /obj/item/trash/greeblefly = 0.33) //Flies are in swarms so they give less nutrition.
	environmental_req = "Subject requires temperatures higher than 60° Celsius."
	slime_tags = SLIME_HOT_LOVING
	digestion_speed = SLIME_DIGESTION_SPEED * 2

/datum/slime_color/orange/New(slime)
	. = ..()
	RegisterSignal(slime, COMSIG_SLIME_FEEDON, .proc/start_feeding)

/datum/slime_color/orange/remove()
	UnregisterSignal(slime, COMSIG_SLIME_FEEDON)

/datum/slime_color/orange/Life(delta_time, times_fired)
	. = ..()
	var/turf/our_turf = get_turf(slime)
	var/datum/gas_mixture/our_mix = slime.loc.return_air()
	if(our_mix?.temperature >= ORANGE_SLIME_UNHAPPY_TEMP)
		fitting_environment = TRUE
		return

	var/hotspot_modifier = 1
	if(locate(/obj/effect/hotspot) in our_turf)
		hotspot_modifier = HOT_SLIME_HOTSPOT_DAMAGE_MODIFIER

	slime.adjust_nutrition(-2 * delta_time * hotspot_modifier * get_passive_damage_modifier())
	fitting_environment = FALSE

	if(our_mix?.temperature >= ORANGE_SLIME_DANGEROUS_TEMP)
		return

	slime.adjustBruteLoss(SLIME_DAMAGE_MED * delta_time * hotspot_modifier * get_passive_damage_modifier())

/datum/slime_color/orange/proc/start_feeding(datum/source, atom/target) //Metals and oranges have this code so they gobble their victims up instead of buckling to them(imagine buckling to a cockroach or a fucking fly)
	SIGNAL_HANDLER

	if(!istype(target, /mob/living/simple_animal/xenofauna/greeblefly))
		return

	INVOKE_ASYNC(slime, /mob/living/simple_animal/slime.proc/attack_target, target)
	return COMPONENT_SLIME_NO_FEEDON
