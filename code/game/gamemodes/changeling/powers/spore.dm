/obj/item/spore
	name = "spores"
	desc = "An overgrown virus."
	icon = 'icons/obj/items.dmi'
	icon_state = "spore"
	w_class = 1
	flags = NODROP
	var/obj/item/hidden_as = null

/obj/item/spore/afterattack(obj/target, mob/user, proximity)
	if(!proximity) return
	if(istype(target, /obj/item))
		user.unEquip(src, 1)
		src.loc = target.loc
		icon_state = target.icon_state
		icon = target.icon
		name = target.name
		desc = target.desc
		hidden_as = target
		user << "You hide the spores in the [target.name]."
	else
		user << "You can not hide the spores in that."