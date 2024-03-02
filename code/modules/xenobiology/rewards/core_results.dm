/obj/item/grenade/frost_core
	name = "frost core"
	desc = "A blue slime extract covered in a thick layer of ice."
	icon_state = "frost_core"
	shrapnel_type = /obj/projectile/temp/icicle
	shrapnel_radius = 2

/obj/item/grenade/frost_core/detonate(mob/living/lanced_by)
	. = ..()
	if(!.)
		return

	update_mob()
	qdel(src)

/obj/projectile/temp/icicle
	name = "icicle"
	icon_state = "icicle"
	range = 4
	damage = 0
	speed = 1.2
	stamina = 10
	nodamage = FALSE
	armour_penetration = 100
	temperature = -75
	wound_bonus = -100
	armor_flag = BULLET

