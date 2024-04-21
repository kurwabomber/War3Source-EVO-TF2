#include <war3source>
#include <tf2attributes>
#include <sdkhooks>
#include <sdktools>
#assert GGAMEMODE == MODE_WAR3SOURCE

#define RACE_ID_NUMBER 31

public Plugin:myinfo =
{
	name = "Race - Phoenix",
	author = "Razor",
	description = "Phoenix race for War3Source.",
	version = "1.0",
};
public W3ONLY(){}

new thisRaceID;
float djAngle[MAXPLAYERSCUSTOM][3];
float djPos[MAXPLAYERSCUSTOM][3];

bool HooksLoaded = false;
public void Load_Hooks()
{
	if(HooksLoaded) return;
	HooksLoaded = true;

	W3Hook(W3Hook_OnUltimateCommand, OnUltimateCommand);
}
public void UnLoad_Hooks()
{
	if(!HooksLoaded) return;
	HooksLoaded = false;

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

new SKILL_SPELLIMMUNITY, SKILL_RESISTANT, SKILL_REVIVE, ULT_FIRE;

new Float:immunityChance[]={0.75,0.6875,0.625,0.5625,0.5};
new Float:DefenseBonus[]={2.0,2.25,2.5,2.75,3.0};
new Float:Reincarnation[]={45.0, 44.0, 43.0, 42.0, 40.0};
new Float:FlameBaseDMG[]={20.0, 22.0, 24.0, 26.0, 28.0};

public OnWar3LoadRaceOrItemOrdered2(num,reloadrace_id,String:shortname[])
{
	if(num==RACE_ID_NUMBER||(reloadrace_id>0&&StrEqual("phoenix",shortname,false)))
	{
		thisRaceID=War3_CreateNewRace("Phoenix","phoenix",reloadrace_id,"Pyro Race");
		SKILL_SPELLIMMUNITY=War3_AddRaceSkill(thisRaceID,"Spell Immunity","Grants partial immunity to all effects.\nEach level increases rate. 50% to 75%.",false,4);
		SKILL_RESISTANT=War3_AddRaceSkill(thisRaceID,"Resistant Skin","Gives a boost to defense. Gives 2.0 to 3 physical armor.",false,4);
		SKILL_REVIVE=War3_AddRaceSkill(thisRaceID,"Revival","Self-revives with a cooldown. Cooldown is 45 to 40 seconds.",false,4);
		ULT_FIRE=War3_AddRaceSkill(thisRaceID,"Phoenix Fire","Ignites everyone in a 600 HU radius. Deals 20 to 28 damage. Cooldown is 1.5 seconds.",true,4);
		War3_CreateRaceEnd(thisRaceID);
		War3_AddSkillBuff(thisRaceID, SKILL_RESISTANT, fArmorPhysical, DefenseBonus);
		W3SkillCooldownOnSpawn(thisRaceID,SKILL_REVIVE,40.0,true);
	}
}
public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{	
		War3_SetBuff(client,fAbilityResistance,thisRaceID, 1.0);
		War3_SetBuff(client,fUltimateResistance,thisRaceID, 1.0);
		War3_SetBuff(client,fArmorPhysical,thisRaceID,0.0);
	}
	else
	{
		new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_SPELLIMMUNITY);
		War3_SetBuff(client,fAbilityResistance,thisRaceID, immunityChance[skill_level]);
		War3_SetBuff(client,fUltimateResistance,thisRaceID, immunityChance[skill_level]);
	}
}
public OnWar3EventDeath(victim, attacker)
{
	if(RaceDisabled)
		return;

	if(victim==attacker)
		return;

	int race=W3GetVar(DeathRace);
	int skill=War3_GetSkillLevel(victim,thisRaceID,SKILL_REVIVE);
	if(race==thisRaceID && skill>0 && !Silenced(victim) && War3_SkillNotInCooldown(victim,thisRaceID,SKILL_REVIVE,true))
	{
		float VecPos[3];
		float Angles[3];
		War3_CachedAngle(victim,Angles);
		War3_CachedPosition(victim,VecPos);
		djAngle[victim]=Angles;
		djPos[victim]=VecPos;
		CreateTimer(0.2,DoDeathReject,GetClientUserId(victim));
	}
}
public Action:DoDeathReject(Handle:timer,any:userid)
{
	int client=GetClientOfUserId(userid);
	if(ValidPlayer(client,false))
	{
		int skilllevel=War3_GetSkillLevel(client,thisRaceID,SKILL_REVIVE);
		TF2_RespawnPlayer(client);
		War3_RestoreItemsFromDeath(client,false);
		TeleportEntity(client, djPos[client], djAngle[client], NULL_VECTOR);
		War3_CooldownMGR(client,Reincarnation[skilllevel],thisRaceID,SKILL_REVIVE,false,true);
	}
	return Plugin_Continue;
}
public OnAllPluginsLoaded()
{
	War3_RaceOnPluginStart("phoenix");
}

public OnPluginEnd()
{
	if(LibraryExists("RaceClass"))
		War3_RaceOnPluginEnd("phoenix");
}
public OnMapStart()
{
	UnLoad_Hooks();
}
public void OnUltimateCommand(int client, int race, bool pressed, bool bypass)
{
	if(RaceDisabled)
		return;

	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new skill_level = War3_GetSkillLevel(client,thisRaceID,ULT_FIRE);
		if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_FIRE,true ))
		{
			bool victimfound = false;
			for(int i=1;i<=MaxClients;i++)
			{
				if(ValidPlayer(i,true))
				{
					float AttackerPos[3];
					GetClientAbsOrigin(client,AttackerPos);
					int AttackerTeam = GetClientTeam(client);
					float VictimPos[3];
					GetClientAbsOrigin(i,VictimPos);
					if(GetVectorDistance(AttackerPos,VictimPos)<600.0)
					{
						if(GetClientTeam(i)!=AttackerTeam)
						{
							if(!W3HasImmunity(i,Immunity_Ultimates))
							{
								if(War3_DealDamage(i,RoundToNearest(FlameBaseDMG[skill_level]*W3GetBuffStackedFloat(i, fUltimateResistance)),client,_,"phoenixFlames"))
								{
									War3_NotifyPlayerTookDamageFromSkill(i, client, War3_GetWar3DamageDealt(), ULT_FIRE);
								}
								TF2_IgnitePlayer(i, client, 5.0);
								War3_CooldownMGR(client,1.5,thisRaceID,ULT_FIRE,_,_);
								victimfound = true;
							}
						}
					}
				}
			}
			if(!victimfound)
			{
				War3_ChatMessage(client,"{lightgreen}No victims found for Phoenix Flames!");
				War3_CooldownMGR(client,1.0,thisRaceID,ULT_FIRE,_,_);
			}
		}
	}
}