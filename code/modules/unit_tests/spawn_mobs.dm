///Unit test that spawns all mobs that can be spawned by golden slimes
/datum/unit_test/spawn_mobs

/datum/unit_test/spawn_mobs/Run()
	for(var/mob/living/simple_animal/animal as anything in subtypesof(/mob/living/simple_animal))
		if (initial(animal.mob_spawnable_type))
			allocate(animal)
	for(var/mob/living/basic/basic_animal as anything in subtypesof(/mob/living/basic))
		if (initial(basic_animal.mob_spawnable_type))
			allocate(basic_animal)
