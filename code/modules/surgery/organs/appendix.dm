// A 10% chance that out of a group of 25 people, one person will get appendicitis in 1 hour.
#define APPENDICITIS_PROB 100 * (0.1 * (1 / 25) / 3600)
#define INFLAMATION_ADVANCEMENT_PROB 2

/obj/item/organ/appendix
	name = "appendix"
	icon_state = "appendix"
	base_icon_state = "appendix"
	visual = FALSE
	zone = BODY_ZONE_PRECISE_GROIN
	slot = ORGAN_SLOT_APPENDIX
	food_reagents = list(/datum/reagent/consumable/nutriment = 5, /datum/reagent/toxin/bad_food = 5)
	grind_results = list(/datum/reagent/toxin/bad_food = 5)
	healing_factor = STANDARD_ORGAN_HEALING
	decay_factor = STANDARD_ORGAN_DECAY

	now_failing = "<span class='warning'>An explosion of pain erupts in your lower right abdomen!</span>"
	now_fixed = "<span class='info'>The pain in your abdomen has subsided.</span>"

	var/inflamation_stage = 0

/obj/item/organ/appendix/update_name()
	. = ..()
	name = "[inflamation_stage ? "inflamed " : null][initial(name)]"

/obj/item/organ/appendix/update_icon_state()
	icon_state = "[base_icon_state][inflamation_stage ? "inflamed" : ""]"
	return ..()

/obj/item/organ/appendix/on_life(delta_time, times_fired)
	..()
	var/mob/living/carbon/organ_owner = owner
	if(!organ_owner)
		return

	if(organ_flags & ORGAN_FAILING)
		// forced to ensure people don't use it to gain tox as slime person
		organ_owner.adjustToxLoss(2 * delta_time, updating_health = TRUE, forced = TRUE)
	else if(inflamation_stage)
		inflamation(delta_time)
	else if(DT_PROB(APPENDICITIS_PROB, delta_time))
		become_inflamed()

/obj/item/organ/appendix/proc/become_inflamed()
	inflamation_stage = 1
	update_appearance()
	if(owner)
		ADD_TRAIT(owner, TRAIT_DISEASELIKE_SEVERITY_MEDIUM, type)
		owner.med_hud_set_status()

/obj/item/organ/appendix/proc/inflamation(delta_time)
	var/mob/living/carbon/organ_owner = owner
	if(inflamation_stage < 3 && DT_PROB(INFLAMATION_ADVANCEMENT_PROB, delta_time))
		inflamation_stage += 1

	switch(inflamation_stage)
		if(1)
			if(DT_PROB(2.5, delta_time))
				organ_owner.emote("cough")
		if(2)
			if(DT_PROB(1.5, delta_time))
				to_chat(organ_owner, span_warning("You feel a stabbing pain in your abdomen!"))
				organ_owner.adjustOrganLoss(ORGAN_SLOT_APPENDIX, 5)
				organ_owner.Stun(rand(40, 60))
				organ_owner.adjustToxLoss(1, updating_health = TRUE, forced = TRUE)
		if(3)
			if(DT_PROB(0.5, delta_time))
				organ_owner.vomit(95)
				organ_owner.adjustOrganLoss(ORGAN_SLOT_APPENDIX, 15)


/obj/item/organ/appendix/get_availability(datum/species/owner_species)
	return !(TRAIT_NOHUNGER in owner_species.inherent_traits)

/obj/item/organ/appendix/Remove(mob/living/carbon/organ_owner, special = FALSE)
	REMOVE_TRAIT(organ_owner, TRAIT_DISEASELIKE_SEVERITY_MEDIUM, type)
	organ_owner.med_hud_set_status()
	..()

/obj/item/organ/appendix/Insert(mob/living/carbon/organ_owner, special = FALSE)
	..()
	if(inflamation_stage)
		ADD_TRAIT(organ_owner, TRAIT_DISEASELIKE_SEVERITY_MEDIUM, type)
		organ_owner.med_hud_set_status()

/obj/item/organ/appendix/get_status_text()
	if((!(organ_flags & ORGAN_FAILING)) && inflamation_stage)
		return "<font color='#ff9933'>Inflamed</font>"
	else
		return ..()

/obj/item/organ/appendix/slime
	name = "slimy appendix"
	icon_state = "appendix-slime"
	base_icon_state = "appendix-slime"
	healing_factor = SLIME_ORGAN_HEALING

/obj/item/organ/appendix/slime/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/hydrophobic, 0.5, 0, BRUTE)

#undef APPENDICITIS_PROB
#undef INFLAMATION_ADVANCEMENT_PROB
