#include <war3source>
#include <tf2attributes>
#include <sdkhooks>
#include <sdktools>
#assert GGAMEMODE == MODE_WAR3SOURCE

#define RACE_ID_NUMBER 34

public Plugin:myinfo =
{
	name = "Race - Shadow Hunter",
	author = "Razor",
	description = "Shadow Hunter race for War3Source.",
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
	W3Hook(W3Hook_OnAbilityCommand, OnAbilityCommand);
	W3Hook(W3Hook_OnW3TakeDmgBulletPre, OnW3TakeDmgBulletPre);
}
public void UnLoad_Hooks()
{
	if(!HooksLoaded) return;
	HooksLoaded = false;

	W3Unhook(W3Hook_OnUltimateCommand, OnUltimateCommand);
	W3Unhook(W3Hook_OnAbilityCommand, OnAbilityCommand);
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

new SKILL_BLINK, SKILL_OUTRUN, SKILL_HIDDENATTACKS, ULT_HIDDEN;

//Blink
new Float:BlinkDistance[]={1000.0,1100.0,1200.0,1300.0,1400.0};
new String:teleportSound[]="war3source/blinkarrival.mp3";
//Vision Outrun
new Float:OutrunSpeed[]={1.28,1.3,1.32,1.34,1.35};
//Hidden Attacks
new Float:HiddenDamage[]={1.4,1.425,1.45,1.475,1.5};
//Hidden
new Float:HiddenDuration[]={4.0,4.25,4.5,4.75,5.0};

public OnWar3LoadRaceOrItemOrdered2(num,reloadrace_id,String:shortname[])
{
	if(num==RACE_ID_NUMBER||(reloadrace_id>0&&StrEqual("shadowhunter",shortname,false)))
	{
		thisRaceID=War3_CreateNewRace("Shadow Hunter","shadowhunter",reloadrace_id,"Spy Race");
		SKILL_BLINK=War3_AddRaceSkill(thisRaceID,"Blink","Teleports you by 1000 to 1400HU. (+ability)",false,4);
		SKILL_OUTRUN=War3_AddRaceSkill(thisRaceID,"Vision Outrun","Increases movespeed by 28% to 35%.",false,4);
		SKILL_HIDDENATTACKS=War3_AddRaceSkill(thisRaceID,"Hidden Attacks","Attacks that are from 60 degrees backwards deal 40% to 50% more damage.",false,4);
		ULT_HIDDEN=War3_AddRaceSkill(thisRaceID,"Hidden","Gives a cloak that you are able to attack in for 4 to 5 seconds. (+ultimate)",true,4);
		War3_CreateRaceEnd(thisRaceID);
		War3_AddSkillBuff(thisRaceID, SKILL_OUTRUN, fMaxSpeed, OutrunSpeed);
	}
}
public OnW3Denyable(W3DENY:event,client)
{
	if(RaceDisabled)
		return;

	if(War3_GetRace(client)==thisRaceID)
	{
		if((event == DN_CanBuyItem1) && (W3GetVar(EventArg1) == War3_GetItemIdByShortname("boot")))
		{
			W3Deny();
			War3_ChatMessage(client, "You're already wearing boots!");
		}
	}
}
public OnMapStart()
{
	UnLoad_Hooks();
	PrecacheSound(teleportSound);
}
public OnAddSound(sound_priority)
{
	if(sound_priority==PRIORITY_MEDIUM)
	{
		War3_AddSound(teleportSound);
	}
}
public OnAllPluginsLoaded()
{
	War3_RaceOnPluginStart("shadowhunter");
}
public OnPluginEnd()
{
	if(LibraryExists("RaceClass"))
		War3_RaceOnPluginEnd("shadowhunter");
}
public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
	}
}
public void OnUltimateCommand(int client, int race, bool pressed, bool bypass)
{
	if(RaceDisabled)
		return;

	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new skill_level = War3_GetSkillLevel(client,thisRaceID,ULT_HIDDEN);
		if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_HIDDEN,true ))
		{
			War3_CooldownMGR(client,25.0,thisRaceID,ULT_HIDDEN,_,_);
			TF2_AddCondition(client, TFCond_Stealthed,HiddenDuration[skill_level]);
		}
	}
}
public Action OnW3TakeDmgBulletPre(int victim, int attacker, float damage, int damagecustom)
{
	if(RaceDisabled)
		return Plugin_Continue;

	if(ValidPlayer(attacker,true) && ValidPlayer(victim,true))
	{
		if(GetClientTeam(victim)==GetClientTeam(attacker) || W3HasImmunity(victim, Immunity_Skills))
			return Plugin_Continue;
	}
	if(ValidPlayer(victim,true)&&ValidPlayer(attacker,false))
	{
		if(War3_GetRace(attacker) != thisRaceID)
			return Plugin_Continue;
		//Hidden Attacks
		new skill_level = War3_GetSkillLevel(attacker,thisRaceID,SKILL_HIDDENATTACKS);
		new Float:VictimAngle[3];
		GetClientEyeAngles(victim,VictimAngle);
		new Float:AttackerAngle[3];
		GetClientEyeAngles(attacker,AttackerAngle);
		new Float:angleDistance;
		angleDistance = GetVectorDistance(VictimAngle, AttackerAngle);
		if (angleDistance > 180)
		{
			angleDistance = FloatAbs(angleDistance - 360);
		}
		if(angleDistance <= 60.0)
		{
			War3_DamageModPercent(1+(HiddenDamage[skill_level]-1)*W3GetBuffStackedFloat(victim, fAbilityResistance));
			PrintHintText(attacker,"%.2fx damage! Hidden Attack", 1+(HiddenDamage[skill_level]-1)*W3GetBuffStackedFloat(victim, fAbilityResistance));
		}
	}
	return Plugin_Changed;
}
public void OnAbilityCommand(int client, int ability, bool pressed, bool bypass)
{
	if(RaceDisabled)
		return;

	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && ValidPlayer(client,true))
	{
		new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_BLINK);
		if(!Silenced(client)&&(bypass||War3_SkillNotInCooldown(client,thisRaceID,SKILL_BLINK,true)))
			W3Teleport(client,_,_,BlinkDistance[skill_level],thisRaceID,SKILL_BLINK);
	}
}
public OnW3Teleported(client,target,distance,raceid,skillid)
{
	if(ValidPlayer(client) && raceid==thisRaceID)
	{
		War3_CooldownMGR(client,13.0,thisRaceID,SKILL_BLINK,_,_);
		EmitSoundToAll(teleportSound,client);
	}
}
public Action:OnW3TeleportLocationChecking(client,Float:playerVec[3])
{
	if(ValidPlayer(client) && War3_GetRace(client)==thisRaceID)
	{
		float otherVec[3];
		new team = GetClientTeam(client);
		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true)&&GetClientTeam(i)!=team)
			{
				GetClientAbsOrigin(i,otherVec);
				float resistance = W3GetBuffStackedFloat(i, fAbilityResistance);
				if(W3HasImmunity(i,Immunity_Skills)){
					if(GetVectorDistance(playerVec,otherVec)<400.0)
					{
						War3_NotifyPlayerImmuneFromSkill(client, i, SKILL_BLINK);
						return Plugin_Handled;
					}
				}
				else if(resistance != 1.0){
					if(GetVectorDistance(playerVec,otherVec)<400.0*(1-resistance))
					{
						War3_NotifyPlayerImmuneFromSkill(client, i, SKILL_BLINK);
						return Plugin_Handled;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}