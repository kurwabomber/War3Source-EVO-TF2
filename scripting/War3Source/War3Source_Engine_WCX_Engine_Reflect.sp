// War3Source_Engine_WCX_Engine_Reflect.sp

public void War3Source_Engine_WCX_Engine_Reflect_OnWar3EventPostHurt(int victim, int attacker,float damage,char weapon[64],bool isWarcraft)
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

	if(!War3_IsUsingMeleeWeapon(attacker))
		return;

	float ReflectRatio = GetBuffSumFloat(victim, fMeleeThorns);
	int damageDealt = RoundToNearest(ReflectRatio * damage);

	if(damageDealt > 0)
	{
		if(War3_DealDamage(attacker,damageDealt,victim,_,"reflect"))
		{

		}
	}
}

