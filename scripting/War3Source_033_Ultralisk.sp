#include <war3source>
#include <tf2attributes>
#include <sdkhooks>
#include <sdktools>
#assert GGAMEMODE == MODE_WAR3SOURCE

#define RACE_ID_NUMBER 33

public Plugin:myinfo =
{
	name = "Race - Ultralisk",
	author = "Razor",
	description = "Ultralisk race for War3Source.",
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
	W3Hook(W3Hook_OnW3TakeDmgBulletPre, OnW3TakeDmgBulletPre);
}
public void UnLoad_Hooks()
{
	if(!HooksLoaded) return;
	HooksLoaded = false;

	W3Unhook(W3Hook_OnUltimateCommand, OnUltimateCommand);
	W3Unhook(W3Hook_OnW3TakeDmgBulletPre, OnW3TakeDmgBulletPre);
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

new SKILL_ORGAN, SKILL_REGEN, SKILL_PLATING, ULT_FRENZY;

//Anabolic Synthesis
new Float:SynthesisRegen[]={5.0,5.5,6.0,6.5,7.0};
//Chitinous Plating
new PlatingHealth[]={60,65,70,75,80};
//Organ Redundancy
new Float:AmmoRegen[]={0.2,0.225,0.25,0.275,0.3};
//Frenzied
new Float:FrenzyCooldown[]={4.5,4.25,4.0,3.75,3.5};
bool isFrenzied[MAXPLAYERSCUSTOM] = {false,...};
new String:ultsnd[]="war3source/ultralisk_ult.mp3";

public OnWar3LoadRaceOrItemOrdered2(num,reloadrace_id,String:shortname[])
{
	if(num==RACE_ID_NUMBER||(reloadrace_id>0&&StrEqual("ultralisk",shortname,false)))
	{
		thisRaceID=War3_CreateNewRace("Ultralisk","ultralisk",reloadrace_id,"Heavy Race");
		SKILL_ORGAN=War3_AddRaceSkill(thisRaceID,"Organ Redundancy","20% to 30% max ammo per 5 seconds.",false,4);
		SKILL_REGEN=War3_AddRaceSkill(thisRaceID,"Anabolic Synthesis","Increases health regen by 5 to 7 per second.",false,4);
		SKILL_PLATING=War3_AddRaceSkill(thisRaceID,"Chitinous Plating","Increase health by 60 to 80.",false,4);
		ULT_FRENZY=War3_AddRaceSkill(thisRaceID,"Frenzied","Reduce damage by 75% for the next hit taken. Cooldown is 4.5-3.5 seconds.",true,4);
		War3_CreateRaceEnd(thisRaceID);
		War3_AddSkillBuff(thisRaceID, SKILL_REGEN, fHPRegen, SynthesisRegen);
		War3_AddSkillBuff(thisRaceID, SKILL_PLATING, iAdditionalMaxHealth, PlatingHealth);
	}
}
public OnMapStart()
{
	UnLoad_Hooks();
	PrecacheSound(ultsnd);
}
public OnAddSound(sound_priority)
{
	if(sound_priority==PRIORITY_MEDIUM)
	{
		War3_AddSound(ultsnd);
	}
}
public OnAllPluginsLoaded()
{
	War3_RaceOnPluginStart("ultralisk");
}

public OnPluginEnd()
{
	if(LibraryExists("RaceClass"))
		War3_RaceOnPluginEnd("ultralisk");
}
public void OnPluginStart()
{
	HookEvent("post_inventory_application", Event_PlayerreSpawn);
	HookEvent("player_spawn", Event_PlayerreSpawn);
}
public Event_PlayerreSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!ValidPlayer(client,false))
		return;
		
	if(War3_GetRace(client)==thisRaceID)
	{
		new skill_level = War3_GetSkillLevel(client,thisRaceID,SKILL_ORGAN);
		TF2Attrib_SetByName(client,"ammo regen", AmmoRegen[skill_level]);
	}
	isFrenzied[client] = false;
}
public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,0);
		War3_SetBuff(client,fHPRegen,thisRaceID,0.0);
	}
	if(oldrace == thisRaceID){
		TF2Attrib_RemoveByName(client,"ammo regen");
	}
}
public void OnUltimateCommand(int client, int race, bool pressed, bool bypass)
{
	if(RaceDisabled)
		return;

	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new skill_level = War3_GetSkillLevel(client,thisRaceID,ULT_FRENZY);
		if(HasLevels(client,skill_level,1))
		{
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_FRENZY,true ))
			{
				War3_CooldownMGR(client,FrenzyCooldown[skill_level],thisRaceID,ULT_FRENZY,_,_);
				isFrenzied[client] = true;
				War3_EmitSoundToAll(ultsnd,client);
			}
		}
	}
}
public Action OnW3TakeDmgBulletPre(int victim, int attacker, float damage, int damagecustom)
{
	if(RaceDisabled)
		return Plugin_Continue;

	if(ValidPlayer(attacker,true) && ValidPlayer(victim,true))
	{
		if(GetClientTeam(victim)==GetClientTeam(attacker))
			return Plugin_Continue;
	}
	if(ValidPlayer(victim,true)&&ValidPlayer(attacker,false))
	{
		if(isFrenzied[victim])
		{
			isFrenzied[victim] = false;
			PrintHintText(victim, "Frenzy took off %.0f damage!",damage * 0.75);
			War3_DamageModPercent(0.25);
		}
	}
	return Plugin_Changed;
}
