/**
 * A component to reset the parent to its previous state after some time passes
 */
/datum/component/dejavu

	///message sent when dejavu rewinds
	var/rewind_message = "You remember a time not so long ago..."
	///message sent when dejavu is out of rewinds
	var/no_rewinds_message = "But the memory falls out of your reach."

	/// The turf the parent was on when this components was applied, they get moved back here after the duration
	var/turf/starting_turf
	/// Determined by the type of the parent so different behaviours can happen per type
	var/rewind_type
	/// How many rewinds will happen before the effect ends
	var/rewinds_remaining
	/// How long to wait between each rewind
	var/rewind_interval

	/// The starting value of toxin loss at the beginning of the effect
	var/tox_loss = 0
	/// The starting value of oxygen loss at the beginning of the effect
	var/oxy_loss = 0
	/// The starting value of stamina loss at the beginning of the effect
	var/stamina_loss = 0
	/// The starting value of brain loss at the beginning of the effect
	var/brain_loss = 0
	/// The starting value of brute loss at the beginning of the effect
	/// This only applies to simple animals
	var/brute_loss
	/// The starting value of integrity at the beginning of the effect
	/// This only applies to objects
	var/integrity
	/// A list of body parts saved at the beginning of the effect
	var/list/datum/saved_bodypart/saved_bodyparts

/datum/component/dejavu/Initialize(rewinds = 1, interval = 10 SECONDS)
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE

	starting_turf = get_turf(parent)
	rewinds_remaining = rewinds
	rewind_interval = interval

	if(isliving(parent))
		var/mob/living/L = parent
		tox_loss = L.getToxLoss()
		oxy_loss = L.getOxyLoss()
		stamina_loss = L.getStaminaLoss()
		brain_loss = L.get_organ_loss(ORGAN_SLOT_BRAIN)
		rewind_type = PROC_REF(rewind_living)

	if(iscarbon(parent))
		var/mob/living/carbon/C = parent
		saved_bodyparts = C.save_bodyparts()
		rewind_type = PROC_REF(rewind_carbon)

	else if(isanimal_or_basicmob(parent))
		var/mob/living/animal = parent
		brute_loss = animal.bruteloss
		rewind_type = PROC_REF(rewind_animal)

	else if(isobj(parent))
		var/obj/O = parent
		integrity = O.get_integrity()
		rewind_type = PROC_REF(rewind_obj)

	addtimer(CALLBACK(src, rewind_type), rewind_interval)

/datum/component/dejavu/Destroy()
	starting_turf = null
	saved_bodyparts = null
	return ..()

/datum/component/dejavu/proc/rewind()
	SEND_SIGNAL(parent, COMSIG_DEJAVU_REWIND, src)
	to_chat(parent, span_notice(rewind_message))

	//comes after healing so new limbs comically drop to the floor
	if(starting_turf)
		var/area/destination_area = starting_turf.loc
		if(destination_area.area_flags & NOTELEPORT)
			to_chat(parent, span_warning("For some reason, your head aches and fills with mental fog when you try to think of where you were... It feels like you're now going against some dull, unstoppable universal force."))
		else
			var/atom/movable/master = parent
			master.forceMove(starting_turf)

	rewinds_remaining --
	if(rewinds_remaining)
		addtimer(CALLBACK(src, rewind_type), rewind_interval)
	else
		to_chat(parent, span_notice(no_rewinds_message))
		qdel(src)

/datum/component/dejavu/proc/rewind_living()
	var/mob/living/master = parent
	master.setToxLoss(tox_loss)
	master.setOxyLoss(oxy_loss)
	master.setStaminaLoss(stamina_loss)
	master.setOrganLoss(ORGAN_SLOT_BRAIN, brain_loss)
	rewind()

/datum/component/dejavu/proc/rewind_carbon()
	if(saved_bodyparts)
		var/mob/living/carbon/master = parent
		master.apply_saved_bodyparts(saved_bodyparts)
	rewind_living()

/datum/component/dejavu/proc/rewind_animal()
	var/mob/living/master = parent
	master.bruteloss = brute_loss
	master.updatehealth()
	rewind_living()

/datum/component/dejavu/proc/rewind_obj()
	var/obj/master = parent
	master.update_integrity(integrity)
	rewind()

///differently themed dejavu for modsuits.
/datum/component/dejavu/timeline
	rewind_message = "Your suit rewinds, pulling you through spacetime!"
	no_rewinds_message = "\"Rewind complete. You have arrived at: 10 seconds ago.\""

/datum/component/dejavu/timeline/rewind()
	playsound(get_turf(parent), 'sound/items/modsuit/rewinder.ogg')
	. = ..()

///And for slimes as well!
/datum/component/dejavu/slime
	rewind_message = "You feel horribly nauseous as your sepia extract pulls you through space and time!"
	no_rewinds_message = "You feel your body stabilizing as the now-spent extract finishes its job."

/datum/component/dejavu/slime/rewind()
	playsound(get_turf(parent), 'sound/magic/timeparadox2.ogg', 100, TRUE)
	. = ..()

/datum/component/dejavu/slime/sepia_core

/datum/component/dejavu/slime/coremeister

/datum/saved_bodypart
	var/obj/item/bodypart/old_part
	var/bodypart_type
	var/brute_dam
	var/burn_dam
	var/stamina_dam

/datum/saved_bodypart/New(obj/item/bodypart/part)
	old_part = part
	bodypart_type = part.type
	brute_dam = part.brute_dam
	burn_dam = part.burn_dam
	stamina_dam = part.stamina_dam

/mob/living/carbon/proc/apply_saved_bodyparts(list/datum/saved_bodypart/parts)
	var/list/dont_chop = list()
	for(var/zone in parts)
		var/datum/saved_bodypart/saved_part = parts[zone]
		var/obj/item/bodypart/already = get_bodypart(zone)
		if(QDELETED(saved_part.old_part))
			saved_part.old_part = new saved_part.bodypart_type
		if(!already || already != saved_part.old_part)
			saved_part.old_part.replace_limb(src, TRUE)
		saved_part.old_part.heal_damage(INFINITY, INFINITY, INFINITY, null, FALSE)
		saved_part.old_part.receive_damage(saved_part.brute_dam, saved_part.burn_dam, saved_part.stamina_dam, wound_bonus=CANT_WOUND)
		dont_chop[zone] = TRUE
	for(var/_part in bodyparts)
		var/obj/item/bodypart/part = _part
		if(dont_chop[part.body_zone])
			continue
		part.drop_limb(TRUE)

/mob/living/carbon/proc/save_bodyparts()
	var/list/datum/saved_bodypart/ret = list()
	for(var/_part in bodyparts)
		var/obj/item/bodypart/part = _part
		var/datum/saved_bodypart/saved_part = new(part)

		ret[part.body_zone] = saved_part
	return ret
