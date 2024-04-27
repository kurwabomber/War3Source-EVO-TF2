#include <war3source>

#define PLUGIN_VERSION "3.0a (6/26/2016)"
/**
 * File: War3Source_ShopItems.sp
 * Description: The shop items that come with War3Source:EVO.
 * Author(s): Anthony Iacono
 *--
 *-- Add all shopmenu items into the code, including War3Source:EVO shopmenu items.
 *-- El Diablo
 *-- www.war3evo.info
 */

#pragma semicolon 1

#assert GGAMEMODE == MODE_WAR3SOURCE

//#include <cstrike>

char helmSound0[]="physics/metal/metal_solid_impact_bullet1.wav";
char helmSound1[]="physics/metal/metal_solid_impact_bullet2.wav";
char helmSound2[]="physics/metal/metal_solid_impact_bullet3.wav";
char helmSound3[]="physics/metal/metal_solid_impact_bullet4.wav";

int shopItem[MAXITEMS];//
bool bDidDie[65]; // did they die before spawning?
Handle BootsSpeedCvar;
#if GGAMETYPE_JAILBREAK == JAILBREAK_OFF
#endif
Handle ClawsAttackCvar;
Handle MaskDeathCvar;
bool bFrosted[65]; // don't frost before unfrosted
Handle OrbFrostCvar;
Handle TomeCvar;
Handle SockCvar;
Handle RegenHPTFCvar;

char masksnd[256]; //="war3source/mask.mp3";
int maskSoundDelay[66];

// shield
int MoneyOffsetCS;
Handle ShieldRestrictionCvar;

public Plugin:myinfo =
{
	name = "W3S - Shopitems",
	author = "PimpinJuice && El Diablo",
	description = "The shop items that come with War3Source.",
	version = "1.0.0.0",
	url = "https://forums.alliedmods.net/showthread.php?p=2430864"
};

public void OnAllPluginsLoaded()
{
	W3Hook(W3Hook_OnW3TakeDmgAll, OnW3TakeDmgAll);
#if GGAMETYPE == GGAME_TF2
	W3Hook(W3Hook_OnW3TakeDmgBullet, OnW3TakeDmgBullet);
#endif
	W3Hook(W3Hook_OnWar3Event, OnWar3Event);
}

public OnPluginStart()
{
	CreateConVar("war3_shopmenu1",PLUGIN_VERSION,"War3Source:EVO shopmenu1", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	BootsSpeedCvar=CreateConVar("war3_shop_boots_speed","0.2","Boots speed, 0.2 is default");
	ClawsAttackCvar=CreateConVar("war3_shop_claws_damage","0.10","Claws of attack additional percentage damage per second");
	MaskDeathCvar=CreateConVar("war3_shop_mask_percent","0.3","Percent of damage rewarded for Mask of Death, from 0.0 - 1.0");
	OrbFrostCvar=CreateConVar("war3_shop_orb_speed","0.5","Orb of Frost speed, 1.0 is normal speed, 0.6 default for orb.");
	TomeCvar=CreateConVar("war3_shop_tome_xp","10","Experience awarded for Tome of Experience.");
	SockCvar=CreateConVar("war3_shop_sock_gravity","0.4","Gravity used for Sock of Feather, 0.4 is default for sock, 1.0 is normal gravity");
#if GGAMETYPE == GGAME_TF2
	RegenHPTFCvar=CreateConVar("war3_shop_ring_hp_tf","4","How much HP is regenerated for TF.");
#else
	RegenHPTFCvar=CreateConVar("war3_shop_ring_hp_tf","2","How much HP is regenerated for CSS.");
#endif

	CreateTimer(0.1,PointOneSecondLoop,_,TIMER_REPEAT);
#if GGAMETYPE == GGAME_TF2
	CreateTimer(1.0,SecondLoop,_,TIMER_REPEAT);
#endif
	CreateTimer(5.0,FiveSecondLoop,_,TIMER_REPEAT);
	for(new i=1;i<=MaxClients;i++){
		maskSoundDelay[i]=War3_RegisterDelayTracker();
	}
	LoadTranslations("w3s._common.phrases");
	LoadTranslations("w3s.item.helm.phrases");
	LoadTranslations("w3s.item.courage.phrases");
	LoadTranslations("w3s.item.uberme.phrases");
#if GGAMETYPE == GGAME_TF2
	LoadTranslations("w3s.item.fireorb.phrases");
#endif

	//shield
	ShieldRestrictionCvar=CreateConVar("war3_shop_shield_restriction","0","Set this to 1 if you want to forbid necklace+shield. 0 default");
	LoadTranslations("w3s.item.shield.phrases");

}

public OnAddSound(sound_priority)
{
	if(sound_priority==PRIORITY_TOP)
	{
		War3_AddSound(helmSound0,STOCK_SOUND);
		War3_AddSound(helmSound1,STOCK_SOUND);
		War3_AddSound(helmSound2,STOCK_SOUND);
		War3_AddSound(helmSound3,STOCK_SOUND);
	}
	if(sound_priority==PRIORITY_LOW)
	{
		strcopy(masksnd,sizeof(masksnd),"war3source/mask.mp3");
		War3_AddSound(masksnd);
	}
}
#if GGAMETYPE_JAILBREAK == JAILBREAK_OFF
bool war3ready;
#endif
public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==40){
#if GGAMETYPE_JAILBREAK == JAILBREAK_OFF
		war3ready=true;
#endif
		for(new x=0;x<MAXITEMS;x++)
			shopItem[x]=0;
		shopItem[BOOTS]=War3_CreateShopItemT("boot","20% speed boost",3,2500);

		shopItem[CLAW]=War3_CreateShopItemT("claw","10% damage bonus",3,5000);

		shopItem[CLOAK]=War3_CreateShopItemT("cloak","40% invis",2,1000);

		shopItem[MASK]=War3_CreateShopItemT("mask","30% lifesteal",3,1500);

		shopItem[NECKLACE]=War3_CreateShopItemT("lace","40% immunity to ultimates",2,800);

		shopItem[FROST]=War3_CreateShopItemT("orb","50% slowdown on hit",3,2000);

		shopItem[RING]=War3_CreateShopItemT("ring","+4 hp per second",3,1500);

		shopItem[TOME]=War3_CreateShopItemT("tome","3000 xp on buy",10,10000);
		War3_SetItemProperty(shopItem[TOME], ITEM_USED_ON_BUY,true);

		shopItem[SOCK]=War3_CreateShopItemT("sock","-60% gravity",2,1500);

		shopItem[OIL]=War3_CreateShopItem("Oil of Penetration","oil","+2 armor penetration","Coats your weapons with ability to armor.\n+2 armor penetration.",11,3500);

		shopItem[SHIELD]=War3_CreateShopItemT("shield","40% immunity to skills",3,2000);

		shopItem[GAUNTLET]=War3_CreateShopItem("Gauntlet of Endurance","gauntlet","+35 max hp","Increases max health by 35 HP",5,3000);
#if GGAMETYPE == GGAME_TF2
		shopItem[FIREORB]=War3_CreateShopItemT("fireorb","chance to ignite victim per second", 10, 4000);
#endif

		shopItem[COURAGE]=War3_CreateShopItem("Armor of Courage","courage","+5 phys dmg reduction","increases up to 25% resistance against all physcial damage\n(does not block magical)",10,3000);

		shopItem[FAITH]=War3_CreateShopItem("Armor of Faith","faith","+5 magic dmg reduction","increases up to 25% resistance against all magical damage\n(does not block physical)",10,3000);

		shopItem[ARMBAND]=War3_CreateShopItem("Armband of Repetition","armband","+15% attack speed","Increases attack speed by 15%\n(does not stack with other attack speed increases)",10,3000);

		shopItem[MBOOTS]=War3_CreateShopItem("Medi Boots","mboots","healing gives speed","Gives healing target increased movement speed",9,3000);
		War3_TFSetItemClasses(shopItem[MBOOTS],TFClass_Medic);
		shopItem[MRING]=War3_CreateShopItem("Medi Ring","mring","healing gives regen","Gives healing target regeneration of hp",9,3000);
		War3_TFSetItemClasses(shopItem[MRING],TFClass_Medic);
		shopItem[MHEALTH]=War3_CreateShopItem("Medi Health","mhealth","healing gives health","Gives healing target extra hp",9,3000);
		War3_TFSetItemClasses(shopItem[MHEALTH],TFClass_Medic);

		shopItem[DIVINERAPIER]=War3_CreateShopItem("Divine Rapier", "rapier", "+4 additive damage", "+4 additive damage", 17, 10000);
		shopItem[REFRESHERORB]=War3_CreateShopItem("Refresh Orb", "refreshorb", "1.4x faster ability cooldown", "1.4x faster ability cooldown", 15, 10000);
		
		shopItem[GLIMMERCAPE]=War3_CreateShopItem("Glimmer Cape", "cape", "+7 magic dmg reduction", "+7 magic dmg reduction", 15, 10000);
		shopItem[AGHANIMSCEPTRE]=War3_CreateShopItem("Aghanim's Sceptre", "sceptre", "WIP:NOT WORKING upgrades all ultimates", "WIP:NOT WORKING upgrades all ultimates", 25, 10000);
		shopItem[ORBOFVENOM]=War3_CreateShopItem("Orb of Venom", "venom", "attacks apply venom dot (4dps)", "attacks apply venom dot (4dps)", 1, 10000);
		shopItem[RINGOFPROTECTION]=War3_CreateShopItem("Ring of Protection", "protection", "+3 dmg reduction", "+3 dmg reduction", 5, 10000);
		shopItem[TALISMANOFEVASION]=War3_CreateShopItem("Talisman of Evasion", "evasion", "+15% evasion", "+15% evasion", 10, 10000);
		shopItem[BLADEMAIL]=War3_CreateShopItem("Blade Mail", "blademail", "+7 dmg reduction & 65% melee reflect", "+7 dmg reduction & 65% melee reflect", 20, 10000);
		shopItem[ASSAULTCUIRASS]=War3_CreateShopItem("Assault Cuirass", "cuirass", "+5 dmg reduction & +10% attack speed", "+5 dmg reduction & +10% attack speed", 35, 10000);
		shopItem[HEARTOFTARRASQUE]=War3_CreateShopItem("Heart of Tarrasque", "heart", "+4% maxHPR", "+4% maxHPR", 15, 10000);
		shopItem[NULLTALISMAN]=War3_CreateShopItem("Null Talisman", "talisman", "+1 hpr, phys & magic dmg reduction, +5% ms and dmg.", "+1 hpr, phys & magic dmg reduction, +5% ms and dmg.", 2, 10000);
		shopItem[DAEDALUS]=War3_CreateShopItem("Daedalus", "daedalus", "+20% crit chance. crit dmg default to 1.5x if none", "+20% crit chance. crit dmg default to 1.5x if none", 15, 10000);
		shopItem[DESOLATOR]=War3_CreateShopItem("Desolator", "desolator", "+3 armor penetration", "+3 armor penetration", 15, 10000);
		shopItem[PANICNECKLACE]=War3_CreateShopItem("Panic Necklade", "panic", "+2s speed boost when hit", "+2s speed boost when hit", 2, 10000);
		shopItem[BLOODBOUNDGEM]=War3_CreateShopItem("Bloodbound Gem", "bloodbound", "+40% sustain boost", "+40% sustain boost", 12, 10000);
		shopItem[MEKANSM]=War3_CreateShopItem("Mekansm", "mekansm", "+15HP AOE heal/5s", "+15HP AOE heal/5s", 10, 10000);
		shopItem[MANTLEOFINTEL]=War3_CreateShopItem("Mantle of Intelligence", "mantle", "+25% magic dmg", "+25% magic dmg", 6, 10000);

#if GGAMETYPE2 == GGAME_PVM
		// Armor
		shopItem[LEATHER]=War3_CreateShopItem("Leather Armor +12","leather","+12 phys armor","Increases physical armor by +12",24,3000);
		shopItem[CHAINMAIL]=War3_CreateShopItem("Chainmail Armor +14","chainmail","+14 phys armor","Increases physical armor by +14",28,3000);
		shopItem[BANDEDMAIL]=War3_CreateShopItem("Banded mail Armor +16","bandedmail","+16 phys armor","Increases physical armor by +16",32,3000);
		shopItem[HALFPLATE]=War3_CreateShopItem("Half-plate Armor +18","halfplate","+18 phys armor","Increases physical armor by +18",36,3000);
		shopItem[FULLPLATE]=War3_CreateShopItem("Full-plate Armor +20","fullplate","+20 phys armor","Increases physical armor by +20",40,3000);

		shopItem[DRAGONMAIL]=War3_CreateShopItem("Dragon mail Armor +50","dragonmail","+50 magic armor","Increases magical armor by +50",50,3000);

		War3_AddItemBuff(shopItem[LEATHER], fArmorPhysical, 12.0);
		War3_AddItemBuff(shopItem[CHAINMAIL], fArmorPhysical, 14.0);
		War3_AddItemBuff(shopItem[BANDEDMAIL], fArmorPhysical, 16.0);
		War3_AddItemBuff(shopItem[HALFPLATE], fArmorPhysical, 18.0);
		War3_AddItemBuff(shopItem[FULLPLATE], fArmorPhysical, 20.0);

		War3_AddItemBuff(shopItem[DRAGONMAIL], fArmorMagic, 50.0);
#endif

		War3_AddItemBuff(shopItem[SOCK], fLowGravityItem, GetConVarFloat(SockCvar));
		War3_AddItemBuff(shopItem[NECKLACE], fUltimateResistance, 0.6);
		War3_AddItemBuff(shopItem[RING], fHPRegen, GetConVarFloat(RegenHPTFCvar));
		War3_AddItemBuff(shopItem[BOOTS], fMaxSpeed2, GetConVarFloat(BootsSpeedCvar));
		War3_AddItemBuff(shopItem[SHIELD], fAbilityResistance, 0.6);
		War3_AddItemBuff(shopItem[GAUNTLET], iAdditionalMaxHealth, 35);
		War3_AddItemBuff(shopItem[ARMBAND], fAttackSpeed, 1.15);
		War3_AddItemBuff(shopItem[CLAW],fDamageModifier,GetConVarFloat(ClawsAttackCvar));
		War3_AddItemBuff(shopItem[MASK],fVampirePercent,GetConVarFloat(MaskDeathCvar));
		War3_AddItemBuff(shopItem[DIVINERAPIER], iDamageBonus, 4);
		War3_AddItemBuff(shopItem[FAITH],fArmorMagic,5.0);
		War3_AddItemBuff(shopItem[COURAGE],fArmorPhysical,5.0);
		War3_AddItemBuff(shopItem[REFRESHERORB],fCooldownReduction,1.4);
		War3_AddItemBuff(shopItem[GLIMMERCAPE],fArmorMagic,7.0);
		War3_AddItemBuff(shopItem[RINGOFPROTECTION],fArmorPhysical,3.0);
		War3_AddItemBuff(shopItem[TALISMANOFEVASION],fDodgeChance,0.15);
		War3_AddItemBuff(shopItem[BLADEMAIL],fArmorPhysical,7.0);
		War3_AddItemBuff(shopItem[BLADEMAIL],fMeleeThorns,0.65);
		War3_AddItemBuff(shopItem[ASSAULTCUIRASS],fArmorPhysical,5.0);
		War3_AddItemBuff(shopItem[ASSAULTCUIRASS],fAttackSpeed,1.1);
		War3_AddItemBuff(shopItem[HEARTOFTARRASQUE],fMaxHealthRegen,0.04);
		War3_AddItemBuff(shopItem[NULLTALISMAN],fHPRegen,1.0);
		War3_AddItemBuff(shopItem[NULLTALISMAN],fArmorPhysical,1.0);
		War3_AddItemBuff(shopItem[NULLTALISMAN],fArmorMagic,1.0);
		War3_AddItemBuff(shopItem[NULLTALISMAN],fMaxSpeed2,0.05);
		War3_AddItemBuff(shopItem[NULLTALISMAN],fDamageModifier,0.05);
		War3_AddItemBuff(shopItem[DAEDALUS],fCritChance,0.2);
		War3_AddItemBuff(shopItem[DAEDALUS],fCritModifier,1.5);
		War3_AddItemBuff(shopItem[BLOODBOUNDGEM],fSustainEfficiency,0.4);
		War3_AddItemBuff(shopItem[MANTLEOFINTEL],fMagicDamageModifier,0.25);
		War3_AddItemBuff(shopItem[OIL],fArmorPenetration,2.0);
		War3_AddItemBuff(shopItem[DESOLATOR],fArmorPenetration,3.0);
	}
}

public Action FiveSecondLoop(Handle timer, any data){
	if(W3Paused()) return Plugin_Continue;

	for(int client=1; client <= MaxClients; client++)
	{
		if(!ValidPlayer(client, true))
			continue;

		if(War3_GetOwnsItem(client, shopItem[MEKANSM])){
			for(int i=1;i<=MaxClients;++i){
				if(!ValidPlayer(i,true))
					continue;
				if(IsOnDifferentTeams(client, i))
					continue;
				if(GetPlayerDistance(client, i) > 350.0)
					continue;
				
				War3_HealToMaxHP(i, 15);
			}
		}
	}
	return Plugin_Continue;
}

#if GGAMETYPE == GGAME_TF2
int HealingTarget[MAXPLAYERSCUSTOM];
public Action:SecondLoop(Handle:timer,any:data)
{
	if(W3Paused()) return Plugin_Continue;

	for(int client=1; client <= MaxClients; client++)
	{
		if(ValidPlayer(client, true))
		{
			// Medic Special Items
			if (TF2_GetPlayerClass(client) != TFClass_Medic)
				continue;	// Client isnt valid

			int HealTarget = TF2_GetHealingTarget(client);

			if(HealingTarget[client]>0 && HealingTarget[client]!=HealTarget)
			{
				//DP("HealingTarget[client]!=HealTarget");
				// reset buffs
				//fMaxSpeed2
				War3_SetBuffItem(HealingTarget[client],fMaxSpeed2,shopItem[MBOOTS],0.0);
				// Regen
				War3_SetBuffItem(HealingTarget[client],fHPRegen,shopItem[MRING],0.0);
				// Additional Health
				War3_SetBuffItem(HealingTarget[client],iAdditionalMaxHealth,shopItem[MHEALTH],0);
			}


			if(ValidPlayer(HealTarget))
			{
				HealingTarget[client]=HealTarget;

				if(IsPlayerAlive(HealTarget)) // if alive
				{
					//DP("HealTarget IsPlayerAlive 368");
					if(War3_GetOwnsItem(client,shopItem[MBOOTS]))
					{
						//fMaxSpeed2
						War3_SetBuffItem(HealTarget,fMaxSpeed2,shopItem[MBOOTS],0.2,client);
						//CreateTimer(1.0,SecondLoop,_,TIMER_REPEAT);
						//DP("set MaxSpeed2 HealTarget");
					}
					if(War3_GetOwnsItem(client,shopItem[MRING]))
					{
						// Regen
						War3_SetBuffItem(HealTarget,fHPRegen,shopItem[MRING],2.0,client);
						//DP("set fHPRegen HealTarget");
					}
					if(War3_GetOwnsItem(client,shopItem[MHEALTH]))
					{
						// Regen
						War3_SetBuffItem(HealTarget,iAdditionalMaxHealth,shopItem[MHEALTH],100,client);
						//DP("set iAdditionalMaxHealth HealTarget");
					}
					continue;
				}
				else
				{
					//DP("HealTarget !IsPlayerAlive 392");
					HealingTarget[client]=-1;
					if(War3_GetOwnsItem(client,shopItem[MBOOTS]))
					{
						//fMaxSpeed2
						War3_SetBuffItem(HealTarget,fMaxSpeed2,shopItem[MBOOTS],0.0,client);
						//DP("UNSET fMaxSpeed2 HealTarget");
					}
					if(War3_GetOwnsItem(client,shopItem[MRING]))
					{
						// Regen
						War3_SetBuffItem(HealTarget,fHPRegen,shopItem[MRING],0.0,client);
						//DP("UNSET fHPRegen HealTarget");
					}
					if(War3_GetOwnsItem(client,shopItem[MHEALTH]))
					{
						// Regen
						War3_SetBuffItem(HealTarget,iAdditionalMaxHealth,shopItem[MHEALTH],0,client);
						//DP("UNSET iAdditionalMaxHealth HealTarget");
					}
					continue;
				}
			}
			else
			{
				//DP("HealTarget IsInvalid");
				if(HealingTarget[client]>0)
				{
					// reset buffs
					//fMaxSpeed2
					War3_SetBuffItem(HealingTarget[client],fMaxSpeed2,shopItem[MBOOTS],0.0);
					// Regen
					War3_SetBuffItem(HealingTarget[client],fHPRegen,shopItem[MRING],0.0);
					// Additional Health
					War3_SetBuffItem(HealingTarget[client],iAdditionalMaxHealth,shopItem[MHEALTH],0);
				}
				HealingTarget[client]=-1;
			}
		}
	}

	return Plugin_Continue;
}
#endif

public Action:PointOneSecondLoop(Handle:timer,any:data)
{
	if(W3Paused()) return Plugin_Continue;

#if GGAMETYPE_JAILBREAK == JAILBREAK_OFF
	if(war3ready){
		doCloak();
	}
#endif
	return Plugin_Continue;
}
#if GGAMETYPE_JAILBREAK == JAILBREAK_OFF
public doCloak() //this loop should detec weapon chnage and add a new alpha
{
	for(int x=1;x<=MaxClients;x++)
	{
		if(ValidPlayer(x,true)&&War3_GetOwnsItem(x,shopItem[CLOAK]))
		{
			//knife? melle?
			if(War3_IsUsingMeleeWeapon(x))
			{
				War3_SetBuffItem(x,fInvisibilityItem,shopItem[CLOAK],0.4);
			}
			else
			{
				War3_SetBuffItem(x,fInvisibilityItem,shopItem[CLOAK],0.6); // was 0.5
			}
		}
	}
}
#endif
public OnW3Denyable(W3DENY:event,client)
{
	if((event == DN_CanBuyItem1) && (W3GetVar(EventArg1) == shopItem[SHIELD]) && (War3_GetOwnsItem(client, shopItem[NECKLACE]) && GetConVarBool(ShieldRestrictionCvar)))
	{
		W3Deny();
		War3_ChatMessage(client, "Cannot wear Necklace and Shield at the same time.");
	}
	if((event == DN_CanBuyItem1) && (W3GetVar(EventArg1) == shopItem[NECKLACE]) && (War3_GetOwnsItem(client, shopItem[SHIELD])) && GetConVarBool(ShieldRestrictionCvar))
	{
		W3Deny();
		War3_ChatMessage(client, "Cannot wear Necklace and Shield at the same time.");
	}
#if GGAMETYPE == GGAME_TF2
	if((event == DN_CanBuyItem1) && (W3GetVar(EventArg1) == shopItem[MBOOTS]) && TF2_GetPlayerClass(client) != TFClass_Medic)
	{
		W3Deny();
	}
	if((event == DN_CanBuyItem1) && (W3GetVar(EventArg1) == shopItem[MRING]) && TF2_GetPlayerClass(client) != TFClass_Medic)
	{
		W3Deny();
	}
	if((event == DN_CanBuyItem1) && (W3GetVar(EventArg1) == shopItem[MHEALTH]) && TF2_GetPlayerClass(client) != TFClass_Medic)
	{
		W3Deny();
	}
#endif
}



public OnItemPurchase(client,item)
{
	if(!ValidPlayer(client))
		return 0;

	if(shopItem[MBOOTS]==item){
		War3_SetBuffItem(client,fMaxSpeed2,shopItem[MBOOTS],0.2);
	}
	if(shopItem[SOCK]==item){
		War3_ChatMessage(client,"You pull on your socks");
	}
	if(shopItem[TOME]==item) // tome of xp
	{
		//War3Source_Races W3racefunctions = War3Source_Races();
		int race=War3_GetRace(client);
		int add_xp=GetConVarInt(TomeCvar);
		if(add_xp<0)	add_xp=0;
		War3_SetXP(client,race,War3_GetXP(client,race)+add_xp);
		W3DoLevelCheck(client);
		War3_SetOwnsItem(client,item,false);
		War3_ChatMessage(client,"+%i XP",add_xp);
		War3_ShowXP(client);
	}
	
	if(!War3_GetItemProperty(item, ITEM_USED_ON_BUY)){
		War3_NotifyPlayerItemActivated(client,item,true);
	}
}

//deactivate BUFFS AND PASSIVES
public OnItemLost(client,item){ //deactivate passives , client may have disconnected
	if(!ValidPlayer(client))
		return 0;
	if(shopItem[MBOOTS]==item)
	{
		War3_SetBuffItem(client,fMaxSpeed2,shopItem[MBOOTS],0.0);
		if(HealingTarget[client]>0)
			War3_SetBuffItem(HealingTarget[client],fMaxSpeed2,shopItem[MBOOTS],0.0);
	}
	if(shopItem[MRING]==item)
	{
		if(HealingTarget[client]>0)
			War3_SetBuffItem(HealingTarget[client],fHPRegen,shopItem[MRING],0.0);
	}
	if(shopItem[MHEALTH]==item)
	{
		if(HealingTarget[client]>0)
			War3_SetBuffItem(HealingTarget[client],iAdditionalMaxHealth,shopItem[MHEALTH],0);
	}
	if(!War3_GetItemProperty(item, ITEM_USED_ON_BUY)){
		War3_NotifyPlayerItemActivated(client,item,false);
	}
}
///change ownership only, DO NOT RESET BUFFS here, do that in OnItemLost
public OnWar3EventDeath(victim, attacker, deathrace, distance, attacker_hpleft)
{
	if (ValidPlayer(victim))
	{
		bDidDie[victim]=true;
		for(int i = 0;i<MAXITEMS;++i){
			if(War3_GetOwnsItem(victim,i))
				War3_SetOwnsItem(victim, i, false);
		}
	}
}

public void OnWar3EventSpawn (int client)
{
	if( bFrosted[client])
	{
		bFrosted[client]=false;
		War3_SetBuffItem(client,fSlow,shopItem[FROST],1.0);
	}
	bDidDie[client]=false;
}

// use? OnW3TakeDmgAll
/*
Trying to resolve:  I think we should try OnW3TakeDmgAll because it allows damage.
[SM] Displaying call stack trace for plugin "war3source/War3Source_Engine_DamageSystem.smx":
L 12/08/2012 - 02:58:58: [SM]   [0]  Line 455, War3Source_Engine_DamageSystem.sp::Native_War3_DealDamage()
L 12/08/2012 - 02:58:58: [SM] Plugin encountered error 25: Call was aborted
L 12/08/2012 - 02:58:58: [SM] Native "War3_DealDamage" reported: Error encountered while processing a dynamic native
L 12/08/2012 - 02:58:58: [SM] Displaying call stack trace for plugin "war3source/War3Source_013_SuccubusHunter.smx":
L 12/08/2012 - 02:58:58: [SM]   [0]  Line 213, War3Source_013_SuccubusHunter.sp::OnWar3EventPostHurt()
L 12/08/2012 - 03:06:15: Error log file session closed.

same error above except with shopmenu items
*/
//public OnWar3EventPostHurt(victim,attacker,damage){

public Action OnW3TakeDmgAll(int victim,int attacker, float damage)
{
	if(!W3IsOwnerSentry(attacker))
	{
		if(ValidPlayer(attacker,true) && ValidPlayer(victim,true))
		{
			if(GetClientTeam(victim)==GetClientTeam(attacker))
			{
				return Plugin_Continue;
			}
		}
		if(W3GetDamageIsBullet()&&ValidPlayer(victim)&&ValidPlayer(attacker,true))
		{
			//DP("bullet 1 claw %d vic alive%d",War3_GetOwnsItem(attacker,shopItem[CLAW]),ValidPlayer(victim,true,true));
			//int vteam=GetClientTeam(victim);
			//int ateam=GetClientTeam(attacker);

			if(!Perplexed(attacker))
			{
				if(ValidPlayer(victim))
				{
					if(War3_GetOwnsItem(attacker,shopItem[FROST]) && !bFrosted[victim])
					{
						if(W3Chance(W3ChanceModifier(attacker)) && GetRandomFloat(0.0,1.0)<=0.25)
						{
							float speed_frost=GetConVarFloat(OrbFrostCvar);
							if(speed_frost<=0.0) speed_frost=0.01; // 0.0 for override removes
							if(speed_frost>1.0)	speed_frost=1.0;
							War3_SetBuffItem(victim,fSlow,shopItem[FROST],speed_frost);
							bFrosted[victim]=true;

							PrintHintText(victim,"Frosted! %.2f% speed!", 100.0*(speed_frost-1.0));

							CreateTimer(1.0,Unfrost,victim);
						}	
					}
					if(War3_GetOwnsItem(attacker,shopItem[ORBOFVENOM])){
						DOTStock(victim,attacker,4.0,-1,DMG_GENERIC,4,0.5,1.0);
					}
					if(War3_GetOwnsItem(victim,shopItem[PANICNECKLACE])){
						TF2_AddCondition(victim, TFCond_SpeedBuffAlly, 2.0);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Unfrost(Handle:timer,any:client)
{
	bFrosted[client]=false;
	War3_SetBuffItem(client,fSlow,shopItem[FROST],1.0);
	if(ValidPlayer(client))
	{
		PrintToConsole(client,"%T","REGAINED SPEED from frost",client);
	}
}

public void OnWar3Event(W3EVENT event,int client)
{
	if(event==ClearPlayerVariables){
		bDidDie[client]=false;
	}
}

stock GetMoney(player)
{
	return GetEntData(player,MoneyOffsetCS);
}

stock SetMoney(player,money)
{
	SetEntData(player,MoneyOffsetCS,money);
}

#if GGAMETYPE == GGAME_TF2
public Action OnW3TakeDmgBullet(int victim, int attacker, float damage)
{
#if GGAMETYPE == GGAME_TF2
	if (!W3IsOwnerSentry(attacker))
	{
#endif
		if(ValidPlayer(victim, true) && ValidPlayer(attacker) && victim != attacker)
		{
			if (GetClientTeam(victim) != GetClientTeam(attacker))
			{
				if(War3_GetOwnsItem(attacker, shopItem[FIREORB]) && !(TF2_IsPlayerInCondition(victim, TFCond_OnFire)) && !Perplexed(attacker))
				{
					char GetWeapon[64];
					if(ValidPlayer(attacker,true,true))
					{
						GetClientWeapon( attacker, GetWeapon , 64);
					}
					else
					{
						GetWeapon = "";
					}
					if(GetRandomFloat(0.0,1.0)<=getClassChance(attacker))
					{
						TF2_IgnitePlayer(victim, attacker, 3.0);
					}
				}
			}
		}
#if GGAMETYPE == GGAME_TF2
	}
#endif
	return Plugin_Continue;
}
float getClassChance(attacker) {
	float chance;
	switch (TF2_GetPlayerClass(attacker))
	{
		case TFClass_Scout:
		{
			chance = 0.4;
		}
		case TFClass_Sniper:
		{
			chance = 0.6;
		}
		case TFClass_Soldier:
		{
			chance = 0.5;
		}
		case TFClass_DemoMan:
		{
			chance = 0.5;
		}
		case TFClass_Medic:
		{
			chance = 0.2;
		}
		case TFClass_Heavy:
		{
			chance = 0.2;
		}
		case TFClass_Pyro:
		{
			chance = 0.5;
		}
		case TFClass_Spy:
		{
			chance = 0.4;
		}
		case TFClass_Engineer:
		{
			chance = 0.2;
		}
		default:
		{
			chance = 0.3;
		}
	}
	return chance;
}
#endif