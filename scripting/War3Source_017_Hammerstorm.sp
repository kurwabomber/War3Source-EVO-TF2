#include <war3source>
#assert GGAMEMODE == MODE_WAR3SOURCE

#define RACE_ID_NUMBER 17

//#pragma semicolon 1	///WE RECOMMEND THE SEMICOLON

//#include <sourcemod>
//#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo =
{
	name = "Race - Hammerstorm",
	author = "Glider",
	description = "Hammerstorm (The Rogue Knight) race for War3Source.",
	version = "1.2",
};
public W3ONLY(){} //unload this?
/* Changelog
 * 1.2 - Fixed speed buff not being removed on race switch
 */

new thisRaceID;

bool HooksLoaded = false;
public void Load_Hooks()
{
	if(HooksLoaded) return;
	HooksLoaded = true;

	W3Hook(W3Hook_OnW3TakeDmgBulletPre, OnW3TakeDmgBulletPre);
	W3Hook(W3Hook_OnW3TakeDmgBullet, OnW3TakeDmgBullet);
	W3Hook(W3Hook_OnUltimateCommand, OnUltimateCommand);
	W3Hook(W3Hook_OnAbilityCommand, OnAbilityCommand);
	W3Hook(W3Hook_OnWar3EventSpawn, OnWar3EventSpawn);
}
public void UnLoad_Hooks()
{
	if(!HooksLoaded) return;
	HooksLoaded = false;

	W3Unhook(W3Hook_OnW3TakeDmgBulletPre, OnW3TakeDmgBulletPre);
	W3Unhook(W3Hook_OnW3TakeDmgBullet, OnW3TakeDmgBullet);
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

		UnLoad_Hooks();
	}
}
//	if(RaceDisabled)
//		return;

new SKILL_BOLT, SKILL_CLEAVE, SKILL_WARCRY, ULT_STRENGTH;

// Tempents
new g_BeamSprite;
new g_HaloSprite;

// Storm Bolt
new BoltDamage[] = {40,45,50,55,60};
new Float:BoltRange[]={225.0,250.0,275.0,300.0,325.0};
new Float:BoltStunDuration=0.4;
new Float:StormCooldownTime=15.0;


new const StormCol[4] = {255, 255, 255, 155}; // Color of the beacon



// Cleave Multiplayer
new Float:CleaveDistance=200.0;
new Float:CleaveMultiplier[] = {0.2,0.22,0.24,0.26,0.28};

// Warcry Buffs
new Float:WarcrySpeed[]={1.15,1.175,1.2,1.225,1.250};
new Float:WarcryArmor[]={1.8,1.9,2.0,2.1,2.2};

// Gods Strength
new Float:GodsStrength[]={1.50,1.55,1.6,1.65,1.7};
new bool:bStrengthActivated[MAXPLAYERSCUSTOM];
new Handle:ultCooldownCvar; // cooldown

// Sounds
new String:hammerboltsound[] = "war3source/hammerstorm/stun.mp3";
new String:ultsnd[] = "war3source/hammerstorm/ult.mp3";

public OnWar3LoadRaceOrItemOrdered2(num,reloadrace_id,String:shortname[])
{
	if(num==RACE_ID_NUMBER||(reloadrace_id>0&&StrEqual("hammerstorm",shortname,false)))
	{
		thisRaceID=War3_CreateNewRace("Hammerstorm","hammerstorm",reloadrace_id,"Lightning, dmg & armor.");
		SKILL_BOLT=War3_AddRaceSkill(thisRaceID,"Storm Bolt","(+Ability) Stuns enemies in 225 to 325 radius\nfor 0.4 seconds, deals 40 to 60 damage",false,4, "(voice Help!)");
		SKILL_CLEAVE=War3_AddRaceSkill(thisRaceID,"Great Cleave","Your attacks splash 20 to 28 percent\ndamage to enemys within 200 units",false,4);
		SKILL_WARCRY=War3_AddRaceSkill(thisRaceID,"Warcry","Gain 1.8 to 2.2 physical armor,\nincreases your speed by 15 to 25 percent",false,4);
		ULT_STRENGTH=War3_AddRaceSkill(thisRaceID,"Gods Strength","Greatly enhance your damage by 50 to 70 percent for a short amount of time.\nChannels for 0.75 seconds before usage.",true,4,"(voice Jeers)");
		War3_CreateRaceEnd(thisRaceID);

		War3_AddSkillBuff(thisRaceID, SKILL_WARCRY, fMaxSpeed, WarcrySpeed);
		War3_AddSkillBuff(thisRaceID, SKILL_WARCRY, fArmorPhysical, WarcryArmor);
	}
}
public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		War3_SetBuff(client,fArmorPhysical,thisRaceID,0.0);
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
	}
}
public OnPluginStart()
{
	ultCooldownCvar=CreateConVar("war3_hammerstorm_strength_cooldown","20","Cooldown timer.");
	//LoadTranslations("w3s.race.hammerstorm.phrases");
}
public OnAllPluginsLoaded()
{
	War3_RaceOnPluginStart("hammerstorm");
}

public OnPluginEnd()
{
	if(LibraryExists("RaceClass"))
		War3_RaceOnPluginEnd("hammerstorm");
}

public OnMapStart()
{
	UnLoad_Hooks();

	//strcopy(hammerboltsound,sizeof(hammerboltsound),"war3source/hammerstorm/stun.mp3");
	//strcopy(ultsnd,sizeof(ultsnd),"war3source/hammerstorm/ult.mp3");

	// Precache the stuff for the beacon ring
	g_BeamSprite = War3_PrecacheBeamSprite();
	g_HaloSprite = War3_PrecacheHaloSprite();
	//Sounds
	PrecacheSound(hammerboltsound);
	PrecacheSound(ultsnd);
}

public OnAddSound(sound_priority)
{
	if(sound_priority==PRIORITY_MEDIUM)
	{
		War3_AddSound(hammerboltsound);
		War3_AddSound(ultsnd);
	}
}


public void OnWar3EventSpawn (int client)
{
	bStrengthActivated[client] = false;
#if GGAMETYPE != GGAME_CSGO
	W3ResetPlayerColor(client, thisRaceID);
#endif
}

public Action OnW3TakeDmgBulletPre(int victim, int attacker, float damage, int damagecustom)
{
	if(RaceDisabled)
		return Plugin_Continue;

	if(ValidPlayer(attacker,true) && ValidPlayer(victim,true))
	{
		if(GetClientTeam(victim)==GetClientTeam(attacker))
		{
			return Plugin_Continue;
		}
	}
	if(IsValidEntity(victim)&&ValidPlayer(attacker,false))
	{
		if(War3_GetRace(attacker)==thisRaceID &&!W3HasImmunity(victim,Immunity_Ultimates))
		{
			new skilllvl;
			if(bStrengthActivated[attacker])
			{
				// GODS STRENGTH!
				skilllvl = War3_GetSkillLevel(attacker,thisRaceID,ULT_STRENGTH);
				War3_DamageModPercent(1+(GodsStrength[skilllvl]-1)*W3GetBuffStackedFloat(victim, fUltimateResistance));
			}
		}
	}
	return Plugin_Changed;
}

public Action OnW3TakeDmgBullet(int victim, int attacker, float damage)
{
	if(RaceDisabled)
		return Plugin_Continue;

	if(ValidPlayer(victim,true)&&ValidPlayer(attacker,false)&&GetClientTeam(victim)!=GetClientTeam(attacker))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			// Cleave
			new skilllvl = War3_GetSkillLevel(attacker,thisRaceID,SKILL_CLEAVE);
			float splashdmg = damage * CleaveMultiplier[skilllvl];
			new Float:dist = CleaveDistance;
			new AttackerTeam = GetClientTeam(attacker);
			new Float:OriginalVictimPos[3];
			GetClientAbsOrigin(victim,OriginalVictimPos);
			new Float:VictimPos[3];

			if(attacker>0)
			{
				for(new i=1;i<=MaxClients;i++)
				{
					if(ValidPlayer(i,true)&&(GetClientTeam(i)!=AttackerTeam)&&(victim!=i)&&!W3HasImmunity(i,Immunity_Skills))
					{
						GetClientAbsOrigin(i,VictimPos);
						if(GetVectorDistance(OriginalVictimPos,VictimPos)<=dist)
						{
							int dmg = RoundFloat(splashdmg*W3GetBuffStackedFloat(i, fAbilityResistance))
							if(War3_DealDamage(i,dmg,attacker,_,"greatcleave"))
							{
								//W3PrintSkillDmgConsole(i,attacker,War3_GetWar3DamageDealt(),SKILL_CLEAVE);
								War3_NotifyPlayerTookDamageFromSkill(i, attacker, dmg, SKILL_CLEAVE);
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public void OnAbilityCommand(int client, int ability, bool pressed, bool bypass)
{
	if(RaceDisabled)
		return;

	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new skilllvl = War3_GetSkillLevel(client,thisRaceID,SKILL_BOLT);
		if(!Silenced(client)&&(bypass||War3_SkillNotInCooldown(client,thisRaceID,SKILL_BOLT,true)))
		{
			new damage = BoltDamage[skilllvl];
			new Float:AttackerPos[3];
			GetClientAbsOrigin(client,AttackerPos);
			new AttackerTeam = GetClientTeam(client);
			new Float:VictimPos[3];

			TE_SetupBeamRingPoint(AttackerPos, 10.0, BoltRange[skilllvl]*2.0, g_BeamSprite, g_HaloSprite, 0, 25, 0.5, 5.0, 0.0, StormCol, 10, 0);
			TE_SendToAll();
			AttackerPos[2]+=10.0;
			TE_SetupBeamRingPoint(AttackerPos, 10.0, BoltRange[skilllvl]*2.0, g_BeamSprite, g_HaloSprite, 0, 25, 0.5, 5.0, 0.0, StormCol, 10, 0);
			TE_SendToAll();

			War3_EmitSoundToAll(hammerboltsound,client);
			War3_EmitSoundToAll(hammerboltsound,client);

			for(new i=1;i<=MaxClients;i++)
			{
				if(ValidPlayer(i,true)){
					GetClientAbsOrigin(i,VictimPos);
					if(GetVectorDistance(AttackerPos,VictimPos)<BoltRange[skilllvl])
					{
						if(GetClientTeam(i)!=AttackerTeam)
						{
							if(!W3HasImmunity(i,Immunity_Skills))
							{
								if(War3_DealDamage(i,RoundFloat(damage*W3GetBuffStackedFloat(i, fAbilityResistance)),client,DMG_GENERIC,"stormbolt",W3DMGORIGIN_SKILL))
								{
									//W3PrintSkillDmgConsole(i,client,War3_GetWar3DamageDealt(),SKILL_BOLT);
									War3_NotifyPlayerTookDamageFromSkill(i, client, War3_GetWar3DamageDealt(), SKILL_BOLT);
								}

								W3SetPlayerColor(i,thisRaceID, StormCol[0], StormCol[1], StormCol[2], StormCol[3]);
								War3_SetBuff(i,bStunned,thisRaceID,true);

								W3FlashScreen(i,RGBA_COLOR_RED);
								CreateTimer(BoltStunDuration*W3GetBuffStackedFloat(i, fAbilityResistance),UnstunPlayer,i);

								PrintHintText(i,"You were stunned by Storm Bolt");
							}
							else
							{
								War3_NotifyPlayerImmuneFromSkill(client, i, SKILL_BOLT);
							}

						}
					}
				}
			}
			//War3_EmitSoundToAll(hammerboltsound,client);
			War3_CooldownMGR(client,StormCooldownTime,thisRaceID,SKILL_BOLT);
		}
	}
}

public Action:UnstunPlayer(Handle:timer,any:client)
{
	War3_SetBuff(client,bStunned,thisRaceID,false);
	W3ResetPlayerColor(client, thisRaceID);
}

public void OnUltimateCommand(int client, int race, bool pressed, bool bypass)
{
	if(RaceDisabled)
		return;

	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_STRENGTH,true ))
		{
			if(!War3_IsInSpawn(client))
			{
				War3_CastSpell(client, 0, SpellEffectsLight, SPELLCOLOR_RED, thisRaceID, ULT_STRENGTH, 0.75);
				War3_CooldownMGR(client,20.0,thisRaceID,ULT_STRENGTH,false,true);
			}
			else
			{
				War3_ChatMessage(client,"You can not be in spawn to cast this spell!");
			}
		}
	}
}


public Action:stopUltimate(Handle:t,any:client){
	bStrengthActivated[client] = false;
	War3_NotifyPlayerSkillActivated(client,ULT_STRENGTH,false);
	if(ValidPlayer(client,true)){
		PrintHintText(client,"You feel less powerful");
	}
}



//====================================================================================
//						OnWar3CastingFinished
//====================================================================================
public OnWar3CastingFinished(client, target, W3SpellEffects:spelleffect, String:SpellColor[], raceid, skillid)
{
	//DP("casting finished");
	if(ValidPlayer(client,true) && raceid==thisRaceID)
	{
		if(skillid == ULT_STRENGTH)
		{
			War3_EmitSoundToAll(ultsnd,client);
			War3_EmitSoundToAll(ultsnd,client);
			PrintHintText(client,"The gods lend you their strength");
			bStrengthActivated[client] = true;
			CreateTimer(5.0,stopUltimate,client);
			War3_NotifyPlayerSkillActivated(client,ULT_STRENGTH,true);

			//War3_EmitSoundToAll(ultsnd,client);
			War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_STRENGTH);
		}
	}
}


//====================================================================================
//						OnWar3CancelSpell_Post
//====================================================================================
public OnWar3CancelSpell_Post(client, raceid, skillid, target)
{
	if(ValidPlayer(client,true) && raceid==thisRaceID)
	{
		if(skillid == ULT_STRENGTH)
		{
			War3_CooldownMGR(client,20.0,thisRaceID,ULT_STRENGTH,false,true);
		}
	}
}
