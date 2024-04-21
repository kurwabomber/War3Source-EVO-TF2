#include <war3source>
#include <tf2attributes>
#include <sdkhooks>
#include <sdktools>
#assert GGAMEMODE == MODE_WAR3SOURCE

#define RACE_ID_NUMBER 35
#define raceshortname "guardian"
#define racelongname "Guardian"
#define racedescription "Tank Race"

public Plugin:myinfo =
{
	name = "Race - Guardian",
	author = "Razor",
	description = "Guardian race for War3Source.",
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

new SKILL_FIRST, SKILL_SECOND, SKILL_THIRD, ULT;

//Juggernaut
new Float:JuggernautHPR[]={6.0,6.5,7.0,7.5,8.0};
new JuggernautHP[]={50,55,60,65,70};
new Float:JuggernautMovespeed[]={0.6,0.6,0.6,0.6,0.6};
new Float:JuggernautArmor[]={8.0,8.0,8.0,8.0,8.0};
new Float:JuggernautDamage[]={0.15,0.15,0.15,0.15,0.15};
//Cleansing Flame
new Float:CleasningFlameDamage[]={80.0,85.0,85.0,85.0,85.0};
new Float:CleansingFlameCooldown[]={25.0,25.0,22.5,20.0,18.5};
new BeamSprite,HaloSprite;

//Chokeslam
new Float:ChokeslamDamage[]={75.0,80.0,85.0,90.0,95.0};

//Steadfast Corruption
new Float:SteadfastCorruptionDamage[]={130.0,135.0,140.0,145.0,160.0};
new String:explSound[]="weapons/air_burster_explode1.wav";
new String:rocketsound[]="items/cart_explode.wav";

public OnWar3LoadRaceOrItemOrdered2(num,reloadrace_id,String:shortname[])
{
	if(num==RACE_ID_NUMBER||(reloadrace_id>0&&StrEqual(raceshortname,shortname,false)))
	{
		thisRaceID=War3_CreateNewRace(racelongname,raceshortname,reloadrace_id,racedescription);
		SKILL_FIRST=War3_AddRaceSkill(thisRaceID,"Juggernaut","+8 armor. Deal 15% more damage.\n+6 to 8 HPR, +50-70 MaxHP. -40% movespeed. (passive)",false,4);
		SKILL_SECOND=War3_AddRaceSkill(thisRaceID,"Cleansing Flame","Within a 500HU radius, deal 80 to 85 damage.\n25s to 18.5s cooldown. Using this also adds cooldown to other abilities. (+ability)",false,4);
		SKILL_THIRD=War3_AddRaceSkill(thisRaceID,"Chokeslam","Grab a nearby enemy, dealing 75 -> 95 dmg. Stuns for 1.5s.\n30s cooldown.  Using this also adds cooldown to other abilities. (+ability2)",false,4);
		ULT=War3_AddRaceSkill(thisRaceID,"Steadfast Corruption","Creates a shockwave arc with 550HU length.\nCast time is 2.5s. Deals 130 -> 160 dmg.\n45s cooldown. (+ultimate)",true,4);
		War3_CreateRaceEnd(thisRaceID);
		War3_AddSkillBuff(thisRaceID, SKILL_FIRST, fHPRegen, JuggernautHPR);
		War3_AddSkillBuff(thisRaceID, SKILL_FIRST, iAdditionalMaxHealth, JuggernautHP);
		War3_AddSkillBuff(thisRaceID, SKILL_FIRST, fSlow, JuggernautMovespeed);
		War3_AddSkillBuff(thisRaceID, SKILL_FIRST, fArmorPhysical, JuggernautArmor);
		War3_AddSkillBuff(thisRaceID, SKILL_FIRST, fArmorMagic, JuggernautArmor);
		War3_AddSkillBuff(thisRaceID, SKILL_FIRST, fDamageModifier, JuggernautDamage);
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
				War3_ChatMessage(client, "The claws interfere with your armor.");
			}
			if((W3GetVar(EventArg1) == War3_GetItemIdByShortname("gauntlet")))
			{
				W3Deny();
				War3_ChatMessage(client, "The gauntlets interfere with your armor.");
			}
			if((W3GetVar(EventArg1) == War3_GetItemIdByShortname("ring")))
			{
				W3Deny();
				War3_ChatMessage(client, "The ring interfere with your armor.");
			}
			if((W3GetVar(EventArg1) == War3_GetItemIdByShortname("courage")))
			{
				W3Deny();
				War3_ChatMessage(client, "You already have armor.");
			}
			if((W3GetVar(EventArg1) == War3_GetItemIdByShortname("cuirass")))
			{
				W3Deny();
				War3_ChatMessage(client, "You already have armor.");
			}
			if((W3GetVar(EventArg1) == War3_GetItemIdByShortname("blademail")))
			{
				W3Deny();
				War3_ChatMessage(client, "You already have armor.");
			}
		}
	}
}
public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,0);
		War3_SetBuff(client,fHPRegen,thisRaceID,0.0);
		War3_SetBuff(client,fSlow,thisRaceID,1.0);
		War3_SetBuff(client,fArmorPhysical,thisRaceID,0.0);
		War3_SetBuff(client,fArmorMagic,thisRaceID,0.0);
		War3_SetBuff(client,fDamageModifier,thisRaceID,0.0);
	}
}
public OnMapStart()
{
	UnLoad_Hooks();
	PrecacheSound(explSound);
	PrecacheSound(rocketsound);
	BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();
}
public OnAllPluginsLoaded()
{
	War3_RaceOnPluginStart(raceshortname);
}

public OnPluginEnd()
{
	if(LibraryExists("RaceClass"))
		War3_RaceOnPluginEnd(raceshortname);
}
public void OnAbilityCommand(int client, int ability, bool pressed, bool bypass)
{
	if(RaceDisabled)
		return;

	if(War3_GetRace(client)==thisRaceID && pressed && IsPlayerAlive(client))
	{
		switch(ability)
		{
			case 0:
			{
				new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_SECOND);
				if(!Silenced(client)&&(bypass||War3_SkillNotInCooldown(client,thisRaceID,SKILL_SECOND,true)))
				{
					War3_EmitSoundToAll(explSound,client);
					new Float:FrostNovaOrigin[3];
					GetClientAbsOrigin(client,FrostNovaOrigin);
					FrostNovaOrigin[2]+=15.0;

					TE_SetupBeamRingPoint(FrostNovaOrigin, 1.0, 650.0, BeamSprite, HaloSprite, 0, 5, 1.0, 50.0, 1.0, {255,0,0,255}, 50, 0);
					TE_SendToAll();
					
					new Float:otherVec[3];
					new team = GetClientTeam(client);
					for(new i=1;i<=MaxClients;i++)
					{
						if(ValidPlayer(i,true)&&GetClientTeam(i)!=team)
						{
							GetClientAbsOrigin(i,otherVec);
							new Float:victimdistance=GetVectorDistance(FrostNovaOrigin,otherVec);
							if(victimdistance<500.0&&FloatAbs(otherVec[2]-FrostNovaOrigin[2])<50)
							{
								if(!W3HasImmunity(i,Immunity_Skills))
								{
									if(War3_DealDamage(i, RoundToNearest(CleasningFlameDamage[skill_level]*W3GetBuffStackedFloat(i, fAbilityResistance)), client, DMG_BURN, "cleansingflame"))
									{
										War3_NotifyPlayerTookDamageFromSkill(client, i, War3_GetWar3DamageDealt(), SKILL_SECOND);
										PrintHintText(i,"You were hit by cleansing flames!");
									}
								}
								else
								{
									War3_NotifyPlayerImmuneFromSkill(client, i, SKILL_SECOND);
								}
							}
						}
					}
					War3_CooldownMGR(client,CleansingFlameCooldown[skill_level],thisRaceID,SKILL_SECOND,_,_);
					if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_THIRD,true))
					{
						War3_CooldownMGR(client,4.0,thisRaceID,SKILL_THIRD,_,_);
					}
					if(War3_SkillNotInCooldown(client,thisRaceID,ULT,true))
					{
						War3_CooldownMGR(client,4.0,thisRaceID,ULT,_,_);
					}
					PrintHintText(client,"Cleansing Flame Casted!");
				}
			}
			case 2:
			{
				new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_THIRD);
				if(!Silenced(client)&&(bypass||War3_SkillNotInCooldown(client,thisRaceID,SKILL_THIRD,true)))
				{
					new Float:vOrigin[3];
					GetClientAbsOrigin(client,vOrigin);
					new Float:otherVec[3];
					new team = GetClientTeam(client);
					bool successful;
					for(new i=1;i<=MaxClients;i++)
					{
						if(ValidPlayer(i,true)&&GetClientTeam(i)!=team)
						{
							GetClientAbsOrigin(i,otherVec);
							new Float:victimdistance=GetVectorDistance(vOrigin,otherVec);
							if(victimdistance<=120.0)
							{
								if(!W3HasImmunity(i,Immunity_Skills))
								{
									if(War3_DealDamage(i, RoundToNearest(ChokeslamDamage[skill_level]*W3GetBuffStackedFloat(i, fAbilityResistance)), client, DMG_CLUB, "chokeslam"))
									{
										War3_NotifyPlayerTookDamageFromSkill(client, i, War3_GetWar3DamageDealt(), SKILL_THIRD);
										TF2_StunPlayer(i, 1.5, 1.0, TF_STUNFLAGS_NORMALBONK, client);
										PrintHintText(i,"You were grabbed by %N!",client);
										PrintHintText(client,"You grabbed %N!",i);
										
										War3_CooldownMGR(client,30.0,thisRaceID,SKILL_THIRD,_,_);
										if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_SECOND,true))
										{
											War3_CooldownMGR(client,4.0,thisRaceID,SKILL_SECOND,_,_);
										}
										if(War3_SkillNotInCooldown(client,thisRaceID,ULT,true))
										{
											War3_CooldownMGR(client,4.0,thisRaceID,ULT,_,_);
										}
										successful = true;
										break;
									}
								}
								else
								{
									War3_NotifyPlayerImmuneFromSkill(client, i, SKILL_THIRD);
								}
							}
						}
					}
					if(!successful){
						PrintHintText(client, "Did not find any valid targets for chokeslam.");
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
		if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT,true ))
		{
			War3_CastSpell(client, 0, SpellEffectsLight, SPELLCOLOR_GREEN, thisRaceID, ULT, 2.5);
			War3_CooldownMGR(client,45.0,thisRaceID,ULT,_,_);
			
			War3_EmitSoundToAll(explSound,client);
		}
	}
}
public OnWar3CastingFinished(client, target, W3SpellEffects:spelleffect, String:SpellColor[], raceid, skillid)
{
	//DP("casting finished");
	if(ValidPlayer(client,true) && raceid==thisRaceID)
	{
		if(skillid == ULT)
		{
			new skill_level=War3_GetSkillLevel(client,raceid,ULT);
			War3_EmitSoundToAll(explSound,client);
			War3_EmitSoundToAll(rocketsound,client);
			War3_NotifyPlayerSkillActivated(client,ULT,true);
			War3_CooldownMGR(client,45.0,thisRaceID,ULT);
			
			for(new i=1; i<=MaxClients; i++)
			{
				if(ValidPlayer(i,true) && IsPlayerAlive(i) && GetClientTeam(i) != GetClientTeam(client))
				{	
					if(IsTargetInSightRange(client, i, 90.0, 550.0, true, false))
					{
						if(IsAbleToSee(client,i) == true)
						{
							if(!W3HasImmunity(i,Immunity_Ultimates))
							{
								if(War3_DealDamage(i, RoundToNearest(SteadfastCorruptionDamage[skill_level]*W3GetBuffStackedFloat(i, fUltimateResistance)), client, DMG_BURN, "corruption"))
								{
									War3_NotifyPlayerTookDamageFromSkill(client, i, War3_GetWar3DamageDealt(), ULT);
								}
							}
						}
					}
				}
			}
		}
	}
}
