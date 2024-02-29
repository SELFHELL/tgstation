/// Limbs and organs with this component will get damaged upon being exposed to water

/datum/component/hydrophobic
	var/reagent_damage = 0.5
	var/exposure_damage = 2
	var/damage_type = BRUTE
	var/mob/living/carbon/our_owner
	COOLDOWN_DECLARE(damage_cooldown) //No instakills using extinguishers

/datum/component/hydrophobic/Initialize(_reagent_damage, _exposure_damage, _damage_type)
	. = ..()
	if(!istype(parent, /obj/item/bodypart) && !istype(parent, /obj/item/organ))
		return COMPONENT_INCOMPATIBLE

	if(_reagent_damage)
		reagent_damage = _reagent_damage
	if(_exposure_damage)
		exposure_damage =_exposure_damage
	if(_damage_type)
		damage_type = _damage_type

	if(istype(parent, /obj/item/bodypart))
		RegisterSignal(parent, COMSIG_ATTACH_LIMB, .proc/limb_attached)
		RegisterSignal(parent, COMSIG_REMOVE_LIMB, .proc/limb_removed)
		return

	if(istype(parent, /obj/item/organ))
		RegisterSignal(parent, COMSIG_ORGAN_IMPLANTED, .proc/on_organ_implanted)
		RegisterSignal(parent, COMSIG_ORGAN_REMOVED, .proc/on_organ_removed)
		return

/datum/component/hydrophobic/proc/limb_attached(datum/source, obj/item/bodypart/new_limb, mob/living/carbon/new_owner, special)
	SIGNAL_HANDLER
	RegisterSignal(new_owner, COMSIG_LIVING_APPLY_WATER, .proc/on_water_exposure)
	our_owner = new_owner
	START_PROCESSING(SSobj, src) //Same wait time as SSmobs

/datum/component/hydrophobic/proc/limb_removed(datum/source, obj/item/bodypart/old_limb, mob/living/carbon/last_owner, special)
	SIGNAL_HANDLER
	UnregisterSignal(last_owner, COMSIG_LIVING_APPLY_WATER)
	our_owner = null
	STOP_PROCESSING(SSobj, src)

/datum/component/hydrophobic/proc/on_organ_implanted(datum/source, mob/living/carbon/owner)
	SIGNAL_HANDLER
	RegisterSignal(owner, COMSIG_LIVING_APPLY_WATER, .proc/on_water_exposure)
	our_owner = owner
	START_PROCESSING(SSobj, src)

/datum/component/hydrophobic/proc/on_organ_removed(datum/source, mob/living/carbon/owner)
	SIGNAL_HANDLER
	UnregisterSignal(owner, COMSIG_LIVING_APPLY_WATER)
	our_owner = null
	STOP_PROCESSING(SSobj, src)

/datum/component/hydrophobic/proc/on_water_exposure(datum/source)
	SIGNAL_HANDLER

	if(!COOLDOWN_FINISHED(src, damage_cooldown))
		return

	COOLDOWN_START(src, damage_cooldown, 1)

	if(istype(parent, /obj/item/bodypart))
		var/obj/item/bodypart/bodypart = parent
		bodypart.receive_damage((damage_type == BRUTE ? exposure_damage : 0), (damage_type == BURN ? exposure_damage : 0))
		return

	if(istype(parent, /obj/item/organ))
		var/obj/item/organ/organ = parent
		organ.applyOrganDamage(exposure_damage)
		return

/datum/component/hydrophobic/process(delta_time, times_fired)
	if(!our_owner)
		STOP_PROCESSING(SSobj, src)
		return

	var/datum/reagent/water/found_water = our_owner.reagents.has_reagent(/datum/reagent/water)
	if(!found_water)
		return

	if(istype(parent, /obj/item/bodypart))
		var/obj/item/bodypart/bodypart = parent
		bodypart.receive_damage((damage_type == BRUTE ? reagent_damage * delta_time : 0), (damage_type == BURN ? reagent_damage * delta_time : 0))
		return

	if(istype(parent, /obj/item/organ))
		var/obj/item/organ/organ = parent
		organ.applyOrganDamage(reagent_damage * delta_time)
		return
