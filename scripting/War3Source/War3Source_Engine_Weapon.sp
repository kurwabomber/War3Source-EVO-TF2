// War3Source_Engine_Weapon.sp

//#assert GGAMEMODE == MODE_WAR3SOURCE
#include <tf2attributes>

new String:weaponsAllowed[MAXPLAYERSCUSTOM][MAXRACES][300];
new restrictionPriority[MAXPLAYERSCUSTOM][MAXRACES];
new highestPriority[MAXPLAYERSCUSTOM];
new bool:restrictionEnabled[MAXPLAYERSCUSTOM][MAXRACES]; ///if restriction has length, then this should be true (caching allows quick skipping)
new bool:hasAnyRestriction[MAXPLAYERSCUSTOM]; //if any of the races said client has restriction, this is true (caching allows quick skipping)

/*
public Plugin:myinfo=
{
	name="W3S Engine Weapons",
	author="Ownz (DarkEnergy)",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};
*/

/*
public Action:cmddroptest(client,args){
	if(W3IsDeveloper(client)){
		War3_WeaponRestrictTo(client, War3_GetRace(client),"weapon_knife",1);
	}
	return Plugin_Handled;
} */

public bool:War3Source_Engine_Weapon_InitNatives()
{
	CreateNative("War3_WeaponRestrictTo",NWar3_WeaponRestrictTo);
	CreateNative("War3_GetWeaponRestriction",NWar3_GetWeaponRestrict);
	CreateNative("W3GetCurrentWeaponEnt",NW3GetCurrentWeaponEnt);
	CreateNative("W3DropWeapon",NW3DropWeapon);

	return true;
}

public NW3GetCurrentWeaponEnt(Handle:plugin,numParams)
{
	return GetEntPropEnt(GetNativeCell(1), Prop_Send, "m_hActiveWeapon");
}

public NW3DropWeapon(Handle:plugin,numParams)
{
	new client = GetNativeCell(1);
	new wpent = GetNativeCell(2);
	if (ValidPlayer(client,true) && IsValidEdict(wpent)){
#if GGAMETYPE != GGAME_TF2
		CS_DropWeapon(client,wpent,true);
#endif
		//SDKHooks_DropWeapon(client, wpent);
	}
}

public NWar3_WeaponRestrictTo(Handle:plugin,numParams)
{

	new client=GetNativeCell(1);
	new raceid=GetNativeCell(2);
	new String:restrictedto[300];
	GetNativeString(3,restrictedto,sizeof(restrictedto));

	restrictionPriority[client][raceid]=GetNativeCell(4);
	//new String:pluginname[100];
	//GetPluginFilename(plugin, pluginname, 100);
	//PrintToServer("%s NEW RESTRICTION: %s",pluginname,restrictedto);
	//LogError("%s NEW RESTRICTION: %s",pluginname,restrictedto);
	//PrintIfDebug(client,"%s NEW RESTRICTION: %s",pluginname,restrictedto);
	strcopy(weaponsAllowed[client][raceid],200,restrictedto);
}

public NWar3_GetWeaponRestrict(Handle:plugin,numParams)
{
	new client=GetNativeCell(1);
	new raceid=GetNativeCell(2);
	//new String:restrictedto[300];
	new maxsize=GetNativeCell(4);
	if(maxsize>0) SetNativeString(3, weaponsAllowed[client][raceid], maxsize, false);
}

public War3Source_Engine_Weapon_OnClientPutInServer(client)
{
	//War3_WeaponRestrictTo(client,0,""); //REMOVE RESTICTIONS ON JOIN
	int limit=GetRacesLoaded();
	for(int raceid=0;raceid<=limit;raceid++){
		restrictionEnabled[client][raceid]=false;
		//Format(weaponsAllowed[client][i],3,"");

	}
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse); //weapon touch and equip only
}
public War3Source_Engine_Weapon_OnClientDisconnect(client)
{
	SDKUnhook(client,SDKHook_WeaponCanUse,OnWeaponCanUse);
}

bool:CheckCanUseWeapon(client,weaponent){
	decl String:WeaponName[32];
	GetEdictClassname(weaponent, WeaponName, sizeof(WeaponName));

	if(StrContains(WeaponName,"c4")>-1)
	{ //allow c4
		return true;
	}

	int limit=GetRacesLoaded();
	for(int raceid=0;raceid<=limit;raceid++)
	{
		if(restrictionEnabled[client][raceid]&&restrictionPriority[client][raceid]==highestPriority[client])
		{ //cached strlen is not zero
			if(StrContains(weaponsAllowed[client][raceid],WeaponName)<0)
			{ //weapon name not found
				return false;
			}
		}
	}
	return true; //allow
}

public Action:OnWeaponCanUse(client, weaponent)
{
	if(hasAnyRestriction[client]){
		if(CheckCanUseWeapon(client,weaponent))
		{
			return Plugin_Continue; //ALLOW
		}
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public War3Source_Engine_Weapon_DeciSecondTimer()
{
	if(MapChanging || War3SourcePause) return 0;

	for(new client=1;client<=MaxClients;++client)
	{
		if(ValidPlayer(client,true))
		{
			new Float:multi = W3GetBuffStackedFloat(client,fAttackSpeed);
			TF2Attrib_SetByName(client, "fire rate bonus", 1.0/multi);
			TF2Attrib_SetByName(client, "mult smack time", 1.0/multi);
			TF2Attrib_SetByName(client, "effect bar recharge rate increased", 1.0/multi);
			TF2Attrib_SetByName(client, "mult_item_meter_charge_rate", 1.0/multi);
		}
	}
	return 1;
}