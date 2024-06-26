//War3Source_Damage.inc


//=============================================================================
// Damage
//=============================================================================

// The following are bit-flags for War3_DealDamage
// Does not appear useful in any way
#define DMG_TIMEBASED				(DMG_PARALYZE | DMG_NERVEGAS | DMG_POISON | DMG_RADIATION | DMG_DROWNRECOVER | DMG_ACID | DMG_SLOWBURN)

//=============================================================================
// Deal Damage
//=============================================================================

/**
 * Deal damage.
 * @param victim: Victim's client index.
 * @param damage: Damage to be dealt.
 * @param attacker: Optional, attacker client index. Pass 0 for none.
 * @param damage_type: Optional, damage bit-flags. See above for DMG_* defines.
 * @param weaponstr: Optional, weapon name for simulated damage.
 * @param W3DMGOrigin: where the damage came from IE SKILL or ULTIMATE or ITEM
 * @param WAR3_DMGTYPE: is this damage true (no armor) physical (physical armor/immunity)  or magic (magic armor/immunity)
 * @param respectVictimImmunity: should damage be blocked if victim has that type of immunity, accouts for ORIGIN immunity and DMG type. (SKILL, ULTIMATE, ITEM, |||| MAGIC AND PHYSICAL ) simplifies so that u dont have to check
 * @param countAsFirstDamageRetriggered: should this damage allow to be rehooked (creating a real hurt-event again)? this may cause infinite loops!  Yes to combime with items and other skills only if its not in a damage hook itself. (infinite loop triggering)
 * @param noWarning: Prevent warning print when using DealDamage from a event where it's error prone
 * @return bool: did damage go through, false if player was immune to that damage type or damage was zero or something else failed
 */
native bool:War3_DealDamage(victim,damage,attacker=0,damage_type=DMG_GENERIC,String:weaponNameStr[], War3DamageOrigin:W3DMGORIGIN=W3DMGORIGIN_UNDEFINED , War3DamageType:W3DMGTYPE=W3DMGTYPE_MAGIC , bool:respectVictimImmunity=true , bool:countAsFirstDamageRetriggered=false, bool:noWarning=false);

//=============================================================================
// Get Damage Details
//=============================================================================

//get the actual damage dealt from War3_DealDamage, because real damage is different after taking account to magic/physical armor
//u wana call this immediately after War3_DealDamage cuz this is a single global variable. when someone else calls War3_DealDamage it will be changed
native War3_GetWar3DamageDealt();

///is last damage a bullet first triggered damage? works on posthurt and sdkhookdmgall
//is the damange number right now, was it trigered by bullet type attack, or a warcraft type attack
native W3GetDamageIsBullet();

native W3ForceDamageIsBullet();
// if u do damage within a takedmg, the original damage may be nullified as non bullet,
//use this function after you have dealt damage inside a takedmg
//so you can allow other isdmgbullet proc

//get the depth of the damage stack, usually 1 or more
native W3GetDamageStack();

/*
 * forces the damage to be multiplied by @num
 * shall only be done inside SDKHOOKS damage forward (when damage hasnt been dealt yet)
 * @noreturn
 */
native War3_DamageModPercent(Float:num);

//return the game damagetype (burn, laser, etc) of the last damage (TakeDmg forward)
native W3GetDamageType();
//get inflictor of the last damage (TakeDmg forward) (ie sentry gun  is a different object than the attacker itself)
native W3GetDamageInflictor();

#if GGAMETYPE == GGAME_TF2
//=============================================================================
// Is client Sentry Owner?
//=============================================================================

/**
 * Basically checks to see if this is a Owner's sentry.
 *
 * best use inside OnW3TakeDmgBullet or OnW3TakeDmgBullet or SDKHooks calls that have inflictors
 * where you can use this code:
 *  new inflictor = W3GetDamageInflictor();
 *  then pass the inflictor as the entity below:
 *
 * @param client: client you wish to check as the owner
 * @param UseInternalInflictor: true if you wish the native to grab the W3GetDamageInflictor for you.
 *         ^ only use if you are using inside a OnW3TakeDamage function type, else use your own
 *         (Default true)
 * @param ExternalInflictor: entity you wish to check that maybe a sentry / optional
 *        Make sure you put UseInternalInflictor as false.
 *
 * @param return: true if the client is the sentry owner and the entity is the owned sentry
 *
 */
native bool:W3IsOwnerSentry(client,bool:UseInternalInflictor=true,ExternalInflictor=0);
#endif

//=============================================================================
// Chance Modifier
//=============================================================================

//helper, directly uses last inflictor and damagetype
// Acts like a DPS limiter
native Float:W3ChanceModifier(attacker);


//=============================================================================
// Fowards
//=============================================================================

/**
 * Called when a an entity takes damage, requires SDK Hooks until SM natively supports this.
 * @param victim: Victim entity.
 * @param attacker: Attacker entity.
 * @param damage: How much damage is done.
 * @noreturn
 *
 * order of execution is
 * damageallpre
 * bulletpre (if bullet)
 * damageall
 * bullet  (if bullet)
 */
//FF triggers this function!!! even though it didnt damage any teammate
//THIS is a theoretical damage given by the engine, if u want real damage dealt use the hurt-event
//use natives to retrieve inflictor and game damagetype
//becareful when using this, u should only use this to reduce incoming damage. if you want to return damge, only use on bullet (first trigger damage)(below) or check IsBullet
//you may set damage mod percent HERE
//you may NOT DAMAGE IN HERE
//forward OnW3TakeDmgAllPre (int victim, int attacker,float damage);
//bullet only
//forward OnW3TakeDmgBulletPre(victim,attacker,Float:damage,damagecustom);

//you may NOT set damage mod percent HERE
//you may DAMAGE in here, however damage will be engine theoretical damage, not actual damage dealt
//forward OnW3TakeDmgAll(victim,attacker,Float:damage);
// BULLET GAME DAMAGE ONLY or Warcraft damage that is allowed to be retriggered (allow more item and skill modifiers), (FILTERED)
//you may NOT set damage mod percent HERE
//you may DAMAGE in here
//forward OnW3TakeDmgBullet(victim,attacker,Float:damage);

//when a weapon fires, via weapon_fire or TF2 Calc critical (which crits must be on)
forward OnWeaponFired(victim,attacker,Float:damage);

//=============================================================================
// Stocks
//=============================================================================
native bool War3_IsUsingMeleeWeapon(client);

stock bool:W3IsDamageFromMelee(const String:weapon[])
{
	return (// Logfile names
			StrEqual(weapon, "shovel") ||
			StrEqual(weapon, "wrench") ||
			StrEqual(weapon, "bat") ||
			StrEqual(weapon, "bonesaw") ||
			StrEqual(weapon, "bottle") ||
			StrEqual(weapon, "club") ||
			StrEqual(weapon, "fireaxe") ||
			StrEqual(weapon, "fists") ||
			StrEqual(weapon, "sandman") ||
			StrEqual(weapon, "pickaxe") ||
			StrEqual(weapon, "sword") ||
			StrEqual(weapon, "demoshield") ||
			StrEqual(weapon, "taunt_scout") ||
			StrEqual(weapon, "taunt_sniper") ||
			StrEqual(weapon, "taunt_pyro") ||
			StrEqual(weapon, "taunt_demoman") ||
			StrEqual(weapon, "taunt_heavy") ||
			StrEqual(weapon, "taunt_spy") ||
			StrEqual(weapon, "taunt_soldier")||
			StrEqual(weapon, "annihilator") ||
			StrEqual(weapon, "ubersaw") ||
			StrEqual(weapon, "axtinguisher") ||
			StrEqual(weapon, "gloves") ||
			StrEqual(weapon, "sandman") ||
			StrEqual(weapon, "unique_pickaxe") ||
			StrEqual(weapon, "robot_arm") ||
			StrEqual(weapon, "sledgehammer") ||
			StrEqual(weapon, "paintrain") ||
			StrEqual(weapon, "southern_hospitality") ||
			StrEqual(weapon, "wrench_golden") ||
			StrEqual(weapon, "tribalkukri") ||
			StrEqual(weapon, "battleaxe") ||
			StrEqual(weapon, "battleneedle") ||
			StrEqual(weapon, "powerjack") ||
			StrEqual(weapon, "holy_mackerel") ||
			StrEqual(weapon, "eternal_reward") ||
			StrEqual(weapon, "bushwacka") ||
			StrEqual(weapon, "gloves_running_urgently") ||
			StrEqual(weapon, "fryingpan") ||
			StrEqual(weapon, "headtaker") ||
			StrEqual(weapon, "ullapool_caber") ||
			StrEqual(weapon, "warrior_spirit") ||
			StrEqual(weapon, "candy_cane") ||
			StrEqual(weapon, "boston_basher") ||
			StrEqual(weapon, "back_scratcher") ||
			StrEqual(weapon, "claidheamohmor") ||
			StrEqual(weapon, "wrench_jag") ||
			StrEqual(weapon, "steel_fists") ||
			StrEqual(weapon, "lava_axe") ||
			StrEqual(weapon, "lava_bat") ||
			StrEqual(weapon, "warfan") ||
			StrEqual(weapon, "kunai") ||
			StrEqual(weapon, "demokatana") ||
			StrEqual(weapon, "shahanshah") ||
			StrEqual(weapon, "persian_persuader") ||
			StrEqual(weapon, "solemn_vow") ||
			StrEqual(weapon, "market_gardener") ||
			StrEqual(weapon, "saxxy") ||
			StrEqual(weapon, "eviction_notice") ||
			StrEqual(weapon, "disciplinary_action") ||
			StrEqual(weapon, "atomizer") ||
			StrEqual(weapon, "scout_sword") ||
			StrEqual(weapon, "mailbox") ||
			StrEqual(weapon, "big_earner") ||
			StrEqual(weapon, "the_maul") ||
			StrEqual(weapon, "nonnonviolent_protest") ||
			StrEqual(weapon, "nessieclub") ||
			StrEqual(weapon, "unarmed_combat") ||
			StrEqual(weapon, "voodoo_pin") ||
			StrEqual(weapon, "apocofists") ||
			StrEqual(weapon, "eureka_effect") ||
			StrEqual(weapon, "thirddegree") ||
			StrEqual(weapon, "scotland_shard") ||
			StrEqual(weapon, "sharp_dresser") ||
			StrEqual(weapon, "wrap_assassin") ||
			StrEqual(weapon, "spy_cicle") ||
			StrEqual(weapon, "holiday_punch") ||
			StrEqual(weapon, "black_rose") ||
			StrEqual(weapon, "lollichop") ||
			StrEqual(weapon, "unique_pickaxe_escape") ||
			StrEqual(weapon, "freedom_staff") ||
			// Weapon names
			StrEqual(weapon, "tf_weapon_bat") ||
			StrEqual(weapon, "tf_weapon_bat_wood") ||
			StrEqual(weapon, "tf_weapon_bat_fish") ||
			StrEqual(weapon, "tf_weapon_shovel") ||
			StrEqual(weapon, "saxxy") ||
			StrEqual(weapon, "tf_weapon_bat_giftwrap") ||
			StrEqual(weapon, "tf_weapon_fireaxe") ||
			StrEqual(weapon, "tf_weapon_sword") ||
			StrEqual(weapon, "tf_weapon_bottle") ||
			StrEqual(weapon, "tf_weapon_stickbomb") ||
			StrEqual(weapon, "tf_weapon_katana") ||
			StrEqual(weapon, "tf_weapon_fists") ||
			StrEqual(weapon, "tf_weapon_wrench") ||
			StrEqual(weapon, "tf_weapon_robot_arm") ||
			StrEqual(weapon, "tf_weapon_bonesaw") ||
			StrEqual(weapon, "tf_weapon_club") ||
			StrEqual(weapon, "tf_weapon_knife")
			);
	//return false;
}



// In csgo killing 2 players in the same frame causes a crash so we use this dirty workaround
public Action:_war3source_Timer_DealDamage(Handle:timer, Handle:pack)
{
	ResetPack(pack); //resolve the package...
	new victim = ReadPackCell(pack);
	if(!ValidPlayer(victim,true)) {
		// immedialety exit!
		return Plugin_Stop;
	}
	new attacker = ReadPackCell(pack);
	new damage = ReadPackCell(pack);
	new bool:showDamage = bool:ReadPackCell(pack);
	new showDamage_skill = ReadPackCell(pack);
	decl String:classname[32];
	ReadPackString(pack,classname,sizeof(classname));
	if(War3_DealDamage(victim,damage,attacker,DMG_BULLET,classname) && showDamage) {
		W3PrintSkillDmgConsole(victim,attacker,War3_GetWar3DamageDealt(),showDamage_skill);
	}
	return Plugin_Stop;
}

stock War3_DealDamageDelayed(victim,attacker,damage,String:classname[32],Float:delay=0.0,bool:showDamage=false,showDamage_skill=0) {
	new Handle:pack;
	CreateDataTimer(delay, _war3source_Timer_DealDamage, pack);
	WritePackCell(pack, victim);
	WritePackCell(pack, attacker);
	WritePackCell(pack, damage);
	WritePackCell(pack, showDamage);
	WritePackCell(pack, showDamage_skill);
	WritePackString(pack, classname);
}
