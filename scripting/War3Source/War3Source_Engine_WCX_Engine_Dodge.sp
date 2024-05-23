// War3Source_Engine_WCX_Engine_Dodge.sp

/* Plugin Template generated by Pawn Studio */

//#include <war3source>

//#assert GGAMEMODE == MODE_WAR3SOURCE

//#pragma semicolon 1

new Handle:FHOnW3DodgePre;
new Handle:FHOnW3DodgePost;
/*
public Plugin:myinfo =
{
	name = "WCX - Dodge Engine",
	author = "necavi, Anthony Iacono",
	description = "WCX - Dodge Engine",
	version = "0.1",
	url = "http://necavi.com"
}*/

public bool:War3Source_Engine_WCX_Engine_Dodge_InitNativesForwards()
{
	FHOnW3DodgePre=CreateGlobalForward("OnW3DodgePre",ET_Hook,Param_Cell,Param_Cell,Param_Float);
	FHOnW3DodgePost=CreateGlobalForward("OnW3DodgePost",ET_Hook,Param_Cell,Param_Cell);
	return true;
}
public dodge_internal_OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if (ValidPlayer(victim))
	{
		//int inflictor=W3GetDamageInflictor();
		float EvadeChance = 0.0;
		// CHECK DAMAGE FROM MELEE (DODGE MELEE)
		if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
		{
			if (attacker == g_CurInflictor || !IsValidEntity(g_CurInflictor))
			{
				char weapon[64];
				GetClientWeapon(attacker, weapon, sizeof(weapon));
				EvadeChance += GetBuffInverseStackedFloat(victim,fDodgeChance)*GetBuffStackedFloat(attacker,fAbilityResistance);
				if(EvadeChance>0.0)
				{
					int vteam=GetClientTeam(victim);
					int ateam=GetClientTeam(attacker);
					if(vteam!=ateam)
					{
						float chance = GetRandomFloat(0.0,1.0);

						Call_StartForward(FHOnW3DodgePre);
						Call_PushCell(victim);
						Call_PushCell(attacker);
						Call_PushFloat(chance);
						Call_Finish(dummyresult);

						//if(!Hexed(victim,false) && chance<=EvadeChance && !W3HasImmunity(attacker,Immunity_Skills))
						// Gems are not skills ... they are something new
						if(chance<=EvadeChance)
						{
							W3FlashScreen(victim,RGBA_COLOR_BLUE);


							DamageModPercent(0.0);
							//DP("MELEE DODGED!");

							W3MsgEvaded(victim,attacker);

							Call_StartForward(FHOnW3DodgePost);
							Call_PushCell(victim);
							Call_PushCell(attacker);
							Call_Finish(dummyresult);
#if GGAMETYPE == GGAME_TF2
							decl Float:pos[3];
							GetClientEyePosition(victim, pos);
							pos[2] += 4.0;
							TE_ParticleToClient(0, "miss_text", pos); //to the attacker at the enemy pos
#endif
						}
					}
				}
			}
		}

		EvadeChance=0.0;
		// CHECK DAMAGE FROM RANGED (DODGE RANGED)
		if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
		{
			if (attacker == g_CurInflictor || !IsValidEntity(g_CurInflictor))
			{
				char weapon[64];
				GetClientWeapon(attacker, weapon, sizeof(weapon));
				EvadeChance += GetBuffInverseStackedFloat(victim,fDodgeChanceRanged)*GetBuffStackedFloat(attacker,fAbilityResistance);
				if(EvadeChance>0.0 && !W3IsDamageFromMelee(weapon))
				{
					int vteam=GetClientTeam(victim);
					int ateam=GetClientTeam(attacker);
					if(vteam!=ateam)
					{
						float chance = GetRandomFloat(0.0,1.0);

						Call_StartForward(FHOnW3DodgePre);
						Call_PushCell(victim);
						Call_PushCell(attacker);
						Call_PushFloat(chance);
						Call_Finish(dummyresult);

						//if(!Hexed(victim,false) && chance<=EvadeChance && !W3HasImmunity(attacker,Immunity_Skills))
						// Gems are not skills ... they are something new
						if(chance<=EvadeChance)
						{
							W3FlashScreen(victim,RGBA_COLOR_BLUE);


							DamageModPercent(0.0);
							//DP("RANGE DODGED!");

							W3MsgEvaded(victim,attacker);

							Call_StartForward(FHOnW3DodgePost);
							Call_PushCell(victim);
							Call_PushCell(attacker);
							Call_Finish(dummyresult);
#if GGAMETYPE == GGAME_TF2
							decl Float:pos[3];
							GetClientEyePosition(victim, pos);
							pos[2] += 4.0;
							TE_ParticleToClient(0, "miss_text", pos); //to the attacker at the enemy pos
#endif
						}
					}
				}
			}
		}
	}
}



