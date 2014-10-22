/datum/game_mode
	var/list/ape_infectees = list()

/datum/game_mode/monkey
	name = "monkey"
	config_tag = "monkey"
	antag_flag = BE_MONKEY

	required_players = 20
	target_monkeys = -1


/datum/antagonist/monkey
	name = "infected monkey"
	restricted_jobs = list("cyborg", "AI")


/datum/antag_handler/monkey

	var/list/carriers = list()

	var/monkeys_to_win = 0
	var/escaped_monkeys = 0

	var/players_per_carrier = 30

/datum/antag_handler/monkey/calculate_target_num_of_antags()
	target_num_of_antags = max(round(num_players()/players_per_carrier, 1), 1)


/datum/game_mode/monkey/announce()
	world << "<B>The current game mode is - Monkey!</B>"
	world << "<B>One or more crewmembers have been infected with Jungle Fever! Crew: Contain the outbreak. None of the infected monkeys may escape alive to Centcom. \
				Monkeys: Ensure that your kind lives on! Rise up against your captors!</B>"


/datum/antagonist/monkey/greet_antagonist(var/mob/carrier)
	carrier << "<B><span class = 'notice'>You are the Jungle Fever patient zero!!</B>"
	carrier << "<b>You have been planted onto this station by the Animal Rights Consortium.</b>"
	carrier << "<b>Soon the disease will transform you into an ape. Afterwards, you will be able spread the infection to others with a bite.</b>"
	carrier << "<b>While your infection strain is undetectable by scanners, any other infectees will show up on medical equipment.</b>"
	carrier << "<b>Your mission will be deemed a success if any of the live infected monkeys reach Centcom.</b>"
	return

/datum/game_mode/monkey/post_setup()
	for(var/datum/mind/carriermind in carriers)
		greet_carrier(carriermind)
		ape_infectees += carriermind

		var/datum/disease/D = new /datum/disease/transformation/jungle_fever
		D.hidden = list(1,1)
		D.holder = carriermind.current
		D.affected_mob = carriermind.current
		carriermind.current.viruses += D
	..()

/datum/game_mode/monkey/proc/check_monkey_victory()
	for(var/mob/living/carbon/monkey/M in living_mob_list)
		if (M.has_disease(/datum/disease/transformation/jungle_fever))
			var/area/A = get_area(M)
			if(is_type_in_list(A, centcom_areas))
				escaped_monkeys++
	if(escaped_monkeys >= monkeys_to_win)
		return 0
	else
		return 1

/datum/game_mode/proc/add_monkey(datum/mind/monkey_mind)
	ape_infectees |= monkey_mind
	monkey_mind.special_role = "Infected Monkey"

/datum/game_mode/proc/remove_monkey(datum/mind/monkey_mind)
	ape_infectees.Remove(monkey_mind)
	monkey_mind.special_role = null


/datum/game_mode/monkey/declare_completion()
	if(!check_monkey_victory())
		feedback_set_details("round_end_result","win - monkey win")
		feedback_set("round_end_result",escaped_monkeys)
		world << "<span class='userdanger'><FONT size = 3>The monkeys have overthrown their captors! Eeek eeeek!!</FONT></span>"
	else
		feedback_set_details("round_end_result","loss - staff stopped the monkeys")
		feedback_set("round_end_result",escaped_monkeys)
		world << "<span class='userdanger'><FONT size = 3>The staff managed to contain the monkey infestation!</FONT></span>"
