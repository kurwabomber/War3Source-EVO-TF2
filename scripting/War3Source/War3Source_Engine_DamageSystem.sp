// War3Source_Engine_DamageSystem.sp

//would you like to see the damage stack print out?
//#define DEBUG
new String:helmSound0[]="physics/metal/metal_solid_impact_bullet1.wav";
new String:helmSound1[]="physics/metal/metal_solid_impact_bullet2.wav";
new String:helmSound2[]="physics/metal/metal_solid_impact_bullet3.wav";
new String:helmSound3[]="physics/metal/metal_solid_impact_bullet4.wav";

#if GGAMETYPE == GGAME_TF2
new Handle:PyroW3ChanceModifierCvar;
new Handle:HeavyW3ChanceModifierCvar;
#endif

new g_CurDamageType=-99;
new g_CurInflictor=-99; //variables from sdkhooks, natives retrieve them if needed
new g_CurDamageIsWarcraft=0; //for this damage only
new g_CurDamageIsTrueDamage=0; //not used yet?

new Float:g_CurDMGModifierPercent=-99.9;

new g_CurLastActualDamageDealt=-99;

bool isEntityHooked[MAXENTITIES];
new bool:g_CanSetDamageMod=false; //default false, you may not change damage percent when there is none to change
new bool:g_CanDealDamage=true; //default true, you can initiate damage out of nowhere
//for deal damage only
new g_NextDamageIsWarcraftDamage=0;
new g_NextDamageIsTrueDamage=0;

new dummyresult;

//global
#if GGAMETYPE == GGAME_TF2
new ownerOffset;
#endif

new damagestack=0;

new Float:LastDamageDealtTime[MAXPLAYERSCUSTOM];
new Float:ChanceModifier[MAXPLAYERSCUSTOM];
/*
public Plugin:myinfo=
{
	name="W3S Engine Damage",
	author="Ownz (DarkEnergy)",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};
*/

public War3Source_Engine_DamageSystem_OnPluginStart()
{
	CreateConVar("DamageSystem",PLUGIN_VERSION,"War3Source:EVO Damage System",FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
#if GGAMETYPE == GGAME_TF2
	PyroW3ChanceModifierCvar=CreateConVar("war3_pyro_w3chancemod","0.500","Float 0.0 - 1.0");
	HeavyW3ChanceModifierCvar=CreateConVar("war3_heavy_w3chancemod","0.666","Float 0.0 - 1.0");

	ownerOffset = FindSendPropInfo("CBaseObject", "m_hBuilder");
#endif
}

public War3Source_Engine_DamageSystem_OnAddSound(sound_priority)
{
	if(sound_priority==PRIORITY_TOP)
	{
		War3_AddSound(helmSound0,STOCK_SOUND);
		War3_AddSound(helmSound1,STOCK_SOUND);
		War3_AddSound(helmSound2,STOCK_SOUND);
		War3_AddSound(helmSound3,STOCK_SOUND);
	}
}

//cvar handle
#if GGAMETYPE == GGAME_TF2
new Handle:ChanceModifierSentry;
new Handle:ChanceModifierSentryRocket;
#endif
public bool:War3Source_Engine_DamageSystem_InitNatives()
{
	CreateNative("War3_DamageModPercent",Native_War3_DamageModPercent);

	CreateNative("W3GetDamageType",NW3GetDamageType);
	CreateNative("W3GetDamageInflictor",NW3GetDamageInflictor);
	CreateNative("W3GetDamageIsBullet",NW3GetDamageIsBullet);
	CreateNative("W3ForceDamageIsBullet",NW3ForceDamageIsBullet);

	CreateNative("War3_DealDamage",Native_War3_DealDamage);
	CreateNative("War3_GetWar3DamageDealt",Native_War3_GetWar3DamageDealt);

	CreateNative("W3GetDamageStack",NW3GetDamageStack);

	CreateNative("W3ChanceModifier",Native_W3ChanceModifier);
#if GGAMETYPE == GGAME_TF2
	CreateNative("W3IsOwnerSentry",Native_W3IsOwnerSentry);
#endif

#if GGAMETYPE == GGAME_TF2
	ChanceModifierSentry=CreateConVar("war3_chancemodifier_sentry","","None to use attack rate dependent chance modifier. Set from 0.0 to 1.0 chance modifier for sentry, this will override time dependent chance modifier");
	ChanceModifierSentryRocket=CreateConVar("war3_chancemodifier_sentryrocket","","None to use attack rate dependent chance modifier. Set from 0.0 to 1.0 chance modifier for sentry, this will override time dependent chance modifier");
#endif

	return true;
}
Handle p_OnW3TakeDmgAllPre;
Handle p_OnW3TakeDmgBulletPre;
Handle p_OnW3TakeDmgAll;
Handle p_OnW3TakeDmgBullet;

Handle p_OnWar3EventPostHurt;

public bool:War3Source_Engine_DamageSystem_InitNativesForwards()
{
	// BELOW NEEDS TO BE TESTED SOME DAY..
	// CHANGED TO ET_Ignore if it doesn't act funny.

	// used to be ET_Hook for OnW3TakeDmgAllPre,OnW3TakeDmgBulletPre,OnW3TakeDmgAll,and OnW3TakeDmgBullet
	// but i do not see any reason for this, as it does not return anything.

	//OnW3TakeDmgAllPre
	p_OnW3TakeDmgAllPre=CreateForward(ET_Hook,Param_Cell,Param_Cell,Param_Float);

	//OnW3TakeDmgBulletPre
	p_OnW3TakeDmgBulletPre=CreateForward(ET_Hook,Param_Cell,Param_Cell,Param_Float,Param_Cell);

	//OnW3TakeDmgAll
	p_OnW3TakeDmgAll=CreateForward(ET_Hook,Param_Cell,Param_Cell,Param_Float);

	//OnW3TakeDmgBullet
	p_OnW3TakeDmgBullet=CreateForward(ET_Hook,Param_Cell,Param_Cell,Param_Float);

	//OnWar3EventPostHurt
	p_OnWar3EventPostHurt=CreateForward(ET_Ignore,Param_Cell,Param_Cell,Param_Float,Param_String,Param_Cell,Param_Array,Param_Array);

	return true;
}

stock DamageModPercent(Float:num)
{
	if(!g_CanSetDamageMod){
		LogError("	");
		ThrowError("You may not set damage mod percent here, use ....Pre forward");
	}

	#if defined DEBUG
	PrintToServer("percent change %f",num);
	#endif
	g_CurDMGModifierPercent*=num;
}

public Native_War3_DamageModPercent(Handle:plugin,numParams)
{
	DamageModPercent(Float:GetNativeCell(1));
}



public NW3GetDamageType(Handle:plugin,numParams){
	return g_CurDamageType;
}
public NW3GetDamageInflictor(Handle:plugin,numParams){
	return g_CurInflictor;
}
public NW3GetDamageIsBullet(Handle:plugin,numParams){
	return _:(!g_CurDamageIsWarcraft);
}
public NW3ForceDamageIsBullet(Handle:plugin,numParams){
	g_CurDamageIsWarcraft=false;
}
public NW3GetDamageStack(Handle:plugin,numParams){
	return damagestack;
}


// Damage Engine needs to know about sentries and dispensers and stuff...
public OnEntityCreated(entity, const String:classname[])
{
	// Errors from this event... gives massive negative values.. should use entity > 0
	// DONT REMOVE entity>0
	Engine_Wards_Checking_OnEntityCreated(entity, classname);
	RequestFrame(ApplyDamageHooks, entity);
}
public void OnEntityDestroyed(int entity){
	if(0 <= entity < MAXENTITIES)
		isEntityHooked[entity] = false;
}
public void ApplyDamageHooks(int entity){
	if(IsValidForDamage(entity) && !isEntityHooked[entity])
	{
		SDKHook(entity, SDKHook_OnTakeDamage, SDK_Forwarded_OnTakeDamage);
		if(IS_PLAYER(entity))
			SDKHook(entity, SDKHook_OnTakeDamageAlive, OnTakeDamageAliveHook);
		else
			SDKHook(entity, SDKHook_OnTakeDamagePost, OnTakeDamagePostHook);

		isEntityHooked[entity] = true;
	}
}
public War3Source_Engine_DamageSystem_OnClientPutInServer(client){
	RequestFrame(ApplyDamageHooks, client);
}
public War3Source_Engine_DamageSystem_OnClientDisconnect(client){
	SDKUnhook(client,SDKHook_OnTakeDamage,SDK_Forwarded_OnTakeDamage);
	SDKUnhook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAliveHook);
	isEntityHooked[client] = false;
}
#if GGAMETYPE == GGAME_TF2
stock bool:IsOwnerSentry(client,bool:UseInternalInflictor=true,ExternalInflictor=0)
{
	new pSentry;
	if(UseInternalInflictor)
		pSentry=g_CurInflictor;
	else
		pSentry=ExternalInflictor;

	if(ValidPlayer(client))
	{
		if(IsValidEntity(pSentry)&&TF2_GetPlayerClass(client)==TFClass_Engineer)
		{
			decl String:netclass[32];
			GetEntityNetClass(pSentry, netclass, sizeof(netclass));

			if (strcmp(netclass, "CObjectSentrygun") == 0 || strcmp(netclass, "CObjectTeleporter") == 0 || strcmp(netclass, "CObjectDispenser") == 0)
			{
				if (GetEntDataEnt2(pSentry, ownerOffset) == client)
					return true;
			}
		}
	}
	return false;
}

public Native_W3IsOwnerSentry(Handle:plugin,numParams)
{
	return IsOwnerSentry(GetNativeCell(1),bool:GetNativeCell(2),GetNativeCell(3));
}
#endif

stock Float:fChanceModifier(attacker)
{
	if(attacker<=0 || attacker>MaxClients || !IsValidEdict(attacker))
	{
		return 1.0;
	}

#if GGAMETYPE == GGAME_TF2
	new Float:tempChance = GetRandomFloat(0.0,1.0);
	switch (TF2_GetPlayerClass(attacker))
	{
		case TFClass_Heavy:
		{
			if (tempChance <= GetConVarFloat(HeavyW3ChanceModifierCvar)) //heavy cvar here, replaces 0.666
				return 0.0;
		}
		case TFClass_Pyro:
		{
			if (tempChance <= GetConVarFloat(PyroW3ChanceModifierCvar)) //pyro cvar here, replaces 0.500
				return 0.0;
		}
	}
#endif
	return ChanceModifier[attacker];
}
public Native_W3ChanceModifier(Handle:plugin,numParams)
{
	return _:fChanceModifier(GetNativeCell(1));
}

public Action:SDK_Forwarded_OnTakeDamage(victim,&attacker,&inflictor,&Float:damage,&damagetype,&weapon,Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if(MapChanging || War3SourcePause) return Plugin_Continue;

	if(IsValidEntity(victim))
	{
		//store old variables on local stack!

		new old_DamageType= g_CurDamageType;
		new old_Inflictor= g_CurInflictor;
		new old_IsWarcraftDamage= g_CurDamageIsWarcraft;
		new Float:old_DamageModifierPercent = g_CurDMGModifierPercent;
		new old_IsTrueDamage = g_CurDamageIsTrueDamage;

		new attacker_Owns_item = 0;

		if(ValidPlayer(attacker,true))
		{
			if(!W3HasImmunity(victim,Immunity_ArmorPiercing))
			{
				new piercing_item = internal_GetItemIdByShortname("piercing");
				attacker_Owns_item = GetOwnsItem(attacker,piercing_item);
			}
			else
			{
				new piercing_item = internal_GetItemIdByShortname("piercing");
				if(GetOwnsItem(attacker,piercing_item))
				{
					War3_NotifyPlayerImmuneFromItem(attacker, victim, piercing_item);
				}
			}
		}

		//set these to global
		g_CurDamageType=damagetype;
		g_CurInflictor=inflictor;
		g_CurDMGModifierPercent=1.0;
		g_CurDamageIsWarcraft=g_NextDamageIsWarcraftDamage;
		g_CurDamageIsTrueDamage=g_NextDamageIsTrueDamage;

		damagestack++;

		
		if(g_CurDamageIsWarcraft)
		{
			if(!GetBuffHasOneTrue(victim,bArmorMagicDenyAll))
			{
				damage=(damage * MagicArmorMulti(victim, GetBuffSumFloat(attacker, fArmorPenetration)));
				damage *= 1+GetBuffSumFloat(attacker, fMagicDamageModifier);
			}
		}
		else if((attacker_Owns_item!=1)&&!g_CurDamageIsTrueDamage&&!GetBuffHasOneTrue(victim,bfArmorPhysicalDenyAll))
		{
			if(inflictor != -1 && weapon != -1){
				char weaponName[64];
				new realWeapon = weapon == -1 ? inflictor : weapon;
				GetEntityClassname(realWeapon, weaponName, sizeof(weaponName));
				//Now uses the pre-damage as the reflect. Backstabs are instead 150 damage.
				if(damagecustom == TF_CUSTOM_BACKSTAB){
					War3Source_Engine_WCX_Engine_Reflect_OnWar3EventPostHurt(victim,attacker,150.0,weaponName,view_as<bool>(g_CurDamageIsWarcraft),weapon);
				}else{
					War3Source_Engine_WCX_Engine_Reflect_OnWar3EventPostHurt(victim,attacker,damage,weaponName,view_as<bool>(g_CurDamageIsWarcraft),weapon);
				}
			}
			//bullet
			new Float:theMult=PhysicalArmorMulti(victim, GetBuffSumFloat(attacker, fArmorPenetration));
			damage=(damage * theMult);

			new Float:armorred=(1.0-PhysicalArmorMulti(victim, GetBuffSumFloat(attacker, fArmorPenetration)))*100;
			if (armorred > 0.0 && ValidPlayer(attacker) && ValidPlayer(victim) && GetClientTeam(attacker)!=GetClientTeam(victim))
			{
				if (damage > 9.0)
				{
					new random = GetRandomInt(0,3);
					if(random==0){
						War3_EmitSoundToAll(helmSound0,victim);
					}else if(random==1){
						War3_EmitSoundToAll(helmSound1,victim);
					}else if(random==2){
						War3_EmitSoundToAll(helmSound2,victim);
					}else{
						War3_EmitSoundToAll(helmSound3,victim);
					}
				}
			}
		}
		else if(HasEntProp(victim,Prop_Send,"m_hBuilder")){
			new owner = GetEntPropEnt(victim,Prop_Send,"m_hBuilder");//Damage Reductions for buildings. Does not apply if sentry is wrangled, or if building is disabled.
			if(ValidPlayer(owner,true) && (!HasEntProp(victim, Prop_Send, "m_nShieldLevel") || GetEntProp(victim, Prop_Send, "m_nShieldLevel") == 0) && !GetEntProp(victim, Prop_Send, "m_bDisabled"))
			{
				damage *= PhysicalArmorMulti(owner, GetBuffSumFloat(attacker, fArmorPenetration));
			}
		}
		if(!g_CurDamageIsWarcraft && ValidPlayer(attacker))
		{
			new Float:now=GetGameTime();

			new Float:value=now-LastDamageDealtTime[attacker];
			if(value>1.0||value<0.0){
				ChanceModifier[attacker]=1.0;
			}
			else{
				ChanceModifier[attacker]=value;
			}
			//DP("%f",ChanceModifier[attacker]);
			LastDamageDealtTime[attacker]=GetGameTime();
		}
		if(attacker!=inflictor)
		{
			if(inflictor>0 && IsValidEdict(inflictor))
			{
	new String:ent_name[64];
	GetEdictClassname(inflictor,ent_name,64);
			//	DP("ent name %s",ent_name);
#if GGAMETYPE == GGAME_TF2
	if(StrContains(ent_name,"obj_sentrygun",false)==0	&&!CvarEmpty(ChanceModifierSentry))
	{
		ChanceModifier[attacker]=GetConVarFloat(ChanceModifierSentry);
	}
	else if(StrContains(ent_name,"tf_projectile_sentryrocket",false)==0 &&!CvarEmpty(ChanceModifierSentryRocket))
	{
		ChanceModifier[attacker]=GetConVarFloat(ChanceModifierSentryRocket);
	}
#endif
			}
		}
		new bool:old_CanSetDamageMod=g_CanSetDamageMod;
		new bool:old_CanDealDamage=g_CanDealDamage;
		g_CanSetDamageMod=true;
		g_CanDealDamage=false;
		Call_StartForward(p_OnW3TakeDmgAllPre);
		Call_PushCell(victim);
		Call_PushCell(attacker);
		Call_PushFloat(damage);
		Call_Finish(dummyresult); //this will be returned to
		if(!g_CurDamageIsWarcraft && damagetype != DMG_BURN + DMG_PREVENT_PHYSICS_FORCE)
		{
			Call_StartForward(p_OnW3TakeDmgBulletPre);
			Call_PushCell(victim);
			Call_PushCell(attacker);
			Call_PushFloat(damage);
			Call_PushCell(damagecustom);
			Call_Finish(dummyresult); //this will be returned to

			dodge_internal_OnW3TakeDmgBulletPre(victim,attacker,damage);
		}
		g_CanSetDamageMod=false;
		g_CanDealDamage=true;
		if(g_CurDMGModifierPercent>0.001)
		{
			//so if damage is already canceled, no point in forwarding the second part , do we dont get: evaded but still recieve warcraft damage proc)
			Call_StartForward(p_OnW3TakeDmgAll);
			Call_PushCell(victim);
			Call_PushCell(attacker);
			Call_PushFloat(damage);
			Call_Finish(dummyresult); //this will be returned to
			if(!g_CurDamageIsWarcraft && damagetype != DMG_BURN + DMG_PREVENT_PHYSICS_FORCE)
			{
				Call_StartForward(p_OnW3TakeDmgBullet);
				Call_PushCell(victim);
				Call_PushCell(attacker);
				Call_PushFloat(damage);
				Call_Finish(dummyresult); //this will be returned to
			}
		}
		g_CanSetDamageMod=old_CanSetDamageMod;
		g_CanDealDamage=old_CanDealDamage;
		//modify final damage
		damage=damage*g_CurDMGModifierPercent; ////so we calculate the percent

		//nobobdy retrieves our global variables outside of the forward call, restore old stack vars
		g_CurDamageType= old_DamageType;
		g_CurInflictor= old_Inflictor;
		g_CurDamageIsWarcraft= old_IsWarcraftDamage;
		g_CurDMGModifierPercent = old_DamageModifierPercent;
		g_CurDamageIsTrueDamage = old_IsTrueDamage;

		damagestack--;

		#if defined DEBUG
		DP2("sdktakedamage %d->%d END dmg [%.2f]",attacker,victim,damage);
		#endif
	}

	return Plugin_Changed;
}

public Action OnTakeDamageAliveHook(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(MapChanging || War3SourcePause) return Plugin_Handled;

	// GHOSTS!!
	if (weapon == -1 && inflictor == -1)
	{
		return Plugin_Handled;
	}

	//Block uber hits (no actual damage)
#if GGAMETYPE == GGAME_TF2
	if(War3_IsUbered(victim))
	{
		return Plugin_Handled;
	}
#endif
	damagestack++;

	new bool:old_CanDealDamage=g_CanDealDamage;
	g_CanSetDamageMod=true;

	g_CurInflictor = inflictor;

	// war3source 2.0 uses this:
	//Figure out what really hit us. A weapon? A sentry gun?
	char weaponName[64];
	new realWeapon = weapon == -1 ? inflictor : weapon;
	GetEntityClassname(realWeapon, weaponName, sizeof(weaponName));

	bool isWarCraft = g_CurDamageIsWarcraft?true:false;

	if(!(damagetype == DMG_BURN + DMG_PREVENT_PHYSICS_FORCE)){
		War3Source_Engine_WCX_Engine_Bash_OnWar3EventPostHurt(victim,attacker,damage,weaponName,isWarCraft);
		War3Source_Engine_WCX_Engine_Crit_OnWar3EventPostHurt(victim,attacker,damage,weaponName,isWarCraft);
		Engine_WCX_Engine_Vampire_OnWar3EventPostHurt(victim,attacker,damage,weaponName,isWarCraft);
	}
	
	//damage += newdamage;

	Call_StartForward(p_OnWar3EventPostHurt);
	Call_PushCell(victim);
	Call_PushCell(attacker);
	Call_PushFloat(damage);

	// new war3source 2.0 uses this.. we don't
	//Call_PushFloat(damage);
	Call_PushString(weaponName);
	Call_PushCell(g_CurDamageIsWarcraft);

	Call_PushArray(damageForce,sizeof(damageForce));
	Call_PushArray(damagePosition,sizeof(damagePosition));

	Call_Finish(dummyresult);

	g_CanDealDamage=old_CanDealDamage;

	damagestack--;

	g_CurLastActualDamageDealt = RoundToFloor(damage);

	return Plugin_Changed;
}
public OnTakeDamagePostHook(victim, attacker, inflictor, Float:damage, damagetype, weapon, const Float:damageForce[3], const Float:damagePosition[3])
{
		if(MapChanging || War3SourcePause) return 0;

		// GHOSTS!!
		if (weapon == -1 && inflictor == -1)
		{
				return 0;
		}

		//Block uber hits (no actual damage)
#if GGAMETYPE == GGAME_TF2
		if(War3_IsUbered(victim))
		{
				return 0;
		}
#endif
		damagestack++;

		new bool:old_CanDealDamage=g_CanDealDamage;
		g_CanSetDamageMod=true;

		g_CurInflictor = inflictor;

		// war3source 2.0 uses this:
		//Figure out what really hit us. A weapon? A sentry gun?
		char weaponName[64];
		new realWeapon = weapon == -1 ? inflictor : weapon;
		GetEntityClassname(realWeapon, weaponName, sizeof(weaponName));

		bool isWarCraft = g_CurDamageIsWarcraft?true:false;

		if(!(damagetype == DMG_BURN + DMG_PREVENT_PHYSICS_FORCE)){
			War3Source_Engine_WCX_Engine_Bash_OnWar3EventPostHurt(victim,attacker,damage,weaponName,isWarCraft);
			War3Source_Engine_WCX_Engine_Crit_OnWar3EventPostHurt(victim,attacker,damage,weaponName,isWarCraft);
			Engine_WCX_Engine_Vampire_OnWar3EventPostHurt(victim,attacker,damage,weaponName,isWarCraft);
		}
		//damage += newdamage;

		Call_StartForward(p_OnWar3EventPostHurt);
		Call_PushCell(victim);
		Call_PushCell(attacker);
		Call_PushFloat(damage);

		// new war3source 2.0 uses this.. we don't
		//Call_PushFloat(damage);
		Call_PushString(weaponName);
		Call_PushCell(g_CurDamageIsWarcraft);

		Call_PushArray(damageForce,sizeof(damageForce));
		Call_PushArray(damagePosition,sizeof(damagePosition));

		Call_Finish(dummyresult);

		g_CanDealDamage=old_CanDealDamage;

		damagestack--;

		g_CurLastActualDamageDealt = RoundToFloor(damage);

		return 1;
}

stock DP2(const String:szMessage[], any:...)
{
	new String:szBuffer[1000];
	new String:pre[132];
	for(new i=0;i<damagestack;i++){
		StrCat(pre,sizeof(pre),"	");
	}
	VFormat(szBuffer, sizeof(szBuffer), szMessage, 2);
	PrintToServer("[DP2] %s%s %s",pre,szBuffer,W3GetDamageIsBullet()?"B":"",!g_NextDamageIsWarcraftDamage?"NB":"");
	PrintToChatAll("[DP2] %s%s %s", pre, szBuffer,W3GetDamageIsBullet()?"B":"",!g_NextDamageIsWarcraftDamage?"NB":"");
}

stock bool:DealDamage(int victim,int damage,int attacker=0,int damage_type=DMG_GENERIC,String:weaponNameStr[], War3DamageOrigin:W3DMGORIGIN=W3DMGORIGIN_UNDEFINED , War3DamageType:W3DMGTYPE=W3DMGTYPE_MAGIC , bool:respectVictimImmunity=true , bool:countAsFirstDamageRetriggered=false, bool:noWarning=false)
{
	new bool:whattoreturn=true;

	if(!g_CanDealDamage && !noWarning){
		LogError("	");
		ThrowError("War3_DealDamage called when DealDamage is not suppose to be called, please use the non PRE forward");
	}

	if(IsValidEntity(victim) && damage>0)
	{
		new old_IsWarcraftDamage= g_CurDamageIsWarcraft;
		new old_IsTrueDamage = g_CurDamageIsTrueDamage;

		new old_NextDamageIsWarcraftDamage=g_NextDamageIsWarcraftDamage;
		new old_NextDamageIsTrueDamage=g_NextDamageIsTrueDamage;

		g_CurLastActualDamageDealt=-88;

		if(ValidPlayer(victim) && respectVictimImmunity)
		{
			switch(W3DMGORIGIN)
			{
				case W3DMGORIGIN_SKILL:  
				{
					if(W3HasImmunity(victim,Immunity_Skills) )
					{
						return false;
					}
				}
				case W3DMGORIGIN_ULTIMATE:  {
					if(W3HasImmunity(victim,Immunity_Ultimates) )
					{
						return false;
					}
				}
			}
			switch(W3DMGTYPE)
			{
				case W3DMGTYPE_PHYSICAL:  
				{
					if(W3HasImmunity(victim,Immunity_PhysicalDamage) )
					{
						return false;
					}
				}
				case W3DMGTYPE_MAGIC:  
				{
					if(W3HasImmunity(victim,Immunity_MagicDamage) )
					{
						return false;
					}
				}
			}
		}

		if(countAsFirstDamageRetriggered){
			g_NextDamageIsWarcraftDamage=false;
		}
		else {
			g_NextDamageIsWarcraftDamage=true;
		}
		g_CurDamageIsWarcraft=g_NextDamageIsWarcraftDamage;
		//sdk immediately follows, we must expose this to posthurt once sdk exists

		g_NextDamageIsTrueDamage=(W3DMGTYPE==W3DMGTYPE_TRUEDMG);
		g_CurDamageIsTrueDamage=(W3DMGTYPE==W3DMGTYPE_TRUEDMG);


		#if defined DEBUG
		DP2("dealdamage %d->%d {",attacker,victim);
		damagestack++;
		#endif

		decl String:dmg_str[16];
		IntToString(damage,dmg_str,sizeof(dmg_str));
		decl String:dmg_type_str[32];
		IntToString(damage_type,dmg_type_str,sizeof(dmg_type_str));

		new pointHurt=CreateEntityByName("point_hurt");
		if(IsValidEntity(pointHurt))
		{
			DispatchKeyValue(victim,"targetname","war3_hurtme"); //set victim as the target for damage
			DispatchKeyValue(pointHurt,"Damagetarget","war3_hurtme");
			DispatchKeyValue(pointHurt,"Damage",dmg_str);
			DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
			if(!StrEqual(weaponNameStr,""))
			{
				DispatchKeyValue(pointHurt,"classname",weaponNameStr);
			}
			else{
				DispatchKeyValue(pointHurt,"classname","war3_point_hurt");
			}
			DispatchSpawn(pointHurt);
			AcceptEntityInput(pointHurt,"Hurt",(attacker>0)?attacker:-1);
			DispatchKeyValue(victim,"targetname","war3_donthurtme"); //unset the victim as target for damage
			RemoveEntity(pointHurt);
		}
		//damage has been dealt BY NOW


		if(g_CurLastActualDamageDealt==-88){
			g_CurLastActualDamageDealt=0;
			whattoreturn=false;
		}
		#if defined DEBUG
		damagestack--;
		DP2("dealdamage %d->%d }",attacker,victim);
		#endif

		g_CurDamageIsWarcraft= old_IsWarcraftDamage;

		g_CurDamageIsTrueDamage = old_IsTrueDamage;

		g_NextDamageIsWarcraftDamage=old_NextDamageIsWarcraftDamage;
		g_NextDamageIsTrueDamage=old_NextDamageIsTrueDamage;
	}
	else{
		//player is already dead
		whattoreturn=false;
		g_CurLastActualDamageDealt=0;
	}

	return whattoreturn;
}

public Native_War3_DealDamage(Handle:plugin,numParams)
{
	new bool:noWarning = false;
	if (numParams >= 10)
		noWarning = bool:GetNativeCell(10);

	decl String:weapon[64];
	GetNativeString(5,weapon,64);

	return DealDamage(GetNativeCell(1), //victim
	GetNativeCell(2), //damage
	GetNativeCell(3), //attacker
	GetNativeCell(4), //damage_type
	weapon, //weaponNameStr
	War3DamageOrigin:GetNativeCell(6) , //War3DamageOrigin
	War3DamageType:GetNativeCell(7) , //War3DamageType
	bool:GetNativeCell(8) , //respectVictimImmunity
	bool:GetNativeCell(9), //countAsFirstDamageRetriggered
	noWarning); //noWarning
}

public Native_War3_GetWar3DamageDealt(Handle:plugin,numParams) {
	return g_CurLastActualDamageDealt;
}
