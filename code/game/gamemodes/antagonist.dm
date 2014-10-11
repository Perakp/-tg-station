/* Le Antagonist Datum
 *
 * Keep it simple, stupid!
 */

/datum/antagonist

	var/name = "antagonist"

	// Restricted jobs are used when assigning jobs and when deciding if a latejoiner can be antagonist
	var/list/restricted_jobs = list("cyborg")	// Jobs it doesn't make sense to be.  I.E chaplain or AI cultist
	// Protected jobs concern config options against antag-security and other such shenagigans
	var/list/protected_jobs = list("Security Officer", "Warden", "Detective", "Head of Security", "Captain")


	var/required_players = 1
	var/antag_flag = null //preferences flag such as BE_WIZARD that need to be turned on for players to be antag


/datum/antagonist/proc/create_objectives(var/datum/mind/antagonist_mind)
	return

/datum/antagonist/proc/equip_antagonist()
	return

/datum/antagonist/proc/greet_antagonist(mob/living/antagonist)
	antagonist << "<B><font size=3 color=red>You are the [name].</font></B>"
	var/obj_count = 1
	for(var/datum/objective/objective in antagonist.objectives)
		antagonist.current << "<B>Objective #[obj_count]</B>: [objective.explanation_text]"
		obj_count++
	return

/datum/antagonist/proc/round_end_report(var/datum/mind/ply)
	var/role = "\improper[ply.assigned_role]"
	var/text = "<br><b>[ply.name]</b>(<b>[ply.key]</b>) as \a <b>[role]</b> ("
	if(ply.current)
		if(ply.current.stat == DEAD)
			text += "died"
		else
			text += "survived"
		if(ply.current.real_name != ply.name)
			text += " as <b>[ply.current.real_name]</b>"
	else
		text += "body destroyed"
	text += ")"

	return text
