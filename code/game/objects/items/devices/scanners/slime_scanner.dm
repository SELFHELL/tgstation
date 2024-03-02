/obj/item/slime_scanner
	name = "slime scanner"
	desc = "A device that analyzes a slime's internal composition and measures its stats."
	icon = 'icons/obj/devices/scanner.dmi'
	icon_state = "slime"
	inhand_icon_state = "analyzer"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	obj_flags = CONDUCTS_ELECTRICITY
	throwforce = 0
	throw_speed = 3
	throw_range = 7
	custom_materials = list(/datum/material/iron=SMALL_MATERIAL_AMOUNT*0.30, /datum/material/glass=SMALL_MATERIAL_AMOUNT * 0.20)
	var/advanced = FALSE //you dont get the nice stuff

/obj/item/slime_scanner/attack(mob/living/M, mob/living/user)
	if(user.stat || !user.can_read(src) || user.is_blind())
		return
	if (!isslime(M))
		to_chat(user, span_warning("This device can only scan slimes!"))
		return
	var/mob/living/simple_animal/slime/T = M
	slime_scan(T, user, advanced)
	flick("[initial(icon_state)]-scan", src)

/obj/item/slime_scanner/advanced
	name = "advanced slime scanner"
	desc = "An advanced version of a slime scanner, capable of precise measurements and ranged scans."
	icon_state = "slime_adv"
	advanced = TRUE

/obj/item/slime_scanner/advanced/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(target.Adjacent(user))
		return

	if(user.stat || user.is_blind())
		return

	if (!isslime(target))
		to_chat(user, span_warning("This device can only scan slimes!"))
		return

	var/mob/living/simple_animal/slime/slime = target
	slime_scan(slime, user, advanced)
	flick("[initial(icon_state)]-scan", src)

/proc/slime_scan(mob/living/simple_animal/slime/slime, mob/living/user, advanced = FALSE)
	var/to_render = "========================\
					\n<b>Slime scan results:</b>\
					\n[span_notice("[capitalize(slime.slime_color.color)] [slime.is_adult ? "adult" : "baby"] slime")]\
					\nNutrition: [slime.nutrition]/[slime.get_max_nutrition()]"
	if (slime.nutrition < slime.get_starve_nutrition())
		to_render += "\n[span_warning("Warning: slime is starving!")]"
	else if (slime.nutrition < slime.get_hunger_nutrition())
		to_render += "\n[span_warning("Warning: slime is hungry")]"
	to_render += "\nElectric change strength: [slime.powerlevel]\nHealth: [round(slime.health / slime.maxHealth, 0.01) * 100]%"
	if (!LAZYLEN(slime.slime_color.mutations))
		to_render += "\nThis slime does not evolve any further."
	else
		var/mutations_text = ""
		for(var/possible_mutation_type in slime.slime_color.mutations)
			var/datum/slime_color/possible_mutation = possible_mutation_type
			if(LAZYLEN(mutations_text))
				mutations_text = "[mutations_text], "
			var/muta_chance = ""
			if(slime.slime_color.mutations[possible_mutation_type] != 1)
				muta_chance = "(x[slime.slime_color.mutations[possible_mutation_type]])"
			mutations_text = "[mutations_text][initial(possible_mutation.color)][muta_chance]"
		to_render += "\nPossible mutations: [mutations_text]"
		if(advanced)
			to_render += "\n Genetic instability: [slime.mutation_chance * slime.slime_color.mutation_modifier] % chance of mutation on splitting"

	if (slime.cores > 1 && advanced)
		to_render += "\nMultiple cores detected"
	if(slime.slime_color.food_types)
		to_render += "\n Prefered food types:"
		for(var/food_type in slime.slime_color.food_types)
			var/atom/food = food_type
			to_render += "\n [icon2html(icon(initial(food.icon), initial(food.icon_state)), user)] [initial(food.name)]"
	to_render += "\nGrowth progress: [slime.amount_grown]/[SLIME_EVOLUTION_THRESHOLD]"
	to_chat(user, to_render + "\n========================")
