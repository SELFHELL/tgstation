/datum/traitor_objective/final/tuporixin //Like romerol but with slimes.
	name = "Inject a slime core with tuporixin in a public area to start an outbreak %AREA%"
	description = "Go to %AREA%, and recieve the experemental toxin. Inject it into a slime extract \
	to create an infective biohazard slime and watch the chaos unfold. Warning: The slimes will attack you too."

	///area type the objective owner must be in to recieve the tuporixin
	var/area/tuporixin_spawnarea_type
	///checker on whether we have sent the tuporixin yet.
	var/sent_tuporixin = FALSE

/datum/traitor_objective/final/tuporixin/generate_objective(datum/mind/generating_for, list/possible_duplicates)
	if(!can_take_final_objective())
		return
	var/list/possible_areas = GLOB.the_station_areas.Copy()
	for(var/area/possible_area as anything in possible_areas)
		//remove areas too close to the destination, too obvious for our poor shmuck, or just unfair
		if(istype(possible_area, /area/station/hallway) || istype(possible_area, /area/station/security) || istype(possible_area, /area/station/science/xenobiology))
			possible_areas -= possible_area
	tuporixin_spawnarea_type = pick(possible_areas)
	replace_in_name("%AREA%", initial(tuporixin_spawnarea_type.name))
	return TRUE

/datum/traitor_objective/final/tuporixin/generate_ui_buttons(mob/user)
	var/list/buttons = list()
	if(!sent_tuporixin)
		buttons += add_ui_button("", "Pressing this will call down a pod with the tuporixin injector.", "biohazard", "tuporixin")
	return buttons

/datum/traitor_objective/final/tuporixin/ui_perform_action(mob/living/user, action)
	. = ..()
	switch(action)
		if("tuporixin")
			if(sent_tuporixin)
				return
			var/area/delivery_area = get_area(user)
			if(delivery_area.type != tuporixin_spawnarea_type)
				to_chat(user, span_warning("You must be in [initial(tuporixin_spawnarea_type.name)] to recieve the experimental toxin."))
				return
			sent_tuporixin = TRUE
			podspawn(list(
				"target" = get_turf(user),
				"style" = STYLE_SYNDICATE,
				"spawn" = /obj/item/reagent_containers/syringe/tuporixin,
			))
