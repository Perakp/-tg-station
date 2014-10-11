var/global/datum/controller/gameticker/ticker
var/round_start_time = 0

#define GAME_STATE_PREGAME		1
#define GAME_STATE_SETTING_UP	2
#define GAME_STATE_PLAYING		3
#define GAME_STATE_FINISHED		4

/datum/controller/gameticker
	var/const/restart_timeout = 250
	var/current_state = GAME_STATE_PREGAME

	var/hide_mode = 0
	var/datum/game_mode/mode = null
	var/event_time = null
	var/event = 0

	var/login_music			// music played in pregame lobby

	var/list/datum/mind/minds = list()//The people in the game. Used for objective tracking.

	var/Bible_icon_state	// icon_state the chaplain has chosen for his bible
	var/Bible_item_state	// item_state the chaplain has chosen for his bible
	var/Bible_name			// name of the bible
	var/Bible_deity_name

	var/list/syndicate_coalition = list() // list of traitor-compatible factions
	var/list/factions = list()			  // list of all factions
	var/list/availablefactions = list()	  // list of factions with openings

	var/pregame_timeleft = 0

	var/delay_end = 0	//if set to nonzero, the round will not restart on it's own

	var/triai = 0//Global holder for Triumvirate

	var/list/runnable_modes = list()


// Lobby: Play relaxing music, wait for the round to start
/datum/controller/gameticker/proc/pregame()

	login_music = pickweight(list('sound/ambience/title2.ogg' = 49, 'sound/ambience/title1.ogg' = 49, 'sound/ambience/clown.ogg' = 2)) // choose title music!
	if(events.holiday == "April Fool's Day")
		login_music = 'sound/ambience/clown.ogg'
	for(var/client/C in clients)
		C.playtitlemusic()
	do
		if(config)
			pregame_timeleft = config.lobby_countdown
		else
			ERROR("configuration was null when retrieving the lobby_countdown value.")
			pregame_timeleft = 120
		world << "<B><FONT color='blue'>Welcome to the pre-game lobby!</FONT></B>"
		world << "Please, setup your character and select ready. Game will start in [pregame_timeleft] seconds"
		while(current_state == GAME_STATE_PREGAME)
			sleep(10)
			if(going)
				pregame_timeleft--

			if(pregame_timeleft <= 0)
				current_state = GAME_STATE_SETTING_UP
	while (!setup())



/datum/controller/gameticker/proc/setup()

	runnable_modes = config.get_runnable_modes()
	// Try to set up the game mode. Return to lobby if no game mode can be started.
	if(!create_gamemode())
		return 0
	// Try to choose antagonists for the selected mode.
	var/antagonists_selected = mode.select_antagonists()

	if(!Debug2)
		if(!antagonists_selected)
			del(mode)
			current_state = GAME_STATE_PREGAME
			world << "<B>Error setting up [master_mode].</B> Reverting to pre-game lobby."
			job_master.ResetOccupations()
			return 0
	else
		world << "<span class='notice'>DEBUG: Bypassing prestart checks..."

	job_master.DivideOccupations()
	announce_mode()
	round_start_time = world.time

	supply_shuttle.process() 		//Start the supply shuttle regenerating points
	master_controller.process()		//Start master_controller.process()
	lighting_controller.process()	//Start processing DynamicAreaLighting updates

	sleep(10)

	create_characters() //Create player characters and transfer them
	collect_minds()
	equip_characters()
	data_core.manifest()
	current_state = GAME_STATE_PLAYING

	spawn(0)//Forking here so we dont have to wait for this to finish
		mode.post_setup()
		//Cleanup some stuff
		for(var/obj/effect/landmark/start/S in landmarks_list)
			//Deleting Startpoints but we need the ai point to AI-ize people later
			if (S.name != "AI")
				qdel(S)
		world << "<FONT color='blue'><B>Welcome to [station_name()], enjoy your stay!</B></FONT>"
		world << sound('sound/AI/welcome.ogg') // Skie
		//Holiday Round-start stuff	~Carn
		if(events.holiday)
			world << "<font color='blue'>and...</font>"
			world << "<h4>Happy [events.holiday] Everybody!</h4>"

	if(!admins.len)
		send2irc("Server", "Round just started with no admins online!")
	auto_toggle_ooc(0) // Turn it off

	if(config.sql_enabled)
		spawn(3000)
			statistic_cycle() // Polls population totals regularly and stores them in an SQL DB
	return 1


/datum/controller/gameticker/proc/announce_mode()
	if(hide_mode)
		var/list/modes = list()
		for (var/datum/game_mode/M in runnable_modes)
			modes+=M.name
		modes = sortList(modes)
		world << "<B>The current game mode is - Secret!</B>"
		world << "<B>Possibilities:</B> [english_list(modes)]"
	else
		mode.announce()

// Creates the game mode from current settings, considering the requirements to start the game mode
// TODO: clean this up. It shouldn't look like this.
/datum/controller/gameticker/proc/create_gamemode()

	if((master_mode=="random") || (master_mode=="secret"))
		if((master_mode=="secret") && (secret_force_mode != "secret"))
			var/datum/game_mode/smode = config.pick_mode(secret_force_mode)
			if (!smode.can_start())
				message_admins("\blue Unable to force secret [secret_force_mode]. [smode.required_players] players and [smode.required_enemies] eligible antagonists needed.", 1)
			else
				src.mode = smode

		if(!src.mode)
			if (runnable_modes.len==0)
				current_state = GAME_STATE_PREGAME
				world << "<B>Unable to choose playable game mode.</B> Reverting to pre-game lobby."
				return 0
			src.mode = pickweight(runnable_modes)

	else
		src.mode = config.pick_mode(master_mode)
		if (!src.mode.can_start())
			world << "<B>Unable to start [mode.name].</B> Not enough players, [mode.required_players] players and [mode.required_enemies] eligible antagonists needed. Reverting to pre-game lobby."
			del(mode)
			current_state = GAME_STATE_PREGAME
			return 0



/datum/controller/gameticker/proc/create_characters()
	for(var/mob/new_player/player in player_list)
		if(player.ready && player.mind)
			joined_player_list += player.ckey
			if(player.mind.assigned_role=="AI")
				player.close_spawn_windows()
				player.AIize()
			else
				player.create_character()
				qdel(player)
		else
			player.new_player_panel()


/datum/controller/gameticker/proc/collect_minds()
	for(var/mob/living/player in player_list)
		if(player.mind)
			ticker.minds += player.mind


/datum/controller/gameticker/proc/equip_characters()
	var/captainless=1
	for(var/mob/living/carbon/human/player in player_list)
		if(player && player.mind && player.mind.assigned_role)
			if(player.mind.assigned_role == "Captain")
				captainless=0
			if(player.mind.assigned_role != "MODE")
				job_master.EquipRank(player, player.mind.assigned_role, 0)
	if(captainless)
		for(var/mob/M in player_list)
			if(!istype(M,/mob/new_player))
				M << "Captainship not forced on anyone."


/datum/controller/gameticker/proc/process()
	if(current_state != GAME_STATE_PLAYING)
		return 0

	mode.process()

	emergency_shuttle.process()

	if(!mode.explosion_in_progress && mode.check_finished())
		current_state = GAME_STATE_FINISHED
		auto_toggle_ooc(1) // Turn it on
		spawn
			declare_completion()

		spawn(50)
			if (mode.station_was_nuked)
				feedback_set_details("end_proper","nuke")
				if(!delay_end)
					world << "\blue <B>Rebooting due to destruction of station in [restart_timeout/10] seconds</B>"
			else
				feedback_set_details("end_proper","proper completion")
				if(!delay_end)
					world << "\blue <B>Restarting in [restart_timeout/10] seconds</B>"


			if(blackbox)
				blackbox.save_all_data_to_sql()

			if(!delay_end)
				sleep(restart_timeout)
				kick_clients_in_lobby("\red The round came to an end with you in the lobby.", 1) //second parameter ensures only afk clients are kicked
				world.Reboot()
			else
				world << "\blue <B>An admin has delayed the round end</B>"

	return 1




/datum/controller/gameticker/proc/declare_completion()
	var/station_evacuated
	if(emergency_shuttle.location > 0)
		station_evacuated = 1
	var/num_survivors = 0
	var/num_escapees = 0

	world << "<BR><BR><BR><FONT size=3><B>The round has ended.</B></FONT>"

	//Player status report
	for(var/mob/Player in mob_list)
		if(Player.mind && !isnewplayer(Player))
			if(Player.stat != DEAD && !isbrain(Player))
				num_survivors++
				if(station_evacuated) //If the shuttle has already left the station
					var/turf/playerTurf = get_turf(Player)
					if(playerTurf.z != 2)
						Player << "<font color='blue'><b>You managed to survive, but were marooned on [station_name()]...</b></FONT>"
					else
						num_escapees++
						Player << "<font color='green'><b>You managed to survive the events on [station_name()] as [Player.real_name].</b></FONT>"
				else
					Player << "<font color='green'><b>You managed to survive the events on [station_name()] as [Player.real_name].</b></FONT>"
			else
				Player << "<font color='red'><b>You did not survive the events on [station_name()]...</b></FONT>"

	//Round statistics report
	var/datum/station_state/end_state = new /datum/station_state()
	end_state.count()
	var/station_integrity = round( 100.0 *  start_state.score(end_state), 0.1)

	world << "<BR>[TAB]Shift Duration: <B>[round(world.time / 36000)]:[add_zero("[world.time / 600 % 60]", 2)]:[world.time / 100 % 6][world.time / 100 % 10]</B>"
	world << "<BR>[TAB]Station Integrity: <B>[mode.station_was_nuked ? "<font color='red'>Destroyed</font>" : "[station_integrity]%"]</B>"
	if(joined_player_list.len)
		world << "<BR>[TAB]Total Population: <B>[joined_player_list.len]</B>"
		if(station_evacuated)
			world << "<BR>[TAB]Evacuation Rate: <B>[num_escapees] ([round((num_escapees/joined_player_list.len)*100, 0.1)]%)</B>"
		else
			world << "<BR>[TAB]Survival Rate: <B>[num_survivors] ([round((num_survivors/joined_player_list.len)*100, 0.1)]%)</B>"
	world << "<BR>"

	//Silicon laws report
	for (var/mob/living/silicon/ai/aiPlayer in mob_list)
		if (aiPlayer.stat != 2 && aiPlayer.mind)
			world << "<b>[aiPlayer.name] (Played by: [aiPlayer.mind.key])'s laws at the end of the round were:</b>"
			aiPlayer.show_laws(1)
		else if (aiPlayer.mind) //if the dead ai has a mind, use its key instead
			world << "<b>[aiPlayer.name] (Played by: [aiPlayer.mind.key])'s laws when it was deactivated were:</b>"
			aiPlayer.show_laws(1)

		if (aiPlayer.connected_robots.len)
			var/robolist = "<b>[aiPlayer.real_name]'s minions were:</b> "
			for(var/mob/living/silicon/robot/robo in aiPlayer.connected_robots)
				robolist += "[robo.name][robo.stat?" (Deactivated) (Played by: [robo.mind.key]), ":" (Played by: [robo.mind.key]), "]"
			world << "[robolist]"
	for (var/mob/living/silicon/robot/robo in mob_list)
		if (!robo.connected_ai && robo.mind)
			if (robo.stat != 2)
				world << "<b>[robo.name] (Played by: [robo.mind.key]) survived as an AI-less borg! Its laws were:</b>"
			else
				world << "<b>[robo.name] (Played by: [robo.mind.key]) was unable to survive the rigors of being a cyborg without an AI. Its laws were:</b>"

			if(robo) //How the hell do we lose robo between here and the world messages directly above this?
				robo.laws.show_laws(world)

	mode.declare_completion()//To declare normal completion.

	//Print a list of antagonists to the server log
	var/list/total_antagonists = list()
	//Look into all mobs in world, dead or alive
	for(var/datum/mind/Mind in minds)
		var/temprole = Mind.special_role
		if(temprole)							//if they are an antagonist of some sort.
			if(temprole in total_antagonists)	//If the role exists already, add the name to it
				total_antagonists[temprole] += ", [Mind.name]([Mind.key])"
			else
				total_antagonists.Add(temprole) //If the role doesnt exist in the list, create it and add the mob
				total_antagonists[temprole] += ": [Mind.name]([Mind.key])"

	//Now print them all into the log!
	log_game("Antagonists at round end were...")
	for(var/i in total_antagonists)
		log_game("[i]s[total_antagonists[i]].")

	return 1
