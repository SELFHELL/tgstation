/obj/item/slime_potion
	name = "slime potion"
	desc = "A gelatinous flask with filled with a mysterious substance produced by a slime."
	icon = 'icons/obj/xenobiology/slime_extracts.dmi'

/obj/item/slime_potion/slime_steroid
	name = "slime steroid potion"
	desc = "A gelatinous flask with filled with a slime steroid that will make slimes produce more cores. This effect is somewhat inherited upon splitting."
	icon_state = "potion_steroid"

/obj/item/slime_potion/slime_steroid/attack(mob/living/simple_animal/slime/slime, mob/user)
	if(!isslime(slime))
		to_chat(user, span_warning("[src] only works on slimes!"))
		return ..()

	if(slime.stat == DEAD)
		to_chat(user, span_warning("[slime] is dead!"))
		return

	if(slime.max_cores >= 5)
		to_chat(user, span_warning("[slime]'s core can't split anymore!"))
		return

	to_chat(user, span_notice("You feed [slime] [src]. It will now produce one more extract."))
	slime.max_cores++
	new /obj/effect/temp_visual/slime_plus(get_turf(slime))
	qdel(src)

/obj/item/slime_potion/slime_stabilizer
	name = "slime stabilizer potion"
	desc = "A gelatinous flask with filled with a slime stabilizer that will lower slime's mutation chance."
	icon_state = "potion_stabilizer"

/obj/item/slime_potion/slime_stabilizer/attack(mob/living/simple_animal/slime/slime, mob/user)
	if(!isslime(slime))
		to_chat(user, span_warning("[src] only works on slimes!"))
		return ..()

	if(slime.stat == DEAD)
		to_chat(user, span_warning("[slime] is dead!"))
		return

	if(slime.mutation_chance == 0)
		to_chat(user, span_warning("[slime] already has no chance of mutating!"))
		return

	if(slime.mutator_used)
		to_chat(user, span_warning("[slime] has already been fed a mutator potion, it's core is too unstable for another one!"))
		return

	to_chat(user, span_notice("You feed [slime] [src]. It is now less likely to mutate."))
	slime.mutation_chance = clamp(slime.mutation_chance - 15, 0, 100)
	new /obj/effect/temp_visual/arrow_down(get_turf(slime))
	slime.mutator_used = TRUE
	qdel(src)

/obj/item/slime_potion/slime_destabilizer
	name = "slime destabilizer potion"
	desc = "A gelatinous flask with filled with a slime destabilizer that will increase slime's mutation chance."
	icon_state = "potion_destabilizer"

/obj/item/slime_potion/slime_destabilizer/attack(mob/living/simple_animal/slime/slime, mob/user)
	if(!isslime(slime))
		to_chat(user, span_warning("[src] only works on slimes!"))
		return ..()

	if(slime.stat == DEAD)
		to_chat(user, span_warning("[slime] is dead!"))
		return

	if(slime.mutation_chance == 100)
		to_chat(user, span_warning("[slime] already has maximum chance of mutating!"))
		return

	if(slime.mutator_used)
		to_chat(user, span_warning("[slime] has already been fed a mutator potion, it's core is too unstable for another one!"))
		return

	to_chat(user, span_notice("You feed [slime] [src]]. It is now more likely to mutate."))
	slime.mutation_chance = clamp(slime.mutation_chance + 15, 0, 100)
	new /obj/effect/temp_visual/arrow_up(get_turf(slime))
	slime.mutator_used = TRUE
	qdel(src)

/obj/item/slime_potion/enhancer
	name = "extract enhancer"
	desc = "A potent chemical mix that will give a slime extract an additional use."
	icon_state = "potion_enhancer"

/obj/item/slime_potion/enhancer/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!istype(target, /obj/item/slime_extract))
		return

	var/obj/item/slime_extract/extract = target

	if(extract.uses <= 0 && !extract.activated)
		to_chat(user, span_warning("[extract]'s power is already spent and even [src] can't restore it!"))
		return

	if(extract.uses >= 5)
		to_chat(user, span_warning("You cannot enhance [extract] further!"))
		return

	to_chat(user, span_notice("You apply [src] to [extract], allowing it to be reused a few more times."))
	extract.uses = min(5, extract.uses + 2)
	new /obj/effect/temp_visual/slime_plus/cerulean(get_turf(extract))
	qdel(src)

/obj/item/slime_potion/docility
	name = "docility potion"
	desc = "A potent chemical mix that nullifies a slime's hunger, causing it to become docile and tame."
	icon_state = "potion_docility"

/obj/item/slime_potion/docility/attack(mob/living/simple_animal/slime/slime, mob/user)
	if(!isslime(slime))
		to_chat(user, span_warning("The potion only works on slimes!"))
		return ..()

	if(slime.stat == DEAD)
		to_chat(user, span_warning("The slime is dead!"))
		return

	if(HAS_TRAIT(slime, TRAIT_SLIME_RABID)) //Stops being rabid, but doesn't become truly docile.
		to_chat(slime, span_warning("You absorb the potion, and your rabid hunger finally settles to a normal desire to feed."))
		to_chat(user, span_notice("You feed the slime the potion, calming its rabid rage."))
		REMOVE_TRAIT(slime, TRAIT_SLIME_RABID, null)
		qdel(src)
		return

	slime.docile = TRUE
	slime.set_nutrition(700)
	to_chat(slime, span_warning("You absorb the potion and feel your intense desire to feed melt away."))
	to_chat(user, span_notice("You feed the slime the potion, removing its hunger and calming it."))
	var/newname = sanitize_name(tgui_input_text(user, "Would you like to give the slime a name?", "Name your new pet", "Pet Slime", MAX_NAME_LEN))
	if (!newname)
		newname = "Pet Slime"

	slime.name = newname
	slime.real_name = newname
	qdel(src)

/obj/item/slime_potion/transference
	name = "consciousness transference potion"
	desc = "A strange slime-based chemical that, when used, allows the user to transfer their consciousness to a lesser being."
	icon_state = "potion_transfer"
	var/prompted = FALSE
	var/animal_type = SENTIENCE_ORGANIC

/obj/item/slime_potion/transference/afterattack(mob/living/switchy_mob, mob/living/user, proximity)
	if(!proximity)
		return

	if(prompted || !ismob(switchy_mob))
		return

	if(!(isanimal(switchy_mob) || isbasicmob(switchy_mob))|| switchy_mob.ckey) //much like sentience, these will not work on something that is already player controlled
		to_chat(user, span_warning("[switchy_mob] already has a higher consciousness!"))
		return ..()

	if(switchy_mob.stat)
		to_chat(user, span_warning("[switchy_mob] is dead!"))
		return ..()

	if(isanimal(switchy_mob))
		var/mob/living/simple_animal/switchy_animal= switchy_mob
		if(switchy_animal.sentience_type != animal_type)
			to_chat(user, span_warning("You cannot transfer your consciousness to [switchy_animal].") )
			return ..()
	else	//ugly code duplication, but necccesary as sentience_type is implemented twice.
		var/mob/living/basic/basic_mob = switchy_mob
		if(basic_mob.sentience_type != animal_type)
			to_chat(user, span_warning("You cannot transfer your consciousness to [basic_mob].") )
			return ..()

	var/job_banned = is_banned_from(user.ckey, ROLE_MIND_TRANSFER)
	if(QDELETED(src) || QDELETED(switchy_mob) || QDELETED(user))
		return

	if(job_banned)
		to_chat(user, span_warning("Your mind goes blank as you attempt to use the potion."))
		return

	prompted = TRUE
	if(tgui_alert(usr,"This will permanently transfer your consciousness to [switchy_mob]. Are you sure you want to do this?",,list("Yes","No"))=="No")
		prompted = FALSE
		return

	to_chat(user, span_notice("You drink the potion then place your hands on [switchy_mob]..."))

	user.mind.transfer_to(switchy_mob)
	switchy_mob.copy_languages(user, LANGUAGE_MIND)
	switchy_mob.faction = user.faction.Copy()
	user.death()
	to_chat(switchy_mob, span_notice("In a quick flash, you feel your consciousness flow into [switchy_mob]!"))
	to_chat(switchy_mob, span_warning("You are now [switchy_mob]. Your allegiances, alliances, and role is still the same as it was prior to consciousness transfer!"))
	switchy_mob.name = "[user.real_name]"
	qdel(src)

	if(isanimal(switchy_mob))
		var/mob/living/simple_animal/switchy_animal = switchy_mob
		switchy_animal.sentience_act()

/obj/item/slime_potion/sentience
	name = "intelligence potion"
	desc = "A miraculous chemical mix that grants human like intelligence to living beings."
	icon_state = "potion_sentience"
	var/being_used = FALSE
	var/sentience_type = SENTIENCE_ORGANIC

/obj/item/slime_potion/sentience/attack(mob/living/dumb_mob, mob/user)
	if(being_used || !ismob(dumb_mob))
		return

	if((!isanimal(dumb_mob) && !isbasicmob(dumb_mob)) || dumb_mob.ckey) //only works on animals that aren't player controlled
		to_chat(user, span_warning("[dumb_mob] is already too intelligent for this to work!"))
		return

	if(dumb_mob.stat)
		to_chat(user, span_warning("[dumb_mob] is dead!"))
		return

	if(isanimal(dumb_mob))
		var/mob/living/simple_animal/dumb_animal = dumb_mob
		if(dumb_animal.sentience_type != sentience_type)
			to_chat(user, span_warning("[src] won't work on [dumb_animal]."))
			return

	else if(isbasicmob(dumb_mob)) //duplicate shit code until all simple animasls are made into basic mobs. sentience_type is not on living, but it duplicated  on basic and animal
		var/mob/living/basic/basic_dumb_bitch = dumb_mob
		if(basic_dumb_bitch.sentience_type != sentience_type)
			to_chat(user, span_warning("[src] won't work on [basic_dumb_bitch]."))
			return

	to_chat(user, span_notice("You offer [src] to [dumb_mob]..."))
	being_used = TRUE

	var/list/candidates = poll_candidates_for_mob("Do you want to play as [dumb_mob.name]?", ROLE_SENTIENCE, ROLE_SENTIENCE, 5 SECONDS, dumb_mob, POLL_IGNORE_SENTIENCE_POTION) // see poll_ignore.dm
	if(LAZYLEN(candidates))
		var/mob/dead/observer/C = pick(candidates)
		dumb_mob.key = C.key
		dumb_mob.mind.enslave_mind_to_creator(user)
		SEND_SIGNAL(dumb_mob, COMSIG_SIMPLEMOB_SENTIENCEPOTION, user)
		if(isanimal(dumb_mob))
			var/mob/living/simple_animal/smart_animal = dumb_mob
			smart_animal.sentience_act()
		to_chat(dumb_mob, span_warning("All at once it makes sense: you know what you are and who you are! Self awareness is yours!"))
		to_chat(dumb_mob, span_userdanger("You are grateful to be self aware and owe [user.real_name] a great debt. Serve [user.real_name], and assist [user.p_them()] in completing [user.p_their()] goals at any cost."))
		if(dumb_mob.flags_1 & HOLOGRAM_1) //Check to see if it's a holodeck creature
			to_chat(dumb_mob, span_userdanger("You also become depressingly aware that you are not a real creature, but instead a holoform. Your existence is limited to the parameters of the holodeck."))
		to_chat(user, span_notice("[dumb_mob] accepts [src] and suddenly becomes attentive and aware. It worked!"))
		dumb_mob.copy_languages(user, LANGUAGE_MASTER)
		after_success(user, dumb_mob)
		qdel(src)
	else
		to_chat(user, span_notice("[dumb_mob] looks interested for a moment, but then looks back down. Maybe you should try again later."))
		being_used = FALSE
		return ..()

/obj/item/slime_potion/sentience/proc/after_success(mob/living/user, mob/living/smart_mob)
	return

/obj/item/slime_potion/sentience/nuclear
	name = "syndicate intelligence potion"
	desc = "A miraculous chemical mix that grants human like intelligence to living beings. It has been modified with Syndicate technology to also grant an internal radio implant to the target and authenticate with identification systems."
	icon_state = "potion_sentience_syndie"

/obj/item/slime_potion/sentience/nuclear/after_success(mob/living/user, mob/living/smart_mob)
	var/obj/item/implant/radio/syndicate/imp = new(src)
	imp.implant(smart_mob, user)
	smart_mob.AddComponent(/datum/component/simple_access, list(ACCESS_SYNDICATE, ACCESS_MAINT_TUNNELS))

/obj/item/slime_potion/radio
	name = "bluespace radio potion"
	desc = "A strange chemical that grants those who ingest it the ability to broadcast and receive subscape radio waves."
	icon_state = "potion_radio"

/obj/item/slime_potion/radio/attack(mob/living/target, mob/user)
	if(!ismob(target))
		return ..()

	if(!isanimal(target))
		to_chat(user, span_warning("[target] is too complex for the potion!"))
		return

	if(target.stat == DEAD)
		to_chat(user, span_warning("[target] is dead!"))
		return

	to_chat(user, span_notice("You feed the potion to [target]."))
	to_chat(target, span_notice("Your mind tingles as you are fed the potion. You can hear radio waves now!"))
	var/obj/item/implant/radio/slime/imp = new(src)
	imp.implant(target, user)
	qdel(src)
