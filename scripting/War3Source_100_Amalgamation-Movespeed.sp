#include <war3source>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#assert GGAMEMODE == MODE_WAR3SOURCE

#define RACE_ID_NUMBER 100
#define NO_ATTACH 0
#define ATTACH_NORMAL 1
#define ATTACH_HEAD 2

//#pragma semicolon 1	///WE RECOMMEND THE SEMICOLON

//#include <sourcemod>
//#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo =
{
	name = "Race - Amalgamation - Speed",
	author = "Razor",
	description = "Amalgamation race for War3Source.",
	version = "1.0",
};
public W3ONLY(){} //unload this?
/* Changelog
 * 1.2 - Fixed speed buff not being removed on race switch
 */
new thisRaceID;
new m_vecVelocity_0;
new Laser;
new String:leapsnd[256] = "war3source/chronos/timeleap.mp3";
new bool:lastframewasground[MAXPLAYERSCUSTOM];
bool HooksLoaded = false;
public void Load_Hooks()
{
	if(HooksLoaded) return;
	HooksLoaded = true;

	W3Hook(W3Hook_OnW3TakeDmgBulletPre, OnW3TakeDmgBulletPre);
	W3Hook(W3Hook_OnUltimateCommand, OnUltimateCommand);
	W3Hook(W3Hook_OnWar3EventSpawn, OnWar3EventSpawn);
}
public void UnLoad_Hooks()
{
	if(!HooksLoaded) return;
	HooksLoaded = false;

	W3Unhook(W3Hook_OnW3TakeDmgBulletPre, OnW3TakeDmgBulletPre);
	W3Unhook(W3Hook_OnUltimateCommand, OnUltimateCommand);
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
new SKILL_ASSAULT, SKILL_LEAP, SKILL_WINDWALKER, ULT_WARCRY;

//leap
new Float:leapPowerTF[]={650.0, 675.0, 700.0, 725.0, 750.0};

//Assault Tackle
new Float:assaultcooldown[]={7.0,6.6,6.0,5.6,5.0};
new Float:assaultMoveMult[]={1.0,1.1,1.2,1.3,1.4};

// WindWalker
new Float:WindWalkerStart = 3.0;
new Float:WindWalkerTimer[MAXPLAYERS+1];
new bool:WindWalkerActivated[MAXPLAYERS+1];
new Float:WindWalkerInvis[] = {0.6,0.6,0.5,0.45,0.4};
new Float:WindWalkerMoveSpeed[]={0.35,0.375,0.4,0.425,0.450};

// War Cry
new bool:isInFlight[MAXPLAYERS+1] = {false,...};
new Float:WingsOfGlory_Speed[] = { 3.0, 3.0, 3.0, 3.0, 3.0};

public OnWar3LoadRaceOrItemOrdered2(num,reloadrace_id,String:shortname[])
{
	if(num==RACE_ID_NUMBER||(reloadrace_id>0&&StrEqual("speed",shortname,false)))
	{
		thisRaceID=War3_CreateNewRace("Amalgamation - Speed","speed",reloadrace_id,"pure speed");
		SKILL_LEAP=War3_AddRaceSkill(thisRaceID,"Time Leap","Burst of velocity forwards when jumping.",false,4);
		SKILL_ASSAULT=War3_AddRaceSkill(thisRaceID,"Assault Tackle","Boosts speed when jumping.",false,4);
		SKILL_WINDWALKER=War3_AddRaceSkill(thisRaceID,"Windwalker","Gain speed and invis while not in combat for 1 second.",false,4);
		ULT_WARCRY=War3_AddRaceSkill(thisRaceID,"Wings of Glory","Toggles flight. (+ultimate)",true,4);
		War3_CreateRaceEnd(thisRaceID);
	}
}
public Action:Timer_CheckWindWalker(Handle:timer)
{
	for(new i = 0; i < MAXPLAYERS + 1; i++)
	{
		if(IsValidClient(i))
		{
			if(War3_GetRace(i)==thisRaceID && WindWalkerActivated[i] == false)
			{
				new skilllvl = War3_GetSkillLevel(i,thisRaceID,SKILL_WINDWALKER);
				if(WindWalkerTimer[i] <= 0.0 )
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
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(RaceDisabled)
		return Plugin_Continue;

	if(W3Paused()) return Plugin_Continue;
	

	WindWalkerTimer[client] -= GetTickInterval();

	if (buttons & IN_JUMP) //assault for non CS games
	{
		if (War3_GetRace(client) == thisRaceID)
		{
			new bool:lastwasgroundtemp=lastframewasground[client];
			lastframewasground[client]=bool:(GetEntityFlags(client) & FL_ONGROUND);
			new skill_Leap=War3_GetSkillLevel(client,thisRaceID,SKILL_LEAP);
			if(!Hexed(client)&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_LEAP) &&  lastwasgroundtemp &&   !(GetEntityFlags(client) & FL_ONGROUND) )
			{
				#if GGAMETYPE == GGAME_TF2
				if (TF2_HasTheFlag(client))
					return Plugin_Continue;
				#endif
				decl Float:velocity[3];
				GetEntDataVector(client, m_vecVelocity_0, velocity); //gets all 3
				new Float:oldz=velocity[2];
				velocity[2]=0.0;
				new Float:len=GetVectorLength(velocity);
				if(len>3.0){
					ScaleVector(velocity,leapPowerTF[skill_Leap]/len);
					velocity[2]=oldz;
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
				}


				War3_EmitSoundToAll(leapsnd,client);
				War3_EmitSoundToAll(leapsnd,client);

				War3_CooldownMGR(client,6.5,thisRaceID,SKILL_LEAP,_,_);
			}
			new skill_SKILL_ASSAULT=War3_GetSkillLevel(client,thisRaceID,SKILL_ASSAULT);
			if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_ASSAULT) &&  lastwasgroundtemp &&   !(GetEntityFlags(client) & FL_ONGROUND) &&!Hexed(client) )
			{
				#if GGAMETYPE == GGAME_TF2
				if (TF2_HasTheFlag(client))
					return Plugin_Continue;
				#endif
				decl Float:velocity[3];
				GetEntDataVector(client, m_vecVelocity_0, velocity); //gets all 3
				new Float:oldz=velocity[2];
				velocity[2]=0.0; //zero z
				new Float:len=GetVectorLength(velocity);
				if(len>3.0){
					new Float:amt = 1.2 + (assaultMoveMult[skill_SKILL_ASSAULT]);
					velocity[0]*=amt;
					velocity[1]*=amt;
					velocity[2]=oldz;
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
				}
				War3_CooldownMGR(client,assaultcooldown[skill_SKILL_ASSAULT],thisRaceID,SKILL_ASSAULT,_,_);
				#if GGAMETYPE == GGAME_TF2
				if (!War3_IsCloaked(client))
				{
					new String:wpnstr[32];
					GetClientWeapon(client, wpnstr, 32);
					for(new slot=0;slot<10;slot++){

						new wpn=GetPlayerWeaponSlot(client, slot);
						if(wpn>0){
							//PrintToChatAll("wpn %d",wpn);
							new String:comparestr[32];
							GetEdictClassname(wpn, comparestr, 32);
							//PrintToChatAll("%s %s",wpn, comparestr);
							if(StrEqual(wpnstr,comparestr,false)){

								TE_SetupKillPlayerAttachments(wpn);
								TE_SendToAll();

								new color[4]={0,25,255,200};
								if(GetClientTeam(client)==TEAM_T||GetClientTeam(client)==TEAM_RED){
									color[0]=255;
									color[2]=0;
								}
								TE_SetupBeamFollow(wpn,Laser,0,0.5,2.0,7.0,1,color);
								TE_SendToAll();
								break;
							}
						}
					}
				}
				#endif
			}
		}
	}
	return Plugin_Continue;
}
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
	CreateTimer(0.15, Timer_CheckWindWalker, _, TIMER_REPEAT);
	m_vecVelocity_0 = FindSendPropInfo("CBasePlayer","m_vecVelocity[0]");
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
		War3_SetBuff(client,bSlowImmunity,thisRaceID,0.0);
		War3_SetBuff(client,bImmunitySkills,thisRaceID,0.0);
		War3_SetBuff(client,bImmunityUltimates,thisRaceID,0.0);
		War3_SetBuff(client,bImmunityWards,thisRaceID,0.0);
		W3ResetPlayerColor(client,thisRaceID);
		War3_SetBuff(client,bFlyMode,thisRaceID,0.0);
	}
}
public OnAddSound(sound_priority)
{
	if(sound_priority==PRIORITY_MEDIUM)
	{
		War3_AddSound(leapsnd);
	}
}

public OnAllPluginsLoaded()
{
	War3_RaceOnPluginStart("speed");
}

public OnPluginEnd()
{
	if(LibraryExists("RaceClass"))
		War3_RaceOnPluginEnd("speed");
}

public OnMapStart()
{
	UnLoad_Hooks();
	Laser=PrecacheModel("materials/sprites/laserbeam.vmt");
	PrecacheSound(leapsnd);
}

public void OnWar3EventSpawn (int client)
{
	StopWindWalker(client);
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
		if(War3_GetRace(victim)==thisRaceID)
		{
			StopWindWalker(victim);
		}
	}
	return Plugin_Continue;
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if(RaceDisabled)
		return Plugin_Continue;
		
	if(War3_GetRace(client)==thisRaceID)	
	{
		StopWindWalker(client);
	}
	return Plugin_Continue;
}
public void OnUltimateCommand(int client, int race, bool pressed, bool bypass)
{
	if(RaceDisabled)
		return;

	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new skill_level = War3_GetSkillLevel(client,thisRaceID,ULT_WARCRY);
		if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_WARCRY,true ))
		{
			if(!isInFlight[client])
			{
				War3_SetBuff(client,fMaxSpeed,thisRaceID,WingsOfGlory_Speed[skill_level]);
				War3_SetBuff(client,bFlyMode,thisRaceID,1.0);
				new Float:ClientPos[3];
				GetClientAbsOrigin( client, ClientPos );
				ClientPos[2] += 25;
				TeleportEntity( client, ClientPos, NULL_VECTOR, NULL_VECTOR );
				W3Hint(client,HINT_SKILL_STATUS,1.0,"Look up and Fly! Wings of Glory!");
				isInFlight[client] = true;
				/*
				CreateParticle("community_sparkle", 10.0, client, 2,0.0,0.0,0.0);
				CreateParticle("community_sparkle", 10.0, client, 2,50.0,-25.0,0.0);
				CreateParticle("community_sparkle", 10.0, client, 2,50.0,0.0,0.0);
				CreateParticle("community_sparkle", 10.0, client, 2,50.0,25.0,0.0);
				CreateParticle("community_sparkle", 10.0, client, 2,100.0,-25.0,0.0);
				CreateParticle("community_sparkle", 10.0, client, 2,100.0,0.0,0.0);
				CreateParticle("community_sparkle", 10.0, client, 2,100.0,25.0,0.0);
				// body
				CreateParticle("community_sparkle", 10.0, client, 2,0.0,0.0,-25.0);
				CreateParticle("community_sparkle", 10.0, client, 2,50.0,-25.0,-25.0);
				CreateParticle("community_sparkle", 10.0, client, 2,50.0,0.0,-25.0);
				CreateParticle("community_sparkle", 10.0, client, 2,25.0,0.0,-40.0);
				CreateParticle("community_sparkle", 10.0, client, 2,100.0,-25.0,-25.0);
				CreateParticle("community_sparkle", 10.0, client, 2,100.0,0.0,-25.0);
				CreateParticle("community_sparkle", 10.0, client, 2,30.0,25.0,-25.0);
				// feet
				CreateParticle("community_sparkle", 10.0, client, 2,30.0,0.0,-75.0);
				CreateParticle("critical_rocket_red", 10.0, client, 2,20.0,0.0,-75.0);
				CreateParticle("critical_rocket_blue", 10.0, client, 2,20.0,0.0,-75.0);
				CreateParticle("teleporter_red_charged_wisps", 10.0, client, 2,10.0,0.0,-50.0);
				CreateParticle("teleporter_blue_charged_wisps", 10.0, client, 2,10.0,0.0,-50.0);
				CreateParticle("teleporter_blue_entrance", 10.0, client, 2,0.0,0.0,-50.0);
				CreateParticle("teleporter_red_entrance", 10.0, client, 2,0.0,0.0,-50.0);
				*/
			}
			else
			{
				isInFlight[client] = false;
				W3ResetPlayerColor(client,thisRaceID);
				War3_SetBuff(client,fSlow,thisRaceID,1.0);
				War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
				W3Hint(client,HINT_SKILL_STATUS,1.0,"END OF:...Wings of Glory...");
				War3_SetBuff(client,bFlyMode,thisRaceID,0.0);
			}
		}
	}
}
stock Handle:CreateParticle(String:type[], Float:time, entity, attach=NO_ATTACH, Float:xOffs=0.0, Float:yOffs=0.0, Float:zOffs=0.0)
{
	if(IsValidEntity(entity))
	{
		new particle = CreateEntityByName("info_particle_system");
		if (IsValidEdict(particle)) {
			decl Float:pos[3];
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
			pos[0] += xOffs;
			pos[1] += yOffs;
			pos[2] += zOffs;
			TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
			DispatchKeyValue(particle, "effect_name", type);

			if (attach != NO_ATTACH) {
				SetVariantString("!activator");
				AcceptEntityInput(particle, "SetParent", entity, particle, 0);

				if (attach == ATTACH_HEAD) {
					SetVariantString("head");
					AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset", particle, particle, 0);
				}
			}
			DispatchKeyValue(particle, "targetname", "present");
			DispatchSpawn(particle);
			ActivateEntity(particle);
			AcceptEntityInput(particle, "Start");
			return CreateTimer(time, DeleteParticle, particle);
		} else {
			LogError("(CreateParticle): Could not create info_particle_system");
		}
	}

	return INVALID_HANDLE;
}
public Action:DeleteParticle(Handle:timer, any:particle)
{
        if (IsValidEdict(particle)) {
                new String:classname[64];
                GetEdictClassname(particle, classname, sizeof(classname));

                if (StrEqual(classname, "info_particle_system", false)) {
                        RemoveEdict(particle);
                }
        }
}
