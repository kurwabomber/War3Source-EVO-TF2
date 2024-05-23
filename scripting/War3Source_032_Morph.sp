#include <war3source>
#include <tf2attributes>
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

new String:explSound[]="weapons/air_burster_explode1.wav";

public OnMapStart()
{
	UnLoad_Hooks();
	PrecacheSound("buttons/button2.wav");
	PrecacheSound(explSound);
}

new SKILL_STATMORPH, SKILL_ADAPTIVE, SKILL_LIQUID, ULT_MORPH;

//Strength Morph
new Float:StrDMG[]={0.12, 0.135, 0.15, 0.165, 0.18};
new Float:StrRegen[]={3.0, 3.25, 3.5, 3.75, 4.0};
//Agility Morph
new Float:AgiMove[]={0.15, 0.1625, 0.175, 0.1875, 0.20};
new Float:AgiDef[]={3.0, 3.25, 3.5, 3.75, 4.0};
bool morphForm[MAXPLAYERSCUSTOM];

//Adaptive Strike
int AdaptiveStrDamage[] = {20, 22, 25, 27, 30};
int AdaptiveAgiDamage[] = {40, 42, 45, 47, 50};

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
		SKILL_STATMORPH=War3_AddRaceSkill(thisRaceID, "Ebb & Flow","Switches stat forms between strength and agility.\nIn strength form: you gain +12-18% damage & 3.0 to 4.0 regeneration.\nIn agility form: you gain +15-20% movespeed and +3-4 physical armor.",false,4,"(voice Help!)");
		SKILL_ADAPTIVE=War3_AddRaceSkill(thisRaceID,"Adaptive Strike","Deals a crushing attack depending on morph form.\nIn strength form: bashes twice and deals 20-30 damage.\nIn agility form: shoots 3 piercing bolts that deal 40-50 damage.",false,4,"(voice Battle Cry)");
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
		morphForm[client] = false;
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
		morphForm[client] = false;

		new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_STATMORPH);
		if(!morphForm[client]){
			//str
			War3_SetBuff(client,fDamageModifier,thisRaceID,StrDMG[skill_level]);
			War3_SetBuff(client,fHPRegen,thisRaceID,StrRegen[skill_level]);

			War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
			War3_SetBuff(client,fArmorPhysical,thisRaceID,0.0);
		}
		else{
			//agi
			War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0 + AgiMove[skill_level]);
			War3_SetBuff(client,fArmorPhysical,thisRaceID,AgiDef[skill_level]);

			War3_SetBuff(client,fDamageModifier,thisRaceID,0.0);
			War3_SetBuff(client,fHPRegen,thisRaceID,0.0);
		}
	}
}
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && pressed && ValidPlayer(client))
	{
		if(!Silenced(client)){
			if(ability==0){
				new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_STATMORPH);
				morphForm[client] = !morphForm[client];
				if(!morphForm[client]){
					//str
					War3_SetBuff(client,fDamageModifier,thisRaceID,StrDMG[skill_level]);
					War3_SetBuff(client,fHPRegen,thisRaceID,StrRegen[skill_level]);

					War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
					War3_SetBuff(client,fArmorPhysical,thisRaceID,0.0);
				}
				else{
					//agi
					War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0 + AgiMove[skill_level]);
					War3_SetBuff(client,fArmorPhysical,thisRaceID,AgiDef[skill_level]);

					War3_SetBuff(client,fDamageModifier,thisRaceID,0.0);
					War3_SetBuff(client,fHPRegen,thisRaceID,0.0);
				}
				War3_EmitSoundToClient(client,"buttons/button2.wav");

				if(!morphForm[client])
					PrintHintText(client,"You are now in Strength form");
				else
					PrintHintText(client,"You are now in Agility form");
			}
			else if(ability==2){
				//Adaptive Strike
				if(War3_SkillNotInCooldown(client, thisRaceID, SKILL_ADAPTIVE,true)){
					int skill_level = War3_GetSkillLevel(client,thisRaceID,SKILL_ADAPTIVE);
					if(!morphForm[client]){
						War3_CooldownMGR(client,15.0,thisRaceID,SKILL_ADAPTIVE,_,_);
						
						new Float:fwd[3],Float:fAngles[3],Float:fOrigin[3];
						GetClientEyeAngles(client, fAngles);
						GetClientEyePosition(client, fOrigin);
						GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
						ScaleVector(fwd, 100.0);
						AddVectors(fOrigin, fwd, fOrigin);
						War3_EmitSoundToAll(explSound,client);
						createExplosionEffect(fOrigin);
						
						for(new i = 1; i < MAXENTITIES; i++)
						{
							if(IsValidForDamage(i) && IsOnDifferentTeams(client,i))
							{
								new Float:targetvec[3];
								GetEntPropVector(i, Prop_Data, "m_vecOrigin", targetvec);
								if(GetVectorDistance(fOrigin, targetvec, true) <= 62500)
								{
									if(IsPointVisible(fOrigin,targetvec))
									{
										War3_DealDamage(i, RoundFloat(AdaptiveStrDamage[skill_level]*W3GetBuffStackedFloat(i,fAbilityResistance)), client, DMG_BLAST, "adaptive_strike", W3DMGORIGIN_SKILL, W3DMGTYPE_PHYSICAL);
									}
								}
							}
						}
						CreateTimer(0.5,doNextBash,client);
					}
					else{
						War3_CooldownMGR(client,9.0,thisRaceID,SKILL_ADAPTIVE,_,_);
						War3_EmitSoundToAll(explSound,client);

						float fAngles[3],fOrigin[3],vBuffer[3],fVelocity[3], fwd[3];
						GetClientEyePosition(client, fOrigin);
						GetClientEyeAngles(client,fAngles);
						fAngles[1] -= 8.0;
						for(int i=0;i<3;++i){
							new iEntity = CreateEntityByName("tf_projectile_arrow");
							if (IsValidEdict(iEntity)) 
							{
								new iTeam = GetClientTeam(client);
								SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

								SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
								SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
								SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", client);
								SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
								SetEntProp(iEntity, Prop_Send, "m_bCritical", 1);
								
								GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
								GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
								ScaleVector(fwd, 30.0);
								
								AddVectors(fOrigin, fwd, fOrigin);
								
								new Float:Speed = 2000.0;
								fVelocity[0] = vBuffer[0]*Speed;
								fVelocity[1] = vBuffer[1]*Speed;
								fVelocity[2] = vBuffer[2]*Speed;
								SetEntPropVector(iEntity, Prop_Send, "m_vInitialVelocity", fVelocity );
								SetEntProp(iEntity, Prop_Send, "m_usSolidFlags", 0x0008);
								SetEntProp(iEntity, Prop_Data, "m_nSolidType", 6);
								SetEntProp(iEntity, Prop_Send, "m_CollisionGroup", 13); 
								TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
								DispatchSpawn(iEntity);
								SDKHook(iEntity, SDKHook_Touch, OnCollisionPiercing);
								CreateSpriteTrail(iEntity, "0.33", "5.0", "1.0", iTeam == 2 ? "materials/effects/arrowtrail_red.vmt":"materials/effects/arrowtrail_blu.vmt", "255 255 255");
								CreateTimer(4.0, SelfDestruct, EntIndexToEntRef(iEntity));
							}
							fAngles[1] += 8.0;
						}
					}
				}
			}
		}
	}
}

public Action:OnCollisionPiercing(entity, client)
{
	char strName[32];
	GetEntityClassname(client, strName, 32)
	char strName1[32];
	GetEntityClassname(entity, strName1, 32)
	if(!StrEqual(strName, strName1) && IsValidForDamage(client))
	{
		int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
		if(ValidPlayer(owner) && IsOnDifferentTeams(entity,client))
		{
			float origin[3],ProjAngle[3],vBuffer[3];
			GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);
			GetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);
			GetAngleVectors(ProjAngle, vBuffer, NULL_VECTOR, NULL_VECTOR);
			ScaleVector(vBuffer, 100.0);
			AddVectors(origin, vBuffer, origin);
			TeleportEntity(entity, origin,NULL_VECTOR,NULL_VECTOR);
			RequestFrame(fixPiercingVelocity,EntIndexToEntRef(entity))

			int skill_level = War3_GetSkillLevel(owner, thisRaceID, SKILL_ADAPTIVE);
			War3_DealDamage(client, RoundFloat(AdaptiveAgiDamage[skill_level]*W3GetBuffStackedFloat(client,fAbilityResistance)), owner, _, "adaptive_strike");
		}
	}
	if(IsValidEdict(entity))
	{
		float origin[3],ProjAngle[3],vBuffer[3];
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);
		GetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);
		GetAngleVectors(ProjAngle, vBuffer, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(vBuffer, 20.0);
		AddVectors(origin, vBuffer, origin);
		TeleportEntity(entity, origin,NULL_VECTOR,NULL_VECTOR);
		RequestFrame(fixPiercingVelocity,EntIndexToEntRef(entity))
	}

	return Plugin_Stop;
}
public void fixPiercingVelocity(entity)
{
	entity = EntRefToEntIndex(entity)
	if(IsValidEdict(entity))
	{
		float origin[3],ProjAngle[3],vBuffer[3],fVelocity[3],speed = 3000.0;
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);
		GetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);
		GetAngleVectors(ProjAngle, vBuffer, NULL_VECTOR, NULL_VECTOR);
		if(HasEntProp(entity, Prop_Send, "m_vInitialVelocity"))
		{
			GetEntPropVector(entity, Prop_Send, "m_vInitialVelocity", fVelocity);
			speed = GetVectorLength(fVelocity);
		}
		fVelocity[0] = vBuffer[0]*speed;
		fVelocity[1] = vBuffer[1]*speed;
		fVelocity[2] = vBuffer[2]*speed;
		TeleportEntity(entity, origin,NULL_VECTOR,fVelocity);
	}
}
public Action:doNextBash(Handle:timer, int client) 
{  
	if(ValidPlayer(client,true))
	{
		new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_ADAPTIVE);
		new Float:fwd[3],Float:fAngles[3],Float:fOrigin[3];
		GetClientEyeAngles(client, fAngles);
		GetClientEyePosition(client, fOrigin);
		GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(fwd, 200.0);
		AddVectors(fOrigin, fwd, fOrigin);
		War3_EmitSoundToAll(explSound,client);
		createExplosionEffect(fOrigin);
		
		for(new i = 1; i < MAXENTITIES; i++)
		{
			if(IsValidForDamage(i) && IsOnDifferentTeams(client,i))
			{
				new Float:targetvec[3];
				GetEntPropVector(i, Prop_Data, "m_vecOrigin", targetvec);
				if(GetVectorDistance(fOrigin, targetvec, true) <= 62500)
				{
					if(IsPointVisible(fOrigin,targetvec))
					{
						War3_DealDamage(i, RoundFloat(AdaptiveStrDamage[skill_level]*W3GetBuffStackedFloat(i,fAbilityResistance)), client, DMG_BLAST, "adaptive_strike", W3DMGORIGIN_SKILL, W3DMGTYPE_PHYSICAL);
					}
				}
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

stock CreateSpriteTrail(int iEntity, char[] lifetime, char[] startwidth, char[] endwidth, char[] spritename, char[] rendercolor)
{
	int spriteTrail = CreateEntityByName("env_spritetrail");
	if (IsValidEdict(spriteTrail))
	{
		SetEntPropFloat(spriteTrail, Prop_Send, "m_flTextureRes", 0.05);
		DispatchKeyValue(spriteTrail, "lifetime", lifetime );
		DispatchKeyValue(spriteTrail, "startwidth", startwidth );
		DispatchKeyValue(spriteTrail, "endwidth", endwidth );
		DispatchKeyValue(spriteTrail, "spritename", spritename);
		DispatchKeyValue(spriteTrail, "renderamt", "255" );
		DispatchKeyValue(spriteTrail, "rendercolor", rendercolor);
		DispatchKeyValue(spriteTrail, "rendermode", "5");
		DispatchSpawn(spriteTrail);
		AttachTrail(spriteTrail, iEntity);
	}
	return spriteTrail;
}
stock AttachTrail(ent, client)
{
	float m_fOrigin[3], m_fAngle[3];
	float m_fTemp[3] = {0.0, 90.0, 0.0};
	GetEntPropVector(client, Prop_Data, "m_angAbsRotation", m_fAngle);
	SetEntPropVector(client, Prop_Data, "m_angAbsRotation", m_fTemp);
	float m_fPosition[3];
	m_fPosition[0] = 0.0;
	m_fPosition[1] = 0.0;
	m_fPosition[2]= 0.0;
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", m_fOrigin);
	AddVectors(m_fOrigin, m_fPosition, m_fOrigin);
	TeleportEntity(ent, m_fOrigin, m_fTemp, NULL_VECTOR);
	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", client, ent);
	SetEntPropVector(client, Prop_Data, "m_angAbsRotation", m_fAngle);
}