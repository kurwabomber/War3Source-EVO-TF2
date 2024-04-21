#include <war3source>
#include <tf2attributes>
#assert GGAMEMODE == MODE_WAR3SOURCE

#define RACE_ID_NUMBER 25

//#pragma semicolon 1	///WE RECOMMEND THE SEMICOLON

//#include <sourcemod>
//#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo =
{
	name = "Race - Sniper Commando",
	author = "Razor",
	description = "Sniper Commando race for War3Source.",
	version = "1.0",
};
public W3ONLY(){}

new thisRaceID;

bool HooksLoaded = false;
public void Load_Hooks()
{
	if(HooksLoaded) return;
	HooksLoaded = true;

	W3Hook(W3Hook_OnUltimateCommand, OnUltimateCommand);
	//W3Hook(W3Hook_OnWar3EventSpawn, OnWar3EventSpawn);
}
public void UnLoad_Hooks()
{
	if(!HooksLoaded) return;
	HooksLoaded = false;

	W3Unhook(W3Hook_OnUltimateCommand, OnUltimateCommand);
	//W3Unhook(W3Hook_OnWar3EventSpawn, OnWar3EventSpawn);
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

new SKILL_COMBAT, SKILL_MOVE, SKILL_ADRENALINE, ULT_SCAN;

// Combat Experience
new Float:HeadshotDMG[] = {1.24,1.265,1.29,1.315,1.34};

// On The Move
new Float:MoveMultiplier[] = {1.2,1.225,1.25,1.275,1.3};
new Float:ScopeMoveMultiplier[] = {1.16,1.2,1.22,1.24,1.26};

// Adrenaline
new Float:AdrenalineRegen[]={3.0,3.25,3.5,3.75,4.0};
new Float:AdrenalineAttackspeed[]={1.1,1.1125,1.125,1.13375,1.15};

// UAV Scan
new Float:UAVCooldown[]={38.0,36.0,34.0,32.0,30.0};

public OnWar3LoadRaceOrItemOrdered2(num,reloadrace_id,String:shortname[])
{
	if(num==RACE_ID_NUMBER||(reloadrace_id>0&&StrEqual("commando",shortname,false)))
	{
		thisRaceID=War3_CreateNewRace("Sniper Commando","commando",reloadrace_id,"Sniper Race");
		SKILL_COMBAT=War3_AddRaceSkill(thisRaceID,"Combat Experience","All headshots (hits to the head) deal 24% to 34% more damage.",false,4);
		SKILL_MOVE=War3_AddRaceSkill(thisRaceID,"On The Move","Increases movepseed by 20% to 30% and scope speed by 16% to 26%.",false,4);
		SKILL_ADRENALINE=War3_AddRaceSkill(thisRaceID,"Adrenaline","You regenerate health & increase attackspeed.\nRegenerates 3 to 4 HP per second and increases attackspeed by 10% to 15%.",false,4);
		ULT_SCAN=War3_AddRaceSkill(thisRaceID,"UAV Scan","You and teammates gain the ability to see targets anywhere. Lasts 7 seconds.\nCooldown is 38 to 30 seconds.",true,4);
		War3_CreateRaceEnd(thisRaceID);

		War3_AddSkillBuff(thisRaceID, SKILL_MOVE, fMaxSpeed, MoveMultiplier);
		War3_AddSkillBuff(thisRaceID, SKILL_ADRENALINE, fHPRegen, AdrenalineRegen);
		War3_AddSkillBuff(thisRaceID, SKILL_ADRENALINE, fAttackSpeed, AdrenalineAttackspeed);
	}
}
stock bool:IsValidClient( client, bool:replaycheck = true )
{
    if ( client <= 0 || client > MaxClients ) return false; 
    if ( !IsClientInGame( client ) ) return false; 
    if ( !IsClientConnected( client ) ) return false; 
    if ( GetEntProp( client, Prop_Send, "m_bIsCoaching" ) ) return false; 
    if ( replaycheck )
    {
        if ( IsClientSourceTV( client ) || IsClientReplay( client ) ) return false; 
    }
    return true; 
}
public void OnPluginStart()
{
	HookEvent("post_inventory_application", Event_PlayerreSpawn);
	HookEvent("player_spawn", Event_PlayerreSpawn);
}
public Event_PlayerreSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!IsValidClient(client))
		return;
		
	if(War3_GetRace(client)==thisRaceID)
		GiveCommandoPerks(client);
}
public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace==thisRaceID)
	{
		GiveCommandoPerks(client);
	}
	if(oldrace==thisRaceID)
	{
		RemoveCommandoPerks(client);
	}
}
GiveCommandoPerks(client)
{
	new weapon = GetPlayerWeaponSlot(client, 0);
	new skill_level = War3_GetSkillLevel(client,thisRaceID,SKILL_MOVE);
	if(IsValidEntity(weapon))
	{
		TF2Attrib_SetByName(weapon,"aiming movespeed increased", ScopeMoveMultiplier[skill_level]);
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.001);
	}
}
RemoveCommandoPerks(client)
{
	new weapon = GetPlayerWeaponSlot(client, 0);
	if(IsValidEntity(weapon))
	{
		TF2Attrib_RemoveByName(weapon,"aiming movespeed increased");
	}
}
public OnAllPluginsLoaded()
{
	War3_RaceOnPluginStart("commando");
}

public OnPluginEnd()
{
	if(LibraryExists("RaceClass"))
		War3_RaceOnPluginEnd("commando");
}

public OnMapStart()
{
	UnLoad_Hooks();
}
public OnClientPutInServer(client)
{
	SDKHook(client,SDKHook_TraceAttack,SDK_Forwarded_TraceAttack);
}

public OnClientDisconnect(client)
{
	SDKUnhook(client,SDKHook_TraceAttack,SDK_Forwarded_TraceAttack);
}
public Action:SDK_Forwarded_TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if(RaceDisabled)
		return;
	if(hitgroup == 1 && War3_GetRace(attacker)==thisRaceID && ValidPlayer(attacker,false) && ValidPlayer(victim,false)&&!W3HasImmunity(victim,Immunity_Skills))
	{
		new skill_level = War3_GetSkillLevel(attacker,thisRaceID,SKILL_COMBAT);
		damage *= 1+(HeadshotDMG[skill_level]-1)* W3GetBuffStackedFloat(victim, fAbilityResistance);
	}
}
public Action:stopUltimate(Handle:t,any:client){
	War3_NotifyPlayerSkillActivated(client,ULT_SCAN,false);
	if(ValidPlayer(client,true)){
		PrintHintText(client,"You stopped scanning.");
	}
	for(new i = 0; i < MAXPLAYERS + 1; i++)
	{
		if(IsValidClient(i) && IsValidClient(client) && GetClientTeam(i) != GetClientTeam(client)&&!W3HasImmunity(i,Immunity_Ultimates))
		{
			SetEntProp(i, Prop_Send, "m_bGlowEnabled", 0, 1);
		}
	}
}
public void OnUltimateCommand(int client, int race, bool pressed, bool bypass)
{
	if(RaceDisabled)
		return;

	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new skill_level = War3_GetSkillLevel(client,thisRaceID,ULT_SCAN);
		if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_SCAN,true ))
		{
			if(!War3_IsInSpawn(client))
			{
				War3_CastSpell(client, 0, SpellEffectsLight, SPELLCOLOR_GOLD, thisRaceID, ULT_SCAN, 3.0);
				War3_CooldownMGR(client,UAVCooldown[skill_level],thisRaceID,ULT_SCAN,false,true);
			}
			else
			{
				War3_ChatMessage(client,"You can not be in spawn to cast this spell!");
			}
		}
	}
}

public OnWar3CastingFinished(client, target, W3SpellEffects:spelleffect, String:SpellColor[], raceid, skillid)
{
	//DP("casting finished");
	if(ValidPlayer(client,true) && raceid==thisRaceID)
	{
		if(skillid == ULT_SCAN)
		{
			new skill_level=War3_GetSkillLevel(client,raceid,ULT_SCAN);
			PrintHintText(client,"Scan Finished!");
			CreateTimer(7.0,stopUltimate,client);
			War3_NotifyPlayerSkillActivated(client,ULT_SCAN,true);
			War3_CooldownMGR(client,UAVCooldown[skill_level],thisRaceID,ULT_SCAN);
			for(new i = 0; i < MAXPLAYERS + 1; i++)
			{
				if(IsValidClient(i) && IsValidClient(client) && GetClientTeam(i) != GetClientTeam(client))
				{
					SetEntProp(i, Prop_Send, "m_bGlowEnabled", 1, 1);
				}
			}
		}
	}
}
public OnWar3CancelSpell_Post(client, raceid, skillid, target)
{
	if(ValidPlayer(client,true) && raceid==thisRaceID)
	{
		if(skillid == ULT_SCAN)
		{
			War3_CooldownMGR(client,UAVCooldown[skillid],thisRaceID,ULT_SCAN,false,true);
		}
	}
}