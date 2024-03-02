/obj/item/slime_accessory
	name = "default slime accessory"
	desc = "Yell at coders if you see this!"
	icon = 'icons/obj/xenobiology/equipment.dmi'
	var/mob/living/simple_animal/slime/owner

/obj/item/slime_accessory/proc/slime_equipped(mob/living/new_owner)
	owner = new_owner
	owner.accessory = src
	owner.regenerate_icons()
	return TRUE

/obj/item/slime_accessory/proc/slime_unequipped(mob/living/former_owner, forced = FALSE)
	former_owner.regenerate_icons()
	owner = null
	return TRUE

/obj/item/slime_accessory/proc/get_damage_modificator()
	return 1

/obj/item/slime_accessory/proc/on_life(delta_time, times_fired)

/obj/item/slime_accessory/translator
	name = "slime translator"
	desc = "A complex device that can be attached to a slime to allow it to speak galactic common."
	icon_state = "accessory_translator"

/obj/item/slime_accessory/translator/slime_equipped(mob/living/simple_animal/slime/new_owner)
	. = ..()
	RegisterSignal(new_owner, COMSIG_MOB_SAY, .proc/handle_speech)

/obj/item/slime_accessory/translator/slime_unequipped(mob/living/simple_animal/slime/former_owner, forced = FALSE)
	. = ..()
	UnregisterSignal(former_owner, COMSIG_MOB_SAY)

/obj/item/slime_accessory/translator/proc/handle_speech(datum/source, list/speech_args)
	SIGNAL_HANDLER

	say(speech_args[SPEECH_MESSAGE], "machine", speech_args[SPEECH_SPANS] | SPAN_ROBOT, language = /datum/language/common)

/obj/item/slime_accessory/crown
	name = "slime crown"
	desc = "A biomechanical crown that's powered by the wearer's power and shows their status to other slimes."
	icon_state = "accessory_crown"

/obj/item/slime_accessory/crown/slime_equipped(mob/living/simple_animal/slime/new_owner, mob/living/equipper)
	. = ..()
	ADD_TRAIT(new_owner, TRAIT_SLIME_KING, SLIME_ACCESSORY_TRAIT)
	new_owner.apply_moodlet(/datum/slime_moodlet/crowned)
	if(istype(new_owner.slime_color, /datum/slime_color/rainbow) && equipper.client)
		equipper.client.give_award(/datum/award/achievement/misc/rainbow_king, equipper)

/obj/item/slime_accessory/crown/slime_unequipped(mob/living/simple_animal/slime/former_owner, mob/living/equipper = null, forced = FALSE)
	. = ..()
	REMOVE_TRAIT(former_owner, TRAIT_SLIME_KING, SLIME_ACCESSORY_TRAIT)
	former_owner.remove_moodlet(/datum/slime_moodlet/crowned)

/obj/item/slime_accessory/friendship_necklace
	name = "friendship necklace"
	desc = "A friendship necklace made out of stabilized plasma. Slimes love these."
	icon_state = "accessory_necklace"

/obj/item/slime_accessory/friendship_necklace/slime_equipped(mob/living/simple_animal/slime/new_owner, mob/living/equipper)
	. = ..()
	new_owner.add_friendship(equipper, 5)
	new_owner.visible_message(span_notice("[new_owner] seems to like [src] and blorbles happily."))
	new_owner.apply_moodlet(/datum/slime_moodlet/friendship_necklace)

/obj/item/slime_accessory/friendship_necklace/slime_unequipped(mob/living/simple_animal/slime/former_owner, mob/living/equipper = null, forced = FALSE)
	. = ..()
	former_owner.add_friendship(equipper, -5)
	former_owner.visible_message(span_warning("[former_owner] tries to hold onto [former_owner.p_their()] [name] as it's being removed by [equipper]!"))
	former_owner.remove_moodlet(/datum/slime_moodlet/friendship_necklace)

/obj/item/slime_accessory/demorpher
	name = "AX-L demorphing module"
	desc = "A small badge-like device that spreads it's nanites throughout the slime it's connected to to and prevents them from changing their form."
	icon_state = "accessory_demorpher"

/obj/item/slime_accessory/demorpher/slime_equipped(mob/living/simple_animal/slime/new_owner, mob/living/equipper = null)
	RegisterSignal(new_owner, COMSIG_SLIME_POST_REGENERATE_ICONS, .proc/add_slime_overlay)
	. = ..()

/obj/item/slime_accessory/demorpher/proc/add_slime_overlay()
	SIGNAL_HANDLER

	var/mutable_appearance/nanite_overlay = mutable_appearance(owner.icon, "[icon_state][owner.is_adult ? "-adult" : ""][owner.stat == DEAD ? "-dead" : ""]-overlay")
	nanite_overlay.layer = owner.layer + 0.03
	owner.add_overlay(nanite_overlay)
	owner.update_icon()

/obj/item/slime_accessory/demorpher/slime_unequipped(mob/living/simple_animal/slime/former_owner, mob/living/equipper = null, forced = FALSE)
	if(forced)
		return ..()
	return FALSE
