// War3Source_018_Scout.sp

#include <war3source>
#assert GGAMEMODE == MODE_WAR3SOURCE
#assert GGAMETYPE_JAILBREAK == JAILBREAK_OFF

#define RACE_ID_NUMBER 18

/**
* File: War3Source_NightElf.sp
* Description: The Night Elf race for War3Source.
* Author(s): Anthony Iacono
*/

//#pragma semicolon 1

//#include <sourcemod>
//#include "W3SIncs/War3Source_Interface"
//#include <sdktools>

new thisRaceID;
bool HooksLoaded = false;
public void Load_Hooks()
{
	if(HooksLoaded) return;
	HooksLoaded = true;

	W3Hook(W3Hook_OnW3TakeDmgBulletPre, OnW3TakeDmgBulletPre);
	W3Hook(W3Hook_OnW3TakeDmgAll, OnW3TakeDmgAll);
	W3Hook(W3Hook_OnWar3EventPostHurt, OnWar3EventPostHurt);
	W3Hook(W3Hook_OnWar3EventSpawn, OnWar3EventSpawn);
}
public void UnLoad_Hooks()
{
	if(!HooksLoaded) return;
	HooksLoaded = false;

	W3Unhook(W3Hook_OnW3TakeDmgBulletPre, OnW3TakeDmgBulletPre);
	W3Unhook(W3Hook_OnW3TakeDmgAll, OnW3TakeDmgAll);
	W3Unhook(W3Hook_OnWar3EventPostHurt, OnWar3EventPostHurt);
	W3Unhook(W3Hook_OnWar3EventSpawn, OnWar3EventSpawn);
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
//new SKILL_INVIS, SKILL_TRUESIGHT, SKILL_DISARM, ULT_MARKSMAN, SKILL_FADE,SKILL_IMPROVED_INVIS;
int SKILL_FADE, SKILL_TRUESIGHT, SKILL_DISARM, ULT_MARKSMAN;

// Chance/Data Arrays
//new Float:InvisDrain=0.05; //as a percent of your health
//new Float:InvisDuration[9]={0.0,6.0,7.0,8.0,9.0,9.5,10.0,10.5,11.0};
//new Handle:InvisEndTimer[MAXPLAYERSCUSTOM];
new bool:InInvis[MAXPLAYERSCUSTOM];

// SKILL FADE
new bool:InFade[MAXPLAYERSCUSTOM];
//new Handle:EndFadeTimer[MAXPLAYERSCUSTOM];
new Float:FadeCoolDown[]={4.0,4.0,3.0,2.0,1.0};
new FadeDurationREQ[]={4,4,3,3,3};

new Float:EyeRadius[]={800.0,900.0,1000.0,1100.0,1200.0};

new Float:DisarmChance[]={0.15,0.16,0.17,0.18,0.19};
new Float:DisarmSeconds[]={1.0,1.05,1.1,1.15,1.2};

new Float:MarksmanCrit[]={0.4,0.425,0.45,0.475,0.5};


new bool:bDisarmed[MAXPLAYERSCUSTOM];
new Float:lastvec[MAXPLAYERSCUSTOM][3];
new standStillCount[MAXPLAYERSCUSTOM];

// Effects
//new BeamSprite,HaloSprite;

const float immunityRevealRadius = 600.0;

new AuraID;

public Plugin:myinfo =
{
	name = "Race - Scout",
	author = "Ownz",
	description = "The Night Elf race for War3Source.",
	version = "1.0.0.0",
	url = "http://pimpinjuice.net/"
};

public OnPluginStart()
{


	//UltCooldownCvar=CreateConVar("war3_scout_ult_cooldown","20","Cooldown timer.");

	//LoadTranslations("w3s.race.scout_o.phrases");
	CreateTimer(1.0,DeciSecondTimer,_,TIMER_REPEAT);

	AddCommandListener(Taunt, "+taunt");

	for(new i = 1; i <= MaxClients; i++)
	{
		if(ValidPlayer(i))
		{
			SDKHook(i, SDKHook_SetTransmit, SDK_FORWARD_TRANSMIT);
		}
	}
}
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_SetTransmit, SDK_FORWARD_TRANSMIT);
}

public OnAllPluginsLoaded()
{
	War3_RaceOnPluginStart("scout_o");
}

public OnPluginEnd()
{
	if(LibraryExists("RaceClass"))
		War3_RaceOnPluginEnd("scout_o");
	for(new i = 1; i <= MaxClients; i++)
	{
		if(ValidPlayer(i))
		{
			SDKUnhook(i, SDKHook_SetTransmit, SDK_FORWARD_TRANSMIT);
		}
	}
}

public OnMapStart()
{
	UnLoad_Hooks();
	//BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	//HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");

}

public OnWar3LoadRaceOrItemOrdered2(num,reloadrace_id,String:shortname[])
{
	if(num==RACE_ID_NUMBER||(reloadrace_id>0&&StrEqual("scout_o",shortname,false)))
	{
		thisRaceID=War3_CreateNewRace("Scout","scout_o",reloadrace_id,"Sniper styled race");
		SKILL_TRUESIGHT=War3_AddRaceSkill(thisRaceID,"TrueSight","Enemies cannot be invisible or partially invisible around you. \n800-1100 units.\nDoes not affect spy cloak",false,4);
		SKILL_FADE=War3_AddRaceSkill(thisRaceID,"Blink","If standing still for 4 to 3 seconds, you go completely invisible.\nAny movement or damage (to or from you) makes you visible.",false,4);
		SKILL_DISARM=War3_AddRaceSkill(thisRaceID,"Disarm","15 to 19% chance to disarm the enemy on hit\n1 to 1.2 seconds to disarm victim.\nHas a cooldown of 8s.",false,4,"(Autocast)");
		ULT_MARKSMAN=War3_AddRaceSkill(thisRaceID,"Marksman","You deal up to 1.4-1.5x damage based on distance to target.\n1400 units or more deals maximum damage",true,4);
		War3_CreateRaceEnd(thisRaceID);

		AuraID =W3RegisterChangingDistanceAura("scout_reveal",true);
	}
}

public OnW3Denyable(W3DENY:event,client)
{
	if(RaceDisabled)
		return;

	if((event == DN_CanBuyItem1) && (W3GetVar(EventArg1) == War3_GetItemIdByShortname("ring")))
	{
		if(War3_GetRace(client)==thisRaceID)
		{
			W3Deny();
			War3_ChatMessage(client, "What?!  Not on my trigger finger!");
		}
	}
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
	//War3_SetBuff(client,fArmorMagic,thisRaceID,3.0);
	new level=War3_GetSkillLevel(client,thisRaceID,SKILL_TRUESIGHT);
	W3SetPlayerAura(AuraID,client,EyeRadius[level],level);
}

public RemovePassiveSkills(client)
{
	//War3_SetBuff(client,fArmorPhysical,thisRaceID,0.0);
	//War3_SetBuff(client,fArmorMagic,thisRaceID,0.0);
	W3ResetAllBuffRace(client, thisRaceID);
	W3RemovePlayerAura(AuraID,client);
	War3_SetBuff(client,bNoMoveMode,thisRaceID,false);
	EndFade(client);
}


public void OnSkillLevelChanged(int client, int currentrace, int skill, int newskilllevel, int oldskilllevel)
{
	if(RaceDisabled)
		return;

	if(currentrace==thisRaceID)
	{
		if(skill==SKILL_TRUESIGHT) //1
		{
			W3RemovePlayerAura(AuraID,client);
			W3SetPlayerAura(AuraID,client,EyeRadius[newskilllevel],newskilllevel);
		}
	}
}

public void OnWar3EventSpawn (int client)
{
	if(bDisarmed[client]){
		EndInvis2(INVALID_HANDLE,client);
	}
	if(InInvis[client]||InFade[client]){
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
#if GGAMETYPE == GGAME_TF2
		TF2_RemoveCondition(client, TFCond_Stealthed);
		//SetVariantInt(0);
		if (AcceptEntityInput(client, "EnableShadow"))
		{
			//War3_ChatMessage(client,"{blue}Shadows Enabled");
		}
#endif
		War3_SetBuff(client,fHPDecay,thisRaceID,0.0);
		InInvis[client]=false;
		InFade[client]=false;
	}
}
public OnWar3EventDeath(victim,attacker){
	if(RaceDisabled)
		return;
	if(War3_GetRace(victim)==thisRaceID)
	{
		War3_SetBuff(victim,bNoMoveMode,thisRaceID,false);
	}
}
public EndFade(client)
{
	if(ValidPlayer(client) && InFade[client])
	{
		InFade[client]=false;

		if(W3GetBuff(client,bNoMoveMode,thisRaceID))
		{
			PrintHintText(client,"OUTPOST OFF");
			War3_SetBuff(client,bNoMoveMode,thisRaceID,false);
		}

#if (GGAMETYPE == GGAME_CSS || GGAMETYPE == GGAME_CSGO)
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
#elseif GGAMETYPE == GGAME_TF2
		TF2_RemoveCondition(client, TFCond_Stealthed);
		//SetVariantInt(0);
		if (AcceptEntityInput(client, "EnableShadow"))
		{
			//War3_ChatMessage(client,"{blue}Shadows Enabled");
		}
#endif
		PrintHintText(client,"You Blink into the Light!");
		new skilllvl = War3_GetSkillLevel(client,thisRaceID,SKILL_FADE);
		War3_CooldownMGR(client,FadeCoolDown[skilllvl],thisRaceID,SKILL_FADE);
	}

}
public Action:EndInvis(Handle:timer,any:client)
{
	InInvis[client]=false;
	if(!InFade[client])
	{
#if (GGAMETYPE == GGAME_CSS || GGAMETYPE == GGAME_CSGO)
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
#elseif GGAMETYPE == GGAME_TF2
		TF2_RemoveCondition(client, TFCond_Stealthed);
		//SetVariantInt(0);
		if (AcceptEntityInput(client, "EnableShadow"))
		{
			//War3_ChatMessage(client,"{blue}Shadows Enabled");
		}
#endif
	}
	//War3_SetBuff(client,fHPDecay,thisRaceID,0.0);
	// Got an Error in the logs, so added ValidPlayer for checking.
	if (ValidPlayer(client))
		CreateTimer(1.0,EndInvis2,client);
	PrintHintText(client,"No Longer Invis! Cannot shoot for 1 sec!");
}
public Action:EndInvis2(Handle:timer,any:client){
	War3_SetBuff(client,bDisarm,thisRaceID,false);
	bDisarmed[client]=false;
	//SetVariantInt(0);
	if (AcceptEntityInput(client, "EnableShadow"))
	{
		//War3_ChatMessage(client,"{blue}Shadows Enabled");
	}
}

public Action OnW3TakeDmgAll(int victim,int attacker, float damage)
{
	if(RaceDisabled)
		return Plugin_Continue;

	if(ValidPlayer(victim)&&ValidPlayer(attacker))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			if(InFade[attacker]){ //stood still for 10 second
			if(ValidPlayer(attacker))
				EndFade(attacker);
			}
		}
		else
		if(War3_GetRace(victim)==thisRaceID)
		{
			if(InFade[victim]){ //stood still for 10 second
			if(ValidPlayer(victim))
				EndFade(victim);
			}
		}
	}
	return Plugin_Continue;
}

public Action OnW3TakeDmgBulletPre(int victim, int attacker, float damage, int damagecustom)
{
	if(RaceDisabled)
		return Plugin_Continue;

	if(ValidPlayer(attacker,true) && ValidPlayer(victim,true))
	{
		if(GetClientTeam(victim)==GetClientTeam(attacker) || W3HasImmunity(victim,Immunity_Ultimates))
		{
			return Plugin_Continue;
		}
	}
	if(IsValidEntity(victim)&&ValidPlayer(attacker,false))
	{
		if(War3_GetRace(attacker)==thisRaceID){
			new lvl=War3_GetSkillLevel(attacker,thisRaceID,ULT_MARKSMAN);
			new Float:vicpos[3];
			new Float:attpos[3];
			GetEntPropVector(victim, Prop_Send, "m_vecOrigin", vicpos);
			GetClientAbsOrigin(attacker,attpos);
			new Float:distance=GetVectorDistance(vicpos,attpos);

			if(distance>1400.0)
				distance=1400.0;
			
			new Float:multi=1.0 + (distance*MarksmanCrit[lvl]/1400.0*W3GetBuffStackedFloat(victim,fUltimateResistance));
			War3_DamageModPercent(multi);
			PrintToConsole(attacker,"[War3Source:EVO] %.2fX dmg by marksman shot",multi);
		}
	}
	return Plugin_Changed;
}


public Action OnWar3EventPostHurt(int victim, int attacker, float dmgamount, char weapon[32], bool isWarcraft, const float damageForce[3], const float damagePosition[3])
{
	if(RaceDisabled)
		return Plugin_Continue;

	if(W3GetDamageIsBullet()&&ValidPlayer(victim,true)&&ValidPlayer(attacker,true)&&GetClientTeam(victim)!=GetClientTeam(attacker))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			new skill_level=War3_GetSkillLevel(attacker,thisRaceID,SKILL_DISARM);
			if(!Hexed(attacker,false))
			{
				if(!bDisarmed[victim]){
					if(War3_SkillNotInCooldown(attacker, thisRaceID, SKILL_DISARM) && W3Chance(DisarmChance[skill_level]*W3ChanceModifier(attacker))){
						if(!W3HasImmunity(victim,Immunity_Skills))
						{
							War3_SetBuff(victim,bDisarm,thisRaceID,true);
							CreateTimer(DisarmSeconds[skill_level],Undisarm,victim);
							War3_CooldownMGR(attacker, 8.0, thisRaceID, SKILL_DISARM);
						}
						else
						{
							War3_NotifyPlayerImmuneFromSkill(attacker, victim, SKILL_DISARM);
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}
public Action:Undisarm(Handle:t,any:client){
	War3_SetBuff(client,bDisarm,thisRaceID,false);
}


public Action:DeciSecondTimer(Handle:t){
	if(RaceDisabled)
		return;

	for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client,true,true)&&War3_GetRace(client)==thisRaceID)
		{
			static Float:vec[3];
			GetClientAbsOrigin(client,vec);
			if(GetVectorDistance(vec,lastvec[client])>5.0)
			{
				standStillCount[client]=0;
				if(ValidPlayer(client) && InFade[client])
				{
					EndFade(client);
					//DP("TRIGGER END FADE");
				}
			}
			else
			{
				standStillCount[client]++;
				/*
				FIXES  THE PROBLEM WHEN YOU SHOOT AND BECOME VISIBLE FOR A SECOND
				if(InFade[client])
					standStillCount[client]=10;
				*/
				new skilllvl = War3_GetSkillLevel(client,thisRaceID,SKILL_FADE);
				if(InFade[client])
					standStillCount[client]=FadeDurationREQ[skilllvl];
				//if(InFade[client] && standStillCount[client]>600)
					//standStillCount[client]=600;
			}
			lastvec[client][0]=vec[0];
			lastvec[client][1]=vec[1];
			lastvec[client][2]=vec[2];
		}
		//PrintToChatAll("stand still client %i count %i",client,standStillCount[client]);
		if(ValidPlayer(client,true)&&War3_GetRace(client)==thisRaceID&&!TF2_IsPlayerInCondition(client, TFCond_Stealthed))
		{
			new skilllvl = War3_GetSkillLevel(client,thisRaceID,SKILL_FADE);
			if(standStillCount[client]>=FadeDurationREQ[skilllvl] && War3_SkillNotInCooldown(client,thisRaceID,SKILL_FADE,true))
			{
				//FADE
				if(!InFade[client])
				{
					InFade[client]=true;
					//EndFadeTimer[client]=CreateTimer(FadeDurationT[skilllvl],EndFade,client);
					/*
					//FIXES  THE PROBLEM WHEN YOU SHOOT AND BECOME VISIBLE FOR A SECOND
					standStillCount[client]=10;
					*/
					//if(InFade[client] && standStillCount[client]>600)
						//standStillCount[client]=600;

#if (GGAMETYPE == GGAME_CSS || GGAMETYPE == GGAME_CSGO)
					War3_SetBuff(client,fInvisibilitySkill,thisRaceID,0.01);
#elseif GGAMETYPE == GGAME_TF2
					TF2_AddCondition(client, TFCond_Stealthed,2400.0);
					//SetVariantInt(1);
					if (AcceptEntityInput(client, "DisableShadow"))
					{
						//War3_ChatMessage(client,"{blue}Shadows Disabled");
					}
#endif
					W3Hint(client,HINT_SKILL_STATUS,5.0,"You Blink into darkness..");
				}
			}
		}
	}
}

public OnW3PlayerAuraStateChanged(client,tAuraID,bool:inAura,level,AuraStack,AuraOwner){
	if(RaceDisabled)
		return;

	if(tAuraID==AuraID)
	{
		//DP(inAura?"in aura":"not in aura");
		//new String:StrOwner[128];
		//GetClientName(AuraOwner,StrOwner,sizeof(StrOwner));
		//DP("Scout Aura Owner %s",StrOwner);
		if(!W3HasImmunity(client,Immunity_Skills))
		{
			if(AuraStack>0)
			{
				War3_SetBuff(client,bInvisibilityDenyAll,thisRaceID,true,AuraOwner);
			}
			else
			{
				War3_SetBuff(client,bInvisibilityDenyAll,thisRaceID,false);
			}
#if GGAMETYPE == GGAME_TF2
			if(ValidPlayer(client,true))
			{
				TF2_RemoveCondition(client, TFCond_Stealthed);
			}
#endif
		}
		else
		{
			War3_SetBuff(client,bInvisibilityDenyAll,thisRaceID,false);
			War3_NotifyPlayerImmuneFromSkill(AuraOwner, client, SKILL_TRUESIGHT);
		}
		float resistance = W3GetBuffStackedFloat(client, fAbilityResistance)
		if(resistance < 1.0)
		{
			if(GetPlayerDistance(client, AuraOwner) <= 500.0*(1-resistance)){
				if(ValidPlayer(AuraOwner,true))
				{
					TF2_RemoveCondition(AuraOwner, TFCond_Stealthed);
				}
			}
		}
	}

}

#if GGAMETYPE == GGAME_TF2
public TF2_OnConditionRemoved(client, TFCond:condition)
{
	if(RaceDisabled)
		return;

	if(ValidPlayer(client) && War3_GetRace(client)==thisRaceID)
	{
		if(condition==TFCond_Stealthed)
		{
			EndFade(client);
		}
	}

}
#endif

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(RaceDisabled)
		return Plugin_Continue;

	if((buttons & IN_ATTACK))
	{
		if(ValidPlayer(client) && War3_GetRace(client)==thisRaceID)
		{
			EndFade(client);
		}
	}
	else if((buttons & IN_ATTACK2))
	{
		if(ValidPlayer(client) && War3_GetRace(client)==thisRaceID)
		{
			EndFade(client);
		}
	}
	return Plugin_Continue;
}

public Action:Taunt(client, String:cmd[], args)
{
	if (client <= 0)
	{
		return Plugin_Continue;
	}
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}
	//if (!TF2_IsPlayerInCondition(client, TFCond_Taunting))
	//{
		//DP("not taunting");
		//return Plugin_Continue;
	//}
	if(ValidPlayer(client) && War3_GetRace(client)==thisRaceID)
	{
		EndFade(client);
		//return Plugin_Handled;
	}
	return Plugin_Continue;
}


public Action:SDK_FORWARD_TRANSMIT(entity, client)
{
	if(RaceDisabled)
		return Plugin_Continue;

#if GGAMETYPE == GGAME_TF2
	if(entity!=client
	&& InFade[client]
	&& ValidPlayer(entity)
	&& ValidPlayer(client)
	&& War3_GetRace(client)==thisRaceID
	&& W3HasImmunity(entity,Immunity_Skills))
	{
		new ClientTeam=GetClientTeam(client);
		if((ClientTeam==2 || ClientTeam==3)
		&& GetClientTeam(entity)!=ClientTeam
		&& IsPlayerAlive(entity)
		&& GetPlayerDistance(client,entity)>60.0
		&& !TF2_IsPlayerInCondition(entity, TFCond_Jarated)
		&& !TF2_IsPlayerInCondition(entity, TFCond_OnFire)
		&& !TF2_IsPlayerInCondition(entity, TFCond_Milked))
		{
			return Plugin_Handled;
		}
	}
#else
	if(entity!=client
	&& InFade[client]
	&& ValidPlayer(entity)
	&& ValidPlayer(client)
	&& War3_GetRace(client)==thisRaceID
	&& W3HasImmunity(entity,Immunity_Skills))
	{
		new ClientTeam=GetClientTeam(client);
		if((ClientTeam==2 || ClientTeam==3)
		&& GetClientTeam(entity)!=ClientTeam
		&& IsPlayerAlive(entity)
		&& GetPlayerDistance(client,entity)>60.0)
		{
			return Plugin_Handled;
		}
	}
#endif
	return Plugin_Continue;
}
