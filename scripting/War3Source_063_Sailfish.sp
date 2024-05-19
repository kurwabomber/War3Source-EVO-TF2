#include <war3source>

#pragma semicolon 1
//#include <sourcemod>
//#include <sdkhooks>
//#include "W3SIncs/War3Source_Interface"
#assert GGAMEMODE == MODE_WAR3SOURCE

#define RACE_ID_NUMBER 630

new MaximumWards[]={4,5,6,7,8};
new PushPower[]={40,42,45,47,50};

new Float:SwimSpeed[]={2.25,2.5,2.65,2.8,3.0};

// War3Source stuff
new thisRaceID, SKILL_SWIMFAST, SKILL_HYPERSWIM, SKILL_WATERBREATHING, SKILL_BUGZAP_WARD, ULTIMATE; //, SKILL_UNDERWATER_WEAPON;

bool HooksLoaded = false;
public void Load_Hooks()
{
	if(HooksLoaded) return;
	HooksLoaded = true;

	W3Hook(W3Hook_OnUltimateCommand, OnUltimateCommand);
	W3Hook(W3Hook_OnAbilityCommand, OnAbilityCommand);
	W3Hook(W3Hook_OnWar3EventSpawn, OnWar3EventSpawn);
}
public void UnLoad_Hooks()
{
	if(!HooksLoaded) return;
	HooksLoaded = false;

	W3UnhookAll(W3Hook_OnUltimateCommand);
	W3UnhookAll(W3Hook_OnAbilityCommand);
	W3UnhookAll(W3Hook_OnWar3EventSpawn);
}
bool RaceDisabled=true;
public OnWar3RaceEnabled(newrace)
{
	if(newrace==thisRaceID)
	{
		Load_Hooks();

		RaceDisabled=false;
	}
}
public OnWar3RaceDisabled(oldrace)
{
	if(oldrace==thisRaceID)
	{
		RaceDisabled=true;

		UnLoad_Hooks();
	}
}
//	if(RaceDisabled)
//		return;


public Plugin:myinfo =
{
	name = "War3Source Race - Sailfish",
	author = "El Diablo",
	description = "Sailfish race for War3Source.",
	version = "1.0.0.0",
	url = ""
};

new m_vecVelocity_0, m_vecVelocity_1, m_vecBaseVelocity; //offsets

public OnPluginStart()
{
	m_vecVelocity_0 = FindSendPropInfo("CBasePlayer","m_vecVelocity[0]");
	m_vecVelocity_1 = FindSendPropInfo("CBasePlayer","m_vecVelocity[1]");
	m_vecBaseVelocity = FindSendPropInfo("CBasePlayer","m_vecBaseVelocity");

	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i))
		{
			if(War3_GetRace(i)==thisRaceID)
			{
				SDKHook(i, SDKHook_PreThink, PreThinkEvent);
			}
		}
	}

	CreateTimer(0.5,UnderWaterBreathing,_,TIMER_REPEAT);
}

public OnPluginEnd()
{
	if(LibraryExists("RaceClass"))
		War3_RaceOnPluginEnd("sailfish");
}

public OnAllPluginsLoaded()
{
	War3_RaceOnPluginStart("sailfish");
	ServerCommand("war3 sailfish_flags \"nobots\"");
	//ServerCommand("war3 sailfish_accessflag \"\"");
}

public OnWar3LoadRaceOrItemOrdered2(num,reloadrace_id,String:shortname[])
{
	if(num==RACE_ID_NUMBER||(reloadrace_id>0&&StrEqual("sailfish",shortname,false)))
	{
		thisRaceID = War3_CreateNewRace( "Sailfish", "sailfish",reloadrace_id,"Fastest Swimmer" );

		SKILL_SWIMFAST = War3_AddRaceSkill( thisRaceID, "Swim Uber Fast", "Swim 1.5 to 3 times faster!\nIn Water Only", false, 4 );
		
		SKILL_BUGZAP_WARD = War3_AddRaceSkill( thisRaceID, "Bug Zapper", "(+ability) Zaps enemies.\nMaximum of 8 wards 120 HU radius.\n40 to 50 dmg per second", false, 4, "(voice Help!)");

		SKILL_HYPERSWIM = War3_AddRaceSkill( thisRaceID, "Hyper Swim", "(+ability2) Gives you an extra push of hyper speed\nIn Water Only!", false, 4, "(voice Battle Cry)");

		SKILL_WATERBREATHING = War3_AddRaceSkill( thisRaceID, "Water Breathing", "Stay under water longer.\nLast level is infinite water breathing!\nIn Water Only!", false, 4 );

		ULTIMATE =  War3_AddRaceSkill( thisRaceID, "Drown", "Drown a player", true, 1, "(voice Jeers)");

		War3_CreateRaceEnd( thisRaceID );
	}
}

public OnWardExpire(wardindex, owner, behaviorID)
{
	if(RaceDisabled)
		return;

	if(ValidPlayer(owner) && War3_GetRace(owner)==thisRaceID)
	{
		new skill_level=War3_GetSkillLevel(owner,thisRaceID,SKILL_BUGZAP_WARD);
		W3Hint(owner,HINT_COOLDOWN_EXPIRED,4.0,"You now have %d/%d Bug Zapper Wards.", War3_GetWardCount(owner)-1, MaximumWards[skill_level]);
	}
}
public OnRaceChanged(client,oldrace,newrace)
{
	if(ValidPlayer(client))
	{
		if(newrace==thisRaceID)
		{
			SDKHook(client, SDKHook_PreThink, PreThinkEvent);
		}
		else
		{
			SDKUnhook(client, SDKHook_PreThink, PreThinkEvent);
		}
	}
}

enum Water_level
{
	WATER_LEVEL_NOT_IN_WATER = 0,
	WATER_LEVEL_FEET_IN_WATER,
	WATER_LEVEL_WAIST_IN_WATER,
	WATER_LEVEL_HEAD_IN_WATER
};

new Float:fWaterBreathing[MAXPLAYERSCUSTOM];
new bool:bWaterBreathing[MAXPLAYERSCUSTOM];

new bool:bDrown[MAXPLAYERSCUSTOM];

public OnWar3PlayerAuthed(client)
{
	if(ValidPlayer(client))
	{
		fWaterBreathing[client]=0.0;
		bWaterBreathing[client]=false;
		bDrown[client]=false;
		SDKUnhook(client, SDKHook_PreThink, PreThinkEvent);
	}
}

public void PreThinkEvent(int client)
{
	if(ValidPlayer(client,true))
	{
		if(bDrown[client])
		{
			if(!W3HasImmunity(client,Immunity_Ultimates))
			{
				SetEntProp(client, Prop_Send, "m_nWaterLevel", WATER_LEVEL_HEAD_IN_WATER);
				return;
			}
			else
			{
				bDrown[client]=false;
				SDKUnhook(client, SDKHook_PreThink, PreThinkEvent);
			}
		}

		if(War3_GetRace(client)==thisRaceID)
		{
			if(bWaterBreathing[client])
			{
				SetEntProp(client, Prop_Send, "m_nWaterLevel", WATER_LEVEL_FEET_IN_WATER); //WATER_LEVEL_NOT_IN_WATER
			}
		}
	}
}

public Action:UnderWaterBreathing(Handle:timer,any:client)
{
	if(RaceDisabled)
		return;

	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true))
		{
			// possible special effects to add?
			//if(bDrown[client])
			//{
				//if(!W3HasImmunity(client,Immunity_Ultimates))
				//{
					//new Float:origin[3];
					//GetClientAbsOrigin(client,origin);
					//AttachThrowAwayParticle(client,"rockettrail_waterbubbles", origin, "", 0.25);
				//}
			//}

			if(War3_GetRace(i)==thisRaceID)
			{
				if(GetEntityFlags(i) & FL_INWATER)
				{
					new skill_level=War3_GetSkillLevel(i,thisRaceID,SKILL_WATERBREATHING);
					if(fWaterBreathing[i]==0.0)
					{
						//DP("%i = new",i);
						fWaterBreathing[i]=GetGameTime();
						bWaterBreathing[i]=false;
						continue;
					}
					if(skill_level==1 && fWaterBreathing[i]<(GetGameTime()-3.0))
					{
						//DP("%i = waterbreathing = reset",i);
						bWaterBreathing[i]=false;
						fWaterBreathing[i]=GetGameTime();
					}
					if(skill_level==2 && fWaterBreathing[i]<(GetGameTime()-2.0))
					{
						//DP("%i = waterbreathing = false",i);
						bWaterBreathing[i]=false;
						continue;
					}
					if(skill_level==3 && fWaterBreathing[i]<(GetGameTime()-1.0))
					{
						//DP("%i = waterbreathing = true",i);
						bWaterBreathing[i]=true;
						continue;
					}
					if(skill_level==4 && fWaterBreathing[i]<(GetGameTime()-0.1))
					{
						bWaterBreathing[i]=true;
						continue;
					}
				}
			}
		}
	}

}

//public OnWardExpire(wardindex, owner, behaviorID)
//{
	//if(RaceDisabled)
		//return;

//	if(ValidPlayer(owner) && War3_GetRace(owner)==thisRaceID)
//	{
	//	new skill_level=War3_GetSkillLevel(owner,thisRaceID,SKILL_BUGZAP_WARD);
//		W3Hint(owner,HINT_COOLDOWN_EXPIRED,4.0,"You now have %d/%d Bug Zapper Wards.", War3_GetWardCount(owner)-1, MaximumWards[skill_level]);
	//}
//}

//public OnAbilityCommand(client,ability,bool:pressed)
//{
	//if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	//{
		//new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_UNDERWATER_WEAPON);
		//if(skill_level>0&&!Silenced(client))
		//if(!Silenced(client))
		//{
			//War3_ChatMessage(client,"does nothing");
			//new fCurFlags	= GetEntityFlags(client);
			//fCurFlags &= ~FL_INWATER;
			//SetEntityFlags(client, fCurFlags);

			//DP("Set flags");
			//new weapon =  GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

			//if (IsValidEntity(weapon)) {
				//SetEntProp(weapon, Prop_Data, "m_bFiresUnderwater", true);
				//DP("set fire underwater");
			//}
		//}
	//}
//}

//leap
new Float:leapPower[9]={0.0,4000.0,6000.0,8000.0,10000.0,11000.0,12000.0,13000.0,14000.0};
new String:leapsnd[256]; //="war3source/chronos/timeleap.mp3";

public OnAddSound(sound_priority)
{
	if(sound_priority==PRIORITY_MEDIUM)
	{
		strcopy(leapsnd,sizeof(leapsnd),"war3source/chronos/timeleap.mp3");

		War3_AddSound(leapsnd);
	}
}
public void OnAbilityCommand(int client, int ability, bool pressed, bool bypass)
{
	if(RaceDisabled)
		return;

	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_BUGZAP_WARD);
		if(!Silenced(client))
		{
			if(War3_GetWardCount(client)<MaximumWards[skill_level])
			{
				new Float:location[3];
				GetClientAbsOrigin(client, location);
				if(War3_CreateWardMod(client, location, 120, 360.0, 1.0, "zap", SKILL_BUGZAP_WARD, PushPower, WARD_TARGET_ENEMYS)>-1)
				{
					W3MsgCreatedWard(client, War3_GetWardCount(client), MaximumWards[skill_level]);
				}
			}
			else
			{
				PrintHintText(client, "All of your wards were reset.");
				War3_RemoveWards(client);
			}
		}
	}
	if(War3_GetRace(client)==thisRaceID && ability==2 && pressed && IsPlayerAlive(client))
	{
		new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_HYPERSWIM);
		if(!Silenced(client)&&SkillAvailable(client,thisRaceID,SKILL_HYPERSWIM,true))
		{
			new buttons = GetEntityFlags(client);
			if(buttons & FL_INWATER)
			{
				new Float:velocity[3]={0.0,0.0,0.0};
				velocity[0]= GetEntDataFloat(client,m_vecVelocity_0);
				velocity[1]= GetEntDataFloat(client,m_vecVelocity_1);
				velocity[2]= 50.0;
				new Float:len=GetVectorLength(velocity);
				if(len>3.0)
				{
					//PrintToChatAll("pre  vec %f %f %f",velocity[0],velocity[1],velocity[2]);
					ScaleVector(velocity,leapPower[skill_level]/len);

					//PrintToChatAll("post vec %f %f %f",velocity[0],velocity[1],velocity[2]);
					SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
					War3_EmitSoundToAll(leapsnd,client);
					War3_EmitSoundToAll(leapsnd,client);
					War3_CooldownMGR(client,10.0,thisRaceID,SKILL_HYPERSWIM,_,_);
				}
			}
			else
			{
				War3_ChatMessage(client,"{lightgreen}You must be in water to use this boost!");
			}
		}
	}
}



public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(RaceDisabled)
		return Plugin_Continue;

	if(W3Paused()) return Plugin_Continue;

	if (War3_GetRace(client)==thisRaceID && ((buttons & IN_FORWARD)||(buttons & IN_BACK)))
	{
		new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_SWIMFAST);
		//new fCurFlags	= GetEntityFlags(client);
		if(GetEntityFlags(client) & FL_INWATER)
		{
			War3_SetBuff(client,fMaxSpeed,thisRaceID,SwimSpeed[skill_level]);
		}
		else
		{
			War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
		}
	}
	else
	{
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
	}
	return Plugin_Continue;
}
public Action:StopDrowning(Handle:timer,any:userid)
{
	new client=GetClientOfUserId(userid);
	if(ValidPlayer(client))
	{
		bDrown[client]=false;
		SDKUnhook(client, SDKHook_PreThink, PreThinkEvent);
	}
}
public void OnUltimateCommand(int client, int race, bool pressed, bool bypass)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true,true) && !Silenced(client))
	{
		if(War3_SkillNotInCooldown(client,thisRaceID,ULTIMATE,true))
		{
			new target=War3_GetTargetInViewCone(client,600.0,false,23.0,UltFilter,ULTIMATE);
			if(ValidPlayer(target))
			{
				War3_NotifyPlayerTookDamageFromSkill(target, client, 0, ULTIMATE);
				SDKHook(target, SDKHook_PreThink, PreThinkEvent);
				bDrown[target]=true;
				new userid=GetClientUserId(target);
				CreateTimer(30.0,StopDrowning,userid);
				War3_CooldownMGR(client,20.0,thisRaceID,ULTIMATE,true,true);
			}
		}
	}
}

#if GGAMETYPE == GGAME_TF2
public OnW3SupplyLocker(client)
{
	if(RaceDisabled)
		return;

	if(ValidPlayer(client) && bDrown[client])
	{
		int userid=GetClientUserId(client);
		CreateTimer(0.1,StopDrowning,userid);
	}
}
#endif

public OnW3HealthPickup(const String:output[], caller, activator, Float:delay)
{
	if(RaceDisabled)
		return;

	if(ValidPlayer(activator) && bDrown[activator])
	{
		int userid=GetClientUserId(activator);
		CreateTimer(0.1,StopDrowning,userid);
	}
}

public void OnWar3EventSpawn (int client)
{
	if(ValidPlayer(client) && bDrown[client])
	{
		int userid=GetClientUserId(client);
		CreateTimer(0.1,StopDrowning,userid);
	}
}
