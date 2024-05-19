#include <war3source>
#include <tf2attributes>
#include <sdkhooks>
#include <sdktools>
#assert GGAMEMODE == MODE_WAR3SOURCE

#define RACE_ID_NUMBER 32

public Plugin:myinfo =
{
	name = "Race - Morph",
	author = "Razor",
	description = "Morph(morphling) race for War3Source.",
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
	
}
public void UnLoad_Hooks()
{
	if(!HooksLoaded) return;
	HooksLoaded = false;

	W3Unhook(W3Hook_OnUltimateCommand, OnUltimateCommand);
	W3Unhook(W3Hook_OnAbilityCommand, OnAbilityCommand);
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
public OnMapStart()
{
	UnLoad_Hooks();
	PrecacheSound("buttons/button2.wav");
}

new SKILL_STRMORPH, SKILL_AGIMORPH, SKILL_LIQUID, ULT_MORPH;

//Strength Morph
int strPoints[MAXPLAYERSCUSTOM];
new Float:StrDMG[]={0.024,0.025,0.027,0.029,0.03};
//new Float:StrHP[]={0.0,6.0,6.0,6.0,6.0,6.375,6.75,7.125,7.5};
new Float:StrRegen[]={0.5,0.55,0.6,0.65,0.7};
//Agility Morph
int agiPoints[MAXPLAYERSCUSTOM];
//new Float:AgiAttSPD[]={0.0,0.03,0.03,0.03,0.03,0.03125,0.0325,0.03375,0.035};
new Float:AgiMove[]={0.035,0.0365,0.0375,0.03875,0.04};
new Float:AgiDef[]={0.5,0.6,0.7,0.8,0.9};
int morphPoints[MAXPLAYERSCUSTOM];
//Liquid Form
new Float:Evasion[]={0.06,0.07,0.075,0.084,0.1};
//Morph
new Float:MorphRange[]={1050.0,1100.0,1150.0,1200.0,1250.0};
new Float:MorphCooldown[]={60.0,60.0,60.0,60.0,60.0};
new Float:MorphDuration[]={6.0,6.25,6.5,6.75,7.0};
float djAngle[MAXPLAYERSCUSTOM][3];
float djPos[MAXPLAYERSCUSTOM][3];
new TFClassType:MorphSavedClass[MAXPLAYERSCUSTOM];
bool isMorphed[MAXPLAYERSCUSTOM];

public OnWar3LoadRaceOrItemOrdered2(num,reloadrace_id,String:shortname[])
{
	if(num==RACE_ID_NUMBER||(reloadrace_id>0&&StrEqual("morph",shortname,false)))
	{
		thisRaceID=War3_CreateNewRace("Morphling","morph",reloadrace_id,"Morphling from DOTA");
		SKILL_STRMORPH=War3_AddRaceSkill(thisRaceID,"Strength Morph","Per each point assigned to strength, you gain 2.4% to 3% damage & 0.5 to 0.7 regeneration.",false,4,"(voice Help!)");
		SKILL_AGIMORPH=War3_AddRaceSkill(thisRaceID,"Agility Morph","Per each point assigned to agility, you gain 3.5% to 4% movespeed & 0.5 to 0.9 armor.",false,4,"(voice Battle Cry)");
		SKILL_LIQUID=War3_AddRaceSkill(thisRaceID,"Splishy Splashy (Liquid Form)","Gives 6% to 10% evasion.",false,4);
		ULT_MORPH=War3_AddRaceSkill(thisRaceID,"Morph","Changes your race & class to your target. Targets whoever is within a cone.\n1050 to 1250HU range, 60s cooldown, and 6 to 7s duration.",true,4,"(voice Jeers)");
		War3_CreateRaceEnd(thisRaceID);
		War3_AddSkillBuff(thisRaceID, SKILL_LIQUID, fDodgeChance, Evasion);
		W3SkillCooldownOnSpawn(thisRaceID,ULT_MORPH,30.0,true);
	}
}
public OnW3Denyable(W3DENY:event,client)
{
	if((event == DN_CanBuyItem1))
	{
		if(War3_GetRace(client)==thisRaceID)
		{
			if((W3GetVar(EventArg1) == War3_GetItemIdByShortname("claw")))
			{
				W3Deny();
				War3_ChatMessage(client, "You are unable to grasp the item!");
			}
			if((W3GetVar(EventArg1) == War3_GetItemIdByShortname("boot")))
			{
				W3Deny();
				War3_ChatMessage(client, "You are unable to grasp the item!");
			}
			if((W3GetVar(EventArg1) == War3_GetItemIdByShortname("ring")))
			{
				W3Deny();
				War3_ChatMessage(client, "You are unable to grasp the item!");
			}
		}
	}
}
public OnAllPluginsLoaded()
{
	War3_RaceOnPluginStart("morph");
}

public OnPluginEnd()
{
	if(LibraryExists("RaceClass"))
		War3_RaceOnPluginEnd("morph");
}
public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{	
		strPoints[client] = 0;
		agiPoints[client] = 0;
		morphPoints[client] = 0;
		//str
		War3_SetBuff(client,fDamageModifier,thisRaceID,0.0);
		War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,0);
		War3_SetBuff(client,fHPRegen,thisRaceID,0.0);
		//agi
		War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
		War3_SetBuff(client,fArmorPhysical,thisRaceID,0.0);
		War3_SetBuff(client,fDodgeChance,thisRaceID,0.0);
	}
	else
	{
		strPoints[client] = 0;
		agiPoints[client] = 0;
		morphPoints[client] = 4;
	}
}
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && pressed && ValidPlayer(client))
	{
		new str_skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_STRMORPH);
		new agi_skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_AGIMORPH);
		bool success = false;
		if(!Silenced(client)){
			if(ability==0){
				if(morphPoints[client] > 0)
				{
					strPoints[client]++;
					morphPoints[client]--;
					success = true;
				}
				else if(agiPoints[client] > 0)
				{
					agiPoints[client]--;
					strPoints[client]++;
					success = true;
				}
			}
			else if(ability==2){
				if(morphPoints[client] > 0)
				{
					agiPoints[client]++;
					morphPoints[client]--;
					success = true;
				}
				else if(strPoints[client] > 0)
				{
					strPoints[client]--;
					agiPoints[client]++;
					success = true;
				}
			}
			if(success)
			{
				//str
				War3_SetBuff(client,fDamageModifier,thisRaceID,StrDMG[str_skill_level] * strPoints[client]);
				//War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,RoundToNearest(StrHP[str_skill_level] * strPoints[client]));
				War3_SetBuff(client,fHPRegen,thisRaceID,StrRegen[str_skill_level] * strPoints[client]);
				//agi
				//War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0 + (AgiAttSPD[agi_skill_level] * agiPoints[client]));
				War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0 + (AgiMove[agi_skill_level] * agiPoints[client]));
				War3_SetBuff(client,fArmorPhysical,thisRaceID,AgiDef[agi_skill_level] * agiPoints[client]);
				War3_EmitSoundToClient(client,"buttons/button2.wav");
				PrintHintText(client,"%i STR | %i AGI", strPoints[client], agiPoints[client]);
			}
		}
	}
}
public void OnUltimateCommand(int client, int race, bool pressed, bool bypass)
{
	if(RaceDisabled)
		return;

	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new skill_level = War3_GetSkillLevel(client,thisRaceID,ULT_MORPH);
		if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_MORPH,true ))
		{
			new target;
			target=War3_GetTargetInViewCone(client,MorphRange[skill_level],false,20.0);
			if(ValidPlayer(target,true))
			{
				if(!W3HasImmunity(target,Immunity_Ultimates))
				{
					War3_CooldownMGR(client,MorphCooldown[skill_level],thisRaceID,ULT_MORPH,_,_);
					MorphSavedClass[client] = TF2_GetPlayerClass(client);
					
					W3SetPendingRace(client,-1);
					War3_SetRace(client,War3_GetRace(target));
					TF2_SetPlayerClass(client, TF2_GetPlayerClass(target));
					TF2_RegeneratePlayer(client);
					
					isMorphed[client] = true;
					
					CreateTimer(MorphDuration[skill_level]*W3GetBuffStackedFloat(target, fUltimateResistance),ResetMorph,client);
				}
				else
				{
					War3_ChatMessage(client,"{lightgreen}That player has ultimate immunity!");
					War3_CooldownMGR(client,1.0,thisRaceID,ULT_MORPH,_,_);
				}
			}
			else
			{
				War3_ChatMessage(client,"{lightgreen}No victims found for Morph!");
				War3_CooldownMGR(client,1.0,thisRaceID,ULT_MORPH,_,_);
			}
		}
	}
}
public OnWar3EventDeath(victim, attacker)
{
	if(!isMorphed[victim])
		return;

	float VecPos[3];
	float Angles[3];
	War3_CachedAngle(victim,Angles);
	War3_CachedPosition(victim,VecPos);
	djAngle[victim]=Angles;
	djPos[victim]=VecPos;
	CreateTimer(0.1,Respawn,victim);
	isMorphed[victim] = false;
}
public Action:Respawn(Handle:timer,int client)
{
	if(ValidPlayer(client,false))
	{
		TF2_SetPlayerClass(client, MorphSavedClass[client]);
		TF2_RespawnPlayer(client);
		TeleportEntity(client, djPos[client], djAngle[client], NULL_VECTOR);
		SetEntityHealth(client, 50);
		TF2_AddCondition(client, TFCond_UberchargedCanteen, 2.0);
		W3SetPendingRace(client,-1);
		War3_SetRace(client,thisRaceID);
		War3_RestoreItemsFromDeath(client,false);
	}
	return Plugin_Continue;
}
public Action:ResetMorph(Handle:timer,int client)
{
	if(ValidPlayer(client,false) && isMorphed[client])
	{
		isMorphed[client] = false;
		W3SetPendingRace(client,-1);
		War3_SetRace(client,thisRaceID);
		TF2_SetPlayerClass(client, MorphSavedClass[client]);
		TF2_RegeneratePlayer(client);
	}
}