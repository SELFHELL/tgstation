/// Slime Extracts ///

/obj/item/slime_extract
	name = "slime extract"
	desc = "Goo extracted from a slime. Legends claim these to have \"magical powers\"."
	icon = 'icons/obj/xenobiology/slime_extracts.dmi'
	icon_state = "grey"
	force = 0
	w_class = WEIGHT_CLASS_TINY
	throwforce = 0
	throw_speed = 3
	throw_range = 6
	grind_results = list()
	var/uses = 1 ///uses before it goes inert
	var/tier = 1
	var/list/react_reagents = list()
	var/activated = FALSE
	var/attached_gold_core = FALSE
	var/jelly_color
	var/use_types = NONE
	var/coremeister_description = ""

/obj/item/slime_extract/proc/activate()

/obj/item/slime_extract/proc/use_up()
	if(activated)
		return
	name = "used [name]"
	desc += " This extract has been used up."
	add_atom_colour(color_matrix_saturation(0.85), FIXED_COLOUR_PRIORITY)

/obj/item/slime_extract/examine(mob/user)
	. = ..()
	if(uses > 1)
		. += "It has [uses] uses remaining."

/obj/item/slime_extract/Initialize(mapload)
	. = ..()
	create_reagents(100, INJECTABLE | DRAWABLE)

/obj/item/slime_extract/on_grind()
	. = ..()
	if(uses || activated)
		grind_results[/datum/reagent/toxin/slime_jelly] = 20

/obj/item/slime_extract/afterattack(atom/target, mob/living/user, proximity_flag)
	if(!proximity_flag)
		return ..()

	if(isjellyperson(user) && user.zone_selected == BODY_ZONE_PRECISE_MOUTH && uses > 0 && !activated)
		attempt_consume(user)
		return

	if(!target.is_open_container())
		return ..()

	var/datum/reagents/target_reagents = target.reagents
	if(target_reagents.trans_to(src, reagents.maximum_volume - reagents.total_volume))
		to_chat(user, span_notice("You dip [src] into [target]."))
		return

	if(!target_reagents.total_volume)
		to_chat(user, span_warning("[target] is empty!"))
	else
		to_chat(user, span_warning("[src] is full!"))

/obj/item/slime_extract/proc/attempt_consume(mob/living/carbon/eater)
	var/covered = ""
	if(eater.is_mouth_covered(head_only = 1))
		covered = "headgear"
	else if(eater.is_mouth_covered(mask_only = 1))
		covered = "mask"

	if(covered)
		to_chat(eater, span_warning("You have to remove your [covered] first!"))
		return

	if(!do_after(eater, 2 SECONDS, src, IGNORE_USER_LOC_CHANGE | IGNORE_TARGET_LOC_CHANGE))
		return

	var/datum/species/jelly/jelly_species = eater.dna.species
	jelly_species.consume_extract(eater, src)

/obj/item/slime_extract/proc/coremeister_life(mob/living/carbon/human/jellyman, datum/species/jelly/coremeister/species, delta_time, times_fired)

/obj/item/slime_extract/proc/coremeister_chosen(mob/living/carbon/human/jellyman, datum/species/jelly/coremeister/species)
	if(use_types & CORE_USE_MAJOR)
		species.extract_major.Grant(jellyman)

	if(use_types & CORE_USE_MINOR)
		species.extract_minor.Grant(jellyman)

/obj/item/slime_extract/proc/coremeister_discarded(mob/living/carbon/human/jellyman, datum/species/jelly/coremeister/species)
	species.extract_major.Remove(jellyman)
	species.extract_minor.Remove(jellyman)

/obj/item/slime_extract/proc/coremeister_minor(mob/living/carbon/human/jellyman, datum/species/jelly/coremeister/species)

/obj/item/slime_extract/proc/coremeister_major(mob/living/carbon/human/jellyman, datum/species/jelly/coremeister/species)

/obj/item/slime_extract/update_overlays()
	. = ..()
	if(attached_gold_core)
		. += mutable_appearance(icon, icon_state = "gold_secondary_attached")

/obj/item/slime_extract/special
	tier = 0

// ************************************************
// ******************* TIER ONE *******************
// ************************************************

// Grey Extract

/obj/item/slime_extract/grey
	name = "grey slime extract"
	icon_state = "grey"
	tier = 1
	react_reagents = list(/datum/reagent/toxin/plasma = 5, /datum/reagent/blood = 5)
	jelly_color = "#AAAAAA"
	coremeister_description = "Shortens user's cooldowns in cost of rapid nutrition drain."

/obj/item/slime_extract/grey/coremeister_life(mob/living/carbon/human/jellyman, datum/species/jelly/coremeister/species, delta_time, times_fired)
	for(var/core_type in species.core_type_cooldowns)
		species.core_type_cooldowns[core_type] -= delta_time * 0.5 SECONDS
		jellyman.adjust_nutrition(-delta_time)

	if(!COOLDOWN_FINISHED(species, core_swap_cooldown) && !species.rainbow_active)
		species.core_swap_cooldown -= delta_time * 0.5 SECONDS
		jellyman.adjust_nutrition(-delta_time)

// ************************************************
// ******************* TIER TWO *******************
// ************************************************

// Orange Extract

/obj/item/slime_extract/orange
	name = "orange slime extract"
	icon_state = "orange"
	tier = 2
	react_reagents = list(/datum/reagent/blood = 21, /datum/reagent/toxin/plasma = 5)
	jelly_color = "#EEAB46"

// Blue Extract

/obj/item/slime_extract/blue
	name = "blue slime extract"
	icon_state = "blue"
	tier = 2
	react_reagents = list(/datum/reagent/toxin/plasma = 5, /datum/reagent/blood = 5, /datum/reagent/water = 5)
	jelly_color = "#3BE4E4"

// Purple Extract

/obj/item/slime_extract/purple
	name = "purple slime extract"
	icon_state = "purple"
	tier = 2
	react_reagents = list(/datum/reagent/blood = 10, /datum/reagent/toxin/plasma = 5)
	jelly_color = "#C84FEC"

// Metal Extract

/obj/item/slime_extract/metal
	name = "metal slime extract"
	icon_state = "metal"
	tier = 2
	react_reagents = list(/datum/reagent/toxin/plasma = 5, /datum/reagent/blood = 5)
	jelly_color = "#909090"

// ************************************************
// ****************** TIER THREE ******************
// ************************************************

// Dark Purple Extract

/obj/item/slime_extract/dark_purple
	name = "dark purple slime extract"
	icon_state = "dark_purple"
	tier = 3
	react_reagents = list(/datum/reagent/water = 5, /datum/reagent/toxin/plasma = 5)
	jelly_color = "#9948F7"
	coremeister_description = "User breaths plasma instead of oxygen."
	var/drained_amount = 0
	var/original_oxy_min
	var/original_plasma_min
	var/original_plasma_max

/obj/item/slime_extract/dark_purple/coremeister_chosen(mob/living/carbon/human/jellyman, datum/species/jelly/coremeister/species)
	. = ..()
	RegisterSignal(jellyman, COMSIG_CARBON_GAIN_ORGAN, .proc/check_added_organ)
	RegisterSignal(jellyman, COMSIG_CARBON_LOSE_ORGAN, .proc/check_removed_organ)

	var/obj/item/organ/internal/lungs/lungs = jellyman.getorganslot(ORGAN_SLOT_LUNGS)
	if(!lungs)
		return

	original_oxy_min = lungs.safe_oxygen_min
	original_plasma_min = lungs.safe_plasma_min
	original_plasma_max = lungs.safe_plasma_max

	lungs.safe_oxygen_min = 0
	lungs.safe_plasma_min = 4
	lungs.safe_plasma_max = 0

/obj/item/slime_extract/dark_purple/proc/check_added_organ(mob/owner, obj/item/organ/internal/lungs/lungs)
	SIGNAL_HANDLER

	if(!istype(lungs))
		return

	original_oxy_min = lungs.safe_oxygen_min
	original_plasma_min = lungs.safe_plasma_min
	original_plasma_max = lungs.safe_plasma_max

	lungs.safe_oxygen_min = 0
	lungs.safe_plasma_min = 4
	lungs.safe_plasma_max = 0

/obj/item/slime_extract/dark_purple/proc/check_removed_organ(mob/owner, obj/item/organ/internal/lungs/lungs)
	SIGNAL_HANDLER

	if(!istype(lungs))
		return

	lungs.safe_oxygen_min = original_oxy_min
	lungs.safe_plasma_min = original_plasma_min
	lungs.safe_plasma_max = original_plasma_max

/obj/item/slime_extract/dark_purple/coremeister_discarded(mob/living/carbon/human/jellyman, datum/species/jelly/coremeister/species)
	. = ..()
	UnregisterSignal(jellyman, COMSIG_CARBON_GAIN_ORGAN)
	UnregisterSignal(jellyman, COMSIG_CARBON_LOSE_ORGAN)

/obj/item/slime_extract/dark_purple/proc/plasma_drain()
	var/turf/our_turf = get_turf(src)
	our_turf.visible_message(span_notice("[src] starts to glow and hiss as it begins absorbing plasma in the air!"))
	START_PROCESSING(SSfastprocess, src)
	icon_state = "[initial(icon_state)]_pulsating"
	name = "activated [initial(name)]"
	desc = "An activated [initial(name)]. It's draining plasma from the atmospehre and condensing it into solid plasma sheets."
	activated = TRUE
	update_icon()
	addtimer(CALLBACK(src, .proc/stop_draining), 15 SECONDS)

/obj/item/slime_extract/dark_purple/proc/stop_draining() //Converts 50% of the plasma in the air into sheets, 200 moles per sheet
	STOP_PROCESSING(SSfastprocess, src)
	icon_state = initial(icon_state)
	name = initial(name)
	desc = initial(desc)
	activated = FALSE
	if(uses <= 0)
		use_up()
	update_icon()
	if(drained_amount >= 200)
		new /obj/item/stack/sheet/mineral/plasma(get_turf(src), round(drained_amount / 200))

/obj/item/slime_extract/dark_purple/process()
	for(var/turf/drain_turf in range(1, get_turf(src))) //High efficiency draining!
		var/datum/gas_mixture/drain_mix = drain_turf.return_air()
		if(!drain_mix.gases[/datum/gas/plasma] || !drain_mix.gases[/datum/gas/plasma][MOLES])
			return

		drained_amount += drain_mix.gases[/datum/gas/plasma][MOLES]
		drain_mix.remove_specific(/datum/gas/plasma, drain_mix.gases[/datum/gas/plasma][MOLES])

// Dark Blue Extract

/obj/item/slime_extract/dark_blue
	name = "dark blue slime extract"
	icon_state = "dark_blue"
	tier = 3
	react_reagents = list(/datum/reagent/water = 5, /datum/reagent/toxin/plasma = 5)
	jelly_color = "#33A0FF"

/obj/item/slime_extract/dark_blue/activate()
	activated = TRUE
	icon_state = "[initial(icon_state)]_pulsating"
	name = "activated [initial(name)]"
	desc = "An activated [initial(name)]. It can be smeared over somebody in critical condition or youself to cover them in stasis-inducing and pressure-proof slime for one minute."

/obj/item/slime_extract/dark_blue/afterattack(atom/target, mob/living/user, proximity_flag)
	. = ..()
	if(!proximity_flag)
		return

	if(!ishuman(target) || !activated)
		return

	var/mob/living/carbon/human/victim = target
	if(victim != user && !victim.stat)
		return

	victim.visible_message(span_warning("[src] starts to inflate and envelops [victim] in a layer stasis-inducing slime!"), span_userdanger("[src] starts to inflate and envelops you in a layer stasis-inducing slime!"))
	victim.apply_status_effect(/datum/status_effect/slime/dark_blue)
	icon_state = initial(icon_state)
	name = initial(name)
	desc = initial(desc)
	activated = FALSE
	if(uses <= 0)
		qdel(src)
	return

// Silver Extract

/obj/item/slime_extract/silver
	name = "silver slime extract"
	icon_state = "silver"
	tier = 3
	react_reagents = list(/datum/reagent/toxin/plasma = 5, /datum/reagent/blood = 5, /datum/reagent/water = 5)
	jelly_color = "#DADADA"

/obj/item/slime_extract/silver/activate()
	activated = TRUE
	icon_state = "[initial(icon_state)]_pulsating"
	name = "activated [initial(name)]"
	desc = "An activated [initial(name)]. It can be applied to yourself in order to create a small blorbie that you can control remotely."

/obj/item/slime_extract/silver/afterattack(atom/target, mob/living/user, proximity_flag)
	. = ..()
	if(!proximity_flag || !ishuman(target) || !activated || target != user)
		return

	var/mob/living/carbon/human/victim = target
	victim.apply_status_effect(/datum/status_effect/silver_control)
	icon_state = initial(icon_state)
	name = initial(name)
	desc = initial(desc)
	activated = FALSE
	if(uses <= 0)
		qdel(src)
	return

// Yellow Extract

/obj/item/slime_extract/yellow
	name = "yellow slime extract"
	icon_state = "yellow"
	tier = 3
	react_reagents = list(/datum/reagent/toxin/plasma = 5, /datum/reagent/blood = 5, /datum/reagent/water = 5)
	jelly_color = "#FFF419"
	coremeister_description = "User is able to see wires when hacking and is immune to shocks at cost of not being able to move away from the powernet."

/obj/item/slime_extract/yellow/coremeister_chosen(mob/living/carbon/human/jellyman, datum/species/jelly/coremeister/species)
	. = ..()
	RegisterSignal(jellyman, COMSIG_MOB_CLIENT_PRE_MOVE, .proc/on_move)
	RegisterSignal(jellyman, COMSIG_MOVABLE_MOVED, .proc/on_moved)
	ADD_TRAIT(jellyman, TRAIT_KNOW_ALL_WIRES, "yellow_coremeister")
	ADD_TRAIT(jellyman, TRAIT_MESS_UP_WIRES, "yellow_coremeister") // Randomises wire colors so you can't abuse knowledge of those later when you switch into another form
	ADD_TRAIT(jellyman, TRAIT_SHOCKIMMUNE, "yellow_coremeister")

/obj/item/slime_extract/yellow/coremeister_discarded(mob/living/carbon/human/jellyman, datum/species/jelly/coremeister/species)
	. = ..()
	UnregisterSignal(jellyman, list(COMSIG_MOB_CLIENT_PRE_MOVE, COMSIG_MOVABLE_MOVED))
	REMOVE_TRAIT(jellyman, TRAIT_KNOW_ALL_WIRES, "yellow_coremeister")
	REMOVE_TRAIT(jellyman, TRAIT_MESS_UP_WIRES, "yellow_coremeister")
	REMOVE_TRAIT(jellyman, TRAIT_SHOCKIMMUNE, "yellow_coremeister")

/obj/item/slime_extract/yellow/proc/on_moved(mob/living/carbon/human/jellyman, old_loc)
	SIGNAL_HANDLER
	t_ray_scan(jellyman, 2 SECONDS, 2)

/obj/item/slime_extract/yellow/proc/on_move(mob/living/carbon/human/jellyman, list/move_args) //Don't move on tiles that don't have power nearby
	SIGNAL_HANDLER

	var/power_detected = FALSE
	for(var/obj/structure/cable/cable in range(1, jellyman))
		if(!cable.powernet || !cable.powernet.avail)
			continue
		power_detected = TRUE
		break

	if(!power_detected) // We already don't have any power, let them move so they can run up to a cable and not die
		return

	var/turf/new_loc = get_turf(move_args[MOVE_ARG_NEW_LOC])

	for(var/obj/structure/cable/cable in range(1, new_loc))
		if(!cable.powernet || !cable.powernet.avail)
			continue
		return

	jellyman.setDir(get_dir(jellyman, new_loc))
	return COMSIG_MOB_CLIENT_BLOCK_PRE_MOVE

/obj/item/slime_extract/yellow/coremeister_life(mob/living/carbon/human/jellyman, datum/species/jelly/coremeister/species, delta_time, times_fired)
	. = ..()
	t_ray_scan(jellyman, 2 SECONDS, 2)

	for(var/obj/structure/cable/cable in range(1, jellyman))
		if(!cable.powernet || !cable.powernet.avail)
			continue
		return

	jellyman.adjustBruteLoss(10 / 3 * delta_time) //30 seconds without power to crit and 30 more to die

// ************************************************
// ****************** TIER FOUR *******************
// ************************************************

// Red Extract

/obj/item/slime_extract/red
	name = "red slime extract"
	icon_state = "red"
	tier = 4
	react_reagents = list(/datum/reagent/toxin/plasma = 5, /datum/reagent/blood = 5, /datum/reagent/water = 5)
	jelly_color = "#F13636"

// Green Extract

/obj/item/slime_extract/green
	name = "green slime extract"
	icon_state = "green"
	tier = 4
	react_reagents = list(/datum/reagent/toxin/plasma = 5, /datum/reagent/blood = 5, /datum/reagent/uranium/radium = 5)
	jelly_color = "#37E84D"

// Pink Extract

/obj/item/slime_extract/pink
	name = "pink slime extract"
	icon_state = "pink"
	tier = 4
	react_reagents = list(/datum/reagent/toxin/plasma = 5, /datum/reagent/blood = 5)
	jelly_color = "#FF5BBD"

/obj/item/slime_extract/pink/on_grind()
	. = ..()
	if(uses || activated)
		grind_results[/datum/reagent/toxin/slime_jelly] = 0
		grind_results[/datum/reagent/toxin/slime_jelly/pink] = 20

/obj/item/slime_extract/pink/activate()
	icon_state = "[initial(icon_state)]_pulsating"
	name = "activated [initial(name)]"
	desc = "An activated [initial(name)]. You can apply it to yourself or someone else to increase their mood for 15 minutes."
	activated = TRUE

/obj/item/slime_extract/pink/afterattack(atom/target, mob/living/user, proximity_flag)
	. = ..()
	if(!proximity_flag)
		return

	if(!isliving(target) || !activated || !target.GetComponent(/datum/component/mood))
		return

	icon_state = initial(icon_state)
	name = initial(name)
	desc = initial(desc)
	activated = FALSE
	to_chat(user, span_notice("You apply [src] to [target] and it dissolves as soon as it comes in contact with [target.p_them()]."))
	to_chat(target, span_hypnophrase("A wave of heat and pleasure rolls through your body as [user] applies [src] to you!"))
	SEND_SIGNAL(target, COMSIG_ADD_MOOD_EVENT, "pink_extract", /datum/mood_event/pink_extract)

	if(uses <= 0)
		qdel(src)
	return

// Gold Extract

/obj/item/slime_extract/gold
	name = "gold slime extract"
	icon_state = "gold"
	tier = 4
	jelly_color = "#e0b92c"

/obj/item/slime_extract/gold/activate()
	icon_state = "[initial(icon_state)]_pulsating"
	name = "activated [initial(name)]"
	desc = "An activated [initial(name)]. You can apply it to someone else to peer through their eyes."
	activated = TRUE

/obj/item/slime_extract/gold/afterattack(atom/target, mob/living/user, proximity_flag)
	if(!isliving(target) || !activated || target == user)
		. = ..()
		return

	if(!proximity_flag)
		return

	icon_state = initial(icon_state)
	name = initial(name)
	desc = initial(desc)
	activated = FALSE

	var/mob/living/victim = target
	if(victim.can_block_magic(MAGIC_RESISTANCE_MIND, charge_cost = 0))
		to_chat(user, span_warning("Something is shielding [target]'s mind from [src]'s influence!"))
		if(uses <= 0)
			qdel(src)
		return

	to_chat(user, span_notice("You apply [src] to [victim] without [victim.p_them()] noticing and your vision blurs as your mind links to [victim.p_their()] eyes."))
	user.apply_status_effect(/datum/status_effect/golden_eyes, victim)
	if(uses <= 0)
		qdel(src)
	return

/obj/item/slime_extract/special/gold_secondary
	name = "secondary gold slime extract"
	desc = "A small chunk of gold slime. You can attach it to another slime extract and it will sync it's reagents with the linked secondary extract."
	icon_state = "gold_secondary"
	uses = 0
	var/obj/item/slime_extract/special/gold_secondary/linked_extract
	var/obj/item/slime_extract/target_extract

/obj/item/slime_extract/special/gold_secondary/afterattack(atom/target, mob/living/user, proximity_flag)
	. = ..()
	if(!proximity_flag)
		return

	if(!istype(target, /obj/item/slime_extract))
		return

	var/obj/item/slime_extract/extract = target

	if(istype(extract, /obj/item/slime_extract/special/gold_secondary))
		to_chat(user, span_warning("You can't attach [src] to another [target]!"))
		return

	if(target_extract)
		to_chat(user, span_warning("[src] is already linked to another extract!"))
		return

	extract.attached_gold_core = TRUE
	extract.update_icon()
	linked_extract.target_extract = extract
	linked_extract.reagents.trans_to(extract, linked_extract.reagents.total_volume)
	linked_extract.linked_extract = null
	QDEL_NULL(src)

/obj/item/slime_extract/special/gold_secondary/create_reagents(max_vol, flags)
	. = ..()
	RegisterSignal(reagents, list(COMSIG_REAGENTS_NEW_REAGENT, COMSIG_REAGENTS_DEL_REAGENT), .proc/on_reagent_change)
	RegisterSignal(reagents, COMSIG_PARENT_QDELETING, .proc/on_reagents_del)

/obj/item/slime_extract/special/gold_secondary/proc/on_reagents_del(datum/reagents/reagents)
	SIGNAL_HANDLER
	UnregisterSignal(reagents, list(COMSIG_REAGENTS_NEW_REAGENT, COMSIG_REAGENTS_DEL_REAGENT, COMSIG_PARENT_QDELETING))
	return NONE

/obj/item/slime_extract/special/gold_secondary/proc/on_reagent_change(datum/reagents/holder, ...)
	SIGNAL_HANDLER
	if(!target_extract)
		return

	reagents.trans_to(target_extract, reagents.total_volume)

// ************************************************
// ****************** TIER FIVE *******************
// ************************************************

// Cerulean Extract

/obj/item/slime_extract/cerulean
	name = "cerulean slime extract"
	icon_state = "cerulean"
	tier = 5
	react_reagents = list(/datum/reagent/toxin/plasma = 5, /datum/reagent/blood = 5)
	jelly_color = "#5783AA"
	coremeister_description = "User's hands will turn into sharp claws that will allow them to tackle, but prevent picking up or using any items."
	var/datum/component/tackler

/obj/item/slime_extract/cerulean/activate()
	icon_state = "[initial(icon_state)]_pulsating"
	name = "activated [initial(name)]"
	desc = "An activated [initial(name)]. You can throw it at a wall and the extract will stick onto it, creating a proximity slime trap which will jump at whoever triggers them, significantly slowing them. Thrower won't trigger the trap."
	activated = TRUE

/obj/item/slime_extract/cerulean/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	if(!activated || !isclosedturf(hit_atom))
		return

	if(!throwingdatum || !throwingdatum.thrower || !isliving(throwingdatum.thrower))
		return

	new /obj/item/restraints/legcuffs/bola/slime_trap(get_turf(src), get_dir(get_turf(src), hit_atom), throwingdatum.thrower, uses)
	visible_message(span_notice("[src] sticks to [hit_atom], forming a small blob-like booby trap!"))
	qdel(src)

/obj/item/slime_extract/cerulean/coremeister_chosen(mob/living/carbon/human/jellyman, datum/species/jelly/coremeister/species)
	. = ..()
	tackler = jellyman.AddComponent(/datum/component/tackler, stamina_cost = 15, base_knockdown = 0.75 SECONDS, range = 5, speed = 1, skill_mod = 1, min_distance = 0, free_hands_required = FALSE)
	species.mutanthands = /obj/item/cerulean_tackle

	for(var/obj/item/held as anything in jellyman.held_items)
		if(istype(held))
			jellyman.dropItemToGround(held)
			continue
		INVOKE_ASYNC(jellyman, /mob.proc/put_in_hands, new /obj/item/cerulean_tackle)

/obj/item/slime_extract/cerulean/coremeister_discarded(mob/living/carbon/human/jellyman, datum/species/jelly/coremeister/species)
	. = ..()
	QDEL_NULL(tackler)
	species.mutanthands = initial(species.mutanthands)
	for(var/obj/item/cerulean_tackle/tackle in jellyman.held_items)
		qdel(tackle)

/obj/item/cerulean_tackle
	name = "cerulean claws"
	desc = "A pair of sharp cerulean slime claws."
	icon = 'icons/effects/effects.dmi'
	icon_state = "cerulean_tackle_left"
	item_flags = ABSTRACT | DROPDEL
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	force = 15
	sharpness = SHARP_EDGED
	wound_bonus = -30
	bare_wound_bonus = 15
	damtype = BRUTE

/obj/item/cerulean_tackle/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, HAND_REPLACEMENT_TRAIT)

/obj/item/cerulean_tackle/visual_equipped(mob/user, slot)
	. = ..()
	//these are intentionally inverted
	var/i = user.get_held_index_of_item(src)
	if(!(i % 2))
		icon_state = "cerulean_tackle_left"
	else
		icon_state = "cerulean_tackle_right"

// Sepia Extract

/obj/item/slime_extract/sepia
	name = "sepia slime extract"
	icon_state = "sepia"
	tier = 5
	react_reagents = list(/datum/reagent/toxin/plasma = 5, /datum/reagent/blood = 5)
	jelly_color = "#9B8A7A"
	coremeister_description = "User is able to place a dejavu recall point which lasts for up to a minute. Pressing the ability button again will recall the user and stun them for the duration of the recall."
	use_types = CORE_USE_MAJOR
	var/obj/effect/overlay/holo_pad_hologram/recall_hologram
	var/datum/component/dejavu/slime/coremeister/coremeister_dejavu
	var/obj/effect/abstract/particle_holder/particle_holder
	var/dejavu_start = 0
	var/time_jump = FALSE

/obj/item/slime_extract/sepia/activate(explosive = TRUE)
	icon_state = "[initial(icon_state)]_pulsating"
	name = "activated [initial(name)]"
	activated = TRUE
	if(!explosive)
		time_jump = TRUE
		desc = "An activated [initial(name)]. It can be applied to pull you through space time, 10 seconds for each of it's uses."
		return
	desc = "An activated [initial(name)]. It will soon explode into a timestop field!"
	addtimer(CALLBACK(src, .proc/slime_stop), 5 SECONDS)
	playsound(get_turf(src), 'sound/magic/mandswap.ogg', 100, TRUE)

/obj/item/slime_extract/sepia/proc/slime_stop()
	icon_state = initial(icon_state)
	name = initial(name)
	desc = initial(desc)
	activated = FALSE
	new /obj/effect/timestop/small_effect(get_turf(src), 1)
	if(uses > 0)
		var/mob/lastheld = get_mob_by_key(fingerprintslast)
		if(lastheld && !lastheld.equip_to_slot_if_possible(src, ITEM_SLOT_HANDS, disable_warning = TRUE))
			forceMove(get_turf(lastheld))
	else
		use_up()

/obj/item/slime_extract/sepia/afterattack(atom/target, mob/living/user, proximity_flag)
	. = ..()
	if(!proximity_flag)
		return

	if(!isliving(target) || !time_jump)
		return

	user.visible_message(span_warning("[user] begins applying [src] to [(target == user) ? "themselves" : target]."), span_notice("You begin applying [src] to [(target == user) ? "yourself" : target]."))
	if(!do_after(user, 3 SECONDS, target))
		return

	icon_state = initial(icon_state)
	name = initial(name)
	desc = initial(desc)
	activated = FALSE
	time_jump = FALSE
	var/datum/component/dejavu/slime/sepia_core/existing_dejavu = target.GetComponent(/datum/component/dejavu/slime/sepia_core)
	if(existing_dejavu)
		playsound(target, 'sound/magic/teleport_diss.ogg', 50, TRUE)
		existing_dejavu.rewinds_remaining += uses
		qdel(src)
		return

	playsound(target, 'sound/magic/teleport_app.ogg', 50, TRUE)
	AddComponent(/datum/component/dejavu/slime/sepia_core, uses + 1, 10 SECONDS)
	qdel(src)
	return

/obj/item/slime_extract/sepia/coremeister_major(mob/living/carbon/human/jellyman, datum/species/jelly/coremeister/species)
	. = ..()
	if(coremeister_dejavu)
		coremeister_dejavu.rewind_carbon()
		return

	recall_hologram = new(get_turf(jellyman))
	recall_hologram.appearance = jellyman.appearance
	recall_hologram.alpha = 170
	recall_hologram.add_atom_colour(COLOR_BROWN, FIXED_COLOUR_PRIORITY)
	recall_hologram.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	recall_hologram.layer = FLY_LAYER
	recall_hologram.plane = ABOVE_GAME_PLANE
	recall_hologram.set_anchored(TRUE)
	recall_hologram.name = "[jellyman.name]'s Dejavu"
	recall_hologram.set_light(2)
	coremeister_dejavu = jellyman.AddComponent(/datum/component/dejavu/slime/coremeister, 1, 1 MINUTES)
	COOLDOWN_START(species, core_swap_cooldown, 1 MINUTES)
	RegisterSignal(jellyman, COMSIG_DEJAVU_REWIND, .proc/on_dejavu)
	dejavu_start = world.time
	RegisterSignal(jellyman, COMSIG_MOVABLE_MOVED, .proc/on_moved)

/obj/item/slime_extract/sepia/proc/on_moved(mob/living/carbon/human/jellyman, old_loc)
	SIGNAL_HANDLER

	if(!isturf(jellyman.loc))
		return

	if(particle_holder)
		addtimer(VARSET_CALLBACK(particle_holder.particles, spawning, 0), 0.25 SECONDS)
		QDEL_IN(particle_holder, 3 SECONDS) //as soon as the last particles disappear

	particle_holder = new(jellyman.loc, /particles/sepia_ash)
	particle_holder.plane = GAME_PLANE
	particle_holder.layer = BELOW_MOB_LAYER

	var/particles/sepia_ash/dejavu_particles = particle_holder.particles
	var/particle_distance = sqrt((recall_hologram.x - jellyman.x) ** 2 + (recall_hologram.y - jellyman.y) ** 2)
	var/list/particle_dir = list((recall_hologram.x - jellyman.x) / max(1, particle_distance), (recall_hologram.y - jellyman.y) / max(1, particle_distance))
	dejavu_particles.velocity = list(particle_dir[1] * 3, particle_dir[2] * 3)
	dejavu_particles.drift = generator("vector", list(0, 0), list(particle_dir[1] / 40, particle_dir[2] / 40), NORMAL_RAND)

/obj/item/slime_extract/sepia/proc/on_dejavu(mob/living/carbon/human/jellyman, datum/component/dejavu/dejavu)
	SIGNAL_HANDLER

	if(dejavu != coremeister_dejavu)
		return

	var/datum/species/jelly/coremeister/species = jellyman.dna.species
	UnregisterSignal(jellyman, list(COMSIG_MOVABLE_MOVED, COMSIG_DEJAVU_REWIND))
	QDEL_NULL(recall_hologram)
	if(type in species.core_type_cooldowns)
		species.core_type_cooldowns[type] += 1 MINUTES
		return

	species.core_type_cooldowns[type] = 1 MINUTES
	ADD_TRAIT(jellyman, TRAIT_MUTE, "sepia_coremeister")
	jellyman.Stun(world.time - dejavu_start)
	jellyman.add_atom_colour(list(-1,0,0,0, 0,-1,0,0, 0,0,-1,0, 0,0,0,1, 1,1,1,0), TEMPORARY_COLOUR_PRIORITY)
	addtimer(CALLBACK(src, .proc/remove_negative, jellyman), world.time - dejavu_start)

	if(particle_holder)
		particle_holder.particles.spawning = 0
		QDEL_IN(particle_holder, 3 SECONDS)

/obj/item/slime_extract/sepia/proc/remove_negative(mob/living/carbon/human/jellyman)
	jellyman.remove_atom_colour(TEMPORARY_COLOUR_PRIORITY)
	REMOVE_TRAIT(jellyman, TRAIT_MUTE, "sepia_coremeister")

/obj/item/slime_extract/sepia/coremeister_discarded(mob/living/carbon/human/jellyman, datum/species/jelly/coremeister/species)
	. = ..()
	if(coremeister_dejavu)
		coremeister_dejavu.rewind_carbon()

/particles/sepia_ash
	icon = 'icons/effects/particles/sepia.dmi'
	icon_state = list("sepia_1" = 1, "sepia_2" = 1, "sepia_3" = 1)
	width = 256
	height = 256
	count = 1000
	spawning = 0.5
	lifespan = 3 SECONDS
	fade = 1 SECONDS
	velocity = list(0, 0)
	position = generator("box", list(-8, -16), list(8, 16), NORMAL_RAND)
	scale = 1
	rotation = generator("num", 0, 360)
	spin = generator("num", -20, 20)

// Pyrite Extract

/obj/item/slime_extract/pyrite
	name = "pyrite slime extract"
	icon_state = "pyrite"
	tier = 5
	react_reagents = list(/datum/reagent/toxin/plasma = 5, /datum/reagent/blood = 5, /datum/reagent/water = 5)
	jelly_color = "#ffde22"

/obj/item/slime_extract/pyrite/activate()
	activated = TRUE
	icon_state = "[initial(icon_state)]_pulsating"
	name = "activated [initial(name)]"
	desc = "An activated [initial(name)]. You can remotely use it on someone else to temporary copy their appearance."

/obj/item/slime_extract/pyrite/afterattack(atom/target, mob/living/user, proximity_flag)
	. = ..()
	if(!ishuman(target) || !activated)
		return

	if(user.has_status_effect(/datum/status_effect/slime/pyrite))
		to_chat(user, "You are already impersonating somebody!")
		return

	icon_state = initial(icon_state)
	name = initial(name)
	desc = initial(desc)
	activated = FALSE
	to_chat(user, span_notice("You squish [src] in your hand and think about [target]."))
	user.apply_status_effect(/datum/status_effect/slime/pyrite, target)

	if(uses <= 0)
		qdel(src)
	return

// Bluespace Extract

/obj/item/slime_extract/bluespace
	name = "bluespace slime extract"
	icon_state = "bluespace"
	tier = 5
	react_reagents = list(/datum/reagent/toxin/plasma = 5, /datum/reagent/blood = 5, /datum/reagent/water = 5)
	jelly_color = "#FFFFFF"
	var/activation_x
	var/activation_y
	var/activation_z

/obj/item/slime_extract/bluespace/activate()
	var/turf/our_turf = get_turf(src)
	var/area/teleport_area = get_area(src)
	if(teleport_area.area_flags & NOTELEPORT || HAS_TRAIT(our_turf, TRAIT_BLUESPACE_SLIME_FIXATION))
		uses += 1
		our_turf.visible_message("[src] starts glowing but soon calms down, unable to memorise it's location.")
		return
	icon_state = "[initial(icon_state)]_pulsating"
	name = "activated [initial(name)]"
	desc = "An activated [initial(name)]. You can use it in-hand or throw it to create a one-way wormhole portal to its activation spot."
	activated = TRUE
	activation_x = our_turf.x
	activation_y = our_turf.y
	activation_z = our_turf.z

/obj/item/slime_extract/bluespace/attack_self(mob/user, modifiers)
	. = ..()
	if(activated)
		create_portal()

/obj/item/slime_extract/bluespace/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	if(!. && activated) //Caught by a mob or not activated
		create_portal()

/obj/item/slime_extract/bluespace/proc/create_portal()
	var/turf/our_turf = get_turf(src)
	var/area/teleport_area = get_area(src)

	icon_state = initial(icon_state)
	name = initial(name)
	desc = initial(desc)
	activated = FALSE

	if(teleport_area.area_flags & NOTELEPORT || !activation_x || HAS_TRAIT(our_turf, TRAIT_BLUESPACE_SLIME_FIXATION))
		uses += 1
		our_turf.visible_message("[src] starts glowing but soon calms down, unable to channel the portal.")
		return

	var/turf/target_turf = locate(activation_x, activation_y, activation_z)
	var/obj/effect/portal/slime/portal = new(our_turf, 10 SECONDS)
	portal.linked_turf = target_turf

	if(uses <= 0)
		use_up()

// ************************************************
// ******************* TIER SIX *******************
// ************************************************

// Oil Extract

/obj/item/slime_extract/oil
	name = "oil slime extract"
	icon_state = "oil"
	tier = 6
	react_reagents = list(/datum/reagent/toxin/plasma = 5, /datum/reagent/blood = 5)
	jelly_color = "#3B3B3B"
	coremeister_description = "User is extremely flammable and constantly dripping oil."
	var/primer

/obj/item/slime_extract/oil/activate()
	icon_state = "[initial(icon_state)]_pulsating"
	name = "activated [initial(name)]"
	desc = "An activated [initial(name)]. It will soon explode!"
	activated = TRUE
	playsound(get_turf(src), 'sound/magic/mandswap.ogg', 100, TRUE)

	var/turf/our_turf = get_turf(src)
	var/touch_msg = "N/A"
	if(fingerprintslast)
		primer = get_mob_by_key(fingerprintslast)
		touch_msg = "[ADMIN_LOOKUPFLW(primer)]."
	message_admins("Slime Explosion reaction started at [ADMIN_VERBOSEJMP(our_turf)]. Last Fingerprint: [touch_msg]")
	log_game("Slime Explosion reaction started at [AREACOORD(our_turf)]. Last Fingerprint: [fingerprintslast ? fingerprintslast : "N/A"].")
	our_turf.visible_message(span_danger("[src] starts to vibrate violently!"))

	addtimer(CALLBACK(src, .proc/slime_explosion), 5 SECONDS)

/obj/item/slime_extract/oil/proc/slime_explosion()
	if(!primer)
		primer = src
	explosion(src, devastation_range = 1, heavy_impact_range = 3, light_impact_range = 6, explosion_cause = primer)
	qdel(src)

/obj/item/slime_extract/oil/coremeister_life(mob/living/carbon/human/jellyman, datum/species/jelly/coremeister/species, delta_time, times_fired)
	if(jellyman.fire_stacks >= 3)
		return
	jellyman.adjust_fire_stacks(3 - jellyman.fire_stacks, /datum/status_effect/fire_handler/fire_stacks/oil)

/obj/item/slime_extract/oil/coremeister_chosen(mob/living/carbon/human/jellyman, datum/species/jelly/coremeister/species)
	. = ..()
	RegisterSignal(jellyman, COMSIG_MOVABLE_MOVED, .proc/on_moved)
	RegisterSignal(jellyman, COMSIG_HUMAN_MELEE_UNARMED_ATTACK, .proc/on_melee)
	ADD_TRAIT(jellyman, TRAIT_NO_FIRE_PROTECTION, "oil_coremeister")

/obj/item/slime_extract/oil/coremeister_discarded(mob/living/carbon/human/jellyman, datum/species/jelly/coremeister/species)
	. = ..()
	UnregisterSignal(jellyman, list(COMSIG_MOVABLE_MOVED, COMSIG_HUMAN_MELEE_UNARMED_ATTACK))
	REMOVE_TRAIT(jellyman, TRAIT_NO_FIRE_PROTECTION, "oil_coremeister")

/obj/item/slime_extract/oil/proc/on_moved(mob/living/carbon/human/jellyman, old_loc)
	SIGNAL_HANDLER
	if(!isturf(jellyman.loc)) //No locker abuse
		return

	new /obj/effect/decal/cleanable/fuel_pool/oil(jellyman.loc)

/obj/item/slime_extract/oil/proc/on_melee(mob/living/carbon/human/jellyman, atom/attacked_atom, proximity)
	SIGNAL_HANDLER

	if(!isliving(attacked_atom))
		return

	var/mob/living/victim = attacked_atom
	if(victim.fire_stacks >= 5)
		return

	victim.adjust_fire_stacks(1, /datum/status_effect/fire_handler/fire_stacks/oil)

// Black Extract

/obj/item/slime_extract/black
	name = "black slime extract"
	icon_state = "black"
	tier = 6
	react_reagents = list(/datum/reagent/toxin/plasma = 5, /datum/reagent/blood = 5)
	jelly_color = "#555555"
	coremeister_description = "Prevents the user from dying or entering critical condition at cost of doubling all incoming damage and making them easier to wound and dismember." //Sounds OP but in reality it's just a huge meme
	var/list/limb_transform_types = list(
		BODY_ZONE_L_ARM = /obj/item/bodypart/l_arm/jelly/slime,
		BODY_ZONE_R_ARM = /obj/item/bodypart/r_arm/jelly/slime,
		BODY_ZONE_HEAD = /obj/item/bodypart/head/jelly/slime,
		BODY_ZONE_L_LEG = /obj/item/bodypart/l_leg/jelly/slime,
		BODY_ZONE_R_LEG = /obj/item/bodypart/r_leg/jelly/slime,
	)

/obj/item/slime_extract/black/activate()
	activated = TRUE
	icon_state = "[initial(icon_state)]_pulsating"
	name = "activated [initial(name)]"
	desc = "An activated [initial(name)]. It can be smeared over someone's missing limb to restore it or existing one to patch up its wounds."

/obj/item/slime_extract/black/afterattack(atom/target, mob/living/user, proximity_flag)
	. = ..()
	if(!proximity_flag)
		return

	if(!ishuman(target) || !activated)
		return

	icon_state = initial(icon_state)
	name = initial(name)
	desc = initial(desc)
	activated = FALSE

	var/mob/living/carbon/human/victim = target
	var/obj/item/bodypart/target_part = victim.get_bodypart(user.zone_selected)
	if(target_part && target_part.bodytype & BODYTYPE_ORGANIC)
		target_part.heal_damage(50, 50) //Usually full heal
		for(var/datum/wound/wound as anything in target_part.wounds)
			wound.on_synthflesh(30)
			wound.on_xadone(70) //Not enough to heal critical wounds, but works for moderate and severe
		if(uses <= 0)
			qdel(src)
		return

	var/limb_type = limb_transform_types[user.zone_selected]
	var/obj/item/bodypart/new_part = new limb_type()
	new_part.mutation_color = "#333333"
	new_part.attach_limb(victim, TRUE)
	victim.update_body_parts()
	playsound(get_turf(victim), 'sound/effects/splat.ogg', 100, TRUE)
	victim.visible_message(span_notice("[user] smears [src] all over [victim]'s missing [parse_zone(user.zone_selected)] and it reforms into a new slimy limb."))

	if(uses <= 0)
		qdel(src)
	return

/obj/item/slime_extract/black/coremeister_chosen(mob/living/carbon/human/jellyman, datum/species/jelly/coremeister/species)
	. = ..()
	jellyman.physiology.damage_resistance -= 100
	ADD_TRAIT(jellyman, TRAIT_NODEATH, "black_coremeister")
	ADD_TRAIT(jellyman, TRAIT_NOHARDCRIT, "black_coremeister")
	ADD_TRAIT(jellyman, TRAIT_NOSOFTCRIT, "black_coremeister")
	ADD_TRAIT(jellyman, TRAIT_EASYDISMEMBER, "black_coremeister")
	ADD_TRAIT(jellyman, TRAIT_EASILY_WOUNDED, "black_coremeister")

/obj/item/slime_extract/black/coremeister_discarded(mob/living/carbon/human/jellyman, datum/species/jelly/coremeister/species)
	. = ..()
	jellyman.physiology.damage_resistance += 100
	REMOVE_TRAIT(jellyman, TRAIT_NODEATH, "black_coremeister")
	REMOVE_TRAIT(jellyman, TRAIT_NOHARDCRIT, "black_coremeister")
	REMOVE_TRAIT(jellyman, TRAIT_NOSOFTCRIT, "black_coremeister")
	REMOVE_TRAIT(jellyman, TRAIT_EASYDISMEMBER, "black_coremeister")
	REMOVE_TRAIT(jellyman, TRAIT_EASILY_WOUNDED, "black_coremeister")

// Adamantine Extract

/obj/item/slime_extract/adamantine
	name = "adamantine slime extract"
	icon_state = "adamantine"
	tier = 6
	react_reagents = list(/datum/reagent/toxin/plasma = 5, /datum/reagent/blood = 5)
	jelly_color = "#2A9777"

// Light Pink Extract

/obj/item/slime_extract/light_pink
	name = "light pink slime extract"
	icon_state = "light_pink"
	tier = 6
	react_reagents = list(/datum/reagent/toxin/plasma = 5, /datum/reagent/blood = 5)
	jelly_color = "#FFD3F7"

/obj/item/slime_extract/light_pink/proc/start_pacifism()
	var/area/our_area = get_area(get_turf(src))
	if(our_area.outdoors)
		return

	for(var/turf/open/affected_turf in our_area)
		var/obj/effect/abstract/petals_holder/petals = locate() in affected_turf
		if(petals)
			deltimer(petals.del_timer)
			QDEL_IN(petals, 3 MINUTES)
			continue

		petals = new(affected_turf)
		for(var/mob/living/victim in affected_turf)
			ADD_TRAIT(victim, TRAIT_PACIFISM, MAGIC_TRAIT)
			to_chat(victim, span_notice("You feel hypnotised by the falling sakura petals..."))

/obj/effect/abstract/petals_holder //Because I want particles be ontop of the mobs and byonds system is fucking STUUUUPID. Can't do one particle generator because curved rooms muh.
	anchored = TRUE //dont move my shit
	particles = new /particles/sakura_petals()
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_ALL_MOB_LAYER
	plane = ABOVE_GAME_PLANE
	var/del_timer

/obj/effect/abstract/petals_holder/Initialize(mapload)
	. = ..()
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = .proc/on_entered,
		COMSIG_ATOM_EXITED = .proc/on_exited,
	)

	AddElement(/datum/element/connect_loc, loc_connections)
	del_timer = QDEL_IN(src, 3 MINUTES)

/obj/effect/abstract/petals_holder/proc/on_entered(datum/source, atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	SIGNAL_HANDLER

	if(!isliving(arrived) || HAS_TRAIT_FROM(arrived, TRAIT_PACIFISM, MAGIC_TRAIT))
		return

	ADD_TRAIT(arrived, TRAIT_PACIFISM, MAGIC_TRAIT)
	to_chat(arrived, span_notice("You feel hypnotised by the falling sakura petals..."))

/obj/effect/abstract/petals_holder/proc/on_exited(datum/source, atom/movable/gone, direction)
	SIGNAL_HANDLER

	if(!isliving(gone))
		return

	var/turf/dir_turf = get_step(get_turf(src), direction)
	if(locate(type) in dir_turf)
		return

	REMOVE_TRAIT(gone, TRAIT_PACIFISM, MAGIC_TRAIT)

/obj/effect/abstract/petals_holder/Destroy(force)
	var/turf/our_turf = get_turf(src)
	for(var/mob/living/victim in our_turf)
		REMOVE_TRAIT(victim, TRAIT_PACIFISM, MAGIC_TRAIT)
		to_chat(victim, span_notice("You lose the fleeing feeling of inner peace as last sakura petals fall to the ground..."))
	return ..()

/particles/sakura_petals
	icon = 'icons/effects/particles/sakura.dmi'
	icon_state = list("sakura_1" = 1, "sakura_2" = 2, "sakura_3" = 2)
	width = 1024
	height = 1024
	count = 10000
	spawning = 0.02
	lifespan = 9 SECONDS
	fade = 3 SECONDS
	fadein = 1 SECONDS
	grow = -0.001
	velocity = list(-1.5, -1)
	position = generator("box", list(48, 96), list(144, 128), NORMAL_RAND)
	drift = generator("vector", list(0, -0.0010), list(0, 0))
	scale = generator("vector", list(0.75, 0.75), list(1,1), NORMAL_RAND)
	rotation = generator("num", 0, 360)
	spin = generator("num", -20, 20)

// ************************************************
// ****************** TIER SEVEN ******************
// ************************************************

// Rainbow Extract

/obj/item/slime_extract/special/rainbow
	name = "rainbow slime extract"
	icon_state = "rainbow"
	tier = 7
	react_reagents = list(/datum/reagent/toxin/plasma = 5, /datum/reagent/blood = 5)
	var/shield = FALSE

/obj/item/slime_extract/special/rainbow/activate(shielding)
	shield = shielding
	activated = TRUE
	icon_state = "[initial(icon_state)]_aura"
	name = "activated [initial(name)]"
	desc = "An activated [initial(name)]. It can be applied on yourself or someone else to grant them [shield ? "almost complete protection for 15 seconds" : "incredible speed for 45 seconds"]."

/obj/item/slime_extract/special/rainbow/afterattack(atom/target, mob/living/user, proximity_flag)
	. = ..()
	if(!proximity_flag)
		return

	if(!ishuman(target) || !activated)
		return

	var/mob/living/carbon/human/victim = target

	icon_state = initial(icon_state)
	name = initial(name)
	desc = initial(desc)
	activated = FALSE
	if(shield)
		victim.apply_status_effect(/datum/status_effect/rainbow_shield)
	else
		victim.apply_status_effect(/datum/status_effect/rainbow_dash)
	victim.visible_message(span_warning("[victim] starts shining with all colors of rainbow as soon as [user] applies [src] to them!"))
	if(uses <= 0)
		qdel(src)
	return

/obj/item/slime_extract/special/fiery
	name = "fiery slime extract"
	icon_state = "fiery"
	react_reagents = list(/datum/reagent/toxin/plasma = 5, /datum/reagent/blood = 5)
	jelly_color = "#F86018"

/obj/item/slime_extract/special/biohazard
	name = "biohazard slime extract"
	icon_state = "biohazard"
	react_reagents = list(/datum/reagent/toxin/plasma = 5)
	jelly_color = "#319241"

/obj/item/storage/box/syndicate/slime_core_debug/PopulateContents()
	. = ..()
	for(var/core_type in (subtypesof(/obj/item/slime_extract) - /obj/item/slime_extract/special))
		new core_type(src)
