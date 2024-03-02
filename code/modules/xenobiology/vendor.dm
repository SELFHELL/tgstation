/obj/machinery/mining_equipment_vendor/xenobiology
	name = "xenobiology equipment vendor"
	desc = "An equipment vendor for xenobiologists in which you can buy items for xenobio points."
	icon = 'icons/obj/xenobiology/machinery.dmi'
	icon_state = "vendor"
	icon_deny = "vendor-deny"
	circuit = /obj/item/circuitboard/machine/xenobio_equipment_vendor

	voucher_type = /obj/item/xenobio_voucher

/obj/machinery/mining_equipment_vendor/xenobiology/ui_data(mob/user)
	. = list()
	var/obj/item/card/id/C
	if(isliving(user))
		var/mob/living/L = user
		C = L.get_idcard(TRUE)
	if(C)
		.["user"] = list()
		.["user"]["points"] = C.xenobio_points
		if(C.registered_account)
			.["user"]["name"] = C.registered_account.account_holder
			if(C.registered_account.account_job)
				.["user"]["job"] = C.registered_account.account_job.title
			else
				.["user"]["job"] = "No Job"

/obj/machinery/mining_equipment_vendor/xenobiology/attempt_purchase(params)
	var/obj/item/card/id/I
	if(isliving(usr))
		var/mob/living/L = usr
		I = L.get_idcard(TRUE)
	if(!istype(I))
		to_chat(usr, span_alert("Error: An ID is required!"))
		flick(icon_deny, src)
		return FALSE
	var/datum/data/mining_equipment/prize = locate(params["ref"]) in prize_list
	if(!prize || !(prize in prize_list))
		to_chat(usr, span_alert("Error: Invalid choice!"))
		flick(icon_deny, src)
		return FALSE
	if(prize.cost > I.xenobio_points)
		to_chat(usr, span_alert("Error: Insufficient points for [prize.equipment_name] on [I]!"))
		flick(icon_deny, src)
		return FALSE
	I.xenobio_points -= prize.cost
	to_chat(usr, span_notice("[src] clanks to life briefly before vending [prize.equipment_name]!"))
	new prize.equipment_path(loc)
	SSblackbox.record_feedback("nested tally", "xenobiology_equipment_bought", 1, list("[type]", "[prize.equipment_path]"))

/obj/item/xenobio_voucher
	name = "xenobiology voucher"
	desc = "A token to redeem a piece of equipment. Use it on a xenobiology equipment vendor."
	icon = 'icons/obj/xenobiology/equipment.dmi'
	icon_state = "voucher"
	w_class = WEIGHT_CLASS_TINY

/obj/item/storage/box/wobble
	name = "box of wobble eggs"
	illustration = "writing"

/obj/item/storage/box/wobble/PopulateContents()
	new /obj/item/food/wobble_egg(src)
	new /obj/item/food/wobble_egg(src)
	new /obj/item/food/wobble_egg(src)
