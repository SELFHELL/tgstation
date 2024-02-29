/datum/slime_color/dark_blue
	color = "dark blue"
	icon_color = "dark_blue"
	coretype = /obj/item/slime_extract/dark_blue
	mutations = list(/datum/slime_color/blue = 1, /datum/slime_color/purple = 1, /datum/slime_color/cerulean = 2)
	temperature_modifier = T0C - 60 //You can put these together with blue slimes to skip water vapor transfer step
	slime_tags = SLIME_DISCHARGER_WEAKENED | SLIME_WATER_IMMUNITY
	environmental_req = "Subject requires water vapour to prevent damage and core loss."
	var/core_lose = 0

/datum/slime_color/dark_blue/Life(delta_time, times_fired)
	. = ..()
	var/datum/gas_mixture/our_mix = slime.loc.return_air()
	if(our_mix?.temperature <= DARK_BLUE_SLIME_DANGEROUS_TEMP && our_mix.gases[/datum/gas/water_vapor] && our_mix.gases[/datum/gas/water_vapor][MOLES] > DARK_BLUE_SLIME_VAPOR_REQUIRED)
		fitting_environment = TRUE
		core_lose = 0
		return

	slime.adjustBruteLoss(SLIME_DAMAGE_MED * delta_time * get_passive_damage_modifier())
	fitting_environment = FALSE
	if(slime.cores > 0)
		core_lose += 1
		if(core_lose >= DARK_BLUE_SLIME_CORE_LOSE)
			slime.cores -= 1
			core_lose = 0
	else
		core_lose = 0

/datum/slime_color/dark_purple
	color = "dark purple"
	icon_color = "dark_purple"
	coretype = /obj/item/slime_extract/dark_purple
	mutations = list(/datum/slime_color/purple = 1, /datum/slime_color/orange = 1, /datum/slime_color/sepia = 2)
	slime_tags = SLIME_DISCHARGER_WEAKENED

	environmental_req = "Subject requires plasma to function and will react violently if any oxygen is present in the air."

/datum/slime_color/dark_purple/Life(delta_time, times_fired)
	. = ..()
	var/turf/our_turf = get_turf(slime)
	var/datum/gas_mixture/our_mix = slime.loc.return_air()

	if(SLIME_SHOULD_MISBEHAVE(slime, delta_time))
		our_turf.atmos_spawn_air("plasma=10")
		our_turf.hotspot_expose(1000, 5)

	if(our_mix.gases[/datum/gas/plasma] && our_mix.gases[/datum/gas/plasma][MOLES] > DARK_PURPLE_SLIME_PLASMA_REQUIRED && (!our_mix.gases[/datum/gas/oxygen] || our_mix.gases[/datum/gas/oxygen][MOLES] < DARK_PURPLE_SLIME_OXYGEN_MAXIMUM))
		fitting_environment = TRUE
		return

	slime.adjustBruteLoss(SLIME_DAMAGE_HIGH * delta_time * get_passive_damage_modifier())
	fitting_environment = FALSE
	if(DT_PROB(DARK_PURPLE_SLIME_PUFF_PROBABILITY, delta_time))
		our_turf.atmos_spawn_air("plasma=10")
		our_turf.hotspot_expose(1000, 5)

/datum/slime_color/silver
	color = "silver"
	coretype = /obj/item/slime_extract/silver
	mutations = list(/datum/slime_color/blue = 1, /datum/slime_color/metal = 1, /datum/slime_color/pyrite = 2)

	environmental_req = "Subject's vacuole is unstable, making it will always seek for food regardless of it's size and nutrition. Vacuole stabilizators required to avoid implosion."

/datum/slime_color/silver/New(mob/living/simple_animal/slime/slime)
	. = ..()
	slime.nutrition_control = FALSE

/datum/slime_color/silver/remove()
	slime.nutrition_control = initial(slime.nutrition_control)

/datum/slime_color/silver/Life(delta_time, times_fired)
	. = ..()
	for(var/obj/machinery/xenobio_device/vacuole_stabilizer/stabilizer in range(3, get_turf(slime)))
		if(stabilizer.on)
			fitting_environment = TRUE
			return

	fitting_environment = FALSE

	if(DT_PROB(SILVER_SLIME_IMPLODE_PROB, delta_time)) //You should consider putting a stabilizer into the cold room
		slime.visible_message(span_danger("[slime]'s vacuole implodes, tearing it apart into a few small blorbies!"))
		for(var/i = 1 to rand(2, 4))
			new /mob/living/simple_animal/hostile/slime_blorbie(get_turf(slime))
		playsound(get_turf(slime), 'sound/effects/meatslap.ogg', 100)
		qdel(slime)

/datum/slime_color/yellow
	color = "yellow"
	coretype = /obj/item/slime_extract/yellow
	mutations = list(/datum/slime_color/orange = 1, /datum/slime_color/metal = 1, /datum/slime_color/bluespace = 2)
	food_types = list(/mob/living/simple_animal/xenofauna/wobble_chicken = 6, /mob/living/simple_animal/xenofauna/wobble_chicken/chick = 6, /obj/item/food/wobble_egg = 1, /obj/item/food/meat/slab/chicken/wobble = 1)
	slime_tags = SLIME_ANTISOCIAL
	environmental_req = "Subject will create beams of lightning once fully charged. To safely discharge it you'll need a slime discharger."

/datum/slime_color/yellow/New(mob/living/simple_animal/slime/slime)
	. = ..()
	ADD_TRAIT(slime, TRAIT_SHOCKIMMUNE, ROUNDSTART_TRAIT)
	ADD_TRAIT(slime, TRAIT_TESLA_SHOCKIMMUNE, ROUNDSTART_TRAIT)

/datum/slime_color/yellow/remove()
	REMOVE_TRAIT(slime, TRAIT_SHOCKIMMUNE, ROUNDSTART_TRAIT)
	REMOVE_TRAIT(slime, TRAIT_TESLA_SHOCKIMMUNE, ROUNDSTART_TRAIT)

/datum/slime_color/yellow/Life(delta_time, times_fired)
	. = ..()
	fitting_environment = FALSE
	var/our_discharger

	for(var/obj/machinery/power/energy_accumulator/slime_discharger/discharger in range(2, get_turf(slime)))
		if(istype(discharger) && discharger.on)
			fitting_environment = TRUE
			our_discharger = discharger
			break

	if(slime.powerlevel >= 5 && DT_PROB(slime.powerlevel * YELLOW_SLIME_ZAP_PROB, delta_time))
		slime.visible_message(span_danger("[slime] overcharges, sending out arcs of lightning!"))

		if(our_discharger)
			slime.powerlevel = round(slime.powerlevel / 2)
			slime.Beam(our_discharger, icon_state="lightning[rand(1,12)]", time = 5)
			return

		tesla_zap(slime, slime.powerlevel * 2, YELLOW_SLIME_ZAP_POWER * (slime.powerlevel - 2), ZAP_MOB_DAMAGE | ZAP_OBJ_DAMAGE)
		var/datum/effect_system/spark_spread/sparks = new /datum/effect_system/spark_spread
		sparks.set_up(1, 1, src)
		sparks.start()
		slime.powerlevel -= 1
		slime.adjustBruteLoss(YELLOW_SLIME_DISCHARGE_DAMAGE)
