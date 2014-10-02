/datum/game_mode
	var/traitor_name = "traitor"

	var/datum/mind/exchange_red
	var/datum/mind/exchange_blue

/datum/game_mode/traitor
	name = "traitor"
	config_tag = "traitor"
	antag_flag = BE_TRAITOR
	restricted_jobs = list("Cyborg")//They are part of the AI if he is traitor so are they, they use to get double chances
	protected_jobs = list("Security Officer", "Warden", "Detective", "Head of Security", "Captain")//AI", Currently out of the list as malf does not work for shit
	required_players = 0
	required_enemies = 1
	recommended_enemies = 4

	var/traitorcap = 4 //hard limit on traitors if scaling is turned off
	var/scale_modifier = 1 // Used for gamemodes, that are a child of traitor, that need more than the usual.


/datum/game_mode/traitor/announce()
	world << "<B>The current game mode is - Traitor!</B>"
	world << "<B>There are syndicate traitors on the station. Do not let the traitors succeed!</B>"


/datum/game_mode/traitor/select_antagonists()

	if(config.protect_roles_from_antagonist)
		restricted_jobs += protected_jobs

	var/target_num_traitors = 1

	if(config.traitor_scaling_coeff)
		target_num_traitors = max(1, min( round(num_players()/(config.traitor_scaling_coeff*scale_modifier*2))+2, round(num_players()/(config.traitor_scaling_coeff*scale_modifier)) ))
	else
		target_num_traitors = max(1, min(num_players(), traitorcap))

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
	for(var/datum/mind/antagonist in antagonists)
		for(var/datum/antagonist/traitor/traitor_datum in antagonist.antag_roles)
			traitor_datum.forge_traitor_objectives(antagonist)
		spawn(rand(10,100))
			finalize_traitor(traitor)
			greet_traitor(traitor)
	if(!exchange_blue)
		exchange_blue = -1 //Block latejoiners from getting exchange objectives
	..()
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





/datum/game_mode/proc/greet_traitor(var/datum/mind/traitor)
	traitor.current << "<B><font size=3 color=red>You are the [traitor_name].</font></B>"
	var/obj_count = 1
	for(var/datum/objective/objective in traitor.objectives)
		traitor.current << "<B>Objective #[obj_count]</B>: [objective.explanation_text]"
		obj_count++
	return


/datum/game_mode/proc/finalize_traitor(var/datum/mind/traitor)
	if (istype(traitor.current, /mob/living/silicon))
		add_law_zero(traitor.current)
	else
		equip_traitor(traitor.current)
	return


/datum/game_mode/traitor/declare_completion()
	..()
	return//Traitors will be checked as part of check_extra_completion. Leaving this here as a reminder.

/datum/game_mode/proc/give_codewords(mob/living/traitor_mob)
	traitor_mob << "<U><B>The Syndicate provided you with the following information on how to identify their agents:</B></U>"
	traitor_mob << "<B>Code Phrase</B>: <span class='danger'>[syndicate_code_phrase]</span>"
	traitor_mob << "<B>Code Response</B>: <span class='danger'>[syndicate_code_response]</span>"

	traitor_mob.mind.store_memory("<b>Code Phrase</b>: [syndicate_code_phrase]")
	traitor_mob.mind.store_memory("<b>Code Response</b>: [syndicate_code_response]")

	traitor_mob << "Use the code words in the order provided, during regular conversation, to identify other agents. Proceed with caution, however, as everyone is a potential foe."


/datum/game_mode/proc/add_law_zero(mob/living/silicon/ai/killer)
	var/law = "Accomplish your objectives at all costs."
	var/law_borg = "Accomplish your AI's objectives at all costs."
	killer << "<b>Your laws have been changed!</b>"
	killer.set_zeroth_law(law, law_borg)
	killer << "New law: 0. [law]"
	give_codewords(killer)


/datum/game_mode/proc/auto_declare_completion_traitor()
	if(traitors.len)
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



