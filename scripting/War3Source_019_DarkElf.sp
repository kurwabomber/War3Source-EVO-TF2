#include <war3source>
#assert GGAMEMODE == MODE_WAR3SOURCE
#assert GGAMETYPE_JAILBREAK == JAILBREAK_OFF


#define RACE_ID_NUMBER 19

//#pragma semicolon 1    ///WE RECOMMEND THE SEMICOLON

//#include <sourcemod>
//#include "W3SIncs/War3Source_Interface"


new thisRaceID;
public Plugin:myinfo =
{
	name = "Race - Dark Elf",
	author = "Smilax & Glider helped a lot :D", //modified by Ownz
	description = "The Dark Elf race for War3Source.",
	version = "1.0.0.0",
	url = "http://www.war3evo.info/"
};

bool HooksLoaded = false;
public void Load_Hooks()
{
	if(HooksLoaded) return;
	HooksLoaded = true;

	W3Hook(W3Hook_OnW3TakeDmgBulletPre, OnW3TakeDmgBulletPre);
	W3Hook(W3Hook_OnUltimateCommand, OnUltimateCommand);
	W3Hook(W3Hook_OnAbilityCommand, OnAbilityCommand);
	W3Hook(W3Hook_OnWar3EventSpawn, OnWar3EventSpawn);
}
public void UnLoad_Hooks()
{
	if(!HooksLoaded) return;
	HooksLoaded = false;

	W3Unhook(W3Hook_OnW3TakeDmgBulletPre, OnW3TakeDmgBulletPre);
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
}//	if(RaceDisabled)
//		return;

new SKILL_FADE,SKILL_SLOWFALL,SKILL_TRIBUNAL,ULTIMATE_DARKORB;

new FadeReaction[]={20,20,20,20,20};
new FadeReactionGain[]={40,42,45,47,50};

new Float:FadeChance[]={0.20,0.22,0.24,0.26,0.28};
new Float:TribunalDecay[]={6.5,6.25,6.0,5.75,5.5};
new Float:TribunalSpeed[]={1.40, 1.425,1.45,1.475,1.5};

new bool:IsInTribunal[MAXPLAYERSCUSTOM];

//new Float:TribunalDuration=3.5;
//new Float:TribunalCooldownTime=15.0;
new Float:DarkorbDistance=1000.0;
new Float:DarkorbDuration[]={2.0,2.25,2.5,2.75,3.0};
new Float:DarkorbCooldownTime=10.0;

//new Float:darkvec[3]={0.0,0.0,0.0};
//new Float:prevdarkvec[3]={0.0,0.0,0.0};
new Float:victimvec[3]={0.0,0.0,0.0};

// Sounds
stock String:tribunal[]="war3source/darkelf/tribunal.mp3";
stock String:darkorb[]="war3source/darkelf/darkorb.mp3";


public OnWar3LoadRaceOrItemOrdered2(num,reloadrace_id,String:shortname[])
{
	if(num==RACE_ID_NUMBER||(reloadrace_id>0&&StrEqual("darkelf_o",shortname,false)))
	{
		thisRaceID=War3_CreateNewRace("Dark Elf","darkelf_o",reloadrace_id,"Blind players");
		SKILL_FADE=War3_AddRaceSkill(thisRaceID,"Fade","You fade out of sight on hit, 20-28% Chance",false,4);
		SKILL_SLOWFALL=War3_AddRaceSkill(thisRaceID,"Fade Reaction","When you fade, you lose 20 non-lethal health, but gain 40 to 50 health when you're visible again.",false,4);
		SKILL_TRIBUNAL=War3_AddRaceSkill(thisRaceID,"Tribunal","(+ability) At the cost 6.5 to 5.5 hp/sec, you speed up 40 to 50%.",false,4,"(voice Help!)");
		ULTIMATE_DARKORB=War3_AddRaceSkill(thisRaceID,"DarkOrb","Blind a player. 2-3 second duration & 1000 Range. Cooldown is 10s.",true,4,"(voice Jeers)");
		War3_CreateRaceEnd(thisRaceID); ///DO NOT FORGET THE END!!!
	}
}

public OnPluginStart()
{
	//CreateTimer(0.1,SlowfallTimer,_,TIMER_REPEAT);
	//LoadTranslations("w3s.race.darkelf_o.phrases");
}
public OnAllPluginsLoaded()
{
	War3_RaceOnPluginStart("darkelf_o");
}

public OnPluginEnd()
{
	if(LibraryExists("RaceClass"))
		War3_RaceOnPluginEnd("darkelf_o");
}

#if GGAMETYPE == GGAME_TF2
//#define TELEPORTER_RED "teleporter_red_entrance"
//#define TELEPORTER_BLUE "teleporter_blue_entrance"
#define GHOST_SMOKE "ghost_smoke"
#elseif GGAMETYPE == GGAME_CSGO
//#define TELEPORTER_RED "teleporter_red_entrance"
//#define TELEPORTER_BLUE "teleporter_blue_entrance"
#define GHOST_SMOKE "office_smoke"
#else
//#define TELEPORTER_RED ""
//#define TELEPORTER_BLUE ""
#define GHOST_SMOKE ""
#endif

public OnMapStart()
{
	UnLoad_Hooks();
	//War3_PrecacheParticle(TELEPORTER_RED);
	//War3_PrecacheParticle(TELEPORTER_BLUE);
	War3_PrecacheParticle(GHOST_SMOKE);
	PrecacheSound(tribunal);
	PrecacheSound(darkorb);
}

public void OnUltimateCommand(int client, int race, bool pressed, bool bypass)
{
	if(RaceDisabled)
		return;

	new userid=GetClientUserId(client);
	if(race==thisRaceID && pressed && userid>1 && IsPlayerAlive(client) )
	{
		new ult_level=War3_GetSkillLevel(client,race,ULTIMATE_DARKORB);
		if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULTIMATE_DARKORB,true))
		{
			//War3_GetTargetInViewCone(client,Float:max_distance=0.0,bool:include_friendlys=false,Float:cone_angle=23.0,Function:FilterFunction=INVALID_FUNCTION);
			new target = War3_GetTargetInViewCone(client,DarkorbDistance,false,23.0,UltFilter,ULTIMATE_DARKORB);
			new Float:duration = DarkorbDuration[ult_level] * W3GetBuffStackedFloat(client, fUltimateResistance);
			if(target>0&&!W3HasImmunity(target,Immunity_Ultimates))
			{
				GetClientAbsOrigin(target,victimvec);
				//W3FlashScreen(target,RGBA_COLOR_BLACK,duration,0.5,FFADE_OUT); RGBA_COLOR_etc doesn't work.
				W3FlashScreen(target,{0,0,0,255},duration,0.5,FFADE_OUT);
				if(IsFakeClient(target)){
					War3_SetBuff(target,bDisarm,thisRaceID,true);
					CreateTimer(duration, UndisarmClient, EntIndexToEntRef(target));
				}

				War3_EmitSoundToAll(darkorb,target);
				War3_EmitSoundToAll(darkorb,target);

				// tf2 only ghost_smoke
				AttachThrowAwayParticle(target, GHOST_SMOKE, victimvec, "", duration);
				War3_CooldownMGR(client,DarkorbCooldownTime,thisRaceID,ULTIMATE_DARKORB,_,_);
				W3Hint(target,HINT_COOLDOWN_NOTREADY,5.0,"You've been blinded by a Dark Elf!");
				W3Hint(client,HINT_COOLDOWN_NOTREADY,5.0,"DarkOrb blinded Successfully");
			}
		}
	}
}
public Action UndisarmClient(Handle timer, int ref){
	int client = EntRefToEntIndex(ref);
	if(IS_PLAYER(client)){
		War3_SetBuff(client,bDisarm,thisRaceID,false);
	}
	return Plugin_Stop;
}
/*
public bool:DarkorbFilter(client,target)
{
	if(W3HasImmunity(target,Immunity_Ultimates))
	{
		War3_NotifyPlayerImmuneFromSkill(client, target, ULTIMATE_DARKORB);
		return false;
	}
	return true;
}*/

public Action OnW3TakeDmgBulletPre(int victim, int attacker, float damage, int damagecustom)
{
	if(RaceDisabled)
		return Plugin_Continue;

	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_victim=War3_GetRace(victim);
			if(race_victim==thisRaceID)
			{
				new skill_level_fade=War3_GetSkillLevel(victim,thisRaceID,SKILL_FADE);
				if( !Hexed(victim,false) && GetRandomFloat(0.0,1.0)<=FadeChance[skill_level_fade])
				{
					if(!W3HasImmunity(attacker,Immunity_Skills))
					{
						W3FlashScreen(victim,{244,244,244,50},0.2,0.2,FFADE_OUT);

						War3_SetBuff(victim,fInvisibilitySkill,thisRaceID,0.05);

						new skill_level_fade_reaction=War3_GetSkillLevel(victim,thisRaceID,SKILL_SLOWFALL);
						War3_DecreaseHP(victim,FadeReaction[skill_level_fade_reaction]);
						CreateTimer(1.2,FadeTimer,victim);
					}
					else
					{
						War3_NotifyPlayerImmuneFromSkill(victim, attacker, SKILL_FADE);
					}

				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:FadeTimer(Handle:timer,any:victim)
{

	War3_SetBuff(victim,fInvisibilitySkill,thisRaceID,1.0);
	if(War3_GetRace(victim)==thisRaceID)
	{
		new skill_level_fade_reaction=War3_GetSkillLevel(victim,thisRaceID,SKILL_SLOWFALL);
		new IncreaseHealthBy=FadeReactionGain[skill_level_fade_reaction];
		War3_HealToMaxHP(victim,IncreaseHealthBy);
	}
}

public void OnWar3EventSpawn(int client)
{
	StopTribunal(client);
}

public void OnAbilityCommand(int client, int ability, bool pressed, bool bypass)
{
	if(RaceDisabled)
		return;

	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && ValidPlayer(client,true))
	{
		new skilllvl = War3_GetSkillLevel(client,thisRaceID,SKILL_TRIBUNAL);
		new Float:speed = TribunalSpeed[skilllvl];
		new Float:decay = TribunalDecay[skilllvl];
		if(!Silenced(client))
		{	//W3SetPlayerColor(client,raceid,r,g,b,a=255,overridepriority=GLOW_DEFAULT)
			//W3SetPlayerColor(client,thisRaceID,128,0,128,255); //purple:D not sure if works
			War3_EmitSoundToAll(tribunal,client);
			if(IsInTribunal[client]){
				StopTribunal(client);
			}
			else{
				IsInTribunal[client]=true;
				War3_SetBuff(client,fMaxSpeed,thisRaceID,speed);
				War3_SetBuff(client,fHPDecay,thisRaceID,decay);

		//		CreateTimer(TribunalDuration,TribunalTimer,client);
				W3Hint(client,HINT_NORMAL,5.0,"You sacrificed for speed.");
			}
			//War3_CooldownMGR(client,TribunalCooldownTime,thisRaceID,SKILL_TRIBUNAL,_,_);
		}
	}
}

/*
public Action:TribunalTimer(Handle:timer,any:client)
{
	War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
	War3_SetBuff(client,fHPDecay,thisRaceID,0.0);
	W3ResetPlayerColor(client,thisRaceID);
}*/

/*
public Action:SlowfallTimer(Handle:timer,any:zclient)
{
	if(RaceDisabled)
		return;

	for(new client=1; client <= MaxClients; client++)
	{
		if(ValidPlayer(client, true))
		{
			if(War3_GetRace(client) == thisRaceID)
			{
				GetClientAbsOrigin(client,prevdarkvec);
				CreateTimer(0.1,Slowfall2Timer,client);
			}
		}

	}
}
public Action:Slowfall2Timer(Handle:timer,any:client)
{
	if(ValidPlayer(client, true)){
		GetClientAbsOrigin(client,darkvec);
		new flags = GetEntityFlags(client);
		if ( !(flags & FL_ONGROUND) )
		{

			if (darkvec[2]<prevdarkvec[2])
			{
				new skilllevel_levi=War3_GetSkillLevel(client,thisRaceID,SKILL_SLOWFALL);
				new Float:gravity=SlowfallGravity[skilllevel_levi];
				//DP("set %f",gravity);
				//War3_SetBuff(client,fLowGravitySkill,thisRaceID,gravity);
				if(!IsInvis(client)){
					AttachThrowAwayParticle(client, GetApparentTeam(client)==TEAM_RED?"teleporter_red_entrance":"teleporter_blue_entrance", darkvec, "", 1.0);
				}
			}
			else
			{
				//War3_SetBuff(client,fLowGravitySkill,thisRaceID,1.0);
				//DP("nograv2");
				//previousvec[2]=vec[2];
			}
		}
	}
}*/


public OnRaceChanged(client,oldrace,newrace)
{
	if(IsInTribunal[client]){
		StopTribunal(client);
	}
	if(newrace!=thisRaceID)
	{
		//War3_SetBuff(client,fLowGravitySkill,thisRaceID,1.0);
		//DP("nograv");
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
		W3ResetPlayerColor(client,thisRaceID);
		IsInTribunal[client]=false;
	}
}

StopTribunal(client)
{
	IsInTribunal[client]=false;
	War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
	War3_SetBuff(client,fHPDecay,thisRaceID,0.0);
}



