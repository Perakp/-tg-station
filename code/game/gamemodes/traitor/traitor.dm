/datum/game_mode
	var/datum/mind/exchange_red
	var/datum/mind/exchange_blue
	var/traitor_name = "traitor" //or "double agent"

/datum/game_mode/traitor
	name = "traitor"
	antag_flag = BE_TRAITOR

	required_enemies = 1
	recommended_enemies = 4

	var/traitors_possible = 4 //hard limit on traitors if scaling is turned off
	var/num_modifier = 0 // Used for gamemodes, that are a child of traitor, that need more than the usual.

/datum/game_mode/traitor/announce()
	world << "<B>The current game mode is - Traitor!</B>"
	world << "<B>There are syndicate traitors on the station. Do not let the traitors succeed!</B>"


/datum/game_mode/traitor/select_antagonists()

	var/target_num_traitors = required_enemies

	if(config.traitor_scaling_coeff)
 		target_num_traitors = max(required_enemies, min( round(num_players()/(config.traitor_scaling_coeff*2))+ 2 + num_modifier, round(num_players()/(config.traitor_scaling_coeff)) + num_modifier ))

	else
		target_num_traitors = max(required_enemies, min(num_players(), traitors_possible))

	for(var/j = 0, j < target_num_traitors, j++)
		if (!antag_candidates.len)
			break
		var/datum/mind/traitor = pick(antag_candidates)
		antagonists |= traitor
		traitors |= traitor
		traitor.special_role = traitor_name
		var/datum/antagonist/traitor/t = new
		traitor.antag_roles |= t
		log_game("[traitor.key] (ckey) has been selected as a [traitor_name]")
		antag_candidates.Remove(traitor)

	if(traitors < required_enemies)
		return 0
	return 1


/datum/game_mode/traitor/post_setup()
	if(traitors>=5)
		for(var/datum/mind/antagonist in antagonists)
			if(!exchange_blue)
				for(var/datum/antagonist/traitor/t in antagonist.antag_roles)
					if(ishuman(antagonist.current))
						if(!exchange_blue)
							exchange_blue = antagonist
							break
						else if(!exchange_red)
							exchange_red = antagonist
							assign_exchange_role(exchange_blue, "blue", exchange_red)
							assign_exchange_role(exchange_red, "red", exchange_blue)
							break
			else
				break
	..()
	if(!exchange_blue)
		exchange_blue = -1 //Block latejoiners from getting exchange objectives
	return 1

/datum/game_mode/traitor/make_antag_chance(var/mob/living/carbon/human/character) //Assigns traitor to latejoiners
	if(!config.traitor_scaling_coeff)
		return
	traitorcap = round(joined_player_list.len / (config.traitor_scaling_coeff * scale_modifier * 2))
	if(traitors >= traitorcap) //Upper cap for number of latejoin antagonists
		return
	if(traitors <= (traitorcap - 2) || prob(100 / (config.traitor_scaling_coeff * scale_modifier * 2)))
		if(character.client.prefs.be_special & BE_TRAITOR)
			if(!jobban_isbanned(character.client, "traitor") && !jobban_isbanned(character.client, "Syndicate"))
				if(!(character.job in ticker.mode.restricted_jobs))
					add_latejoin_traitor(character.mind)
	..()

/datum/game_mode/traitor/proc/add_latejoin_traitor(var/datum/mind/character)
	character.make_Traitor()


//This is called whenever a round ends
/datum/game_mode/proc/auto_declare_completion_traitor()

	declare_antagonists(traitors, traitor_name)

	if(traitors.len && syndicate_code_phrase)
		world << "<br><b>The code phrases were:</b> <font color='red'>[syndicate_code_phrase]</font><br>\
			<b>The code responses were:</b> <font color='red'>[syndicate_code_response]</font><br>"
	return 1



