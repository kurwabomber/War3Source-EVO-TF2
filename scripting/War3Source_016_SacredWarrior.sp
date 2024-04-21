#include <war3source>
#assert GGAMEMODE == MODE_WAR3SOURCE

#define RACE_ID_NUMBER 16

//#pragma semicolon 1    ///WE RECOMMEND THE SEMICOLON

//#include <sourcemod>
//#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo =
{
	name = "Race - Sacred Warrior",
	author = "Glider / modified by Ownz (DarkEnergy)",
	description = "The Sacred Warrior race for War3Source.",
	version = "1.1",
};

new thisRaceID;

bool HooksLoaded = false;
public void Load_Hooks()
{
	if(HooksLoaded) return;
	HooksLoaded = true;

	W3Hook(W3Hook_OnW3TakeDmgBullet, OnW3TakeDmgBullet);
	W3Hook(W3Hook_OnUltimateCommand, OnUltimateCommand);
	W3Hook(W3Hook_OnAbilityCommand, OnAbilityCommand);
	W3Hook(W3Hook_OnWar3EventSpawn, OnWar3EventSpawn);
}
public void UnLoad_Hooks()
{
	if(!HooksLoaded) return;
	HooksLoaded = false;

	W3Unhook(W3Hook_OnW3TakeDmgBullet, OnW3TakeDmgBullet);
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

//public W3ONLY(){} //unload this?
new SKILL_VITALITY, SKILL_SPEAR, SKILL_BLOOD, ULT_BREAK; //,IMPROVED_ULT_BREAK;

// Inner Vitality, HP healed
new Float:VitalityHealed[]={4.5, 5.0, 5.5, 6.0}; // How much HP Vitality heals each second

// Burning Spear stacking effect
new SpearDamage[]={4,5,6,7,8}; // How much damage does a stack do?
new MaxSpearStacks=5; // How many stacks can the attacker dish out?
//new Float:SpearUntil[MAXPLAYERSCUSTOM]; // Until when is the victim affected?
new VictimSpearStacks[MAXPLAYERSCUSTOM]; // How many stacks does the victim have?
new VictimSpearTicks[MAXPLAYERSCUSTOM];
//new bool:bSpeared[MAXPLAYERSCUSTOM]; // Is this player speared (has DoT on him)?
new SpearedBy[MAXPLAYERSCUSTOM]; // Who was the victim speared by?
new bool:bSpearActivated[MAXPLAYERSCUSTOM]; // Does the player have Burning Spear activated?

// Buffs that berserker applys
//new Float:BerserkerBuffDamage[]={0.0,0.005,0.01,0.015,0.02};  // each 7% you add one of these
new Float:BerserkerBuffASPD[]={0.04, 0.045, 0.05, 0.055, 0.06};      // to get the total buff...

// Life Break costs / damage dealt
new Float:LifeBreakHPVictim[]={0.50, 0.525, 0.55, 0.575, 0.6};
new Float:LifeBreakHPCaster[]={0.3, 0.275, 0.25, 0.225, 0.2};


new Handle:ultCooldownCvar;
new Float:ultmaxdistance = 600.0;
public OnPluginStart()
{

	CreateTimer(0.3,BerserkerCalculateTimer,_,TIMER_REPEAT);      // Berserker ASPD Buff timer
	CreateTimer(1.0,Heal_BurningSpearTimer,_,TIMER_REPEAT);  // Burning Spear DoT Timer
	//LoadTranslations("w3s.race.sacredw.phrases");
	ultCooldownCvar=CreateConVar("war3_sacredw_ult_cooldown","20","Cooldown time for ult.");
}

/* ***************************	OnMapStart *************************************/

public OnMapStart()
{
	UnLoad_Hooks();
	PrecacheSound("buttons/button2.wav");
}

public OnWar3LoadRaceOrItemOrdered2(num,reloadrace_id,String:shortname[])
{
	if(num==RACE_ID_NUMBER||(reloadrace_id>0&&StrEqual("sacredw",shortname,false)))
	{
		thisRaceID=War3_CreateNewRace("Sacred Warrior","sacredw",reloadrace_id,"Rage & regeneration");
		SKILL_VITALITY=War3_AddRaceSkill(thisRaceID,"Inner Vitality","Passively recover 1 to 6HP per second.\nWhen below 40% you heal twice as fast.",false,4);
		SKILL_SPEAR=War3_AddRaceSkill(thisRaceID,"Burning Spear","(+ability) Passively lose 5% maxHP, but set enemies ablaze.\nDeals 1 to 8 DPS for next 3 seconds.\nStacks 5 times.",false,4);
		SKILL_BLOOD=War3_AddRaceSkill(thisRaceID,"Berserkers Blood","Gain 1 to 6 percent attack speed for each 7 percent of your health missing",false,4);
		ULT_BREAK=War3_AddRaceSkill(thisRaceID,"Life Break","(+ultimate) Damage yourself (30% to 20% of maxHP) to deal\na great amount of damage (50% to 60% of victim's currentHP)",true,4);
		War3_CreateRaceEnd(thisRaceID); ///DO NOT FORGET THE END!!!
	}
}
public OnAllPluginsLoaded()
{
	War3_RaceOnPluginStart("sacredw");
}

public OnPluginEnd()
{
	if(LibraryExists("RaceClass"))
		War3_RaceOnPluginEnd("sacredw");
}
public void OnWar3EventSpawn (int client)
{
	War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
	VictimSpearStacks[client] = 0;  // deactivate Burning Spear
	VictimSpearTicks[client] = 0;
	bSpearActivated[client] = false;  // on spawn
	CheckSkills(client);
}

public Action:Heal_BurningSpearTimer(Handle:h,any:data) //1 sec
{
	if(RaceDisabled)
		return Plugin_Continue;

	new attacker;
	new damage;
	//new SelfDamage;
	new skill;
	for(new i=1;i<=MaxClients;i++) // Iterate over all clients
	{
		if(ValidPlayer(i,true))
		{
			if(War3_GetRace(i)==thisRaceID){
				CheckSkills(i);
			}
		//	if(bSpearActivated[i]) // Client has Burning Spear activated
		//	{
		//		SelfDamage = RoundToCeil(War3_GetMaxHP(i) * 0.05);
		//		War3_DealDamage(i,SelfDamage,i,_,"burningspear"); // damage the client for having it activated
		//	}

			if(VictimSpearTicks[i] >0)
			{
				attacker = SpearedBy[i];
				skill = War3_GetSkillLevel(attacker, thisRaceID, SKILL_SPEAR);
				if(ValidPlayer(attacker, true)&&bSpearActivated[attacker]) // Attacker has Burning Spear activated
				{
					damage = RoundFloat(VictimSpearStacks[i] * SpearDamage[skill] * W3GetBuffStackedFloat(i, fAbilityResistance)); // Number of stacks on the client * damage of the attacker

					War3_DealDamage(i,damage,attacker,_,"bleed_kill"); // Bleeding Icon
					VictimSpearTicks[i]--;
				}
				else{
					VictimSpearTicks[i]=0; //attacker deactivated spears
				}
				if(VictimSpearTicks[i]==0){ //last tick
					VictimSpearStacks[i]=0; // Reset stacks
				}
			}
		}
	}
	return Plugin_Continue;
}


public Action:BerserkerCalculateTimer(Handle:timer,any:userid) // Check each 0.5 second if the conditions for Berserkers Blood have changed
{
	if(RaceDisabled)
		return Plugin_Continue;

	if(thisRaceID>0)
	{
		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true))
			{
				if(War3_GetRace(i)==thisRaceID)
				{
					new client=i;


					new Float:ASPD;

					new skilllvl = War3_GetSkillLevel(client,thisRaceID,SKILL_BLOOD);
					new VictimCurHP = GetClientHealth(client);
					new MaxHP=War3_GetMaxHP(client);
					if(VictimCurHP>=MaxHP){
						ASPD=1.0;
					}
					else{
						new missing=MaxHP-VictimCurHP;
						new Float:percentmissing=float(missing)/float(MaxHP);
						ASPD=1.0+BerserkerBuffASPD[skilllvl]*(percentmissing/0.07);
					}
					//PrintToChat(client,"%f",ASPD);
					War3_SetBuff(client,fAttackSpeed,thisRaceID,ASPD); // Set the buff
				}
			}
		}
	}
	return Plugin_Continue;
}


public Action OnW3TakeDmgBullet(int victim, int attacker, float damage)
{
	if(RaceDisabled)
		return Plugin_Continue;

	if(ValidPlayer(victim,true)&&ValidPlayer(attacker,false)&&GetClientTeam(victim)!=GetClientTeam(attacker))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			// Apply Blood buff
			if(!Hexed(attacker)){
				if(W3Chance(W3ChanceModifier(attacker))){
					if(!W3HasImmunity(attacker,Immunity_Skills))
					{
						if(VictimSpearStacks[victim]<MaxSpearStacks){
							VictimSpearStacks[victim]++; //stack if less than max stacks
						}
						VictimSpearTicks[victim] =3 ; //always three ticks

						SpearedBy[victim] = attacker;

					}
					else
					{
						War3_NotifyPlayerImmuneFromSkill(victim, attacker, SKILL_SPEAR);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}
public void OnSkillLevelChanged(int client, int currentrace, int skill, int newskilllevel, int oldskilllevel)
{
	if(RaceDisabled)
		return;

	if(currentrace==thisRaceID)
	{
		if(skill==SKILL_VITALITY) //1
		{
			int VictimCurHP = GetClientHealth(client);
			int VictimMaxHP = War3_GetMaxHP(client);
			float DoubleTrigger = VictimMaxHP * 0.4;

			if(bSpearActivated[client])
			{
				War3_SetBuff(client,fHPDecay,thisRaceID,VictimMaxHP*0.03);
			}
			else
			{
				//level 0 is fine
				War3_SetBuff(client,fHPRegen,thisRaceID,  (VictimCurHP<=DoubleTrigger)  ?  VitalityHealed[newskilllevel]*2.0: VitalityHealed[newskilllevel] );
				War3_SetBuff(client,fHPDecay,thisRaceID,0.0);
			}
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
	CheckSkills(client);
}

public RemovePassiveSkills(client)
{
	//War3_SetBuff(client,fArmorPhysical,thisRaceID,0.0);
	//War3_SetBuff(client,fArmorMagic,thisRaceID,0.0);
	War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0); // Remove ASPD buff when changing races
	War3_SetBuff(client,fHPRegen,thisRaceID,0.0);
	War3_SetBuff(client,fHPDecay,thisRaceID,0.0);
}

public OnWar3EventDeath(victim, attacker, deathrace, distance, attacker_hpleft)
{
	War3_SetBuff(victim,fAttackSpeed,thisRaceID,1.0);
}

CheckSkills(client)
{
	if(War3_GetRace(client) == thisRaceID){
		new skill = War3_GetSkillLevel(client,thisRaceID,SKILL_VITALITY);
		new VictimCurHP = GetClientHealth(client);
		new VictimMaxHP = War3_GetMaxHP(client);
		new Float:DoubleTrigger = VictimMaxHP * 0.4;

		if(bSpearActivated[client]){
			War3_SetBuff(client,fHPRegen,thisRaceID,0.0);
			War3_SetBuff(client,fHPDecay,thisRaceID,VictimMaxHP*0.05);
		}
		else
		{
		//level 0 is fine
			War3_SetBuff(client,fHPRegen,thisRaceID,  (VictimCurHP<=DoubleTrigger)  ?  VitalityHealed[skill]*2.0: VitalityHealed[skill] );
			War3_SetBuff(client,fHPDecay,thisRaceID,0.0);
		}
	}
}

public void OnAbilityCommand(int client, int ability, bool pressed, bool bypass)
{
	if(RaceDisabled)
		return;

	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client)&&!Silenced(client))
	{
		if(!bSpearActivated[client])
		{
			PrintHintText(client,"Activated Burning Spear");
			War3_EmitSoundToClient(client,"buttons/button2.wav");
			War3_EmitSoundToClient(client,"buttons/button2.wav");
			bSpearActivated[client] = true;
			CheckSkills(client);
		}
		else
		{
			PrintHintText(client,"Deactivated Burning Spear");
			War3_EmitSoundToClient(client,"buttons/button2.wav");
			War3_EmitSoundToClient(client,"buttons/button2.wav");
			bSpearActivated[client] = false;
			CheckSkills(client);
		}
	}
}
public void OnUltimateCommand(int client, int race, bool pressed, bool bypass)
{
	if(RaceDisabled)
		return;

	if(race==thisRaceID && pressed && ValidPlayer(client,true) &&!Silenced(client) )
	{
		new ult_level=War3_GetSkillLevel(client,race,ULT_BREAK);
		new Float:AttackerMaxHP = float(War3_GetMaxHP(client));
		new AttackerCurHP = GetClientHealth(client);
		new SelfDamage = RoundToCeil(AttackerMaxHP * LifeBreakHPCaster[ult_level]);
		new bool:bUltPossible = SelfDamage < AttackerCurHP;
		if(!Silenced(client)&&(bypass||War3_SkillNotInCooldown(client,thisRaceID,ULT_BREAK,true)))
		{
			if(!bUltPossible)
			{
				PrintHintText(client,"You do not have enough HP to cast that...");
			}
			else
			{


				new target = War3_GetTargetInViewCone(client,ultmaxdistance,false,23.0,UltFilter,ULT_BREAK);
				if(target>0)
				{

					new Float:VictimMaxHP = float(War3_GetMaxHP(target));
					new Damage = RoundToFloor(LifeBreakHPVictim[ult_level] * VictimMaxHP * W3GetBuffStackedFloat(target, fUltimateResistance));

					if(War3_DealDamage(target,Damage,client,DMG_BULLET,"lifebreak")) // do damage to nearest enemy
					{
						//W3PrintSkillDmgHintConsole(target,client,War3_GetWar3DamageDealt(),ULT_BREAK); // print damage done
						War3_NotifyPlayerTookDamageFromSkill(target, client, War3_GetWar3DamageDealt(), ULT_BREAK);
						W3FlashScreen(target,RGBA_COLOR_RED); // notify victim he got hurt
						W3FlashScreen(client,RGBA_COLOR_RED); // notify he got hurt

						//IMPROVED_ULT_BREAK
						//new improved_ult_level=War3_GetSkillLevel(client,race,IMPROVED_ULT_BREAK);
						//War3_SetBuff(target,fSlow,thisRaceID,LifeBreakSLOWVictim[improved_ult_level]); // Set the buff
						//CreateTimer(2.5,Ult_Remove_Slow,target);

						//War3_EmitSoundToAll(ultimateSound,client);
						if(War3_DealDamage(client,SelfDamage,client,DMG_BULLET,"lifebreak")) // Do damage to attacker
						{
							War3_NotifyPlayerTookDamageFromSkill(client, client, War3_GetWar3DamageDealt(), ULT_BREAK);
						}
						War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_BREAK); // invoke cooldown

						PrintHintText(client,"Life Break");
					}
				}
				else{
					W3MsgNoTargetFound(client,ultmaxdistance);
				}

			}
		}
	}
}

/*
public Action:Ult_Remove_Slow(Handle:h,any:client)
{
	War3_SetBuff(client,fSlow,thisRaceID,1.0); // Set the buff
}*/

//

public OnW3SupplyLocker(client)
{
	if(RaceDisabled)
		return;

	if(ValidPlayer(client))
	{
		VictimSpearStacks[client] = 0;  // deactivate Burning Spear
		VictimSpearTicks[client] = 0;
		bSpearActivated[client] = false;  // on spawn
	}
}

public OnW3HealthPickup(const String:output[], caller, activator, Float:delay)
{
	if(RaceDisabled)
		return;

	if(ValidPlayer(activator))
	{
		VictimSpearStacks[activator] = 0;  // deactivate Burning Spear
		VictimSpearTicks[activator] = 0;
		bSpearActivated[activator] = false;  // on spawn
	}
}
