
/datum/game_mode/blob
	name = "blob"

	required_players = 30
	target_blobs = -1

/datum/game_mode/blob/announce()
	world << "<B>The current game mode is - <font color='green'>Blob</font>!</B>"
	world << "<B>A dangerous alien organism is rapidly spreading throughout the station!</B>"
	world << "You must kill it all while minimizing the damage to the station."



/datum/game_mode/blob/declare_completion()
	if(blob_handler.blobwincount <= blobs.len)
		feedback_set_details("round_end_result","win - blob took over")
		world << "<FONT size = 3><B>The blob has taken over the station!</B></FONT>"
		world << "<B>The entire station was eaten by the Blob</B>"
		log_game("Blob mode completed with a blob victory.")

	else if(station_was_nuked)
		feedback_set_details("round_end_result","halfwin - nuke")
		world << "<FONT size = 3><B>Partial Win: The station has been destroyed!</B></FONT>"
		world << "<B>Directive 7-12 has been successfully carried out preventing the Blob from spreading.</B>"
		log_game("Blob mode completed with a tie (station destroyed).")

	else if(!blob_cores.len)
		feedback_set_details("round_end_result","loss - blob eliminated")
		world << "<FONT size = 3><B>The staff has won!</B></FONT>"
		world << "<B>The alien organism has been eradicated from the station</B>"
		log_game("Blob mode completed with a crew victory.")
		world << "<span class='notice'>Rebooting in 30s</span>"
	..()
	return 1
