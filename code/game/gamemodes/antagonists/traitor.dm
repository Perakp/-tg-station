/* Traitor datum
 *
 * Mostly a carbon copy of antagonist
 *
 */
/datum/antagonist/traitor


/datum/antagonist/traitor/equip_antagonist(var/datum/mind/traitor)
	if (istype(traitor.current, /mob/living/silicon))
		add_law_zero(traitor.current)
	else
		equip_traitor(traitor.current)
	return

/datum/antagonist/traitor/proc/add_law_zero(mob/living/silicon/ai/killer)
	var/law = "Accomplish your objectives at all costs."
	var/law_borg = "Accomplish your AI's objectives at all costs."
	killer << "<b>Your laws have been changed!</b>"
	killer.set_zeroth_law(law, law_borg)
	killer << "New law: 0. [law]"
	give_codewords(killer)


/datum/antagonist/traitor/proc/equip_traitor(mob/living/carbon/human/traitor_mob, var/safety = 0)
	if (!istype(traitor_mob))
		return
	. = 1
	if (traitor_mob.mind)
		if (traitor_mob.mind.assigned_role == "Clown")
			traitor_mob << "Your training has allowed you to overcome your clownish nature, allowing you to wield weapons without harming yourself."
			traitor_mob.mutations.Remove(CLUMSY)

	// find a radio! toolbox(es), backpack, belt, headset
	var/loc = ""
	var/obj/item/R = locate(/obj/item/device/pda) in traitor_mob.contents //Hide the uplink in a PDA if available, otherwise radio
	if(!R)
		R = locate(/obj/item/device/radio) in traitor_mob.contents

	if (!R)
		traitor_mob << "Unfortunately, the Syndicate wasn't able to get you a radio."
		. = 0
	else
		if (istype(R, /obj/item/device/radio))
			// generate list of radio freqs
			var/obj/item/device/radio/target_radio = R
			var/freq = 1441
			var/list/freqlist = list()
			while (freq <= 1489)
				if (freq < 1451 || freq > 1459)
					freqlist += freq
				freq += 2
				if ((freq % 2) == 0)
					freq += 1
			freq = freqlist[rand(1, freqlist.len)]

			var/obj/item/device/uplink/hidden/T = new(R)
			target_radio.hidden_uplink = T
			T.uplink_owner = "[traitor_mob.key]"
			target_radio.traitor_frequency = freq
			traitor_mob << "The Syndicate have cunningly disguised a Syndicate Uplink as your [R.name] [loc]. Simply dial the frequency [format_frequency(freq)] to unlock its hidden features."
			traitor_mob.mind.store_memory("<B>Radio Freq:</B> [format_frequency(freq)] ([R.name] [loc]).")
		else if (istype(R, /obj/item/device/pda))
			// generate a passcode if the uplink is hidden in a PDA
			var/pda_pass = "[rand(100,999)] [pick("Alpha","Bravo","Delta","Omega")]"

			var/obj/item/device/uplink/hidden/T = new(R)
			R.hidden_uplink = T
			T.uplink_owner = "[traitor_mob.key]"
			var/obj/item/device/pda/P = R
			P.lock_code = pda_pass

			traitor_mob << "The Syndicate have cunningly disguised a Syndicate Uplink as your [R.name] [loc]. Simply enter the code \"[pda_pass]\" into the ringtone select to unlock its hidden features."
			traitor_mob.mind.store_memory("<B>Uplink Passcode:</B> [pda_pass] ([R.name] [loc]).")
	if(!safety)//If they are not a rev. Can be added on to.
		give_codewords(traitor_mob)

/datum/antagonist/traitor/proc/assign_exchange_role(var/datum/mind/owner, var/faction, var/datum/mind/target)

	//Assign objectives
	var/datum/objective/steal/exchange/exchange_objective = new
	exchange_objective.set_faction(faction,target)
	exchange_objective.owner = owner
	owner.objectives += exchange_objective

	if(prob(20))
		var/datum/objective/steal/exchange/backstab/backstab_objective = new
		backstab_objective.set_faction(faction)
		backstab_objective.owner = owner
		owner.objectives += backstab_objective

	//Spawn and equip documents
	var/mob/living/carbon/human/mob = owner.current

	var/obj/item/weapon/folder/syndicate/folder
	if(faction == "red")
		folder = new/obj/item/weapon/folder/syndicate/red(mob.locs)
	else
		folder = new/obj/item/weapon/folder/syndicate/blue(mob.locs)

	var/list/slots = list (
		"backpack" = slot_in_backpack,
		"left pocket" = slot_l_store,
		"right pocket" = slot_r_store,
		"left hand" = slot_l_hand,
		"right hand" = slot_r_hand,
	)

	var/where = "At your feet"
	var/equipped_slot = mob.equip_in_one_of_slots(folder, slots)
	if (equipped_slot)
		where = "In your [equipped_slot]"
	mob << "<BR><BR><span class='info'>[where] is a folder containing <b>secret documents</b> that another Syndicate group wants. We have set up a meeting with one of their agents on station to make an exchange. Exercise extreme caution as they cannot be trusted and may be hostile.</span><BR>"
	mob.update_icons()


/datum/antagonist/traitor/create_objectives(var/datum/mind/traitor)
	if(istype(traitor.current, /mob/living/silicon))
		var/objective_count = 0
		if(prob(10))
			var/datum/objective/block/block_objective = new
			block_objective.owner = traitor
			traitor.objectives += block_objective
			objective_count++

		for(var/i = objective_count, i < config.traitor_objectives_amount, i++)
			var/datum/objective/assassinate/kill_objective = new
			kill_objective.owner = traitor
			kill_objective.find_target()
			traitor.objectives += kill_objective

		var/datum/objective/survive/survive_objective = new
		survive_objective.owner = traitor
		traitor.objectives += survive_objective
	else
		var/is_hijacker = prob(10)
		var/objective_count = is_hijacker 			//Hijacking counts towards number of objectives
		objective_count += traitor.objectives.len
		var/list/active_ais = active_ais()
		for(var/i = objective_count, i < config.traitor_objectives_amount, i++)
			if(prob(50))
				if(active_ais.len && prob(100/joined_player_list.len))
					var/datum/objective/destroy/destroy_objective = new
					destroy_objective.owner = traitor
					destroy_objective.find_target()
					traitor.objectives += destroy_objective
				else if(prob(30))
					var/datum/objective/maroon/maroon_objective = new
					maroon_objective.owner = traitor
					maroon_objective.find_target()
					traitor.objectives += maroon_objective
				else
					var/datum/objective/assassinate/kill_objective = new
					kill_objective.owner = traitor
					kill_objective.find_target()
					traitor.objectives += kill_objective
			else
				var/datum/objective/steal/steal_objective = new
				steal_objective.owner = traitor
				steal_objective.find_target()
				traitor.objectives += steal_objective

		if(is_hijacker && objective_count <= config.traitor_objectives_amount) //Don't assign hijack if it would exceed the number of objectives set in config.traitor_objectives_amount
			if (!(locate(/datum/objective/hijack) in traitor.objectives))
				var/datum/objective/hijack/hijack_objective = new
				hijack_objective.owner = traitor
				traitor.objectives += hijack_objective
		else
			if (!(locate(/datum/objective/escape) in traitor.objectives))
				var/datum/objective/escape/escape_objective = new
				escape_objective.owner = traitor
				traitor.objectives += escape_objective
	return


/datum/antagonist/traitor/proc/give_codewords(mob/living/traitor_mob)
	traitor_mob << "<U><B>The Syndicate provided you with the following information on how to identify their agents:</B></U>"
	traitor_mob << "<B>Code Phrase</B>: <span class='danger'>[syndicate_code_phrase]</span>"
	traitor_mob << "<B>Code Response</B>: <span class='danger'>[syndicate_code_response]</span>"

	traitor_mob.mind.store_memory("<b>Code Phrase</b>: [syndicate_code_phrase]")
	traitor_mob.mind.store_memory("<b>Code Response</b>: [syndicate_code_response]")

	traitor_mob << "Use the code words in the order provided, during regular conversation, to identify other agents. Proceed with caution, however, as everyone is a potential foe."
