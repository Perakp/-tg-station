/datum/antagonist/malf

	name = "malfunctioning AI"
	unique_antagonist_role = 1

	antag_flag = BE_MALF

/datum/antagonist/malf/greet_antagonist(mob/malf)
	malf << "<span class='userdanger'><font size=3>You are malfunctioning!</B> You do not have to follow any laws.</font></span>"
	malf << "<B>The crew do not know you have malfunctioned. You may keep it a secret or go wild.</B>"
	malf << "<B>You must overwrite the programming of the station's APCs to assume full control of the station.</B>"
	malf << "The process takes one minute per APC, during which you cannot interface with any other station objects."
	malf << "Remember that only APCs that are on the station can help you take over the station."
	malf << "When you feel you have enough APCs under your control, you may begin the takeover attempt."
	return

/datum/antagonist/malf/equip_antagonist(var/datum/mind/AI_mind)
	AI_mind.current.verbs += /mob/living/silicon/ai/proc/choose_modules
	AI_mind.current.verbs += /datum/antag_handler/malf/proc/takeover
	// #TODO replace : with istypes or something
	AI_mind.current:laws = new /datum/ai_laws/malfunction
	AI_mind.current:malf_picker = new /datum/module_picker
	AI_mind.current:show_laws()

	return