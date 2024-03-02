/datum/xenobio_bounty
	var/name = "Broken xenobio bounty"
	var/desc = "Report this to coderbus!"

	var/list/requirements = list()
	var/text_requirements = "Error"
	var/list/rewards = list()
	var/text_rewards = "Error"

	var/datum/xenobio_corporation/author
	var/bounty_level = 1
	var/levels_per_bounty = 0

/datum/xenobio_bounty/New(datum/xenobio_corporation/author)
	. = ..()
	src.author = author

/datum/xenobio_bounty/proc/process_item(atom/target)
	qdel(target)

/datum/xenobio_bounty/proc/reward(obj/machinery/slime_bounty_pad/bounty_pad)
	author.relationship_level += levels_per_bounty
	var/turf/pad_turf = get_turf(bounty_pad)
	for(var/reward_type in rewards)
		for(var/i = 1 to rewards[reward_type])
			new reward_type(pad_turf)
