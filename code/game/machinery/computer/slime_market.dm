/obj/machinery/computer/slime_market
	name = "slime market console"
	desc = "Used to sell slime cores and manage intergalactic slime bounties."
	icon_screen = "slime_market"
	icon_keyboard = "rd_key"
	light_color = LIGHT_COLOR_LAVENDER
	circuit = /obj/item/circuitboard/computer/slime_market
	var/obj/machinery/slime_market_pad/market_pad
	var/obj/machinery/slime_bounty_pad/bounty_pad
	var/datum/xenobio_bounty/current_bounty
	var/list/total_bounties = list()

/obj/machinery/computer/slime_market/Initialize(mapload, obj/item/circuitboard/C)
	. = ..()
	link_market_pad()
	link_bounty_pad()

/obj/machinery/computer/slime_market/proc/link_market_pad()
	if(market_pad)
		return

	for(var/direction in GLOB.cardinals)
		market_pad = locate(/obj/machinery/slime_market_pad, get_step(src, direction))
		if(market_pad)
			market_pad.link_console()
			break

	return market_pad

/obj/machinery/computer/slime_market/proc/link_bounty_pad()
	if(bounty_pad)
		return

	for(var/direction in GLOB.cardinals)
		bounty_pad = locate(/obj/machinery/slime_bounty_pad, get_step(src, direction))
		if(bounty_pad)
			bounty_pad.link_console()
			break

	return bounty_pad

/obj/machinery/computer/slime_market/proc/send_bounty()
	if(!current_bounty || !bounty_pad)
		return

	var/list/items_on_the_pad = list()
	var/list/required_items = current_bounty.requirements.Copy()
	for(var/atom/atom_on_pad in get_turf(bounty_pad))
		for(var/required_type in required_items)
			if(istype(atom_on_pad, required_type))
				items_on_the_pad.Add(atom_on_pad)
				required_items[required_type] -= 1
				if(required_items[required_type] <= 0)
					required_items.Remove(required_type)
				break

	if(LAZYLEN(required_items))
		playsound(get_turf(bounty_pad), 'sound/machines/buzz-sigh.ogg', 100, TRUE)
		bounty_pad.say("Unable to send bounty: Missing required objects.")
		return

	playsound(get_turf(bounty_pad), 'sound/weapons/flash.ogg', 100, TRUE)
	flick("[initial(bounty_pad.icon_state)]_activate", bounty_pad)
	sleep(3.2)

	for(var/atom/atom_on_pad in items_on_the_pad)
		current_bounty.process_item(atom_on_pad)

	sleep(12)
	flick("[initial(bounty_pad.icon_state)]_activate", bounty_pad)
	current_bounty.reward(bounty_pad)

/obj/machinery/computer/slime_market/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet/xenobio_market),
	)

/obj/machinery/computer/slime_market/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "XenobioMarket", name)
		ui.open()

/obj/machinery/computer/slime_market/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("selected_bounty")
			var/datum/xenobio_bounty/bounty = locate(params["ref"]) in total_bounties
			if(!bounty)
				return
			current_bounty = bounty
		if("send_bounty")
			send_bounty()

/obj/machinery/computer/slime_market/ui_data()
	var/data = list()
	var/list/prices = list()
	var/list/price_row = list()
	var/iter = 1
	for(var/core_type in (subtypesof(/obj/item/slime_extract) - subtypesof(/obj/item/slime_extract/special)))
		if(iter % 4 == 1)
			prices.Add(list(list("key" = LAZYLEN(prices), "prices" = price_row.Copy())))
			price_row = list()

		if(core_type == /obj/item/slime_extract/grey)
			price_row.Add(list(list("key" = iter % 4)))
			iter += 1

		var/obj/item/slime_extract/core = core_type
		var/list/core_data = list("icon" = "[initial(core.icon_state)]-dead",
								  "price" = SSresearch.slime_core_prices[core_type],
								  "key" = iter % 4,
								  )
		price_row.Add(list(core_data))
		iter += 1

		if(core_type == /obj/item/slime_extract/grey)
			core = /obj/item/slime_extract/special/rainbow
			var/list/rainbow_core_data = list("icon" = "[initial(core.icon_state)]-dead",
									"price" = SSresearch.slime_core_prices[/obj/item/slime_extract/special/rainbow],
									"key" = iter % 4,
									)
			price_row.Add(list(rainbow_core_data))
			iter += 1
			price_row.Add(list(list("key" = iter % 4)))
			iter += 1

	data["prices"] = prices

	var/list/corporations = list()
	var/list/corporations_by_name = list()
	for(var/datum/xenobio_corporation/corporation in SSresearch.xenobio_corporations)
		if(corporation.illegal && !(obj_flags & EMAGGED))
			continue

		var/list/corporation_data = list("name" = corporation.name,
									 	 "desc" = corporation.desc,
									 	 "icon" = corporation.icon,
									 	 "relationship" = round(corporation.relationship_level),
									 	 "maximum_relationship" = round(corporation.max_relationship_level),
									 	 "bounties_finished" = corporation.bounties_finished,
									 	 )

		var/list/bounties = list()
		for(var/bounty_level = 1 to corporation.relationship_level)
			var/list/bounty_row = list("iter" = bounty_level, "bounties" = list())
			for(var/datum/xenobio_bounty/bounty in corporation.get_bounties_by_level(bounty_level))
				var/list/bounty_data = list("name" = bounty.name,
									 		"text_requirements" = bounty.text_requirements,
									 		"text_rewards" = bounty.text_rewards,
									 		"author_name" = bounty.author.name,
									  		"ref" = REF(bounty),
											 )
				bounty_row["bounties"] += list(bounty_data)
				if(!(bounty in total_bounties))
					total_bounties.Add(bounty)
			bounties.Add(list(bounty_row))

		corporation_data["bounties"] = bounties
		corporations.Add(list(corporation_data))
		corporations_by_name[corporation.name] = corporation_data

	data["corporations"] = corporations
	data["corporations_by_name"] = corporations_by_name

	if(current_bounty)
		data["current_bounty"] = list("name" = current_bounty.name,
									  "text_requirements" = current_bounty.text_requirements,
									  "text_rewards" = current_bounty.text_rewards,
									  "author_name" = current_bounty.author.name,
									  "ref" = REF(current_bounty),
									  )
	return data
