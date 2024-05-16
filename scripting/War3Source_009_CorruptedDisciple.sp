#include <war3source>
#assert GGAMEMODE == MODE_WAR3SOURCE

#define RACE_ID_NUMBER 9

/**
 *
 * Description:   CD from HON
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
//new Float:ultCooldownCvar=30.0;

new SKILL_TIDE, SKILL_CONDUIT, SKILL_STATIC, ULT_OVERLOAD;


// Chance/Data Arrays
new ElectricTideMaxDamage[]={80,85,90,95,100};
new Float:ElectricTideRadius=250.0;
new Float:AbilityCooldownTime=6.0;

new ConduitPerHit[]={2,3,3,4,4};
new ConduitDuration=7;
new ConduitCooldown=7;
new ConduitMaxHeal[]={10,11,12,13,14};

new Float:StaticHealPercent[]={0.25, 0.275, 0.3, 0.325, 0.35};
new StaticHealRadius=800;

new OverloadDuration=25; //HIT TIMES, DURATION DEPENDS ON TIMER
new OverloadRadius=400;
new OverloadDamagePerHit[]={8,9,10,11,12};
new Float:OverloadDamageIncrease[]={0.015,0.016,0.017,0.018,0.019};
////


new Float:ElectricTideOrigin[MAXPLAYERSCUSTOM][3];
new ElectricTideLoopCountdown[MAXPLAYERSCUSTOM];

new bool:HitOnForwardTide[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM]; //[VICTIM][ATTACKER]
new bool:HitOnBackwardTide[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM];



new Float:ConduitUntilTime[MAXPLAYERSCUSTOM]; // less than 1.0 is considered not activated, eles if curren ttime is more than  GetGameTime()
new ConduitSubtractDamage[MAXPLAYERSCUSTOM];
new ConduitBy[MAXPLAYERSCUSTOM]; //[VICTIM]


new UltimateZapsRemaining[MAXPLAYERSCUSTOM];
new Float:PlayerDamageIncrease[MAXPLAYERSCUSTOM];

new String:taunt1[]="war3source/cd/feeltheburn2.mp3";
new String:taunt2[]="war3source/cd/feeltheburn3.mp3";

new String:overload1[]="war3source/cd/overload2.mp3";
new String:overloadzap[]="war3source/cd/overloadzap.mp3";
new String:overloadstate[]="war3source/cd/ultstate.mp3";

// Effects
new BeamSprite,HaloSprite;

public Plugin:myinfo =
{
	name = "Race - Corrupted Disciple",
	author = "PimpJuice and Ownz (DarkEnergy)",
	description = "The Corrupted Disciple race for War3Source.",
	version = "1.0",
	url = "http://pimpinjuice.net/"
};

public OnPluginStart()
{
	//HookEvent("player_hurt",PlayerHurtEvent);
	//ultCooldownCvar=CreateConVar("war3_cd_ult_cooldown","30","Cooldown time for CD ult overload.");
	CreateTimer(0.2,CalcConduit,_,TIMER_REPEAT);
}

public OnAllPluginsLoaded()
{
	//LoadTranslations("w3s.race.cd.phrases");
	War3_RaceOnPluginStart("cd");
}


bool HooksLoaded = false;
public void Load_Hooks()
{
	if(HooksLoaded) return;
	HooksLoaded = true;

	W3Hook(W3Hook_OnW3TakeDmgAllPre, OnW3TakeDmgAllPre);
	W3Hook(W3Hook_OnW3TakeDmgAll, OnW3TakeDmgAll);
	W3Hook(W3Hook_OnUltimateCommand, OnUltimateCommand);
	W3Hook(W3Hook_OnAbilityCommand, OnAbilityCommand);
	W3Hook(W3Hook_OnWar3EventSpawn, OnWar3EventSpawn);
}
public void UnLoad_Hooks()
{
	if(!HooksLoaded) return;
	HooksLoaded = false;

	W3Unhook(W3Hook_OnW3TakeDmgAllPre, OnW3TakeDmgAllPre);
	W3Unhook(W3Hook_OnW3TakeDmgAll, OnW3TakeDmgAll);
	W3Unhook(W3Hook_OnUltimateCommand, OnUltimateCommand);
	W3Unhook(W3Hook_OnAbilityCommand, OnAbilityCommand);
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
	}
}
//	if(RaceDisabled)
//		return;

public OnPluginEnd()
{
	if(LibraryExists("RaceClass"))
		War3_RaceOnPluginEnd("cd");
}

public OnWar3LoadRaceOrItemOrdered2(num,reloadrace_id,String:shortname[])
{
	if(num==RACE_ID_NUMBER||(reloadrace_id>0&&StrEqual("cd",shortname,false)))
	{
		thisRaceID=War3_CreateNewRace("Corrupted Disciple","cd",reloadrace_id,"Electricity & support");
		SKILL_TIDE=War3_AddRaceSkill(thisRaceID,"Electric Tide","Expands electric rings around you, deals the most damage at the edge.\nMaximum damage is 80-100. Has a 6 second cooldown.",false,4,"(voice Help!)");
		SKILL_CONDUIT=War3_AddRaceSkill(thisRaceID,"Corrupted Conduit","Your victim will lose damage per attack for a duration.\nAuto activate when not on cooldown. On activation: Heals 2-4 health when you're hit.\nLasts 7 seconds, has a 7 second cooldown.",false,4,"(Autocast)");
		SKILL_STATIC=War3_AddRaceSkill(thisRaceID,"Static Discharge","Heals teammates and you for 25-35% of damage taken. 800HU radius.",false,4);
		ULT_OVERLOAD=War3_AddRaceSkill(thisRaceID,"Overload","(+ultimate) Shocks the lowest hp enemy around you per second while you gain damage per hit\nHits for 8-11 dmg, has 25 damage ticks. Your damage increases by 1.5% -> 1.9% per zap. Ticks every 0.3 seconds.",true,4,"(voice Jeers)");
		War3_CreateRaceEnd(thisRaceID);
	}

}

public OnMapStart()
{
	UnLoad_Hooks();

	BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();

	PrecacheSound(taunt1);
	PrecacheSound(taunt2);
	PrecacheSound(overload1);
	PrecacheSound(overloadzap);
	PrecacheSound(overloadstate);
}

public OnAddSound(sound_priority)
{
	if(sound_priority==PRIORITY_MEDIUM)
	{
		War3_AddSound(overload1);
		War3_AddSound(overloadzap);
		War3_AddSound(overloadstate);
	}
	if(sound_priority==PRIORITY_LOW)
	{
		War3_AddSound(taunt1);
		War3_AddSound(taunt2);
	}
}

public void OnAbilityCommand(int client, int ability, bool pressed, bool bypass)
{
	if(RaceDisabled)
		return;

	//if(!bypass)
		//DP("!bypass");

	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && ValidPlayer(client,true))
	{
		if(!Silenced(client)&&(bypass||War3_SkillNotInCooldown(client,thisRaceID,SKILL_TIDE,true)))
		{
			GetClientAbsOrigin(client,ElectricTideOrigin[client]);
			ElectricTideOrigin[client][2]+=15.0;
			ElectricTideLoopCountdown[client]=20;

			for(new i=1;i<=MaxClients;i++){
				HitOnBackwardTide[i][client]=false;
				HitOnForwardTide[i][client]=false;
			}
			//50 IS THE CLOSE CHECK
			TE_SetupBeamRingPoint(ElectricTideOrigin[client], 20.0, 2*ElectricTideRadius+20, BeamSprite, HaloSprite, 0, 5, 0.5, 10.0, 1.0, {255,0,255,133}, 60, 0);
			TE_SendToAll();

			CreateTimer(0.1,BurnLoop,GetClientUserId(client)); //damage
			CreateTimer(0.13,BurnLoop,GetClientUserId(client)); //damage
			CreateTimer(0.17,BurnLoop,GetClientUserId(client)); //damage

			CreateTimer(0.5,SecondRing,GetClientUserId(client));

			War3_CooldownMGR(client,AbilityCooldownTime,thisRaceID,SKILL_TIDE,_,_);
			War3_EmitSoundToAll(taunt1,client);//,_,SNDLEVEL_TRAIN);
			War3_EmitSoundToAll(taunt1,client);//,_,SNDLEVEL_TRAIN);
			War3_EmitSoundToAll(taunt2,client);

			PrintHintText(client,"Feel the burn!");
		}
	}
}

public Action:SecondRing(Handle:timer,any:userid)
{
	new client=GetClientOfUserId(userid);
	TE_SetupBeamRingPoint(ElectricTideOrigin[client], 2*ElectricTideRadius+20,20.0, BeamSprite, HaloSprite, 0, 5, 0.5, 10.0, 1.0, {255,0,255,133}, 60, 0);
	TE_SendToAll();
}
public Action:BurnLoop(Handle:timer,any:userid)
{
	new attacker=GetClientOfUserId(userid);
	if(ValidPlayer(attacker) && ElectricTideLoopCountdown[attacker]>0)
	{
		new team = GetClientTeam(attacker);
		//War3_DealDamage(victim,damage,attacker,DMG_BURN);
		CreateTimer(0.1,BurnLoop,userid);

		new Float:damagingRadius=(1.0-FloatAbs(float(ElectricTideLoopCountdown[attacker])-10.0)/10.0)*ElectricTideRadius;

		//PrintToChatAll("distance to damage %f",damagingRadius);

		ElectricTideLoopCountdown[attacker]--;

		new Float:otherVec[3];
		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true)&&GetClientTeam(i)!=team)
			{
				if(!W3HasImmunity(i,Immunity_Skills))
				{
					if(ElectricTideLoopCountdown[attacker]<10){
						if(HitOnBackwardTide[i][attacker]==true){
							continue;
						}
					}
					else{
						if(HitOnForwardTide[i][attacker]==true){
							continue;
						}
					}

					GetClientAbsOrigin(i,otherVec);
					otherVec[2]+=30.0;
					new Float:victimdistance=GetVectorDistance(ElectricTideOrigin[attacker],otherVec);
					float resistance = W3GetBuffStackedFloat(i, fAbilityResistance);
					if(victimdistance<ElectricTideRadius&&FloatAbs(otherVec[2]-ElectricTideOrigin[attacker][2])<25)
					{
						if(FloatAbs(victimdistance-damagingRadius)<(ElectricTideRadius/10.0))
						{
							float distFactor = (1+victimdistance/ElectricTideRadius)/2.0;

							if(ElectricTideLoopCountdown[attacker]<10){
								HitOnBackwardTide[i][attacker]=true;
							}
							else{
								HitOnForwardTide[i][attacker]=true;
							}
							if(War3_DealDamage(i,RoundFloat(resistance*ElectricTideMaxDamage[War3_GetSkillLevel(attacker,thisRaceID,SKILL_TIDE)]*distFactor/2.0),attacker,DMG_ENERGYBEAM,"electrictide"))
							{
								War3_NotifyPlayerTookDamageFromSkill(i, attacker, War3_GetWar3DamageDealt(), SKILL_TIDE);
							}
						}

					}
				}
				else
				{
					War3_NotifyPlayerImmuneFromSkill(attacker, i, SKILL_TIDE);
				}
			}
		}
	}

}

public void OnWar3EventSpawn (int client)
{
	UltimateZapsRemaining[client]=0;
}
public void OnUltimateCommand(int client, int race, bool pressed, bool bypass)
{
	if(RaceDisabled)
		return;

	if(race==thisRaceID && pressed && IsPlayerAlive(client))
	{
		if(UltimateZapsRemaining[client]>0)
		{
			War3_ChatMessage(client,"{lightgreen}Overload is already active!");
			return;
		}
#if GGAMETYPE == GGAME_TF2
		if(Spying(client))
		{
			War3_ChatMessage(client,"{lightgreen}You can not be spying and use Overload at the same time!");
			return;
		}
		if(TF2_IsPlayerInCondition(client, TFCond_Bonked))
		{
			War3_ChatMessage(client,"{lightgreen}You can not be bonked and use Overload at the same time!");
			return;
		}
		if(War3_IsUbered(client))
		{
			War3_ChatMessage(client,"{lightgreen}You can not be ubered and use Overload at the same time!");
			return;
		}
#endif
		if(!Silenced(client)&&(bypass||War3_SkillNotInCooldown(client,thisRaceID,ULT_OVERLOAD,true)))
		{
			UltimateZapsRemaining[client]=OverloadDuration;

			PlayerDamageIncrease[client]=1.0;

			CreateTimer(0.3,UltimateLoop,GetClientUserId(client)); //damage

			War3_EmitSoundToAll(overload1,client);
			War3_EmitSoundToAll(overload1,client);

			War3_EmitSoundToAll(overloadstate,client);
			CreateTimer(3.7,UltStateSound,client);
		}
	}
}
public Action:UltimateLoop(Handle:timer,any:userid)
{
	new attacker=GetClientOfUserId(userid);
	if(ValidPlayer(attacker,true) && UltimateZapsRemaining[attacker]>0)
	{
		SetHudTextParams(0.4, 0.7, 0.1, 138, 66, 245, 255);
		ShowHudText(attacker, -1, "Overload Damage Bonus: %.2fx", PlayerDamageIncrease[attacker]);
		UltimateZapsRemaining[attacker]--;
		new Float:pos[3];
		new Float:otherpos[3];
		GetClientEyePosition(attacker,pos);
		new team = GetClientTeam(attacker);
		new lowesthp=2147483647;
		new besttarget=0;

		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true))
			{
#if GGAMETYPE == GGAME_TF2
				if(Spying(attacker))
				{
					besttarget=0;
					break;
				}
				if(TF2_IsPlayerInCondition(attacker, TFCond_Bonked))
				{
					besttarget=0;
					break;
				}
				if(TF2_IsPlayerInCondition(attacker, TFCond_Bonked))
				{
					besttarget=0;
					break;
				}
				if(War3_IsUbered(attacker))
				{
					besttarget=0;
					break;
				}

				// skip victim if they are spying
				if(Spying(i))
				{
					continue;
				}
#endif
				if(GetClientTeam(i)!=team)
				{
					GetClientAbsOrigin(i,otherpos);
					//PrintToChatAll("%d distance %f",i,GetVectorDistance(pos,otherpos));
					if(GetVectorDistance(pos,otherpos)<OverloadRadius)
					{
						if(!W3HasImmunity(i,Immunity_Ultimates))
						{
							new Float:distanceVec[3];
							SubtractVectors(otherpos,pos,distanceVec);
							new Float:angles[3];
							GetVectorAngles(distanceVec,angles);

							TR_TraceRayFilter(pos, angles, MASK_PLAYERSOLID, RayType_Infinite, CanHitThis,attacker);
							new ent;
							if(TR_DidHit(_))
							{
								ent=TR_GetEntityIndex(_);
								//PrintToChatAll("trace hit: %d      wanted to hit player: %d",ent,i);
							}

							if(ent==i&&GetClientHealth(i)<lowesthp){
								besttarget=i;
								lowesthp=GetClientHealth(i);
							}
						}
						else
						{
							War3_NotifyPlayerImmuneFromSkill(attacker, i, ULT_OVERLOAD);
						}
					}
				}
			}
		}
		if(besttarget>0){
			pos[2]-=15.0; //ATTACKER EYE

			GetClientEyePosition(besttarget,otherpos);
			otherpos[2]-=20.0; //THIS IS EYE NOW, NOT ABS
			TE_SetupBeamPoints(pos,otherpos,BeamSprite,HaloSprite,0,35,0.15,6.0,5.0,0,1.0,{255,000,255,255},20);
			TE_SendToAll();
			float resistance = W3GetBuffStackedFloat(besttarget, fUltimateResistance);
			if(War3_DealDamage(besttarget,RoundFloat(resistance*OverloadDamagePerHit[War3_GetSkillLevel(attacker,thisRaceID,ULT_OVERLOAD)]),attacker,_,"overload"))
			{
				War3_NotifyPlayerTookDamageFromSkill(besttarget, attacker, War3_GetWar3DamageDealt(), ULT_OVERLOAD);
			}
			PlayerDamageIncrease[attacker]+=OverloadDamageIncrease[War3_GetSkillLevel(attacker,thisRaceID,ULT_OVERLOAD)];

			War3_EmitSoundToAll(overloadzap,attacker);
			War3_EmitSoundToAll(overloadzap,attacker);
			War3_EmitSoundToAll(overloadzap,besttarget);
			War3_EmitSoundToAll(overloadzap,besttarget);
		}
		CreateTimer(0.3,UltimateLoop,GetClientUserId(attacker)); //damage
	}
	if(UltimateZapsRemaining[attacker]==0)
	{
		UltimateZapsRemaining[attacker]=-1;
		if(ValidPlayer(attacker))
		{
			War3_CooldownMGR(attacker,30.0,thisRaceID,ULT_OVERLOAD,_,_);
		}
	}
}
public Action:UltStateSound(Handle:t,any:attacker){
	if(ValidPlayer(attacker,true)&&UltimateZapsRemaining[attacker]>0){
		War3_EmitSoundToAll(overloadstate,attacker);
		CreateTimer(3.7,UltStateSound,attacker);
	}
}

public bool:CanHitThis(entity, mask, any:data)
{
	if(entity == data)
	{// Check if the TraceRay hit the itself.
		return false; // Don't allow self to be hit
	}
	return true; // It didn't hit itself
}







public Action OnW3TakeDmgAllPre(int victim, int attacker, float damage)
{
	if(RaceDisabled)
		return Plugin_Continue;

	if(IsValidEntity(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		if(ValidPlayer(victim,true))
		{
			if(GetClientTeam(victim)==GetClientTeam(attacker) || W3HasImmunity(victim, Immunity_Ultimates))
				return Plugin_Continue;
		}
		new race_attacker=War3_GetRace(attacker);
		if(race_attacker==thisRaceID&&IsPlayerAlive(attacker)&&UltimateZapsRemaining[attacker]>0)
		{
			float resistance = W3GetBuffStackedFloat(victim, fUltimateResistance);
			War3_DamageModPercent(1+ (PlayerDamageIncrease[attacker]-1)*resistance);
		}
	}
	return Plugin_Changed;
}



//public PlayerHurtEvent(Handle:event,const String:name[],bool:dontBroadcast)
//{
public Action OnW3TakeDmgAll(int victim,int attacker, float damage)
{
	if(RaceDisabled)
		return Plugin_Continue;

	//new userid=GetEventInt(event,"userid");
	//new attacker_userid=GetEventInt(event,"attacker");
	//new dmg=GetEventInt(event,"dmg_health");
	//new weaponidTF;
	//dmg=GetEventInt(event,"damageamount");
	//weaponidTF=GetEventInt(event,"weaponid");
	//PrintToChatAll("weaponid %d",weaponidTF);
	//if(userid&&attacker_userid&&userid!=attacker_userid)
	//{
	new dmg=RoundToCeil(damage);
	//new victim=GetClientOfUserId(userid);
	//new attacker=GetClientOfUserId(attacker_userid);
	if(ValidPlayer(victim)&&ValidPlayer(attacker))
	{
		new race_attacker=War3_GetRace(attacker);
		if(race_attacker==thisRaceID)
		{
			new skill_level=War3_GetSkillLevel(attacker,thisRaceID,SKILL_CONDUIT);

			if(W3GetDamageIsBullet()&&!Hexed(attacker,false))
			{
				if(ConduitUntilTime[victim]>1.0&&W3Chance(W3ChanceModifier(attacker)))
				{
					//do nothing, already on conduit
					ConduitSubtractDamage[victim]+=ConduitPerHit[skill_level];
				}
				else if(War3_SkillNotInCooldown(attacker,thisRaceID,SKILL_CONDUIT))
				{
					//activate conduit on this victim

					if(!W3HasImmunity(victim,Immunity_Skills))
					{
						float resistance = W3GetBuffStackedFloat(victim, fAbilityResistance);
						ConduitUntilTime[victim]=GetGameTime()+float(ConduitDuration)*resistance;
						ConduitSubtractDamage[victim]+=ConduitPerHit[skill_level];
						ConduitBy[victim]=attacker;
						War3_CooldownMGR(attacker,float(ConduitCooldown),thisRaceID,SKILL_CONDUIT,_,false);

						PrintHintText(victim,"Conduit activated on you!");
						PrintHintText(attacker,"Activated Conduit!");
						War3_NotifyPlayerSkillActivated(attacker,SKILL_CONDUIT,true);
					}
					else
					{
						War3_NotifyPlayerImmuneFromSkill(attacker, victim, SKILL_CONDUIT);
					}
				}
			}
		}

		///attacker has conduit:
		if(ConduitSubtractDamage[attacker]){
			if(ValidPlayer(ConduitBy[attacker],false)){
				//PrintToChatAll("dmg: %d back hp: %d",dmg,ConduitSubtractDamage[attacker]);
				new heal=ConduitSubtractDamage[attacker]-dmg;
				if(heal>ConduitMaxHeal[War3_GetSkillLevel(ConduitBy[attacker],thisRaceID,SKILL_CONDUIT)])
				{
					heal=ConduitMaxHeal[War3_GetSkillLevel(ConduitBy[attacker],thisRaceID,SKILL_CONDUIT)];
				}
				War3_HealToBuffHP(victim,ConduitSubtractDamage[attacker]);
#if GGAMETYPE == GGAME_TF2
				if(heal>=0){
					decl Float:pos[3];
					GetClientEyePosition(victim, pos);
					pos[2] += 4.0;
					War3_TF_ParticleToClient(0, "miss_text", pos); //to the attacker at the enemy pos
				}
#endif
			}
		}

		new race_victim=War3_GetRace(victim);
		if(race_victim==thisRaceID){
			new skill = War3_GetSkillLevel(victim,thisRaceID,SKILL_STATIC);
			if(!Hexed(victim,false)){
				new heal=RoundFloat(StaticHealPercent[skill]*dmg);
				new team=GetClientTeam(victim);

				new Float:pos[3];
				GetClientAbsOrigin(victim,pos);
				new Float:otherVec[3];
				for(new i=1;i<=MaxClients;i++)
				{
					if(ValidPlayer(i,true)&&GetClientTeam(i)!=team)
					{
						GetClientAbsOrigin(i,otherVec);
						if(GetVectorDistance(pos,otherVec)<StaticHealRadius){
							War3_HealToBuffHP(i,heal);
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}




public Action:CalcConduit(Handle:timer,any:userid)
{
	new Float:time = GetGameTime();
	for(new i=1;i<=MaxClients;i++){
		if(time>ConduitUntilTime[i] && ConduitUntilTime[i]!=0.0){
			if(ValidPlayer(ConduitBy[i]))
			{
				War3_NotifyPlayerSkillActivated(ConduitBy[i], SKILL_CONDUIT,false);
			}
			ConduitUntilTime[i]=0.0;
			ConduitSubtractDamage[i]=0;
			ConduitBy[i]=0;
		}
	}
}
public OnClientPutInServer(i){
	ConduitBy[i]=0;
	ConduitUntilTime[i]=0.0;
	ConduitSubtractDamage[i]=0;
}


//
#if GGAMETYPE == GGAME_TF2
public OnW3SupplyLocker(client)
{
	if(RaceDisabled)
		return;

	if(ValidPlayer(client))
	{
		ConduitBy[client]=0;
		ConduitUntilTime[client]=0.0;
		ConduitSubtractDamage[client]=0;
	}
}
#endif

public OnW3HealthPickup(const String:output[], caller, activator, Float:delay)
{
	if(RaceDisabled)
		return;

	if(ValidPlayer(activator))
	{
		ConduitBy[activator]=0;
		ConduitUntilTime[activator]=0.0;
		ConduitSubtractDamage[activator]=0;
	}
}
