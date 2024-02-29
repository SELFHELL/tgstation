/datum/slime_color/rainbow
	color = "rainbow"
	coretype = /obj/item/slime_extract/special/rainbow
	slime_tags = SLIME_BLUESPACE_CONNECTION | SLIME_NO_RANDOM_SPAWN | SLIME_SOCIAL
	environmental_req = "Non-standard slime located. Database entry missing."

/datum/slime_color/fiery
	color = "fiery"
	coretype = /obj/item/slime_extract/special/fiery
	slime_tags = SLIME_HOT_LOVING | SLIME_NO_RANDOM_SPAWN | SLIME_ATTACK_SLIMES | SLIME_WATER_WEAKNESS | SLIME_ANTISOCIAL
	environmental_req = "Non-standard slime located. Subject can manipulate flames and ignite it's targets on attack."
	COOLDOWN_DECLARE(fireball_cooldown)

/datum/slime_color/fiery/New(mob/living/simple_animal/slime/slime)
	. = ..()
	RegisterSignal(slime, COMSIG_SLIME_ATTACK_TARGET, .proc/fiery_attack)
	RegisterSignal(slime, COMSIG_SLIME_ATTEMPT_RANGED_ATTACK, .proc/fireball)

/datum/slime_color/fiery/remove()
	UnregisterSignal(slime, list(COMSIG_SLIME_ATTACK_TARGET, COMSIG_SLIME_ATTEMPT_RANGED_ATTACK))

/datum/slime_color/fiery/proc/fiery_attack(datum/source, atom/attack_target)
	SIGNAL_HANDLER

	if(!isliving(attack_target))
		return

	var/mob/living/victim = attack_target
	if(victim.fire_stacks >= 3)
		return

	victim.adjust_fire_stacks(3)
	victim.ignite_mob()

/datum/slime_color/fiery/proc/fireball(datum/source, atom/target)
	SIGNAL_HANDLER

	if(!COOLDOWN_FINISHED(src, fireball_cooldown) || !isliving(target) || !COOLDOWN_FINISHED(slime, attack_cd))
		return

	if(get_dist(slime, target) <= 1)
		return

	COOLDOWN_START(src, fireball_cooldown, FIERY_SLIME_PROJECTILE_COOLDOWN)
	COOLDOWN_START(slime, attack_cd, get_attack_cd(target))
	var/obj/projectile/our_projectile = new /obj/projectile/magic/fireball/minor(get_turf(slime))
	our_projectile.firer = slime
	our_projectile.original = target
	INVOKE_ASYNC(our_projectile, /obj/projectile.proc/fire)

/datum/slime_color/fiery/Life(delta_time, times_fired)
	. = ..()

	if(!HAS_TRAIT(slime, TRAIT_SLIME_RABID))
		ADD_TRAIT(slime, TRAIT_SLIME_RABID, "fiery_slime")

	if(!DT_PROB(20, delta_time))
		return

	for(var/mob/living/victim in range(1, src))
		if(victim.fire_stacks < 2)
			victim.adjust_fire_stacks(2)
			victim.ignite_mob()
			to_chat(victim, span_userdanger("You are set ablaze by [slime]'s heat!"))

/datum/slime_color/biohazard
	color = "biohazard"
	coretype = /obj/item/slime_extract/special/biohazard
	slime_tags = SLIME_NO_RANDOM_SPAWN | SLIME_ATTACK_SLIMES | SLIME_BZ_IMMUNE | SLIME_WATER_RESISTANCE
	environmental_req = "Non-standard slime located. Quarantine or immediate destruction recommended."

/datum/slime_color/biohazard/New(mob/living/simple_animal/slime/slime)
	. = ..()
	slime.AddElement(/datum/element/lifesteal, 5)
	RegisterSignal(slime, COMSIG_SLIME_ATTACK_TARGET, .proc/attempt_poison) //Not using venomous element because it ignores bio armor

/datum/slime_color/biohazard/remove()
	slime.RemoveElement(/datum/element/lifesteal)
	UnregisterSignal(slime, COMSIG_SLIME_ATTACK_TARGET)
	REMOVE_TRAIT(slime, TRAIT_SLIME_RABID, "biohazard_slime")

/datum/slime_color/biohazard/Life(delta_time, times_fired)
	. = ..()
	if(!HAS_TRAIT(slime, TRAIT_SLIME_RABID))
		ADD_TRAIT(slime, TRAIT_SLIME_RABID, "biohazard_slime")

/datum/slime_color/biohazard/proc/attempt_poison(datum/source, atom/target)
	SIGNAL_HANDLER

	if(!iscarbon(target))
		return

	var/mob/living/carbon/victim = target
	if(prob(victim.getarmor(null, BIO)))
		return

	victim.reagents?.add_reagent(/datum/reagent/toxin/tuporixin, 2) //3 hits in a rapid succession to start infection

/datum/slime_color/biohazard/get_attack_cd(atom/attack_target) //Faster than normal ones
	return 2.5 SECONDS
