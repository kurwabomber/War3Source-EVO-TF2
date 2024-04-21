/**
 * File: War3Source_Warden.sp
 * Description: The Warden race for War3Source.
 * Author(s): Anthony Iacono & Ownage | Ownz (DarkEnergy)
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <war3source>
public W3ONLY(){} //unload this?
new thisRaceID;
#define RACE_ID_NUMBER 7
#define RACE_LONGNAME "Warden"
#define RACE_SHORTNAME "warden"

bool HooksLoaded = false;
public void Load_Hooks()
{
	if(HooksLoaded) return;
	HooksLoaded = true;

	W3Hook(W3Hook_OnUltimateCommand, OnUltimateCommand);
	W3Hook(W3Hook_OnWar3EventSpawn, OnWar3EventSpawn);
	W3Hook(W3Hook_OnW3TakeDmgBullet, OnW3TakeDmgBullet);
}
public void UnLoad_Hooks()
{
	if(!HooksLoaded) return;
	HooksLoaded = false;

	W3Unhook(W3Hook_OnUltimateCommand, OnUltimateCommand);
	W3Unhook(W3Hook_OnW3TakeDmgBullet, OnW3TakeDmgBullet);
	W3Unhook(W3Hook_OnWar3EventSpawn, OnWar3EventSpawn);
}

//skill 1
new Float:FanOfKnivesTFChanceArr[]={0.08,0.09,0.1,0.11,0.12};
new const KnivesTFDamage = 50; 
new const Float:KnivesTFRadius = 300.0;
 
//skill 2
new Float:UltimateResistance[]={0.5, 0.45, 0.40, 0.375, 0.35};

//skill 3
new const ShadowStrikeInitialDamage=20;
new const ShadowStrikeTrailingDamage=5;
new Float:ShadowStrikeChanceArr[]={0.2,0.225,0.275,0.325,0.35};
new ShadowStrikeTimes[]={5,5,6,6,7};
new BeingStrikedBy[MAXPLAYERSCUSTOM];
new StrikesRemaining[MAXPLAYERSCUSTOM];

//ultimate
new Handle:ultCooldownCvar;

new Float:VengenceTFHealHPPercent[]={1.0,1.1,1.2,1.3,1.5};

#define IMMUNITYBLOCKDISTANCE 300.0


new SKILL_FANOFKNIVES, SKILL_BLINK,SKILL_SHADOWSTRIKE,ULT_VENGENCE;

new String:shadowstrikestr[]="war3source/shadowstrikebirth.mp3";
new String:ultimateSound[]="war3source/MiniSpiritPissed1.mp3";

new BeamSprite;
new HaloSprite;

public Plugin:myinfo =
{
	name = "Race - Warden",
	author = "PimpinJuice & Ownz (DarkEnergy)",
	description = "The Warden race for War3Source.",
	version = "1.0.0.0",
	url = "http://Www.OwnageClan.Com"
};
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
public OnPluginStart()
{
	
	ultCooldownCvar=CreateConVar("war3_warden_vengence_cooldown","20","Cooldown between Warden Vengence (ultimate)");
	
	CreateTimer(0.2,CalcBlink,_,TIMER_REPEAT);

	//LoadTranslations("w3s.race.warden.phrases");
}

public OnWar3LoadRaceOrItemOrdered2(num,reloadrace_id,String:shortname[])
{
	if(num==RACE_ID_NUMBER||(reloadrace_id>0&&StrEqual(RACE_SHORTNAME,shortname,false)))
	{
		thisRaceID=War3_CreateNewRace(RACE_LONGNAME,RACE_SHORTNAME,reloadrace_id,"Ult Immunity, healing.");
		SKILL_FANOFKNIVES=War3_AddRaceSkill(thisRaceID,"Fan Of Knives","Deals 50 damage to attacker. 8-12% chance to proc.",false,4);
		SKILL_BLINK=War3_AddRaceSkill(thisRaceID,"Immunity","25% Immunity chance per level.",false,4);
		SKILL_SHADOWSTRIKE=War3_AddRaceSkill(thisRaceID,"Shadow Strike","Chance to deal initial 20 damage and 5 aftertime damage.\nDOT attacks 5-7 times and has a 20-35% chance to proc.",false,4);
		ULT_VENGENCE=War3_AddRaceSkill(thisRaceID,"Vengence","When used: Heals for 100% to 150% of your max health. Cooldown is 20 seconds.",true,4);
		War3_CreateRaceEnd(thisRaceID);
	
	}
}
public OnAllPluginsLoaded()
{
	War3_RaceOnPluginStart(RACE_SHORTNAME);
}

public OnPluginEnd()
{
	if(LibraryExists("RaceClass"))
		War3_RaceOnPluginEnd(RACE_SHORTNAME);
}
public OnMapStart()
{
	PrecacheSound(shadowstrikestr);
	PrecacheSound(ultimateSound);
	BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();
}
public OnAddSound(sound_priority)
{
	if(sound_priority==PRIORITY_MEDIUM)
	{
		War3_AddSound(shadowstrikestr);
		War3_AddSound(ultimateSound);
	}
}
public OnWar3EventSpawn(client){
	StrikesRemaining[client]=0;
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{	
		War3_SetBuff(client,fUltimateResistance,thisRaceID,1.0);
	}

}


public OnUltimateCommand(client,race,bool:pressed)
{
	// TODO: Increment UltimateUsed[client]
	if(race==thisRaceID && pressed && IsPlayerAlive(client))
	{
		new ult_level=War3_GetSkillLevel(client,race,ULT_VENGENCE);
		if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_VENGENCE,true))
		{
			if(!blockingVengence(client))
			{
				new maxhp=War3_GetMaxHP(client);
			
				new heal=RoundToCeil(float(maxhp)*VengenceTFHealHPPercent[ult_level]);
				War3_HealToBuffHP(client,heal);
				W3FlashScreen(client,{0,255,0,20},0.5,_,FFADE_OUT);
				
				War3_EmitSoundToAll(ultimateSound,client);
				War3_EmitSoundToAll(ultimateSound,client);
				
				War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_VENGENCE,_,_);
				
			}
			else
			{
				W3MsgUltimateBlocked(client);
			}
		}
	}
}



public Action OnW3TakeDmgBullet(int victim, int attacker, float damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		if(ValidPlayer(attacker,true) && ValidPlayer(victim,true))
		{
			if(GetClientTeam(victim)==GetClientTeam(attacker))
			{
				return Plugin_Continue;
			}
		}
		if(IsValidEntity(victim)&&ValidPlayer(attacker,false))
		{
			//VICTIM IS WARDEN!!! 
			if(War3_GetRace(victim)==thisRaceID)
			{
				new Float:chance_mod=W3ChanceModifier(attacker);
				
				/// CHANCE MOD BY ATTACKER
				new skill_level = War3_GetSkillLevel(victim,thisRaceID,SKILL_FANOFKNIVES);
				if(!W3HasImmunity(victim,Immunity_Skills) && !Hexed(victim,false)&&GetRandomFloat(0.0,1.0)<=chance_mod*FanOfKnivesTFChanceArr[skill_level])
				{
					//knives damage hp around the victim
					W3MsgThrewKnives(victim);
					new Float:playerVec[3];
					GetClientAbsOrigin(victim,playerVec);

					playerVec[2]+=20;
					TE_SetupBeamRingPoint(playerVec, 10.0, KnivesTFRadius, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 10.0, {255,255,255,155}, 100, 0);
					TE_SendToAll();
					playerVec[2]-=20;

					new Float:otherVec[3];
					new team = GetClientTeam(victim);
					for(new i=1;i<=MaxClients;i++)
					{
						if(ValidPlayer(i,true)&&GetClientTeam(i)!=team && !W3HasImmunity(victim,Immunity_Skills))
						{
							GetClientAbsOrigin(i,otherVec);
							if(GetVectorDistance(playerVec,otherVec)<KnivesTFRadius)
							{
								float resistance = W3GetBuffStackedFloat(i, fAbilityResistance);

								if(War3_DealDamage(i,RoundFloat(resistance*KnivesTFDamage),victim,DMG_BULLET,"knives",W3DMGORIGIN_SKILL,W3DMGTYPE_MAGIC))
								{
									W3FlashScreen(i,RGBA_COLOR_RED);
									W3MsgHitByKnives(i);
									decl Float:StartPos[3];
									GetClientAbsOrigin(victim,StartPos);
									StartPos[2]+=40;
									TE_SetupBeamRingPoint(StartPos, 150.0, 10.0, BeamSprite, HaloSprite, 0, 10, 0.8, 20.0, 0.0, {255,50,130,255}, 1600, FBEAM_SINENOISE);
									TE_SendToAll();
									TE_SetupBeamRingPoint(StartPos, 150.0, 10.0, BeamSprite, HaloSprite, 0, 10, 0.8, 20.0, 0.0, {255,50,130,255}, 1600, FBEAM_SINENOISE);
									TE_SendToAll(0.3);
									TE_SetupBeamRingPoint(StartPos, 150.0, 10.0, BeamSprite, HaloSprite, 0, 10, 0.8, 20.0, 0.0, {255,50,130,255}, 1600, FBEAM_SINENOISE);
									TE_SendToAll(0.6);
									TE_SetupBeamRingPoint(StartPos, 10.0, 200.0, BeamSprite, HaloSprite, 0, 10, 0.5, 20.0, 0.0, {255,50,130,255}, 1600, FBEAM_SINENOISE);
									TE_SendToAll(0.8);
								}
								else {
									W3MsgSkillBlocked(i,_,"Knives");
								}
							}
						}
					}
				}
			}
			//ATTACKER IS WARDEN
			if(War3_GetRace(attacker)==thisRaceID)
			{
				//shadow strike poison
				new Float:chance_mod=W3ChanceModifier(attacker);
				/// CHANCE MOD BY VICTIM
				new skill_level = War3_GetSkillLevel(attacker,thisRaceID,SKILL_SHADOWSTRIKE);
				if(StrikesRemaining[victim]==0 && !Hexed(attacker,false)&&GetRandomFloat(0.0,1.0)<=chance_mod*ShadowStrikeChanceArr[skill_level])
				{
					if(W3HasImmunity(victim,Immunity_Skills))
					{
						W3MsgSkillBlocked(victim,attacker,"Shadow Strike");
					}
					else
					{
						W3MsgAttackedBy(victim,"Shadow Strike");
						W3MsgActivated(attacker,"Shadow Strike");
						
						BeingStrikedBy[victim]=attacker;
						StrikesRemaining[victim]=ShadowStrikeTimes[skill_level];

						float resistance = W3GetBuffStackedFloat(victim, fAbilityResistance);
						War3_DealDamage(victim,RoundFloat(resistance*ShadowStrikeInitialDamage),attacker,DMG_BULLET,"shadowstrike");
						W3FlashScreen(victim,RGBA_COLOR_RED);
						
						War3_EmitSoundToAll(shadowstrikestr,attacker);
						War3_EmitSoundToAll(shadowstrikestr,attacker);
						CreateTimer(1.0,ShadowStrikeLoop,GetClientUserId(victim));
					}
				}
			}
		}
	}
	return Plugin_Continue;
}
public Action:ShadowStrikeLoop(Handle:timer,any:userid)
{
	new victim = GetClientOfUserId(userid);
	if(StrikesRemaining[victim]>0 && ValidPlayer(BeingStrikedBy[victim]) && ValidPlayer(victim,true))
	{
		float resistance = W3GetBuffStackedFloat(victim, fAbilityResistance);
		War3_DealDamage(victim,RoundFloat(resistance*ShadowStrikeTrailingDamage),BeingStrikedBy[victim],DMG_BULLET,"shadowstrike");
		StrikesRemaining[victim]--;
		W3FlashScreen(victim,RGBA_COLOR_RED);
		CreateTimer(1.0,ShadowStrikeLoop,userid);
		decl Float:StartPos[3];
		GetClientAbsOrigin(victim,StartPos);
		TE_SetupDynamicLight(StartPos,255,255,100,100,100.0,0.3,3.0);
		TE_SendToAll();
	}
}
public Action:CalcBlink(Handle:timer,any:userid)
{
	if(thisRaceID>0)
	{
		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true)&&War3_GetRace(i)==thisRaceID)
			{
				War3_SetBuff(i,fUltimateResistance,thisRaceID, UltimateResistance[War3_GetSkillLevel(i,thisRaceID,SKILL_BLINK)] );
			}
		}
	}
}

public bool:blockingVengence(client)  //TF2 only
{
	//ELIMINATE ULTIMATE IF THERE IS IMMUNITY AROUND
	new Float:playerVec[3];
	GetClientAbsOrigin(client,playerVec);
	new Float:otherVec[3];
	new team = GetClientTeam(client);

	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true)&&GetClientTeam(i)!=team)
		{
			GetClientAbsOrigin(i,otherVec);
			float resistance = W3GetBuffStackedFloat(i, fUltimateResistance);
			if(W3HasImmunity(i,Immunity_Ultimates)){
				if(GetVectorDistance(playerVec,otherVec)<IMMUNITYBLOCKDISTANCE)
					return true;
			}
			else if(resistance != 1.0){
				if(GetVectorDistance(playerVec, otherVec)<IMMUNITYBLOCKDISTANCE*(1-resistance))
					return true;
			}
		}
	}
	return false;
}