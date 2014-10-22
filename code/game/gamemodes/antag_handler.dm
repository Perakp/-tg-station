// This handles the selection of antagonists.
// Each antag type has their own antag handler, that is used at the start of the round.
// This was needed because selecting antagonists separate from their game mode makes sense.
// We want to be able to have all antagonists in all game modes, eg. have only one game mode
// and just change the numbers of antagonists to create the different game modes.
/datum/antag_handler

	var/datum/antagonist/antag_type_path = /datum/antagonist
	var/target_number_of_antag = 0
	var/preference_flag = 0

	var/list/datum/mind/antags = list()
	var/list/datum/mind/candidates = list() //multiple antag role madness

/datum/antag_handler/proc/get_antags()
	if(!candidates.len)
		get_candidates()
	if(!candidates.len || !target_num_of_antag || candidates.len < target_number_of_antag)
		return 0
	var/datum/mind/chosen
	while((antags.len <= target_number_of_antag) && candidates.len)
		chosen = pick(candidates)
		candidates -= chosen
		if(chosen.antag_roles.len)
			continue
		antags += chosen
		var/datum/antagonist/a = new antag_type_path
		chosen.special_role = a.name
		chosen.antag_roles |= a
		on_being_selected_as_antag(chosen)
		log_game("[chosen.key] (ckey) has been selected as a [a.name].")
	return 0

// additional stuff to do when someone is selected as antag
/datum/antag_handler/proc/on_being_selected_as_antag(var/datum/mind/chosen)
	return

/datum/antag_handler/proc/calculate_target_num_of_antags()
	// Antag scaling calculation here.
	return target_num_of_antags

// Returns a list of people who had the antagonist role set to yes in their preferences,
// weren't banned and were ready
/datum/antag_handler/proc/get_candidates()
	var/list/players = list() // List of players that are ready
	var/roletext
	switch(preference_flag)
		if(BE_CHANGELING)	roletext="changeling"
		if(BE_TRAITOR)		roletext="traitor"
		if(BE_OPERATIVE)	roletext="operative"
		if(BE_WIZARD)		roletext="wizard"
		if(BE_REV)			roletext="revolutionary"
		if(BE_GANG)			roletext="gangster"
		if(BE_CULTIST)		roletext="cultist"
		if(BE_MONKEY)		roletext="monkey"

	for(var/mob/new_player/player in player_list)
		if(player.client && player.ready)
			if(!jobban_isbanned(player, "Syndicate") && !jobban_isbanned(player, roletext))
				if(player.client.prefs.be_special & preference_flag)
					if(additional_candidate_test(player))
						candidates += player.mind

	candidates = shuffle(candidates)
	return

// anything else that should be tested for candidates, 1 for pass, 0 for fail
/datum/antag_handler/proc/additional_candidate_test(var/mob/new_player/player)
	return 1

/datum/antag_handler/proc/has_enough_candidates()
	if(target_num_of_antag == -1)
		target_num_of_antag = calculate_target_num_of_antags()
	if(candidates.len >= target_num_of_antag)
		return 1
	return 0


/datum/antag_handler/proc/on_round_start()
	return



/datum/antag_handler/proc/declare_completion()
	if(antags.len)
		var/datum/antagonist/a = new antag_type_path
		world << "<br><font size=3><b>The [a.name]s were:</b></font>"
		var/text = ""
		for(var/datum/mind/antagonist in a)
			text += antagonist.print_antagonist_roles()
			a.antagonist_roles = list()

/datum/antag_handler/traitor
	antag_type_path = /datum/antagonist/traitor
	preference_flag = BE_TRAITOR

/datum/antag_handler/wizard
	antag_type_path = /datum/antagonist/wizard
	preference_flag = BE_WIZARD

/datum/antag_handler/traitor/double_agent
	antag_type_path = /datum/antagonist/traitor/double_agent

/datum/antag_handler/operative
	antag_type_path = /datum/antagonist/operative
	preference_flag = BE_OPERATIVE

/datum/antag_handler/rev
	antag_type_path = /datum/antagonist/rev
	preference_flag = BE_REV

/datum/antag_handler/cult
	antag_type_path = /datum/antagonist/cultist
	preference_flag = BE_CULTIST

/datum/antag_handler/gang
	antag_type_path = /datum/antagonist/gang
	preference_flag = BE_GANG

/datum/antag_handler/monkey
	antag_type_path = /datum/antagonist/monkey
	preference_flag = BE_MONKEY



