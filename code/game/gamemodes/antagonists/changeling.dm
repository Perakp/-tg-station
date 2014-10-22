/datum/antagonist/changeling
	var/name = "changeling"
	var/antag_flag = BE_CHANGELING

	var/list/restricted_jobs = list("cyborg", "AI")
	var/list/protected_jobs = list("Security Officer", "Warden", "Detective", "Head of Security", "Captain")




/datum/antagonist/changeling/create_objectives(var/datum/mind/changeling)
	//OBJECTIVES - Always absorb at least 5 genomes, plus random traitor objectives.
	//If they have two objectives as well as absorb, they must survive rather than escape
	//No escape alone because changelings aren't suited for it and it'd probably just lead to rampant robusting
	//If it seems like they'd be able to do it in play, add a 10% chance to have to escape alone

	var/datum/objective/absorb/absorb_objective = new
	absorb_objective.owner = changeling
	absorb_objective.gen_amount_goal(6, 8)
	changeling.objectives += absorb_objective

	var/list/active_ais = active_ais()
	if(active_ais.len && prob(100/joined_player_list.len))
		var/datum/objective/destroy/destroy_objective = new
		destroy_objective.owner = changeling
		destroy_objective.find_target()
		changeling.objectives += destroy_objective
	else
		if(prob(70))
			var/datum/objective/assassinate/kill_objective = new
			kill_objective.owner = changeling
			kill_objective.find_target()
			changeling.objectives += kill_objective
		else
			var/datum/objective/maroon/maroon_objective = new
			maroon_objective.owner = changeling
			maroon_objective.find_target()
			changeling.objectives += maroon_objective

	if(prob(60))
		var/datum/objective/steal/steal_objective = new
		steal_objective.owner = changeling
		steal_objective.find_target()
		changeling.objectives += steal_objective
	else
		var/datum/objective/debrain/debrain_objective = new
		debrain_objective.owner = changeling
		debrain_objective.find_target()
		changeling.objectives += debrain_objective

	if (!(locate(/datum/objective/escape) in changeling.objectives))
		var/datum/objective/escape/escape_objective = new
		escape_objective.owner = changeling
		changeling.objectives += escape_objective
	return

/datum/antagonist/changeling/greet_antagonist(var/mob/changeling)
	changeling << "<span class='userdanger'>You are [changeling.changeling.changelingID], a changeling! You have absorbed and taken the form of a human.</span>"

	if (changeling.current.mind)
		if (changeling.mind.assigned_role == "Clown")
			changeling << "You have evolved beyond your clownish nature, allowing you to wield weapons without harming yourself."
			changeling.mutations.Remove(CLUMSY)

	print_objectives(changeling)
	return

/datum/antagonist/changeling/print_antagonist(var/datum/mind/changeling)
	var/text
	text += "<br><b>Changeling ID:</b> [changeling.changeling.changelingID]."
	text += "<br><b>Genomes Extracted:</b> [changeling.changeling.absorbedcount]"
	return text