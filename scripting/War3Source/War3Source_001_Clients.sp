// War3Source_000_Clients.sp

public bool:OnClientConnect(client,String:rejectmsg[], maxlen)
{
	new bool:Return_OnClientConnect=true;

	//Return_OnClientConnect = War3Source_Engine_Statistics_OnClientConnect();

	return Return_OnClientConnect;
}
public OnClientConnected(client)
{
#if SHOPMENU3 == MODE_ENABLED
	War3Source_Engine_ItemDatabase3_OnClientConnected(client);
#endif

	War3Source_Engine_Wards_Engine_OnClientConnected(client);
#if GGAMETYPE != GGAME_CSGO
	War3Source_Engine_SteamTools_OnClientConnected(client);
#endif
}

public OnClientPutInServer(client)
{
	LastLoadingHintMsg[client]=GetGameTime();
	PrintToServer("Hooking for %N", client);
	PrintToServer("1");
	//DatabaseSaveXP now handles clearing of vars and triggering retrieval

	War3Source_Engine_DatabaseSaveXP_OnClientPutInServer(client);
	PrintToServer("2");
	War3Source_Engine_BuffMaxHP_OnClientPutInServer(client);
	PrintToServer("3");
	War3Source_Engine_BuffSystem_OnClientPutInServer(client);
	PrintToServer("4");
#if CYBORG_SKIN == MODE_ENABLED
#if GGAMETYPE == GGAME_TF2
	War3Source_Engine_Cyborg_OnClientPutInServer(client);
	PrintToServer("5");
#endif
#endif
	War3Source_Engine_DamageSystem_OnClientPutInServer(client);
	PrintToServer("6");
	War3Source_Engine_ItemOwnership_OnClientPutInServer(client);
	PrintToServer("7");
	//War3Source_Engine_Statistics_OnClientPutInServer(client);
	War3Source_Engine_Weapon_OnClientPutInServer(client);
	PrintToServer("8");
#if GGAMETYPE != GGAME_CSGO
	War3Source_Engine_SteamTools_OnClientPutInServer(client);
	PrintToServer("9");
#endif
	//disabled
	//War3Source_Engine_Talents_OnClientPutInServer(client);
#if GGAMETYPE == GGAME_CSGO
	War3Source_Engine_BuffSpeedGravGlow_OnClientPutInServer(client);
	PrintToServer("10");
	War3Source_Engine_CSGO_Radar_OnClientChange(client);
	PrintToServer("11");
#endif
	PrintToServer("y");
}

public OnClientDisconnect(client)
{
	// War3Source_Engine_Bank
	if (client > 0 && client <= MaxClients)
	{
		Internal_SaveBank(client);
		Clear_Variables(client);
	}
#if GGAMETYPE == GGAME_TF2
	War3Source_Engine_BuffMaxHP_OnClientDisconnect(client);
#if CYBORG_SKIN == MODE_ENABLED
	War3Source_Engine_Cyborg_OnClientDisconnect(client);
#endif
#endif
	War3Source_Engine_DamageSystem_OnClientDisconnect(client);

	War3Source_Engine_DatabaseSaveXP_OnClientDisconnect(client);

	War3Source_Engine_NewPlayers_OnClientDisconnect(client);

	War3Source_Engine_Wards_Engine_OnClientDisconnect(client);

	War3Source_Engine_Weapon_OnClientDisconnect(client);

	War3Source_Engine_Casting_OnClientDisconnect(client);

#if GGAMETYPE == GGAME_CSGO
	War3Source_Engine_CSGO_Radar_OnClientChange(client);
#endif
}

public OnClientDisconnect_Post(client)
{
	War3Source_Engine_Download_Control_OnClientDisconnect_Post(client);
}


public OnWar3PlayerAuthed(client)
{
#if SHOPMENU3 == MODE_ENABLED
	War3Source_Engine_ItemDatabase3_OnWar3PlayerAuthed(client);
#endif

	War3Source_Engine_Notifications_OnWar3PlayerAuthed(client);

	War3Source_Engine_Wards_Wards_OnWar3PlayerAuthed(client);

//=============================
// War3Source_Engine_Bank
//=============================
	// Send call to database for gold information
	char steamid[64];

	if(g_hDatabase) // no bots and steamid
	{
		if(ValidPlayer(client) && !IsFakeClient(client) && GetClientAuthId(client,AuthId_Steam2,STRING(steamid),true))
		{
			CanLoadDataBase = true;

			//strcopy(p_bank_steamid[client], 63, steamid);

			char query[256];
			Format(query, sizeof(query), "SELECT gold,withdraw_stamp FROM `%s` WHERE `sid` = '%s';",DATABASENAME,steamid);
			SQL_TQuery(g_hDatabase, SQLCallback_PlayerJoin, query, GetClientUserId(client));
			return;
		}
	}
	else
	{
		g_hDatabase = internal_W3GetVar(hDatabase);
	}

	// Try one more time?
	if(g_hDatabase) // no bots and steamid
	{
		if(ValidPlayer(client) && !IsFakeClient(client) && GetClientAuthId(client,AuthId_Steam2,STRING(steamid),true))
		{
			CanLoadDataBase = true;

			//strcopy(p_bank_steamid[client], 63, steamid);

			char query[256];
			Format(query, sizeof(query), "SELECT gold,withdraw_stamp FROM `%s` WHERE `sid` = '%s';",DATABASENAME,steamid);
			SQL_TQuery(g_hDatabase, SQLCallback_PlayerJoin, query, GetClientUserId(client));
		}
	}
	else
	{
		BankLog("OnWar3PlayerAuthed() War3Source_Engine_Bank Database Invalid!");
	}

	//War3Source_Engine_Statistics_OnWar3PlayerAuthed(client);

}

//public OnClientPostAdminCheck(client)
//{
//}
