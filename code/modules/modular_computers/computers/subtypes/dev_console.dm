/obj/machinery/computer/modular
	name = "console"
	maximum_component_parts = list(/obj/item/weapon/stock_parts = 14)	//There's a lot of stuff that goes in these
	var/list/interact_sounds = list("keyboard", "keystroke")
	var/obj/item/weapon/stock_parts/computer/hard_drive/portable/usb

/obj/machinery/computer/modular/Initialize()
	set_extension(src, /datum/extension/interactive/ntos, /datum/extension/interactive/ntos/console)
	. = ..()

/obj/machinery/computer/modular/Destroy()
	QDEL_NULL(usb)
	var/datum/extension/interactive/ntos/os = get_extension(src, /datum/extension/interactive/ntos)
	if(os)
		os.system_shutdown()
	. = ..()

/obj/machinery/computer/modular/Process()
	if(stat & NOPOWER)
		return
	var/datum/extension/interactive/ntos/os = get_extension(src, /datum/extension/interactive/ntos)
	if(os)
		os.Process()

/obj/machinery/computer/modular/power_change()
	. = ..()
	if(. && (stat & NOPOWER))
		var/datum/extension/interactive/ntos/os = get_extension(src, /datum/extension/interactive/ntos)
		if(os)
			os.event_powerfailure()
			os.system_shutdown()

/obj/machinery/computer/modular/interface_interact(mob/user)
	var/datum/extension/interactive/ntos/os = get_extension(src, /datum/extension/interactive/ntos)
	if(os)
		if(!os.on)
			os.system_boot()

		os.ui_interact(user)
	return TRUE

/obj/machinery/computer/modular/get_screen_overlay()
	var/datum/extension/interactive/ntos/os = get_extension(src, /datum/extension/interactive/ntos)
	if(os)
		return os.get_screen_overlay()

/obj/machinery/computer/modular/get_keyboard_overlay()
	var/datum/extension/interactive/ntos/os = get_extension(src, /datum/extension/interactive/ntos)
	if(os)
		return os.get_keyboard_overlay()

/obj/machinery/computer/modular/emag_act(var/remaining_charges, var/mob/user)
	var/obj/item/weapon/stock_parts/circuitboard/modular_computer/MB = get_component_of_type(/obj/item/weapon/stock_parts/circuitboard/modular_computer)
	return MB && MB.emag_act(remaining_charges, user)

/obj/machinery/computer/modular/components_are_accessible(var/path)
	. = ..()
	if(.)
		return
	if(!ispath(path, /obj/item/weapon/stock_parts/computer))
		return FALSE
	var/obj/item/weapon/stock_parts/computer/P = path
	return initial(P.external_slot)

/obj/machinery/computer/modular/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/weapon/stock_parts/computer/hard_drive/portable))
		if(usb)
			to_chat(user, SPAN_WARNING("There's already \a [usb] plugged in."))
			return TRUE
		else if(user.unEquip(I, src))
			usb = I
			verbs += /obj/machinery/computer/modular/proc/eject_usb
			visible_message(SPAN_NOTICE("[user] plugs \the [I] into \the [src]."))
			return TRUE
	return ..()

/obj/machinery/computer/modular/proc/eject_usb()
	set name = "Eject Portable Storage"
	set category = "Object"
	set src in view(1)

	if(!CanPhysicallyInteract(usr))
		to_chat(usr, "<span class='warning'>You can't reach it.</span>")
		return

	if(ismob(usr))
		var/mob/user = usr
		visible_message(SPAN_NOTICE("[user] ejects \the [usb] from \the [src]."))
		user.put_in_hands(usb)
	else
		usb.dropInto(loc)
	usb = null
	verbs -= /obj/machinery/computer/modular/proc/eject_usb

/obj/machinery/computer/modular/CouldUseTopic(var/mob/user)
	..()
	if(LAZYLEN(interact_sounds) && CanPhysicallyInteract(user))
		playsound(src, pick(interact_sounds), 40)

/obj/machinery/computer/modular/RefreshParts()
	..()
	var/extra_power = 0
	for(var/obj/item/weapon/stock_parts/computer/part in component_parts)
		if(part.enabled)
			extra_power += part.power_usage
	change_power_consumption(initial(active_power_usage) + extra_power, POWER_USE_ACTIVE)

/obj/machinery/computer/modular/CtrlAltClick(mob/user)
	if(!CanPhysicallyInteract(user))
		return
	var/datum/extension/interactive/ntos/os = get_extension(src, /datum/extension/interactive/ntos)
	if(os)
		os.open_terminal(user)