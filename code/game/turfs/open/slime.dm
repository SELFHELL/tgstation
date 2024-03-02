/turf/open/misc/slime
	name = "slimy floor"
	desc = "Very slimy and veiny. Probably doesn't taste good either."
	icon_state = "slime_floor"
	baseturfs = /turf/open/openspace
	underfloor_accessibility = UNDERFLOOR_VISIBLE
	footstep = FOOTSTEP_MEAT
	barefootstep = FOOTSTEP_MEAT
	clawfootstep = FOOTSTEP_MEAT
	heavyfootstep = FOOTSTEP_MEAT

/turf/open/misc/slime/Initialize(mapload)
	..()
	return INITIALIZE_HINT_LATELOAD

/turf/open/misc/slime/LateInitialize()
	. = ..()
	AddElement(/datum/element/turf_z_transparency)

/turf/open/misc/slime/ex_act()
	. = ..()
	ScrapeAway(flags = CHANGETURF_INHERIT_AIR)

/turf/open/misc/slime/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	if(the_rcd.mode == RCD_FLOORWALL)
		return list("mode" = RCD_FLOORWALL, "delay" = 5 SECONDS, "cost" = 8)

/turf/open/misc/slime/rcd_act(mob/user, obj/item/construction/rcd/the_rcd, passed_mode)
	if(passed_mode == RCD_FLOORWALL)
		to_chat(user, span_notice("You build a floor."))
		ChangeTurf(/turf/open/floor/plating, flags = CHANGETURF_INHERIT_AIR)
		return TRUE
	return FALSE

/turf/open/misc/slime/burn_tile()
	return

/turf/open/misc/slime/break_tile()
	return

/turf/open/misc/slime/attack_hand(mob/user, list/modifiers)
	if(user.zone_selected != BODY_ZONE_PRECISE_MOUTH || !iscarbon(user))
		return ..()

	var/mob/living/carbon/carbon_user = user

	if(!carbon_user.is_mouth_covered())
		if(carbon_user.combat_mode)
			carbon_user.visible_message(span_warning("[carbon_user] takes a bite out of [src]."), span_warning("You take a bite out of [src] and it tastes horribly."))
			carbon_user.reagents.add_reagent(/datum/reagent/toxin/slime_jelly, 5)
			playsound(src, 'sound/weapons/bite.ogg', 50, TRUE, -1)
			return

		var/obj/item/organ/internal/tongue/licking_tongue = carbon_user.getorganslot(ORGAN_SLOT_TONGUE)
		if(!licking_tongue)
			return

		carbon_user.visible_message(span_warning("[carbon_user] licks [src]."), span_warning("You lick [src] and wonder how did you end up here."))
		carbon_user.reagents.add_reagent(/datum/reagent/toxin/slime_jelly, 1)

/turf/open/misc/slime/attackby(obj/item/I, mob/user, params)
	playsound(src, 'sound/effects/blobattack.ogg', 100, TRUE)
	user.changeNext_move(CLICK_CD_MELEE)
	user.do_attack_animation(src)
	if(prob(I.force * 3 - 15))
		user.visible_message(span_danger("[user] smashes through [src]!"), \
						span_danger("You smash through [src] with [I]!"))
		ScrapeAway(flags = CHANGETURF_INHERIT_AIR)
	else
		to_chat(user, span_danger("You hit [src], to no effect!"))

/turf/open/misc/slime/tool_act(mob/living/user, obj/item/I, tool_type)
	return
