#include <war3source>
#include <tf2>
#assert GGAMEMODE == MODE_WAR3SOURCE
#pragma tabsize 0
#define RACE_ID_NUMBER 3

//#pragma semicolon 1	///WE RECOMMEND THE SEMICOLON

//#include <sourcemod>
//#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo =
{
	name = "Race - Orcish Horde",
	author = "Razor!",
	description = "Orcish Horde race for War3Source.",
	version = "1.0",
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

new SKILL_WINDWALKER, SKILL_CRITS, SKILL_ORB, ULT_LIGHTNING;

// WindWalker
new Float:WindWalkerStart = 3.0;
new Float:WindWalkerTimer[MAXPLAYERS+1];
new bool:WindWalkerActivated[MAXPLAYERS+1];
new Float:WindWalkerInvis[] = {0.6,0.6,0.5,0.45,0.4};
new Float:WindWalkerMoveSpeed[]={0.35,0.375,0.4,0.425,0.450};

// Critical Strike
new Float:CritChance = 0.10;
new Float:CritMultiplier[] = {2.0,2.125,2.25,2.375,2.5};

// Orb Of Lightning
new Float:OrbAttackspeed[]={0.2,0.225,0.25,0.275,0.3};
new Float:OrbCleave[]={0.17,0.19,0.21,0.23,0.25};
new orbInflictor[MAXPLAYERS+1];
new bool:bOrbActivated[MAXPLAYERS+1];
//					   ^Inflictor	 ^current player

// Lightning Strike
new LSMaxDamage[]={60,70,80,90,100};
new Float:Cooldown[] = {20.0,19.0,18.0,17.0,16.0}; // cooldown
new String:lightningSound[]="war3source/lightningbolt.mp3";
new bool:bBeenHit[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM];
new BeamSprite,HaloSprite;
stock bool:IsValidClient( client, bool:replaycheck = true )
{
    if ( client <= 0 || client > MaxClients ) return false; 
    if ( !IsClientInGame( client ) ) return false; 
    if ( !IsClientConnected( client ) ) return false; 
    if ( GetEntProp( client, Prop_Send, "m_bIsCoaching" ) ) return false; 
    if ( replaycheck )
    {
        if ( IsClientSourceTV( client ) || IsClientReplay( client ) ) return false; 
    }
    return true; 
}
public void OnPluginStart()
{
	CreateTimer(0.1, Timer_CheckWindWalker, _, TIMER_REPEAT);
}
public OnWar3LoadRaceOrItemOrdered2(num,reloadrace_id,String:shortname[])
{
	if(num==RACE_ID_NUMBER||(reloadrace_id>0&&StrEqual("orcish",shortname,false)))
	{
		thisRaceID=War3_CreateNewRace("Orcish Horde","orcish",reloadrace_id,"Speed, crits, cleave");
		SKILL_WINDWALKER=War3_AddRaceSkill(thisRaceID,"Windwalker","While not in combat for 2 seconds, you gain movespeed and invisibility.\nUp to 60% invis and 45% movespeed.",false,4);
		SKILL_CRITS=War3_AddRaceSkill(thisRaceID,"Critical Strike","You have a 10% chance to deal up to 2.5 times damage.",false,4);
		SKILL_ORB=War3_AddRaceSkill(thisRaceID,"Orb of Lightning","Gain attackspeed and cleave within 150 HU for 6 seconds, Can give to teammates if looking nearby them.\nup to +30% attack speed and 25% cleave.",false,4);
		ULT_LIGHTNING=War3_AddRaceSkill(thisRaceID,"Lightning Strike","Strike nearby enemies, will chain to other enemies if nearby.\nCooldown 20s to 16s, Damage 60 to 100.",true,4);
		War3_CreateRaceEnd(thisRaceID);
	}
}
public Action:Timer_CheckWindWalker(Handle:timer)
{
	for(new i = 0; i < MaxClients+ 1; i++)
	{
		if(IsValidClient(i))
		{
			if(War3_GetRace(i)==thisRaceID && WindWalkerActivated[i] == false)
			{
				new skilllvl = War3_GetSkillLevel(i,thisRaceID,SKILL_WINDWALKER);
				if(skilllvl > 0 && WindWalkerTimer[i] <= 0.0 )
				{
					WindWalkerActivated[i] = true;
					War3_SetBuff(i,fInvisibilitySkill,thisRaceID,1.0-WindWalkerInvis[skilllvl]);
					War3_SetBuff(i,fMaxSpeed,thisRaceID,1.0+WindWalkerMoveSpeed[skilllvl]);
				}
			}
		}
	}
}
StopWindWalker(client)
{	
	WindWalkerActivated[client] = false;
	War3_SetBuff(client,fMaxSpeed,thisRaceID, 1.0, client);
	War3_SetBuff(client,fInvisibilitySkill,thisRaceID, 1.0, client);
	WindWalkerTimer[client] = WindWalkerStart;
}
public OnAllPluginsLoaded()
{
	War3_RaceOnPluginStart("orcish");
}

public OnPluginEnd()
{
	if(LibraryExists("RaceClass"))
		War3_RaceOnPluginEnd("orcish");
}

public OnMapStart()
{
	UnLoad_Hooks();
	BeamSprite=War3_PrecacheBeamSprite(); 
	HaloSprite=War3_PrecacheHaloSprite();
	PrecacheSound(lightningSound);	
}
public OnAddSound(sound_priority)
{
	if(sound_priority==PRIORITY_MEDIUM)
	{
		War3_AddSound(lightningSound);
	}
}
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)//on every server frame
{
	WindWalkerTimer[client] -= GetTickInterval();
	return Plugin_Continue;
}
public void OnWar3EventSpawn(int client)
{
	StopWindWalker(client);
}
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if(RaceDisabled)
		return Plugin_Continue;
		
	if(War3_GetRace(client)==thisRaceID)	
	{
		new skilllvl = War3_GetSkillLevel(client,thisRaceID,SKILL_WINDWALKER);
		if(skilllvl > 0)
		{
			StopWindWalker(client);
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
		if(GetClientTeam(victim)==GetClientTeam(attacker) || W3HasImmunity(victim, Immunity_Skills))
			return Plugin_Continue;
	}
	if(IsValidEntity(victim)&&ValidPlayer(attacker,false))
	{
		if(ValidPlayer(victim,true) && War3_GetRace(victim)==thisRaceID)
		{
			new skilllvl = War3_GetSkillLevel(victim,thisRaceID,SKILL_WINDWALKER);
			if(skilllvl > 0)
			{
				StopWindWalker(victim);
			}
		}
		if(War3_GetRace(attacker)==thisRaceID)
		{
			new skilllvl = War3_GetSkillLevel(attacker,thisRaceID,SKILL_CRITS);
			if(skilllvl > 0)
			{
				new Float:Chance = GetRandomFloat(0.0, 1.0);
				float resistance = W3GetBuffStackedFloat(victim, fAbilityResistance);

				if(!ValidPlayer(victim,false) && CritChance*resistance >= Chance)
				{
					War3_DamageModPercent(CritMultiplier[skilllvl]);
					W3Hint(attacker,HINT_COOLDOWN_NOTREADY,2.0,"Crit!");
				}
				if(ValidPlayer(victim,false) && CritChance*resistance >= Chance && !W3HasImmunity(victim,Immunity_Skills))
				{
					War3_DamageModPercent(CritMultiplier[skilllvl]);
					W3Hint(attacker,HINT_COOLDOWN_NOTREADY,2.0,"Crit!");			
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

	if(ValidPlayer(attacker,true) && ValidPlayer(victim,true))
	{
		if(GetClientTeam(victim)==GetClientTeam(attacker))
		{
			return Plugin_Continue;
		}
	}
	if(IsValidEntity(victim)&&ValidPlayer(attacker,false) && bOrbActivated[attacker] == true)
	{
		new skilllvl = War3_GetSkillLevel(orbInflictor[attacker],thisRaceID,SKILL_ORB);
		new splashdmg = RoundToFloor(damage * OrbCleave[skilllvl]);
		if(splashdmg>80)
		{
			splashdmg = 80;
		}
		new Float:dist = 150.0;
		new AttackerTeam = GetClientTeam(attacker);
		new Float:OriginalVictimPos[3];
		GetClientAbsOrigin(victim,OriginalVictimPos);
		new Float:VictimPos[3];
		if(attacker>0)
		{
			for(new i=1;i<=MaxClients;i++)
			{
				if(ValidPlayer(i,true)&&(GetClientTeam(i)!=AttackerTeam)&&(victim!=i))
				{
					GetClientAbsOrigin(i,VictimPos);
					if(GetVectorDistance(OriginalVictimPos,VictimPos)<=dist)
					{
						if(War3_DealDamage(i,splashdmg,attacker,_,"lightningorb"))
						{
							//W3PrintSkillDmgConsole(i,attacker,War3_GetWar3DamageDealt(),SKILL_CLEAVE);
							War3_NotifyPlayerTookDamageFromSkill(i, attacker, splashdmg, SKILL_ORB);
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
		new skilllvl = War3_GetSkillLevel(client,thisRaceID,SKILL_ORB);
		if(skilllvl > 0)
		{
			if(!Silenced(client)&&(bypass||War3_SkillNotInCooldown(client,thisRaceID,SKILL_ORB,true)))
			{
				new Float:Range = 300.0;
				new Float:AttackerPos[3];
				GetClientAbsOrigin(client,AttackerPos);
				new AttackerTeam = GetClientTeam(client);
				float VictimPos[3];
				bool victimfound = false;
				for(int i=1;i<=MaxClients;i++)
				{
					if(ValidPlayer(i,true))
					{
						int VictimTeam = GetClientTeam(i);
						GetClientAbsOrigin(i,VictimPos);
						if(GetVectorDistance(AttackerPos,VictimPos)<Range && VictimTeam == AttackerTeam)
						{
							GetClientAbsOrigin(i,VictimPos);
							bOrbActivated[i] = true;
							orbInflictor[i] = client;
							CreateTimer(6.0,BuffOff,i);
							War3_SetBuff(i, fAttackSpeed, thisRaceID, 1.0+OrbAttackspeed[skilllvl]);
							W3Hint(i,HINT_COOLDOWN_NOTREADY,5.0,"You were shocked! Increased attackspeed and attacks cleave.");
							victimfound = true;
						}
					}
				}
				if(victimfound)
				{
					War3_CooldownMGR(client,30.0,thisRaceID,SKILL_ORB,_,_);
				}
				if(victimfound == false)
				{
					W3MsgNoTargetFound(client,Range);
				}
			}
		}
	}
}
public Action:BuffOff(Handle:timer,any:client)
{
	bOrbActivated[client] = false;
	orbInflictor[client] = 0;
	War3_SetBuff(client,fAttackSpeed,RACE_ID_NUMBER, 1.0, client);
	W3Hint(client,HINT_COOLDOWN_NOTREADY,2.0,"Lightning orb ran out!");
}

public void OnUltimateCommand(int client, int race, bool pressed, bool bypass)
{
	if(RaceDisabled)
		return;

	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new skill_level = War3_GetSkillLevel(client,thisRaceID,ULT_LIGHTNING);
		if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_LIGHTNING,true ))
		{
			for(new x=1;x<=MaxClients;x++)
			{
				bBeenHit[client][x]=false;    
			}
			new Float:distance=200.0;
			DoChain(client,distance,LSMaxDamage[skill_level],true,0);		
		}
	}
}
public DoChain(client,Float:distance,dmg,bool:first_call,last_target)
{
    if(RaceDisabled)
    {
        return;
    }
	
	new skill_level = War3_GetSkillLevel(client,thisRaceID,ULT_LIGHTNING);
	new target = 0;
    new Float:target_dist=distance+1.0; // just an easy way to do this
    new caster_team=GetClientTeam(client);
    new Float:start_pos[3];
    if(last_target<=0)
        GetClientAbsOrigin(client,start_pos);
    else
        GetClientAbsOrigin(last_target,start_pos);
    for(new x=1;x<=MaxClients;x++)
    {
        if(ValidPlayer(x,true)&&!bBeenHit[client][x]&&caster_team!=GetClientTeam(x)&&!W3HasImmunity(x,Immunity_Ultimates))
        {
            new Float:this_pos[3];
            GetClientAbsOrigin(x,this_pos);
            new Float:dist_check=GetVectorDistance(start_pos,this_pos);
            if(dist_check<=target_dist)
            {
                // found a candidate, whom is currently the closest
                target=x;
                target_dist=dist_check;
            }
        }
    }
    if(target<=0)
    {
    //DP("no target");
        // no target, if first call dont do cooldown
        if(first_call)
        {
            W3MsgNoTargetFound(client,distance);
        }
    }
    else
    {
        // found someone
		float resistance = W3GetBuffStackedFloat(target, fUltimateResistance);
        bBeenHit[client][target]=true; // don't let them get hit twice
        War3_DealDamage(target,RoundFloat(dmg * resistance),client,DMG_ENERGYBEAM,"chainlightning");
        PrintHintText(target,"Hit by Chain Lightning -%i HP",War3_GetWar3DamageDealt());
        start_pos[2]+=30.0; // offset for effect
        decl Float:target_pos[3],Float:vecAngles[3];
        GetClientAbsOrigin(target,target_pos);
        target_pos[2]+=30.0;
        TE_SetupBeamPoints(start_pos,target_pos,BeamSprite,HaloSprite,0,35,1.0,25.0,25.0,0,10.0,{255,100,255,255},40);
        TE_SendToAll();
        GetClientEyeAngles(target,vecAngles);
        War3_EmitSoundToAll(lightningSound , target);
		
        new new_dmg=RoundFloat(float(dmg)*0.80);
        
        DoChain(client,distance,new_dmg,false,target);
		
		new Float:cooldown = Cooldown[skill_level];
        War3_CooldownMGR(client,cooldown,thisRaceID,ULT_LIGHTNING,_,_);
    }
}
public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace==thisRaceID)
	{
		WindWalkerTimer[client] = 1.0;
	}
	else
	{
		StopWindWalker(client);
	}
}