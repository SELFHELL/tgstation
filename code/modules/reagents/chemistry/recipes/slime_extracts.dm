

/datum/chemical_reaction/slime
	reaction_flags = REACTION_INSTANT
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_SLIME
	required_other = TRUE

	var/deletes_extract = TRUE

/datum/chemical_reaction/slime/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	use_slime_core(holder)

/datum/chemical_reaction/slime/proc/use_slime_core(datum/reagents/holder)
	SSblackbox.record_feedback("tally", "slime_cores_used", 1, "type")
	if(!istype(holder.my_atom, /obj/item/slime_extract))
		return

	var/obj/item/slime_extract/extract = holder.my_atom
	extract.uses--
	if(extract.uses > 0)
		return

	var/list/seen = viewers(4, get_turf(extract))
	extract.visible_message(span_notice("[icon2html(extract, seen)] [extract]'s power is consumed in the reaction."))
	extract.use_up()
	if(deletes_extract)
		delete_extract(holder)

/datum/chemical_reaction/slime/proc/delete_extract(datum/reagents/holder)
	var/obj/item/slime_extract/M = holder.my_atom
	if(!results.len) //if the slime doesn't output chemicals
		qdel(M)

/datum/chemical_reaction/slime/proc/attempt_balloon(balloon_text, datum/reagents/holder)
	var/atom/cycle_loc = holder.my_atom
	while(!isturf(cycle_loc) && !ishuman(cycle_loc))
		cycle_loc = cycle_loc.loc

	if(!isliving(cycle_loc))
		return

	cycle_loc.balloon_alert(cycle_loc, balloon_text)

/datum/chemical_reaction/slime/biohazard
	required_container = /obj/item/slime_extract
	required_reagents = list(/datum/reagent/toxin/tuporixin = 1)
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_SLIME | REACTION_TAG_DANGEROUS

/datum/chemical_reaction/slime/biohazard/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/turf/extract_turf = get_turf(holder.my_atom)
	var/mob/living/simple_animal/slime/color/biohazard/slime = new(extract_turf)
	extract_turf.visible_message(span_danger("[holder.my_atom] starts rapidly expanding and changing it's color, turning into [slime]!"))
	return ..()

// ************************************************
// ******************* TIER ONE *******************
// ************************************************

// Grey Extract

/datum/chemical_reaction/slime/grey_blood
	required_container = /obj/item/slime_extract/grey
	required_reagents = list(/datum/reagent/blood = 1)

/datum/chemical_reaction/slime/grey_blood/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	new /obj/item/stack/biomass(get_turf(holder.my_atom), 3) //You can insert these into the biomass recycler and get 3 monkey cubes
	return ..()

/datum/chemical_reaction/slime/grey_plasma
	required_container = /obj/item/slime_extract/grey
	required_reagents = list(/datum/reagent/toxin/plasma = 1)

/datum/chemical_reaction/slime/grey_plasma/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/mob/living/simple_animal/slime/color/grey/slime = new(get_turf(holder.my_atom))
	slime.visible_message(span_danger("[holder.my_atom] begins to grow as it is injected with plasma and turns into a small grey slime!"))
	return ..()

// ************************************************
// ******************* TIER TWO *******************
// ************************************************

// Orange Extract

/datum/chemical_reaction/slime/orange_blood
	required_container = /obj/item/slime_extract/orange
	required_reagents = list(/datum/reagent/blood = 3)
	results = list(/datum/reagent/phosphorus = 1, /datum/reagent/potassium = 1, /datum/reagent/consumable/sugar = 1, /datum/reagent/consumable/capsaicin = 2)

/datum/chemical_reaction/slime/orange_plasma
	required_reagents = list(/datum/reagent/toxin/plasma = 1)
	required_container = /obj/item/slime_extract/orange

/datum/chemical_reaction/slime/orange_plasma/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/atom/cycle_loc = holder.my_atom
	while(!isturf(cycle_loc) && !ishuman(cycle_loc))
		cycle_loc = cycle_loc.loc

	if(!ishuman(cycle_loc))
		cycle_loc.visible_message(span_warning("[holder.my_atom] starts to expand, but fails to find something to latch onto and deflates!"))
		deletes_extract = FALSE
		return ..()

	var/mob/living/carbon/human/owner = cycle_loc
	owner.apply_status_effect(/datum/status_effect/slime/orange)
	return ..()


// Purple Extract

/datum/chemical_reaction/slime/purple_blood
	required_container = /obj/item/slime_extract/purple
	required_reagents = list(/datum/reagent/blood = 1)
	results = list(/datum/reagent/medicine/regen_jelly = 5)

/datum/chemical_reaction/slime/purple_plasma
	required_container = /obj/item/slime_extract/purple
	required_reagents = list(/datum/reagent/toxin/plasma = 1)

/datum/chemical_reaction/slime/purple_plasma/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	new /obj/item/slime_potion/slime_steroid(get_turf(holder.my_atom))
	return ..()

// Blue Extract

/datum/chemical_reaction/slime/blue_plasma
	required_container = /obj/item/slime_extract/blue
	required_reagents = list(/datum/reagent/toxin/plasma = 1)
	results = list(/datum/reagent/consumable/frostoil = 10)

/datum/chemical_reaction/slime/blue_blood
	required_container = /obj/item/slime_extract/blue
	required_reagents = list(/datum/reagent/blood = 1)

/datum/chemical_reaction/slime/blue_blood/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	new /obj/item/slime_potion/slime_stabilizer(get_turf(holder.my_atom))
	return ..()

/datum/chemical_reaction/slime/blue_water
	required_container = /obj/item/slime_extract/blue
	required_reagents = list(/datum/reagent/water = 1)

/datum/chemical_reaction/slime/blue_water/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	new /obj/item/grenade/frost_core(get_turf(holder.my_atom))
	return ..()

// Metal Extract

/datum/chemical_reaction/slime/metal_plasma
	required_reagents = list(/datum/reagent/toxin/plasma = 1)
	required_container = /obj/item/slime_extract/metal

/datum/chemical_reaction/slime/metal_plasma/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/turf/location = get_turf(holder.my_atom)
	new /obj/item/stack/sheet/plasteel(location, 5)
	new /obj/item/stack/sheet/iron(location, 15)
	return ..()

/datum/chemical_reaction/slime/metal_water
	required_reagents = list(/datum/reagent/water = 1)
	required_container = /obj/item/slime_extract/metal

/datum/chemical_reaction/slime/metal_water/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/turf/location = get_turf(holder.my_atom)
	new /obj/item/stack/sheet/rglass(location, 5)
	new /obj/item/stack/sheet/glass(location, 15)
	return ..()

// ************************************************
// ****************** TIER THREE ******************
// ************************************************

// Yellow Extract

/datum/chemical_reaction/slime/yellow_blood
	required_reagents = list(/datum/reagent/blood = 1)
	required_container = /obj/item/slime_extract/yellow
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_SLIME | REACTION_TAG_DANGEROUS
	deletes_extract = FALSE

/datum/chemical_reaction/slime/yellow_blood/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	empulse(get_turf(holder.my_atom), 3, 7)
	return ..()

/datum/chemical_reaction/slime/yellow_plasma
	required_reagents = list(/datum/reagent/toxin/plasma = 1)
	required_container = /obj/item/slime_extract/yellow

/datum/chemical_reaction/slime/yellow_plasma/on_reaction(datum/reagents/holder, created_volume)
	new /obj/item/stock_parts/cell/emproof/slime(get_turf(holder.my_atom))
	return ..()

/datum/chemical_reaction/slime/yellow_water
	required_reagents = list(/datum/reagent/water = 1)
	required_container = /obj/item/slime_extract/yellow

/datum/chemical_reaction/slime/yellow_water/on_reaction(datum/reagents/holder, created_volume)
	var/turf/location = get_turf(holder.my_atom)
	location.visible_message(span_danger("[holder.my_atom] explodes into an electrical field!"))
	playsound(get_turf(src), 'sound/weapons/zapbang.ogg', 50, TRUE)
	for(var/mob/living/victim in view(4, location))
		victim.Beam(location, "lightning[rand(1, 12)]", time = 8)
		victim.electrocute_act(25, src)
		to_chat(victim, span_userdanger("You feel a sharp electrical pulse!"))
	return ..()

// Dark Purple

/datum/chemical_reaction/slime/dark_purple_plasma
	required_reagents = list(/datum/reagent/toxin/plasma = 1)
	required_container = /obj/item/slime_extract/dark_purple

/datum/chemical_reaction/slime/dark_purple_plasma/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	new /obj/item/stack/sheet/mineral/plasma(get_turf(holder.my_atom), 5)
	return ..()

/datum/chemical_reaction/slime/dark_purple_water
	required_reagents = list(/datum/reagent/water = 1)
	required_container = /obj/item/slime_extract/dark_purple
	deletes_extract = FALSE

/datum/chemical_reaction/slime/dark_purple_water/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/obj/item/slime_extract/dark_purple/extract = holder.my_atom
	if(!istype(extract))
		return ..()
	extract.plasma_drain()
	return ..()

// Dark Blue

/datum/chemical_reaction/slime/dark_blue_plasma
	required_reagents = list(/datum/reagent/toxin/plasma = 1)
	required_container = /obj/item/slime_extract/dark_blue
	deletes_extract = FALSE

/datum/chemical_reaction/slime/dark_blue_plasma/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/obj/item/slime_extract/dark_blue/extract = holder.my_atom
	if(!istype(extract) || extract.activated)
		return
	extract.activate()
	attempt_balloon("ready for application", holder)
	return ..()

/datum/chemical_reaction/slime/dark_blue_blood
	required_reagents = list(/datum/reagent/blood = 1)
	required_container = /obj/item/slime_extract/dark_blue

/datum/chemical_reaction/slime/dark_blue_blood/on_reaction(datum/reagents/holder, created_volume)
	new /obj/item/reagent_containers/hypospray/medipen/slimepen/dark_blue(get_turf(holder.my_atom))
	return ..()

// Silver

/datum/chemical_reaction/slime/silver_blood
	required_reagents = list(/datum/reagent/blood = 1)
	required_container = /obj/item/slime_extract/silver

/datum/chemical_reaction/slime/silver_blood/on_reaction(datum/reagents/holder, created_volume)
	new /obj/item/reagent_containers/hypospray/medipen/slimepen/silver(get_turf(holder.my_atom))
	return ..()

/datum/chemical_reaction/slime/silver_plasma
	required_reagents = list(/datum/reagent/toxin/plasma = 1)
	required_container = /obj/item/slime_extract/silver
	deletes_extract = FALSE

/datum/chemical_reaction/slime/silver_plasma/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/obj/item/slime_extract/silver/extract = holder.my_atom
	if(!istype(extract) || extract.activated)
		return
	extract.activate()
	attempt_balloon("ready for application", holder)
	return ..()

/datum/chemical_reaction/slime/silver_water
	required_reagents = list(/datum/reagent/water = 1)
	required_container = /obj/item/slime_extract/silver

/datum/chemical_reaction/slime/silver_water/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/turf/holder_turf = get_turf(holder.my_atom)

	playsound(holder_turf, 'sound/effects/phasein.ogg', 100, TRUE)

	for(var/mob/living/carbon/victim in viewers(holder_turf, null))
		victim.flash_act()

	for(var/i in 1 to 4 + rand(1,2))
		var/chosen = get_random_food()
		var/obj/item/food_item = new chosen(holder_turf)
		food_item.desc += "\n [span_notice("It vaguely smells like acid")]"

		if(istype(food_item, /obj/item/food))
			var/obj/item/food/foody = food_item
			foody.food_flags |= FOOD_SILVER_SPAWNED

		if(prob(5))//Fry it!
			var/obj/item/food/deepfryholder/fried
			fried = new(holder_turf, food_item)
			fried.fry() // actually set the name and colour it

		if(prob(50))
			for(var/j in 1 to rand(1, 3))
				step(food_item, pick(NORTH,SOUTH,EAST,WEST))

		for(var/datum/reagent/consumable/consumable in food_item.reagents.reagent_list)
			food_item.reagents.remove_reagent(consumable.type, consumable.volume * 0.5)

		if(prob(35) && food_item.reagents)
			food_item.reagents.add_reagent(/datum/reagent/toxin/slime_jelly, rand(5, 15))

	return ..()

// ************************************************
// ******************* TIER FOUR ******************
// ************************************************

// Red

/datum/chemical_reaction/slime/red_water
	required_container = /obj/item/slime_extract/red
	required_reagents = list(/datum/reagent/water = 1)

/datum/chemical_reaction/slime/red_water/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	new /obj/item/slime_potion/slime_destabilizer(get_turf(holder.my_atom))
	return ..()

/datum/chemical_reaction/slime/red_blood
	required_reagents = list(/datum/reagent/blood = 1)
	required_container = /obj/item/slime_extract/red
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_SLIME | REACTION_TAG_DANGEROUS

/datum/chemical_reaction/slime/red_blood/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	for(var/mob/living/simple_animal/slime/slime in viewers(10, get_turf(holder.my_atom)))
		if(slime.docile) //Undoes docility, but doesn't make rabid.
			slime.visible_message(span_danger("[slime] forgets its training, becoming wild once again!"))
			slime.docile = FALSE
			slime.update_name()
			new /obj/effect/temp_visual/annoyed/slime(get_turf(slime))
			continue
		ADD_TRAIT(slime, TRAIT_SLIME_RABID, "red_bloodlust")
		slime.visible_message(span_danger("The [slime] is driven into a frenzy!"))
		new /obj/effect/temp_visual/annoyed(get_turf(slime))
	return ..()

/datum/chemical_reaction/slime/red_plasma
	required_container = /obj/item/slime_extract/red
	required_reagents = list(/datum/reagent/toxin/plasma = 1)

/datum/chemical_reaction/slime/red_plasma/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/atom/cycle_loc = holder.my_atom
	while(!isturf(cycle_loc) && !ishuman(cycle_loc))
		cycle_loc = cycle_loc.loc

	if(!ishuman(cycle_loc))
		cycle_loc.visible_message(span_warning("[holder.my_atom] starts to expand, but fails to find something to latch onto and deflates!"))
		deletes_extract = FALSE
		return ..()

	var/mob/living/carbon/human/owner = cycle_loc
	owner.apply_status_effect(/datum/status_effect/slime/red)
	return ..()

// Pink

/datum/chemical_reaction/slime/pink_plasma
	required_container = /obj/item/slime_extract/pink
	required_reagents = list(/datum/reagent/toxin/plasma = 1)

/datum/chemical_reaction/slime/pink_plasma/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	new /obj/item/slime_potion/docility(get_turf(holder.my_atom))
	return ..()

/datum/chemical_reaction/slime/pink_blood
	required_container = /obj/item/slime_extract/pink
	required_reagents = list(/datum/reagent/blood = 1)
	deletes_extract = FALSE

/datum/chemical_reaction/slime/pink_blood/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/obj/item/slime_extract/pink/extract = holder.my_atom
	if(!istype(extract) || extract.activated)
		return
	extract.activate()
	attempt_balloon("ready for application", holder)
	return ..()

// Green

/datum/chemical_reaction/slime/green_plasma
	required_container = /obj/item/slime_extract/green
	required_reagents = list(/datum/reagent/toxin/plasma = 1)
	results = list(/datum/reagent/jelly_toxin = 1)

/datum/chemical_reaction/slime/green_blood
	required_container = /obj/item/slime_extract/green
	required_reagents = list(/datum/reagent/blood = 1)
	results = list(/datum/reagent/jelly_toxin/human = 1)

/datum/chemical_reaction/slime/green_radium
	required_container = /obj/item/slime_extract/green
	required_reagents = list(/datum/reagent/uranium/radium = 1)
	results = list(/datum/reagent/jelly_toxin/lizard = 1)

// Golden

/datum/chemical_reaction/slime/gold_plasma
	required_container = /obj/item/slime_extract/gold
	required_reagents = list(/datum/reagent/toxin/plasma = 1)

/datum/chemical_reaction/slime/gold_plasma/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/obj/item/slime_extract/special/gold_secondary/first_child = new(get_turf(holder.my_atom))
	var/obj/item/slime_extract/special/gold_secondary/second_child = new(get_turf(holder.my_atom))
	first_child.linked_extract = second_child
	second_child.linked_extract = first_child
	return ..()

/datum/chemical_reaction/slime/gold_blood
	required_container = /obj/item/slime_extract/gold
	required_reagents = list(/datum/reagent/blood = 1)
	deletes_extract = FALSE

/datum/chemical_reaction/slime/gold_blood/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/obj/item/slime_extract/gold/extract = holder.my_atom
	if(!istype(extract) || extract.activated)
		return
	extract.activate()
	attempt_balloon("ready for application", holder)
	return ..()

// ************************************************
// ******************* TIER FIVE ******************
// ************************************************

// Bluespace

/datum/chemical_reaction/slime/bluespace_plasma
	required_reagents = list(/datum/reagent/toxin/plasma = 1)
	required_container = /obj/item/slime_extract/bluespace

/datum/chemical_reaction/slime/bluespace_plasma/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/turf/holder_turf = get_turf(holder.my_atom)
	var/obj/item/stack/sheet/bluespace_crystal/crystals = new (holder_turf, 3)
	crystals.visible_message(span_notice("[crystals] appear out of thin air!"))
	playsound(holder_turf, 'sound/effects/phasein.ogg', 100, TRUE)
	return ..()

/datum/chemical_reaction/slime/bluespace_blood
	required_reagents = list(/datum/reagent/blood = 1)
	required_container = /obj/item/slime_extract/bluespace
	deletes_extract = FALSE

/datum/chemical_reaction/slime/bluespace_blood/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/obj/item/slime_extract/bluespace/extract = holder.my_atom
	if(!istype(extract) || extract.activated)
		return
	extract.activate()
	attempt_balloon("ready for usage or throwing", holder)
	return ..()

/datum/chemical_reaction/slime/bluespace_water
	required_reagents = list(/datum/reagent/water = 1)
	required_container = /obj/item/slime_extract/bluespace

/datum/chemical_reaction/slime/bluespace_water/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	new /obj/item/slime_potion/radio(get_turf(holder.my_atom))
	return ..()

// Sepia

/datum/chemical_reaction/slime/sepia_plasma
	required_reagents = list(/datum/reagent/toxin/plasma = 1)
	required_container = /obj/item/slime_extract/sepia
	deletes_extract = FALSE

/datum/chemical_reaction/slime/sepia_plasma/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/obj/item/slime_extract/sepia/extract = holder.my_atom
	if(!istype(extract) || extract.activated)
		return
	extract.activate(explosive = TRUE)
	attempt_balloon("timestop in 5 seconds!", holder)
	return ..()

/datum/chemical_reaction/slime/sepia_blood
	required_reagents = list(/datum/reagent/blood = 1)
	required_container = /obj/item/slime_extract/sepia
	deletes_extract = FALSE

/datum/chemical_reaction/slime/sepia_blood/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/obj/item/slime_extract/sepia/extract = holder.my_atom
	if(!istype(extract) || extract.activated)
		return
	extract.activate(explosive = FALSE)
	attempt_balloon("ready for application", holder)
	return ..()

// Cerulean

/datum/chemical_reaction/slime/cerulean_plasma
	required_container = /obj/item/slime_extract/cerulean
	required_reagents = list(/datum/reagent/toxin/plasma = 1)

/datum/chemical_reaction/slime/cerulean_plasma/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	new /obj/item/slime_potion/enhancer(get_turf(holder.my_atom))
	return ..()

/datum/chemical_reaction/slime/cerulean_blood
	required_container = /obj/item/slime_extract/cerulean
	required_reagents = list(/datum/reagent/blood = 1)
	deletes_extract = FALSE

/datum/chemical_reaction/slime/cerulean_blood/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/obj/item/slime_extract/cerulean/extract = holder.my_atom
	if(!istype(extract) || extract.activated)
		return
	extract.activate()
	attempt_balloon("ready for throwing", holder)
	return ..()

// Pyrite


/datum/chemical_reaction/slime/pyrite_plasma
	required_container = /obj/item/slime_extract/pyrite
	required_reagents = list(/datum/reagent/toxin/plasma = 1)
	deletes_extract = FALSE

/datum/chemical_reaction/slime/pyrite_plasma/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/obj/item/slime_extract/pyrite/extract = holder.my_atom
	if(!istype(extract) || extract.activated)
		return
	extract.activate()
	attempt_balloon("ready for application", holder)
	return ..()

/datum/chemical_reaction/slime/pyrite_blood
	required_reagents = list(/datum/reagent/blood = 1)
	required_container = /obj/item/slime_extract/pyrite

/datum/chemical_reaction/slime/pyrite_blood/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	new /obj/item/stack/tile/pyrite/five(get_turf(holder.my_atom))
	return ..()

/datum/chemical_reaction/slime/pyrite_water
	required_reagents = list(/datum/reagent/water = 1)
	required_container = /obj/item/slime_extract/pyrite

/datum/chemical_reaction/slime/pyrite_water/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	new /obj/item/stack/tile/pyrite/five(get_turf(holder.my_atom))
	return ..()

// ************************************************
// ******************* TIER SIX *******************
// ************************************************

// Oil

/datum/chemical_reaction/slime/oil_plasma
	required_container = /obj/item/slime_extract/oil
	required_reagents = list(/datum/reagent/toxin/plasma = 1)
	deletes_extract = FALSE
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_SLIME | REACTION_TAG_DANGEROUS

/datum/chemical_reaction/slime/oil_plasma/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/obj/item/slime_extract/oil/extract = holder.my_atom
	if(!istype(extract) || extract.activated)
		return
	extract.activate()
	attempt_balloon("explosion in 5 seconds!")
	return ..()

/datum/chemical_reaction/slime/oil_blood
	required_container = /obj/item/slime_extract/oil
	required_reagents = list(/datum/reagent/blood = 1)

/datum/chemical_reaction/slime/oil_blood/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/atom/cycle_loc = holder.my_atom
	while(!isturf(cycle_loc) && !ishuman(cycle_loc))
		cycle_loc = cycle_loc.loc

	if(!ishuman(cycle_loc))
		cycle_loc.visible_message(span_warning("[holder.my_atom] starts to expand, but fails to find something to latch onto and deflates!"))
		deletes_extract = FALSE
		return ..()

	var/mob/living/carbon/human/owner = cycle_loc
	owner.apply_status_effect(/datum/status_effect/slime/oil)
	return ..()

// Black

/datum/chemical_reaction/slime/black_plasma
	required_reagents = list(/datum/reagent/toxin/plasma = 1)
	required_container = /obj/item/slime_extract/black

/datum/chemical_reaction/slime/black_plasma/on_reaction(datum/reagents/holder, created_volume)
	new /obj/item/reagent_containers/hypospray/medipen/slimepen/black(get_turf(holder.my_atom))
	return ..()

/datum/chemical_reaction/slime/black_blood
	required_container = /obj/item/slime_extract/black
	required_reagents = list(/datum/reagent/blood = 1)
	deletes_extract = FALSE

/datum/chemical_reaction/slime/black_blood/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/obj/item/slime_extract/black/extract = holder.my_atom
	if(!istype(extract) || extract.activated)
		return
	extract.activate()
	attempt_balloon("ready for application", holder)
	return ..()

/// Light Pink

/datum/chemical_reaction/slime/light_pink_plasma
	required_container = /obj/item/slime_extract/light_pink
	required_reagents = list(/datum/reagent/toxin/plasma = 1)

/datum/chemical_reaction/slime/light_pink_plasma/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	new /obj/item/slime_potion/sentience(get_turf(holder.my_atom))
	return ..()

/datum/chemical_reaction/slime/light_pink_blood
	required_container = /obj/item/slime_extract/light_pink
	required_reagents = list(/datum/reagent/blood = 1)
	deletes_extract = FALSE

/datum/chemical_reaction/slime/light_pink_blood/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/obj/item/slime_extract/light_pink/extract = holder.my_atom
	if(!istype(extract))
		return
	extract.start_pacifism()
	return ..()

/// Adamantine

/datum/chemical_reaction/slime/adamantine_plasma
	required_container = /obj/item/slime_extract/adamantine
	required_reagents = list(/datum/reagent/toxin/plasma = 1)

/datum/chemical_reaction/slime/adamantine_plasma/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	new /obj/item/stack/sheet/mineral/adamantine(get_turf(holder.my_atom))
	return ..()

/datum/chemical_reaction/slime/adamantine_blood
	required_container = /obj/item/slime_extract/adamantine
	required_reagents = list(/datum/reagent/blood = 1)

/datum/chemical_reaction/slime/adamantine_blood/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/atom/cycle_loc = holder.my_atom
	while(!isturf(cycle_loc) && !ishuman(cycle_loc))
		cycle_loc = cycle_loc.loc

	if(!ishuman(cycle_loc))
		cycle_loc.visible_message(span_warning("[holder.my_atom] starts to expand, but fails to find something to latch onto and deflates!"))
		deletes_extract = FALSE
		return ..()

	var/mob/living/carbon/human/owner = cycle_loc
	owner.apply_status_effect(/datum/status_effect/slime/adamantine)
	return ..()

// ************************************************
// ***************** TIER SPECIAL *****************
// ************************************************

/datum/chemical_reaction/slime/rainbow_plasma
	required_container = /obj/item/slime_extract/special/rainbow
	required_reagents = list(/datum/reagent/toxin/plasma = 1)
	deletes_extract = FALSE

/datum/chemical_reaction/slime/rainbow_plasma/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/obj/item/slime_extract/special/rainbow/extract = holder.my_atom
	if(!istype(extract) || extract.activated)
		return
	extract.activate(TRUE)
	attempt_balloon("ready for application (shield)", holder)
	return ..()

/datum/chemical_reaction/slime/rainbow_blood
	required_container = /obj/item/slime_extract/special/rainbow
	required_reagents = list(/datum/reagent/blood = 1)
	deletes_extract = FALSE

/datum/chemical_reaction/slime/rainbow_blood/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/obj/item/slime_extract/special/rainbow/extract = holder.my_atom
	if(!istype(extract) || extract.activated)
		return
	extract.activate(FALSE)
	attempt_balloon("ready for application (speed)", holder)
	return ..()

/datum/chemical_reaction/slime/fiery_plasma
	required_container = /obj/item/slime_extract/special/fiery
	required_reagents = list(/datum/reagent/toxin/plasma = 1)

/datum/chemical_reaction/slime/fiery_plasma/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	new /obj/item/slime_potion/transference(get_turf(holder.my_atom))
	return ..()

/datum/chemical_reaction/slime/fiery_blood
	required_container = /obj/item/slime_extract/special/fiery
	required_reagents = list(/datum/reagent/blood = 1)

/datum/chemical_reaction/slime/fiery_blood/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	INVOKE_ASYNC(src, .proc/fiery_cascade, get_turf(holder.my_atom))
	return ..()

/datum/chemical_reaction/slime/fiery_blood/proc/fiery_cascade(turf/center)
	playsound(center, 'sound/items/welder.ogg', 75, TRUE)
	for(var/i in 0 to 4)
		for(var/turf/nearby_turf as anything in spiral_range_turfs(i, center))
			new /obj/effect/hotspot(nearby_turf)
			nearby_turf.hotspot_expose(750, 50, 1)
			for(var/mob/living/fried_living in nearby_turf.contents)
				fried_living.adjustFireLoss(5)
		sleep(3)

/datum/chemical_reaction/slime/biohazard_plasma
	required_container = /obj/item/slime_extract/special/biohazard
	required_reagents = list(/datum/reagent/toxin/plasma = 1)
	results = list(/datum/reagent/aslimetoxin = 3)
