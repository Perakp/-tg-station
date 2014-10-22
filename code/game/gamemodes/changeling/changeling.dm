var/list/possible_changeling_IDs = list("Alpha","Beta","Gamma","Delta","Epsilon","Zeta","Eta","Theta","Iota","Kappa","Lambda","Mu","Nu","Xi","Omicron","Pi","Rho","Sigma","Tau","Upsilon","Phi","Chi","Psi","Omega")


/datum/game_mode/changeling
	name = "changeling"
	antag_flag = BE_CHANGELING
	required_players = 15
	target_changelings = -1 // Scaling implemented in calculate_target_num_of_antags

/datum/antag_handler/changeling
	antag_type_path = /datum/antagonist/changeling
	preference_flag = BE_CHANGELING

/*
 * Legacy intercept probabilities
	var/const/prob_int_murder_target = 50 // intercept names the assassination target half the time
	var/const/prob_right_murder_target_l = 25 // lower bound on probability of naming right assassination target
	var/const/prob_right_murder_target_h = 50 // upper bound on probability of naimg the right assassination target

	var/const/prob_int_item = 50 // intercept names the theft target half the time
	var/const/prob_right_item_l = 25 // lower bound on probability of naming right theft target
	var/const/prob_right_item_h = 50 // upper bound on probability of naming the right theft target

	var/const/prob_int_sab_target = 50 // intercept names the sabotage target half the time
	var/const/prob_right_sab_target_l = 25 // lower bound on probability of naming right sabotage target
	var/const/prob_right_sab_target_h = 50 // upper bound on probability of naming right sabotage target

	var/const/prob_right_killer_l = 25 //lower bound on probability of naming the right operative
	var/const/prob_right_killer_h = 50 //upper bound on probability of naming the right operative
	var/const/prob_right_objective_l = 25 //lower bound on probability of determining the objective correctly
	var/const/prob_right_objective_h = 50 //upper bound on probability of determining the objective correctly
*/


/datum/game_mode/changeling/announce()
	world << "<b>The current game mode is - Changeling!</b>"
	world << "<b>There are alien changelings on the station. Do not let the changelings succeed!</b>"


/datum/antag_handler/changeling/calculate_target_num_of_antags()
	var/required_enemies = 1
	var/recommended_enemies = 4
	var/N_players = num_players()
	if(config.changeling_scaling_coeff)
		target_num_of_antags = max(required_enemies, min( round(N_players/(config.changeling_scaling_coeff*2))+2, round(N_players/config.changeling_scaling_coeff) ))
	else
		target_num_of_antags = max(required_enemies, min(num_players(), recommended_enemies))
	return target_num_of_antags


/datum/game_mode/changeling/make_antag_chance(var/mob/living/carbon/human/character) //Assigns changeling to latejoiners
	var/changelingcap = min( round(joined_player_list.len/(config.changeling_scaling_coeff*2))+2, round(joined_player_list.len/config.changeling_scaling_coeff) )
	if(changelings.len >= changelingcap) //Caps number of latejoin antagonists
		return
	if(changelings.len <= (changelingcap - 2) || prob(100 - (config.changeling_scaling_coeff*2)))
		if(character.client.prefs.be_special & BE_CHANGELING)
			if(!jobban_isbanned(character.client, "changeling") && !jobban_isbanned(character.client, "Syndicate"))
				if(!(character.job in ticker.mode.restricted_jobs))
					character.mind.make_Changling()
	..()




// #todo: combine this with /datum/antagonist/changeling
/datum/changeling //stores changeling powers, changeling recharge thingie, changeling absorbed DNA and changeling ID (for changeling hivemind)
	var/list/absorbed_dna = list()
	var/dna_max = 4 //How many extra DNA strands the changeling can store for transformation.
	var/absorbedcount = 1 //We would require at least 1 sample of compatible DNA to have taken on the form of a human.
	var/chem_charges = 20
	var/chem_storage = 50
	var/chem_recharge_rate = 0.5
	var/chem_recharge_slowdown = 0
	var/sting_range = 2
	var/changelingID = "Changeling"
	var/geneticdamage = 0
	var/isabsorbing = 0
	var/geneticpoints = 10
	var/purchasedpowers = list()
	var/mimicing = ""
	var/canrespec = 0
	var/changeling_speak = 0
	var/datum/dna/chosen_dna
	var/obj/effect/proc_holder/changeling/sting/chosen_sting

/datum/changeling/New(var/gender=FEMALE)
	..()
	var/honorific
	if(gender == FEMALE)	honorific = "Ms."
	else					honorific = "Mr."
	if(possible_changeling_IDs.len)
		changelingID = pick(possible_changeling_IDs)
		possible_changeling_IDs -= changelingID
		changelingID = "[honorific] [changelingID]"
	else
		changelingID = "[honorific] [rand(1,999)]"
	absorbed_dna.len = dna_max


/datum/changeling/proc/regenerate()
	chem_charges = min(max(0, chem_charges + chem_recharge_rate - chem_recharge_slowdown), chem_storage)
	geneticdamage = max(0, geneticdamage-1)


/datum/changeling/proc/get_dna(var/dna_owner)
	for(var/datum/dna/DNA in absorbed_dna)
		if(dna_owner == DNA.real_name)
			return DNA

/datum/changeling/proc/can_absorb_dna(var/mob/living/carbon/user, var/mob/living/carbon/target)
	if(absorbed_dna[1] == user.dna)//If our current DNA is the stalest, we gotta ditch it.
		user << "<span class='warning'>We have reached our capacity to store genetic information! We must transform before absorbing more.</span>"
		return
	if(!target)
		return
	if(NOCLONE in target.mutations || HUSK in target.mutations)
		user << "<span class='warning'>DNA of [target] is ruined beyond usability!</span>"
		return
	if(!ishuman(target))//Absorbing monkeys is entirely possible, but it can cause issues with transforming. That's what lesser form is for anyway!
		user << "<span class='warning'>We could gain no benefit from absorbing a lesser creature.</span>"
		return
	var/datum/dna/tDna = target.dna
	for(var/datum/dna/D in absorbed_dna)
		if(tDna.is_same_as(D))
			user << "<span class='warning'>We already have that DNA in storage.</span>"
			return
	if(!check_dna_integrity(target))
		user << "<span class='warning'>[target] is not compatible with our biology.</span>"
		return
	return 1
