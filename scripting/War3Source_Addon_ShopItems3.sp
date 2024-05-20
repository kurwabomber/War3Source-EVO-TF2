#include <war3source>
#include <tf2attributes>

#define PLUGIN_VERSION "1.0"

#pragma semicolon 1

int ItemID[MAXITEMS3];
float currentBarrier[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "War3Evo:Shop items 3",
	author = "Razor",
	description = "Implement sh3 items.",
	version = "1.0",
	url = "no."
};

public void OnAllPluginsLoaded()
{
	W3Hook(W3Hook_OnW3TakeDmgBulletPre, OnW3TakeDmgBulletPre);
}

public OnPluginStart()
{
	CreateConVar("war3_shopmenu3",PLUGIN_VERSION,"War3Source:EVO shopmenu 3",FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	CreateTimer(0.2, Timer_QuickTimer, _, TIMER_REPEAT);
	CreateTimer(3.0, Timer_SlowTimer, _, TIMER_REPEAT);
	CreateTimer(10.0, Timer_Every10s, _, TIMER_REPEAT);
}

public OnClientPutInServer(client)
{
	SDKHook(client,SDKHook_TraceAttack,SDK_Forwarded_TraceAttack);
}

public OnClientDisconnect(client)
{
	SDKUnhook(client,SDKHook_TraceAttack,SDK_Forwarded_TraceAttack);
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==20){

		for(int x=0;x<MAXITEMS3;x++)
			ItemID[x]=0;

		//Red - Offensive
		ItemID[REDTEARSTONE]=War3_CreateShopItem3("Red Tearstone","red_tearstone","Gain a 15%% damage boost while at 25%% or below.\nLeveling up increases threshold. Adds 2%% per level.",40,"Red","Red Tearstone",10,"Red Tearstone",0);
		if(ItemID[REDTEARSTONE]==0){
			DP("Shopitems 3 | Something went wrong while generating IDs for items.");
		}

		ItemID[STORMHEART]=War3_CreateShopItem3("Heart of the Storm","stormheart","Adds +2 damage to all hits.\nLeveling up increases additive damage. Adds 0.1 damage per level.",80,"Red","Heart of the Storm",10,"Heart of the Storm",0);

		//Yellow - Modifiers
		ItemID[WINDPEARL]=War3_CreateShopItem3("Cloudy Pearl","windpearl","Gives +6%% movespeed.\nLeveling increases movespeed. 1%% increase per level.",30,"Yellow","Cloudy Pearl",10,"Cloudy Pearl",0);
		ItemID[FREEZE]=War3_CreateShopItem3("Frozen Fists","freeze","Hits have a 10% chance to stop enemy movement for 0.2 seconds.\nCannot level up.",60,"Yellow","Frozen Fists",0,"Frozen Fists",0);
		
		//Blue - Survivability
		ItemID[BLUETEARSTONE]=War3_CreateShopItem3("Blue Tearstone","blue_tearstone","Gain a 20%% defense boost while at 25%% or below.\nLeveling up increases threshold. Adds 2%% per level.",30,"Blue","Blue Tearstone",10,"Blue Tearstone",0);
		ItemID[UBERHEART]=War3_CreateShopItem3("Ubered Heart","uberheart","Gives +2.5%% max health.\nLeveling up increases max health. +0.2%% max health per level.",50,"Blue","Ubered Heart",10,"Ubered Heart",0);
		
		//Orange - Red & Yellow
		ItemID[MAGMACHARM]=War3_CreateShopItem3("Magmatic Charm","magmacharm","Ignites target for 1 second on hit.\nCannot level up.",90,"Orange","Magmatic Charm",0,"Magmatic Charm",0);
		ItemID[POISONGEM]=War3_CreateShopItem3("Poison Gem","poisongem","10%% chance to apply 4 ticks of 2 dmg poison on hit.\nLeveling up decreases tickspeed and increases damage.\n -0.05s per tick per level, +0.25 dmg per level.",50,"Orange","Poison Gem",10,"Poison Gem",0);
		
		//Green - Blue & Yellow
		ItemID[SPRINGGEM]=War3_CreateShopItem3("Spring Gem","spring","Gives +2/s regen.\nWhile your health is below or equal to 40%%, regen is boosted by 2x.\nUpgrading increases regen. 0.1 regen per level.",60,"Green","Spring Gem",10,"Spring Gem",0);
		ItemID[SOLARCREST]=War3_CreateShopItem3("Solar Crest","heat","Gives a 20 damage barrier every 10s that gives:\n+1 armor while active. Increases armor bonus by +0.05 per level.",50,"Green","Solar Crest",20,"Solar Crest",0);
		
		//Purple - Red & Blue
		ItemID[MARKSMAN]=War3_CreateShopItem3("Marksman's Sign","marksman","Shots to the head deal 15%% more damage and have 15%% lifesteal.\nLeveling up increases lifesteal. +1%% lifesteal per level.",50,"Purple","Marksman's Sign",10,"Marksman's Sign",0);
		ItemID[RAGE]=War3_CreateShopItem3("Rage Gem","rage","You gain 0.2%% attackspeed per 1%% health missing.\nLeveling up increases attackspeed. +0.005%% attackspeed per level.",55,"Purple","Rage Gem",10,"Rage Gem",0);
		ItemID[RUNESHARD]=War3_CreateShopItem3("Rune Shard","runeshard","Gives 1.1x cooldown reduction. Increased by +0.005 per level.",70,"Purple","Rune Shard",10,"Rune Shard",0);

		//Prism - All or Misc
		ItemID[SANGE]=War3_CreateShopItem3("Sange","sange","Gives +5%% healing efficiency and +5%% damage.\nEach level gives +0.3%% healing efficiency and attackspeed.",200,"Prismatic","Sange",20,"Sange",0);
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	War3_SetBuffItem3(client,iDamageBonus,ItemID[STORMHEART],0);
	War3_SetBuffItem3(client,fDamageModifier,ItemID[REDTEARSTONE],0.0);
	War3_SetBuffItem3(client,fAttackSpeed,ItemID[RAGE],1.0);
	War3_SetBuffItem3(client,fHPRegen,ItemID[SPRINGGEM],0.0);
	War3_SetBuffItem3(client,fBashChance,ItemID[FREEZE],0.0);
	War3_SetBuffItem3(client,fBashDuration,ItemID[FREEZE],0.0);
	War3_SetBuffItem3(client,fMaxHealth,ItemID[UBERHEART],1.0);
	War3_SetBuffItem3(client,fCooldownReduction,ItemID[RUNESHARD],1.0);
	War3_SetBuffItem3(client,fMaxSpeed2, ItemID[WINDPEARL], 0.0);

	War3_SetBuffItem3(client,fArmorPhysical,ItemID[SOLARCREST],0.0);
	War3_SetBuffItem3(client,fArmorMagic,ItemID[SOLARCREST],0.0);
	currentBarrier[client] = 0.0;

	//Sange
	War3_SetBuffItem3(client,fSustainEfficiency,ItemID[SANGE],0.0);
	War3_SetBuffItem3(client,fDamageModifier,ItemID[SANGE],0.0);
	War3_SetBuffItem3(client,fAttackSpeed,ItemID[SANGE],1.0);
}

public Action:Timer_QuickTimer(Handle:timer)
{
	for(new client = 1; client <= MaxClients; ++client)
	{
		if(ValidPlayer(client, true))
		{
			new race = War3_GetRace(client);
			if(!ValidRace(race))
				continue;

			if(War3_GetOwnsItem3(client,race,ItemID[SPRINGGEM]))
			{
				new level = War3_GetItemLevel(client,race,ItemID[SPRINGGEM])+1;
				new Float:RegenPerTick = 2.0 + level * 0.1;
				
				new clientHealth = GetEntProp(client, Prop_Data, "m_iHealth");
				new clientMaxHealth = War3_GetMaxHP(client);
				if(clientHealth <= RoundToNearest(clientMaxHealth * 0.4))
				{
					RegenPerTick *= 2.0;
				}
				War3_SetBuffItem3(client,fHPRegen,ItemID[SPRINGGEM],RegenPerTick);
			}
		
			if(War3_GetOwnsItem3(client,race,ItemID[REDTEARSTONE]))
			{
				new level = War3_GetItemLevel(client,race,ItemID[REDTEARSTONE])+1;
				if(level > 0)
				{
					if(RoundToNearest(War3_GetMaxHP(client) * (0.25 + (level * 0.02))) >= GetClientHealth(client))
					{
						War3_SetBuffItem3(client,fDamageModifier,ItemID[REDTEARSTONE],0.15);
					}
					else
					{
						War3_SetBuffItem3(client,fDamageModifier,ItemID[REDTEARSTONE],0.0);
					}
				}
			}

			if(War3_GetOwnsItem3(client,race,ItemID[RAGE]))
			{
				new level = War3_GetItemLevel(client,race,ItemID[RAGE])+1;
				if(level > 0)
				{
					new Float:ASPD;
					new VictimCurHP = GetClientHealth(client);
					new MaxHP=War3_GetMaxHP(client);
					if(VictimCurHP>=MaxHP){
						ASPD=1.0;
					}
					else{
						new missing=MaxHP-VictimCurHP;
						new Float:percentmissing=float(missing)/float(MaxHP);
						ASPD=1.0+(0.002 + (level * 0.00005))*(percentmissing*100.0);
					}
					War3_SetBuffItem3(client,fAttackSpeed,ItemID[RAGE],1.0/(1.0/ASPD));
				}
			}
			else
			{
				War3_SetBuffItem3(client,fAttackSpeed,ItemID[RAGE],1.0);
			}

			if(War3_GetOwnsItem3(client,race,ItemID[SOLARCREST]) && currentBarrier[client] > 0.0){
				War3_SetBuffItem3(client,fArmorPhysical,ItemID[SOLARCREST],1.0);
				War3_SetBuffItem3(client,fArmorMagic,ItemID[SOLARCREST],1.0);
			}
		}
	}
}
public Action:Timer_SlowTimer(Handle:timer)
{
	for(new client = 1; client <= MaxClients; ++client)
	{
		if(!ValidPlayer(client, true))
			continue;

		new race = War3_GetRace(client);
		if(!ValidRace(race))
			continue;
		
		if(War3_GetOwnsItem3(client,race,ItemID[STORMHEART])){
			War3_SetBuffItem3(client,iDamageBonus,ItemID[STORMHEART],2);
		}
		if(War3_GetOwnsItem3(client,race,ItemID[WINDPEARL])){
			new level = War3_GetItemLevel(client,race,ItemID[WINDPEARL])+1;
			War3_SetBuffItem3(client, fMaxSpeed2, ItemID[WINDPEARL], 0.06 + level*0.01);
		}

		if(War3_GetOwnsItem3(client,race,ItemID[FREEZE])){
			War3_SetBuffItem3(client,fBashChance,ItemID[FREEZE],0.1);
			War3_SetBuffItem3(client,fBashDuration,ItemID[FREEZE],0.2);
		}

		if(War3_GetOwnsItem3(client,race,ItemID[UBERHEART])){
			new level = War3_GetItemLevel(client,race,ItemID[UBERHEART])+1;
			War3_SetBuffItem3(client,fMaxHealth,ItemID[UBERHEART],1.025 + (0.002 * level));
		}
		
		if(War3_GetOwnsItem3(client, race, ItemID[RUNESHARD])){
			int level = War3_GetItemLevel(client,race,ItemID[RUNESHARD])+1;
			War3_SetBuffItem3(client,fCooldownReduction,ItemID[RUNESHARD],1.1 + 0.005*level);
		}

		if(War3_GetOwnsItem3(client, race, ItemID[SANGE])){
			int level = War3_GetItemLevel(client,race,ItemID[SANGE])+1;
			War3_SetBuffItem3(client,fSustainEfficiency,ItemID[SANGE],0.05+level*0.003);
			War3_SetBuffItem3(client,fDamageModifier,ItemID[SANGE],0.05);
			War3_SetBuffItem3(client,fAttackSpeed,ItemID[SANGE],1.0+level*0.003);
		}
	}
}
public Action:Timer_Every10s(Handle:timer)
{
	for(new client = 1; client <= MaxClients; ++client)
	{
		if(!ValidPlayer(client, true))
			continue;

		new race = War3_GetRace(client);
		if(!ValidRace(race))
			continue;
		
		if(War3_GetOwnsItem3(client,race,ItemID[SOLARCREST])){
			currentBarrier[client] = 20.0;
		}
	}
}
public Action OnW3TakeDmgBulletPre(int victim, int attacker, float damage, int damagecustom)
{
	if(ValidPlayer(attacker,false) && IsValidEntity(victim) &&victim>0&&attacker>0&&attacker!=victim)
	{
		if(ValidPlayer(victim,true))
		{
			if(GetClientTeam(victim)==GetClientTeam(attacker))
			{
				return Plugin_Continue;
			}
			if(!Perplexed(victim,false))
			{
				//BLUE
				new victimrace = War3_GetRace(victim);
				if(!ValidRace(victimrace))
					return Plugin_Continue;

				if(War3_GetOwnsItem3(victim,victimrace,ItemID[BLUETEARSTONE]))
				{
					new level = War3_GetItemLevel(victim,victimrace,ItemID[BLUETEARSTONE])+1;
					if(level > 0 && RoundToNearest(War3_GetMaxHP(attacker) * (0.25 + (level * 0.02))) >= GetClientHealth(victim))
					{
						War3_DamageModPercent(0.8);
					}
				}
				if(War3_GetOwnsItem3(victim,victimrace,ItemID[SOLARCREST]) && currentBarrier[victim] > 0.0)
				{
					if(damage > currentBarrier[victim]){
						//jankiest way to subtract damage LOL
						War3_DamageModPercent((damage - currentBarrier[victim]) / damage);
						currentBarrier[victim] = 0.0;
					}else{
						currentBarrier[victim] -= damage;
						War3_DamageModPercent(0.0);
					}
				}
			}
		}
		//Attacker Checks.
		if(!Perplexed(attacker,false))
		{
			//RED
			new attackerrace = War3_GetRace(attacker);
			if(!ValidRace(attackerrace))
				return Plugin_Continue;

			if(ValidPlayer(victim,true))
			{
				if(War3_GetOwnsItem3(attacker,attackerrace,ItemID[POISONGEM]) && GetRandomFloat(0.0,1.0)<=0.1)
				{
					new level = War3_GetItemLevel(attacker,attackerrace,ItemID[POISONGEM])+1;
					if(level > 0)
					{
						DOTStock(victim,attacker,2.0+(level*0.25),-1,0,4,0.5,1.0-(level*0.05));
					}
				}
				if(War3_GetOwnsItem3(attacker,attackerrace,ItemID[MAGMACHARM]))
				{
					new level = War3_GetItemLevel(attacker,attackerrace,ItemID[MAGMACHARM])+1;
					if(level > 0 && !TF2_IsPlayerInCondition(victim, TFCond_OnFire))
					{
						TF2_IgnitePlayer(victim, attacker, 1.0);
					}
				}
			}
		}
	}
	return Plugin_Changed;
}

public Action:SDK_Forwarded_TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	new bool:changed = false;
	if(ValidPlayer(attacker,false) && ValidPlayer(victim,false))
	{
		if(!Perplexed(attacker,false))
		{
			new attackerrace = War3_GetRace(attacker);
			if(!ValidRace(attackerrace))
				return Plugin_Continue;
			//PURPLE
			if(hitgroup == 1)
			{
				if(War3_GetOwnsItem3(attacker,attackerrace,ItemID[MARKSMAN])){
					new level = War3_GetItemLevel(attacker,attackerrace,ItemID[MARKSMAN])+1;
					if(level > 0)
					{
						War3_DealDamage(victim,RoundFloat(damage * 0.15),attacker,_,"MARKSMAN",W3DMGORIGIN_ITEM,W3DMGTYPE_PHYSICAL,_,_,true);
						changed = true;
						
						float hp_percent=0.15 + (level * 0.01);
						int add_hp=RoundFloat(damage * hp_percent);
						if(add_hp>40)	add_hp=40;
						War3_HealToBuffHP(attacker,add_hp);
					}
				}
			}
		}
	}
	if(changed)
	{
		return Plugin_Changed;
	}
	return Plugin_Continue;
}