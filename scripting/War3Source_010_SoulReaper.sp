#include <war3source>
#include <tf2utils>
#assert GGAMEMODE == MODE_WAR3SOURCE

#define RACE_ID_NUMBER 10

/**
 *
 * Description:   SR FROM HON
 * Author(s): Ownz (DarkEnergy) and pimpjuice
 */

//#pragma semicolon 1

//#include <sourcemod>
//#include "W3SIncs/War3Source_Interface"
//#include <sdktools>
//#include <sdktools_functions>
//#include <sdktools_tempents>
//#include <sdktools_tempents_stocks>
//#include <cstrike>

public W3ONLY(){} //unload this?
new thisRaceID;

new SKILL_JUDGE, SKILL_PRESENCE,SKILL_INHUMAN, ULT_EXECUTE;


// Chance/Data Arrays
new JudgementAmount[]={40,40,40,40,40};
float JudgementCooldownTime[]= {15.0, 14.0, 13.0, 12.0, 11.0};
new Float:JudgementRange=600.0;

new Float:PresenseAmount[]={5.0,5.2,5.4,5.6,5.8};
new Float:PresenceRange[]={305.0,320.0,340.0,360.0,380.0};

new InhumanAmount[]={20, 22, 25, 27, 30};
new Float:InhumanRange=1600.0;

new Float:ultRange=450.0;
new Float:ultCooldown[]={45.0,44.0,43.0,42.0,41.0};

new String:judgesnd[]="war3source/sr/judgement.mp3";
new String:ultsnd[]="war3source/SoulBurn1.mp3";
new String:ultsnd2[]="war3source/sr/ult.mp3";

new AuraID;

public Plugin:myinfo =
{
	name = "Race - Soul Reaper",
	author = "Ownz (DarkEnergy)",
	description = "Soul Reaper for War3Source.",
	version = "1.0",
	url = "War3Source.com"
};

ResetDecay()
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client))
		{
			War3_SetBuff(client,fHPDecay,thisRaceID,0.0);
		}
	}
}

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
//	if(RaceDisabled)
//		return;

public OnPluginStart()
{
	HookEvent("player_death",PlayerDeathEvent);

	//LoadTranslations("w3s.race.sr.phrases");
}
public OnAllPluginsLoaded()
{
	War3_RaceOnPluginStart("sr");
}

public OnPluginEnd()
{
	if(LibraryExists("RaceClass"))
		War3_RaceOnPluginEnd("sr");
}

public OnWar3LoadRaceOrItemOrdered2(num,reloadrace_id,String:shortname[])
{
	if(num==RACE_ID_NUMBER||(reloadrace_id>0&&StrEqual("sr",shortname,false)))
	{
		thisRaceID=War3_CreateNewRace("Soul Reaper","sr",reloadrace_id,"Execution, magic damage.");
		SKILL_JUDGE=War3_AddRaceSkill(thisRaceID,"Judgement","[+ability] Heals teammates around you, damages enemies around you.\nDamage/heals for 40, Cooldown is 15s and radius is 600HU.\nUpgrading decreases cooldown by -1s.",false,4,"(voice Help!)");
		SKILL_PRESENCE=War3_AddRaceSkill(thisRaceID,"Withering Presence","Enemies take non-lethal damage just by being within 200 to 380 HU of you.\nDeals 4 to 5.8 DPS.",false,4);
		SKILL_INHUMAN=War3_AddRaceSkill(thisRaceID,"Inhuman Nature","Heals for 20-30hp from anyone dying in a 800HU radius.\nAlso decreases the cooldown of abilities by -1s.",false,4);
		ULT_EXECUTE=War3_AddRaceSkill(thisRaceID,"Demonic Execution","(+ultimate)Deals 40 + 40% of targets lost health.\nCooldown is 45s. Each level red. CD by -1s.",true,4,"(voice Jeers)");
		War3_CreateRaceEnd(thisRaceID);
		AuraID=W3RegisterChangingDistanceAura("witheringpresense",true);

		// Possible replacement if needed?
		//War3_AddAuraSkillBuff(thisRaceID, SKILL_PRESENCE, fHPDecay, PresenseAmount,
		//					  "witheringpresense", PresenceRange,
		//					  true);
	}
}

public OnMapStart()
{
	PrecacheSound(judgesnd);
	PrecacheSound(ultsnd);
	PrecacheSound(ultsnd2);
}

public OnAddSound(sound_priority)
{
	if(sound_priority==PRIORITY_MEDIUM)
	{
		War3_AddSound(judgesnd);
		War3_AddSound(ultsnd);
		War3_AddSound(ultsnd2);
	}
}


public void OnAbilityCommand(int client, int ability, bool pressed, bool bypass)
{
	if(RaceDisabled)
		return;

	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_JUDGE);
		if(!Silenced(client)&&(bypass||War3_SkillNotInCooldown(client,thisRaceID,SKILL_JUDGE,true)))
		{
			new amount=JudgementAmount[skill_level];

			new Float:playerOrigin[3];
			GetClientAbsOrigin(client,playerOrigin);

			new team = GetClientTeam(client);
			new Float:otherVec[3];
			for(new i=1;i<=MaxClients;i++){
				if(ValidPlayer(i,true)){
					GetClientAbsOrigin(i,otherVec);
					if(GetVectorDistance(playerOrigin,otherVec)<JudgementRange)
					{
						if(GetClientTeam(i)==team){
							War3_HealToMaxHP(i,amount);
						}
						else{
							float resistance = W3GetBuffStackedFloat(i, fAbilityResistance);
							if(War3_DealDamage(i,RoundFloat(resistance*amount),client,DMG_BURN,"judgement",W3DMGORIGIN_SKILL))
							{
								War3_NotifyPlayerTookDamageFromSkill(i, client, War3_GetWar3DamageDealt(), SKILL_JUDGE);
							}
							else
							{
								War3_NotifyPlayerImmuneFromSkill(client, i, SKILL_JUDGE);
							}
						}

					}
				}
			}
			PrintHintText(client,"+/- %d HP",amount);
			War3_EmitSoundToAll(judgesnd,client);
			War3_EmitSoundToAll(judgesnd,client);
			War3_CooldownMGR(client,JudgementCooldownTime[skill_level],thisRaceID,SKILL_JUDGE,true,true);

			if(War3_SkillNotInCooldown(client, thisRaceID, ULT_EXECUTE))
				War3_CooldownMGR(client,2.0,thisRaceID,ULT_EXECUTE,true,true);
			else
				War3_CooldownMGR(client,2.0,thisRaceID,ULT_EXECUTE,true,false,true);
		}
	}
}


public void OnUltimateCommand(int client, int race, bool pressed, bool bypass)
{
	if(RaceDisabled)
		return;

	if(race==thisRaceID && pressed && IsPlayerAlive(client))
	{
		//if(

		new skill=War3_GetSkillLevel(client,race,ULT_EXECUTE);
		if(!Silenced(client)&&(bypass||War3_SkillNotInCooldown(client,thisRaceID,ULT_EXECUTE,true)))
		{
			bool foundTarget;
			for(int target = 1; target <= MaxClients; ++target){
				if(ValidPlayer(target,true))
				{
					if(!IsOnDifferentTeams(client, target))
						continue;

					if(GetPlayerDistance(client, target) <= ultRange){
						if(!W3HasImmunity(target,Immunity_Ultimates))
						{
							new dmg=RoundFloat( (40.0 + 0.4 * (TF2Util_GetEntityMaxHealth(target) - GetClientHealth(target))) * W3GetBuffStackedFloat(target, fUltimateResistance));

							if(dmg >= 0 && War3_DealDamage(target,dmg,client,_,"demonicexecution"))
							{
								PrintHintText(client,"Dealt %i damage with demonic execution!", War3_GetWar3DamageDealt());
								War3_NotifyPlayerTookDamageFromSkill(target, client, War3_GetWar3DamageDealt(), ULT_EXECUTE);
								foundTarget = true;
							}
						}
						else
						{
							War3_NotifyPlayerImmuneFromSkill(client, target, ULT_EXECUTE);
						}
					}
				}
			}

			if(foundTarget){
				War3_CooldownMGR(client,ultCooldown[skill],thisRaceID,ULT_EXECUTE,true,true);
				War3_EmitSoundToAll(ultsnd,client);
				War3_EmitSoundToAll(ultsnd,client);
				War3_EmitSoundToAll(ultsnd2,client);

				if(War3_SkillNotInCooldown(client, thisRaceID, SKILL_JUDGE))
					War3_CooldownMGR(client,2.0,thisRaceID,SKILL_JUDGE,true,true);
				else
					War3_CooldownMGR(client,2.0,thisRaceID,SKILL_JUDGE,true,false,true);
			}else{
				W3MsgNoTargetFound(client,ultRange);
			}
		}
	}
}



CheckAura(client){
	new level=War3_GetSkillLevel(client,thisRaceID,SKILL_PRESENCE);
	W3SetPlayerAura(AuraID,client,PresenceRange[level],level);
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace==thisRaceID)
	{
		InitPassiveSkills(client);
	}
	else //if(oldrace==thisRaceID)
	{
		RemovePassiveSkills(client);
	}
}

public InitPassiveSkills(client)
{
	// Natural Armor Buff
	//War3_SetBuff(client,fArmorPhysical,thisRaceID,3.0);
	CheckAura(client);
	War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,30);
}

public RemovePassiveSkills(client)
{
	//War3_SetBuff(client,fArmorPhysical,thisRaceID,0.0);
	ResetDecay();
	W3RemovePlayerAura(AuraID,client);
	War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,0);
}

public void OnSkillLevelChanged(int client, int currentrace, int skill, int newskilllevel, int oldskilllevel)
{
	if(RaceDisabled)
		return;

	if(currentrace==thisRaceID)
	{
		if(skill==SKILL_PRESENCE) //1
		{
			W3RemovePlayerAura(AuraID,client);
			W3SetPlayerAura(AuraID,client,PresenceRange[newskilllevel],newskilllevel);
		}
	}
}

public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(RaceDisabled)
		return;

	new userid=GetEventInt(event,"userid");
	new victim=GetClientOfUserId(userid);

	if(victim>0)
	{
		new Float:deathvec[3];
		GetClientAbsOrigin(victim,deathvec);

		new Float:gainhpvec[3];

		for(new client=1;client<=MaxClients;client++)
		{
			if(ValidPlayer(client,true)&&War3_GetRace(client)==thisRaceID){
				GetClientAbsOrigin(client,gainhpvec);
				if(GetVectorDistance(deathvec,gainhpvec)<InhumanRange){
					new skilllevel=War3_GetSkillLevel(client,thisRaceID,SKILL_INHUMAN);
					if(!Hexed(client)){
						War3_HealToMaxHP(client,InhumanAmount[skilllevel]);
						War3_CooldownMGR(client,-1.0, thisRaceID, SKILL_JUDGE,_,_,true);
						War3_CooldownMGR(client,-1.0, thisRaceID, ULT_EXECUTE,_,_,true);
					}
				}
			}
		}
		//new deathFlags = GetEventInt(event, "death_flags");
	// where is the list of flags? idksee firefox
		//if (deathFlags & 32)
		//{
		   //PrintToChat(client,"war3 debug: dead ringer kill");
		//}


	}
}

public OnW3PlayerAuraStateChanged(client,aura,bool:inAura,level,AuraStack,AuraOwner)
{
	if(RaceDisabled)
		return;

	if(aura==AuraID)
	{
		/*
		if(inAura)
		{
			new String:StrOwner[128];
			GetClientName(AuraOwner,StrOwner,sizeof(StrOwner));
			new String:Strclient[128];
			GetClientName(client,Strclient,sizeof(Strclient));
			DP("Client %s is in Aura - true - Aura Owner %s",Strclient,StrOwner);
		}
		else
		{
			new String:StrOwner[128];
			GetClientName(AuraOwner,StrOwner,sizeof(StrOwner));
			new String:Strclient[128];
			GetClientName(client,Strclient,sizeof(Strclient));
			DP("Client %s is Not in Aura - false - Aura Owner %s",Strclient,StrOwner);
		}*/
		if(AuraStack>0 && inAura && !IsInvis(AuraOwner))
		{
			if(!W3HasImmunity(client,Immunity_Skills))
			{
				new Float:StackBuff=(float(AuraStack) * PresenseAmount[level] * W3GetBuffStackedFloat(client, fAbilityResistance));
				War3_SetBuff(client,fHPDecay,thisRaceID,StackBuff,AuraOwner);
				//PrintToChatAll("DecayOn");
			}
			else
			{
				War3_SetBuff(client,fHPDecay,thisRaceID,0.0);
				War3_NotifyPlayerImmuneFromSkill(AuraOwner, client, SKILL_PRESENCE);
				//PrintToChatAll("DecayOff");
			}
		}
		else
		{
			War3_SetBuff(client,fHPDecay,thisRaceID,0.0);
			//PrintToChatAll("DecayOff");
		}
	}
}
