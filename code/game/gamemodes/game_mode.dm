/*
 * GAMEMODES
 *
 * In the new mode system all special roles are fully supported.
 * You can have proper wizards/traitors/changelings/cultists during any mode.
 * Only few things really depends on gamemode:
 * 1. Conditions of starting the round. (#TODO: Freeform round start conditions)
 * 2. Antagonists that are spawned at the beginning of round (Can always spawn more antagonists during round)
 * 3. Conditions of ending the round (#TODO: round end conditions can change during round)
 *
 */


/datum/game_mode
	var/name = "invalid"
	var/votable = 1
	var/probability = 1

	var/end_round = 0 // Triggers round end

	//Antag selection

	//Requirements for selecting this gamemode
	var/required_players = 1 // you can always play alone, but don't start a game with no players

	// These variables are used at round start.
	// target_antags = -1 is for antag scaling.
	var/target_traitors = 0
	var/target_changelings = 0
	var/target_double_agents = 0
	var/target_wizards = 0
	var/target_blobs = 0
	var/target_monkeys = 0

	var/starting_rev = 0
	var/starting_cult = 0
	var/starting_malf = 0 // 1 for malf, 3 for triumvirate
	var/starting_alien = 0

	// antag handlers hallelujah.
	var/list/datum/antag_handler/antag_handlers = list()
	var/datum/antag_handler/traitor/traitor_handler = new
	var/datum/antag_handler/changeling/changeling_handler = new
	var/datum/antag_handler/wizard/wizard_handler = new
	var/datum/antag_handler/cult/cult_handler = new
	var/datum/antag_handler/rev/revolution_handler = new
	var/datum/antag_handler/operative/nukeops_handler = new
	var/datum/antag_handler/blob/blob_handler = new
	var/datum/antag_handler/malf/malf_handler = new
	var/datum/antag_handler/monkey/monkey_handler = new

	//Intercept report wait limits
	var/const/waittime_l = 600
	var/const/waittime_h = 1800 // started at 1800

	//Some gamemode specific stuff > #todo: move these to their antag_handlers
	var/shuttleCanBeCalled= 1 //Can the shuttle be called. Redundant copy of shuttle variable
	var/allowMalfTakeover = 0 //Can the round end in malfunction takeover
	var/station_was_nuked = 0 //see nuclearbomb.dm and malfunction.dm
	var/explosion_in_progress = 0 //sit back and relax
	var/datum/mind/sacrifice_target = null



// Need a list to loop through, and individual handles for fast access.
/datum/game_mode/proc/init_antag_handlers()
	antag_handlers += traitor_handler
	antag_handlers += changeling_handler
	antag_handlers += wizard_handler
	antag_handlers += cult_handler
	antag_handlers += revolution_handler
	antag_handlers += nukeops_handler
	antag_handlers += blob_handler
	antag_handlers += malf_handler
	antag_handlers += monkey_handler
	traitor_handler.target_number_of_antag = target_traitors
	changeling_handler.target_number_of_antag = target_changelings
	wizard_handler.target_number_of_antag = target_wizards
	double_agent_handler.target_number_of_antag = target_double_agents
	blob_handler.target_number_of_antag = target_blobs
	malf_handler.target_number_of_antag = starting_malf
	monkey_handler.target_number_of_antag = target_monkeys

/datum/game_mode/proc/announce() //to be called when round starts
	world << "<B>Notice</B>: [src] did not define announce()"


///can_start()
///Checks to see if the game can be setup and ran with the current number of players or whatnot.
/datum/game_mode/proc/can_start()
	var/playerC = 0
	for(var/mob/new_player/player in player_list)
		if((player.client)&&(player.ready))
			playerC++
	if(!Debug2)
		if(playerC < required_players)
			return 0
	init_antag_handlers()
	var/enough_antag_candidates = 1
	for(var/datum/antag_handler/a in antag_handlers)
		if(enough_antag_candidates)
			a.get_candidates()
			enough_antag_candidates = a.has_enough_candidates()
		else
			break
	if(!Debug2)
		return enough_antag_candidates
	else
		world << "<span class='notice'>DEBUG: GAME STARTING WITHOUT PLAYER NUMBER CHECKS, THIS WILL PROBABLY BREAK SHIT."
		return 1



///Attempts to select players for special roles the mode might have.
/datum/game_mode/proc/select_antagonists()
	for(var/datum/antag_handler/a in antag_handlers)
		a.get_antags()
	return 1

/datum/game_mode/proc/finalize_antagonists()
	var/list/datum/mind/handled_antagonists = list()
	for(var/datum/antag_handler/a in antag_handlers)
		for(var/datum/mind/antagonist in a.antags)
			if(antagonist in handled_antagonists)
				continue
			for(var/datum/antagonist/antagonist_datum in antagonist.antag_roles)
				antagonist_datum.create_objectives(antagonist)
				antagonist_datum.equip_antagonist(antagonist)
				antagonist_datum.greet_antagonist(antagonist.current)
			antagonist.print_objectives(antagonist.current)
			handled_antagonists |= antagonist
		a.on_round_start()

// post_setup()
// Everyone should now be on the station and have their normal gear.
// This is the place to give the special roles extra things
/datum/game_mode/proc/post_setup(var/send_intercept=1)

	finalize_antagonists()

	spawn (ROUNDSTART_LOGOUT_REPORT_TIME)
		display_roundstart_logout_report()

	feedback_set_details("round_start","[time2text(world.realtime)]")
	if(ticker && ticker.mode)
		feedback_set_details("game_mode","[ticker.mode]")
	if(revdata.revision)
		feedback_set_details("revision","[revdata.revision]")
	feedback_set_details("server_ip","[world.internet_address]:[world.port]")
	if(send_intercept)
		spawn (rand(waittime_l, waittime_h))
			send_intercept(0)
	start_state = new /datum/station_state()
	start_state.count()

	return 1

// make_antag_chance()
// Handles late-join antag assignments
// They already have a job and everything at this point
/datum/game_mode/proc/make_antag_chance(var/mob/living/carbon/human/character)
	return

//process()
//Called by the gameticker
/datum/game_mode/proc/process()
	return 0


/datum/game_mode/proc/check_finished() //to be called by ticker
	if(emergency_shuttle.location==2 || station_was_nuked || end_round)
		return 1
	return 0


/datum/game_mode/proc/declare_completion()

	for(var/datum/antag_handler/a in antag_handlers)
		a.declare_completion()

//	declare_antagonists(antagonists, "antagonist")

	var/clients = 0
	var/surviving_humans = 0
	var/surviving_total = 0
	var/ghosts = 0
	var/escaped_humans = 0
	var/escaped_total = 0
	var/escaped_on_pod_1 = 0
	var/escaped_on_pod_2 = 0
	var/escaped_on_pod_3 = 0
	var/escaped_on_pod_5 = 0
	var/escaped_on_shuttle = 0

	var/list/area/escape_locations = list(/area/shuttle/escape/centcom, /area/shuttle/escape_pod1/centcom, /area/shuttle/escape_pod2/centcom, /area/shuttle/escape_pod3/centcom, /area/shuttle/escape_pod4/centcom)

	for(var/mob/M in player_list)
		if(M.client)
			clients++
			if(ishuman(M))
				if(!M.stat)
					surviving_humans++
					if(M.loc && M.loc.loc && M.loc.loc.type in escape_locations)
						escaped_humans++
			if(!M.stat)
				surviving_total++
				if(M.loc && M.loc.loc && M.loc.loc.type in escape_locations)
					escaped_total++

				if(M.loc && M.loc.loc && M.loc.loc.type == /area/shuttle/escape/centcom)
					escaped_on_shuttle++

				if(M.loc && M.loc.loc && M.loc.loc.type == /area/shuttle/escape_pod1/centcom)
					escaped_on_pod_1++
				if(M.loc && M.loc.loc && M.loc.loc.type == /area/shuttle/escape_pod2/centcom)
					escaped_on_pod_2++
				if(M.loc && M.loc.loc && M.loc.loc.type == /area/shuttle/escape_pod3/centcom)
					escaped_on_pod_3++
				if(M.loc && M.loc.loc && M.loc.loc.type == /area/shuttle/escape_pod4/centcom)
					escaped_on_pod_5++

			if(isobserver(M))
				ghosts++

	if(clients > 0)
		feedback_set("round_end_clients",clients)
	if(ghosts > 0)
		feedback_set("round_end_ghosts",ghosts)
	if(surviving_humans > 0)
		feedback_set("survived_human",surviving_humans)
	if(surviving_total > 0)
		feedback_set("survived_total",surviving_total)
	if(escaped_humans > 0)
		feedback_set("escaped_human",escaped_humans)
	if(escaped_total > 0)
		feedback_set("escaped_total",escaped_total)
	if(escaped_on_shuttle > 0)
		feedback_set("escaped_on_shuttle",escaped_on_shuttle)
	if(escaped_on_pod_1 > 0)
		feedback_set("escaped_on_pod_1",escaped_on_pod_1)
	if(escaped_on_pod_2 > 0)
		feedback_set("escaped_on_pod_2",escaped_on_pod_2)
	if(escaped_on_pod_3 > 0)
		feedback_set("escaped_on_pod_3",escaped_on_pod_3)
	if(escaped_on_pod_5 > 0)
		feedback_set("escaped_on_pod_5",escaped_on_pod_5)

	send2irc("Server", "Round just ended.")

	return 0


//universal trigger to be called at mob death, nuke explosion, etc. To be called from everywhere.
/datum/game_mode/proc/check_win()
	return 0


/datum/game_mode/proc/send_intercept()
	var/intercepttext = "<FONT size = 3><B>Centcom Update</B> Requested staus information:</FONT><HR>"
	intercepttext += "<B> Centcom has recently been contacted by the following syndicate affiliated organisations in your area, please investigate any information you may have:</B>"

	var/list/possible_modes = list()
	possible_modes.Add("revolution", "wizard", "nuke", "traitor", "malf", "changeling", "cult")
	possible_modes -= "[ticker.mode]" //remove current gamemode to prevent it from being randomly deleted, it will be readded later

	var/number = pick(1, 2)
	var/i = 0
	for(i = 0, i < number, i++) //remove 1 or 2 possibles modes from the list
		possible_modes.Remove(pick(possible_modes))

	possible_modes[rand(1, possible_modes.len)] = "[ticker.mode]" //replace a random game mode with the current one

	possible_modes = shuffle(possible_modes) //shuffle the list to prevent meta

	var/datum/intercept_text/i_text = new /datum/intercept_text
	for(var/A in possible_modes)
		if(antagonists.len == 0)
			intercepttext += i_text.build(A)
		else
			intercepttext += i_text.build(A, pick(antagonists))

	print_command_report(intercepttext,"Centcom Status Summary")
	priority_announce("Summary downloaded and printed out at all communications consoles.", "Enemy communication intercept. Security Level Elevated.", 'sound/AI/intercept.ogg')
	if(security_level < SEC_LEVEL_BLUE)
		set_security_level(SEC_LEVEL_BLUE)


/datum/game_mode/proc/num_players()
	. = 0
	for(var/mob/new_player/P in player_list)
		if(P.client && P.ready)
			. ++

//////////////////////////
//Reports player logouts//
//////////////////////////
proc/display_roundstart_logout_report()
	var/msg = "<span class='boldnotice'>Roundstart logout report\n\n</span>"
	for(var/mob/living/L in mob_list)

		if(L.ckey)
			var/found = 0
			for(var/client/C in clients)
				if(C.ckey == L.ckey)
					found = 1
					break
			if(!found)
				msg += "<b>[L.name]</b> ([L.ckey]), the [L.job] (<font color='#ffcc00'><b>Disconnected</b></font>)\n"


		if(L.ckey && L.client)
			if(L.client.inactivity >= (ROUNDSTART_LOGOUT_REPORT_TIME / 2))	//Connected, but inactive (alt+tabbed or something)
				msg += "<b>[L.name]</b> ([L.ckey]), the [L.job] (<font color='#ffcc00'><b>Connected, Inactive</b></font>)\n"
				continue //AFK client
			if(L.stat)
				if(L.suiciding)	//Suicider
					msg += "<b>[L.name]</b> ([L.ckey]), the [L.job] (<span class='userdanger'>Suicide</span>)\n"
					continue //Disconnected client
				if(L.stat == UNCONSCIOUS)
					msg += "<b>[L.name]</b> ([L.ckey]), the [L.job] (Dying)\n"
					continue //Unconscious
				if(L.stat == DEAD)
					msg += "<b>[L.name]</b> ([L.ckey]), the [L.job] (Dead)\n"
					continue //Dead

			continue //Happy connected client
		for(var/mob/dead/observer/D in mob_list)
			if(D.mind && D.mind.current == L)
				if(L.stat == DEAD)
					if(L.suiciding)	//Suicider
						msg += "<b>[L.name]</b> ([ckey(D.mind.key)]), the [L.job] (<span class='userdanger'>Suicide</span>)\n"
						continue //Disconnected client
					else
						msg += "<b>[L.name]</b> ([ckey(D.mind.key)]), the [L.job] (Dead)\n"
						continue //Dead mob, ghost abandoned
				else
					if(D.can_reenter_corpse)
						msg += "<b>[L.name]</b> ([ckey(D.mind.key)]), the [L.job] (<span class='userdanger'>This shouldn't appear.</span>)\n"
						continue //Lolwhat
					else
						msg += "<b>[L.name]</b> ([ckey(D.mind.key)]), the [L.job] (<span class='userdanger'>Ghosted</span>)\n"
						continue //Ghosted while alive

	for(var/mob/M in mob_list)
		if(M.client && M.client.holder)
			M << msg


