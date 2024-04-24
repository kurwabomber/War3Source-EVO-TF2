// War3Source_002_OnW3MissionComplete.sp

public War3Source_002_OnW3MissionComplete_OnPluginStart()
{
	HookEvent("mvm_mission_complete", Event_MissionComplete, EventHookMode_Post);
}

public Action:Event_MissionComplete(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(MapChanging || War3SourcePause) return Plugin_Continue;

	char missionName[64];
	char mapName[64];
	GetEventString(event, "mission_name", missionName, sizeof(missionName));
	GetCurrentMap(mapName, sizeof(mapName));

	if(StrContains(mapName, "mvm_ghost_town")){
		GiveAllPlayersXP_Platinum(3000, 35);
		GiveAllPlayersXP_Gold(20000, 120);
	}else if(StrContains(missionName, "normal")){
		GiveAllPlayersXP_Platinum(300, 10);
		GiveAllPlayersXP_Gold(1000, 40);
	}else if(StrContains(missionName, "intermediate")){
		GiveAllPlayersXP_Platinum(600, 17);
		GiveAllPlayersXP_Gold(2000, 60);
	}else if(StrContains(missionName, "ironman")){
		GiveAllPlayersXP_Platinum(600, 20);
		GiveAllPlayersXP_Gold(2000, 70);
	}else if(StrContains(missionName, "advanced")){
		GiveAllPlayersXP_Platinum(600, 25);
		GiveAllPlayersXP_Gold(4000, 80);
	}else if(StrContains(missionName, "expert")){
		GiveAllPlayersXP_Platinum(900, 35);
		GiveAllPlayersXP_Gold(8000, 120);
	}

	return Plugin_Continue;
}

public GiveAllPlayersXP_Platinum(int xp, int platinum){
	for(int i=1;i<=MaxClients;++i){
		if(!ValidPlayer(i))
			continue;
		
		int race = GetRace(i);
		if(!ValidRace(race))
			continue;

		TryToGiveXP_Platinum(i, race, -99, skill1, XPAwardByWin, xp, platinum, "for completing a mission.");
	}
}
public GiveAllPlayersXP_Gold(int xp, int gold){
	for(int i=1;i<=MaxClients;++i){
		if(!ValidPlayer(i))
			continue;
		
		int race = GetRace(i);
		if(!ValidRace(race))
			continue;

		TryToGiveXPGold(i, XPAwardByWin, xp, gold, "for completing a mission.", false);
	}
}
