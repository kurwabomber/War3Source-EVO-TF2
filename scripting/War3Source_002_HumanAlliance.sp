#include <war3source>
#assert GGAMEMODE == MODE_WAR3SOURCE
#assert GGAMETYPE_JAILBREAK == JAILBREAK_OFF


#define RACE_ID_NUMBER 2
#define RACE_LONGNAME "Human Alliance"
#define RACE_SHORTNAME "humanally"

/**
* File: War3Source_HumanAlliance.sp
* Description: The Human Alliance race for War3Source.
* Author(s): Anthony Iacono, necavi
* Modified for TF2 Stability: El Diablo
*/
#define PLUGIN_VERSION "0.0.0.1"

public W3ONLY(){} //unload this?
int thisRaceID;

// Chance/Info Arrays
float BashChance[]={0.25, 0.27, 0.28, 0.29, 0.3};
float BashDuration[]={0.20, 0.225, 0.25, 0.275, 0.3};
float TeleportDistance[]={900.0, 950.0, 1000.0, 1150.0, 1200.0};

//#if GGAMETYPE == GGAME_TF2
//float InvisibilityAlphaTF[7]={1.0,0.84,0.68,0.56,0.40,0.35,0.30};
//#elseif GGAMETYPE == GGAME_CSS
//float InvisibilityAlphaTF[7]={1.0,0.90,0.8,0.7,0.6,0.5,0.4};
//#endif


new DevotionHealth[]={40,42,45,47,50};


// Effects
new BeamSprite,HaloSprite;

float WhiskSpeed[]={1.16,1.17,1.18,1.19,1.2};


new SKILL_SPEED, SKILL_BASH, SKILL_HEALTH,ULT_TELEPORT; //, ULT_IMPROVED_TELEPORT;

/*
new ClientTracer;
float emptypos[3];
float oldpos[MAXPLAYERSCUSTOM][3];
float teleportpos[MAXPLAYERSCUSTOM][3];
new bool:inteleportcheck[MAXPLAYERSCUSTOM];
*/

new String:teleportSound[]="war3source/blinkarrival.mp3";
public Plugin:myinfo =
{
	name = "Race - Human Alliance",
	author = "PimpinJuice, necavi, El Diablo",
	description = "The Human Alliance race for War3Source.",
	version = "1.0",
	url = "http://war3source.com"
};

bool HooksLoaded = false;
public void Load_Hooks()
{
	if(HooksLoaded) return;
	HooksLoaded = true;

	W3Hook(W3Hook_OnUltimateCommand, OnUltimateCommand);
	W3Hook(W3Hook_OnWar3EventSpawn, OnWar3EventSpawn);
}
public void UnLoad_Hooks()
{
	if(!HooksLoaded) return;
	HooksLoaded = false;

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
//	if(RaceDisabled)
//		return;


public OnW3Denyable(W3DENY:event,client)
{
	if(RaceDisabled)
		return;

	if(War3_GetRace(client)==thisRaceID)
	{
		if((event == DN_CanBuyItem1) && (W3GetVar(EventArg1) == War3_GetItemIdByShortname("gauntlet")))
		{
			W3Deny();
			War3_ChatMessage(client, "The gauntlet is too heavy ...");
		}
	}
}

public OnPluginStart()
{
	CreateConVar("HumanAlliance",PLUGIN_VERSION,"War3Source:EVO Human Alliance");
	//LoadTranslations("w3s.race.humanally.phrases");
}

public OnWar3LoadRaceOrItemOrdered2(num,reloadrace_id,String:shortname[])
{
	if(num==RACE_ID_NUMBER||(reloadrace_id>0&&StrEqual(RACE_SHORTNAME,shortname,false)))
	{

		thisRaceID=War3_CreateNewRace(RACE_LONGNAME,RACE_SHORTNAME,reloadrace_id,"Teleport,Invis,+hp");
		SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Whisk","Increases movement speed by 16->20%.",false,4);
		SKILL_HEALTH=War3_AddRaceSkill(thisRaceID,"Devotion Aura","Gives you additional 40->50 health.",false,4);
		SKILL_BASH=War3_AddRaceSkill(thisRaceID,"Bash","7/13/19/25% chance to bash the enemy.\nRenders the enemy immobile for 0.2->0.3 seconds.\nInitial bash hit deals +30 damage.",false,4);
		ULT_TELEPORT=War3_AddRaceSkill(thisRaceID,"Teleport","Teleport toward where you aim.\nUp to 1200 HU range. Ultimate Immunity has 350 blocking radius.",true,4, "(voice Jeers)");
		War3_CreateRaceEnd(thisRaceID);
		War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, WhiskSpeed);
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
	BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();

	PrecacheSound(teleportSound);
}

public OnAddSound(sound_priority)
{
	if(sound_priority==PRIORITY_MEDIUM)
	{
		War3_AddSound(teleportSound);
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace==thisRaceID)
	{
		ActivateSkills(client);
	}
	else
	{
		//War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0); // if we aren't their race anymore we shouldn't be controlling their alpha
		War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,0);
		War3_SetBuff(client,fBashChance,thisRaceID,0.0);
		War3_SetBuff(client,iBashDamage,thisRaceID,0);
		War3_SetBuff(client,fBashDuration,thisRaceID,0.0);
		War3_SetBuff(client,fHPDecay,thisRaceID,0.0);
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
	}
}


/*
public OnWar3EventPostHurt(victim,attacker,float dmgamount,const String:weapon[32],bool:isWarcraft)
{
	if(!isWarcraft && ValidPlayer(attacker) && War3_GetRace(attacker)==thisRaceID && StrContains(weapon,"kunai",false))
	{
		if(War3_GetMaxHP(attacker)<GetClientHealth(attacker))
		{
			War3_SetBuff(attacker,fHPDecay,thisRaceID,2.0);
		}
		else
		{
			War3_SetBuff(attacker,fHPDecay,thisRaceID,0.0);
		}
	}
} */

public ActivateSkills(client)
{
	new skill_devo=War3_GetSkillLevel(client,thisRaceID,SKILL_HEALTH);
	// Devotion Aura
	new hpadd=DevotionHealth[skill_devo];
	float vec[3];
	GetClientAbsOrigin(client,vec);
	vec[2]+=20.0;
	new ringColor[4]={0,0,0,0};
	new team=GetClientTeam(client);
	if(team==2)
	{
		ringColor={255,0,0,255};
	}
	else if(team==3)
	{
		ringColor={0,0,255,255};
	}
	TE_SetupBeamRingPoint(vec,40.0,10.0,BeamSprite,HaloSprite,0,15,1.0,15.0,0.0,ringColor,10,0);
	TE_SendToAll();

#if (GGAMETYPE == GGAME_CSS || GGAMETYPE == GGAME_CSGO)
	new old_health=GetClientHealth(client);
	SetEntityHealth(client,old_health+hpadd);
#endif

	War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,hpadd);

	//new skilllevel=War3_GetSkillLevel(client,thisRaceID,SKILL_INVIS);
	//float alpha=InvisibilityAlphaTF[skilllevel];

	//War3_SetBuff(client,fInvisibilitySkill,thisRaceID,alpha);

	new skill_bash=War3_GetSkillLevel(client,thisRaceID,SKILL_BASH);
	float bash=BashChance[skill_bash];
	float bashDuration=BashDuration[skill_bash];
	War3_SetBuff(client,fBashChance,thisRaceID,bash);
	War3_SetBuff(client,fBashDuration,thisRaceID,bashDuration);
	War3_SetBuff(client,iBashDamage,thisRaceID,30);
}


//new TPFailCDResetToRace[MAXPLAYERSCUSTOM];
//new TPFailCDResetToSkill[MAXPLAYERSCUSTOM];

public void OnUltimateCommand(int client, int race, bool pressed, bool bypass)
{
	if(RaceDisabled)
		return;

	new userid=GetClientUserId(client);
	if(race==thisRaceID && pressed && userid>1 && IsPlayerAlive(client) && !Silenced(client))
	{
		new ult_level=War3_GetSkillLevel(client,race,ULT_TELEPORT);
		if(War3_SkillNotInCooldown(client,thisRaceID,ULT_TELEPORT,true)) //not in the 0.2 second delay when we check stuck via moving
		{
			W3Teleport(client,_,_,TeleportDistance[ult_level],thisRaceID,ULT_TELEPORT);
			/*
			TPFailCDResetToRace[client]=War3_GetRace(client);
			TPFailCDResetToSkill[client]=ULT_TELEPORT;
			new bool:success = Teleport(client,TeleportDistance[ult_level]);
			if(success)
			{
				float cooldown=GetConVarFloat(ultCooldownCvar);
				War3_CooldownMGR(client,cooldown,thisRaceID,ULT_TELEPORT,_,_);
			}*/
		}
	}
	else
	{
		if(Silenced(client))
		{
			W3Hint(client,HINT_LOWEST,5.0,"Can't use teleport because you have been silenced!");
		}
	}
}

public OnW3Teleported(client,target,distance,raceid,skillid)
{
	if(ValidPlayer(client) && raceid==thisRaceID)
	{
		War3_CooldownMGR(client,20.0,thisRaceID,ULT_TELEPORT,_,_);
		EmitSoundToAll(teleportSound,client);
	}
}

public Action:OnW3TeleportLocationChecking(client,Float:playerVec[3])
{
	if(ValidPlayer(client) && War3_GetRace(client)==thisRaceID)
	{
		//DP("teleport location checking");
		//ELIMINATE ULTIMATE IF THERE IS IMMUNITY AROUND
		float otherVec[3];
		new team = GetClientTeam(client);
		//new skilllevel=War3_GetSkillLevel(client,thisRaceID,ULT_IMPROVED_TELEPORT);

		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true)&&GetClientTeam(i)!=team)
			{
				GetClientAbsOrigin(i,otherVec);
				float resistance = W3GetBuffStackedFloat(i, fUltimateResistance);

				if(W3HasImmunity(i,Immunity_Ultimates)){
					if(GetVectorDistance(playerVec,otherVec)<350)
					{
						War3_NotifyPlayerImmuneFromSkill(client, i, ULT_TELEPORT);
						return Plugin_Handled;
					}
				}
				else if(resistance != 1.0){
					if(GetVectorDistance(playerVec,otherVec)<350*(1-resistance))
					{
						War3_NotifyPlayerImmuneFromSkill(client, i, ULT_TELEPORT);
						return Plugin_Handled;
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
		if(newskilllevel>=0)
		{
			if(skill==SKILL_HEALTH) //1
			{
				// Devotion Aura
				new hpadd=DevotionHealth[newskilllevel];
				float vec[3];
				GetClientAbsOrigin(client,vec);
				vec[2]+=20.0;
				new ringColor[4]={0,0,0,0};
				new team=GetClientTeam(client);
				if(team==2)
				{
					ringColor={255,0,0,255};
				}
				else if(team==3)
				{
					ringColor={0,0,255,255};
				}
				TE_SetupBeamRingPoint(vec,40.0,10.0,BeamSprite,HaloSprite,0,15,1.0,15.0,0.0,ringColor,10,0);
				TE_SendToAll();

#if (GGAMETYPE == GGAME_CSS || GGAMETYPE == GGAME_CSGO)
				new old_health=GetClientHealth(client);
				SetEntityHealth(client,old_health+hpadd);
#endif

				War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,hpadd);
			}
			else if(skill==SKILL_BASH) //1
			{
				War3_SetBuff(client,fBashChance,thisRaceID,BashChance[newskilllevel]);
				War3_SetBuff(client,fBashDuration,thisRaceID,BashDuration[newskilllevel]);
			}
		}
	}
}

public void OnWar3EventSpawn(int client)
{
	if(RaceDisabled)
		return;

	if(War3_GetRace(client)==thisRaceID)
	{
		ActivateSkills(client);
	}
}

