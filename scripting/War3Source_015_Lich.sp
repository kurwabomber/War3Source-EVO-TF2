#include <war3source>

#define RACE_ID_NUMBER 15

/**
 * File: War3Source_Lich.sp
 * Description: The Lich race for War3Source.
 * Author(s): [Oddity]TeacherCreature
 */

//#pragma semicolon 1

//#include <sourcemod>
//#include "W3SIncs/War3Source_Interface"
//#include <sdktools>
//#include <sdktools_functions>
//#include <sdktools_tempents>
//#include <sdktools_tempents_stocks>

new thisRaceID;

new SKILL_FROSTNOVA,SKILL_FROSTARMOR,SKILL_DARKRITUAL,ULT_DEATHDECAY;

int AuraID;

//skill 1
new Float:FrostNovaArr[]={0.7,0.675, 0.65, 0.625, 0.6};
new Float:FrostNovaRadius=550.0;
new FrostNovaLoopCountdown[MAXPLAYERSCUSTOM];
new bool:HitOnForwardTide[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM]; //[VICTIM][ATTACKER]
new Float:FrostNovaOrigin[MAXPLAYERSCUSTOM][3];
new Float:AbilityCooldownTime=10.0;

//skill 2
new Float:FrostArmorAmount[]={4.0, 4.5, 5.0, 5.5, 6.0};
int HealthBoost[]={50, 50, 50, 50, 50};

//skill 3
new DarkRitualAmt[]={10,11,12,13,14};

//ultimate
new Handle:ultCooldownCvar;
new Handle:ultRangeCvar;
bool isUltimateActive;
new DeathDecayAmt[]={100,110,120,130,140};
new String:ultsnd[]="war3source/DeathAndDecayTarget2.wav";
new String:novasnd[]="npc/combine_gunship/ping_patrol.wav";
new BeamSprite,HaloSprite;

public Plugin:myinfo =
{
	name = "Race - Lich",
	author = "[Oddity]TeacherCreature",
	description = "The Lich race for War3Source.",
	version = "1.0.0.0",
	url = "warcraft-source.net"
}

bool HooksLoaded = false;
public void Load_Hooks()
{
	if(HooksLoaded) return;
	HooksLoaded = true;

	W3Hook(W3Hook_OnUltimateCommand, OnUltimateCommand);
	W3Hook(W3Hook_OnAbilityCommand, OnAbilityCommand);
}
public void UnLoad_Hooks()
{
	if(!HooksLoaded) return;
	HooksLoaded = false;

	W3Unhook(W3Hook_OnUltimateCommand, OnUltimateCommand);
	W3Unhook(W3Hook_OnAbilityCommand, OnAbilityCommand);
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


public OnPluginStart()
{

	ultCooldownCvar=CreateConVar("war3_lich_deathdecay_cooldown","35","Cooldown between ultimate usage");
	ultRangeCvar=CreateConVar("war3_lich_deathdecay_range","999999","Range of death and decay ultimate");

	//LoadTranslations("w3s.race.lich_o.phrases");
}
public OnAllPluginsLoaded()
{
	War3_RaceOnPluginStart("lich_o");
}

public OnPluginEnd()
{
	if(LibraryExists("RaceClass"))
		War3_RaceOnPluginEnd("lich_o");
}

public OnWar3LoadRaceOrItemOrdered2(num,reloadrace_id,String:shortname[])
{
	if(num==RACE_ID_NUMBER||(reloadrace_id>0&&StrEqual("lich_o",shortname,false)))
	{
		thisRaceID=War3_CreateNewRace("Lich","lich_o",reloadrace_id,"Tank support.");
		SKILL_FROSTNOVA=War3_AddRaceSkill(thisRaceID,"Frost Nova","(+ability) Reduces your enemies' movespeed and attack speed \nSlows by 30-40% and reduces attack speed by 30-40%.\n550HU range and 10s cooldown.",false,4,"(voice Help!)");
		SKILL_FROSTARMOR=War3_AddRaceSkill(thisRaceID,"Frost Armor","Increases your physical and magic armor by 4-6",false,4);
		SKILL_DARKRITUAL=War3_AddRaceSkill(thisRaceID,"Dark Ritual","Heals for 25-40 health when a teammate dies.\nAlso decreases cooldowns by -1.5s on proc.",false,4);
		ULT_DEATHDECAY=War3_AddRaceSkill(thisRaceID,"Death And Decay","Grants 10s of a deathbringing aura that deals\n5 + 2% currentHP damage every second in a 650 HU radius.\nHealing efficiency is decreased by -40% in the aura.",true,4,"(voice Jeers)");
		War3_CreateRaceEnd(thisRaceID);

		War3_AddSkillBuff(thisRaceID, SKILL_FROSTARMOR, fArmorPhysical, FrostArmorAmount);
		War3_AddSkillBuff(thisRaceID, SKILL_FROSTARMOR, fArmorMagic, FrostArmorAmount);
		War3_AddSkillBuff(thisRaceID, SKILL_FROSTARMOR, iAdditionalMaxHealth, HealthBoost);

		AuraID=W3RegisterChangingDistanceAura("lich_decay",true);
	}
}
public OnW3PlayerAuraStateChanged(client,aura,bool:inAura,level,AuraStack,AuraOwner)
{
	if(RaceDisabled)
		return;

	if(aura==AuraID)
	{
		if(AuraStack>0 && inAura && !IsInvis(AuraOwner) && !W3HasImmunity(client,Immunity_Ultimates) && isUltimateActive[AuraOwner])
		{
			new Float:StackBuff=(float(AuraStack) * (5.0 + 0.02*GetClientHealth(client)) * W3GetBuffStackedFloat(client, fUltimateResistance));
			War3_SetBuff(client,fHPDecay,thisRaceID,StackBuff,AuraOwner);
			War3_SetBuff(client,fSustainEfficiency,thisRaceID,-0.4);
		}
		else
		{
			War3_SetBuff(client,fHPDecay,thisRaceID,0.0);
			War3_SetBuff(client,fSustainEfficiency,thisRaceID,0.0);
		}
	}
}
public void OnSkillLevelChanged(int client, int currentrace, int skill, int newskilllevel, int oldskilllevel)
{
	if(RaceDisabled)
		return;

	if(currentrace==thisRaceID)
	{
		if(skill==ULT_DEATHDECAY) 
		{
			W3RemovePlayerAura(AuraID,client);
			W3SetPlayerAura(AuraID,client,650.0,newskilllevel);
		}
	}
}
public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		War3_SetBuff(client,fArmorPhysical,thisRaceID,0.0);
		War3_SetBuff(client,fArmorMagic,thisRaceID,0.0);
		War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,0);
		W3RemovePlayerAura(AuraID,client);
	}
	else
	{
		W3SetPlayerAura(AuraID,client,650.0,War3_GetSkillLevel(client,thisRaceID,ULT_DEATHDECAY));
	}
	War3_SetBuff(client,fHPDecay,thisRaceID,0.0);
	War3_SetBuff(client,fSustainEfficiency,thisRaceID,0.0);

	isUltimateActive[client] = false;
}
public OnW3Denyable(W3DENY:event,client)
{
	if(RaceDisabled)
		return;

	if(War3_GetRace(client)==thisRaceID && event == DN_CanBuyItem1)
	{
		if(W3GetVar(EventArg1) == War3_GetItemIdByShortname("gauntlet"))
		{
			W3Deny();
			War3_ChatMessage(client, "The gauntlet is too heavy ...");
		}
		if(W3GetVar(EventArg1) == War3_GetItemIdByShortname("courage") || W3GetVar(EventArg1) == War3_GetItemIdByShortname("blademail") || W3GetVar(EventArg1) == War3_GetItemIdByShortname("cuirass") || W3GetVar(EventArg1) == War3_GetItemIdByShortname("faith"))
		{
			W3Deny();
			War3_ChatMessage(client, "The armor interferes with your existing one ...");
		}
	}
}
public OnMapStart()
{
	PrecacheSound(ultsnd);
	PrecacheSound(novasnd);
	BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();
}

public OnAddSound(sound_priority)
{
	if(sound_priority==PRIORITY_MEDIUM)
	{
		War3_AddSound(ultsnd);
	}
	if(sound_priority==PRIORITY_TOP)
	{
		War3_AddSound(novasnd,STOCK_SOUND);
	}
}

public void OnAbilityCommand(int client, int ability, bool pressed, bool bypass)
{
	if(RaceDisabled)
		return;

	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		if(!Silenced(client)&&(bypass||War3_SkillNotInCooldown(client,thisRaceID,SKILL_FROSTNOVA,true)))
			{

				War3_EmitSoundToAll(novasnd,client);
				GetClientAbsOrigin(client,FrostNovaOrigin[client]);
				FrostNovaOrigin[client][2]+=15.0;
				FrostNovaLoopCountdown[client]=20;

				for(new i=1;i<=MaxClients;i++){
					HitOnForwardTide[i][client]=false;
				}

				TE_SetupBeamRingPoint(FrostNovaOrigin[client], 1.0, 650.0, BeamSprite, HaloSprite, 0, 5, 1.0, 50.0, 1.0, {0,0,255,255}, 50, 0);
				TE_SendToAll();

				CreateTimer(0.1,BurnLoop,client); //damage
				CreateTimer(0.13,BurnLoop,client); //damage
				CreateTimer(0.17,BurnLoop,client); //damage


				War3_CooldownMGR(client,AbilityCooldownTime,thisRaceID,SKILL_FROSTNOVA,_,_);
				//War3_EmitSoundToAll(taunt1,client);//,_,SNDLEVEL_TRAIN);
				//War3_EmitSoundToAll(taunt1,client);//,_,SNDLEVEL_TRAIN);
				//War3_EmitSoundToAll(taunt2,client);

				PrintHintText(client,"Frost Nova!");

		}
	}
}

public Action:BurnLoop(Handle:timer,any:attacker)
{

	if(ValidPlayer(attacker) && FrostNovaLoopCountdown[attacker]>0)
	{
		new team = GetClientTeam(attacker);
		//War3_DealDamage(victim,damage,attacker,DMG_BURN);
		CreateTimer(0.1,BurnLoop,attacker);

		new Float:hitRadius=(1.0-FloatAbs(float(FrostNovaLoopCountdown[attacker])-10.0)/10.0)*FrostNovaRadius;

		//PrintToChatAll("distance to damage %f",hitRadius);

		FrostNovaLoopCountdown[attacker]--;

		new Float:otherVec[3];
		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true)&&GetClientTeam(i)!=team)
			{
					if(HitOnForwardTide[i][attacker]==true){
						continue;
					}


					GetClientAbsOrigin(i,otherVec);
					//otherVec[2]+=30.0;
					new Float:victimdistance=GetVectorDistance(FrostNovaOrigin[attacker],otherVec);
					if(victimdistance<FrostNovaRadius&&FloatAbs(otherVec[2]-FrostNovaOrigin[attacker][2])<50)
					{
						if(FloatAbs(victimdistance-hitRadius)<(FrostNovaRadius/10.0))
						{
							if(!W3HasImmunity(i,Immunity_Skills))
							{

								HitOnForwardTide[i][attacker]=true;
								//War3_DealDamage(i,RoundFloat(FrostNovaMaxDamage[War3_GetSkillLevel(attacker,thisRaceID,SKILL_FROSTNOVA)]*victimdistance/FrostNovaRadius/2.0),attacker,DMG_ENERGYBEAM,"FrostNova");
								War3_SetBuff(i,fSlow,thisRaceID,FrostNovaArr[War3_GetSkillLevel(attacker,thisRaceID,SKILL_FROSTNOVA)],attacker);
								War3_SetBuff(i,fAttackSpeed,thisRaceID,FrostNovaArr[War3_GetSkillLevel(attacker,thisRaceID,SKILL_FROSTNOVA)],attacker);
								CreateTimer(5.0*W3GetBuffStackedFloat(i, fAbilityResistance),RemoveFrostNova,i);
								PrintHintText(i,"You were slowed by frost nova!");
							}
							else
							{
								War3_NotifyPlayerImmuneFromSkill(attacker, i, SKILL_FROSTNOVA);
							}
						}
					}
			}
		}
	}
}


public Action:RemoveFrostNova(Handle:t,any:client){
	War3_SetBuff(client,fSlow,thisRaceID,1.0);
	War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
}

/*
public Action OnW3TakeDmgBullet(int victim, int attacker, float damage)
{

	if(War3_GetRace(victim)==thisRaceID&&ValidPlayer(attacker,true))
	{
		if(GetClientTeam(victim)!=GetClientTeam(attacker))
		{
			new Float:chance_mod=W3ChanceModifier(attacker);
			new skill_frostarmor=War3_GetSkillLevel(victim,thisRaceID,SKILL_FROSTARMOR);
			if(skill_frostarmor>0)
			{
				if(GetRandomFloat(0.0,1.0)<=FrostArmorChance[skill_frostarmor]*chance_mod && !W3HasImmunity(attacker,Immunity_Skills))
				{
					War3_SetBuff(attacker,fAttackSpeed,thisRaceID,0.5);
					PrintHintText(attacker,"Frost Armor slows you");
					PrintHintText(victim,"Frost Armor slows your attacker");
					W3FlashScreen(attacker,RGBA_COLOR_BLUE,0.5,0.4,FFADE_IN);
					CreateTimer(2.0,farmor,attacker);
				}
			}
		}
	}
}

public Action: farmor(Handle:timer,any:attacker)
{
	War3_SetBuff(attacker,fAttackSpeed,thisRaceID,1.0);
}
*/
public OnWar3EventDeath(victim,attacker)
{
	new team;
	if(ValidPlayer(victim)){
		team=GetClientTeam(victim);
	}
	for(new i=1;i<=MaxClients;i++)
	{
		if(War3_GetRace(i)==thisRaceID)
		{
			if(ValidPlayer(i,true)&&GetClientTeam(i)==team)
			{
				new skill=War3_GetSkillLevel(i,thisRaceID,SKILL_DARKRITUAL);
				if(!Silenced(i))
				{
					new hpadd=DarkRitualAmt[skill];
					War3_HealToBuffHP(i, hpadd);
					W3FlashScreen(i,RGBA_COLOR_GREEN,0.5,0.5,FFADE_IN);
					PrintHintText(i,"Dark Ritual gave you %i health and decreased cooldowns.", hpadd);
					War3_CooldownMGR(i, -1.5, thisRaceID, SKILL_FROSTNOVA, _,_, true);
					War3_CooldownMGR(i, -1.5, thisRaceID, ULT_DEATHDECAY, _,_, true);
				}
			}
		}
	}
}

public void OnUltimateCommand(int client, int race, bool pressed, bool bypass)
{
	if(RaceDisabled)
		return;

	new userid=GetClientUserId(client);
	if(race==thisRaceID && pressed && userid>1 && IsPlayerAlive(client) )
	{
		new ult_level=War3_GetSkillLevel(client,race,ULT_DEATHDECAY);
		if(bypass||War3_SkillNotInCooldown(client,thisRaceID,ULT_DEATHDECAY,true))
		{
			if(!Silenced(client))
			{
				War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_DEATHDECAY,false,_);
				War3_EmitSoundToAll(ultsnd,client);
				War3_EmitSoundToAll(ultsnd,client);
				War3_EmitSoundToAll(ultsnd,client);
				static int table = INVALID_STRING_TABLE;
				if (table == INVALID_STRING_TABLE)
					table = FindStringTable("ParticleEffectNames");

				TE_Start("TFParticleEffect");
				TE_WriteNum("m_iParticleSystemIndex", FindStringIndex(table, "utaunt_hellpit_parent"));
				TE_WriteNum("m_iAttachType", 1);

				TE_WriteNum("entindex", client);
				CreateTimer(10.0, Timer_KillTEParticle, EntIndexToEntRef(client));

				float fOffset[3];
				GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fOffset);
				TE_WriteFloat("m_vecOrigin[0]", fOffset[0]);
				TE_WriteFloat("m_vecOrigin[1]", fOffset[1]);
				TE_WriteFloat("m_vecOrigin[2]", fOffset[2]);
				
				TE_SendToAll();
				isUltimateActive[client] = true;
			}
		}
	}
}

public Action Timer_KillTEParticle(Handle timer, any entity)
{	
	entity = EntRefToEntIndex(entity);
	
	if (IsValidEdict(entity))
	{
		SetVariantString("ParticleEffectStop");
		AcceptEntityInput(entity, "DispatchEffect");
	}
	
	return Plugin_Stop;
}