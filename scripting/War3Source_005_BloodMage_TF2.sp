#include <war3source>
#assert GGAMEMODE == MODE_WAR3SOURCE
#assert GGAMETYPE_JAILBREAK == JAILBREAK_OFF

#define RACE_ID_NUMBER 5

/**
* File: War3Source_BloodMage.sp
* Description: The Blood Mage race for War3Source.
* Author(s): Anthony Iacono & Ownage | Ownz (DarkEnergy) | El Diablo
*
*  REWRITTEN FOR TF2 ONLY - el diablo
*/


//#pragma semicolon 1

//#include <sourcemod>
//#include "W3SIncs/War3Source_Interface"
//#include <sdktools>
//#include <sdktools_functions>
//#include <sdktools_tempents>
//#include <sdktools_tempents_stocks>
// TODO: Effects

int thisRaceID;

int SKILL_REVIVE, SKILL_BANISH, SKILL_MONEYSTEAL,ULT_FLAMESTRIKE;

#if GGAMETYPE == GGAME_TF2
Handle ClientReviveMessage;
#endif

//skill 1
float MaxRevivalChance[MAXPLAYERSCUSTOM]; //chance for first attempt at revival
float CurrentRevivalChance[MAXPLAYERSCUSTOM];
float RevivalChancesArr[]={0.2,0.225,0.25,0.275,0.3};
float MinRevivalChancesArr[]={0.02,0.0225,0.025,0.0275,0.03};
int RevivedBy[MAXPLAYERSCUSTOM];
bool  bRevived[MAXPLAYERSCUSTOM];
float fLastRevive[MAXPLAYERSCUSTOM];

// Team switch checker
bool  Can_Player_Revive[MAXPLAYERSCUSTOM+1];

//skill 2
float BanishChancesArr[]={0.20,0.25,0.30,0.325,0.35};

//for TF only:
float CreditStealChanceTF[]={0.06,0.0675,0.075,0.0825,0.09};   //what are the chances of stealing
// instead of a percent we now base it on the attacker level
//float TFCreditStealPercent=0.02;  //how much to steal

//ultimate
Handle hrevivalDelayCvar;

float UltimateMaxDamage[]={70.0,78.0,86.0,94.0,100.0}; //max distance u can target your ultimate

int BurnsRemaining[MAXPLAYERSCUSTOM]; //burn count for victims
int BeingBurnedBy[MAXPLAYERSCUSTOM];
int UltimateUsed[MAXPLAYERSCUSTOM];

new String:reviveSound[]="war3source/reincarnation.mp3";
char banishSound[] = "war3source/BanishCaster.mp3";
char ultSound[] = "war3source/FlameStrikeBurst.mp3";
char ultExplosionSound[] = "items/pumpkin_explode1.wav";


int BeamSprite,HaloSprite;
int BloodSpray,BloodDrop;

public Plugin:myinfo =
{
	name = "Race - Blood Mage",
	author = "PimpinJuice & Ownz (DarkEnergy)",
	description = "The Blood Mage race for War3Source.",
	version = "1.0.0.0",
	url = "http://Www.OwnageClan.Com"
};

bool HooksLoaded = false;
public void Load_Hooks()
{
	if(HooksLoaded) return;
	HooksLoaded = true;

	W3Hook(W3Hook_OnW3TakeDmgBullet, OnW3TakeDmgBullet);
	W3Hook(W3Hook_OnUltimateCommand, OnUltimateCommand);
}
public void UnLoad_Hooks()
{
	if(!HooksLoaded) return;
	HooksLoaded = false;

	W3Unhook(W3Hook_OnW3TakeDmgBullet, OnW3TakeDmgBullet);
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
//	if(RaceDisabled)
//		return;


public OnPluginStart()
{
	HookEvent("player_spawn",PlayerSpawnEvent);
	HookEvent("round_start",RoundStartEvent);
	hrevivalDelayCvar=CreateConVar("war3_mage_revive_delay","4.0","Delay when reviving a teammate (since death)");

	HookEvent("player_death",PlayerDeathEvent);
	HookEvent("player_team",PlayerTeamEvent);

	//LoadTranslations("w3s.race.mage.phrases");
#if GGAMETYPE == GGAME_TF2
	ClientReviveMessage = CreateHudSynchronizer();


	CreateTimer(0.1,ResWarning,_,TIMER_REPEAT);
#else
	CreateTimer(1.0,ResWarning,_,TIMER_REPEAT);
#endif
}

bool RESwarn[MAXPLAYERSCUSTOM];
public Action ResWarning(Handle timer,any userid)
{
	if(RaceDisabled)
		return Plugin_Stop;

	for(int client=1;client<=MaxClients;client++)
	{
		if(RESwarn[client] && ValidPlayer(client))
		{
#if GGAMETYPE == GGAME_TF2
			SetHudTextParams(-1.0, -1.0, 0.1, 255, 255, 0, 255);
			ShowSyncHudText(client, ClientReviveMessage, "PREPARE FOR CHANCE TO REVIVE!");
#else
			War3_ChatMessage(client,"PREPARE FOR CHANCE TO REVIVE!");
#endif
		}
	}
	return Plugin_Stop;
}

public OnWar3LoadRaceOrItemOrdered2(num,reloadrace_id,String:shortname[])
{
	if(num==RACE_ID_NUMBER||(reloadrace_id>0&&StrEqual("mage",shortname,false)))
	{
		thisRaceID=War3_CreateNewRace("Blood Mage","mage",reloadrace_id,"Revive teammates, steal money.");
		SKILL_REVIVE=War3_AddRaceSkill(thisRaceID,"Phoenix","20-30% chance to revive your teammates that die.\nEach time you revive, chance is reduced by half\nto a minimum of 10% of original chance.",false,4);
		SKILL_BANISH=War3_AddRaceSkill(thisRaceID,"Banish","20-35% of making enemy blind and disoriented for 0.5 seconds",false,4,"(Autocast)");
		SKILL_MONEYSTEAL=War3_AddRaceSkill(thisRaceID,"Siphon Mana","6-9% chance of gaining 6-9 gold via damage",false,4,"(Autocast)");
		ULT_FLAMESTRIKE=War3_AddRaceSkill(thisRaceID,"Flame Strike","Shoot out a fireball that deals 70-100 damage.\nCooldown is 15s long.",true,4,"(voice Jeers)");
		War3_CreateRaceEnd(thisRaceID);
	}
}
public OnAllPluginsLoaded()
{
	War3_RaceOnPluginStart("mage");
}

public OnPluginEnd()
{
	if(LibraryExists("RaceClass"))
		War3_RaceOnPluginEnd("mage");
}
public OnMapStart()
{
	UnLoad_Hooks();

	BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();
	//we gonna use theese bloodsprite as "money blood"(change color)
	BloodSpray = PrecacheModel("sprites/bloodspray.vmt");
	BloodDrop = PrecacheModel("sprites/blood.vmt");

	PrecacheSound(reviveSound);
	PrecacheSound(ultSound);
	PrecacheSound(banishSound);
	PrecacheSound(ultExplosionSound);

	// Reset Can Player Revive
	for(int i=1;i<=MaxClients;i++)    // was MAXPLAYERSCUSTOM
	{
		Can_Player_Revive[i]=true;
	}
}

public OnAddSound(sound_priority)
{
	if(sound_priority==PRIORITY_LOW)
	{
		War3_AddSound(reviveSound);
		War3_AddSound(ultSound);
		War3_AddSound(banishSound);
	}
}

public OnClientDisconnect(client)
{
	RESwarn[client]=false;
}

public OnWar3PlayerAuthed(client)
{
	fLastRevive[client]=0.0;
	Can_Player_Revive[client]=true;
	RESwarn[client]=false;
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
	//War3_SetBuff(client,fArmorPhysical,thisRaceID,2.0);
	War3_SetBuff(client,fArmorMagic,thisRaceID,3.0);
}

public RemovePassiveSkills(client)
{
	int userid=GetClientUserId(client);
	for(int i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i) && BurnsRemaining[i]>0)
		{
			if(BeingBurnedBy[i]==userid)
			{
				BurnsRemaining[i]=0;
				W3ResetPlayerColor(i,thisRaceID);
			}
		}
	}
	//War3_SetBuff(client,fArmorPhysical,thisRaceID,0.0);
	War3_SetBuff(client,fArmorMagic,thisRaceID,0.0);
}

public void OnUltimateCommand(int client, int race, bool pressed, bool bypass)
{
	if(RaceDisabled)
		return;

	int userid=GetClientUserId(client);
	if(race==thisRaceID && pressed && userid>1 && IsPlayerAlive(client) )
	{
		int ult_level=War3_GetSkillLevel(client,race,ULT_FLAMESTRIKE);
		//if(War3_InFreezeTime())
		//{
		//	W3MsgNoCastDuringFreezetime(client);
		//}
		if(!Silenced(client)&&(bypass||War3_SkillNotInCooldown(client,thisRaceID,ULT_FLAMESTRIKE,true)))
		{
			War3_EmitSoundToAll(ultSound, client);
			War3_CooldownMGR(client, 15.0, thisRaceID, ULT_FLAMESTRIKE);

			int iEntity = CreateEntityByName("tf_projectile_spellfireball");
			if (IsValidEntity(iEntity)) 
			{
				int iTeam = GetClientTeam(client);
				float fAngles[3],fOrigin[3],vBuffer[3],fVelocity[3],fwd[3];

				SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);
				SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
				GetClientEyePosition(client, fOrigin);
				GetClientEyeAngles(client, fAngles);

				GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
				ScaleVector(fwd, 30.0);
				
				AddVectors(fOrigin, fwd, fOrigin);
				GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
				fVelocity[0] = vBuffer[0]*1500.0;
				fVelocity[1] = vBuffer[1]*1500.0;
				fVelocity[2] = vBuffer[2]*1500.0;
				
				SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, UltimateMaxDamage[ult_level], true); 
				TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
				DispatchSpawn(iEntity);

				SDKHook(iEntity, SDKHook_StartTouch, OnStartTouchFireball);
			}
		}
	}
}
public Action:OnStartTouchFireball(entity, other)
{
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
	if(!ValidPlayer(owner))
		return Plugin_Continue;

	SDKHook(entity, SDKHook_Touch, OnTouchFireball);
	return Plugin_Handled;
}
public Action:OnTouchFireball(entity, other)
{
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
	if(ValidPlayer(owner))
	{
		float vOrigin[3];
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vOrigin);
		CreateW3SParticle("heavy_ring_of_fire", vOrigin);
		vOrigin[2]+= 30.0;
		
		int i = -1;

		float damage = UltimateMaxDamage[War3_GetSkillLevel(owner, thisRaceID, ULT_FLAMESTRIKE)];
		while ((i = FindEntityByClassname(i, "*")) != -1)
		{
			if(IsValidForDamage(i) && IsOnDifferentTeams(owner,i) && i != entity) 
			{
				float targetvec[3];
				float distance;
				GetEntPropVector(i, Prop_Data, "m_vecOrigin", targetvec);
				distance = GetVectorDistance(vOrigin, targetvec)
				if(distance <= 300.0 && IsPointVisible(vOrigin,targetvec))
				{
					float ratio = (1.0-(distance/300.0)*0.25);
					if(ratio < 0.5)
						ratio = 0.5;
					if(ratio >= 0.95)
						ratio = 1.0;
					damage *= ratio
					
					if(War3_DealDamage(i,RoundFloat(W3GetBuffStackedFloat(i,fUltimateResistance)*damage),owner,_,"flamestrike",W3DMGORIGIN_ULTIMATE))
					{
						War3_NotifyPlayerTookDamageFromSkill(i, owner, War3_GetWar3DamageDealt(), ULT_FLAMESTRIKE);
					}
				}
			}
		}
		War3_EmitSoundToAll(ultExplosionSound, entity);
		RemoveEntity(entity);
	}
	SDKUnhook(entity, SDKHook_Touch, OnTouchFireball);
	return Plugin_Handled;
}

public void OnSkillLevelChanged(int client, int currentrace, int skill, int newskilllevel, int oldskilllevel)
{
	if(RaceDisabled)
		return;

	if(currentrace==thisRaceID)
	{
		if(newskilllevel>=0)
		{
			if(skill==SKILL_REVIVE) //1
			{
				MaxRevivalChance[client]=RevivalChancesArr[newskilllevel];
			}
		}
	}
}

public Action OnW3TakeDmgBullet(int victim, int attacker, float damage)
{
	if(RaceDisabled)
		return Plugin_Continue;

	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&attacker!=victim&&GetClientTeam(attacker)!=GetClientTeam(victim))
	{
#if GGAMETYPE == GGAME_TF2
		if(!W3IsOwnerSentry(attacker))
		{
#endif
			if(War3_GetRace(attacker)==thisRaceID)
			{
				float chance_mod=W3ChanceModifier(attacker);
				float resistance = W3GetBuffStackedFloat(victim, fAbilityResistance);
				chance_mod *= resistance;

				if(IsPlayerAlive(attacker)&&IsPlayerAlive(victim))
				{
					new skill_level=War3_GetSkillLevel(attacker,thisRaceID,SKILL_BANISH);
					if(!Hexed(attacker,false)&&War3_SkillNotInCooldown(attacker,thisRaceID,SKILL_BANISH)&&GetRandomFloat(0.0,1.0)<=BanishChancesArr[skill_level]*chance_mod)
					{
						if(W3HasImmunity(victim,Immunity_Skills))
						{
							//W3MsgSkillBlocked(victim,attacker,"Banish");
							War3_NotifyPlayerImmuneFromSkill(attacker, victim, SKILL_BANISH);
						}
						else
						{
							// TODO: Sound effects?
							//float oldangle[3];
							//GetClientEyeAngles(victim,oldangle);
							//oldangle[0]+=GetRandomFloat(-20.0,20.0);
							//oldangle[1]+=GetRandomFloat(-20.0,20.0);
							//TeleportEntity(victim, NULL_VECTOR, oldangle, NULL_VECTOR);
							War3_CooldownMGR(attacker, 5.0, thisRaceID, SKILL_BANISH);
							War3_EmitSoundToAll(banishSound, attacker);
							W3MsgBanished(victim,attacker);
							W3FlashScreen(victim,{0,0,0,255},0.4,_,FFADE_STAYOUT);
							War3_SetBuff(victim,bDisarm,thisRaceID,true);
							CreateTimer(0.5,Unbanish,GetClientUserId(victim));

							float effect_vec[3];
							GetClientAbsOrigin(attacker,effect_vec);
							float effect_vec2[3];
							GetClientAbsOrigin(victim,effect_vec2);
							effect_vec[2]+=40;
							effect_vec2[2]+=40;
							TE_SetupBeamPoints(effect_vec,effect_vec2,BeamSprite,BeamSprite,0,50,1.0,30.0,10.0,0,12.0,{140,150,255,255},40);
							TE_SendToAll();
							effect_vec2[2]+=18;
							TE_SetupBeamPoints(effect_vec,effect_vec2,BeamSprite,BeamSprite,0,50,1.0,30.0,10.0,0,12.0,{140,150,255,255},40);
							TE_SendToAll();
						}
					}
					skill_level=War3_GetSkillLevel(attacker,thisRaceID,SKILL_MONEYSTEAL);
					if(!Hexed(attacker,false))
					{
						if(GetRandomFloat(0.0,1.0) <= CreditStealChanceTF[skill_level]*chance_mod)
						{
							if(W3HasImmunity(victim,Immunity_Skills))
							{
								//W3MsgSkillBlocked(victim,attacker,"Siphon Mana");
								War3_NotifyPlayerImmuneFromSkill(attacker, victim, SKILL_MONEYSTEAL);
							}
							else
							{
								int stolen=GetRandomInt(6,9);
								if(stolen>0)
								{
									War3_SetGold(attacker,War3_GetGold(attacker)+stolen);
									PrintHintText(attacker, "Gained +%i gold from siphon!", stolen);
									W3FlashScreen(attacker,RGBA_COLOR_BLUE);
									siphonsfx(victim);
								}
							}
						}
					}
				}
			}
#if GGAMETYPE == GGAME_TF2
		}
#endif
	}
	return Plugin_Continue;
}

stock void siphonsfx(int victim)
{
	float vecAngles[3];
	GetClientEyeAngles(victim,vecAngles);
	float target_pos[3];
	GetClientAbsOrigin(victim,target_pos);
	target_pos[2]+=45;
	TE_SetupBloodSprite(target_pos, vecAngles, {250, 250, 28, 255}, 35, BloodSpray, BloodDrop);
	TE_SendToAll();
}

stock void respawnsfx(int target) {
	float effect_vec[3];
	GetClientAbsOrigin(target,effect_vec);
	effect_vec[2]+=15.0;
	TE_SetupBeamRingPoint(effect_vec,60.0,1.0,BeamSprite,HaloSprite,0,15,1.5,8.0,1.0,{255,255,20,255},10,0);
	TE_SendToAll();
	effect_vec[2]+=15.0;
	TE_SetupBeamRingPoint(effect_vec,60.0,1.0,BeamSprite,HaloSprite,0,15,1.5,8.0,1.0,{255,255,20,255},10,0);
	TE_SendToAll();
	effect_vec[2]+=15.0;
	TE_SetupBeamRingPoint(effect_vec,60.0,1.0,BeamSprite,HaloSprite,0,15,1.5,8.0,1.0,{255,255,20,255},10,0);
	TE_SendToAll();
}

// Events
public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(RaceDisabled)
		return;

	int userid=GetEventInt(event,"userid");
	int client=GetClientOfUserId(userid);
	if(client>0)
	{
		UltimateUsed[client]=0;
		if(War3_GetRace(client)==thisRaceID)
		{
			int skill_level_revive=War3_GetSkillLevel(client,thisRaceID,SKILL_REVIVE);
			if(!bRevived[client]&&skill_level_revive)
			{
				CurrentRevivalChance[client]=RevivalChancesArr[skill_level_revive];
			}
		}
		bRevived[client]=false;
	}

}

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(RaceDisabled)
		return;

	for(int i=1;i<=MaxClients;i++)
	{
		//Reset revival chance
		int skill_level_revive=War3_GetSkillLevel(i,thisRaceID,SKILL_REVIVE);
		if(ValidPlayer(i) && skill_level_revive)
		{
			CurrentRevivalChance[i]=RevivalChancesArr[skill_level_revive];
		}
		//reset everyone's ultimate

	}
}

public Action:DoRevival(Handle:timer,any:userid)
{
	int client=GetClientOfUserId(userid);
	if(Can_Player_Revive[client]==false)
	{
		return Plugin_Handled;
	}
	//int client=GetClientOfUserId(userid);
	if(client>0)
	{
		int savior = RevivedBy[client];
		if(ValidPlayer(savior,true) && ValidPlayer(client))
		{
			int iClientTeam = GetClientTeam(client);
			if(GetClientTeam(savior)==iClientTeam&&!IsPlayerAlive(client))
			{
				//PrintToChatAll("omfg remove true");
				//SetEntityMoveType(client, MOVETYPE_NOCLIP);
				War3_SpawnPlayer(client);
				War3_EmitSoundToAll(reviveSound,client);

				W3MsgRevivedBM(client,savior);

				float VecPos[3];
				float Angles[3];
				War3_CachedAngle(client,Angles);
				War3_CachedPosition(client,VecPos);

				// Try and send player to closest teleporter
				//War3_SendToTeleporter(int iClient, int iTeam, bool bEntrance, bool bExit, bool bClosest);

				War3_EmitSoundToAll(reviveSound,client);
				W3MsgRevivedBM(client,savior);

				TeleportEntity(client, VecPos, Angles, NULL_VECTOR);
				RESwarn[client]=false;

				//testhull(client);


				fLastRevive[client]=GetGameTime();
				War3_RestoreItemsFromDeath(client,false);
				//test noclip method

				//SetEntityMoveType(client, MOVETYPE_WALK);

			}
			else
			{
				//this guy changed team?
				CurrentRevivalChance[savior]*=2.0;
				RevivedBy[client]=0;
				bRevived[client]=false;
				RESwarn[client]=false;
			}
		}
		else
		{
			// savior left or something? maybe dead?
			RevivedBy[client]=0;
			bRevived[client]=false;
			RESwarn[client]=false;
		}

	}
	return Plugin_Continue;
}

bool:CooldownRevive(client)
{
	if(GetGameTime() >= (fLastRevive[client]+30.0))
		return true;
	return false;
}

public PlayerTeamEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(RaceDisabled)
		return;

// Team Switch checker
	int userid=GetEventInt(event,"userid");
	int client=GetClientOfUserId(userid);
	// For testing purposes:
	//new String:clientname[64];
	//GetClientName(client, clientname, sizeof(clientname));
	//DP("Player %s Switched Teams (Can not be revived for 15 seconds)",clientname);
	Can_Player_Revive[client]=false;
	RESwarn[client]=false;
	CreateTimer(30.0,PlayerCanRevive,userid);
}

public Action PlayerCanRevive(Handle timer,any userid)
{
// Team Switch checker
	int client=GetClientOfUserId(userid);
	// For testing purposes:
	//new String:clientname[64];
	//GetClientName(client, clientname, sizeof(clientname));
	//DP("Player %s can be revived by bloodmages",clientname);
	Can_Player_Revive[client]=true;
	return Plugin_Stop;
}

public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(RaceDisabled)
		return;

	int userid=GetEventInt(event,"userid");
	int victim=GetClientOfUserId(userid);
	if(victim>0)
	{
		BurnsRemaining[victim]=0;
		W3ResetPlayerColor(victim,thisRaceID);
		int victimTeam = GetClientTeam(victim);
		int skillevel;

		int deathFlags = GetEventInt(event, "death_flags");

		if (deathFlags & 32)
		{
			//PrintToChat(client,"war3 debug: dead ringer kill");
		}
		else
		{

			//

			//TEST!! remove!!
			//DP("Auto revival  Remove this line CreateTimer(0.1,DoRevival,victim);");
			//CreateTimer(0.1,DoRevival,victim);
			//RevivedBy[victim]=GetClientOfUserId(userid);
			//PrintToChatAll("blood mage");

			//find a revival

			// Can_Player_Revive is the team switch checking variable
			if(CooldownRevive(victim)&&Can_Player_Revive[victim] && (!GetEntProp(victim, Prop_Send, "m_bUseBossHealthBar") || !GetEntProp(victim, Prop_Send, "m_bIsMiniBoss"))) {
			//if(Can_Player_Revive[victim]) {
				for(new i=1;i<=MaxClients;i++)
				{
					if(i!=victim&&ValidPlayer(i,true)&&GetClientTeam(i)==victimTeam&&War3_GetRace(i)==thisRaceID)
					{
						skillevel=War3_GetSkillLevel(i,thisRaceID,SKILL_REVIVE);
						if(!Hexed(i,false))
						{
							if(GetRandomFloat(0.0,1.0)<=CurrentRevivalChance[i])
							{
								CurrentRevivalChance[i]/=2.0;
								if(CurrentRevivalChance[i]<MinRevivalChancesArr[skillevel]){
									CurrentRevivalChance[i]=MinRevivalChancesArr[skillevel];
								}
								RevivedBy[victim]=i;
								bRevived[victim]=true;
								RESwarn[victim]=true;
								CreateTimer(GetConVarFloat(hrevivalDelayCvar),DoRevival,GetClientUserId(victim));
								break;
							}
						}
					}
				}
			}
		}
	}
}



public Action Unbanish(Handle timer,any userid)
{
	// never EVER use client in a timer. userid is safe
	int client=GetClientOfUserId(userid);
	if(client>0)
	{
		W3FlashScreen(client,{0,0,0,0},0.1,_,(FFADE_IN|FFADE_PURGE));
		War3_SetBuff(client,bDisarm,thisRaceID,false);
	}
	return Plugin_Stop;
}
/*
new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25,27,-27,30,-30};//,33,-33,40,-40};

public bool:testhull(client){

	//PrintToChatAll("BEG");
	float mins[3];
	float maxs[3];
	GetClientMins(client,mins);
	GetClientMaxs(client,maxs);

	//PrintToChatAll("min : %.1f %.1f %.1f MAX %.1f %.1f %.1f",mins[0],mins[1],mins[2],maxs[0],maxs[1],maxs[2]);
	new absincarraysize=sizeof(absincarray);
	float originalpos[3];
	GetClientAbsOrigin(client,originalpos);

	new limit=5000;
	for(new x=0;x<absincarraysize;x++){
		if(limit>0){
			for(new y=0;y<=x;y++){
				if(limit>0){
					for(new z=0;z<=y;z++){
						float pos[3]={0.0,0.0,0.0};
						AddVectors(pos,originalpos,pos);
						pos[0]+=float(absincarray[x]);
						pos[1]+=float(absincarray[y]);
						pos[2]+=float(absincarray[z]);

						//PrintToChatAll("hull at %.1f %.1f %.1f",pos[0],pos[1],pos[2]);
						//PrintToServer("hull at %d %d %d",absincarray[x],absincarray[y],absincarray[z]);
						TR_TraceHullFilter(pos,pos,mins,maxs,CONTENTS_SOLID|CONTENTS_MOVEABLE,CanHitThis,client);
						//new ent;
						if(TR_DidHit(_))
						{
							//PrintToChatAll("2");
							//ent=TR_GetEntityIndex(_);
							//PrintToChatAll("hit %d self: %d",ent,client);
						}
						else{
							TeleportEntity(client,pos,NULL_VECTOR,NULL_VECTOR);
							limit=-1;
							break;
						}

						if(limit--<0){
							break;
						}
					}

					if(limit--<0){
						break;
					}
				}
			}

			if(limit--<0){
				break;
			}

		}

	}
	//PrintToChatAll("END");
}

public bool:CanHitThis(entityhit, mask, any:data)
{
	if(entityhit == data )
	{// Check if the TraceRay hit the itself.
		return false; // Don't allow self to be hit, skip this result
	}
	if(ValidPlayer(entityhit)&&ValidPlayer(data)&&GetClientTeam(entityhit)==GetClientTeam(data)){
		return false; //skip result, prend this space is not taken cuz they on same team
	}
	return true; // It didn't hit itself
}
*/


//
#if GGAMETYPE == GGAME_TF2
public OnW3SupplyLocker(client)
{
	if(RaceDisabled)
		return;

	if(ValidPlayer(client))
	{
		BeingBurnedBy[client]=0;
		W3ResetPlayerColor(client,thisRaceID);
	}
}
#endif
public OnW3HealthPickup(const String:output[], caller, activator, Float:delay)
{
	if(RaceDisabled)
		return;

	if(ValidPlayer(activator))
	{
		BeingBurnedBy[activator]=0;
		W3ResetPlayerColor(activator,thisRaceID);
	}
}
