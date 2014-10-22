/* Le Antagonist Datum
 *
 */

/datum/antagonist

	var/name = "antagonist"


	// Restricted jobs are used when assigning jobs and when deciding if a latejoiner can be antagonist
	var/list/restricted_jobs = list("cyborg")	// Jobs it doesn't make sense to be.  I.E chaplain or AI cultist
	// Protected jobs concern config options against antag-security and other such shenagigans
	var/list/protected_jobs = list("Security Officer", "Warden", "Detective", "Head of Security", "Captain")
	var/unique_antagonist_role = 0 // if unique, player can not get another antag role other than this

	var/required_players = 1
	var/antag_flag = null //preferences flag such as BE_WIZARD that need to be turned on for players to be antag


/datum/antagonist/proc/create_objectives(var/datum/mind/antagonist_mind)
	return

/datum/antagonist/proc/equip_antagonist(var/datum/mind/antagonist)
	return

/datum/antagonist/proc/greet_antagonist(mob/antagonist)
	antagonist << "<B><font size=3 color=red>You are the [name].</font></B>"


/datum/antagonist/proc/print_objectives(mob/antagonist)
	antagonist << "<b>You must complete the following objectives:</b>"
	var/obj_count = 1
	for(var/datum/objective/objective in antagonist.mind.objectives)
		antagonist << "<B>Objective #[obj_count]</B>: [objective.explanation_text]"
		obj_count++
	return

/datum/antagonist/proc/print_antagonist(var/datum/mind/ply)
	return ""


// Prints all antagonist roles of this player.
/datum/mind/proc/print_antagonist_roles()
	if(!antag_roles.len)
		return

	var/role = "\improper[assigned_role]"
	var/text = "<br><b>[ply.name]</b>(<b>[ply.key]</b>) as \a <b>[role]</b> was "

	// Yeah, properly written lists
	var/datum/antagonist/antag_role
	if(antag_roles.len > 2)
		for(var/i=1,i<antag_roles.len-2, i++)
			antag_role = antag_roles[i]
			text += "[antag_role.name], "
	if(antag_roles.len > 1 )
		antag_role = antag_roles[2]
		text += "[antag_role.name] and "
	antag_role = antag_roles[1]
	text += "[antag_role.name]. ("

	if(current)
		if(current.stat == DEAD)
			text += "died"
		else
			text += "survived"
		if(current.real_name != name)
			text += " as <b>[current.real_name]</b>"
	else
		text += "body destroyed"
	text += ")"

	for(var/datum/antagonist/a in antag_roles)
		text += a.print_antagonist(src)

	var/antagwin=1
	var/objectives = ""
	if(objectives.len)
		var/count = 1
		for(var/datum/objective/objective in objectives)
		if(objective.check_completion())
			objectives += "<br><B>Objective #[count]</B>: [objective.explanation_text] <font color='green'><B>Success!</B></font>"
		else
			objectives += "<br><B>Objective #[count]</B>: [objective.explanation_text] <font color='red'>Fail.</font>"
			antagwin = 0
		count++


	text += objectives

	var/special_role_text
	if(special_role)
		special_role_text = lowertext(traitor.special_role)
	else
		special_role_text = "antagonist"

	if(antagwin)
		text += "<br><font color='green'><B>The [special_role_text] was successful!</B></font>"
			else
		text += "<br><font color='red'><B>The [special_role_text] has failed!</B></font>"

	text += "<br>"

	return text

