// War3Source_Engine_WCX_Engine_Reflect.sp

public void War3Source_Engine_WCX_Engine_Reflect_OnWar3EventPostHurt(int victim, int attacker,float damage,char weapon[64],bool isWarcraft,int wep)
{
	if((victim == attacker) || (!IsValidEntity(victim) || !ValidPlayer(attacker)))
	{
		return;
	}
	if(ValidPlayer(victim,true))
	{
		if((GetClientTeam(victim) == GetClientTeam(attacker)))
		{
			return;
		}
	}

	if(StrEqual(weapon, "reflect"))
		return;

	if(!IsValidEntity(wep) || !HasEntProp(wep, Prop_Send, "m_iItemDefinitionIndex"))
		return;

	if(TF2Util_GetWeaponSlot(wep) != TFWeaponSlot_Melee)
		return;

	float ReflectRatio = GetBuffSumFloat(victim, fMeleeThorns);
	int damageDealt = RoundToNearest(ReflectRatio * damage);

	if(damageDealt > 0)
	{
		if(War3_DealDamage(attacker,damageDealt,victim,_,"reflect",W3DMGORIGIN_ITEM,W3DMGTYPE_PHYSICAL))
		{
		}
	}
}

