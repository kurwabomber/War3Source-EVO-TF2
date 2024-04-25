#include <war3source>
#assert GGAMEMODE == MODE_WAR3SOURCE

#define RACE_ID_NUMBER 13

/**
* vim: set ai et ts=4 sw=4 :
* File: War3Source_SuccubusHunter.sp
* Description: The Succubus Hunter race for SourceCraft.
* Author(s): DisturbeD
* Adapted to TF2 by: -=|JFH|=-Naris (Murray Wilson)
* Offcially ported to War3Source by Ownz (DarkEnergy)
*/

//#pragma semicolon 1
//#include <sourcemod>
//#include <sdktools_tempents>
//#include <sdktools_functions>
//#include <sdktools_tempents_stocks>
//#include <sdktools_entinput>
//#include <sdktools_sound>

//#include "W3SIncs/War3Source_Interface"
public W3ONLY(){} //unload this?

new thisRaceID, SKILL_HEADHUNTER, SKILL_TOTEM, SKILL_ASSAULT, ULT_TRANSFORM;
#if (GGAMETYPE == GGAME_CSS || GGAMETYPE == GGAME_CSGO)
//new m_iAccount = -1, m_vecVelocity_1, m_vecBaseVelocity; //offsets
new m_vecVelocity_1, m_vecBaseVelocity; //offsets
#endif
new m_vecVelocity_0;


//new bool:hurt_flag = true;
new bool:m_IsULT_TRANSFORMformed[MAXPLAYERSCUSTOM];
new skulls[MAXPLAYERSCUSTOM];
//Effects
//new BeamSprite;
new Laser;

new bool:lastframewasground[MAXPLAYERSCUSTOM];
new Handle:ultCooldownCvar;
//Headhunter
new HeadCap[] = {20,20,20,20,20};
new Float:HeadDMG[] = {1.0,1.125,1.25,1.375,1.5};
//Assault Tackle
new Float:assaultcooldown[]={7.0,6.6,6.0,5.6,5.0};
new Float:assaultMoveMult[]={1.0,1.1,1.2,1.3,1.4};
//Demonic Transformation
new TransformHealth[]={60,65,70,75,80};
new Float:TransformAttackspeed[]={0.25,0.275,0.285,0.3,0.325};
new Float:TransformSpeed[]={0.35,0.38,0.4,0.43,0.45};

public Plugin:myinfo =
{
	name = "Race - Succubus Hunter",
	author = "DisturbeD",
	description = "",
	version = "2.0.6",
	url = "http://war3source.com/"
};

bool HooksLoaded = false;
public void Load_Hooks()
{
	if(HooksLoaded) return;
	HooksLoaded = true;

	W3Hook(W3Hook_OnW3TakeDmgBullet, OnW3TakeDmgBullet);
	W3Hook(W3Hook_OnUltimateCommand, OnUltimateCommand);
	W3Hook(W3Hook_OnWar3EventSpawn, OnWar3EventSpawn);
}
public void UnLoad_Hooks()
{
	if(!HooksLoaded) return;
	HooksLoaded = false;

	W3Unhook(W3Hook_OnW3TakeDmgBullet, OnW3TakeDmgBullet);
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

public OnMapStart()
{
	UnLoad_Hooks();

	//PrecacheSound("npc/fast_zombie/claw_strike1.wav");
	//BeamSprite=PrecacheModel("materials/sprites/purpleglow1.vmt");
	Laser=PrecacheModel("materials/sprites/laserbeam.vmt");
}
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
public OnWar3LoadRaceOrItemOrdered2(num,reloadrace_id,String:shortname[])
{
	if(num==RACE_ID_NUMBER||(reloadrace_id>0&&StrEqual("succubus",shortname,false)))
	{
		thisRaceID=War3_CreateNewRace("Succubus Hunter","succubus",reloadrace_id,"Killstreak & mobility");

		SKILL_HEADHUNTER = War3_AddRaceSkill(thisRaceID, "Head Hunter","Deal extra +1-1.5% dmg per skull. Max skulls is 20.\nYou gain your victim's skulls on kill", false, 4);
		SKILL_TOTEM = War3_AddRaceSkill(thisRaceID, "Totem Incantation","You gain 3-4 HP, 3-4 gold and 5-8XP on spawn for each skull you collected. You lose 10 skulls on spawn.", false, 4);
		SKILL_ASSAULT = War3_AddRaceSkill(thisRaceID, "Assault Tackle","Gives you a boost of speed when you jump.", false, 4);
		ULT_TRANSFORM = War3_AddRaceSkill(thisRaceID, "Demonic Transformation","Buffs yourself with increased health, speed & attackspeed. Costs 4 skulls\nGives +60 - 80HP, +25% - +32.5% attack speed, and +35% - +45% speed.", true, 4);
		War3_CreateRaceEnd(thisRaceID);

	}
}

public OnPluginStart()
{
	//m_vecVelocity_0 = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
	m_vecVelocity_0 = FindSendPropInfo("CBasePlayer","m_vecVelocity[0]");

	//HookEvent("player_hurt",PlayerHurtEvent);
	//HookEvent("player_death",PlayerDeathEvent);

	AddCommandListener(SayCommand, "say");
	AddCommandListener(SayCommand, "say_team");
#if (GGAMETYPE == GGAME_CSS || GGAMETYPE == GGAME_CSGO)
	HookEvent("player_jump",PlayerJumpEvent);
	//m_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	m_vecVelocity_1 = FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
	m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
#endif

	ultCooldownCvar=CreateConVar("war3_succ_ult_cooldown","20","Cooldown for succubus ultimate");

	//LoadTranslations("w3s.race.succubus.phrases");
}

public OnAllPluginsLoaded()
{
	War3_RaceOnPluginStart("succubus");
}
public OnPluginEnd()
{
	if(LibraryExists("RaceClass"))
		War3_RaceOnPluginEnd("succubus");
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace==thisRaceID)
	{
		InitPassiveSkills(client);
	}
	else // if(oldrace==thisRaceID)
	{
		RemovePassiveSkills(client);
	}
}

public InitPassiveSkills(client)
{
	// Natural Armor Buff
	//War3_SetBuff(client,fArmorPhysical,thisRaceID,3.0);
}

public RemovePassiveSkills(client)
{
	//War3_SetBuff(client,fArmorPhysical,thisRaceID,0.0);
	War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,0);
}


public void OnWar3EventSpawn (int client)
{
	if(RaceDisabled)
		return;

	new race=War3_GetRace(client);
	if (race==thisRaceID)
	{
		m_IsULT_TRANSFORMformed[client]=false;
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
		//War3_SetBuff(client,fLowGravitySkill,thisRaceID,1.0);



		new skillleveltotem=War3_GetSkillLevel(client,race,SKILL_TOTEM);
		//new maxhp = War3_GetMaxHP(client);
		new hp, dollar, xp;
		switch(skillleveltotem)
		{
			case 0:
			{
				//hp=RoundToNearest(float(maxhp) * 0.02);
				hp=3;
				dollar=55;
				xp=5;
			}
			case 1:
			{
				//hp=RoundToNearest(float(maxhp) * 0.02);
				hp=3;
				dollar=55;
				xp=5;
			}
			case 2:
			{
				//hp=RoundToNearest(float(maxhp) * 0.02);
				hp=3;
				dollar=60;
				xp=6;
			}
			case 3:
			{
				//hp=RoundToNearest(float(maxhp) * 0.02);
				hp=4;
				dollar=60;
				xp=7;
			}
			case 4:
			{
				//hp=RoundToNearest(float(maxhp) * 0.02);
				hp=4;
				dollar=65;
				xp=8;
			}
		}

		hp *= skulls[client];
		dollar *= skulls[client];
		xp *= skulls[client];

//#if GGAMETYPE == GGAME_CSS
//		new old_health=GetClientHealth(client);
	//	SetEntityHealth(client,old_health+hp);
//#endif
// SetBuf for TF2 only?
//#elseif
		War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,hp);
//#endif

		new old_XP = War3_GetXP(client,thisRaceID);
		new kill_XP = W3GetKillXP(client);
		if (xp > kill_XP)
			xp = kill_XP;

		if(W3GetPlayerProp(client,W3PlayerProp::bStatefulSpawn)){
			War3_SetXP(client,thisRaceID,old_XP+xp);
			new max=W3GetMaxGold(client);

			new old_credits=War3_GetGold(client);
			//PrintToChat(client,"dollar %d",dollar);
			// orignal war3source was 100 gold max.. so.. 100/6 = 17 rounded up
			dollar /= 16; // was dollar /= (max/6);
			//PrintToChat(client,"dollar %d",dollar);
			new new_credits = old_credits + dollar;
			if (new_credits > max)
			new_credits = max;
			//PrintToChat(client,"new_credits %d",new_credits);
			War3_SetGold(client,new_credits);
			new_credits = War3_GetGold(client);

			if (new_credits > 0){
				dollar = new_credits-old_credits;
			}
			if(W3GetPlayerProp(client,W3PlayerProp::bStatefulSpawn)){
				PrintToChat(client,"\0x04[Totem Incanation] \0x01You gained %i HP, %i credits and %i XP",hp,dollar,xp);
			}
		}
		skulls[client]=skulls[client]-10;
		if(skulls[client]<0)
			skulls[client]=0;
	}
}
public Action OnW3TakeDmgBullet(int victim,int attacker, float damage)
{
	if(RaceDisabled)
		return Plugin_Continue;

	if(ValidPlayer(attacker,true) && ValidPlayer(victim,true))
	{
		if(GetClientTeam(victim)==GetClientTeam(attacker) || W3HasImmunity(victim,Immunity_Skills))
			return Plugin_Continue;
	}
	
	if(IsValidEntity(victim)&&ValidPlayer(attacker,false)&&War3_GetRace(attacker) == thisRaceID)
	{
		//DP("bullet succ vic alive %d",ValidPlayer(victim,true));
		new skilllevelheadhunter = War3_GetSkillLevel(attacker,thisRaceID,SKILL_HEADHUNTER);
		if (!Hexed(attacker))
		{
			//DP("health %d",GetClientHealth(victim));
			//new xdamage= RoundFloat(0.2*float(damage) * skulls[attacker]/20 );
			
			new xdamage= RoundFloat(damage * 0.01 * HeadDMG[skilllevelheadhunter] * skulls[attacker] * W3GetBuffStackedFloat(victim, fAbilityResistance));
			War3_DealDamage(victim,xdamage,attacker,_,"headhunter",W3DMGORIGIN_SKILL,W3DMGTYPE_PHYSICAL);

			//W3PrintSkillDmgConsole(victim,attacker,War3_GetWar3DamageDealt(),SKILL_HEADHUNTER);
			if(xdamage>0)
			{
				War3_NotifyPlayerTookDamageFromSkill(victim, attacker, xdamage, SKILL_HEADHUNTER);
			}
			//DP("deal %d",xdamage);
		}
	}
	return Plugin_Changed;
}
public OnWar3EventDeath(victim,attacker){
	if(RaceDisabled)
		return;

	if(War3_GetRace(attacker) != thisRaceID)
		return;

	new skilllevelheadhunter=War3_GetSkillLevel(attacker,thisRaceID,SKILL_HEADHUNTER);
	if (!Hexed(attacker)&&victim!=attacker)
	{
		if (skulls[attacker]<HeadCap[skilllevelheadhunter])
		{
			skulls[attacker]++;
			War3_ChatMessage(attacker,"You gained a SKULL [%i/%i]",skulls[attacker],HeadCap[skilllevelheadhunter]);
		}
	}
}
public PlayerJumpEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(RaceDisabled)
		return;

	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	new race=War3_GetRace(client);
	if (race==thisRaceID)
	{
		new skill_SKILL_ASSAULT=War3_GetSkillLevel(client,race,SKILL_ASSAULT);
		//assaultskip[client]--;
		//if(assaultskip[client]<1||
		if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_ASSAULT)&&!Hexed(client))
		{
			//assaultskip[client]+=2;
			new Float:velocity[3]={0.0,0.0,0.0};
			velocity[0]= GetEntDataFloat(client,m_vecVelocity_0);
			velocity[0]*=assaultMoveMult[skill_SKILL_ASSAULT];
#if (GGAMETYPE == GGAME_CSS || GGAMETYPE == GGAME_CSGO)
			velocity[1]= GetEntDataFloat(client,m_vecVelocity_1);
			velocity[1]*=assaultMoveMult[skill_SKILL_ASSAULT];
#endif

			//new Float:len=GetVectorLength(velocity,false);
			//if(len>100.0){
			//	velocity[0]*=100.0/len;
			//	velocity[1]*=100.0/len;
			//}
			//PrintToChatAll("speed vector length %f cd %d",len,War3_SkillNotInCooldown(client,thisRaceID,SKILL_ASSAULT)?0:1);
			/*len=GetVectorLength(velocity,false);
			PrintToChatAll("speed vector length %f",len);
			*/
#if (GGAMETYPE == GGAME_CSS || GGAMETYPE == GGAME_CSGO)
			SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
#endif
			War3_CooldownMGR(client,assaultcooldown[skill_SKILL_ASSAULT],thisRaceID,SKILL_ASSAULT,_,_);

			new String:wpnstr[32];
			GetClientWeapon(client, wpnstr, 32);
			for(new slot=0;slot<10;slot++){

				new wpn=GetPlayerWeaponSlot(client, slot);
				if(wpn>0){
					//PrintToChatAll("wpn %d",wpn);
					new String:comparestr[32];
					GetEdictClassname(wpn, comparestr, 32);
					//PrintToChatAll("%s %s",wpn, comparestr);
					if(StrEqual(wpnstr,comparestr,false)){

						TE_SetupKillPlayerAttachments(wpn);
						TE_SendToAll();

						new color[4]={0,25,255,200};
						if(GetClientTeam(client)==TEAM_T||GetClientTeam(client)==TEAM_RED){
							color[0]=255;
							color[2]=0;
						}
						TE_SetupBeamFollow(wpn,Laser,0,0.5,2.0,7.0,1,color);
						TE_SendToAll();
						break;
					}
				}
			}
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(RaceDisabled)
		return Plugin_Continue;

	if(W3Paused()) return Plugin_Continue;

	if (buttons & IN_JUMP) //assault for non CS games
	{
		if (War3_GetRace(client) == thisRaceID)
		{
			new skill_SKILL_ASSAULT=War3_GetSkillLevel(client,thisRaceID,SKILL_ASSAULT);
			//assaultskip[client]--;
			//if(assaultskip[client]<1&&
			new bool:lastwasgroundtemp=lastframewasground[client];
			lastframewasground[client]=bool:(GetEntityFlags(client) & FL_ONGROUND);
			if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_ASSAULT) &&  lastwasgroundtemp &&   !(GetEntityFlags(client) & FL_ONGROUND) &&!Hexed(client) )
			{
				//assaultskip[client]+=2;

#if GGAMETYPE == GGAME_TF2
				if (TF2_HasTheFlag(client))
					return Plugin_Continue;
#endif


				decl Float:velocity[3];
				GetEntDataVector(client, m_vecVelocity_0, velocity); //gets all 3

				/*if he is not in speed ult
				if (!(GetEntityFlags(client) & FL_ONGROUND))
				{
					new Float:absvel = velocity[0];
					if (absvel < 0.0)
						absvel *= -1.0;

					if (velocity[1] < 0.0)
						absvel -= velocity[1];
					else
						absvel += velocity[1];

					new Float:maxvel = m_IsULT_TRANSFORMformed[client] ? 1000.0 : 500.0;
					if (absvel > maxvel)
						return Plugin_Continue;
				}*/


				new Float:oldz=velocity[2];
				velocity[2]=0.0; //zero z
				new Float:len=GetVectorLength(velocity);
				if(len>3.0){
					new Float:amt = 1.2 + (assaultMoveMult[skill_SKILL_ASSAULT]);
					velocity[0]*=amt;
					velocity[1]*=amt;
					//ScaleVector(velocity,700.0/len);
					velocity[2]=oldz;
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
					//SetEntDataVector(client,m_vecBaseVelocity,velocity,true); //CS
				}





				//new Float:amt = 1.0 + (float(skill_SKILL_ASSAULT)*0.2);
				//velocity[0]*=amt;
				//velocity[1]*=amt;
				//TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);

				War3_CooldownMGR(client,assaultcooldown[skill_SKILL_ASSAULT],thisRaceID,SKILL_ASSAULT,_,_);
				//new color[4] = {255,127,0,255};

#if GGAMETYPE == GGAME_TF2
				if (!War3_IsCloaked(client))
				{
#endif
					new String:wpnstr[32];
					GetClientWeapon(client, wpnstr, 32);
					for(new slot=0;slot<10;slot++){

						new wpn=GetPlayerWeaponSlot(client, slot);
						if(wpn>0){
							//PrintToChatAll("wpn %d",wpn);
							new String:comparestr[32];
							GetEdictClassname(wpn, comparestr, 32);
							//PrintToChatAll("%s %s",wpn, comparestr);
							if(StrEqual(wpnstr,comparestr,false)){

								TE_SetupKillPlayerAttachments(wpn);
								TE_SendToAll();

								new color[4]={0,25,255,200};
								if(GetClientTeam(client)==TEAM_T||GetClientTeam(client)==TEAM_RED){
									color[0]=255;
									color[2]=0;
								}
								TE_SetupBeamFollow(wpn,Laser,0,0.5,2.0,7.0,1,color);
								TE_SendToAll();
								break;
							}
						}
					}
#if GGAMETYPE == GGAME_TF2
				}
#endif
			}
		}
	}
	return Plugin_Continue;
}

public OnClientPutInServer(client)
{
	skulls[client] = 0;
	m_IsULT_TRANSFORMformed[client]=false;

	War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
	//War3_SetBuff(client,fLowGravitySkill,thisRaceID,1.0);
}


public void OnUltimateCommand(int client, int race, bool pressed, bool bypass)
{
	if(ValidPlayer(client,true)&&pressed && race==thisRaceID)
	{
		new skill_trans=War3_GetSkillLevel(client,race,ULT_TRANSFORM);
		if (War3_SkillNotInCooldown(client,thisRaceID,ULT_TRANSFORM,true)&&!Silenced(client))
		{
			if (skulls[client] < 4)
			{
				new required = 4 - skulls[client];
				PrintToChat(client,"\0x04[Daemonic transformation] \0x01You do not have enough skulls: %i more required",required);
			}
			else
			{
				skulls[client]-=4;

				m_IsULT_TRANSFORMformed[client]=true;
				War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,TransformHealth[skill_trans]);
				War3_SetBuff(client,fMaxSpeed,thisRaceID,TransformSpeed[skill_trans]+1.00);
				War3_SetBuff(client,fAttackSpeed,thisRaceID,TransformAttackspeed[skill_trans]+1.00);
				//War3_SetBuff(client,fLowGravitySkill,thisRaceID,1.00-float(skill_trans)/5.00);

				new old_health=GetClientHealth(client);
				SetEntityHealth(client,old_health+TransformHealth[skill_trans]);

				PrintToChat(client,"\0x04[Daemonic transformation] \0x01Your demonic powers boost your strength");
				CreateTimer(10.0,Finishtrans,client);
				War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_TRANSFORM,_,_);
			}
		}
	}
}

public Action:Finishtrans(Handle:timer,any:client)
{

	if(m_IsULT_TRANSFORMformed[client]){
		War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,0);
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
		War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
		//War3_SetBuff(client,fLowGravitySkill,thisRaceID,1.0);
		if(ValidPlayer(client,true)){
			PrintToChat(client,"\0x04[Daemonic transformation] \0x01You transformed back to normal");
		}
	}
}

/**
* Detect when changing classes in TF2
*/




public Action:SayCommand(client, const String:command[], argc)
{
	if(RaceDisabled)
		return Plugin_Continue;

	if (client > 0 && IsClientInGame(client))
	{
		decl String:text[128];
		GetCmdArg(1,text,sizeof(text));

		decl String:arg[2][64];
		ExplodeString(text, " ", arg, 2, 64);

		new String:firstChar[] = " ";
		firstChar[0] = arg[0][0];
		if (StrContains("!/\\",firstChar) >= 0)
			strcopy(arg[0], sizeof(arg[]), arg[0][1]);

		if (StrEqual(arg[0],"skulls",false))
		{
			new skilllevelheadhunter = (War3_GetRace(client)==thisRaceID) ? War3_GetSkillLevel(client,thisRaceID,SKILL_HEADHUNTER) : 0;
			if (skilllevelheadhunter)
				War3_ChatMessage(client,"You have (%i/%i) SKULLs",skulls[client],HeadCap[skilllevelheadhunter]);
			else
			War3_ChatMessage(client,"You have %i \0x04SKULL\0x01s",skulls[client]);

			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

/**
* Weapons related functions.
*/

stock bool:GetWeapon(Handle:event, index,
String:buffer[], buffersize)
{
	new bool:is_equipment;

	buffer[0] = 0;
	GetEventString(event, "weapon", buffer, buffersize);

	if (buffer[0] == '\0' && index && IsPlayerAlive(index))
	{
		is_equipment = true;
		GetClientWeapon(index, buffer, buffersize);
	}
	else
	is_equipment = false;

	return is_equipment;
}

stock bool:IsEquipmentMelee(const String:weapon[])
{
	return (StrEqual(weapon,"tf_weapon_knife") ||
	StrEqual(weapon,"tf_weapon_shovel") ||
	StrEqual(weapon,"tf_weapon_wrench") ||
	StrEqual(weapon,"tf_weapon_bat") ||
	StrEqual(weapon,"tf_weapon_bat_wood") ||
	StrEqual(weapon,"tf_weapon_bonesaw") ||
	StrEqual(weapon,"tf_weapon_bottle") ||
	StrEqual(weapon,"tf_weapon_club") ||
	StrEqual(weapon,"tf_weapon_fireaxe") ||
	StrEqual(weapon,"tf_weapon_fists") ||
	StrEqual(weapon,"tf_weapon_sword"));
}


stock bool:IsMelee(const String:weapon[], bool:is_equipment, index, victim, Float:range=100.0)
{
	if (is_equipment)
	{
		if (IsEquipmentMelee(weapon))
			return IsInRange(index,victim,range);
		else
		return false;
	}
	else
	return W3IsDamageFromMelee(weapon);
}

/**
* Range and Distance functions and variables
*/

stock Float:TargetRange(client,index)
{
	new Float:start[3];
	new Float:end[3];
	GetClientAbsOrigin(client,start);
	GetClientAbsOrigin(index,end);
	return GetVectorDistance(start,end);
}

stock bool:IsInRange(client,index,Float:maxdistance)
{
	return (TargetRange(client,index)<maxdistance);
}