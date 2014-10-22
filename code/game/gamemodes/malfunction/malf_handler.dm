/datum/antag_handler/malf
	antag_type_path = /datum/antagonist/malf
	preference_flag = BE_MALF

	var/AI_win_timeleft = 5400
	var/malf_mode_declared = 0
	var/station_captured = 0
	var/to_nuke_or_not_to_nuke = 0
	var/apcs = 0

/datum/antag_handler/malf/additional_candidate_test(var/mob/new_player/player)
	var/datum/job/ai/DummyAIjob = new
	return (!jobban_isbanned(player, "AI") && DummyAIjob.player_old_enough(player.client))

/datum/antag_handler/malf/on_being_selected_as_antag(var/datum/mind/chosen)
	chosen.assigned_role = "AI"
	return

/datum/antag_handler/malf/on_round_start()
	processing_objects |= src


/datum/antag_handler/malf/process()
	if ((apcs > 0) && malf_mode_declared)
		AI_win_timeleft -= apcs * last_tick_duration
	if (AI_win_timeleft<=0 && !station_captured)
		station_captured = 1
		capture_the_station()
	if(check_finished())
		ticker.mode.end_round = 1
	return


/datum/antag_handler/malf/proc/capture_the_station()
	world << "<FONT size = 3><B>The AI has won!</B></FONT>"
	world << "<B>It has fully taken control of all of [station_name()]'s systems.</B>"

	to_nuke_or_not_to_nuke = 1
	for(var/datum/mind/AI_mind in antags)
		if(AI_mind.current)
			AI_mind.current << "Congratulations you have taken control of the station."
			AI_mind.current << "You may decide to blow up the station. You have 60 seconds to choose."
			AI_mind.current << "You should have a new verb in the Malfunction tab. If you dont - rejoin the game."
			AI_mind.current.verbs += /datum/antag_handler/malf/proc/ai_win
	spawn (600)
		for(var/datum/mind/AI_mind in malf_ai)
			if(AI_mind.current)
				AI_mind.current.verbs -= /datum/antag_handler/malf/proc/ai_win
		to_nuke_or_not_to_nuke = 0
	return


/datum/antag_handler/malf/check_finished()
	if (station_captured && !to_nuke_or_not_to_nuke)
		return 1
	if (is_malf_ai_dead())
		if(config.continuous_round_malf) // #todo: move continuous_round_malf from config to game mode
			if(emergency_shuttle)
				emergency_shuttle.always_fake_recall = 0
			malf_mode_declared = 0
		else
			return 1
	return 0

/datum/antag_handler/malf/proc/is_malf_ai_dead()
	var/all_dead = 1
	for(var/datum/mind/AI_mind in antags)
		if (istype(AI_mind.current,/mob/living/silicon/ai) && AI_mind.current.stat!=2)
			all_dead = 0
			break
	return all_dead


/datum/antag_handler/malf/proc/takeover()
	set category = "Malfunction"
	set name = "System Override"
	set desc = "Start the victory timer"
	if (!ticker.mode.allowMalfTakeover)
		usr << "Safety protocols outside your power stop you from taking over the station!"
		return
	if (malf_mode_declared)
		usr << "The takeover has already begun."
		return
	if (apcs < 3)
		usr << "You don't have enough hacked APCs to take over the station yet. You need to hack at least 3, however hacking more will make the takeover faster. You have hacked [ticker.mode:apcs] APCs so far."
		return

	if (alert(usr, "Are you sure you wish to initiate the takeover? The station hostile runtime detection software is bound to alert everyone. You have hacked [apcs] APCs.", "Takeover:", "Yes", "No") != "Yes")
		return

	priority_announce("Hostile runtimes detected in all station systems, please deactivate your AI to prevent possible damage to its morality core.", "Anomaly Alert", 'sound/AI/aimalf.ogg')
	set_security_level("delta")

	for(var/obj/item/weapon/pinpointer/point in world)
		for(var/datum/mind/AI_mind in antags)
			var/mob/living/silicon/ai/A = AI_mind.current // the current mob the mind owns
			if(A.stat != DEAD)
				point.the_disk = A //The pinpointer now tracks the AI core.

	malf_mode_declared = 1
	for(var/datum/mind/AI_mind in antags)
		AI_mind.current.verbs -= /datum/antag_handler/malf/proc/takeover


/datum/antag_handler/malf/proc/ai_win()
	set category = "Malfunction"
	set name = "Explode"
	set desc = "Station go boom"
	if (!to_nuke_or_not_to_nuke)
		return
	to_nuke_or_not_to_nuke = 0
	for(var/datum/mind/AI_mind in antags)
		AI_mind.current.verbs -= /datum/antag_handler/malf/proc/ai_win
	ticker.mode.explosion_in_progress = 1
	for(var/mob/M in player_list)
		M << 'sound/machines/Alarm.ogg'
	world << "Self-destructing in 10"
	for (var/i=9 to 1 step -1)
		sleep(10)
		world << i
	sleep(10)
	enter_allowed = 0
	if(ticker)
		ticker.station_explosion_cinematic(0,null)
		if(ticker.mode)
			ticker.mode.station_was_nuked = 1
			ticker.mode.explosion_in_progress = 0
	return


/datum/antag_handler/malf/declare_completion()
	if( malf_ai.len || istype(ticker.mode,/datum/game_mode/malfunction) )
		var/text = "<br><FONT size=3><B>The malfunctioning AI were:</B></FONT>"

		for(var/datum/mind/malf in malf_ai)

			text += "<br><b>[malf.key]</b> was <b>[malf.name]</b> ("
			if(malf.current)
				if(malf.current.stat == DEAD)
					text += "deactivated"
				else
					text += "operational"
				if(malf.current.real_name != malf.name)
					text += " as <b>[malf.current.real_name]</b>"
			else
				text += "hardware destroyed"
			text += ")"
		text += "<br>"

		world << text
	return 1
