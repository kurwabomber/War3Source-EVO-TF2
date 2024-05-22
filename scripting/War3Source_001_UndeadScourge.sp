//UPDATED FOR WAR3SOURCE EVOLUTION

#include <war3source>
#assert GGAMEMODE == MODE_WAR3SOURCE
#assert GGAMETYPE_JAILBREAK == JAILBREAK_OFF

#define RACE_ID_NUMBER 1
#define RACE_LONGNAME "Undead Scourge"
#define RACE_SHORTNAME "undead"


/**
* File: War3Source_UndeadScourge.sp
* Description: The Undead Scourge race for War3Source.
* Author(s): Anthony Iacono, Necavi, El Diablo
*/

int thisRaceID;

#if GGAMETYPE == GGAME_TF2
float Reincarnation[]={45.0, 44.0, 43.0, 42.0, 40.0};
float UnholySpeed[]={1.24, 1.26, 1.28, 1.3, 1.32};
float VampirePercent[]={0.25, 0.275, 0.3, 0.325, 0.35};
#endif
bool RESwarn[MAXPLAYERSCUSTOM];
#if GGAMETYPE == GGAME_TF2
Handle ClientInfoMessage;
#endif

float CurrentCritChance[MAXPLAYERS+1];
// Team switch checker
bool Can_Player_Revive[MAXPLAYERSCUSTOM+1];

// Methodmap inherits W3player methodmap from war3source.inc
methodmap ThisRacePlayer < W3player
{
	// constructor
	public ThisRacePlayer(int playerindex) //constructor
	{
		if(!ValidPlayer(playerindex)) return view_as<ThisRacePlayer>(0);
		return view_as<ThisRacePlayer>(playerindex); //make sure you do validity check on players
	}
	property bool canrevive
	{
		public get() { return Can_Player_Revive[this.index]; }
		public set( bool value ) { Can_Player_Revive[this.index] =  value; }
	}
	property bool RESwarn
	{
		public get() { return RESwarn[this.index]; }
		public set( bool value ) { RESwarn[this.index] =  value; }
	}
#if GGAMETYPE == GGAME_TF2
	public void hudmessage( char szMessage[MAX_MESSAGE_LENGTH], any ... )
	{
		char szBuffer[MAX_MESSAGE_LENGTH];
		SetGlobalTransTarget(this.index);
		VFormat(szBuffer, sizeof(szBuffer), szMessage, 3);
		SetHudTextParams(-1.0, -1.0, 0.1, 255, 255, 0, 255);
		ShowSyncHudText(this.index, ClientInfoMessage, szBuffer);
	}
#endif
}


int SKILL_LEECH,SKILL_SPEED,SKILL_LOWGRAV,SKILL_SUICIDE;

public Plugin:myinfo =
{
	name = RACE_LONGNAME,
	author = "PimpinJuice, Necavi, and El Diablo",
	description = "The Undead Scourge race for War3Source:EVO.",
	version = "1.0",
	url = "http://war3source.com"
};

bool HooksLoaded = false;
public void Load_Hooks()
{
	if(HooksLoaded) return;
	HooksLoaded = true;

	W3Hook(W3Hook_OnWar3Event, OnWar3Event);
	W3Hook(W3Hook_OnWar3EventSpawn, OnWar3EventSpawn);
}
public void UnLoad_Hooks()
{
	if(!HooksLoaded) return;
	HooksLoaded = false;

	W3Unhook(W3Hook_OnWar3Event, OnWar3Event);
	W3Unhook(W3Hook_OnWar3EventSpawn, OnWar3EventSpawn);
}
bool RaceDisabled=true;
public void OnWar3RaceEnabled(newrace)
{
	if(newrace==thisRaceID)
	{
		Load_Hooks();

		RaceDisabled=false;
	}
}
public void OnWar3RaceDisabled(oldrace)
{
	if(oldrace==thisRaceID)
	{
		RaceDisabled=true;

		UnLoad_Hooks();
	}
}
// War3Source Functions
public OnPluginStart()
{
	//LoadTranslations("w3s.race.undead.phrases");
#if GGAMETYPE == GGAME_TF2
	ClientInfoMessage = CreateHudSynchronizer();
#endif

	HookEvent("player_team",PlayerTeamEvent);

	CreateTimer(0.1,ResWarning,_,TIMER_REPEAT);
	CreateTimer(0.5,CritChanceDecay,_,TIMER_REPEAT);
}
public OnMapStart()
{
	// Reset Can Player Revive
	for(int i=1;i<=MaxClients;i++)    // was MAXPLAYERSCUSTOM
	{
		Can_Player_Revive[i]=true;
	}
}

public OnWar3PlayerAuthed(client)
{
	Can_Player_Revive[client]=true;
}

public OnWar3LoadRaceOrItemOrdered2(num,reloadrace_id,String:shortname[])
{
	if(num==RACE_ID_NUMBER||(reloadrace_id>0&&StrEqual(RACE_SHORTNAME,shortname,false)))
	{
		thisRaceID=War3_CreateNewRace(RACE_LONGNAME,RACE_SHORTNAME,reloadrace_id,"Lifesteal, crits & speed.");
		SKILL_LEECH=War3_AddRaceSkill(thisRaceID,"Vampiric Aura","Leech Health\nYou recieve up to 35% of your damage dealt as Health\nCan not buy item mask any level",false,4);
		SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Unholy Aura","You run up to 32% faster",false,4);
		SKILL_LOWGRAV=War3_AddRaceSkill(thisRaceID,"Blood Lust","When you gain health from vampire effects, a portion is converted into crit chance boost.\nCrit Chance resets on death and is capped to 20%.\nCrits count as 100% damage increase.\nBonus slowly decays over time.",false,4);
		SKILL_SUICIDE=War3_AddRaceSkill(thisRaceID,"Reincarnation","When you die, you revive on the spot.\nHas a base 60 second cooldown.\nDecreases cooldown by -5s each upgrade. After 4 upgrades, reduces to -1s.",true,4, "READY");
		War3_CreateRaceEnd(thisRaceID);

		War3_AddSkillBuff(thisRaceID, SKILL_LEECH, fVampirePercent, VampirePercent);
		War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, UnholySpeed);
		W3SkillCooldownOnSpawn(thisRaceID,SKILL_SUICIDE,45.0,true);
	}
}
public OnAllPluginsLoaded()
{
	War3_RaceOnPluginStart(RACE_SHORTNAME);
}

public OnPluginEnd()
{
	if(LibraryExists("RaceClass"))
		War3_RaceOnPluginEnd(RACE_SHORTNAME);
}

public Action CritChanceDecay(Handle timer){
	for (int i = 1; i<= MaxClients; ++i){
		if(!IsClientInGame(i))
			continue;
		if(!IsPlayerAlive(i))
			continue;
		if(War3_GetRace(i) != thisRaceID)
			continue;
		
		if(CurrentCritChance[i]>0.0)
		{
			CurrentCritChance[i] -= 0.004;
			if(CurrentCritChance[i] < 0.0)
				CurrentCritChance[i] = 0.0;

			War3_SetBuff(i, fCritChance,thisRaceID,CurrentCritChance[i]);
		}
	}
	return Plugin_Continue;
}
/* ***************************  OnRaceChanged *************************************/

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace==thisRaceID)
	{
		InitPassiveSkills(client);
	}
	else
	{
		RemovePassiveSkills(client);
	}
}
/* ****************************** InitPassiveSkills ************************** */
public InitPassiveSkills(client)
{
	War3_SetBuff(client, iAdditionalMaxHealth, thisRaceID, 20);
}
/* ****************************** RemovePassiveSkills ************************** */
public RemovePassiveSkills(client)
{
	ThisRacePlayer player = ThisRacePlayer(client);
	player.setbuff(fCritChance, thisRaceID, 0.0,client);
	player.setbuff(fVampirePercent, thisRaceID, 0.0,client);
	player.setbuff(fMaxSpeed,thisRaceID,1.0,client);
	War3_SetBuff(client, iAdditionalMaxHealth, thisRaceID, 0);
	player.RESwarn = false;
	CurrentCritChance[client] = 0.0;
}
public ResetCrit(client)
{
	ThisRacePlayer player = ThisRacePlayer(client);
	player.setbuff(fCritChance, thisRaceID, 0.0,client);
	CurrentCritChance[client] = 0.0;
	player.RESwarn = false;
}


public PlayerTeamEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(RaceDisabled)
		return;

// Team Switch checker
	int userid=GetEventInt(event,"userid");
	int client=GetClientOfUserId(userid);
	ThisRacePlayer player = ThisRacePlayer(client);
	if(player)
	{
		ResetCrit(client);

		player.canrevive = false;
		player.RESwarn = false;

		int skilllevel=player.getskilllevel(thisRaceID,SKILL_SUICIDE);
		CreateTimer(Reincarnation[skilllevel],PlayerCanRevive,userid);

		player.setcooldown(Reincarnation[skilllevel],thisRaceID,SKILL_SUICIDE,false,true);
	}
}

public Action:PlayerCanRevive(Handle:timer,any:userid)
{
// Team Switch checker
	int client=GetClientOfUserId(userid);
	ThisRacePlayer player = ThisRacePlayer(client);
	if(player)
	{
		player.canrevive=true;
	}
}
public OnW3Denyable(W3DENY:event,client)
{
	if(RaceDisabled)
		return;

	if((event == DN_CanBuyItem1) && War3_GetRace(client) == thisRaceID)
	{
		if(W3GetVar(EventArg1) == War3_GetItemIdByShortname("mask"))
		{
			W3Deny();
			War3_ChatMessage(client, "{lightgreen}The mask would suffocate me!");
		}
		else if(W3GetVar(EventArg1) == War3_GetItemIdByShortname("boot"))
		{
			W3Deny();
			War3_ChatMessage(client, "{lightgreen}The boots don't improve my speed!");
		}
	}
}

public void OnWar3Event(W3EVENT event,int client)
{
	if(RaceDisabled)
		return;

	ThisRacePlayer player = ThisRacePlayer(client);

	if(event==VampireImmunityCheckPre)
	{
		if(player && player.raceid==thisRaceID)
		{
			W3SetVar(EventArg1, Immunity_Skills);
			W3SetVar(EventArg2, SKILL_LEECH);
			return;
		}
	}
	else if(event==OnVampireBuff)
	{
		if(player)
		{
			if(player.raceid==thisRaceID)
			{
				int healthLeeched = W3GetVar(EventArg1);
				
				int skill_level=player.getskilllevel( thisRaceID, SKILL_LOWGRAV );
				if(CurrentCritChance[client]<0.2)
				{
					CurrentCritChance[client] += healthLeeched*(0.01 + 0.001*skill_level)*0.03;
					War3_SetBuff(client, fCritChance,thisRaceID,CurrentCritChance[client]);
				}

				if(CurrentCritChance[client]>0.2)
				{
					CurrentCritChance[client]=0.2;
					War3_SetBuff(client, fCritChance,thisRaceID,CurrentCritChance[client]);
				}
				//DP("Crit after %f",CurrentCritChance);
			}
		}
	}
}

public void OnWar3EventSpawn (int client)
{
	ThisRacePlayer player = ThisRacePlayer(client);
	if(player.raceid==thisRaceID)
	{
		ResetCrit(client);
	}
}

float djAngle[MAXPLAYERSCUSTOM][3];
float djPos[MAXPLAYERSCUSTOM][3];

public OnWar3EventDeath(victim, attacker)
{
	if(RaceDisabled)
		return;

	ThisRacePlayer pVictim = ThisRacePlayer(victim);

	ResetCrit(victim);
	
	if(victim==attacker)
		return;

	int race=W3GetVar(DeathRace);

	if(race==thisRaceID && !pVictim.hexed && pVictim.skillnotcooldown(thisRaceID,SKILL_SUICIDE,true) && (!GetEntProp(victim, Prop_Send, "m_bUseBossHealthBar") || !GetEntProp(victim, Prop_Send, "m_bIsMiniBoss")))
	{
		pVictim.RESwarn = true;
		float VecPos[3];
		float Angles[3];
		War3_CachedAngle(victim,Angles);
		War3_CachedPosition(victim,VecPos);
		djAngle[victim]=Angles;
		djPos[victim]=VecPos;
		CreateTimer(2.5,DoDeathReject,GetClientUserId(victim));

		/*
		if(!War3_IsNewPlayer(victim))
		{
			decl Float:location[3];
			GetClientAbsOrigin(victim,location);
			War3_SuicideBomber(victim, location, SuicideBomberDamageTF[skill], SKILL_SUICIDE, SuicideBomberRadius[skill]);
		}
		else
		{
			W3MsgNewbieProjectBlocked(victim,"Suicide Bomber",
			"You would have\nbeen killed by Undead Scourge's Suicide Bomber,\nbut because you are new\nyou are immune",
			"When your newbie protection wears out,\nyou will need to type lace in chat in order to be immune.");
		}*/
	}
	else if(pVictim.skillcooldown(thisRaceID,SKILL_SUICIDE,true))
	{
		pVictim.message("{blue}Your Reincarnation skill is on cooldown.");
	}
//#if GGAMETYPE == GGAME_TF2
	//}
//#endif
}

/* ****************************** DoDeathReject ************************** */

public Action:DoDeathReject(Handle:timer,any:userid)
{
	int client=GetClientOfUserId(userid);
	ThisRacePlayer player = ThisRacePlayer(client);
	if(player)
	{
		if(player.canrevive==false)
		{
			return Plugin_Handled;
		}
		int skilllevel=player.getskilllevel(thisRaceID,SKILL_SUICIDE);
		player.respawn();
		War3_RestoreItemsFromDeath(client,false);
		//nsEntity_SetHealth(client, death_reject_health[skilllevel]);
		//War3_EmitSoundToAll(DeathRejectSound,client);
		TeleportEntity(client, djPos[client], djAngle[client], NULL_VECTOR);
		player.RESwarn=false;
		player.setcooldown(Reincarnation[skilllevel],thisRaceID,SKILL_SUICIDE,false,true);
	}
	return Plugin_Continue;
}

public Action:ResWarning(Handle:timer,any:userid)
{
	if(RaceDisabled)
		return;

	ThisRacePlayer player;

	for(int client=1;client<=MaxClients;client++)
	{
		player = ThisRacePlayer(client);
		if(player && player.RESwarn)
		{
#if GGAMETYPE == GGAME_TF2
			player.hudmessage("PREPARE TO REVIVE!");
			//SetHudTextParams(-1.0, -1.0, 0.1, 255, 255, 0, 255);
			//ShowSyncHudText(client, ClientInfoMessage, "PREPARE TO REVIVE!");
#else
			player.message("PREPARE TO REVIVE!");
#endif
		}
	}
}
public OnClientPutInServer(client)
{
	ThisRacePlayer player = ThisRacePlayer(client);
	player.RESwarn=false;
}

public OnClientDisconnect(client)
{
	ThisRacePlayer player = ThisRacePlayer(client);
	player.RESwarn=false;
}
