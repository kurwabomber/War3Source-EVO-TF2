#include <war3source>

#define PLUGIN_VERSION "(7/1/2016)"
/**
 * File: War3Source_ShopItems.sp
 * Description: The shop items that come with War3Source.
 * Author(s): Anthony Iacono
 *
 *-- Added mypiggybank  == Cash Regen for MVM
 *-- Uncomment line 143 in order to enable it.
 *--
 *-- El Diablo
 *-- www.war3evo.info
 */

#pragma semicolon 1

#assert GGAMEMODE == MODE_WAR3SOURCE

int ItemID[MAXITEMS2];

public Plugin:myinfo =
{
	name = "W3S - Shopitems2",
	author = "Ownz & El Diablo",
	description = "The shop items that come with War3Source:EVO.",
	version = "1.0.0.0",
	url = "http://war3source.com/"
};


public OnPluginStart()
{
	CreateConVar("war3_shopmenu2",PLUGIN_VERSION,"War3Source:EVO shopmenu 2",FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==10){
		for(int x=0;x<MAXITEMS2;x++)
			ItemID[x]=0;

		ItemID[POSTHASTE]=War3_CreateShopItem2T("posthaste","+7.5% speed",15);
		if(ItemID[POSTHASTE]==0){
			DP("ERR ITEM ID RETURNED IS ZERO");
		}
		ItemID[TRINKET]=War3_CreateShopItem2T("trinket","+1 HP regeneration",15);
		ItemID[LIFETUBE]=War3_CreateShopItem2T("lifetube","+2 HP regeneration",35);
		ItemID[SNAKE_BRACELET]=War3_CreateShopItem2T("sbracelt","+5% Evasion",30);
		ItemID[FORTIFIED_BRACER]=War3_CreateShopItem2T("fbracer","+15 max HP",25);
		ItemID[LIGHTARMORPLATES]=War3_CreateShopItem2T("lplates","+5% defense",20);
		ItemID[ENHANCEDWEAPONRY]=War3_CreateShopItem2T("eweapon","+3% damage",20);
		ItemID[SCROLLOFGROWTH]=War3_CreateShopItem2T("eweapon","+100% exp bonus",300);
	}
}

public OnItem2Purchase(client,item)
{
	if(item==ItemID[POSTHASTE] )
	{
		War3_SetBuffItem2(client,fMaxSpeed2,ItemID[POSTHASTE],0.075);
	}
	if(item==ItemID[TRINKET] )
	{
		War3_SetBuffItem2(client,fHPRegen,ItemID[TRINKET],1.0);
	}
	if(item==ItemID[LIFETUBE] )
	{
		War3_SetBuffItem2(client,fHPRegen,ItemID[LIFETUBE],2.0);
	}
	if(item==ItemID[FORTIFIED_BRACER]){

		War3_SetBuffItem2(client,iAdditionalMaxHealth,ItemID[FORTIFIED_BRACER],15);
		War3_SetBuffItem2(client,fHPRegenDeny,ItemID[FORTIFIED_BRACER],true);
		War3_HealToMaxHP(client,15);
	}
	if(item==ItemID[SNAKE_BRACELET])
	{
		War3_SetBuffItem2(client,fDodgeChance,ItemID[SNAKE_BRACELET],0.05);
	}
	if(item==ItemID[LIGHTARMORPLATES])
	{
		War3_SetBuffItem2(client,fArmorPhysical,ItemID[LIGHTARMORPLATES],1.0);
	}
	if(item==ItemID[ENHANCEDWEAPONRY])
	{
		War3_SetBuffItem2(client,fDamageModifier,ItemID[ENHANCEDWEAPONRY],0.03);
	}
	if(item==ItemID[SCROLLOFGROWTH])
	{
		War3_SetBuffItem2(client,fExperienceBonus,ItemID[SCROLLOFGROWTH],1.0);
	}
}

public OnItem2Lost(client,item){ //deactivate passives , client may have disconnected
	if(item==ItemID[POSTHASTE]){
		War3_SetBuffItem2(client,fMaxSpeed2,ItemID[POSTHASTE],0.0);
	}
	if(item==ItemID[TRINKET] )
	{
		War3_SetBuffItem2(client,fHPRegen,ItemID[TRINKET],0.0);
	}
	if(item==ItemID[LIFETUBE] )
	{
		War3_SetBuffItem2(client,fHPRegen,ItemID[LIFETUBE],0.0);
	}
	if(item==ItemID[FORTIFIED_BRACER]){
		War3_SetBuffItem2(client,iAdditionalMaxHealth,ItemID[FORTIFIED_BRACER],0);
		War3_SetBuffItem(client,fHPRegenDeny,ItemID[FORTIFIED_BRACER],false);
	}
	if(item==ItemID[SNAKE_BRACELET])
	{
		War3_SetBuffItem2(client,fDodgeChance,ItemID[SNAKE_BRACELET],0.0);
	}
	if(item==ItemID[LIGHTARMORPLATES])
	{
		War3_SetBuffItem2(client,fArmorPhysical,ItemID[LIGHTARMORPLATES],0.0);
	}
	if(item==ItemID[ENHANCEDWEAPONRY])
	{
		War3_SetBuffItem2(client,fDamageModifier,ItemID[ENHANCEDWEAPONRY],0.0);
	}
	if(item==ItemID[SCROLLOFGROWTH])
	{
		War3_SetBuffItem2(client,fExperienceBonus,ItemID[SCROLLOFGROWTH],0.0);
	}
}