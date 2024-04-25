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

// War3Source stuff
new thisRaceID;

new ULT_MULTIPLEROCKET, ABILITY_HEATSEEKING,STABILIZERS_SKILL,T_SKILL2;

// heat seeker
new HeatSeeker_Target[MAXPLAYERS+1];
new bool:HeatSeeker_Target_Multiple[MAXPLAYERS+1];
new bool:shoot[MAXPLAYERS+1];
new Float:HeatSeeker_MaxDistance[]={1400.0,1500.0,1700.0,1900.0,2000.0};
new Float:ult_cooldowntime = 25.0; //20.0

// multiple rocket
new Amount_Of_Additional_Rockets[]={6,6,6,6,6};
new Float:Rocket_Multiple_Damge[]={1.00,1.05,1.075,1.075,1.1};
new Float:Rocket_Mutiple_Random[]={4.0,3.5,3.5,3.0,3.0};
new Float:shake_duration[]={1.0,0.75,0.5,0.5,0.5};
new Float:shake_magnitude[]={10.0,10.0,7.5,7.5,7.5};
new Float:shake_noise[]={10.0,10.0,10.0,10.0,7.5};

//T_SKILL
new Float:t_skill_magic_armor[]={4.0,4.5,5.0,5.5,6.0};

new String:rocketsound[]="items/cart_explode.wav";
new bool:isProjectileHoming[MAXENTITIES] = {false,...};
//new String:rocketticking[]="mvm/sentrybuster/mvm_sentrybuster_loop.wav";

new Handle:HEATROCKET_CONVAR;
new Handle:HEATROCKET_DAM_CONVAR;

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
}

public OnPluginEnd()
{
	if(LibraryExists("RaceClass"))
		War3_RaceOnPluginEnd("heat");
}
public OnPluginStart()
{
	HEATROCKET_CONVAR = CreateConVar("hs_rocketspeed", "600.0", "0.0 - 1100.0");
	HEATROCKET_DAM_CONVAR  = CreateConVar("hs_damage", "100.0", "0.0 - 1100.0");

	PrecacheSound(rocketsound);
	//PrecacheSound(rocketticking);
}
public OnWar3LoadRaceOrItemOrdered2(num,reloadrace_id,String:shortname[])
{
	if(num==26||(reloadrace_id>0&&StrEqual("heat",shortname,false)))
	{
		thisRaceID=War3_CreateNewRace("Heat Seeker","heat",reloadrace_id,"Soldier Race");
		ABILITY_HEATSEEKING=War3_AddRaceSkill(thisRaceID,"Homing Rocket","Locks your rockets on a single player.\nMay run into walls and other things.\nMax range is 1400HU to 2000HU. (+ability)",false,4);
		STABILIZERS_SKILL=War3_AddRaceSkill(thisRaceID,"Stabilizers","Reduces feedback from shooting multiple rockets.",false,4);
		T_SKILL2=War3_AddRaceSkill(thisRaceID,"Barrier","increases magical armor just a little bit. 4 to 6 magic armor.",false,4);
		ULT_MULTIPLEROCKET=War3_AddRaceSkill(thisRaceID," Missile Barrage","Shoots multiple rockets. 6 additional rockets.\nDamage multiplier is 1x to 1.1x.(+ultimate)",true,4);
		W3SkillCooldownOnSpawn(thisRaceID,ULT_MULTIPLEROCKET,30.0,_);
		War3_CreateRaceEnd(thisRaceID);
	}
}
public OnMapStart()
{
//
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
	}
}

/* ****************************** RemovePassiveSkills ************************** */

public RemovePassiveSkills(client)
{
	War3_SetBuff(client,fSlow,thisRaceID,1.0);
	War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
	War3_SetBuff(client,fArmorMagic,thisRaceID,0.0);
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
				if(!blockingUlt(client,400.0))
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
					W3MsgUltimateBlocked(client);
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
					HeatSeeker_Target_Multiple[client]=true;
					shoot[client]=true;
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

public bool:blockingUlt(client, float radius)  //TF2 only
{
	new Float:playerVec[3];
	GetClientAbsOrigin(client,playerVec);
	new Float:otherVec[3];
	new team = GetClientTeam(client);
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&W3HasImmunity(i,Immunity_Ultimates))
		{
			GetClientAbsOrigin(i,otherVec);
			if(GetVectorDistance(playerVec,otherVec)<radius)
			{
				return true;
			}
		}
	}
	return false;
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
		if (HeatSeeker_Target_Multiple[client]==true)
		{
			if (StrEqual(weaponname, "tf_weapon_rocketlauncher", false) == true || StrEqual(weaponname, "tf_weapon_rocketlauncher_directhit", false) == true
			|| StrEqual(weaponname, "tf_weapon_rocketlauncher_airstrike", false) == true)
			{
				HeatSeeker_Target_Multiple[client]=false;
				shoot[client] = false;
				new Float:vAngles[3];
				new Float:vAngles2[3];
				new Float:vPosition[3];
				new Float:vPosition2[3];
				new skill_level=War3_GetSkillLevel(client,thisRaceID,ULT_MULTIPLEROCKET);
				new Amount = Amount_Of_Additional_Rockets[skill_level];
				new ClientTeam = GetClientTeam(client);
				new Float:Random = Rocket_Mutiple_Random[skill_level];
				new Float:DamageMul = Rocket_Multiple_Damge[skill_level];

				GetClientEyeAngles(client, vAngles2);
				GetClientEyePosition(client, vPosition2);

				vPosition[0] = vPosition2[0];
				vPosition[1] = vPosition2[1];
				vPosition[2] = vPosition2[2];

				new Float:Random2 = Random*-1;
				new counter = 0;
				new shake_level = War3_GetSkillLevel(client,thisRaceID,STABILIZERS_SKILL);
				War3_ShakeScreen(client,shake_duration[shake_level],shake_magnitude[shake_level],shake_noise[shake_level]);
				EmitSoundToAll(rocketsound,client);
				for (new i = 0; i < Amount; i++)
				{
					vAngles[0] = vAngles2[0] + GetRandomFloat(Random2,Random);
					vAngles[1] = vAngles2[1] + GetRandomFloat(Random2,Random);
					// avoid unwanted collision
					new i2 = i%4;
					switch(i2)
					{
						case 0:
						{
							counter++;
							vPosition[0] = vPosition2[0] + counter;
						}
						case 1:
						{
							vPosition[1] = vPosition2[1] + counter;
						}
						case 2:
						{
							vPosition[0] = vPosition2[0] - counter;
						}
						case 3:
						{
							vPosition[1] = vPosition2[1] - counter;
						}
					}
					fireProjectile(vPosition, vAngles, GetConVarFloat(HEATROCKET_CONVAR), GetConVarFloat(HEATROCKET_DAM_CONVAR)*DamageMul, ClientTeam, client);
				}
			}
		}
	}
	return Plugin_Continue;
}


fireProjectile(Float:vPosition[3], Float:vAngles[3] = NULL_VECTOR, Float:flSpeed = 500.0, Float:flDamage = 90.0, iTeam, client)
{
	new String:strClassname[32] = "";
	new String:strEntname[32] = "";

	strClassname = "CTFProjectile_Rocket";
	strEntname = "tf_projectile_rocket";

	new iRocket = CreateEntityByName(strEntname);

	if(!IsValidEntity(iRocket))
		return -1;

	decl Float:vVelocity[3];
	decl Float:vBuffer[3];

	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);

	vVelocity[0] = vBuffer[0]*flSpeed;
	vVelocity[1] = vBuffer[1]*flSpeed;
	vVelocity[2] = vBuffer[2]*flSpeed;

	SetEntPropEnt(iRocket, Prop_Send, "m_hOwnerEntity", client);
	SetEntProp(iRocket,    Prop_Send, "m_iTeamNum",     iTeam, 1);
	SetEntData(iRocket, FindSendPropInfo(strClassname, "m_nSkin"), (iTeam-2), 1, true);

	SetEntDataFloat(iRocket, FindSendPropInfo(strClassname, "m_iDeflected") + 4, flDamage, true); // set damage
	TeleportEntity(iRocket, vPosition, vAngles, vVelocity);

	SetVariantInt(iTeam);
	AcceptEntityInput(iRocket, "TeamNum", -1, -1, 0);

	SetVariantInt(iTeam);
	AcceptEntityInput(iRocket, "SetTeam", -1, -1, 0);

	DispatchSpawn(iRocket);

	return iRocket;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	new CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(shoot[client] && IsValidEntity(CWeapon))
	{
		decl String:strName[64];
		GetEntityClassname(CWeapon, strName, 64);
		if(StrEqual(strName, "tf_weapon_rocketlauncher", false) == true || StrEqual(strName, "tf_weapon_rocketlauncher_directhit", false) == true
		|| StrEqual(strName, "tf_weapon_rocketlauncher_airstrike", false) == true)
		{
			SetEntPropFloat(CWeapon, Prop_Send, "m_flNextPrimaryAttack", 0.0);
			buttons |= IN_ATTACK;
		}
	}
	return Plugin_Continue;
}