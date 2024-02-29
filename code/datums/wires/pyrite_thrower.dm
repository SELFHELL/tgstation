
/datum/wires/pyrite_thrower
	holder_type = /obj/machinery/xenobio_device/pyrite_thrower
	proper_name = "Pyrite Thrower"

/datum/wires/pyrite_thrower/New(atom/holder)
	wires = list(WIRE_ACTIVATE)
	return ..()

/datum/wires/microwave/on_pulse(wire)
	var/obj/machinery/xenobio_device/pyrite_thrower/thrower = holder
	switch(wire)
		if(WIRE_ACTIVATE)
			thrower.trigger()
