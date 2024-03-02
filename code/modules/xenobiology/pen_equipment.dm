/obj/item/xenobio_deployable
	icon = 'icons/obj/xenobiology/machinery.dmi'
	var/deployable_type

/obj/item/xenobio_deployable/attack_self(mob/user, modifiers)
	. = ..()
	if(loc == user)
		if(!user.temporarilyRemoveItemFromInventory(src))
			to_chat(user, span_warning("[src] is stuck to your hands!"))
			return

	deploy(user, modifiers)

/obj/item/xenobio_deployable/proc/deploy(mob/user, modifiers)
	playsound(get_turf(src), 'sound/machines/click.ogg', 75, TRUE)
	to_chat(user, span_notice("You put [src] down and it attaches itself to [loc]."))
	new deployable_type(get_turf(src))
	qdel(src)

/obj/machinery/power/energy_accumulator/slime_discharger
	name = "slime discharger"
	desc = "Prevents all living beings from being electrocuted by those nasty yellow slimes."
	icon = 'icons/obj/xenobiology/machinery.dmi'
	icon_state = "discharger-off"
	base_icon_state = "discharger"
	anchored = TRUE
	density = TRUE
	wants_powernet = FALSE
	can_buckle = FALSE
	var/on = FALSE

/obj/machinery/power/energy_accumulator/slime_discharger/examine(mob/user)
	. = ..()
	if(in_range(user, src) || isobserver(user))
		. += span_notice("The status display reads:<br>" + \
		  "Recently grounded <b>[display_joules(get_stored_joules())]</b>.<br>" + \
			"This energy would sustainably release <b>[display_power(get_power_output())]</b>.")

/obj/machinery/power/energy_accumulator/slime_discharger/default_unfasten_wrench(mob/user, obj/item/I, time = 20)
	. = ..()
	if(. != SUCCESSFUL_UNFASTEN)
		return

	new /obj/item/xenobio_deployable/slime_discharger(get_turf(src))
	playsound(get_turf(src), 'sound/machines/click.ogg', 75, TRUE)
	to_chat(user, span_notice("You undo the bolts on [src], detaching it from the floor."))
	qdel(src)

/obj/machinery/power/energy_accumulator/slime_discharger/process(delta_time)
	for(var/mob/living/simple_animal/slime/slime in range(2, src))
		if(slime.slime_color.slime_tags & SLIME_DISCHARGER_WEAKENED)
			slime.adjust_nutrition(SLIME_DISCHARGER_NUTRIMENT_DRAIN * delta_time)
			if(!slime.target && DT_PROB(SLIME_DISCHARGER_AGGRESSIVE_EFFECT, delta_time))
				slime.set_target(src)

		if(slime.powerlevel > 2 && DT_PROB(SLIME_DISCHARGE_PROB, delta_time))
			stored_energy += joules_to_energy((slime.powerlevel - round(slime.powerlevel / 2)) * SLIME_POWER_LEVEL_ENERGY)
			slime.powerlevel = round(slime.powerlevel / 2)
			if(prob(SLIME_DISCHARGE_EFFECT_PROB))
				Beam(slime, icon_state="lightning[rand(1,12)]", time = 5)

/obj/machinery/power/energy_accumulator/slime_discharger/update_icon_state()
	icon_state = "[base_icon_state][on ? "" : "-off"]"
	return ..()

/obj/machinery/power/energy_accumulator/slime_discharger/attackby(obj/item/W, mob/user, params)
	if(default_unfasten_wrench(user, W))
		return

	return ..()

/obj/machinery/power/energy_accumulator/slime_discharger/zap_act(power, zap_flags)
	if(on)
		flick("discharger-shock", src)
		stored_energy += joules_to_energy(power) * 400
		return 0
	else
		. = ..()

/obj/item/xenobio_deployable/slime_discharger
	name = "slime discharger"
	desc = "Prevents all living beings from being electrocuted by those nasty yellow slimes."
	icon_state = "discharger-off"
	w_class = WEIGHT_CLASS_NORMAL
	inhand_icon_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	deployable_type = /obj/machinery/xenobio_device/vacuole_stabilizer

/obj/item/xenobio_deployable/slime_discharger/deploy(mob/user, modifiers)
	for(var/turf/discharger_turf in range(2, get_turf(src)))
		new /obj/effect/temp_visual/xenobio_blast/discharger(discharger_turf)
	. = ..()

/obj/effect/temp_visual/xenobio_blast/discharger
	name = "discharger field"
	color = COLOR_YELLOW

/obj/machinery/xenobio_device
	anchored = TRUE
	icon = 'icons/obj/xenobiology/machinery.dmi'
	var/on = FALSE
	var/device_type

/obj/machinery/xenobio_device/Destroy()
	toggle(FALSE)
	return ..()

/obj/machinery/xenobio_device/wrench_act(mob/living/user, obj/item/tool)
	. = ..()
	default_unfasten_wrench(user, tool)
	return TOOL_ACT_TOOLTYPE_SUCCESS

/obj/machinery/xenobio_device/default_unfasten_wrench(mob/user, obj/item/I, time = 20)
	. = ..()
	if(. != SUCCESSFUL_UNFASTEN)
		return

	if(device_type)
		new device_type(get_turf(src))
	playsound(get_turf(src), 'sound/machines/click.ogg', 75, TRUE)
	to_chat(user, span_notice("You undo the bolts on [src], detaching it from the floor."))
	qdel(src)

/obj/machinery/xenobio_device/proc/toggle(new_state = FALSE)
	if(on == new_state)
		return

	on = new_state
	update_icon()

	if(on)
		START_PROCESSING(SSfastprocess, src)
	else
		STOP_PROCESSING(SSfastprocess, src)

/obj/machinery/xenobio_device/process()
	if(machine_stat & (BROKEN|NOPOWER))
		toggle(FALSE)
		return FALSE

	return TRUE

/obj/machinery/xenobio_device/update_icon_state()
	set_icon_state()
	return ..()

/obj/machinery/xenobio_device/proc/set_icon_state()
	icon_state = "[base_icon_state][on ? "" : "-off"]"

/obj/machinery/xenobio_device/vacuole_stabilizer
	name = "vacuole stabilizer"
	desc = "This device stabilizes vacuoles of silver and oil slimes."
	icon_state = "stabilizer-off"
	base_icon_state = "stabilizer"
	density = TRUE
	light_color = "#FEC429"
	light_power = 2
	light_range = 1
	device_type = /obj/item/xenobio_deployable/vacuole_stabilizer

/obj/machinery/xenobio_device/vacuole_stabilizer/Initialize(mapload)
	. = ..()
	set_light_on(on)

/obj/machinery/xenobio_device/vacuole_stabilizer/update_icon_state()
	set_light_on(on)
	return ..()

/obj/item/xenobio_deployable/vacuole_stabilizer
	name = "vacuole stabilizer"
	desc = "This device stabilizes vacuoles of silver and oil slimes."
	icon_state = "stabilizer-off"
	w_class = WEIGHT_CLASS_NORMAL
	inhand_icon_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	deployable_type = /obj/machinery/xenobio_device/vacuole_stabilizer

/obj/item/xenobio_deployable/vacuole_stabilizer/deploy(mob/user, modifiers)
	for(var/turf/stabilizer_turf in range(3, get_turf(src)))
		new /obj/effect/temp_visual/xenobio_blast/vacuole_stabilizer(stabilizer_turf)
	return ..()

/obj/effect/temp_visual/xenobio_blast/vacuole_stabilizer
	name = "vacuole stabilizer field"
	color = COLOR_WHITE

/obj/item/wallframe/space_heater
	name = "\improper space heater frame"
	desc = "A space heater detached from a wall."
	icon_state = "space_heater"
	pixel_shift = 29
	result_path = /obj/machinery/space_heater/wall_mount

/obj/machinery/space_heater/wall_mount
	icon = 'icons/obj/xenobiology/machinery.dmi'
	anchored = TRUE
	density = FALSE
	use_power = TRUE
	use_cell = FALSE
	cell = null

/obj/machinery/space_heater/wall_mount/default_unfasten_wrench(mob/user, obj/item/wrench, time)
	. = ..()

	if(. != SUCCESSFUL_UNFASTEN)
		return

	new /obj/item/wallframe/space_heater(get_turf(src))
	qdel(src)

/obj/machinery/space_heater/wall_mount/RefreshParts() //Less power more range
	. = ..()

	var/laser = 0
	var/cap = 0
	for(var/obj/item/stock_parts/micro_laser/M in component_parts)
		laser += M.rating
	for(var/obj/item/stock_parts/capacitor/M in component_parts)
		cap += M.rating

	heating_power = laser * 35000
	settable_temperature_range = cap * 50

/obj/item/xenobio_deployable/bluespace_anchor
	name = "bluespace anchor"
	desc = "This device blocks low-power bluespace teleportation used by bluespace slimes, preventing them from escaping from their cells. \
			However, this may cause some other bluespace-connected slimes to become unstable and start chaotically teleporting around."
	icon_state = "bluespace_anchor-off"
	w_class = WEIGHT_CLASS_NORMAL
	inhand_icon_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	deployable_type = /obj/machinery/xenobio_device/bluespace_anchor

/obj/effect/temp_visual/xenobio_blast/bluespace
	name = "bluespace stabilizer field"
	color = COLOR_CYAN

/obj/machinery/xenobio_device/bluespace_anchor
	name = "bluespace anchor"
	desc = "This device blocks low-power bluespace teleportation used by bluespace slimes, preventing them from escaping from their cells. \
			However, this may cause some other bluespace-connected slimes to become unstable and start chaotically teleporting around."
	icon_state = "bluespace_anchor-off"
	base_icon_state = "bluespace_anchor"
	density = FALSE
	device_type = /obj/item/xenobio_deployable/bluespace_anchor
	var/list/affected_turfs = list()
	var/list/visual_effects = list()
	var/charges = 0

/obj/machinery/xenobio_device/bluespace_anchor/toggle(new_state = TRUE)
	. = ..()

	if(!on || charges <= 0)
		for(var/turf/turf in affected_turfs)
			REMOVE_TRAIT(turf, TRAIT_BLUESPACE_SLIME_FIXATION, XENOBIO_DEPLOYABLE_TRAIT)

		for(var/atom/effect in visual_effects)
			qdel(effect)
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

		if(get_dist(turf, get_turf(src)) > BLUESPACE_ANCHOR_RANGE)
			is_pen = FALSE

		if(is_pen)
			pen_turfs += turf

	if(!pen_turfs)
		break_off()
		return

	if(length(pen_turfs) > MAXIMUM_SLIME_PEN_SIZE)
		break_off()
		return

	for(var/turf/pen_turf in pen_turfs)
		new /obj/effect/temp_visual/xenobio_blast/bluespace(pen_turf)
		affected_turfs += pen_turf
		ADD_TRAIT(pen_turf, TRAIT_BLUESPACE_SLIME_FIXATION, XENOBIO_DEPLOYABLE_TRAIT)

	for(var/turf/pen_turf in pen_turfs)
		var/list/non_pen_dirs = list()
		for(var/direction in GLOB.alldirs)
			if(!(get_step(pen_turf, direction) in pen_turfs))
				non_pen_dirs += direction

		if(LAZYLEN(non_pen_dirs))
			var/list/cardinal_dirs = list()
			for(var/card in GLOB.cardinals)
				if(card in non_pen_dirs)
					cardinal_dirs += card


			var/list/diagonal_dirs = list()
			for(var/diag in GLOB.diagonals)
				if(diag in non_pen_dirs)
					diagonal_dirs += diag

			if(LAZYLEN(cardinal_dirs))
				switch(LAZYLEN(cardinal_dirs))
					if(1)
						var/obj/effect/bluespace_field_edge/edge = new(pen_turf)
						visual_effects += edge
						edge.dir = cardinal_dirs[1]
						if(cardinal_dirs[1] in list(NORTH, SOUTH))
							diagonal_dirs -= EAST | cardinal_dirs[1]
							diagonal_dirs -= WEST | cardinal_dirs[1]
						else
							diagonal_dirs -= NORTH | cardinal_dirs[1]
							diagonal_dirs -= SOUTH | cardinal_dirs[1]
					if(2)
						if(turn(cardinal_dirs[1], 180) == cardinal_dirs[2])
							var/obj/effect/bluespace_field_edge/edge = new(pen_turf)
							visual_effects += edge
							edge.dir = cardinal_dirs[1]

							edge = new(pen_turf)
							visual_effects += edge
							edge.dir = cardinal_dirs[2]

							diagonal_dirs = list()
						else
							var/obj/effect/bluespace_field_edge/edge = new(pen_turf)
							visual_effects += edge
							edge.dir = cardinal_dirs[1] | cardinal_dirs[2]
							if(turn(cardinal_dirs[1] | cardinal_dirs[2], 180) in diagonal_dirs)
								diagonal_dirs = list(turn(cardinal_dirs[1] | cardinal_dirs[2], 180))
							else
								diagonal_dirs = list()
					if(3)
						if((NORTH in cardinal_dirs) && (SOUTH in cardinal_dirs))
							cardinal_dirs -= NORTH
							cardinal_dirs -= SOUTH
						else
							cardinal_dirs -= EAST
							cardinal_dirs -= WEST


						var/obj/effect/bluespace_field_edge/edge = new(pen_turf)
						visual_effects += edge
						edge.icon_state = "bluespace_field_end"
						edge.dir = cardinal_dirs[1]
						edge.update_icon()
						diagonal_dirs = list()
					if(4)
						var/obj/effect/bluespace_field_edge/edge = new(pen_turf)
						visual_effects += edge
						edge.icon_state = "bluespace_field"
						edge.update_icon()
						diagonal_dirs = list()

			if(LAZYLEN(diagonal_dirs))
				for(var/diag_dir in diagonal_dirs)
					var/obj/effect/bluespace_field_edge/edge = new(pen_turf)
					visual_effects += edge
					edge.dir = diag_dir
					edge.icon_state = "bluespace_field_corner"
					edge.update_icon()

/obj/machinery/xenobio_device/bluespace_anchor/process(delta_time)
	. = ..()
	if(!.)
		return

	if(on)
		charges = max(0, charges - delta_time / BLUESPACE_ANCHOR_CHARGE_TIME)
		if(charges <= 0)
			toggle(FALSE)

/obj/machinery/xenobio_device/bluespace_anchor/set_icon_state()
	icon_state = "[base_icon_state][on ? "" : (charges > 0 ? "-off" : "-empty")]"

/obj/effect/bluespace_field_edge
	icon_state = "bluespace_field_edge"

/obj/machinery/xenobio_device/bluespace_anchor/proc/break_off()
	new device_type(get_turf(src))
	playsound(get_turf(src), 'sound/machines/click.ogg', 75, TRUE)
	visible_message(span_warning("[src] fails to boot up and detaches itself from the floor."))
	qdel(src)

/obj/machinery/xenobio_device/bluespace_anchor/attackby(obj/item/tool, mob/user, params)
	. = ..()
	if(istype(tool, /obj/item/stack/ore/bluespace_crystal) || istype(tool, /obj/item/stack/sheet/bluespace_crystal))
		var/obj/item/stack/bs_crystal = tool
		var/charges_to_add = min(bs_crystal.get_amount(), BLUESPACE_ANCHOR_CAPACITY - round(charges))
		if(!charges_to_add)
			to_chat(user, span_warning("[src] is already full!"))
			return
		to_chat(user, span_notice("You refill [src] with [bs_crystal]."))
		bs_crystal.add(-charges_to_add)
		charges += charges_to_add
		update_icon()

	else if(istype(tool, /obj/item/bluespace_anchor_refill))
		var/obj/item/bluespace_anchor_refill/refill = tool
		if(refill.spent)
			to_chat(user, span_warning("[refill] is already spent!"))
			return
		charges = BLUESPACE_ANCHOR_CAPACITY
		update_icon()
		to_chat(user, span_notice("You refill [src] with [tool]."))
		refill.spend()

/obj/item/bluespace_anchor_refill
	name = "bluespace anchor refill"
	desc = "A small sealed capsule containing enriched bluespace dust, meant to recharge bluespace anchors."
	icon = 'icons/obj/xenobiology/equipment.dmi'
	icon_state = "anchor_recharge"
	var/spent = FALSE

/obj/item/bluespace_anchor_refill/proc/spend()
	name = "spent bluespace anchor refill"
	desc = "An open capsule that once contained enriched bluespace dust for a bluespace anchor. Looks like it's been spent."
	icon_state = "anchor_recharge_empty"
	update_icon()
	spent = TRUE

/obj/machinery/xenobio_device/pyrite_thrower
	name = "pyrite thrower"
	desc = "Pyrite throwers are small devices that hold a tiny piece of solidified pyrite slime and use it to create columns of flames to warm up hot-loving slimes."
	icon_state = "pyrite_thrower-off"
	base_icon_state = "pyrite_thrower"
	density = FALSE
	light_color = "#ED7B0E"
	light_power = 2
	light_range = 1
	device_type = /obj/item/xenobio_deployable/pyrite_thrower
	COOLDOWN_DECLARE(activation_cooldown)

/obj/machinery/xenobio_device/pyrite_thrower/Initialize(mapload)
	. = ..()
	set_light_on(on)
	wires = new /datum/wires/pyrite_thrower(src)

/obj/machinery/xenobio_device/pyrite_thrower/Destroy()
	for(var/atom/movable/something in contents)
		something.forceMove(get_turf(src))
	if(wires)
		QDEL_NULL(wires)
	return ..()

/obj/machinery/xenobio_device/pyrite_thrower/attackby(obj/item/weapon, mob/user, params)
	if(is_wire_tool(weapon))
		wires.interact(user)
		return TRUE
	return ..()

/obj/machinery/xenobio_device/pyrite_thrower/update_icon_state()
	set_light_on(on)
	return ..()

/obj/machinery/xenobio_device/pyrite_thrower/process()
	. = ..()
	if(!.)
		return

	for(var/mob/living/simple_animal/slime/slime in range(1, get_turf(src)))
		if(slime.slime_color.slime_tags & SLIME_HOT_LOVING)
			trigger()
			return

/obj/machinery/xenobio_device/pyrite_thrower/proc/trigger()
	if(!COOLDOWN_FINISHED(src, activation_cooldown))
		return
	COOLDOWN_START(src, activation_cooldown, PYRITE_THROWER_COOLDOWN)
	for(var/turf/open/target_turf in range(1, get_turf(src)))
		if(locate(/obj/effect/hotspot) in target_turf)
			continue
		new /obj/effect/hotspot(target_turf)
		playsound(get_turf(src), SFX_SPARKS, 25, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)

/obj/item/xenobio_deployable/pyrite_thrower
	name = "pyrite thrower"
	desc = "Pyrite throwers are small devices, holding a tiny piece of solidified pyrite slime and using it to create columns of flames to warm up hot-loving slimes."
	icon_state = "pyrite_thrower-off"
	w_class = WEIGHT_CLASS_NORMAL
	inhand_icon_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	deployable_type = /obj/machinery/xenobio_device/pyrite_thrower

/obj/item/xenobio_deployable/pyrite_thrower/deploy(mob/user, modifiers)
	for(var/turf/stabilizer_turf in range(1, get_turf(src)))
		new /obj/effect/temp_visual/xenobio_blast/pyrite_thrower(stabilizer_turf)
	return ..()

/obj/effect/temp_visual/xenobio_blast/pyrite_thrower
	name = "vacuole stabilizer field"
	color = "#ED7B0E"

/obj/item/giant_slime_plushie
	name = "giant slime plushie"
	desc = "A huge purple slime plushie sewn of liquid-proof cloth. Slimes love these things."
	icon = 'icons/obj/xenobiology/machinery.dmi'
	icon_state = "slime_plushie"
	lefthand_file = 'icons/mob/inhands/items_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items_righthand.dmi'
	force = 0
	w_class = WEIGHT_CLASS_HUGE
	throwforce = 0
	throw_speed = 1
	throw_range = 2
	hitsound = 'sound/effects/blobattack.ogg'
	item_flags = NO_PIXEL_RANDOM_DROP
	density = TRUE

/obj/item/giant_slime_plushie/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/two_handed, require_twohands=TRUE)

/obj/item/giant_slime_plushie/attack_self(mob/user, modifiers)
	. = ..()
	playsound(get_turf(src), 'sound/effects/blobattack.ogg', 100, TRUE)
	flick("slime_plushie-bopped", src)

/obj/item/giant_slime_plushie/attack_slime(mob/living/simple_animal/slime/user)
	playsound(get_turf(src), 'sound/effects/blobattack.ogg', 100, TRUE)
	flick("slime_plushie-bopped", src)
	if(!user.client)
		user.apply_moodlet(/datum/slime_moodlet/plushie_play)
		if(user.target == src)
			user.set_target(null)
