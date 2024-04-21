#include <war3source>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <tf2utils>

#assert GGAMEMODE == MODE_WAR3SOURCE

#define RACE_ID_NUMBER 6

//#pragma semicolon 1	///WE RECOMMEND THE SEMICOLON

//#include <sourcemod>
//#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo =
{
	name = "Race - Blademaster",
	author = "Cake & Razor",
	description = "Blademaster (Grunt) race for War3Source.",
	version = "1.0",
};
public W3ONLY(){} //unload this?

new thisRaceID;

bool HooksLoaded = false;
public void Load_Hooks()
{
	if(HooksLoaded) return;
	HooksLoaded = true;

	W3Hook(W3Hook_OnW3TakeDmgBulletPre, OnW3TakeDmgBulletPre);
	W3Hook(W3Hook_OnUltimateCommand, OnUltimateCommand);
}
public void UnLoad_Hooks()
{
	if(!HooksLoaded) return;
	HooksLoaded = false;

	W3Unhook(W3Hook_OnW3TakeDmgBulletPre, OnW3TakeDmgBulletPre);
	W3Unhook(W3Hook_OnUltimateCommand, OnUltimateCommand);
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
new SKILL_CRITS, SKILL_BERSERK, SKILL_SALVE, ULT_WARCRY;

// Critical Strike
new Float:CritChance[] = {0.36,0.395,0.43,0.465,0.5};
new Float:CritMultiplier[] = {2.0,2.1,2.2,2.3,2.4};

// Berserker
new BerserkHP[] = {60,70,80,90,100};
new Float:BerserkSpeed[] = {0.2,0.22,0.24,0.26,0.28};

// Healing Salve
new Float:Regeneration[]={16.0,18.0,20.0,22.0,24.0};
new bool:OutOfCombat[MAXPLAYERS+1];
new Float:TimeOutOfCombat[MAXPLAYERS+1] = {0.0,...};

// War Cry
new Float:WarCryMult[] = {0.3,0.325,0.35,0.375,0.4};
new Float:WarCrySpeed[] = {1.31,1.32,1.33,1.34,1.35};
new Float:WarCryRange[] = {600.0,613.0,625.0,638.0,650.0};
new Float:CurrentMultiplier[MAXPLAYERS+1] = {0.0,...};

public OnWar3LoadRaceOrItemOrdered2(num,reloadrace_id,String:shortname[])
{
	if(num==RACE_ID_NUMBER||(reloadrace_id>0&&StrEqual("blademaster",shortname,false)))
	{
		thisRaceID=War3_CreateNewRace("Blademaster","blademaster",reloadrace_id,"True melee, crits, tank.");
		SKILL_CRITS=War3_AddRaceSkill(thisRaceID,"Precision","Chance to deal +100% -> +140% damage crits. 36% chance to proc.",false,4);
		SKILL_BERSERK=War3_AddRaceSkill(thisRaceID,"Berserk","Passive : Gives +60-100 health and +20%-28% movespeed.",false,4);
		SKILL_SALVE=War3_AddRaceSkill(thisRaceID,"Healing Salve","After 2.5 seconds of being out of combat, you gain +16-24 regen per second.",false,4);
		ULT_WARCRY=War3_AddRaceSkill(thisRaceID,"War Cry","Gives damage and movespeed to you and nearby players.\n+30-40% damage boost, +30-35% movespeed, 600-650HU radius, lasts 8 seconds.",true,4);
		War3_CreateRaceEnd(thisRaceID);
		
		War3_AddSkillBuff(thisRaceID, SKILL_BERSERK, fMaxSpeed2, BerserkSpeed);
		War3_AddSkillBuff(thisRaceID, SKILL_BERSERK, iAdditionalMaxHealth, BerserkHP);
	}
}
public OnAllPluginsLoaded()
{
	War3_RaceOnPluginStart("blademaster");
}

public OnPluginEnd()
{
	if(LibraryExists("RaceClass"))
		War3_RaceOnPluginEnd("blademaster");
}
stock int TF2_GetPlayerMaxHealth(int client) {
	return GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client);
}
GiveBlademasterPerks(client)
{
	new weapon = GetPlayerWeaponSlot(client, 2);
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	
	for(int i = 0;i<=3;++i){
		int wearable = TF2Util_GetPlayerLoadoutEntity(client, i);
		if(IsValidEntity(wearable) && TF2Util_IsEntityWearable(wearable))
			RemoveEntity(wearable);
	}

	StopSalve(client);
	TF2_AddCondition(client, TFCond_RestrictToMelee, 9999999.0);
	TF2Attrib_SetByName(client,"cancel falling damage", 1.0);
	TF2Attrib_SetByName(weapon,"melee range multiplier", 1.25);
	TF2Attrib_SetByName(weapon,"is_a_sword", 1.0);
	TF2Attrib_SetByName(client,"dmg taken increased", 0.9);
	TF2Attrib_SetByName(client,"damage force reduction", 0.0);
	TF2Attrib_SetByName(client,"airblast vulnerability multiplier", 0.0);

	new skilllvl = War3_GetSkillLevel(client,thisRaceID,SKILL_CRITS);
	War3_SetBuff(client,fCritChance,thisRaceID,CritChance[skilllvl]);
	War3_SetBuff(client,fCritModifier,thisRaceID,CritMultiplier[skilllvl]);
}
RemoveBlademasterPerks(client)
{
	new weapon = GetPlayerWeaponSlot(client, 2);
	TF2Attrib_RemoveByName(client,"max health additive bonus");
	TF2Attrib_RemoveByName(client,"CARD: move speed bonus");
	TF2Attrib_RemoveByName(client,"cancel falling damage");
	TF2Attrib_RemoveByName(client,"dmg taken increased");
	TF2Attrib_RemoveByName(client,"damage force reduction");
	TF2Attrib_RemoveByName(client,"airblast vulnerability multiplier");
	if(IsValidEntity(weapon))
	{
		TF2Attrib_RemoveByName(weapon,"melee range multiplier");
		TF2Attrib_RemoveByName(weapon,"is_a_sword");
	}
	War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,0);
	War3_SetBuff(client,fMaxSpeed2,thisRaceID,0.0);
	War3_SetBuff(client,fCritChance,thisRaceID,0.0);
	War3_SetBuff(client,fCritModifier,thisRaceID,0.0);
}

public void OnPluginStart()
{
	CreateTimer(0.25, Timer_CheckSalve, _, TIMER_REPEAT);
	HookEvent("post_inventory_application", Event_PlayerreSpawn);
	HookEvent("player_spawn", Event_PlayerreSpawn);
}

public Action:Timer_CheckSalve(Handle:timer)
{
	for(new i = 0; i < MAXPLAYERS + 1; i++)
	{
		if(ValidPlayer(i))
		{
			if(War3_GetRace(i)==thisRaceID && OutOfCombat[i] == true)
			{
				new skilllvl = War3_GetSkillLevel(i,thisRaceID,SKILL_SALVE);
				new Float:RegenPerTick = Regeneration[skilllvl];
				new clientHealth = GetClientHealth(i);
				new clientMaxHealth = TF2_GetPlayerMaxHealth(i);
				RegenPerTick = RegenPerTick/4;
				if(clientHealth < clientMaxHealth)
				{
					if(float(clientHealth) + RegenPerTick < clientMaxHealth)
					{
						SetEntityHealth(i, clientHealth+RoundToNearest(RegenPerTick));
					}
					else
					{
						SetEntityHealth(i, clientMaxHealth);
					}
				}
				
			}
		}
	}
}
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)//on every server frame
{
	if(ValidPlayer(client))
	{
		if(War3_GetRace(client)==thisRaceID)
		{
			if(TimeOutOfCombat[client] >= 2.5)
			{
				OutOfCombat[client] = true;
			}
			TimeOutOfCombat[client] += GetTickInterval();
		}
	}
	return Plugin_Continue;
}
public Event_PlayerreSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!ValidPlayer(client))
		return;
		
	if(War3_GetRace(client)==thisRaceID)
		GiveBlademasterPerks(client);
}
public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace==thisRaceID)
	{
		GiveBlademasterPerks(client);
	}
	if(oldrace==thisRaceID)
	{
		RemoveBlademasterPerks(client);
	}
}
StopSalve(client)
{	
	OutOfCombat[client] = false;
	TimeOutOfCombat[client] = 0.0;
}

public OnMapStart()
{
	UnLoad_Hooks();
}

public Action OnW3TakeDmgBulletPre(int victim, int attacker, float damage, int damagecustom)
{
	if(RaceDisabled)
		return Plugin_Continue;

	if(ValidPlayer(attacker,true) && ValidPlayer(victim,true))
	{
		if(GetClientTeam(victim)==GetClientTeam(attacker))
		{
			return Plugin_Continue;
		}
	}
	if(IsValidEntity(victim)&&ValidPlayer(attacker,false))
	{
		if(ValidPlayer(victim,true) && War3_GetRace(victim)==thisRaceID)
		{
			StopSalve(victim);
		}
		if(CurrentMultiplier[attacker] > 0.0)
		{
			float resistance = W3GetBuffStackedFloat(victim, fAbilityResistance);

			if(!ValidPlayer(victim,false))
			{
				War3_DamageModPercent(CurrentMultiplier[attacker]*resistance + 1);
			}
			if(ValidPlayer(victim,false)&&!W3HasImmunity(victim,Immunity_Ultimates))
			{
				War3_DamageModPercent(CurrentMultiplier[attacker]*resistance + 1);
			}
		}
	}
	return Plugin_Changed;
}
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if(RaceDisabled)
		return Plugin_Continue;
		
	if(War3_GetRace(client)==thisRaceID)	
	{
		new skilllvl = War3_GetSkillLevel(client,thisRaceID,SKILL_SALVE);
		if(skilllvl > 0)
		{
			StopSalve(client);
		}
	}
	return Plugin_Continue;
}
public Action:WarCryOff(Handle:timer,any:client)
{	
	TF2Attrib_RemoveByName(client, "major move speed bonus");
	CurrentMultiplier[client] = 0.0;
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);
	W3Hint(client,HINT_SKILL_STATUS,3.0,"War Cry has worn off.");
}
public void OnUltimateCommand(int client, int race, bool pressed, bool bypass)
{
	if(RaceDisabled)
		return;

	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new skill_level = War3_GetSkillLevel(client,thisRaceID,ULT_WARCRY);
		if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_WARCRY,true ))
		{
			new Float:Range = WarCryRange[skill_level];
			new Float:AttackerPos[3];
			GetClientAbsOrigin(client,AttackerPos);
			new AttackerTeam = GetClientTeam(client);
			float VictimPos[3];
			bool victimfound = false;
			for(int i=1;i<=MaxClients;i++)
			{
				if(ValidPlayer(i,true))
				{
					int VictimTeam = GetClientTeam(i);
					GetClientAbsOrigin(i,VictimPos);
					if(GetVectorDistance(AttackerPos,VictimPos)<Range && VictimTeam == AttackerTeam)
					{
						GetClientAbsOrigin(i,VictimPos);
						CreateTimer(8.0,WarCryOff,i);
						
						TF2Attrib_SetByName(i,"major move speed bonus",WarCrySpeed[skill_level]);
						CurrentMultiplier[i] = WarCryMult[skill_level];
						TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.2);
						TF2_AddCondition(i, TFCond_SpeedBuffAlly, 0.2);
						W3Hint(i,HINT_SKILL_STATUS,3.0,"You were inspired! Increased damage and movespeed.");
						victimfound = true;
					}
				}
			}
			if(victimfound)
			{
				War3_CooldownMGR(client,45.0,thisRaceID,ULT_WARCRY,_,_);
			}
			if(victimfound == false)
			{
				W3MsgNoTargetFound(client,Range);
			}
		}
	}
}