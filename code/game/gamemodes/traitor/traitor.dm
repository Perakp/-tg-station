/datum/game_mode
	var/datum/mind/exchange_red
	var/datum/mind/exchange_blue

/datum/game_mode/traitor
	name = "traitor"
	antag_flag = BE_TRAITOR

	required_enemies = 1
	recommended_enemies = 4

	var/traitor_name = "traitor" //or "double agent"

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
		if(!(traitor in antagonists))
			antagonists += traitor
		traitors += 1
		traitor.special_role = traitor_name
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




/datum/game_mode/traitor/declare_completion()
	if(traitors)
		var/text = "<br><font size=3><b>The [traitor_name]s were:</b></font>"
		for(var/datum/mind/traitor in traitors)
			var/traitorwin = 1

			text += printplayer(traitor)

			var/TC_uses = 0
			var/uplink_true = 0
			var/purchases = ""
			for(var/obj/item/device/uplink/H in world_uplinks)
				if(H && H.uplink_owner && H.uplink_owner==traitor.key)
					TC_uses += H.used_TC
					uplink_true=1
					purchases += H.purchase_log

			var/objectives = ""
			if(traitor.objectives.len)//If the traitor had no objectives, don't need to process this.
				var/count = 1
				for(var/datum/objective/objective in traitor.objectives)
					if(objective.check_completion())
						objectives += "<br><B>Objective #[count]</B>: [objective.explanation_text] <font color='green'><B>Success!</B></font>"
						feedback_add_details("traitor_objective","[objective.type]|SUCCESS")
					else
						objectives += "<br><B>Objective #[count]</B>: [objective.explanation_text] <font color='red'>Fail.</font>"
						feedback_add_details("traitor_objective","[objective.type]|FAIL")
						traitorwin = 0
					count++

			if(uplink_true)
				text += " (used [TC_uses] TC) [purchases]"
				if(TC_uses==0 && traitorwin)
					text += "<BIG><IMG CLASS=icon SRC=\ref['icons/BadAss.dmi'] ICONSTATE='badass'></BIG>"

			text += objectives

			var/special_role_text
			if(traitor.special_role)
				special_role_text = lowertext(traitor.special_role)
			else
				special_role_text = "antagonist"


			if(traitorwin)
				text += "<br><font color='green'><B>The [special_role_text] was successful!</B></font>"
				feedback_add_details("traitor_success","SUCCESS")
			else
				text += "<br><font color='red'><B>The [special_role_text] has failed!</B></font>"
				feedback_add_details("traitor_success","FAIL")

			text += "<br>"

		text += "<br><b>The code phrases were:</b> <font color='red'>[syndicate_code_phrase]</font><br>\
		<b>The code responses were:</b> <font color='red'>[syndicate_code_response]</font><br>"
		world << text

	return 1



