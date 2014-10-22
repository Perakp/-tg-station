//Few global vars to track the blob
var/list/blobs = list() //turfs with blob on them
var/list/blob_cores = list()
var/list/blob_nodes = list()


/datum/antag_handler/blob
	antag_type_path = /datum/antagonist/blob
	preference_flag = BE_BLOB

	var/continuous_round_blob = 0 // Blob can grow to a certain limit, or die, but round will go on.
	var/declared = 0
	var/players_per_core = 30
	var/blob_point_rate = 3
	var/blobwincount = 350

/datum/antag_handler/blob/calculate_target_num_of_antags()
	target_num_of_antags = max(round(num_players()/players_per_core, 1), 1)
	blobwincount = initial(blobwincount) * target_num_of_antags
	return target_num_of_antags


/datum/antag_handler/blob/proc/show_message(var/message)
	for(var/datum/mind/blob in antags)
		blob.current << message

/datum/antag_handler/blob/proc/burst_blobs()
	for(var/datum/mind/blob in antags)

		var/client/blob_client = null
		var/turf/location = null

		if(iscarbon(blob.current))
			var/mob/living/carbon/C = blob.current
			if(directory[ckey(blob.key)])
				blob_client = directory[ckey(blob.key)]
				location = get_turf(C)
				if(location.z != 1 || istype(location, /turf/space))
					location = null
				C.gib()

		if(blob_client && location)
			var/obj/effect/blob/core/core = new(location, 200, blob_client, blob_point_rate)


/datum/antag_handler/blob/on_round_start()
	if(!antags.len)
		return
	if(events) // Disable blob random event
		var/datum/round_event_control/blob/B = locate() in events.control
		if(B)
			B.max_occurrences = 0
	else
		ERROR("Events variable is null in blob gamemode post setup.")
	if(!continuous_round_blob && emergency_shuttle)
		emergency_shuttle.always_fake_recall = 1

	spawn(0)
		var/wait_time = rand(waittime_l, waittime_h)
		sleep(wait_time)
		send_intercept(0)
		sleep(100)
		show_message("<span class='userdanger'>You feel tired and bloated.</span>")
		sleep(wait_time)
		show_message("<span class='userdanger'>You feel like you are about to burst.</span>")
		sleep(wait_time / 2)
		burst_blobs()
		sleep(wait_time)
		send_intercept(1)
		declared = 1
		sleep(wait_time)
		priority_announce("Confirmed outbreak of level 5 biohazard aboard [station_name()]. All personnel must contain the outbreak.", "Biohazard Alert", 'sound/AI/outbreak5.ogg')
		sleep(30000)
		send_intercept(2)
	return

/datum/antag_handler/blob/check_finished()
	if(!declared)//No blobs have been spawned yet
		return 0
	if(blobwincount <= blobs.len && !continuous_round_blob)//Blob took over
		return 1
	if(!blob_cores.len && !continuous_round_blob) // blob is dead
		return 1
	return ..()
