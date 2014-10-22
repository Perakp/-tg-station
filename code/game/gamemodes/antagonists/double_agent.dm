/datum/antagonist/traitor/double_agent

// Creating objectives requires information about other double agents, so it's done in game mode code.
/datum/antagonist/traitor/double_agent/create_objectives(var/datum/mind/double_agent)
	if(double_agent.objectives.len == 0)
		..() //Something went wrong with creating DA objectives, so give normal traitor objectives.
	return


