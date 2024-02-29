#define SIZE_DOESNT_MATTER -1
#define BABIES_ONLY 0
#define ADULTS_ONLY 1

#define NO_GROWTH_NEEDED 0
#define GROWTH_NEEDED 1

/datum/action/innate/slime
	check_flags = AB_CHECK_CONSCIOUS
	icon_icon = 'icons/mob/actions/actions_slime.dmi'
	background_icon_state = "bg_slime"
	var/needs_growth = NO_GROWTH_NEEDED

/datum/action/innate/slime/IsAvailable()
	. = ..()
	if(!.)
		return
	var/mob/living/simple_animal/slime/slime = owner
	if(needs_growth == GROWTH_NEEDED)
		if(slime.amount_grown >= SLIME_EVOLUTION_THRESHOLD)
			return TRUE
		return FALSE
	return TRUE

/mob/living/simple_animal/slime/verb/feed()
	set category = "Slime"
	set desc = "This will let you feed on any valid food in the surrounding area. This should also be used to halt the feeding process."

	if(stat)
		return FALSE

	var/list/choices = list()
	for(var/mob/living/nearby_mob in view(1, src))
		if(nearby_mob != src && Adjacent(nearby_mob))
			choices += nearby_mob

	for(var/obj/possible_food in view(1, src))
		if(Adjacent(possible_food) && can_feed_on(possible_food, TRUE))
			choices += possible_food

	var/choice = tgui_input_list(src, "Who do you wish to feed on?", "Slime feed", sort_names(choices))
	if(isnull(choice))
		return FALSE

	if(!can_feed_on(choice))
		return FALSE

	if(!isliving(choice))
		gobble_up(choice)
		return TRUE

	var/mob/living/victim = choice
	feed_on(victim)
	return TRUE

/mob/living/simple_animal/slime/proc/gobble_up(atom/movable/food)
	if(!can_feed_on(food, TRUE))
		return

	set_target(null)
	ai_active = FALSE

	var/matrix/animation_matrix = matrix()
	animation_matrix.Scale(0.7)
	animation_matrix.Translate((x - food.x) * 32, (y - food.y) * 32)
	animate(food, alpha = 0, time = 6, easing = QUAD_EASING|EASE_IN, transform = animation_matrix, flags = ANIMATION_PARALLEL)
	sleep(6)
	food.forceMove(src)
	digesting = food
	digestion_progress = 0

	digestion_overlay = mutable_appearance(food.icon, food.icon_state, layer = src.layer + 0.02, plane = src.plane)
	digestion_overlay.pixel_x = pixel_x
	digestion_overlay.pixel_y = pixel_y
	digestion_overlay.transform = matrix().Scale(0.7)
	digestion_overlay.color = food.color
	digestion_overlay.alpha = 150
	add_overlay(digestion_overlay)
	next_overlay_scale = 0.6

/datum/action/innate/slime/feed
	name = "Feed"
	button_icon_state = "slimeeat"

/datum/action/innate/slime/feed/Activate()
	var/mob/living/simple_animal/slime/S = owner
	S.feed()

/mob/living/simple_animal/slime/proc/can_feed_on(atom/movable/feed_target, silent = FALSE, slimeignore = FALSE, distignore = FALSE)
	if(!Adjacent(feed_target) && !distignore)
		return FALSE

	if(issilicon(feed_target))
		return FALSE

	if(isliving(feed_target))
		var/mob/living/living_target = feed_target
		if(living_target.mob_biotypes & MOB_ROBOTIC)
			return FALSE

	if(isanimal(feed_target))
		var/mob/living/simple_animal/animal_target = feed_target
		if(animal_target.damage_coeff[TOX] <= 0 && animal_target.damage_coeff[CLONE] <= 0) //The creature wouldn't take any damage, it must be too weird even for us.
			if(silent)
				return FALSE

			to_chat(src, span_warning(pick("This subject is incompatible!", \
			"This subject does not have life energy!", "This subject is empty!", \
			"I am not satisified!", "I can not feed from this subject!", \
			"I do not feel nourished!", "This subject is not food!")))
			return FALSE

	if(isslime(feed_target) && !slimeignore)
		if(silent)
			return FALSE

		to_chat(src, span_warning("I can't latch onto another slime..."))
		return FALSE

	if(HAS_TRAIT(feed_target, TRAIT_SLIME_KING) && !HAS_TRAIT(src, TRAIT_SLIME_KING))
		if(silent)
			return FALSE
		to_chat(src, span_warning("I can't attack our king..."))
		return FALSE

	if(docile)
		if(silent)
			return FALSE
		to_chat(src, span_notice("I'm not hungry anymore..."))
		return FALSE

	if(digesting)
		if(silent)
			return FALSE
		to_chat(src, span_notice("I'm already digesting something..."))
		return FALSE

	if(stat)
		if(silent)
			return FALSE
		to_chat(src, span_warning("I must be conscious to do this..."))
		return FALSE

	if(isliving(feed_target))
		var/mob/living/victim = feed_target
		if(victim.stat == DEAD && !(slime_color.slime_tags & SLIME_ATTACK_DEAD))
			if(silent)
				return FALSE
			to_chat(src, span_warning("This subject does not have a strong enough life energy..."))
			return FALSE

	if(locate(/mob/living/simple_animal/slime) in feed_target.buckled_mobs)
		if(silent)
			return FALSE
		to_chat(src, span_warning("Another slime is already feeding on this food..."))
		return FALSE

	var/is_food = FALSE
	if(ishuman(feed_target))
		var/mob/living/carbon/human/victim = feed_target
		if(!ismonkey(victim) || (victim.dna.species.type in slime_color.food_types))
			is_food = TRUE

	if(islarva(feed_target)) //Larvas are an exception
		is_food = TRUE

	if(!is_food)
		for(var/food_type in slime_color.food_types)
			if(istype(feed_target, food_type))
				is_food = TRUE
				break

	if(!is_food)
		if(silent)
			return FALSE
		to_chat(src, span_warning("I don't like this food...."))
		return FALSE

	if(isitem(feed_target) && feed_target.anchored)
		if(silent)
			return FALSE
		to_chat(src, span_warning("It's stuck to [get_turf(feed_target)]..."))
		return FALSE

	if(HAS_TRAIT(feed_target, TRAIT_NO_SLIME_FEED))
		if(silent)
			return FALSE
		to_chat(src, span_warning("It's too shiny to eat...")) //Let's say slime repellers work using certain light frequencies
		return FALSE

	if(SEND_SIGNAL(src, COMSIG_SLIME_CAN_FEED, feed_target) & COMPONENT_SLIME_NO_FEED)
		return

	return TRUE

/mob/living/simple_animal/slime/proc/feed_on(mob/living/feed_target)
	if(SEND_SIGNAL(src, COMSIG_SLIME_CAN_FEEDON, feed_target) & COMPONENT_SLIME_NO_FEEDON)
		return
	if(buckled)
		feed_stop(TRUE)
	feed_target.unbuckle_all_mobs(force=1) //Slimes rip other mobs (eg: shoulder parrots) off (Slimes Vs Slimes is already handled in can_feed_on())

	if(!feed_target.buckle_mob(src, force=TRUE))
		to_chat(src, span_warning("I have failed to latch onto the subject!"))
		return

	layer = feed_target.layer + 0.01 //appear above the target mob
	feed_target.visible_message(span_danger("[name] latches onto [feed_target]!"), \
						span_userdanger("[name] latches onto [feed_target]!"))
	stop_moveloop()
	SEND_SIGNAL(src, COMSIG_SLIME_FEEDON, feed_target)

/mob/living/simple_animal/slime/proc/feed_stop(silent = FALSE, living=1)
	if(!buckled)
		return

	if(!living)
		to_chat(src, span_warning(pick("This subject is incompatible!", \
			"This subject does not have life energy!", "This subject is empty!", \
			"I am not satisified!", "I can not feed from this subject!", \
			"I do not feel nourished!", "This subject is not food!")))

	if(!silent)
		visible_message(span_warning("[src] lets go of [buckled]!"), \
						span_notice("I stopped feeding."))
	layer = initial(layer)
	SEND_SIGNAL(src, COMSIG_SLIME_FEEDSTOP, buckled)
	buckled.unbuckle_mob(src, force = TRUE)

/mob/living/simple_animal/slime/verb/grow_up()
	set category = "Slime"
	set desc = "This will let you grow up from baby to adult slime."

	if(stat)
		to_chat(src, span_warning("I must be conscious to do this..."))
		return

	if(is_adult)
		to_chat(src, span_warning("I am already a grown up..."))
		return

	if(amount_grown < SLIME_EVOLUTION_THRESHOLD)
		to_chat(src, span_warning("I am not ready to grow up yet..."))
		return

	is_adult = TRUE
	maxHealth = 200
	amount_grown = 0
	for(var/datum/action/innate/slime/grow_up/grow_action in actions)
		grow_action.Remove(src)

	var/datum/action/innate/slime/reproduce/reproduce_action = new
	reproduce_action.Grant(src)
	regenerate_icons()
	update_name()

/datum/action/innate/slime/grow_up
	name = "Grow Up"
	button_icon_state = "slimegrow"
	needs_growth = GROWTH_NEEDED

/datum/action/innate/slime/grow_up/Activate()
	var/mob/living/simple_animal/slime/slime = owner
	slime.grow_up()

/mob/living/simple_animal/slime/verb/reproduce()
	set category = "Slime"
	set desc = "This will make you split into four Slimes."

	if(stat)
		to_chat(src, span_warning("I must be conscious to do this..."))
		return

	if(!is_adult)
		to_chat(src, span_warning("I am not old enough to reproduce yet..."))
		return

	if(amount_grown < SLIME_EVOLUTION_THRESHOLD)
		to_chat(src, span_warning("I am not ready to reproduce yet..."))
		return

	if(stat)
		to_chat(src, span_warning("I must be conscious to do this..."))
		return

	var/list/babies = list()
	var/new_nutrition = round(nutrition * 0.25)
	var/new_powerlevel = round(powerlevel / 4)
	var/turf/drop_loc = drop_location()

	for(var/i in 1 to 4)
		var/child_color = slime_color.type
		if(prob(mutation_chance * slime_color.mutation_modifier) && LAZYLEN(slime_color.mutations))
			child_color = pick(slime_color.mutations)

		var/mob/living/simple_animal/slime/split
		split = new(drop_loc, child_color)
		if(ckey)
			split.set_nutrition(new_nutrition) //Player slimes are more robust at spliting. Once an oversight of poor copypasta, now a feature!
		split.powerlevel = new_powerlevel
		if(i != 1)
			step_away(split, src)

		split.set_friends(friends)
		babies += split
		split.mutation_chance = clamp(mutation_chance+(rand(5,-5)),0,100)
		split.max_cores = max(1, round(max_cores / 2))
		SSblackbox.record_feedback("tally", "slime_babies_born", 1, split.slime_color.color)

	var/mob/living/simple_animal/slime/new_slime = pick(babies)
	new_slime.set_combat_mode(TRUE)
	if(src.mind)
		src.mind.transfer_to(new_slime)
	else
		new_slime.key = src.key
	qdel(src)

/datum/action/innate/slime/reproduce
	name = "Reproduce"
	button_icon_state = "slimesplit"
	needs_growth = GROWTH_NEEDED

/datum/action/innate/slime/reproduce/Activate()
	var/mob/living/simple_animal/slime/slime = owner
	slime.reproduce()
