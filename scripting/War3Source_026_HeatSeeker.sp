#define PLUGIN_VERSION "0.0.0.1"
/* ========================================================================== */
/*                                                                            */
/*   War3source_001_Vanilla.sp                                              */
/*   (c) 2012 El Diablo                                                       */
/*                                                                            */
/*   Description  A Race for developers whom want to test vanilla             */
/*                players (players without any modifications) vs              */
/*                what ever race they wish to go against.                     */
/* ========================================================================== */
#pragma semicolon 1

#include <sourcemod>
#include <war3source>
#include <sdkhooks>
#include <tf2attributes>
#include <tf2utils>

// War3Source stuff
int thisRaceID;

int ULT_MULTIPLEROCKET, ABILITY_HEATSEEKING,STABILIZERS_SKILL,T_SKILL2;

// heat seeker
int HeatSeeker_Target[MAXPLAYERS+1];
int remainingShots[MAXPLAYERS+1];
float HeatSeeker_MaxDistance[]={800.0,900.0,1000.0,1100.0,1200.0};
float ult_cooldowntime = 25.0; //20.0

//T_SKILL
float t_skill_magic_armor[]={4.0,4.5,5.0,5.5,6.0};
float SelfBlastDamageReduction[]={0.6,0.55,0.5,0.45,0.4};

//Supernova
float blastRadiusBonus[] = {1.1, 1.125, 1.15, 1.175, 1.2};
float blastFalloffBonus[] = {0.2, 0.225, 0.25, 0.275, 0.3};

char heatSeekingSound[]="war3source/Hunter_Seeker_launch.mp3";
bool isProjectileHoming[MAXENTITIES] = {false,...};

public Plugin:myinfo =
{
	name = "Job - Heat Seeker",
	author = "El Diablo",
	description = "A Race with heat seeking rockets.",
	version = "1.0.0.0",
	url = "http://www.war3evo.com"
};
bool HooksLoaded = false;
public void Load_Hooks()
{
	if(HooksLoaded) return;
	HooksLoaded = true;

	W3Hook(W3Hook_OnWar3EventSpawn, OnWar3EventSpawn);
	W3Hook(W3Hook_OnUltimateCommand, OnUltimateCommand);
	W3Hook(W3Hook_OnAbilityCommand, OnAbilityCommand);
}
public void UnLoad_Hooks()
{
	if(!HooksLoaded) return;
	HooksLoaded = false;

	W3Unhook(W3Hook_OnWar3EventSpawn, OnWar3EventSpawn);
	W3Unhook(W3Hook_OnUltimateCommand, OnUltimateCommand);
	W3Unhook(W3Hook_OnAbilityCommand, OnAbilityCommand);
}
public OnWar3RaceEnabled(newrace)
{
	if(newrace==thisRaceID)
	{
		Load_Hooks();
	}
}
public OnWar3RaceDisabled(oldrace)
{
	if(oldrace==thisRaceID)
	{
		UnLoad_Hooks();
	}
}
public OnAllPluginsLoaded()
{
	War3_RaceOnPluginStart("heat");
	if(LibraryExists("RaceClass"))
		War3_RaceOnPluginEnd("heat");
}
public OnPluginStart()
{
	PrecacheSound(heatSeekingSound);
	//PrecacheSound(rocketticking);
}
public OnAddSound(int priority){
	if(priority == PRIORITY_MEDIUM){
		War3_AddSound(heatSeekingSound);
	}
}
public OnWar3LoadRaceOrItemOrdered2(num,reloadrace_id,String:shortname[])
{
	if(num==26||(reloadrace_id>0&&StrEqual("heat",shortname,false)))
	{
		thisRaceID=War3_CreateNewRace("Heat Seeker","heat",reloadrace_id,"Soldier Race");
		ABILITY_HEATSEEKING=War3_AddRaceSkill(thisRaceID,"Homing Rocket","Locks your rockets on a single player.\nMay run into walls and other things.\nMax range is 800HU to 1200HU. (+ability)",false,4,"(voice Help!)");
		STABILIZERS_SKILL=War3_AddRaceSkill(thisRaceID,"Supernova","Increases blast radius by +10% to +20%. Reduces blast falloff by +20% to +30%",false,4);
		T_SKILL2=War3_AddRaceSkill(thisRaceID,"Barrier","Increases magic armor. 4 to 6 magic armor.\nDecreases self blast damage by -40% to -60%.",false,4);
		ULT_MULTIPLEROCKET=War3_AddRaceSkill(thisRaceID,"Missile Barrage","Loads an extra +6 rockets into your clip.\n2x fire rate for 10s and forces firing for duration.",true,4,"(voice Jeers)");
		W3SkillCooldownOnSpawn(thisRaceID,ULT_MULTIPLEROCKET,20.0,_);
		War3_CreateRaceEnd(thisRaceID);
	}
}

/* ***************************  OnRaceChanged *************************************/

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace==thisRaceID)
	{
		InitPassiveSkills(client);
	}
	else if(oldrace == thisRaceID)
	{
		RemovePassiveSkills(client);
	}
}
/* ****************************** OnSkillLevelChanged ************************** */

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	InitPassiveSkills(client);
}

public InitPassiveSkills(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		new skill_level=War3_GetSkillLevel(client,thisRaceID,T_SKILL2);
		War3_SetBuff(client,fArmorMagic,thisRaceID,t_skill_magic_armor[skill_level]);
		TF2Attrib_SetByName(client, "blast dmg to self increased", SelfBlastDamageReduction[skill_level]);

		skill_level = War3_GetSkillLevel(client, thisRaceID, STABILIZERS_SKILL);
		TF2Attrib_SetByName(client, "dmg falloff decreased", blastFalloffBonus[skill_level]);
		TF2Attrib_SetByName(client, "Blast radius increased", blastRadiusBonus[skill_level]);
	}
}

/* ****************************** RemovePassiveSkills ************************** */

public RemovePassiveSkills(client)
{
	War3_SetBuff(client,fSlow,thisRaceID,1.0);
	War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
	War3_SetBuff(client, fAttackSpeed, thisRaceID, 1.0);
	War3_SetBuff(client,fArmorMagic,thisRaceID,0.0);
	TF2Attrib_RemoveByName(client, "blast dmg to self increased");
	TF2Attrib_RemoveByName(client, "dmg falloff decreased");
	TF2Attrib_RemoveByName(client, "Blast radius increased");
	TF2Attrib_RemoveByName(client, "auto fires full clip");
	TF2Attrib_RemoveByName(client, "projectile spread angle penalty");
	remainingShots[client] = 0;
}

public OnWar3EventSpawn(client){
	if(War3_GetRace(client)==thisRaceID)
	{
		InitPassiveSkills(client);
	}
	else
	{
		RemovePassiveSkills(client);
	}
}

public OnGameFrame()
{
	for(new i = 1; i < MAXENTITIES; i++)
	{
		if(isProjectileHoming[i] == true && IsValidEntity(i))
		{
			SetHomingProjectile(i);
		}
	}
}
public OnEntityCreated(entity, const char[] classname)
{
	if(StrEqual(classname, "tf_projectile_rocket"))
	{
		isProjectileHoming[entity] = true;
	}
}
public OnEntityDestroyed(entity)
{
	if(entity > 0 && entity < MAXENTITIES)
	{
		isProjectileHoming[entity] = false;
	}
}
SetHomingProjectile(entity)
{
	new owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	if(IsValidEntity(owner))
	{
		new Target = HeatSeeker_Target[owner];
		if(Target)
		{
			new Float:ProjLocation[3], Float:ProjVector[3], Float:ProjSpeed, Float:ProjAngle[3], Float:TargetLocation[3], Float:AimVector[3];
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", ProjLocation);
			GetClientAbsOrigin(Target, TargetLocation);
			TargetLocation[2] += 40.0;
			MakeVectorFromPoints(ProjLocation, TargetLocation , AimVector);
			GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", ProjVector);
			ProjSpeed = GetVectorLength(ProjVector);
			AddVectors(ProjVector, AimVector, ProjVector);
			NormalizeVector(ProjVector, ProjVector);
			GetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);
			GetVectorAngles(ProjVector, ProjAngle);
			SetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);
			ScaleVector(ProjVector, ProjSpeed);
			SetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", ProjVector);
		}
	}
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && ValidPlayer(client))
	{
		new skill_level=War3_GetSkillLevel(client,thisRaceID,ABILITY_HEATSEEKING);
		if(War3_SkillNotInCooldown(client,thisRaceID,ABILITY_HEATSEEKING,true))
		{
			HeatSeeker_Target[client]= War3_GetTargetInViewCone(client,HeatSeeker_MaxDistance[skill_level],false,23.0);
			if(!Silenced(client)&&ValidPlayer(HeatSeeker_Target[client]))
			{
				if(!War3_IsUbered(HeatSeeker_Target[client]) && !W3HasImmunity(HeatSeeker_Target[client],Immunity_Skills))
				{
					PrintHintText(client, "Homing Rocket Locked on Target [%N]!",HeatSeeker_Target[client]);
					PrintHintText(HeatSeeker_Target[client], "RUN! You're a target of a heat seeking rocket!");
					War3_CooldownMGR(client, 5.0, thisRaceID, ABILITY_HEATSEEKING);
					War3_EmitSoundToAll(heatSeekingSound, client);
				}
				else
				{
					PrintHintText(client, "Target [%N] is Immune!",HeatSeeker_Target[client]);
					HeatSeeker_Target[client]=0;
				}
			}
		}
	}
}

public OnCooldownExpired(client,raceID,skillNum,bool:expiredByTime){
	if(raceID == thisRaceID){
		if(skillNum == ABILITY_HEATSEEKING){
			PrintHintText(client, "No longer targeting [%N].",HeatSeeker_Target[client]);
			HeatSeeker_Target[client] = 0;
		}
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && pressed && ValidPlayer(client))
	{
		if(War3_SkillNotInCooldown(client,thisRaceID,ULT_MULTIPLEROCKET,true))
		{
			if(!Silenced(client))
			{
				new CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(CWeapon))
				{
					decl String:strName[64];
					GetEntityClassname(CWeapon, strName, 64);
					if(StrEqual(strName, "tf_weapon_rocketlauncher", false) == true || StrEqual(strName, "tf_weapon_rocketlauncher_directhit", false) == true
					|| StrEqual(strName, "tf_weapon_rocketlauncher_airstrike", false) == true)
					{
						War3_CastSpell(client, 0, SpellEffectsLight, SPELLCOLOR_RED, thisRaceID, ULT_MULTIPLEROCKET, 1.25);
						War3_CooldownMGR(client,ult_cooldowntime,thisRaceID,ULT_MULTIPLEROCKET,_,_);
					}
					else
					{
						PrintHintText(client, "You must be holding a rocket launcher.");
					}
				}
			}
			else
			{
				PrintHintText(client, "Either your skill isn't high enough\nor your silenced!");
			}
		}
		else
		{
			PrintHintText(client, "MultiRocket (+ulitmate) Skill is on cooldown!");
		}
	}
}
public OnWar3CastingFinished(client, target, W3SpellEffects:spelleffect, String:SpellColor[], raceid, skillid)
{
	if(ValidPlayer(client,true) && raceid==thisRaceID)
	{
		if(skillid == ULT_MULTIPLEROCKET)
		{
			new CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(CWeapon))
			{
				decl String:strName[64];
				GetEntityClassname(CWeapon, strName, 64);
				if(StrEqual(strName, "tf_weapon_rocketlauncher", false) == true || StrEqual(strName, "tf_weapon_rocketlauncher_directhit", false) == true
				|| StrEqual(strName, "tf_weapon_rocketlauncher_airstrike", false) == true)
				{
					int currentClip = GetEntProp(CWeapon, Prop_Send, "m_iClip1");
					remainingShots[client] = 6+currentClip;
					TF2Attrib_SetByName(client, "auto fires full clip", 1.0);
					TF2Attrib_SetByName(client, "projectile spread angle penalty", 3.0);
					SetEntProp(CWeapon, Prop_Send, "m_iClip1", 6+currentClip);
					War3_SetBuff(client, fAttackSpeed, thisRaceID, 2.0);
				}
				else
				{
					PrintHintText(client, "You must be holding a rocket launcher.");
					War3_CooldownMGR(client,2.0,thisRaceID,ULT_MULTIPLEROCKET,_,_);
				}
			}
		}
	}
}

public OnWar3EventDeath(victim,attacker)
{
	if(HeatSeeker_Target[attacker]==victim)
	{
		HeatSeeker_Target[attacker]=0;
	}
}
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (ValidPlayer(client,true))
	{
		if (remainingShots[client] > 0)
		{
			remainingShots[client]--;
			if(remainingShots[client] == 0){
				War3_SetBuff(client, fAttackSpeed, thisRaceID, 1.0);
				TF2Attrib_RemoveByName(client, "auto fires full clip");
				TF2Attrib_RemoveByName(client, "projectile spread angle penalty");
			}
		}
	}
	return Plugin_Continue;
}