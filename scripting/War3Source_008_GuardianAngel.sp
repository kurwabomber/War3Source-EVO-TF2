//  UPDATED: 3/25/2012 9:30am EST
//
// ========================================================================== */
//                                                                            */
//   War3Source_Customrace_Angel.sp                                           */                      */
//   2012 El Diablo                                                           */
//   idea by Axin                                                             */
//                                                                            */
//                                                                            */
// ========================================================================== */
// My own Functions:
// GetSpectatorCount, IsFlyingAllowed
//
// Rcon variables:
//command                     default
//war3angel_scout_nofly        false
//war3angel_soldier_nofly      false
//war3angel_pyro_nofly         false
//war3angel_demoman_nofly      false
//war3angel_heavy_nofly        true
//war3angel_engineer_nofly     false
//war3angel_medic_nofly        false
//war3angel_sniper_nofly       true
//war3angel_spy_nofly          true
//
//SONG_HealAmountCvar          1.0
// The song HealAmount 0.0-1.0  while 1.0 is equal to 100% of max health to heal.

#pragma semicolon 1    ///WE RECOMMEND THE SEMICOLON
#pragma tabsize 0     // doesn't mess with how you format your lines

#include <war3source>
#assert GGAMEMODE == MODE_WAR3SOURCE

public W3ONLY(){} //unload this?  

public Plugin:myinfo = 
{
	 name = "Angels - Guardian Angel",
	 author = "El Diablo (IDEA BY Axin)",
	 description = "This race is mainly for Pushing and Supporting teammates on the go",
	 version = "1.52",
	 url = "http://cgaclan.com"
};

#define NO_ATTACH 0
#define ATTACH_NORMAL 1
#define ATTACH_HEAD 2

// LUNA
new XBeamSprite,HaloSprite;
new String:beamsnd[256]; // = "war3source/moonqueen/beam.mp3";
new LucentBeamMin[] = {16,17,18,19,20};
new LucentBeamMax[] = {19,20,21,22,23};


const Float:version_num = 1.0; 
const Maximum_Players_array=100;

// Prevent Healing player twice
new bool:SONG[Maximum_Players_array];

// Declare Global Variables
new Handle:ultCooldownCvar_SPAWN;
new Handle:ultCooldownCvar;
new Handle:SONG_HealAmountCvar;

new Handle:NoFly_Scout;
new Handle:NoFly_Soldier;
new Handle:NoFly_Pyro;
new Handle:NoFly_Demoman;
new Handle:NoFly_Heavy;
new Handle:NoFly_Engineer;
new Handle:NoFly_Medic;
new Handle:NoFly_Sniper;
new Handle:NoFly_Spy;

new thisRaceID;
#define RACE_ID_NUMBER 8
#define RACE_LONGNAME "Guardian Angel"
#define RACE_SHORTNAME "angel"

new SKILL_SONG,ULTIMATE_LORDSREWARD,SKILL_HOLYSWORD,ABILITY_WINGSOFGLORY,SKILL_MOONBEAM;

// PRAYERS SONG
new Float:song_timer_count[]={3.0,2.75,2.5,2.25,2.0};   //90 secs, 70 secs, 50 secs, 30 secs
new Timer_Song_counter[Maximum_Players_array];

// MAD MILK
new Float:MadMilkRadius[] = {650.0, 700.0,750.0,800.0,850.0};
new Float:MadMilkDuration[] = {10.0, 11.0,12.0,13.0,14.0};

// WINGS OF GLORY
new Float:WingsOfGlory_Duration[] = { 9.0, 10.0, 11.0, 12.0, 13.0};
new Float:WingsOfGlory_Speed[] = {3.00, 3.0, 3.0, 3.0, 3.0};
new Float:WingsofGlory_Cooldown_Timer = 22.0;

// HOLY SWORD DAMAGE
new Float:HolySword_extradmg[] = { 0.16, 0.17, 0.18, 0.19, 0.2};

// Sounds
new String:MadMilkSoundd[] = "war3source/waterdrop.wav";
new String:BlessingSoundd[] = "war3source/holygrail.wav";

new ExplosionModel;

bool HooksLoaded = false;
public void Load_Hooks()
{
	if(HooksLoaded) return;
	HooksLoaded = true;

	W3Hook(W3Hook_OnUltimateCommand, OnUltimateCommand);
	W3Hook(W3Hook_OnAbilityCommand, OnAbilityCommand);
	W3Hook(W3Hook_OnW3TakeDmgBullet, OnW3TakeDmgBullet);
}
public void UnLoad_Hooks()
{
	if(!HooksLoaded) return;
	HooksLoaded = false;

	W3Unhook(W3Hook_OnUltimateCommand, OnUltimateCommand);
	W3Unhook(W3Hook_OnAbilityCommand, OnAbilityCommand);
	W3Unhook(W3Hook_OnW3TakeDmgBullet, OnW3TakeDmgBullet);
}
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

enum FX
{
	FxNone = 0,
	FxPulseFast,
	FxPulseSlowWide,
	FxPulseFastWide,
	FxFadeSlow,
	FxFadeFast,
	FxSolidSlow,
	FxSolidFast,
	FxStrobeSlow,
	FxStrobeFast,
	FxStrobeFaster,
	FxFlickerSlow,
	FxFlickerFast,
	FxNoDissipation,
	FxDistort,               // Distort/scale/translate flicker
	FxHologram,              // kRenderFxDistort + distance fade
	FxExplode,               // Scale up really big!
	FxGlowShell,             // Glowing Shell
	FxClampMinScale,         // Keep this sprite from getting very small (SPRITES only!)
	FxEnvRain,               // for environmental rendermode, make rain
	FxEnvSnow,               //  "        "            "    , make snow
	FxSpotlight,
	FxRagdoll,
	FxPulseFastWider,
};

enum Render
{
	Normal = 0, 		// src
	TransColor, 		// c*a+dest*(1-a)
	TransTexture,		// src*a+dest*(1-a)
	Glow,				// src*a+dest -- No Z buffer checks -- Fixed size in screen space
	TransAlpha,			// src*srca+dest*(1-srca)
	TransAdd,			// src*a+dest
	Environmental,		// not drawn, used for environmental effects
	TransAddFrameBlend,	// use a fractional frame value to blend between animation frames
	TransAlphaAdd,		// src + dest*(1-a)
	WorldGlow,			// Same as kRenderGlow but not fixed size in screen space
	None,				// Don't render.
};

/* ****************************** OnWar3LoadRaceOrItemOrdered2 ************************** */

public OnWar3LoadRaceOrItemOrdered2(num,reloadrace_id,String:shortname[])
{
	if(num==RACE_ID_NUMBER||(reloadrace_id>0&&StrEqual(RACE_SHORTNAME,shortname,false)))
	{
		thisRaceID=War3_CreateNewRace(RACE_LONGNAME,RACE_SHORTNAME,reloadrace_id,"Flight & support.");
		SKILL_SONG=War3_AddRaceSkill(thisRaceID,"Prayers Song","Every 30 to 20 seconds, the lowest HP player on your team gets 50% of max health.",false,4);
		ABILITY_WINGSOFGLORY=War3_AddRaceSkill(thisRaceID,"Wings of Glory","[+ability] Flight for 9-13 seconds.\nLeveling increases speed & duration.\n3x speed modifier.",false,4);
		SKILL_HOLYSWORD=War3_AddRaceSkill(thisRaceID,"Powerful Judgement","16-20% more damage.",false,4);
		SKILL_MOONBEAM =War3_AddRaceSkill(thisRaceID,"Angel's Light","Up to 20-23 dmg. Autocast. 5s cooldown.",false,4);
		ULTIMATE_LORDSREWARD=War3_AddRaceSkill(thisRaceID,"Lords Reward","In a 650 to 850HU radius, splashes Mad Milk Effect for 10 to 14 seconds.",true,4);
		W3SkillCooldownOnSpawn( thisRaceID, ULTIMATE_LORDSREWARD, GetConVarFloat(ultCooldownCvar_SPAWN) );
		War3_CreateRaceEnd(thisRaceID);
	}
}
public OnW3Denyable(W3DENY:event,client)
{
	if((event == DN_CanBuyItem1))
	{
		if(War3_GetRace(client)==thisRaceID)
		{
			if((W3GetVar(EventArg1) == War3_GetItemIdByShortname("claw")))
			{
				W3Deny();
				War3_ChatMessage(client, "You are unable to use this item!");
			}
			if((W3GetVar(EventArg1) == War3_GetItemIdByShortname("armband")))
			{
				W3Deny();
				War3_ChatMessage(client, "You are unable to use this item!");
			}
		}
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
/* ****************************** OnPluginStart ************************** */

public OnPluginStart()
{
//Create race specific Cvars here
	ultCooldownCvar_SPAWN=CreateConVar("war3_angel_ult_cooldown_spawn","10",
     "Angel's Ultimate Cooldown on spawn.");
	ultCooldownCvar=CreateConVar("war3_angel_ult_cooldown","20",
     "Cooldown");
     SONG_HealAmountCvar=CreateConVar("war3_angel_healamount","0.50",
     "The percentage of max player health the Guardian Angel will heal. (0.00 - 1.00) Default = 0.50 (50%)",
     _,true,0.0,true,1.0);

     NoFly_Scout=CreateConVar("war3angel_scout_nofly","0",
     "If 1, Scout will get alternative for Wings of Glory and will not be able to fly. Def = 0");
     NoFly_Soldier=CreateConVar("war3angel_soldier_nofly","0",
     "If 1, Soldier will get alternative for Wings of Glory and will not be able to fly. Def = 0");
     NoFly_Pyro=CreateConVar("war3angel_pyro_nofly","0",
     "If 1, Pyro will get alternative for Wings of Glory and will not be able to fly. Def = 0");
     NoFly_Demoman=CreateConVar("war3angel_demoman_nofly","0",
     "If 1, Demoman will get alternative for Wings of Glory and will not be able to fly. Def = 0");
     NoFly_Heavy=CreateConVar("war3angel_heavy_nofly","0",
     "If 1, Heavy will get alternative for Wings of Glory and will not be able to fly. Def = 1");
     NoFly_Engineer=CreateConVar("war3angel_engineer_nofly","0",
     "If 1, Engineer will get alternative for Wings of Glory and will not be able to fly. Def = 0");
     NoFly_Medic=CreateConVar("war3angel_medic_nofly","0",
     "If 1, Medic will get alternative for Wings of Glory and will not be able to fly. Def = 0");
     NoFly_Sniper=CreateConVar("war3angel_sniper_nofly","0",
     "If 1, Sniper will get alternative for Wings of Glory and will not be able to fly. Def = 0");
     NoFly_Spy=CreateConVar("war3angel_spy_nofly","0",
     "If 1, Spy will get alternative for Wings of Glory and will not be able to fly. Def = 1");


//Hook events here!!!!
	HookEvent("player_hurt",PlayerHurtEvent);
	HookEvent("player_spawn", Event_PlayerreSpawn);
	HookEvent("player_changeclass", Event_PlayerreSpawn);
  //HookEvent("player_healed",PlayerHealEvent);
  //HookEvent("teamplay_round_start",TeamplayRoundStartEvent);
	HookConVarChange(ultCooldownCvar_SPAWN, W3CvarCooldownHandler);
	HookConVarChange(SONG_HealAmountCvar, W3CvarSONG_HealAmountCvar);
    HookConVarChange(NoFly_Scout, W3CvarNoFly_Scout);
    HookConVarChange(NoFly_Soldier, W3CvarNoFly_Soldier);
    HookConVarChange(NoFly_Pyro, W3CvarNoFly_Pyro);
    HookConVarChange(NoFly_Demoman, W3CvarNoFly_Demoman);
    HookConVarChange(NoFly_Heavy, W3CvarNoFly_Heavy);
    HookConVarChange(NoFly_Engineer, W3CvarNoFly_Engineer);
    HookConVarChange(NoFly_Medic, W3CvarNoFly_Medic);
    HookConVarChange(NoFly_Sniper, W3CvarNoFly_Sniper);
    HookConVarChange(NoFly_Spy, W3CvarNoFly_Spy);
}
public Event_PlayerreSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(War3_GetRace(client)==thisRaceID)
	{
		RemovePassiveSkills(client);
	}
}
/* ****************************** OnMapStart ************************** */

public OnMapStart() 
{
    // mad milk
	ExplosionModel = PrecacheModel( "materials/sprites/zerogxplode.vmt", false );
	PrecacheSound( "weapons/jar_explode.wav", false );
	PrecacheSound(MadMilkSoundd, false );
	PrecacheSound(BlessingSoundd, false );
    CreateTimer(10.0,Timer_Song,_,TIMER_REPEAT);
    for(new i;i<Maximum_Players_array;i++)
    {
     SONG[i]=false;
    }

	strcopy(beamsnd,sizeof(beamsnd),"war3source/moonqueen/beam.mp3");
//	strcopy(lunasnd2,sizeof(lunasnd2),"war3source/flashbang_explode2.mp3");
	//BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();
	//BlueSprite = PrecacheModel( "materials/sprites/physcannon_bluelight1.vmt" );
	XBeamSprite = PrecacheModel( "materials/sprites/XBeam2.vmt" );
	//PrecacheModel("particle/fire.vmt");
}

/* ****************************** OnRaceChanged ************************** */

public OnRaceChanged(client,oldrace,newrace)
{
    if(newrace==thisRaceID)
    {
       InitPassiveSkills(client);
    }
    else
    {
        RemovePassiveSkills(client);
    }                
}

/* ****************************** OnWar3PluginReady ************************** */

//public OnWar3PluginReady()
//{
// Plug in version during TESTING:  
//}

/* ****************************** W3CvarCooldownHandler ************************** */

public W3CvarCooldownHandler(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	new Float:value = StringToFloat(newValue);
	if(value>0.0)
	W3SkillCooldownOnSpawn( thisRaceID, ULTIMATE_LORDSREWARD, value );
}

/* ****************************** W3CvarSONG_HealAmountCvar ************************** */

public W3CvarSONG_HealAmountCvar(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	new Float:value = StringToFloat(newValue);
    SetConVarFloat(SONG_HealAmountCvar,value);
}

/* ****************************** W3CvarNoFly_Scout ************************** */

public W3CvarNoFly_Scout(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	new value = StringToInt(newValue);
    SetConVarInt(NoFly_Scout,value);
}

/* ****************************** W3CvarNoFly_Soldier ************************** */

public W3CvarNoFly_Soldier(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	new value = StringToInt(newValue);
    SetConVarInt(NoFly_Soldier,value);
}

/* ****************************** W3CvarNoFly_Pyro ************************** */

public W3CvarNoFly_Pyro(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	new value = StringToInt(newValue);
    SetConVarInt(NoFly_Pyro,value);
}

/* ****************************** W3CvarNoFly_Demoman ************************** */

public W3CvarNoFly_Demoman(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	new value = StringToInt(newValue);
    SetConVarInt(NoFly_Demoman,value);
}

/* ****************************** W3CvarNoFly_Heavy ************************** */

public W3CvarNoFly_Heavy(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	new value = StringToInt(newValue);
    SetConVarInt(NoFly_Heavy,value);
}

/* ****************************** W3CvarNoFly_Engineer ************************** */

public W3CvarNoFly_Engineer(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	new value = StringToInt(newValue);
    SetConVarInt(NoFly_Engineer,value);
}

/* ****************************** W3CvarNoFly_Medic ************************** */

public W3CvarNoFly_Medic(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	new value = StringToInt(newValue);
    SetConVarInt(NoFly_Medic,value);
}

/* ****************************** W3CvarNoFly_Sniper ************************** */

public W3CvarNoFly_Sniper(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	new value = StringToInt(newValue);
    SetConVarInt(NoFly_Sniper,value);
}

/* ****************************** W3CvarNoFly_Spy ************************** */

public W3CvarNoFly_Spy(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	new value = StringToInt(newValue);
    SetConVarInt(NoFly_Spy,value);
}



/* ****************************** PlayerHealEvent ************************** */

//public PlayerHealEvent( Handle:event, const String:name[], bool:dontBroadcast )
//{
//
//}


/* ****************************** TeamplayRoundStartEvent ************************** */

//public TeamplayRoundStartEvent( Handle:event, const String:name[], bool:dontBroadcast )
//{

/*    for(new i;i<Maximum_Players_array;i++)
    {
     SONG[i]=false;
    } */

//}


/* ****************************** OnWar3EventPostHurt ************************** */
/*
public OnWar3EventPostHurt( victim, attacker, damage )
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_holysword = War3_GetSkillLevel( attacker, thisRaceID, SKILL_HOLYSWORD );
            if( !W3HasImmunity( victim, Immunity_Skills ) && skill_holysword>0 )
				{
                    //new Float:moredmg = float(damage) * HolySword_extradmg[skill_holysword];
                    //new nonfloat_dmg = RoundFloat(moredmg);
                    //War3_DealDamage( victim, nonfloat_dmg, attacker, _, "Powerful Judgement", W3DMGORIGIN_SKILL, W3DMGTYPE_MAGIC );
                    //damage = damage + nonfloat_dmg;
                    //W3Hint(attacker,HINT_NORMAL,1.0,"Damage %i!",damage);
				}
		}
	}
} */

/* ****************************** OnSkillLevelChanged ************************** */

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
    InitPassiveSkills(client);
}

public InitPassiveSkills(client)
{
    if(War3_GetRace(client)==thisRaceID)
    {
     War3_SetBuff(client,fSlow,thisRaceID,1.0);
     War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
     // Powerful Judgement
     new skilllevel=War3_GetSkillLevel(client,thisRaceID,SKILL_HOLYSWORD);
     War3_SetBuff(client,fDamageModifier,thisRaceID,HolySword_extradmg[skilllevel]);
   }
}

/* ****************************** RemovePassiveSkills ************************** */

public RemovePassiveSkills(client)
{
 War3_SetBuff(client,fSlow,thisRaceID,1.0);
 War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
 // Wings of Glory Reset
 War3_SetBuff(client,bSlowImmunity,thisRaceID,0.0);
 War3_SetBuff(client,bImmunitySkills,thisRaceID,0.0);
 War3_SetBuff(client,bImmunityUltimates,thisRaceID,0.0);
 War3_SetBuff(client,bImmunityWards,thisRaceID,0.0);
 W3ResetPlayerColor(client,thisRaceID);
 War3_SetBuff(client,bFlyMode,thisRaceID,0.0);
 // Powerful Judgement
 War3_SetBuff(client,fDamageModifier,thisRaceID,0.0);
 // Song Reset
 //SONG[client]=false;
}

/* ****************************** GetSpectatorCount ************************** */

stock GetSpectatorCount(){
new Spectator_Count=0;
     for(new ic;ic<Maximum_Players_array;ic++)
    {
     if(ValidPlayer(ic))
      {
       if(GetClientTeam(ic)==1)
        {
         Spectator_Count++;
        }
      }
    }
  return Spectator_Count;
}

/* ****************************** Action:Timer_Song ************************** */

public Action:Timer_Song(Handle:timer)
{

// Check to see if we need to reset SONG[] prevention of players
// getting healing from Guardian Angel Race.
// SONG is true when the player has recieved healing, false if not.
// if all SONGs are true, then reset SONGS.
//new bool:SONG_Check=false;
new SONG_Check_Count=0;

     for(new ia;ia<Maximum_Players_array;ia++)
    {
     if(SONG[ia]==true)
      {
      //SONG_Check=true;
      SONG_Check_Count++;
      }
    }

new Number_of_current_players = GetClientCount(true) - GetSpectatorCount();

//PrintToChatAll("DEBUG: Number_of_current_players: %i   SONG_Check_Count: %i",Number_of_current_players,SONG_Check_Count);

if(SONG_Check_Count >= Number_of_current_players)
 {
 //PrintToChatAll("DEBUG: SONG_Check_Count: %i   Number_of_current_players: %i >>",SONG_Check_Count,Number_of_current_players);
// PrintToChatAll("SONG RESET");
   for(new ib;ib<Maximum_Players_array;ib++)
    {
     SONG[ib]=false;

    }
 }

for(new i;i<Maximum_Players_array;i++)
 {
  //if(ValidPlayer(i,true) && !IsFakeClient(i) && (War3_GetRace(i)==thisRaceID))
  if(ValidPlayer(i,true) && (War3_GetRace(i)==thisRaceID))
  {
    new skilllevel=War3_GetSkillLevel(i,thisRaceID,SKILL_SONG);
    //if(skilllevel>0 && War3_Chance(Song_chance[skilllevel]))
      Timer_Song_counter[i]++;
      if(Timer_Song_counter[i]>=song_timer_count[skilllevel])
      {
        Timer_Song_counter[i]=0;

        new pickplayerid=0;
        new pickplayerhealth=9999;
        new get_playerhealth;
        new get_MaxPlayerhealth;
        new Float:Player_percent_health=0.0;
        new iTeam = GetClientTeam(i);
        for(new x;x<Maximum_Players_array;x++)
         {
           //if(ValidPlayer(x,true,true) && !IsFakeClient(x))

           // HAD to ADD x>0 because ValidPlayer isn't catching it!
           if(ValidPlayer(x,true,true) && iTeam==GetClientTeam(x))
             {
             get_playerhealth=GetClientHealth(x);
             get_MaxPlayerhealth=War3_GetMaxHP(x);
             Player_percent_health = float(get_playerhealth / get_MaxPlayerhealth);
              if(Player_percent_health<0.30 && get_playerhealth<pickplayerhealth && get_playerhealth>0 && get_playerhealth!=get_MaxPlayerhealth && SONG[x]==false)
              //if(Player_percent_health<0.30 && get_playerhealth<pickplayerhealth && get_playerhealth>0 && get_playerhealth!=get_MaxPlayerhealth)
                {
                pickplayerid=x;
                pickplayerhealth=get_playerhealth;
                }
             }
         }
     //native War3_HealToMaxHP(client,addhp);
     //native War3_HealToBuffHP(client,addhp);

       if(ValidPlayer(pickplayerid,true,true) && pickplayerid!=i)
       {
        // Find Percent of Max health
          new Float:get_heal_percent=GetConVarFloat(SONG_HealAmountCvar);
          get_MaxPlayerhealth=War3_GetMaxHP(pickplayerid);
          get_playerhealth = RoundToCeil(float(get_MaxPlayerhealth) * get_heal_percent);

          War3_HealToMaxHP(pickplayerid,get_playerhealth);
          //War3_HealToBuffHP(pickplayerid,100);

		  new String:NameGuardianAngel[64];
		  GetClientName( i, NameGuardianAngel, 64 );

		  new String:NamePlayer[64];         //HINT_SKILL_STATUS
		  GetClientName( pickplayerid , NamePlayer, 64 );

          // Prevent player from getting same benefit again for a while
          SONG[pickplayerid]=true;

          EmitSoundToClient( pickplayerid, BlessingSoundd );

          CreateParticle("community_sparkle", 3.0, pickplayerid, 2,0.0,0.0,-25.0);
          CreateParticle("community_sparkle", 3.0, pickplayerid, 2,50.0,-25.0,-25.0);
          CreateParticle("community_sparkle", 3.0, pickplayerid, 2,50.0,0.0,-25.0);
          CreateParticle("community_sparkle", 3.0, pickplayerid, 2,25.0,0.0,-40.0);
          CreateParticle("community_sparkle", 3.0, pickplayerid, 2,100.0,-25.0,-25.0);
          CreateParticle("community_sparkle", 3.0, pickplayerid, 2,100.0,0.0,-25.0);
          CreateParticle("community_sparkle", 3.0, pickplayerid, 2,30.0,25.0,-25.0);
          W3Hint(i,HINT_NORMAL,1.0,"Your Prayers Song blessed %s!", NamePlayer);
          W3Hint(pickplayerid,HINT_NORMAL,1.0,"Guardian Angel %s blessed you!", NameGuardianAngel);
          //PrintToChatAll("DEBUG: \x05 %s Blessed %s",NameGuardianAngel,NamePlayer);

          //PrintToChat( i, "\x05>>> \x03Your Prayers Song blessed \x04%s", NamePlayer );
          //PrintToChat( pickplayerid, "\x05>>> \x03Your Guardian Angel \x04%s \x03blessed you!", NameGuardianAngel );
          //EmitSoundToClient( pickplayerid, BlessingSoundd );

          // Prevent player from being healed again this round
          //SONG[pickplayerid]=true;
       }
		//PrintHintText( i, "Prayers Song blessed s%!", NamePlayer);
		//PrintHintText( pickplayerid, "You have been blessed by s%!", NameGuardianAngel );

      }
    }
 }
}

             // Players can shoot down flying Angel:
/* ***************************  PlayerHurtEvent *************************************/

public PlayerHurtEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
	new victim = GetClientOfUserId( GetEventInt( event, "userid" ) );
	new attacker = GetClientOfUserId( GetEventInt( event, "attacker" ) );

	if( victim > 0 && attacker > 0 && attacker != victim && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( victim ) == thisRaceID )
		{
				//new skill_energy = War3_GetSkillLevel( attacker, thisRaceID, SKILL_MEDITATE );  //KI ENERGY
			if( ValidPlayer( victim, true, true ) == true )
			{
				//if( (skill_energy > 0) && (SkillFilter(victim)) && !War3_IsUbered(victim) && ARMOR_ENABLED==false )
				if(!War3_IsUbered(victim))
				{
					if(W3GetBuffHasTrue(victim,bFlyMode))
					{
						W3ResetAllBuffRace(victim,thisRaceID);
						W3Hint(victim,HINT_SKILL_STATUS,2.0,"You got hurt! Wings of Glory Ended!");
					}
				}
			}
		}
	}
}

/* ****************************** IsNoFly ************************** */

stock bool:IsNoFly(client){
        new bool:NoFly_Boolean=false;
	if(ValidPlayer(client))
	{
        if(TF2_GetPlayerClass(client)==TFClass_Scout && GetConVarInt(NoFly_Scout)==1) NoFly_Boolean=true;
        if(TF2_GetPlayerClass(client)==TFClass_Soldier && GetConVarInt(NoFly_Soldier)==1) NoFly_Boolean=true;
        if(TF2_GetPlayerClass(client)==TFClass_Pyro && GetConVarInt(NoFly_Pyro)==1) NoFly_Boolean=true;
        if(TF2_GetPlayerClass(client)==TFClass_DemoMan && GetConVarInt(NoFly_Demoman)==1) NoFly_Boolean=true;
        if(TF2_GetPlayerClass(client)==TFClass_Heavy && GetConVarInt(NoFly_Heavy)==1) NoFly_Boolean=true;
        if(TF2_GetPlayerClass(client)==TFClass_Engineer && GetConVarInt(NoFly_Engineer)==1) NoFly_Boolean=true;
        if(TF2_GetPlayerClass(client)==TFClass_Medic && GetConVarInt(NoFly_Medic)==1) NoFly_Boolean=true;
        if(TF2_GetPlayerClass(client)==TFClass_Sniper && GetConVarInt(NoFly_Sniper)==1) NoFly_Boolean=true;
        if(TF2_GetPlayerClass(client)==TFClass_Spy && GetConVarInt(NoFly_Spy)==1) NoFly_Boolean=true;
	}

   return NoFly_Boolean;
}


/* ****************************** Stop_WingsOfGlory ************************** */

public Action:Stop_WingsOfGlory(Handle:timer, any:client)
{
  W3ResetPlayerColor(client,thisRaceID);
  War3_SetBuff(client,fSlow,thisRaceID,1.0);
  War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
  W3Hint(client,HINT_SKILL_STATUS,1.0,"END OF:...Wings of Glory...");



  if(IsNoFly(client))
    {
     War3_SetBuff(client,bSlowImmunity,thisRaceID,0.0);
     War3_SetBuff(client,bImmunitySkills,thisRaceID,0.0);
     War3_SetBuff(client,bImmunityUltimates,thisRaceID,0.0);
     War3_SetBuff(client,bImmunityWards,thisRaceID,0.0);
    }
    else
    {
     War3_SetBuff(client,bFlyMode,thisRaceID,0.0);
     W3ResetPlayerColor(client,thisRaceID);
    }

}

/* ****************************** OnAbilityCommand ************************** */

public OnAbilityCommand(client,ability,bool:pressed)
{                              //bFlyMode
//native War3_SetBuff(client,W3Buff:buffindex,raceid,any:value);
//
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
     W3ResetAllBuffRace(client,thisRaceID);   // So that you can press +ability again to stop flymode.
     if(War3_SkillNotInCooldown(client,thisRaceID,ABILITY_WINGSOFGLORY,true))
      {
        new skilllevelz = War3_GetSkillLevel(client,thisRaceID,ABILITY_WINGSOFGLORY);

        War3_SetBuff(client,fSlow,thisRaceID,1.0);

        if(IsNoFly(client))
         {
			W3Hint(client,HINT_SKILL_STATUS,1.0,"Wings of Glory 2 (Immunities to Skills/Ultimates/Wards/Slow)+speed");
			War3_SetBuff(client,bSlowImmunity,thisRaceID,1.0);
			War3_SetBuff(client,bImmunitySkills,thisRaceID,1.0);
			War3_SetBuff(client,bImmunityUltimates,thisRaceID,1.0);
			War3_SetBuff(client,bImmunityWards,thisRaceID,1.0);
			War3_SetBuff(client,fMaxSpeed,thisRaceID,1.4);
         }
         else
         {
			War3_SetBuff(client,fMaxSpeed,thisRaceID,WingsOfGlory_Speed[skilllevelz]);
			War3_SetBuff(client,bFlyMode,thisRaceID,1.0);
			new Float:ClientPos[3];
			GetClientAbsOrigin( client, ClientPos );
			ClientPos[2] += 25;
			TeleportEntity( client, ClientPos, NULL_VECTOR, NULL_VECTOR );
			W3Hint(client,HINT_SKILL_STATUS,1.0,"Look up and Fly! Wings of Glory!");
         }

        // My hope was to create a glow effect around Guardian Angel, but couldn't get it to work.

        //W3SetPlayerColor(client,thisRaceID,255,255,255,150,GLOW_OVERRIDE);
        //AttachLight(client, NULL_VECTOR, "0 255 0 255", "5", 80.0, "eyes");
        // teleport up a little bit so flying is easier.
        //set_rendering(client,FxNone,255,255,0,TransColor,255);  // Glow effect
        //CreateParticle("community_sparkle", WingsOfGlory_Duration[skilllevelz], client, 2,0.0,25.0);
        //CreateParticle("community_sparkle", WingsOfGlory_Duration[skilllevelz], client, 2,0.0,-25.0);
        // head
        CreateParticle("community_sparkle", WingsOfGlory_Duration[skilllevelz], client, 2,0.0,0.0,0.0);
        CreateParticle("community_sparkle", WingsOfGlory_Duration[skilllevelz], client, 2,50.0,-25.0,0.0);
        CreateParticle("community_sparkle", WingsOfGlory_Duration[skilllevelz], client, 2,50.0,0.0,0.0);
        CreateParticle("community_sparkle", WingsOfGlory_Duration[skilllevelz], client, 2,50.0,25.0,0.0);
        CreateParticle("community_sparkle", WingsOfGlory_Duration[skilllevelz], client, 2,100.0,-25.0,0.0);
        CreateParticle("community_sparkle", WingsOfGlory_Duration[skilllevelz], client, 2,100.0,0.0,0.0);
        CreateParticle("community_sparkle", WingsOfGlory_Duration[skilllevelz], client, 2,100.0,25.0,0.0);
        // body
        CreateParticle("community_sparkle", WingsOfGlory_Duration[skilllevelz], client, 2,0.0,0.0,-25.0);
        CreateParticle("community_sparkle", WingsOfGlory_Duration[skilllevelz], client, 2,50.0,-25.0,-25.0);
        CreateParticle("community_sparkle", WingsOfGlory_Duration[skilllevelz], client, 2,50.0,0.0,-25.0);
        CreateParticle("community_sparkle", WingsOfGlory_Duration[skilllevelz], client, 2,25.0,0.0,-40.0);
        CreateParticle("community_sparkle", WingsOfGlory_Duration[skilllevelz], client, 2,100.0,-25.0,-25.0);
        CreateParticle("community_sparkle", WingsOfGlory_Duration[skilllevelz], client, 2,100.0,0.0,-25.0);
        CreateParticle("community_sparkle", WingsOfGlory_Duration[skilllevelz], client, 2,30.0,25.0,-25.0);
        // feet
        CreateParticle("community_sparkle", WingsOfGlory_Duration[skilllevelz], client, 2,30.0,0.0,-75.0);
        CreateParticle("critical_rocket_red", WingsOfGlory_Duration[skilllevelz], client, 2,20.0,0.0,-75.0);
        CreateParticle("critical_rocket_blue", WingsOfGlory_Duration[skilllevelz], client, 2,20.0,0.0,-75.0);
        CreateParticle("teleporter_red_charged_wisps", WingsOfGlory_Duration[skilllevelz], client, 2,10.0,0.0,-50.0);
        CreateParticle("teleporter_blue_charged_wisps", WingsOfGlory_Duration[skilllevelz], client, 2,10.0,0.0,-50.0);
        CreateParticle("teleporter_blue_entrance", WingsOfGlory_Duration[skilllevelz], client, 2,0.0,0.0,-50.0);
        CreateParticle("teleporter_red_entrance", WingsOfGlory_Duration[skilllevelz], client, 2,0.0,0.0,-50.0);

        //W3Hint(client,HINT_SKILL_STATUS,1.0,"Press +ability again to stop Wings of Glory");
        War3_CooldownMGR(client,WingsofGlory_Cooldown_Timer,thisRaceID,ABILITY_WINGSOFGLORY,true,true);
        CreateTimer(WingsOfGlory_Duration[skilllevelz],Stop_WingsOfGlory, client, _);
      }
    }

	if(War3_GetRace(client)==thisRaceID && ability==1 && pressed && IsPlayerAlive(client))
	{
	   //new skilllevelz = War3_GetSkillLevel(client,thisRaceID,ABILITY2_CARDTOSS);
     //stuff here
  }

}

/* ****************************** OnUltimateCommand ************************** */

public OnUltimateCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && pressed && IsPlayerAlive(client))
	{
		new skilllevelz = War3_GetSkillLevel(client,thisRaceID,ULTIMATE_LORDSREWARD);
		if(skilllevelz > 0)
		{
			if(!Silenced(client))
			{
				if(War3_SkillNotInCooldown(client,thisRaceID,ULTIMATE_LORDSREWARD,true))
				{
                   MadMilkBomber( client, skilllevelz );
                   new Float:MadMilkcooldowntime = GetConVarFloat(ultCooldownCvar);
                   War3_CooldownMGR(client,MadMilkcooldowntime,thisRaceID,ULTIMATE_LORDSREWARD,_,_);
                }
            }
        }
    }
}

public MadMilkBomber( client, level )
{
	if( level > 0 )
	{
		new Float:radius = MadMilkRadius[level];
		new our_team = GetClientTeam( client );
		new Float:client_location[3];

        GetClientAbsOrigin( client, client_location );

		TE_SetupExplosion( client_location, ExplosionModel, 10.0, 1, 0, RoundToFloor( radius ), 160 );
		TE_SendToAll();

		EmitSoundToAll( MadMilkSoundd, client );
		EmitSoundToAll( "weapons/jar_explode.wav", client );

		new Float:location_check[3];
		for( new x = 1; x <= MaxClients; x++ )
		{
			if( ValidPlayer( x, true ) && client != x )
			{
				new team = GetClientTeam( x );
				if( team != our_team )
				{
					GetClientAbsOrigin( x, location_check );
					new Float:distance = GetVectorDistance( client_location, location_check );
					if( distance < radius )
					{
						if( !W3HasImmunity( x, Immunity_Ultimates ) )
						{
                            TF2_AddCondition( x, TFCond_Milked, MadMilkDuration[level] );
                            //PrintToHint( x, "\x05: \x04You have been milked!");
                            //PrintToHint( client, "\x04 You Milked \x05: s%",x );

							//War3_ShakeScreen( x, 3.0 * factor, 250.0 * factor, 30.0 );
							W3FlashScreen( x, RGBA_COLOR_WHITE );
						}
						else
						{
							//PrintToConsole( client, "Could not mad milk {player} due to immunity", client, x );
						}
					}
				}
			}
		}
	}
}

stock set_rendering(index, FX:fx=FxNone, r=255, g=255, b=255, Render:render=Normal, amount=255)
{
	SetEntProp(index, Prop_Send, "m_nRenderFX", _:fx, 1);
	SetEntProp(index, Prop_Send, "m_nRenderMode", _:render, 1);

	new offset = GetEntSendPropOffs(index, "m_clrRender");

	SetEntData(index, offset, r, 1, true);
	SetEntData(index, offset + 1, g, 1, true);
	SetEntData(index, offset + 2, b, 1, true);
	SetEntData(index, offset + 3, amount, 1, true);
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


public Action:OnW3TakeDmgBullet( victim, attacker, Float:damage )
{
	if(IsValidEntity(victim) && IS_PLAYER( attacker ) && victim > 0 && attacker > 0 && attacker != victim )
	{
		if(ValidPlayer(victim,true))
		{
			if(GetClientTeam(victim)==GetClientTeam(attacker))
			{
				return;
			}
			if(W3HasImmunity(victim, Immunity_Skills))
			{
				return;
			}
		}
		new race_attacker = War3_GetRace( attacker );
		new skill_level = War3_GetSkillLevel( attacker, thisRaceID, SKILL_MOONBEAM );
		if( race_attacker == thisRaceID &&!Hexed(attacker))
		{
			if(skill_level > 0 && SkillAvailable(attacker,thisRaceID,SKILL_MOONBEAM,false))
			{
				MoonBeamDamageAndEffect(victim, attacker, LucentBeamMin[skill_level], LucentBeamMax[skill_level]);

				War3_CooldownMGR(attacker,3.0,thisRaceID,SKILL_MOONBEAM,true,false);
			}
		}
	}
}

MoonBeamDamageAndEffect(victim, attacker, min, max) {
	decl Float:start_pos[3];
	decl Float:end_pos2[3];
	
	GetEntPropVector(victim, Prop_Send, "m_vecOrigin", start_pos);
	GetEntPropVector(victim, Prop_Send, "m_vecOrigin", end_pos2);

	end_pos2[2] += 10000.0;
	//TE_SetupBeamPoints(const Float:start[3], const Float:end[3], ModelIndex, HaloIndex, StartFrame, FrameRate, Float:Life, Float:Width, Float:EndWidth, FadeLength, Float:Amplitude, const Color[4], Speed)
	TE_SetupBeamPoints(start_pos, end_pos2, XBeamSprite, HaloSprite, 0, 30, Float:1.0, Float:20.0, 20.0, 0, 0.0, {255,215,0,255}, 300);
	TE_SendToAll(0.0);

	//TE_SetupBeamRingPoint(const Float:center[3], Float:Start_Radius, Float:End_Radius, ModelIndex, HaloIndex, StartFrame, FrameRate, Float:Life, Float:Width, Float:Amplitude, const Color[4], Speed, Flags)
	TE_SetupBeamRingPoint(start_pos, 20.0, 99.0, XBeamSprite, HaloSprite, 0, 1, 0.5, 30.0, 0.0, {255,215,0,255}, 10, 0);
	TE_SendToAll(0.3);

	War3_DealDamage(victim, GetRandomInt(min, max), attacker ,DMG_FALL, "lucentbeam");
	if(ValidPlayer(victim,false))
	{
		W3PrintSkillDmgHintConsole(victim, attacker, War3_GetWar3DamageDealt(), SKILL_MOONBEAM);
	}

	EmitSoundToAll(beamsnd, victim);
	EmitSoundToAll(beamsnd, attacker);

}