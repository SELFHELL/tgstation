/**
 * Basically, a fake object that emits light.
 *
 * Why is this used sometimes instead of giving atoms light values directly?
 * Because using these, you can have multiple light sources in a single object.
 */
/obj/effect/dummy/lighting_obj
	name = "lighting"
	desc = "Tell a coder if you're seeing this."
	icon_state = "nothing"
	light_system = OVERLAY_LIGHT
	light_range = MINIMUM_USEFUL_LIGHT_RANGE
	light_color = COLOR_WHITE
	blocks_emissive = EMISSIVE_BLOCK_NONE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/dummy/lighting_obj/Initialize(mapload, range, power, color, duration)
	. = ..()
	if(!isnull(range))
		set_light_range(range)
	if(!isnull(power))
		set_light_power(power)
	if(!isnull(color))
		set_light_color(color)
	if(duration)
		QDEL_IN(src, duration)

/obj/effect/dummy/lighting_obj/moblight
	name = "mob lighting"

/obj/effect/dummy/lighting_obj/moblight/Initialize(mapload, range, power, color, duration)
	. = ..()
	if(!ismob(loc))
		return INITIALIZE_HINT_QDEL

/obj/effect/dummy/lighting_obj/moblight/fire
	name = "mob fire lighting"
	light_color = LIGHT_COLOR_FIRE
	light_range = LIGHT_RANGE_FIRE

/obj/effect/hotspot/oil
	light_color = LIGHT_COLOR_HALOGEN

/obj/effect/hotspot/oil/Initialize(mapload, starting_volume, starting_temperature)
	. = ..()
	color = color_matrix_add(color_matrix_saturation(0.25), list(0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0.05,0.05,0.05,0))

/obj/effect/hotspot/oil/handle_burning(turf/open/location)
	for(var/atom/target as anything in location)
		if(QDELETED(target) || target == src)
			continue

		if(!isliving(target) || isanimal(target))
			target.fire_act(temperature, volume)
			continue

		var/mob/living/victim = target
		victim.adjust_fire_stacks(3, /datum/status_effect/fire_handler/fire_stacks/oil) //Sticky oil fire affects even sillycones
		victim.ignite_mob()

/obj/effect/dummy/lighting_obj/moblight/species
	name = "species lighting"
