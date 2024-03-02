/obj/item/wallframe/pen_manager
	name = "\improper pen manager frame"
	desc = "An unassembled pen manager."
	icon_state = "pen_manager"
	pixel_shift = 29
	result_path = /obj/machinery/pen_manager
	var/obj/item/pen_destignator/pen_destignator

/obj/item/wallframe/pen_manager/after_attach(obj/machinery/pen_manager/manager)
	transfer_fingerprints_to(manager)
	if(pen_destignator)
		manager.pen_destignator = pen_destignator
		pen_destignator.pen_manager = manager

/obj/item/wallframe/pen_manager/attackby(obj/item/W, mob/user, params)
	. = ..()
	if(istype(W, /obj/item/pen_destignator))
		pen_destignator = W
		to_chat(user, span_notice("You link [W] to [src]."))
		playsound(user, 'sound/items/screwdriver2.ogg', 50, TRUE)

/obj/item/pen_destignator
	name = "pen destignator"
	desc = "A small bluespace beacon that pinpoints location of the slime pen it's installed in to the linked pen manager."
	icon = 'icons/obj/xenobiology/machinery.dmi'
	icon_state = "pen_marker"
	w_class = WEIGHT_CLASS_SMALL
	inhand_icon_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	throw_speed = 2
	throw_range = 7
	var/obj/machinery/pen_manager/pen_manager

/obj/item/pen_destignator/wrench_act(mob/living/user, obj/item/tool)
	. = ..()
	if(anchored && isturf(loc))
		anchored = FALSE
		playsound(get_turf(src), 'sound/machines/click.ogg', 75, TRUE)
		to_chat(user, span_notice("You undo the bolts on [src], detaching it from the floor."))
		pen_manager.pen_turfs = null

/obj/item/pen_destignator/attack_self(mob/user, modifiers)
	. = ..()
	if(!pen_manager)
		to_chat(user, span_warning("[src] does not have a working pen manager linked to it!")) //Create a pen manager first and declare it's pen afterwards
		return

	var/list/turfs = detect_room(get_turf(src), list(/turf/open/space), 100)
	var/list/pen_turfs = list()
	for(var/turf/turf in turfs)
		var/is_pen = TRUE
		for(var/direction in GLOB.alldirs)
			if(!(get_step(turf, direction) in turfs))
				is_pen = FALSE
				break

		if(isclosedturf(turf))
			is_pen = FALSE

		if(is_pen)
			pen_turfs += turf

	if(!pen_turfs)
		to_chat(user, span_warning("The slime pen must be completely airtight."))
		return

	if(length(pen_turfs) > MAXIMUM_SLIME_PEN_SIZE)
		to_chat(user, span_warning("The room you're attempting to destignate as a slime pen is too big!"))
		return

	if(loc == user)
		if(!user.temporarilyRemoveItemFromInventory(src))
			to_chat(user, span_warning("[src] is stuck to your hands!"))
			return

	playsound(get_turf(src), 'sound/machines/click.ogg', 75, TRUE)
	forceMove(get_turf(src))
	to_chat(user, span_notice("You put [src] down and it attaches itself to [loc], destignating a new slime pen."))
	anchored = TRUE
	for(var/turf/pen_turf in pen_turfs)
		new /obj/effect/temp_visual/xenobio_blast/pen_destignator(pen_turf)
	pen_manager.pen_turfs = pen_turfs

/obj/effect/temp_visual/xenobio_blast
	icon_state = "xenobio_blast"
	duration = 7.4

/obj/effect/temp_visual/xenobio_blast/pen_destignator
	name = "slime pen destignation field"
	color = COLOR_NAVY

/obj/machinery/pen_manager
	name = "pen manager"
	desc = "A wall-mounted console used to managing slimes."
	icon = 'icons/obj/xenobiology/machinery.dmi'
	icon_state = "pen_manager"
	var/obj/item/pen_destignator/pen_destignator
	var/list/pen_turfs = list()
	var/list/machinery = list()
	var/slimes_rabid = FALSE
	var/slimes_detected = FALSE
	var/slimes_fine = TRUE

/obj/machinery/pen_manager/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/machinery/pen_manager/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/machinery/pen_manager/update_overlays()
	. = ..()
	cut_overlays()
	if(machine_stat & (BROKEN|NOPOWER))
		return

	var/mutable_appearance/light1 = mutable_appearance(icon, "[icon_state]_light1")
	light1.dir = dir
	if(slimes_detected)
		if(slimes_fine)
			light1.color = "#42ff3c"
		else
			light1.color = "#ff3c3c"
	else
		light1.color = "#ffdb3c"

	var/mutable_appearance/light2 = mutable_appearance(icon, "[icon_state]_light2")
	light2.dir = dir

	if(slimes_detected)
		if(slimes_rabid)
			light2.color = "#ff3c3c"
		else
			light2.color = "#42ff3c"
	else
		light2.color = "#ffdb3c"

	. += light1
	. += light2

/obj/machinery/pen_manager/attackby(obj/item/I, mob/user, params)
	. = ..()

	if(istype(I, /obj/item/pen_destignator))
		var/obj/item/pen_destignator/destignator = I
		pen_destignator = destignator
		destignator.pen_manager = src
		to_chat(user, span_notice("You link [destignator] to [src]."))
		playsound(user, 'sound/items/screwdriver2.ogg', 50, TRUE)

	if(default_unfasten_wrench(user, I))
		return TRUE

/obj/machinery/pen_manager/default_unfasten_wrench(mob/user, obj/item/wrench, time)
	. = ..()

	if(. != SUCCESSFUL_UNFASTEN)
		return

	var/obj/item/wallframe/pen_manager/wall_mount = new(get_turf(src))
	if(pen_destignator)
		pen_destignator.pen_manager = null
		wall_mount.pen_destignator = pen_destignator
	qdel(src)

/obj/machinery/pen_manager/proc/get_creatures(slime_only = FALSE)
	var/list/creature_list = list()
	for(var/turf/pen_turf in pen_turfs)
		for(var/mob/living/simple_animal/creature in pen_turf)
			if(!isslime(creature) && slime_only)
				continue
			creature_list += creature
		for(var/mob/living/carbon/human/monke in pen_turf)
			if(ismonkey(monke) && !slime_only)
				creature_list += monke
	return creature_list

/obj/machinery/pen_manager/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PenManager", name)
		ui.open()

/obj/machinery/pen_manager/process()
	if(machine_stat & (BROKEN|NOPOWER))
		return

	var/prev_fine = slimes_fine
	var/prev_detected = slimes_detected
	var/prev_rabid = slimes_rabid

	slimes_fine = TRUE
	slimes_detected = FALSE
	slimes_rabid = FALSE

	for(var/mob/living/simple_animal/slime/slime in get_creatures(slime_only = TRUE))
		slimes_detected = TRUE
		if(HAS_TRAIT(slime, TRAIT_SLIME_RABID))
			slimes_rabid = TRUE
		if(!slime.slime_color.fitting_environment)
			slimes_fine = FALSE

	if(prev_fine == slimes_fine && prev_detected == slimes_detected && prev_rabid == slimes_rabid)
		return

	update_icon()

/obj/machinery/pen_manager/ui_data()
	var/data = list()

	var/list/creature_data = list()
	for(var/mob/living/creature in get_creatures())
		var/list/creature_info = list("name" = creature.name,
									  "health" = creature.health / creature.maxHealth * 100,
									  "is_slime" = isslime(creature),
									  "stat" = (creature.stat == DEAD ? "Dead" : (creature.health < creature.maxHealth ? "Injured" : "Healthy"))
									  )

		if(isslime(creature))
			var/mob/living/simple_animal/slime/slime = creature

			creature_info["nutrition"] = slime.nutrition / slime.get_max_nutrition() * 100
			creature_info["growth"] = slime.amount_grown / SLIME_EVOLUTION_THRESHOLD * 100
			if(slime.cores < slime.max_cores)
				creature_info["core_growth"] = slime.core_generation / SLIME_MAX_CORE_GENERATION * 100
			if(slime.cores > 1)
				creature_info["cores"] = "[slime.cores - 1] additional cores detected."
			creature_info["food_types"] = ""
			if(slime.slime_color.environmental_req)
				creature_info["environmental"] = slime.slime_color.environmental_req
			if(slime.slime_color.food_types)
				for(var/food_type in slime.slime_color.food_types)
					var/atom/food = food_type
					if(creature_info["food_types"] != "")
						creature_info["food_types"] = "[creature_info["food_types"]], "
					creature_info["food_types"] = "[creature_info["food_types"]][capitalize(initial(food.name))]"
		creature_data.Add(list(creature_info))

	data["creature_data"] = creature_data

	machinery = list()

	var/list/heater_data = list()
	for(var/turf/pen_turf in pen_turfs)
		for(var/obj/machinery/space_heater/wall_mount/heater in pen_turf)
			var/list/heater_info = list("ref" = REF(heater),
							   			"name" = heater.name,
							   			"on" = heater.on,
							   			"targetTemp" = round(heater.target_temperature - T0C, 1),
							   			"minTemp" = max(heater.settable_temperature_median - heater.settable_temperature_range, TCMB) - T0C,
							   			"maxTemp" = heater.settable_temperature_median + heater.settable_temperature_range - T0C,
							   			)
			var/datum/gas_mixture/enviroment = pen_turf.return_air()
			var/current_temperature = enviroment.temperature
			if(isnull(current_temperature))
				heater_info["currentTemp"] = "N/A"
			else
				heater_info["currentTemp"] = round(current_temperature - T0C, 1)
			heater_data.Add(list(heater_info))
			machinery.Add(heater)
	data["heater_data"] = heater_data

	var/list/discharger_data = list()
	for(var/turf/pen_turf in pen_turfs)
		for(var/obj/machinery/power/energy_accumulator/slime_discharger/discharger in pen_turf)
			var/list/discharger_info = list("ref" = REF(discharger),
							   				"name" = discharger.name,
							   				"on" = discharger.on,
											"stored_power" = display_joules(discharger.get_stored_joules()),
							   				)
			discharger_data.Add(list(discharger_info))
			machinery.Add(discharger)
	data["discharger_data"] = discharger_data

	var/list/device_data = list() //For simple on-off only devices
	for(var/turf/pen_turf in pen_turfs)
		for(var/obj/machinery/xenobio_device/device in pen_turf)
			var/list/device_info = list("ref" = REF(device),
							   			"name" = device.name,
							   			"on" = device.on,
							   			)
			device_data.Add(list(device_info))
			machinery.Add(device)
	data["device_data"] = device_data

	return data

/obj/machinery/pen_manager/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("heater_power")
			var/obj/machinery/space_heater/wall_mount/heater = locate(params["ref"]) in machinery
			if(!heater)
				return
			heater.toggle_power()

		if("heater_mode")
			var/obj/machinery/space_heater/wall_mount/heater = locate(params["ref"]) in machinery
			if(!heater)
				return
			heater.set_mode = params["mode"]

		if("heater_target")
			var/obj/machinery/space_heater/wall_mount/heater = locate(params["ref"]) in machinery
			if(!heater)
				return
			var/target = params["target"]
			if(text2num(target) != null)
				target = text2num(target) + T0C
				. = TRUE
			if(.)
				heater.target_temperature = clamp(round(target),
					max(heater.settable_temperature_median - heater.settable_temperature_range, TCMB),
					heater.settable_temperature_median + heater.settable_temperature_range)

		if("discharger_power")
			var/obj/machinery/power/energy_accumulator/slime_discharger/discharger = locate(params["ref"]) in machinery
			if(!discharger)
				return
			discharger.on = !discharger.on
			discharger.update_icon()

		if("device_power")
			var/obj/machinery/xenobio_device/device = locate(params["ref"]) in machinery
			if(!device)
				return

			device.toggle(!device.on)
