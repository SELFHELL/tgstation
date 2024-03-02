
/mob/living/simple_animal/xenofauna
	icon = 'icons/mob/xenofauna.dmi'

// Wobble Chicken

/mob/living/simple_animal/xenofauna/wobble_chicken
	name = "\improper wobble chicken"
	desc = "A dark brown chicken with white wings, these birds got their name because of the gelatinous shell on their eggs."
	gender = FEMALE
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	icon_state = "wobble_chicken"
	icon_living = "wobble_chicken"
	icon_dead = "wobble_chicken_dead"
	speak = list("Cluck!","BWAAAAARK BWAK BWAK BWAK!","Bwaak bwak.")
	speak_emote = list("clucks","croons")
	emote_hear = list("clucks.")
	emote_see = list("pecks at the ground.","flaps her wings viciously.")
	density = FALSE
	speak_chance = 2
	turns_per_move = 3
	butcher_results = list(/obj/item/food/meat/slab/chicken/wobble = 2)
	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "gently pushes aside"
	response_disarm_simple = "gently push aside"
	response_harm_continuous = "kicks"
	response_harm_simple = "kick"
	attack_verb_continuous = "kicks"
	attack_verb_simple = "kick"
	health = 25
	maxHealth = 25
	pass_flags = PASSTABLE | PASSMOB
	mob_size = MOB_SIZE_SMALL
	mob_spawnable_type = FRIENDLY_SPAWN
	footstep_type = FOOTSTEP_MOB_CLAW
	minbodytemp = T0C + 20
	maxbodytemp = T0C + 160
	var/egg_layer = TRUE

/mob/living/simple_animal/xenofauna/wobble_chicken/Initialize(mapload)
	. = ..()
	add_cell_sample()
	if(egg_layer)
		AddComponent(/datum/component/egg_layer,\
			/obj/item/food/wobble_egg,\
			list(/obj/item/food/xenoflora/broombush),\
			feed_messages = list(span_notice("[src] clucks happily.")),\
			lay_messages = EGG_LAYING_MESSAGES,\
			eggs_left = 0,\
			eggs_added_from_eating = rand(1, 4),\
			max_eggs_held = 8,\
			egg_laid_callback = CALLBACK(src, .proc/egg_laid)\
		)

/mob/living/simple_animal/xenofauna/wobble_chicken/Life(delta_time, times_fired)
	. = ..()
	handle_slimes()

/mob/living/simple_animal/xenofauna/wobble_chicken/proc/handle_slimes()
	var/mob/living/simple_animal/slime/danger
	for(var/mob/living/simple_animal/slime/slime in view(6, src))
		if(type in slime.slime_color.food_types)
			danger = slime
			break

	if(!danger)
		SSmove_manager.stop_looping(src)
		return

	SSmove_manager.move_away(src, danger)

/mob/living/simple_animal/xenofauna/wobble_chicken/proc/egg_laid(obj/item/egg)
	var/chicken_count = 0
	for(var/mob/living/simple_animal/xenofauna/wobble_chicken/chicken in view(5, src))
		if(istype(chicken))
			chicken_count += 1

	for(var/obj/item/food/wobble_egg/future_chicken in view(5, src))
		if(istype(future_chicken))
			chicken_count += 1

	if(chicken_count > 5 || prob(20))
		STOP_PROCESSING(SSobj, egg)

/mob/living/simple_animal/xenofauna/wobble_chicken/add_cell_sample()
	AddElement(/datum/element/swabable, CELL_LINE_TABLE_CHICKEN, CELL_VIRUS_TABLE_GENERIC_MOB, 1, 5)

/obj/item/food/wobble_egg
	name = "wobble egg"
	desc = "A dark brown egg with white spots and an unusually soft gelatinous shell."
	icon_state = "wobble_egg"
	food_reagents = list(/datum/reagent/consumable/eggyolk = 4, /datum/reagent/consumable/eggwhite = 8)
	foodtypes = MEAT
	w_class = WEIGHT_CLASS_SMALL
	ant_attracting = FALSE
	decomp_type = /obj/item/food/wobble_egg/rotten
	decomp_req_handle = TRUE
	var/no_chick = FALSE
	var/amount_grown = 0

/obj/item/food/wobble_egg/Initialize(mapload)
	. = ..()
	if(!no_chick)
		START_PROCESSING(SSobj, src)

/obj/item/food/wobble_egg/process(delta_time)
	if(no_chick)
		STOP_PROCESSING(SSobj, src)

	var/chicken_count = 0
	for(var/mob/living/simple_animal/xenofauna/wobble_chicken/chicken in view(5, src))
		chicken_count += 1

	for(var/obj/item/food/wobble_egg/egg in view(5, src))
		chicken_count += 1

	if(chicken_count > 5)
		return

	var/turf/our_turf = get_turf(src)
	var/datum/gas_mixture/our_mix = our_turf.return_air()
	if(our_mix?.temperature <= T0C+40)
		return

	amount_grown += rand(1,2) * delta_time
	if(amount_grown >= 200)
		visible_message(span_notice("[src] hatches with a quiet cracking sound."))
		new /mob/living/simple_animal/xenofauna/wobble_chicken/chick(get_turf(src))
		STOP_PROCESSING(SSobj, src)
		qdel(src)

/obj/item/food/wobble_egg/rotten
	name = "rotten wobble egg"
	desc = "An unhealthy-looking wobble egg with it's shell turning yellow."
	icon_state = "wobble_egg_rotten"
	no_chick = TRUE

/obj/item/food/wobble_egg/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if (..())
		return

	var/turf/hit_turf = get_turf(hit_atom)
	new /obj/effect/decal/cleanable/food/egg_smudge(hit_turf)
	if(prob(12.5 + (throwingdatum.gentle * 37.5)) && !no_chick)
		new /mob/living/simple_animal/xenofauna/wobble_chicken/chick(hit_turf)

	reagents.expose(hit_atom, TOUCH)
	qdel(src)

/mob/living/simple_animal/xenofauna/wobble_chicken/chick
	name = "\improper wobble chick"
	desc = "Adorable! They make such a racket though."
	icon_state = "wobble_chick"
	icon_living = "wobble_chick"
	icon_dead = "wobble_chick_dead"
	icon_gib = "chick_gib"
	speak = list("Cherp.","Cherp?","Chirrup.","Cheep!")
	speak_emote = list("cheeps")
	emote_hear = list("cheeps.")
	emote_see = list("pecks at the ground.","flaps her tiny wings.")

	health = 15
	maxHealth = 15
	pass_flags = PASSTABLE | PASSGRILLE | PASSMOB
	mob_size = MOB_SIZE_TINY

	egg_layer = FALSE
	var/amount_grown = 0

/mob/living/simple_animal/xenofauna/wobble_chicken/chick/Initialize(mapload)
	. = ..()
	pixel_x = base_pixel_x + rand(-6, 6)
	pixel_y = base_pixel_y + rand(0, 10)

/mob/living/simple_animal/xenofauna/wobble_chicken/chick/Life(delta_time = SSMOBS_DT, times_fired)
	. =..()
	if(!.)
		return
	if(!stat && !ckey)
		amount_grown += rand(0.5, 1) * delta_time
		if(amount_grown >= 100)
			new /mob/living/simple_animal/xenofauna/wobble_chicken(src.loc)
			qdel(src)

/obj/item/food/meat/slab/chicken/wobble
	name = "wobble chicken meat"
	icon_state = "wobble_meat"
	desc = "A slab of raw wobble chicken. Remember to wash your hands!"

/mob/living/simple_animal/xenofauna/greeblefly
	name = "greeblefly"
	desc = "A giant fly with a trunk and a big glowing butt."
	icon_state = "greeblefly"
	icon_living = "greeblefly"
	icon_dead = "greeblefly-dead"
	speak_emote = list("buzzes")
	emote_hear = list("buzzes")
	turns_per_move = 2
	response_help_continuous = "shoos"
	response_help_simple = "shoo"
	response_disarm_continuous = "swats away"
	response_disarm_simple = "swat away"
	response_harm_continuous = "squashes"
	response_harm_simple = "squash"
	maxHealth = 15
	health = 15
	pass_flags = PASSTABLE | PASSGRILLE | PASSMOB
	density = FALSE
	mob_size = MOB_SIZE_TINY
	mob_biotypes = MOB_ORGANIC|MOB_BUG
	can_be_held = TRUE
	held_w_class = WEIGHT_CLASS_TINY
	del_on_death = 1
	light_power = 0.12
	light_range = 1
	light_color = "#92FF00"
	maxbodytemp = T0C + 120

/mob/living/simple_animal/xenofauna/greeblefly/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_VENTCRAWLER_ALWAYS, INNATE_TRAIT)
	AddElement(/datum/element/simple_flying)
	AddComponent(/datum/component/clickbox, x_offset = -2, y_offset = -2)
	AddComponent(/datum/component/swarming)
	add_overlay(emissive_appearance(icon, "greeblefly-emissive", alpha = src.alpha))

/mob/living/simple_animal/xenofauna/greeblefly/mob_pickup(mob/living/user)
	if(flags_1 & HOLOGRAM_1)
		return
	var/obj/item/clothing/head/mob_holder/destructible/holder = new(get_turf(src), src, held_state, head_icon, held_lh, held_rh, worn_slot_flags)
	holder.AddComponent(/datum/component/edible, list(/datum/reagent/consumable/nutriment = 5), null, RAW | MEAT | GROSS | BUGS, 10, 0, list("grass"), null, 10)
	user.visible_message(span_warning("[user] scoops up [src]!"))
	user.put_in_hands(holder)

/mob/living/simple_animal/xenofauna/greeblefly/death(gibbed)
	if((flags_1 & HOLOGRAM_1))
		return ..()
	var/obj/item/trash/greeblefly/snack = new(loc)
	snack.pixel_x = pixel_x
	snack.pixel_y = pixel_y
	return ..()

/obj/item/trash/greeblefly
	name = "greeblefly"
	desc = "Crunchy, but no longer buzzy."
	icon = 'icons/mob/xenofauna.dmi'
	icon_state = "greeblefly-dead"

/obj/item/trash/greeblefly/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/edible, list(/datum/reagent/consumable/nutriment = 5), null, RAW | MEAT | GROSS | BUGS, 10, 0, list("grass"), null, 10)
