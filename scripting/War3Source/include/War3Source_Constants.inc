/**
* File:
* While we do this, lets document this file. I saw a forum post requesting documentation in this file.
*/

//used for some special things in interface
#define WAR3MAIN

#if GGAMETYPE == GGAME_CSGO
#define HIDE_RADAR 1<<12
#define HIDEHUD_CHAT				( 1<<7 )	// Hide all communication elements (saytext, voice icon, etc)
#endif

#define ATTACKER_WORLD 0

//for all war3source or SH plugins, we define MAXPlAYERS as 66
//just so pigs dont fly when you run a 64 slot server with HLTV
#if GGAMETYPE == GGAME_TF2
#define MAXPLAYERSCUSTOM 34   //+2 of real for normal servers, add +X number of HLTV slots
#elseif (GGAMETYPE == GGAME_CSS || GGAMETYPE == GGAME_CSGO)
#define MAXPLAYERSCUSTOM 66   //+2 of real for normal servers, add +X number of HLTV slots
#endif


//dochecking up to <MAXRACES
//limit check up to >=MAXRACES-1

#define MAXRACES 200 //20 = [1]-[199]  ///can only hold X-1 races, IE 20 can only hold 19 races, we skip zeroth race!

#define MAXSKILLS 100

#define MAXITEMS view_as<int>(MAXITEMSCOUNT)+1  // [1]-[19] //(+1 of real number of items, if there are 8 items to load, use 9!! ignore zeroth rule)
#define MAXITEMS2 view_as<int>(MAXITEMSCOUNT2)+1
#define MAXITEMS3 view_as<int>(MAXITEMSCOUNT3)+1

enum SHOPITEMS1{
	ANKH=0,
	BOOTS,
	CLAW,
	CLOAK,
	MASK,
	NECKLACE,
	FROST,
	TOME,
	SOCK,
	RING,
	OIL,
	SHIELD,
	GAUNTLET,
	FIREORB,
	COURAGE,
	FAITH,
	ARMBAND,
	MBOOTS,
	MRING,
	MHEALTH,
	DIVINERAPIER, //+10 additive damage, is completely lost on death to person who killed you
	REFRESHERORB, //-30% ability cooldown
	GLIMMERCAPE, // Magic Defense
	BUCKLER, // Defense
	AGHANIMSCEPTRE, //Upgrades Ultimates
	ORBOFVENOM, //4 Magic DPS
	RINGOFPROTECTION, //Defense
	TALISMANOFEVASION, //Evasion 
	BLADEMAIL, // Defense + reflect
	ASSAULTCUIRASS, // Both Defense + attackspeed
	HEARTOFTARRASQUE, //PCT HPR
	NULLTALISMAN, //All Around Stat Boost
	DAEDALUS, //Crit Chance
	DESOLATOR, //Defense down on hit
	PANICNECKLACE, //Speed bonus when hit
	BLOODBOUNDGEM, //Amplify lifesteal & regen effects
	MEKANSM, //+35 HP heal every 5s.
	MANTLEOFINTEL, //+15% magic damage
	MAXITEMSCOUNT,
};

enum SHOPITEMS2{
	POSTHASTE=0,
	TRINKET,
	LIFETUBE,
	SNAKE_BRACELET,
	FORTIFIED_BRACER,
	LIGHTARMORPLATES,
	ENHANCEDWEAPONRY,
	SCROLLOFGROWTH,
	MAXITEMSCOUNT2
};

enum SHOPITEMS3{
	REDTEARSTONE=0,
	BLUETEARSTONE,
	STORMHEART,
	MARKSMAN,
	WINDPEARL,
	MAGMACHARM,
	SPRINGGEM,
	POISONGEM,
	RAGE,
	UBERHEART,
	FREEZE,
	SOLARCREST,
	RUNESHARD,
	SANGE,
	MAXITEMSCOUNT3
};
//zeroth item not used

//#define MAXBAGITEMS 3
//#define MAXJOBITEMS 3

// For War3_AddBotAI()
#define TRIGGERED_RANDOM_TIME						(1<<0)
#define TRIGGERED_WHEN_DAMAGED						(1<<1)
#define TRIGGERED_WHEN_HEALED						(1<<2)
#define TRIGGERED_NEAR_ENEMY						(1<<3)
#define TRIGGERED_NEAR_ALLY							(1<<4)
#define HAS_TRIGGERED_CHANCE_MODIFIER				(1<<5)
#define HAS_TRIGGERED_DPS_MODIFIER					(1<<6)
#define REQUIRES_ENEMY_TARGET						(1<<7)
#define REQUIRES_ALLY_TARGET						(1<<8)


#define MAXSKILLCOUNT 8 //[1]-[7]   //if you want 7 skills, use 8. A SKILL IS GENERIC, set the property "ultimate" to true for ultmates

#define DEF_MAX_SKILL_LEVEL 4 //DO NOT CHANGE

#define MAXLEVELXPDEFINED 32 //maximum where level XP is defined, if a race has more than MAXLEVELXPDEFINED levles, xp given and xp to next level is still MAXLEVELXPDEFINED

#define CUSTOMMODIFIERS 5 //how many race indexes extra for modifying buffs without conflicting other races

#define MAXAURAS 100 // [1- ] ignore zeroth index

#define SHORTNAMELEN 16 //item or race shotnames, 15 characters
#define FULLNAMELEN 32 //item or race full names, 31 characters. RUSSIAN and other characters require more than 1 byte to store a displayed character

#define MAXCATS 20 //max race categories

#define MAXFACTIONS 20 //max amount of factions w3 can hold
#define FACTION_LENGTH 32 //max length of a faction name

#define INVALID_DEPENDENCY -1 //describes the default/invalid value of a skill dependency

// The enum W3Var is used with function W3SetVar and internal_W3GetVar.
// It is the first parameter, eg: new deathRace = internal_W3GetVar(DeathRace)
enum W3Var
{
	OldRace, //the race he was before OnRaceChanged //REMOVE DEPRECATED
	DeathRace, //race when player died
	hDatabase, // Handle to database
	hDatabaseType, // DBI driver, ie sqlite or mysql
	hSaveEnabledCvar, //Handle to war3_savexp
	hRaceLimitEnabledCvar, // war3_racelimit_enable
	hNewPlayerLevelbankCvar, // war3_new_player_levelbank

	TheItemBoughtOrLost, // item in question in events such as item bought or item lost
	hPlayerInfoArgStr, // string argument after player says "playerinfo <arg>" if any
	RaceinfoRaceToShow, // who to show the raceinfo  ....
	EventArg1, //generic war3event arguments
	EventArg2,
	EventArg3,
	EventArg4,

	TransClient,//who to translate

	hUseMetricCvar, //handle to cvar

	SmEvent, ///usual game events from sm hooked events

	TheRaceItemBoughtOrLost, // special for shopmenu3 ownership

}
/* used by unused source: ESCompatLayer.sp
stock String:W3VarStrings[][32] = {"OldRace",
								"DeathRace",
								"hDatabase",
								"hDatabaseType",
								"hSaveEnabledCvar",
								"hRaceLimitEnabledCvar",
								"hNewPlayerLevelbankCvar",
								"TheItemBoughtOrLost",
								"hPlayerInfoArgStr",
								"RaceinfoRaceToShow",
								"EventArg1",
								"EventArg2",
								"EventArg3",
								"EventArg4",
								"TransClient",
								"hUseMetricCvar",
								"SmEvent",
								"TheRaceItemBoughtOrLost"};
*/
//These are just used as constants, and enum orders them incrementally
// They are to be used for War3CreateEvent and OnWar3Event, these constants define the type of the event/
//War3Events are basically used kind of like Natives and Forwards, without the trouble of creating actual natives/forwards
enum W3EVENT
{
	ToBeRevived=0,
	DoShowHelpMenu,   //1
	DoShowChangeRaceMenu, //2
	DoShowShopMenu,//3
	DoTriedToBuyItem,//4
	DoShowItemsInfoMenu,//5
	DoShowRaceinfoMenu,//6
	DoShowPlayerinfoMenu,//7
	DoShowPlayerinfoEntryWithArg,//8
	DoShowParticularRaceInfo, //EventArg1 = raceid//9

	ClearPlayerVariables,//10 //Happens on disconnect
	InitPlayerVariables,//11 //Happens OnClientPutInServer
	DoLevelCheck,//12


	DoForwardClientBoughtItem, //tell item ownership to call lost and bought forwards//13
	DoForwardClientLostItem, //uses TheItemBoughtOrLost//14

	DoShowSpendskillsMenu,//15
	PlayerIsNewToServer,//16
	DoResetSkills,//17
	DoShowWar3Menu,//18
	DoShowLevelBank,//19
	DoShowWar3Rank,//20
	DoShowWar3Stats,//21
	DoShowWar3Top,//22

	PlayerLeveledUp,//23
	DoCheckRestrictedItems,//24
	OnPreGiveXPGold, //client, arg1,2,3=W3XPAwardedBy , xp, gold//25
	OnPostGiveXPGold, ///xp gold already given, same args as pre//26

	CanBuyItem, //client, arg1=itemid, if eventarg2 is non zero, he can buy// you have to do the message on the reason why he can't buy//27

	OnDeathPre, //EventArg1 = attacker.  before w3 actual death forward is called to do some reading ( ie before items are lost)//28
	DoShowMenuMyInfo,//29
	DoShowPlayerInfoTarget, ///EventArg1 = target = the person whos info is shown, client=SHOW TO//30

	//shopmenu2
	DoShowShopMenu2,//31
	DoTriedToBuyItem2,//32
	DoForwardClientBoughtItem2, //tell item ownership to call lost and bought forwards//33
	DoForwardClientLostItem2, //uses TheItemBoughtOrLost//34

	DatabaseConnected,//35

	DoShowItems2InfoMenu,//MOVE//36
	OnBuffChanged, //a buff has changed//37
	OnAuraCalculationFinished, //this is after all the OnW3PlayerAuraStateChanged have been sent//38
	DoShowPlayerItemsOwnTarget, ///EventArg1 = target = the person whos items is shown, client=SHOW TO//39

	//shopmenu3
	DoShowItems3InfoMenu,//40
	DoShowShopMenu3,//41
	DoTriedToBuyItem3,//42
	DoShowPlayerItems3OwnTarget,//43
	OnPreGiveXP_Platinum, //client, arg1,2,3=W3XPAwardedBy , xp, gold//44
	OnPostGiveXP_Platinum, ///xp gold already given, same args as pre//45
	OnPreShopMenu1ItemCost,//46
	OnWar3_CooldownMGR, // Can change the values of the cooldown.//47
	DoForwardClientBoughtItem3,//48
	DoForwardClientLostItem3,//49

	// Event for Addon_Bank
	//TomesCallBack,//50

	VampireImmunityCheckPre, //50
	OnVampireBuff,
}
enum W3DENY{
	DN_ShowChangeRace, //can show the menu
	DN_Suicide, //can undead suicide
	DN_CanSelectRace, //can select a race, use EventArg1
	DN_CanBuyItem1, //can buy shopmenu1 items, use EventArg1
	DN_ShowLevelbank, //can show levelbank
	DN_CanPlaceWard,
}
// Constants for an array, which every War3 Plugin has. When the variables are ready, they will be forwarded to you.


//Used as constants...identifies why a player was rewarded XP/Gold
enum W3XPAwardedBy
{
	XPAwardByGeneric=0, ///not defined
	XPAwardByKill,
	XPAwardByAssist,
	XPAwardByWin,
	XPAwardByPointCap,
	XPAwardByPointCapBlock,
	XPAwardByFlagCap,
	XPAwardByHealing,
	XPAwardByReviving,
	XPAwardByRescueing,
	XPAwardByFakeKill,
	XPAwardByFakeAssist,
#if (GGAMETYPE == GGAME_CSS || GGAMETYPE == GGAME_CSGO)
	XPAwardByBomb,
	XPAwardByHostage,
#endif
}

// The types of immunities you can get/set from.
///corresponds to a buff system immunity
enum War3Immunity
{
	Immunity_None = 0, //generic zero
	Immunity_Ultimates, // Immune from ultimates
	Immunity_PhysicalDamage, // Immune from health taking
	Immunity_MagicDamage, // Immune from magic based stuff (doesnt not include ultimates)
	//Immunity_Items, // Immune from shop items
	Immunity_Skills, // Immune from all skills
	Immunity_Wards, // Immune ward modifiers/damage. skill immunity includes ward immunity
	Immunity_Abilities, // Immune from abilities (not implemented by core)
	Immunity_Poison, // cyborg medic used to use this...  temporary antihack immunity
	Immunity_Hacks,
	Immunity_ArmorPiercing,
	Immunity_Extra2,
	Immunity_Extra3,
}; // The last of PimpinJuice's sexy syntax

//where damage is from   skill or ultimate etc
enum War3DamageOrigin
{
	W3DMGORIGIN_UNDEFINED=0,
	W3DMGORIGIN_SKILL,
	W3DMGORIGIN_ULTIMATE,
	W3DMGORIGIN_ITEM,
}

//damage types
enum War3DamageType
{
	W3DMGTYPE_TRUEDMG=0,       //normal damage without accout for physical or magic armor
	W3DMGTYPE_PHYSICAL,
	W3DMGTYPE_MAGIC,
}

//Moved to W3PlayerProp.inc
//Basically Instance variables for the Player Class
/*
enum W3PlayerProp
{
	bool:bPutInServer,
	CurrentRace,
	PendingRace,
	PlayerGold,
	PlayerDiamonds,//REMOVE PlayerDiamonds, //DRPECE
	iMaxHP,
	bIsDucking,

	bool:xpLoaded,
	Float:RaceChosenTime,
	bool:RaceSetByAdmin,
	bool:SpawnedOnce, //if player has spawned once
	Float:sqlStartLoadXPTime,

	bool:isDeveloper,
	Float:LastChangeTeamTime,
	bool:bStatefulSpawn, //set true if spawn is a non repeated spawn. set to true on join and death, set false after spawn forward is finished.
	iGoldDiamondHud,   // Player preferences (Gold Hud on / off)
	bool:dbRaceSelected, //used in spawn camper.
	PlayerPlatinum,
	iBuffChatInfo, // Player preferences (Detailed Buff messages)
	iDetailedOnDeathMsgs, // Player preferences (Detailed Buff messages)
	iBuffChatInfo2, // Player preferences (Detailed Buff messages)
	iIntroSong, // Player preferences
	iSaySounds, // Player preferences
}*/

/*  not used any where.. was found in War3Soruce_Engine_RaceClass.sp
enum W3SkillProp
{
	bool:ActivateOnEnemy,

	///TO BE IMPLEMENTED
	MaxLevel,
	bool:IsUltimate,
	SkillName[32],
} */


//EXCLUSIVE: buffs that do not stack with itself: gravity, invisblity, however to make them stack use a second property ie gravity2, invisibilty2
//////////////////Generally races use "buffvar" and items that wish to stack uses "varbuff2" and the final value is calculated: best of "buffvar" stacked with best of "buffvar2"
//STACKING: buffs that stack with itself
//EACH BUFF SHOULD HAVE A CONCENSUS ON WHAT TYPE OF VALUE IT USES: bool, int, float
///NOT ALL BUFFS HAVE THE SAME DENIES, some only need skill deny or item deny only


enum BuffStackCacheType
{ //each buff can only have one stacking operation:aa
	DoNotCache=0,
	bHasOneTrue,
	iAbsolute, //sum
	fAbsolute, //sum
	fStacked, /// all float multiplied
	fMaximum,
	fMinimum,
	iMinimum,
	iLastValue,
	fInverseStacked,
	ERRUNDEFINED=-99,
}

enum struct W3BuffProperties
{
	any DefaultValue; //array index 1
	BuffStackCacheType BuffStackType; //array index 1
}


enum W3Buff
{
	buffdummy=0,
	bBuffDenyAll, //DENY=not allowed to have any buffs, aka "purge" //1

	// REMOVED GRAVITY VIA War3Source_Engine_BuffSpeedGravGlow.sp line 104-124 was commented out
	fLowGravitySkill, //0.4 ish? //2
	fLowGravityItem, //0.4 ish? //3
	bLowGravityDenyAll, //4

	fInvisibilitySkill, //0.4 ish? //5
	fInvisibilityItem, //0.4 ish? //6
	bInvisibilityDenyAll, //7
	bInvisibilityDenySkill, //needed for orc //8
	bDoNotInvisWeapon, //9
	bInvisWeaponOverride, //set true to use override amount, ONLY 1 RACE SHALL USE THIS AT A TIME PER CLIENT //10
	iInvisWeaponOverrideAmount, ///amolunt of 0-255 , do not have to set back to 255, just set bInvisWeaponOverride to false
	//11

	fMaxSpeed, //for increasing speeds only! MUST BE MORE THAN 1.0
	fMaxSpeed2, //for increasing speeds only!, added onto fMaxSpeed buff, MUST BE MORE THAN 1.0
	//13

	fSlow, //for decreeasing speeds only! MUST BE LESS THAN 1.0
	fSlow2, //for decreeasing speeds only! MUST BE LESS THAN 1.0. allows a race to have stacking slows
	bSlowImmunity, //immune to slow?
	//16

	bImmunitySkills, //is immune to skills
	bImmunityUltimates, // is immune to ultimates
	bImmunityWards, // is immune to wards, skill immunity includes ward immunity
	bImmunityPiercing, // is immune to Piercing
	bImmunityAbilities, // is immune to abilities
	//21

	fAttackSpeed, //attack speed multipler!
	//22

	bStunned, //cannot shoot, cannot cast, cannot move, basically everything below
	bBashed, //cannot move
	bDisarm,//cannot shoot
	bSilenced,  //cannot cast
	bHexed,  // no skill proc
	bPerplexed, //cannot use items / proc items
	//28

	bNoMoveMode,//move type none! overrrides all other movestypes
	bFlyMode,   //fly mode
	bFlyModeDeny,
	bNoClipMode,
	//32

	fArmorPhysical, // does stack
	bfArmorPhysicalDenyAll,
	fArmorMagic, // does stack
	bArmorMagicDenyAll,
	//36

	//DO NOT USE GLOW FOR INVIS
	iGlowRed, //glowing the player 0-255
	iGlowGreen,
	iGlowBlue,
	iGlowAlpha, //careful this is like invisiblity
	iGlowPriority, //highest priority takes effect
	fGlowSetTime, //time is recorded, those with same prioirty will compete via time. not something u set
	//42

	fHPRegen, ///float sum! NO NEGATIVES! MINIM regin rate is 0.5 / second ( 1 hp per 2 seconds)
	fHPDecay, //float sum, NO NEGATIVES, postive means lose this much HP / second, same requirements as fHPRegen
	fHPRegenDeny, //set true to deny hp regen
	iAdditionalMaxHealth,   ///increase / decrease in maxhp
	fMaxHealth,   // Set percentage of max health after bonuses of iAdditionalMaxHealth
				// if 300 max health after all bonuses * 0.50 = 150 max health
	//46

	// DODGE MELEE ONLY
	fDodgeChance, //Registers a chance to dodge, (Note: 0.7 would equal a 70% chance to dodge)
	bDodgeMode, //Set 0 for Pre, 1 for post (quick regen)
	//49

	fVampirePercent, //Sets a % of damage done to give back as health
	fVampirePercentNoBuff, // Same as fVampirePercent, but doesn't overheal
	fMeleeVampirePercent, // Sets a % of damage done to give back as health when the damage was caused by melee
	fMeleeVampirePercentNoBuff, // Same as fMeleeVampirePercent, but doesn't overheal
	//53

	fBashChance, //Registers a chance to bash, (Note: 0.7 would equal a 70% chance to bash)
	iBashDamage, //Does a certain amount of damage when you bash an enemy (more similar to warcraft 3's bash, default 0)
	fBashDuration, //Sets the duration of bash's stun
	//56

	fCritChance, //Registers a chance to crit, (Note: 0.7 would equal a 70% chance to crit)
	iCritMode, //Default 0 (0 is off / none) -- (all damage qualifies for crit) = 1 (bullet damage crit) = 2 (grenade damage crit) = 3 (melee damage crit) = 4 (melee and bullet crit) = 5 (melee and grenade crit) = 6 (bullet and grenade crit) = 7
	fCritModifier, //Sets the critical strike modifer, default 1.0
	//59

	iDamageMode, //Default (none) 0 (all damage qualifies for damage increase) 1 (bullet damage damage increase) 2 (grenade damage damage increase) 3 (melee damage damage increase) 4 (melee and bullet damage increase) 5 (melee and grenade damage increase) 6 (bullet and grenade damage increase)
	//60

	iDamageBonus, //Gives a direct increase to damage done
	fDamageModifier, //Gives a % increase to damage done
	//62

	iAdditionalMaxHealthNoHPChange,   ///increase / decrease in maxhp. NO AUTOMATIC HP CHANGE WHEN BUFF IS CHANGED
	//63

	bImmunityPoison,   // immunity to poisons
	//64

	// DODGE RANGED ONLY
	fDodgeChanceRanged, //Registers a chance to dodge ranged attacks, (Note: 0.7 would equal a 30% chance to dodge)
	//65

	bImmunityHacks,  // immunity to hacks
	//66

	bImmunityExtra, // immunity to something?  This is Extra just in case we need to add another immunity
	//67
	bImmunityExtra2, // immunity to something?  This is Extra2 just in case we need to add another immunity
	//68
	bImmunityExtra3, // immunity to something?  This is Extra3 just in case we need to add another immunity
	//69
	fCooldownReduction,
	//70
	fMeleeThorns,
	//71
	fMaxHealthRegen,
	//72
	fSustainEfficiency,
	//73
	fMagicDamageModifier,
	//74
	fAbilityResistance,
	//75
	fUltimateResistance,
	//76
	fArmorPenetration,
	//77
	fCritChanceModifier,
	//78
	fDamageModifierRanged,
	//79
	fExperienceBonus,

	MaxBuffLoopLimitTemp, //this is a variable that is for loops, this number is automatically generated from the enum.
}
stock MaxBuffLoopLimit=_:MaxBuffLoopLimitTemp;


//create an buffpropertiesarray[W3Buff][W3BuffProperties]; (separate from the array that stores every client's buffs)
//we fill the array with its properties
stock InitiateBuffPropertiesArray(W3BuffProperties buffpropertiesarray[W3Buff])
{
	for(new i=0;i<MaxBuffLoopLimit;i++)
	{
		buffpropertiesarray[W3Buff:i].DefaultValue=-99;
		buffpropertiesarray[W3Buff:i].BuffStackType=ERRUNDEFINED;
	}

	buffpropertiesarray[buffdummy].DefaultValue=false;
	buffpropertiesarray[buffdummy].BuffStackType=bHasOneTrue;

	buffpropertiesarray[bBuffDenyAll].DefaultValue=false;
	buffpropertiesarray[bBuffDenyAll].BuffStackType=bHasOneTrue;

	buffpropertiesarray[fLowGravitySkill].DefaultValue=1.0;
	buffpropertiesarray[fLowGravitySkill].BuffStackType=fMinimum;

	buffpropertiesarray[fLowGravityItem].DefaultValue=1.0;
	buffpropertiesarray[fLowGravityItem].BuffStackType=fMinimum;

	buffpropertiesarray[ bLowGravityDenyAll ].DefaultValue=false;
	buffpropertiesarray[ bLowGravityDenyAll ].BuffStackType=bHasOneTrue;

	buffpropertiesarray[ fInvisibilitySkill ].DefaultValue=1.0;
	buffpropertiesarray[ fInvisibilitySkill ].BuffStackType=fMinimum;

	buffpropertiesarray[ fInvisibilityItem ].DefaultValue=1.0;
	buffpropertiesarray[ fInvisibilityItem ].BuffStackType=fMinimum;

	buffpropertiesarray[ bInvisibilityDenyAll ].DefaultValue=false;
	buffpropertiesarray[ bInvisibilityDenyAll ].BuffStackType=bHasOneTrue;

	buffpropertiesarray[ bInvisibilityDenySkill ].DefaultValue=false;
	buffpropertiesarray[ bInvisibilityDenySkill ].BuffStackType=bHasOneTrue;

	buffpropertiesarray[ bDoNotInvisWeapon ].DefaultValue=false;
	buffpropertiesarray[ bDoNotInvisWeapon ].BuffStackType=bHasOneTrue;

	buffpropertiesarray[ bInvisWeaponOverride ].DefaultValue=false;
	buffpropertiesarray[ bInvisWeaponOverride ].BuffStackType=bHasOneTrue;

	buffpropertiesarray[ iInvisWeaponOverrideAmount ].DefaultValue=255;
	buffpropertiesarray[ iInvisWeaponOverrideAmount ].BuffStackType=iMinimum;

	buffpropertiesarray[ fMaxSpeed ].DefaultValue=1.0;
	buffpropertiesarray[ fMaxSpeed ].BuffStackType=fMaximum;

	buffpropertiesarray[ fMaxSpeed2 ].DefaultValue=0.0;
	buffpropertiesarray[ fMaxSpeed2 ].BuffStackType=fAbsolute;

	buffpropertiesarray[ fSlow ].DefaultValue=1.0;
	buffpropertiesarray[ fSlow ].BuffStackType=fStacked;

	buffpropertiesarray[ fSlow2 ].DefaultValue=1.0;
	buffpropertiesarray[ fSlow2 ].BuffStackType=fStacked;

	buffpropertiesarray[ bSlowImmunity ].DefaultValue=false;
	buffpropertiesarray[ bSlowImmunity ].BuffStackType=bHasOneTrue;

//	buffpropertiesarray[ fIncomingDamage ].DefaultValue=1.0;
//	buffpropertiesarray[ fIncomingDamage ].BuffStackType=fStacked;

	buffpropertiesarray[ bImmunitySkills ].DefaultValue=false;
	buffpropertiesarray[ bImmunitySkills ].BuffStackType=bHasOneTrue;

	buffpropertiesarray[ bImmunityWards ].DefaultValue=false;
	buffpropertiesarray[ bImmunityWards ].BuffStackType=bHasOneTrue;

	buffpropertiesarray[ bImmunityUltimates ].DefaultValue=false;
	buffpropertiesarray[ bImmunityUltimates ].BuffStackType=bHasOneTrue;

	buffpropertiesarray[ bImmunityPiercing ].DefaultValue=false;
	buffpropertiesarray[ bImmunityPiercing ].BuffStackType=bHasOneTrue;

	buffpropertiesarray[ bImmunityAbilities ].DefaultValue=false;
	buffpropertiesarray[ bImmunityAbilities ].BuffStackType=bHasOneTrue;

	buffpropertiesarray[ fAttackSpeed ].DefaultValue=1.0;
	buffpropertiesarray[ fAttackSpeed ].BuffStackType=fStacked;

	buffpropertiesarray[ bStunned ].DefaultValue=false;
	buffpropertiesarray[ bStunned ].BuffStackType=bHasOneTrue;

	buffpropertiesarray[ bBashed ].DefaultValue=false;
	buffpropertiesarray[ bBashed ].BuffStackType=bHasOneTrue;

	buffpropertiesarray[ bDisarm ].DefaultValue=false;
	buffpropertiesarray[ bDisarm ].BuffStackType=bHasOneTrue;

	buffpropertiesarray[ bSilenced ].DefaultValue=false;
	buffpropertiesarray[ bSilenced ].BuffStackType=bHasOneTrue;

	buffpropertiesarray[ bPerplexed ].DefaultValue=false;
	buffpropertiesarray[ bPerplexed ].BuffStackType=bHasOneTrue;

	buffpropertiesarray[ bHexed ].DefaultValue=false;
	buffpropertiesarray[ bHexed ].BuffStackType=bHasOneTrue;

	buffpropertiesarray[ bNoMoveMode ].DefaultValue=false;
	buffpropertiesarray[ bNoMoveMode ].BuffStackType=bHasOneTrue;

	buffpropertiesarray[ bFlyMode ].DefaultValue=false;
	buffpropertiesarray[ bFlyMode ].BuffStackType=bHasOneTrue;

	buffpropertiesarray[ bFlyModeDeny ].DefaultValue=false;
	buffpropertiesarray[ bFlyModeDeny ].BuffStackType=bHasOneTrue;


	buffpropertiesarray[ bNoClipMode ].DefaultValue=false;
	buffpropertiesarray[ bNoClipMode ].BuffStackType=bHasOneTrue;


	buffpropertiesarray[ fArmorPhysical ].DefaultValue=0.0;
	buffpropertiesarray[ fArmorPhysical ].BuffStackType=fAbsolute;

	buffpropertiesarray[ bfArmorPhysicalDenyAll ].DefaultValue=false;
	buffpropertiesarray[ bfArmorPhysicalDenyAll ].BuffStackType=bHasOneTrue;

	buffpropertiesarray[ fArmorMagic ].DefaultValue=0.0;
	buffpropertiesarray[ fArmorMagic ].BuffStackType=fAbsolute;

	buffpropertiesarray[ bArmorMagicDenyAll ].DefaultValue=false;
	buffpropertiesarray[ bArmorMagicDenyAll ].BuffStackType=bHasOneTrue;

	buffpropertiesarray[ iGlowRed ].DefaultValue=255;
	buffpropertiesarray[ iGlowRed ].BuffStackType=DoNotCache;

	buffpropertiesarray[ iGlowGreen ].DefaultValue=255;
	buffpropertiesarray[ iGlowGreen ].BuffStackType=DoNotCache;

	buffpropertiesarray[ iGlowBlue ].DefaultValue=255;
	buffpropertiesarray[ iGlowBlue ].BuffStackType=DoNotCache;

	buffpropertiesarray[ iGlowAlpha ].DefaultValue=255;
	buffpropertiesarray[ iGlowAlpha ].BuffStackType=DoNotCache;

	buffpropertiesarray[ iGlowPriority ].DefaultValue=0;
	buffpropertiesarray[ iGlowPriority ].BuffStackType=DoNotCache;

	buffpropertiesarray[ fGlowSetTime ].DefaultValue=0;
	buffpropertiesarray[ fGlowSetTime ].BuffStackType=DoNotCache;


	buffpropertiesarray[ fHPRegen].DefaultValue=0.0;
	buffpropertiesarray[ fHPRegen].BuffStackType=fAbsolute;

	buffpropertiesarray[ fHPDecay].DefaultValue=0.0;
	buffpropertiesarray[ fHPDecay].BuffStackType=fAbsolute;

	buffpropertiesarray[ fHPRegenDeny].DefaultValue=false;
	buffpropertiesarray[ fHPRegenDeny].BuffStackType=bHasOneTrue;

	buffpropertiesarray[ iAdditionalMaxHealth ].DefaultValue=0;
	buffpropertiesarray[ iAdditionalMaxHealth ].BuffStackType=iAbsolute;

	buffpropertiesarray[ fMaxHealth ].DefaultValue=1.0;
	buffpropertiesarray[ fMaxHealth ].BuffStackType=fStacked;

	buffpropertiesarray[ fDodgeChance ].DefaultValue=0.0;
	buffpropertiesarray[ fDodgeChance ].BuffStackType=fInverseStacked;

	buffpropertiesarray[ bDodgeMode	  ].DefaultValue=0;
	buffpropertiesarray[ bDodgeMode   ].BuffStackType=bHasOneTrue;

	buffpropertiesarray[ fVampirePercent].DefaultValue=0.0;
	buffpropertiesarray[ fVampirePercent].BuffStackType=fAbsolute;

	buffpropertiesarray[ fVampirePercentNoBuff].DefaultValue=0.0;
	buffpropertiesarray[ fVampirePercentNoBuff].BuffStackType=fAbsolute;

	buffpropertiesarray[ fMeleeVampirePercent].DefaultValue=0.0;
	buffpropertiesarray[ fMeleeVampirePercent].BuffStackType=fAbsolute;

	buffpropertiesarray[ fMeleeVampirePercentNoBuff].DefaultValue=0.0;
	buffpropertiesarray[ fMeleeVampirePercentNoBuff].BuffStackType=fAbsolute;

	buffpropertiesarray[ fBashChance ].DefaultValue=0.0;
	buffpropertiesarray[ fBashChance ].BuffStackType=fAbsolute;

	buffpropertiesarray[ iBashDamage ].DefaultValue=0;
	buffpropertiesarray[ iBashDamage ].BuffStackType=iAbsolute;

	buffpropertiesarray[ fBashDuration ].DefaultValue=0.0;
	buffpropertiesarray[ fBashDuration ].BuffStackType=fAbsolute;

	buffpropertiesarray[ fCritChance ].DefaultValue=0.0;
	buffpropertiesarray[ fCritChance ].BuffStackType=fAbsolute;

	buffpropertiesarray[ iCritMode ].DefaultValue=1;
	buffpropertiesarray[ iCritMode ].BuffStackType=iLastValue;

	buffpropertiesarray[ fCritModifier ].DefaultValue=1.0;
	buffpropertiesarray[ fCritModifier ].BuffStackType=fMaximum;

	buffpropertiesarray[ iDamageBonus ].DefaultValue=0;
	buffpropertiesarray[ iDamageBonus ].BuffStackType=iAbsolute;

	buffpropertiesarray[ fDamageModifier ].DefaultValue=0.0;
	buffpropertiesarray[ fDamageModifier ].BuffStackType=fAbsolute;

	buffpropertiesarray[ iDamageMode ].DefaultValue=-1;
	buffpropertiesarray[ iDamageMode ].BuffStackType=iLastValue;

	buffpropertiesarray[ iAdditionalMaxHealthNoHPChange ].DefaultValue=0;
	buffpropertiesarray[ iAdditionalMaxHealthNoHPChange ].BuffStackType=iAbsolute;

	buffpropertiesarray[ bImmunityPoison ].DefaultValue=false;
	buffpropertiesarray[ bImmunityPoison ].BuffStackType=bHasOneTrue;

	buffpropertiesarray[ fDodgeChanceRanged ].DefaultValue=0.0;
	buffpropertiesarray[ fDodgeChanceRanged ].BuffStackType=fInverseStacked;

	buffpropertiesarray[ bImmunityHacks ].DefaultValue=false;
	buffpropertiesarray[ bImmunityHacks ].BuffStackType=bHasOneTrue;

	buffpropertiesarray[ bImmunityExtra ].DefaultValue=false;
	buffpropertiesarray[ bImmunityExtra ].BuffStackType=bHasOneTrue;

	buffpropertiesarray[ bImmunityExtra2 ].DefaultValue=false;
	buffpropertiesarray[ bImmunityExtra2 ].BuffStackType=bHasOneTrue;

	buffpropertiesarray[ bImmunityExtra3 ].DefaultValue=false;
	buffpropertiesarray[ bImmunityExtra3 ].BuffStackType=bHasOneTrue;

	buffpropertiesarray[ fCooldownReduction ].DefaultValue=1.0;
	buffpropertiesarray[ fCooldownReduction ].BuffStackType=fStacked;

	buffpropertiesarray[ fMeleeThorns ].DefaultValue=0.0;
	buffpropertiesarray[ fMeleeThorns ].BuffStackType=fAbsolute;

	buffpropertiesarray[ fMaxHealthRegen ].DefaultValue=0.0;
	buffpropertiesarray[ fMaxHealthRegen ].BuffStackType=fAbsolute;

	buffpropertiesarray[ fSustainEfficiency ].DefaultValue=0.0;
	buffpropertiesarray[ fSustainEfficiency ].BuffStackType=fAbsolute;

	buffpropertiesarray[ fMagicDamageModifier ].DefaultValue=0.0;
	buffpropertiesarray[ fMagicDamageModifier ].BuffStackType=fAbsolute;

	buffpropertiesarray[ fAbilityResistance ].DefaultValue=1.0;
	buffpropertiesarray[ fAbilityResistance ].BuffStackType=fStacked;

	buffpropertiesarray[ fUltimateResistance ].DefaultValue=1.0;
	buffpropertiesarray[ fUltimateResistance ].BuffStackType=fStacked;

	buffpropertiesarray[ fArmorPenetration ].DefaultValue=0.0;
	buffpropertiesarray[ fArmorPenetration ].BuffStackType=fAbsolute;

	buffpropertiesarray[ fCritChanceModifier ].DefaultValue=0.0;
	buffpropertiesarray[ fCritChanceModifier ].BuffStackType=fAbsolute;

	buffpropertiesarray[ fDamageModifierRanged ].DefaultValue=0.0;
	buffpropertiesarray[ fDamageModifierRanged ].BuffStackType=fAbsolute;

	buffpropertiesarray[ fExperienceBonus ].DefaultValue=0.0;
	buffpropertiesarray[ fExperienceBonus ].BuffStackType=fAbsolute;

	//check that all indexes have been set
	for(new i=0;i<MaxBuffLoopLimit;i++)
	{
		if(buffpropertiesarray[W3Buff:i].DefaultValue==-99)
		{
			SetFailState("Buff index %d .DefaultValue was not set properly!",i);
		}
		if(buffpropertiesarray[W3Buff:i].BuffStackType==ERRUNDEFINED)
		{
			SetFailState("Buff index %d .BuffStackType was not set properly!",i);
		}
	}
}

///not yet used  and not sure if we ever will.. an Ownz unfinished project, good idea though.
/*
enum RaceString
{
	RaceName,
	RaceShortname,
	RaceStory,
	RaceDescription,
	RaceTechnical,
} */

//simulates race object
enum ENUM_RaceObject{ //CELLS ONLY, NO STRINGS
	ClassRestrictionCvar, //for TF
	OnlySingleClassAllowedCvar, //for TF
	RaceCategorieCvar,
	RaceExtends,
}


/* // not implemented, not sure if it will be, an ownz unfinished project
enum SkillString
{
	SkillName,
	SkillStory,
	SkillDescription,
	SkillTechnical,
}
*/

/* DEFUNCT
enum W3SkillType{
	SKT_NORMALSKILL=0,
	SKT_ULTIMATE,
	SKT_ABILITY,
	SKT_ABILITY1,
	SKT_ABILITY2,
	SKT_ABILITY3,
	SKT_ABILITY4,
}*/

// War3 Glow constants
enum
{
	GLOW_NONE=0,
	GLOW_BASE=1, //if ur race needs a glow
	GLOW_BASE2, //temporary glow of ur race over ur orignal glow? like mole u can add a glow for another priority
	GLOW_DEFAULT,
	GLOW_SKILL, //if skill activates on u  or others
	GLOW_ULTIMATE, //if ultimate actiavates on u or others
	GLOW_OVERRIDE=255, //override all glow
}


// For Shopmenu3
enum W3ItemInfo
{
	//item1
	item1=0,
	item1level1,
	item1xp1,
	item1level2,
	item1xp2,
	//item2
	item2,
	item2level1,
	item2xp1,
	item2level2,
	item2xp2,
	//item3
	item3,
	item3level1,
	item3xp1,
	item3level2,
	item3xp2,
}

// For Shopmenu3
enum W3ItemSkills
{
	skill1=0,
	skill2,
}

enum W3ItemProp
{
	ITEM_USED_ON_BUY=0,
	ITEM_SELFSTACK,
	ITEM_REQUIRED_RACE
}

enum g_SQLType
{
	SQLType_Unknown = 0,
	SQLType_MySQL,
	SQLType_SQLite,
}

// Ward targeting affinities
enum War3WardAffinity
{
	ENEMIES,
	ALLIES,
	ALL,
	SELF_ONLY
}

enum SkillDependency {
	ID=0, //on which other skill does this depends on?
	LVL //what level i must be to be able to level this?
}

enum FactionBehavior{
	ReturnValue=-1, //pass this to return the settings
	Neutral=0, //zero=default
	Friend,
	Enemy
}

enum W3HintPriority{
	HINT_NORMAL, //things that are attached from non hint engine hints
	HINT_SKILL_STATUS, //"TELEPORTED!"
	HINT_DMG_DEALT,
	HINT_DMG_RCVD,
	HINT_COOLDOWN_NOTREADY,
	HINT_COOLDOWN_EXPIRED,
	HINT_COOLDOWN_COUNTDOWN,
	HINT_LOWEST,

	HINT_SIZE, //do not use this as priority
}
enum W3HintPriorityMultiType{
	HINT_TYPE_SINGLE=0,	//show single, overrides old
	HINT_TYPE_ALL,		//show all of them
	HINT_TYPE_QUEUE,	//queue each one
}
//functio to retreve these constants
stock any:W3GetHintPriorityType(W3HintPriority:priority){
	switch(priority){
		case HINT_NORMAL:  return HINT_TYPE_ALL;
		case HINT_SKILL_STATUS: return HINT_TYPE_ALL;
		case HINT_DMG_DEALT: return HINT_TYPE_ALL;
		case HINT_DMG_RCVD: return HINT_TYPE_ALL;
		case HINT_COOLDOWN_NOTREADY: return HINT_TYPE_SINGLE;
		case HINT_COOLDOWN_EXPIRED:  return HINT_TYPE_ALL;
		case HINT_COOLDOWN_COUNTDOWN:  return HINT_TYPE_SINGLE;
		case HINT_LOWEST:  return HINT_TYPE_ALL;
	}
	return -1;
}

// The following are color presets for the War3_FlashScreen function
#define RGBA_COLOR_RED		{255,0,0,4}
#define RGBA_COLOR_GREEN	{0,255,0,3}
#define RGBA_COLOR_BLUE		{0,0,255,3}
#define RGBA_COLOR_YELLOW	{255,255,0,3}
#define RGBA_COLOR_ORANGE	{255,69,0,3}
#define RGBA_COLOR_PURPLE	{128,0,128,3}
#define RGBA_COLOR_CYAN		{255,0,255,3}
#define RGBA_COLOR_WHITE	{255,255,255,3}
#define RGBA_COLOR_BLACK	{0,0,0,3}
#define RGBA_COLOR_GREY		{128,128,128,3}
#define RGBA_COLOR_PINK		{255,20,147,3}
#define RGBA_COLOR_MAROON	{128,0,0,3}
#define RGBA_COLOR_SKYBLUE	{135,206,25,3}
#define RGBA_COLOR_GOLD		{255,215,0,3}
#define RGBA_COLOR_BROWN	{139,69,19,3}
#define RGBA_COLOR_VIOLET	{238,130,238,3}

#define WARD_RGBA_COLOR_RED		{255,0,0,255}
#define WARD_RGBA_COLOR_GREEN	{0,255,0,255}
#define WARD_RGBA_COLOR_BLUE		{0,0,255,255}
#define WARD_RGBA_COLOR_YELLOW	{255,255,0,255}
#define WARD_RGBA_COLOR_ORANGE	{255,69,0,255}
#define WARD_RGBA_COLOR_PURPLE	{128,0,128,255}
#define WARD_RGBA_COLOR_CYAN		{255,0,255,255}
#define WARD_RGBA_COLOR_WHITE	{255,255,255,255}
#define WARD_RGBA_COLOR_BLACK	{0,0,0,255}
#define WARD_RGBA_COLOR_GREY		{128,128,128,255}
#define WARD_RGBA_COLOR_PINK		{255,20,147,255}
#define WARD_RGBA_COLOR_MAROON	{128,0,0,255}
#define WARD_RGBA_COLOR_SKYBLUE	{135,206,25,255}
#define WARD_RGBA_COLOR_GOLD		{255,215,0,255}
#define WARD_RGBA_COLOR_BROWN	{139,69,19,255}
#define WARD_RGBA_COLOR_VIOLET	{238,130,238,255}

// The following are from the SourceSDK, used for the optional flags field of War3_FlashScreen
#define FFADE_IN			0x0001		// Just here so we don't pass 0 into the function, YOUR SCREEN DECAYS AND YOU SEE CLEARLY SLOWLY
#define FFADE_OUT			0x0002		// Fade out (not in)
#define FFADE_MODULATE		0x0004		// Modulate (don't blend)
#define FFADE_STAYOUT		0x0008		// ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE			0x0010		// Purges all other fades, replacing them with this one

// Team ID's for the Valve specific game
//0 == unassigned
// 1 == spectator
#define  TEAM_SPEC 1
#define  TEAM_T 2
#define  TEAM_CT 3
#define  TEAM_RED 2
#define  TEAM_BLUE 3

// Modeltypes used by the Model Engine  // not implemented anywhere.. good for reference
//#define MDLTYPE_VIEWMODEL 0
//#define MDLTYPE_WORLDMODEL 1

/*
enum ItemClassString
{
	unknown = TFClass_Unknown,
	scout = TFClass_Scout,
	sniper = TFClass_Sniper,
	soldier = TFClass_Soldier,
	demoman = TFClass_DemoMan,
	medic = TFClass_Medic,
	heavy = TFClass_Heavy,
	pyro = TFClass_Pyro,
	spy = TFClass_Spy,
	engineer = TFClass_Engineer
}
*/
//#define MDLTYPE_GRENADE 2 //thrown grenades  // not implemented anywhere.. good for reference

//=============================
// War3Source_Engine_Bank
//=============================
#if GGAMETYPE_JAILBREAK == JAILBREAK_OFF
#define DATABASENAME "bank"
#elseif GGAMETYPE_JAILBREAK == JAILBREAK_ON
#define DATABASENAME "TF2Jail_bank"
#endif


// SPELLCOLOR

#define SPELLCOLOR_RED		"255 0 0"
#define SPELLCOLOR_GREEN	"0 255 0"
#define SPELLCOLOR_BLUE		"0 0 255"
#define SPELLCOLOR_YELLOW	"255 255 0"
#define SPELLCOLOR_ORANGE	"255 69 0"
#define SPELLCOLOR_PURPLE	"128 0 128"
#define SPELLCOLOR_CYAN		"255 0 255"
#define SPELLCOLOR_WHITE	"255 255 255"
#define SPELLCOLOR_BLACK	"25 25 25"
#define SPELLCOLOR_GREY		"128 128 128"
#define SPELLCOLOR_PINK		"255 20 147"
#define SPELLCOLOR_MAROON	"128 0 0"
#define SPELLCOLOR_SKYBLUE	"135 206 25"
#define SPELLCOLOR_GOLD		"255 215 0"
#define SPELLCOLOR_BROWN	"139 69 19"
#define SPELLCOLOR_VIOLET	"238 130 238"

