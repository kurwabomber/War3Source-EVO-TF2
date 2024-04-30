// War3Source_002_OnW3MissionComplete.sp

public War3Source_002_OnW3MissionComplete_OnPluginStart()
{
	//MVMVictory
	HookUserMessage(view_as<UserMsg>(61), Message_MissionVictory);
}
public Action Message_MissionVictory(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init){
	CreateTimer(0.5, GiveMissionRewards);
	return Plugin_Continue;
}

public Action GiveMissionRewards(Handle timer){
	char missionName[512];
	int ObjectiveEntity = FindEntityByClassname(-1, "tf_objective_resource");
	if(IsValidEntity(ObjectiveEntity))
		GetEntPropString(ObjectiveEntity, Prop_Send, "m_iszMvMPopfileName", missionName, sizeof(missionName));

	PrintToChatAll("---- Mission Rewards ----");
	if(StrContains(missionName, "ghost_town") != -1){
		GiveAllPlayersXP_Platinum(3000, 120);
		GiveAllPlayersXP_Gold(20000, 120);
	}else if(StrContains(missionName, "intermediate")  != -1){
		GiveAllPlayersXP_Platinum(600, 65);
		GiveAllPlayersXP_Gold(2000, 60);
	}else if(StrContains(missionName, "ironman") != -1){
		GiveAllPlayersXP_Platinum(600, 65);
		GiveAllPlayersXP_Gold(2000, 70);
	}else if(StrContains(missionName, "advanced") != -1){
		GiveAllPlayersXP_Platinum(600, 90);
		GiveAllPlayersXP_Gold(4000, 80);
	}else if(StrContains(missionName, "expert") != -1){
		GiveAllPlayersXP_Platinum(900, 120);
		GiveAllPlayersXP_Gold(8000, 120);
	}else{
		GiveAllPlayersXP_Platinum(300, 35);
		GiveAllPlayersXP_Gold(1000, 40);
	}
	return Plugin_Stop;
}

public GiveAllPlayersXP_Platinum(int xp, int platinum){
	for(int i=1;i<=MaxClients;++i){
		if(!ValidPlayer(i))
			continue;
		
		int race = GetRace(i);
		if(!ValidRace(race))
			continue;

		TryToGiveXP_Platinum(i, race, -1, skill1, XPAwardByWin, xp, platinum, "for completing a mission.");
	}
}
public GiveAllPlayersXP_Gold(int xp, int gold){
	for(int i=1;i<=MaxClients;++i){
		if(!ValidPlayer(i))
			continue;
		
		int race = GetRace(i);
		if(!ValidRace(race))
			continue;

		TryToGiveXPGold(i, XPAwardByWin, xp, gold, "for completing a mission", false);
	}
}
