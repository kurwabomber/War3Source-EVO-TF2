/* ========================================================================== */
/*                                                                            */
/*   Filename.c                                                               */
/*   (c) 2001 Author                                                          */
/*                                                                            */
/*   Description                                                              */
/*                                                                            */
/* ========================================================================== */

#include <war3source>

#if GGAMETYPE != GGAME_TF2
	#endinput
#endif

#if GGAMEMODE != MODE_WAR3SOURCE
	#endinput
#endif

//#assert GGAMEMODE == MODE_WAR3SOURCE
//#assert GGAMETYPE == GGAME_TF2
// Make sure the Game is set right in switchgamemode.inc in ../includes/switchgamemode.inc
//#assert GGAMETYPE == GGAME_TF2

new bool:AdminHUD[MAXPLAYERSCUSTOM];
new WatchPlayer[MAXPLAYERSCUSTOM];
new WatchPlayerTicks[MAXPLAYERSCUSTOM];

new Handle:ClientNameInfoMessage;
new Handle:AdminInfoMessage1;
new Handle:AdminInfoMessage2;

public Plugin:myinfo=
{
	name="War3Source:EVO Addon - Client Aim Target Information",
	author="El Diablo",
	description="[War3Source:EVO] Addon Plugin",
	version="1.0.0.1",
};

public OnPluginStart()
{
	//CreateConVar("war3evo_mouseover_info",PLUGIN_VERSION,"War3evo Auction system",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegAdminCmd("sm_adminhud", Command_AdminHud, ADMFLAG_GENERIC, "sm_adminhud");
	//RegAdminCmd("sm_watchplayer", Command_WatchPlayer, ADMFLAG_GENERIC, "sm_adminhud");
	RegConsoleCmd("sm_watchplayer",Command_WatchPlayer);

	ClientNameInfoMessage = CreateHudSynchronizer();
	AdminInfoMessage1 = CreateHudSynchronizer();
	AdminInfoMessage2 = CreateHudSynchronizer();

	CreateTimer(0.1,ClientAimTarget,_,TIMER_REPEAT);
}

public OnWar3PlayerAuthed(client)
{
	if(ValidPlayer(client))
	{
		AdminHUD[client]=false;
		WatchPlayer[client]=-1;
		WatchPlayerTicks[client]=0;
	}
}

// Admin Spectate Move Command
public Action:Command_AdminHud(client, args)
{
	//new iLevel=-1;

	//if(args==1)
	//{
	//	decl String:arg[65];
	//	GetCmdArg(1, arg, sizeof(arg));
	//	iLevel = StringToInt(arg);
	//}

	if(ValidPlayer(client))
	{
		AdminHUD[client]=AdminHUD[client]?false:true;
		War3_ChatMessage(client,"War3 Admin Hud is now %s",AdminHUD[client]?"On":"Off");
	}
}
public Action:Command_WatchPlayer(client, args)
{
	//new iLevel=-1;

	//if(args==1)
	//{
	//	decl String:arg[65];
	//	GetCmdArg(1, arg, sizeof(arg));
	//	iLevel = StringToInt(arg);
	//}

	if(ValidPlayer(client))
	{
		if(GetClientTeam(client)!=TEAM_RED || GetClientTeam(client)!=TEAM_BLUE)
		{
			new target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
			if(ValidPlayer(target))
			{
				if(WatchPlayer[client]==target)
				{
					WatchPlayer[client]=-1;
				}
				else
				{
					WatchPlayer[client]=target;
				}
				WatchPlayerTicks[client]=0;
				War3_ChatMessage(client,"Watch player is now %s",WatchPlayer[client]>0?"Locked On":"Locked Off");
			}
			else
			{
				War3_ChatMessage(client,"Player is not valid!");
				WatchPlayer[client]=-1;
				WatchPlayerTicks[client]=0;
			}
		}
		else
		{
			War3_ChatMessage(client,"Watch player is for spectators only!");
		}
	}
}

public Action:ClientAimTarget(Handle:timer,any:userid)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client))
		{
			//new target=GetClientAimTarget(client,true)
			new target=War3_GetTargetInViewCone(client,10000.0,true, 13.0);
			//GetClientTeam(client)!=GetClientTeam(target) ???
			if(ValidPlayer(target))
			{
#if GGAMETYPE == GGAME_TF2
				if(!Spying(target))
				{
#endif
					//native War3_GetRaceName(raceid,String:retstr[],maxlen);
					char racename[64];
					new raceid=War3_GetRace(target);
					float pDIST = 1.0;
					if(GetClientTeam (target)==2) // red team
					{
						SetHudTextParams(-1.0, 0.20, 0.20, 255, 0, 0, 255);
						pDIST = GetPlayerDistance(client,target);
					}
					else if(GetClientTeam (target)==3)  // blue team
					{
						SetHudTextParams(-1.0, 0.20, 0.20, 0, 0, 255, 255);
						pDIST = GetPlayerDistance(client,target);
					}

					if(ValidRace(raceid)){
						War3_GetRaceName(raceid,racename,sizeof(racename));
						ShowSyncHudText(client, ClientNameInfoMessage, "(%s level %d | DST %.0f HU)",racename,War3_GetLevel(target, raceid),pDIST);
					}else{
						ShowSyncHudText(client, ClientNameInfoMessage, "(%N | DST %.0f HU)",target,pDIST);
					}
#if GGAMETYPE == GGAME_TF2
				}
#endif
			}

			// && GetAdminFlag(GetUserAdmin(client), Admin_Kick) || GetAdminFlag(GetUserAdmin(client), Admin_Root)
			if(AdminHUD[client])
			{
				new ClientX;

				if(!ValidPlayer(target,true) && GetClientTeam(client)==1)
				{
					ClientX = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
					if(ValidPlayer(ClientX))
					{
						target=ClientX;
					}
				}

				if(ValidPlayer(target) && !IsFakeClient(target))
				{
					new String:sStatus[64],String:sClientName[128];
					GetClientName(target,sClientName,sizeof(sClientName));
					new clienttime=RoundToCeil(GetClientTime(target)/60.0);
					if(clienttime<0)
					{
						clienttime=0;
					}

					//vip trail is res
					//real vip is with res, admin
					//custom1 is arcitect race
					Format(sStatus,sizeof(sStatus),"%s","N/A");
					if(GetAdminFlag(GetUserAdmin(target), Admin_Reservation))
					{
						Format(sStatus,sizeof(sStatus),"%s","Trial");
					}
					if(GetAdminFlag(GetUserAdmin(target), Admin_Generic))
					{
						Format(sStatus,sizeof(sStatus),"%s","Vip");
					}
					if(GetAdminFlag(GetUserAdmin(target), Admin_Kick))
					{
						Format(sStatus,sizeof(sStatus),"%s","Kick");
					}
					if(GetAdminFlag(GetUserAdmin(target), Admin_Ban))
					{
						Format(sStatus,sizeof(sStatus),"%s-%s",sStatus,"Ban");
					}
					if(!IsPlayerAlive(target))
					{
						Format(sStatus,sizeof(sStatus),"%s %s",sStatus,"DEAD");
					}
					//Format(sStatus,sizeof(sStatus),"%s ",GetClientTime(target));
					SetHudTextParams(-1.0, 0.26, 0.20, 0, 255, 0, 255);
					ShowSyncHudText(client, AdminInfoMessage1, " (%s) USER ID: #%d ",sStatus,GetClientUserId(target));
					SetHudTextParams(-1.0, 0.29, 0.20, 255, 255, 0, 255);
					ShowSyncHudText(client, AdminInfoMessage2, " ping %d [%s] %d min ",Client_GetFakePing(target, true),sClientName,clienttime);
				}
			}

			if(WatchPlayer[client]>0 && WatchPlayerTicks[client]>=10 && ValidPlayer(WatchPlayer[client],true))
			{
				WatchPlayerTicks[client]=0;
				SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", WatchPlayer[client]);
				SetEntProp(client, Prop_Send, "m_iFOV", 0);
			}
			WatchPlayerTicks[client]++;
			if(WatchPlayerTicks[client]>10)
			{
				WatchPlayerTicks[client]=10;
			}
		}
	}
}

#if GGAMETYPE == GGAME_CSGO
public void OnAllPluginsLoaded()
{
	W3Hook(W3Hook_OnWar3EventSpawn, OnWar3EventSpawn);
}

public void OnWar3EventSpawn (int client)
{
	CreateTimer(0.1, RemoveRadar, GetClientUserId(client));
}
public Action:RemoveRadar(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(ValidPlayer(client))
	{
		SetEntProp(client, Prop_Send, "m_iHideHUD", HIDE_RADAR);
	}
}
#endif

stock Client_GetFakePing(client, bool:goldSource=true)
{
	if (IsFakeClient(client)) {
		return 0;
	}

	new ping;
	new Float:latency = GetClientLatency(client, NetFlow_Outgoing); // in seconds

	// that should be the correct latency, we assume that cmdrate is higher
	// then updaterate, what is the case for default settings
	decl String:cl_cmdrate[4];
	GetClientInfo(client, "cl_cmdrate", cl_cmdrate, sizeof(cl_cmdrate));

	new Float:tickRate = GetTickInterval();
	latency -= (0.5 / StringToInt(cl_cmdrate)) + GetTickInterval(); // correct latency

	if (goldSource) {
		// in GoldSrc we had a different, not fixed tickrate. so we have to adjust
		// Source pings by half a tick to match the old GoldSrc pings.
		latency -= tickRate * 0.5;
	}

	ping = RoundFloat(latency * 1000.0); // as msecs
	if(ping > 1000) ping = 1000; // set bounds, dont show pings under 5 msecs

	return ping;
}