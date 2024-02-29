//Basic slime color datum along with grey and rainbow slimes here, other colors are split into files by tiers

/datum/slime_color
	var/color = "error" //I hate bri'ish people, there was C O L O U R everywhere
	var/icon_color //In case we have two or three words as our color
	var/coretype = /obj/item/slime_extract
	var/list/mutations
	var/mutation_modifier = 1
	var/list/food_types = list() //Mob nutrition value is based on their health, while items' is always the same and only depends on the coeff
	var/temperature_modifier = T0C
	var/environmental_req
	var/slime_tags

	var/fitting_environment = TRUE

	var/warpchance = 0 //For bluespace connected slimes
	var/digestion_speed = SLIME_DIGESTION_SPEED

	var/mob/living/simple_animal/slime/slime

/datum/slime_color/New(slime)
	if(!icon_color)
		icon_color = color
	. = ..()
	src.slime = slime
	if(!mutations)
		mutations = list(type, type, type, type)

/datum/slime_color/proc/Life(delta_time, times_fired) //For handling special behavior
	var/turf/our_turf = get_turf(slime)
	if(HAS_TRAIT(our_turf, TRAIT_BLUESPACE_SLIME_FIXATION) && (slime_tags & SLIME_BLUESPACE_CONNECTION))
		if(DT_PROB(warpchance, delta_time))
			slime.visible_message(span_warning("[slime] suddenly starts vibrating as it's being sucked into bluespace!"), span_userdanger("Your severed connection to bluespace causes you to fall through reality!"))
			do_teleport(slime, get_turf(slime), 5, channel = TELEPORT_CHANNEL_BLUESPACE)
			slime.visible_message(span_danger("[slime] appears out of nowhere!"))
			warpchance = 0
		else
			warpchance += SLIME_WARPCHANCE_INCREASE * delta_time

/datum/slime_color/proc/remove()

/datum/slime_color/proc/get_passive_damage_modifier()
	var/damage_mod = 1
	if(slime.accessory)
		damage_mod *= slime.accessory.get_damage_modificator()
	return damage_mod

/datum/slime_color/proc/get_feed_damage_modifier()
	return 1

/datum/slime_color/proc/get_attack_cd(atom/attack_target)
	return 4.5 SECONDS

/datum/slime_color/grey
	color = "grey"
	coretype = /obj/item/slime_extract/grey
	mutations = list(/datum/slime_color/orange, /datum/slime_color/metal, /datum/slime_color/blue, /datum/slime_color/purple)
	food_types = list(/datum/species/monkey = 1)
