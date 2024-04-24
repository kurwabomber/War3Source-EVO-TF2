//=============================================================================
// Races / Race Creation
//=============================================================================

/*
methodmap War3Source_Races
{
	public War3Source_Races()
	{
		return view_as<War3Source_Races>(true);
	}
	public native int War3_CreateNewRace(char[] name, char[] shortname,int reload_race_id=0,char[] shortdesc="no description");
	public native int War3_CreateNewRaceT(String:shortname[],reload_race_id=0,String:shortdesc[]="no description");
	public native int War3_AddRaceSkill(int raceid,char[] tskillorultname,char[] tskillorultdescription,bool isult=false,int maxskilllevel=DEF_MAX_SKILL_LEVEL);
	public native int War3_AddRaceSkillT(int raceid,char[] SkillNameIdentifier,bool isult=false,int maxskilllevel=DEF_MAX_SKILL_LEVEL,any ...);
	public native void War3_CreateRaceEnd(int raceid);

	public native void War3_RaceOnPluginStart(char shortname[16]);
	public native void War3_RaceOnPluginEnd(char shortname[16]);
	public native bool War3_IsRaceReloading();

	public native void War3_GetRaceName(int raceid,char[] retstr,int maxlen);
	public native void War3_GetRaceShortname(int raceid,char[] retstr,int maxlen);
	public native void War3_GetRaceShortdesc(int raceid,char[] retstr,int maxlen);

	public native int War3_GetRacesLoaded();
	public native int W3GetRaceMaxLevel(int raceid);
	//public
	//public
	//public
	//public
	//public
	//public
	//public
	//public

	public native bool War3_IsSkillUltimate(int raceid, int skillnum);
	public native int War3_GetRaceSkillCount(raceid);
	public native void W3GetRaceSkillName(int raceid,int skillindex,char[] retstr,int maxlen);
	public native void W3GetRaceSkillDesc(int raceid,int skillindex,char[] retstr,int maxlen);
	public native int W3GetRaceSkillMaxLevel(int raceid, int skillnum);
	public native int W3GetRaceOrder(int raceid);

	public native int War3_GetSkillLevel(int client, int raceid, int skill);

	public native int War3_SetSkillLevelINTERNAL(int client, int raceid, int skill, int newlevel);
	public native int War3_GetSkillLevelINTERNAL(int client, int raceid, int skill);

	public native int W3GetMinUltLevel();

	public native bool W3RaceHasFlag(int raceid,char[] flag);

	public native void W3GetRaceAccessFlagStr(int raceid,char[] retstr,int maxlen);

	public native void W3GetRaceItemRestrictionsStr(int raceid,char[] retstr,int maxlen);

	public native int W3GetRaceList(int[] racelist);

	public native int W3GetRaceMaxLimitTeam(int raceid, int team);
	public native int W3GetRaceMaxLimitTeamCvar(int raceid, int team); //returns the internal cvar id (int not handle)
	public native int W3GetRaceMinLevelRequired(int raceid);
	public native bool W3IsRaceTranslated(int raceid);

	public native any W3GetRaceCell(int raceid,ENUM_RaceObject property);
	public native void W3SetRaceCell(int raceid,ENUM_RaceObject property,any somevalue);

	public native int War3_GetRace(int client);
	public native void War3_SetRace(int client, int raceid);

	public native int War3_GetRaceIDByShortname(char[] raceshortname);

	public native bool War3_SetRaceDependency(int iRaceID, int iRequiredRace, int iRequiredLevel);
	public native void War3_RemoveRaceDependency(int iRaceID, int iRequiredRace=0);
	public native int War3_FindRaceDependency(int iRaceID, int IRequiredID);
}*/

//creates a new race, returns the race id
//a valid race is >0
//native War3_CreateNewRace(String:name[],String:shortname[],reload_race_id=0,String:shortdesc[]="no description");
native int War3_CreateNewRace(char[] name, char[] shortname,int reload_race_id=0,char[] shortdesc="no description");

//translated
//creates a new race, returns the race id
//native War3_CreateNewRaceT(String:shortname[],reload_race_id=0,String:shortdesc[]="no description");
native int War3_CreateNewRaceT(String:shortname[],reload_race_id=0,String:shortdesc[]="no description");

//adds a skill or a ultimate
//native War3_AddRaceSkill(raceid,String:tskillorultname[],String:tskillorultdescription[],bool:isult=false,maxskilllevel=DEF_MAX_SKILL_LEVEL);
native int War3_AddRaceSkill(int raceid,char[] tskillorultname,char[] tskillorultdescription,bool isult=false,int maxskilllevel=DEF_MAX_SKILL_LEVEL);

//translated
//adds a skill or a ultimate
//additional parameters replaces #1# #2# ... in the translation string (max 5)
// % does not need to be escaped
//native War3_AddRaceSkillT(raceid,String:SkillNameIdentifier[],bool:isult=false,maxskilllevel=DEF_MAX_SKILL_LEVEL,any:...);
native int War3_AddRaceSkillT(int raceid,char[] SkillNameIdentifier,bool isult=false,int maxskilllevel=DEF_MAX_SKILL_LEVEL,any ...);

//ends race creation!!! MUST CALL THIS!!!
native void War3_CreateRaceEnd(int raceid);

//=============================================================================
// Races Reloading
//=============================================================================

// Makes it so that your races are reloadable
native void War3_RaceOnPluginStart(char shortname[16]);
native void War3_RaceOnPluginEnd(char shortname[16]);
native bool War3_IsRaceReloading();

//=============================================================================
// Races Information / name, shortname, etc.
//=============================================================================

native void War3_GetRaceName(int raceid,char[] retstr,int maxlen);
native void War3_GetRaceShortname(int raceid,char[] retstr,int maxlen);
native void War3_GetRaceShortdesc(int raceid,char[] retstr,int maxlen);


//#pragma deprecated Not Fully Implemented, possibly in the future
//native W3GetRaceString(raceid,RaceString:property,String:retstr[],maxlen); // not implemented
//#pragma deprecated Not Fully Implemented, possibly in the future
//native W3GetRaceSkillString(raceid,skillnum,SkillString:property,String:retstr[],maxlen);


/*
 * SHOULD PROBABLY REMOVE THIS, AS I HAVE NEVER USED IT IN MY 6 YEARS OF PROGRAMMING
 * WAR3SOURCE: GENERIC SKILLS
 *
 */
//native War3_CreateGenericSkill(String:gskillname[]);
//genericSkillData is an array or trie that modifies behavior of that generic skill
//if NEW HANDLE is passed, OLD one will be closed (i e during create race call after race has been created like on a map change)
//this means you CAN recreate new handles and pass them, the old one will be closed
//native War3_UseGenericSkill(raceid,String:gskillname[],Handle:genericSkillData,String:yourskillname[],String:untranslatedSkillDescription[]="ERR: No Skill Description Entered.",bool:translated=false,bool:isUltimate=false,maxskilllevel=DEF_MAX_SKILL_LEVEL,any:...);

//=============================================================================
// Get Total number of races loaded
//=============================================================================

native int War3_GetRacesLoaded();

//=============================================================================
// Get Race Max Level
//=============================================================================

native int W3GetRaceMaxLevel(int raceid);

//=============================================================================
// RACE Skills Information
//=============================================================================

native bool War3_IsSkillUltimate(int raceid, int skillnum);
native int War3_GetRaceSkillCount(raceid);
native void W3GetRaceSkillName(int raceid,int skillindex,char[] retstr,int maxlen);
native void W3GetRaceSkillDesc(int raceid,int skillindex,char[] retstr,int maxlen);
native int W3GetRaceSkillMaxLevel(int raceid, int skillnum);
native int W3GetRaceOrder(int raceid);

native int War3_GetSkillLevel(int client, int raceid, int skill);

native int War3_SetSkillLevelINTERNAL(int client, int raceid, int skill, int newlevel);
native int War3_GetSkillLevelINTERNAL(int client, int raceid, int skill);

native int W3GetMinUltLevel();


//=============================================================================
// RACE Flags
//=============================================================================
//Flag is a generic string. We compare the race_flags cvar to the string you passed

native bool W3RaceHasFlag(int raceid,char[] flag);

native void W3GetRaceAccessFlagStr(int raceid,char[] retstr,int maxlen);

native void W3GetRaceItemRestrictionsStr(int raceid,char[] retstr,int maxlen);


//=============================================================================
// RACE Misc
//=============================================================================

//returns a simple array of race IDs, sorted properly.
//Does not include "hidden" races
//pass array of MAXRACES, returns number of races in the array. starts at 0
//ordered properly
//returns the size of the array

native int W3GetRaceList(int[] racelist);

native int W3GetRaceMaxLimitTeam(int raceid, int team);
native int W3GetRaceMaxLimitTeamCvar(int raceid, int team); //returns the internal cvar id (int not handle)
native int W3GetRaceMinLevelRequired(int raceid);
native bool W3IsRaceTranslated(int raceid);

native any W3GetRaceCell(int raceid,ENUM_RaceObject property);
native void W3SetRaceCell(int raceid,ENUM_RaceObject property,any somevalue);

#define MAXENTITIES 2049

stock bool ValidRace(int raceid_)
{
	return bool:(raceid_>0&&raceid_<=War3_GetRacesLoaded());
}
// internal engine only
stock bool eValidRace(int raceid_)
{
	return bool:(raceid_>0&&raceid_<=War3_GetRacesLoaded());
}
stock bool:IsTargetInSightRange(client, target, Float:angle=90.0, Float:distance=0.0, bool:heightcheck=false, bool:negativeangle=false)
{
	if(angle > 360.0 || angle < 0.0)
		ThrowError("Angle Max : 360 & Min : 0. %d isn't proper angle.", angle);
	if(!IsClientConnected(client) && IsPlayerAlive(client))
		ThrowError("Client is not Alive.");
	if(!IsClientConnected(target) && IsPlayerAlive(target))
		ThrowError("Target is not Alive.");
		
	decl Float:clientpos[3], Float:targetpos[3], Float:anglevector[3], Float:targetvector[3], Float:resultangle, Float:resultdistance;
	GetClientEyeAngles(client,anglevector);
	GetAngleVectors(anglevector, anglevector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(anglevector, anglevector);
	if(heightcheck == false)
		anglevector[2] = 0.0;
	if(negativeangle){
		NegateVector(anglevector);
	}
	GetClientAbsOrigin(client, clientpos);
	GetClientAbsOrigin(target, targetpos);
	if(heightcheck && distance > 0){
		targetpos[2] -= 40.0;
		resultdistance = GetVectorDistance(clientpos, targetpos);
	}
	if(heightcheck == false){
		clientpos[2] = targetpos[2] = 0.0;
	}
	MakeVectorFromPoints(clientpos, targetpos, targetvector);
	if(heightcheck == false){
		targetvector[2] = 0.0;
	}
	NormalizeVector(targetvector, targetvector);
	resultangle = GetAngleBetweenVector(targetvector, anglevector);
	
	if(resultangle <= angle)
	{
		if(distance > 0)
		{
			if(!heightcheck)
				resultdistance = GetVectorDistance(clientpos, targetpos);
			if(distance >= resultdistance)
				return true;
			else
				return false;
		}
		else
			return true;
	}
	else
		return false;
}
stock bool:IsAbleToSee(entity, client)
{
    // Skip all traces if the player isn't within the field of view.
    // - Temporarily disabled until eye angle prediction is added.
    // if (IsInFieldOfView(g_vEyePos[client], g_vEyeAngles[client], g_vAbsCentre[entity]))
    
    decl Float:vecOrigin[3], Float:vecEyePos[3];
    GetClientAbsOrigin(entity, vecOrigin);
    GetClientEyePosition(client, vecEyePos);
    
    // Check if centre is visible.
    if (IsPointVisible(vecEyePos, vecOrigin))
    {
        return true;
    }
    
    decl Float:vecEyePos_ent[3], Float:vecEyeAng[3];
    GetClientEyeAngles(entity, vecEyeAng);
    GetClientEyePosition(entity, vecEyePos_ent);
    // Check if weapon tip is visible.
    if (IsFwdVecVisible(vecEyePos, vecEyeAng, vecEyePos_ent))
    {
        return true;
    }
    
    decl Float:mins[3], Float:maxs[3];
    GetClientMins(client, mins);
    GetClientMaxs(client, maxs);
    // Check outer 4 corners of player.
    if (IsRectangleVisible(vecEyePos, vecOrigin, mins, maxs, 1.4))
    {
        return true;
    }

    // Check inner 4 corners of player.
    if (IsRectangleVisible(vecEyePos, vecOrigin, mins, maxs, 0.60))
    {
        return true;
    }
    
    return false;
}
stock bool:IsRectangleVisible(const Float:start[3], const Float:end[3], const Float:mins[3], const Float:maxs[3], Float:scale=1.0)
{
    new Float:ZpozOffset = maxs[2];
    new Float:ZnegOffset = mins[2];
    new Float:WideOffset = ((maxs[0] - mins[0]) + (maxs[1] - mins[1])) / 4.0;

    // This rectangle is just a point!
    if (ZpozOffset == 0.0 && ZnegOffset == 0.0 && WideOffset == 0.0)
    {
        return IsPointVisible(start, end);
    }

    // Adjust to scale.
    ZpozOffset *= scale;
    ZnegOffset *= scale;
    WideOffset *= scale;
    
    // Prepare rotation matrix.
    decl Float:angles[3], Float:fwd[3], Float:right[3];

    SubtractVectors(start, end, fwd);
    NormalizeVector(fwd, fwd);

    GetVectorAngles(fwd, angles);
    GetAngleVectors(angles, fwd, right, NULL_VECTOR);

    decl Float:vRectangle[4][3], Float:vTemp[3];

    // If the player is on the same level as us, we can optimize by only rotating on the z-axis.
    if (FloatAbs(fwd[2]) <= 0.7071)
    {
        ScaleVector(right, WideOffset);
        
        // Corner 1, 2
        vTemp = end;
        vTemp[2] += ZpozOffset;
        AddVectors(vTemp, right, vRectangle[0]);
        SubtractVectors(vTemp, right, vRectangle[1]);
        
        // Corner 3, 4
        vTemp = end;
        vTemp[2] += ZnegOffset;
        AddVectors(vTemp, right, vRectangle[2]);
        SubtractVectors(vTemp, right, vRectangle[3]);
        
    }
    else if (fwd[2] > 0.0) // Player is below us.
    {
        fwd[2] = 0.0;
        NormalizeVector(fwd, fwd);
        
        ScaleVector(fwd, scale);
        ScaleVector(fwd, WideOffset);
        ScaleVector(right, WideOffset);
        
        // Corner 1
        vTemp = end;
        vTemp[2] += ZpozOffset;
        AddVectors(vTemp, right, vTemp);
        SubtractVectors(vTemp, fwd, vRectangle[0]);
        
        // Corner 2
        vTemp = end;
        vTemp[2] += ZpozOffset;
        SubtractVectors(vTemp, right, vTemp);
        SubtractVectors(vTemp, fwd, vRectangle[1]);
        
        // Corner 3
        vTemp = end;
        vTemp[2] += ZnegOffset;
        AddVectors(vTemp, right, vTemp);
        AddVectors(vTemp, fwd, vRectangle[2]);
        
        // Corner 4
        vTemp = end;
        vTemp[2] += ZnegOffset;
        SubtractVectors(vTemp, right, vTemp);
        AddVectors(vTemp, fwd, vRectangle[3]);
    }
    else // Player is above us.
    {
        fwd[2] = 0.0;
        NormalizeVector(fwd, fwd);
        
        ScaleVector(fwd, scale);
        ScaleVector(fwd, WideOffset);
        ScaleVector(right, WideOffset);

        // Corner 1
        vTemp = end;
        vTemp[2] += ZpozOffset;
        AddVectors(vTemp, right, vTemp);
        AddVectors(vTemp, fwd, vRectangle[0]);
        
        // Corner 2
        vTemp = end;
        vTemp[2] += ZpozOffset;
        SubtractVectors(vTemp, right, vTemp);
        AddVectors(vTemp, fwd, vRectangle[1]);
        
        // Corner 3
        vTemp = end;
        vTemp[2] += ZnegOffset;
        AddVectors(vTemp, right, vTemp);
        SubtractVectors(vTemp, fwd, vRectangle[2]);
        
        // Corner 4
        vTemp = end;
        vTemp[2] += ZnegOffset;
        SubtractVectors(vTemp, right, vTemp);
        SubtractVectors(vTemp, fwd, vRectangle[3]);
    }

    // Run traces on all corners.
    for (new i = 0; i < 4; i++)
    {
        if (IsPointVisible(start, vRectangle[i]))
        {
            return true;
        }
    }

    return false;
}
public bool Filter_WorldOnly(int entity,int mask)
{
    return false;
}
stock bool:IsPointVisible(const Float:start[3], const Float:end[3])
{
    TR_TraceRayFilter(start, end, MASK_VISIBLE, RayType_EndPoint, Filter_WorldOnly);

    return TR_GetFraction() == 1.0;
}
stock bool:IsFwdVecVisible(const Float:start[3], const Float:angles[3], const Float:end[3])
{
    decl Float:fwd[3];
    
    GetAngleVectors(angles, fwd, NULL_VECTOR, NULL_VECTOR);
    ScaleVector(fwd, 50.0);
    AddVectors(end, fwd, fwd);

    return IsPointVisible(start, fwd);
}
stock float GetAngleBetweenVector(const float vec1[3], const float vec2[3])
{
    return RadToDeg(ArcCosine(GetVectorDotProduct(vec1, vec2) / (GetVectorLength(vec1) * GetVectorLength(vec2))));
} 
stock createExplosionEffect(const float pos[3])
{
	new particle = CreateEntityByName( "info_particle_system" );
	if ( IsValidEntity( particle ) )
	{
		TeleportEntity( particle, pos, NULL_VECTOR, NULL_VECTOR );
		DispatchKeyValue( particle, "effect_name", "ExplosionCore_MidAir" );
		DispatchSpawn( particle );
		ActivateEntity( particle );
		AcceptEntityInput( particle, "start" );
		SetVariantString( "OnUser1 !self:Kill::8:-1" );
		AcceptEntityInput( particle, "AddOutput" );
		AcceptEntityInput( particle, "FireUser1" );
		CreateTimer(0.01, SelfDestruct, EntIndexToEntRef(particle));
	}
}
public Action:SelfDestruct(Handle:timer, any:ref) 
{
    new entity = EntRefToEntIndex(ref); 

    if(IsValidEdict(entity)) 
    { 
		RemoveEntity(entity);
		KillTimer(timer);
    }
	else
	{
		KillTimer(timer);
	}
}
stock KillParticle(int entity)
{
	if(IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "Kill");
	}
}
stock bool IsValidForDamage(entity)
{
	if(!IsValidEdict(entity)) return false; 
	if(ValidPlayer(entity) && (!IsPlayerAlive(entity) || IsClientObserver(entity))) return false;	
	if(HasEntProp(entity, Prop_Data, "m_hActiveWeapon")) return true;
	if(GetEntProp(entity, Prop_Data, "m_takedamage") == 0) return false;
	return false; 
}
stock bool:IsOnDifferentTeams(entity1,entity2)
{
	new iTeam = -10;
	if(HasEntProp(entity1, Prop_Send, "m_iTeamNum"))
	{
		iTeam = GetEntProp(entity1, Prop_Send, "m_iTeamNum");
	}
	new team = -10;
	if(HasEntProp(entity2, Prop_Send, "m_iTeamNum"))
	{
		team = GetEntProp(entity2, Prop_Send, "m_iTeamNum");
	}
	if(team != -10)
	{
		if(!(team == 2 || team == 3))//They have a valid team, but it's not on red or blue.
		{
			return false;
		}
	}
	if(team != iTeam)
	{
		return true;
	}
	return false; 
}
//=============================================================================
// RACE ID Information
//=============================================================================

native int War3_GetRace(int client);
native void War3_SetRace(int client, int raceid);


//a valid race is >0
native int War3_GetRaceIDByShortname(char[] raceshortname);


//=============================================================================
// RACE DEPENDENCIES
//=============================================================================
/**
 * Adds a dependency on a race
 *
 * @param iRaceID			 Race ID
 * @param iRequiredRace		 Required Skill ID
 * @param iRequiredLevel	 Required Level Num
 * @return					 true on success, otherwhise false!
 * @error					 Thrown on invalid param num/race
 */
native bool War3_SetRaceDependency(int iRaceID, int iRequiredRace, int iRequiredLevel);

/**
 * Removes any known dependency from a race(if any)
 * NOTE: you should be able to call this safetly without having to bother about anything,
 * since no error will be thrown if there currently aren't any active dependencys on this
 *
 * @param iRaceID		 Race ID
 * @noreturn
 * @error				 Thrown on invalid param num/race
 */
native void War3_RemoveRaceDependency(int iRaceID, int iRequiredRace=0);

/**
 * Retrieves various informations about a depending skill
 * NOTE: This can be called to check if there is any dependency or not
 *
 * @param iRaceID		 Race ID
 * @param IRequiredID	 Find Required Race ID
 * @return				 returns required level
 * @error				 Thrown on invalid param num/race
 */
native int War3_FindRaceDependency(int iRaceID, int IRequiredID);



//=============================================================================
// RACE Forwards
//=============================================================================
/**
 * Gets called when someone changes their race.
 * @param client: The client's index.
 * @param newrace: The player's new race.
 */
//#pragma deprecated Use OnRaceChanged(client,oldrace,newrace);
//forward OnRaceSelected(client, newrace); //to be removed

//client is not check if valid or not, still forwarded if client is not present, so you can disable buffs etc
forward OnRaceChanged(client, oldrace, newrace);

forward void OnWar3RaceEnabled(int newrace);
forward void OnWar3RaceDisabled(int oldrace);


/**
 * Called when the plugin is ready.
 * this is called many times, increasing num each time 0.0-float(MAXRACES)*10 in 1 increments
 * this is called after all default races have been loaded (OnWar3LoadRaceOrItemOrdered finished)
 *
 * reloadrace_id used by War3_ReloadRace(), can only reload 1 race at a time.
 */
forward OnWar3LoadRaceOrItemOrdered2(num,reloadrace_id,String:shortname[]);


//=============================================================================
// RACE Misc Stocks
//=============================================================================

// Internal Engine Only!
stock GetRacesOnTeam(raceid, team, ignoreIfAdminSetRace = false)
{
	int num;
	for (int y = 1; y <= MaxClients; y++)
	{
		if (ValidPlayer(y, false))
		{
			if (War3_GetRace(y) == raceid)
			{
				if (GetClientTeam(y) == team)
				{
					if (ignoreIfAdminSetRace&& W3GetPlayerProp(y, W3PlayerProp::RaceSetByAdmin) )
					{
					} else
					{
						num++;
					}
				}
			}
		}
	}
	return num;
}

/*
HasRaceAccess(client,Handle:hRace)
{
	new String:flag_str[8];
	new Handle:cvarCheck=GetArrayCell(hRace,14);
	GetConVarString(cvarCheck,flag_str,8);
	new first_char=_:flag_str[0];
	if(StrEqual(flag_str,"0",false) || first_char<(_:'a') || first_char>(_:'z'))
		return true; // no valid cvar value, give them access
	new AdminFlag:flag_check;
	if(!FindFlagByChar(first_char,flag_check))
		return true; // bad flag provided
	new AdminId:admin = GetUserAdmin(client);
	if((admin!=INVALID_ADMIN_ID)&&(GetAdminFlag(admin,flag_check,Access_Effective)==true))
		return true; // user has flag



	//return IsDeveloper(client); // must not have proper flag if it got all the way down here.
	return false;
}
*/

