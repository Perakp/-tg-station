/datum/antagonist/blob
	name="blob"
	unique_antagonist_role = 1
	antag_flag = BE_BLOB

	restricted_jobs = list("cyborg", "AI")
	protected_jobs = list("Security Officer", "Warden", "Detective", "Head of Security", "Captain")


/datum/antagonist/blob/greet_antagonist(var/mob/blob)
	blob << "<span class='userdanger'>You are infected by the Blob!</span>"
	blob << "<b>Your body is ready to give spawn to a new blob core which will eat this station.</b>"
	blob << "<b>Find a good location to spawn the core and then take control and overwhelm the station!</b>"
	blob << "<b>When you have found a location, wait until you spawn; this will happen automatically and you cannot speed up the process.</b>"
	blob << "<b>If you go outside of the station level, or in space, then you will die; make sure your location has lots of ground to cover.</b>"
	return

/datum/antagonist/blob/equip_antagonist(var/datum/mind/antagonist)
	return

