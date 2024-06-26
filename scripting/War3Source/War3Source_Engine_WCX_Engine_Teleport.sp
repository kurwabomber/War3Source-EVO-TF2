// War3Source_Engine_WCX_Engine_Teleport.sp

/* Plugin Template generated by Pawn Studio */

//#include <war3source>
//#assert GGAMEMODE == MODE_WAR3SOURCE

//new PlayerRace[MAXPLAYERSCUSTOM];
/*
public Plugin:myinfo =
{
	name = "WCX Teleport",
	author = "El Diablo",
	description = "WCX Teleport",
	version = "0.1",
	url = "http://war3evo.info"
}*/

enum struct W3TeleportProp
{
	int tele_target;
	float tele_target_ScaleVector_distance;
	float tele_distance;
	int tele_raceid;
	int tele_skillid;
}

new String:teleportSound[]="war3source/blinkarrival.mp3";

W3TeleportProp PlayerProp[MAXPLAYERSCUSTOM];

new ClientTracer;
new Float:emptypos[3];
new Float:oldpos[MAXPLAYERSCUSTOM][3];
new Float:teleportpos[MAXPLAYERSCUSTOM][3];
new bool:inteleportcheck[MAXPLAYERSCUSTOM];

new Handle:g_OnW3TeleportGetAngleVectorsPre;
new Handle:g_OnW3TeleportEntityCustom;
new Handle:g_OnW3TeleportLocationChecking;
new Handle:g_OnW3Teleported;

public bool:War3Source_Engine_WCX_Engine_Teleport_InitNatives()
{
	CreateNative("W3Teleport", Native_War3_Teleport);
	return true;
}

public bool:War3Source_Engine_WCX_Engine_Teleport_InitNativesForwards()
{
	g_OnW3Teleported=CreateGlobalForward("OnW3Teleported",ET_Ignore,Param_Cell,Param_Cell,Param_Float,Param_Cell,Param_Cell);

	g_OnW3TeleportGetAngleVectorsPre=CreateGlobalForward("OnW3TeleportGetAngleVectorsPre",ET_Hook,Param_Cell,Param_Cell,Param_Array);

	g_OnW3TeleportEntityCustom=CreateGlobalForward("OnW3TeleportEntityCustom",ET_Hook,Param_Cell,Param_Cell,Param_Array,Param_Array);

	g_OnW3TeleportLocationChecking=CreateGlobalForward("OnW3TeleportLocationChecking",ET_Hook,Param_Cell,Param_Array);

	return true;
}

public War3Source_Engine_WCX_Engine_Teleport_OnAddSound(sound_priority)
{
	if(sound_priority==PRIORITY_MEDIUM)
	{
		War3_AddSound(teleportSound);
	}
}

public Native_War3_Teleport(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	if(ValidPlayer(client))
	{
		PlayerProp[client].tele_target = GetNativeCell(2);
		PlayerProp[client].tele_target_ScaleVector_distance = Float:GetNativeCell(3);
		PlayerProp[client].tele_distance = Float:GetNativeCell(4);
		PlayerProp[client].tele_raceid = GetNativeCell(5);
		PlayerProp[client].tele_skillid = GetNativeCell(6);

		internal_Teleport(client,PlayerProp[client].tele_target,PlayerProp[client].tele_target_ScaleVector_distance,PlayerProp[client].tele_distance);
	}
}


bool:internal_Teleport(client,target,Float:ScaleVectorDistance,Float:distance)
{
	if(!inteleportcheck[client])
	{
		if(target>-1 && !ValidPlayer(target,true))
		{
			return false;
		}
		//new Target = BullyEnemyTarget[client];
		new Float:angle[3];
		//GetClientEyeAngles(Target,angle);
		//GetClientEyeAngles(client,angle);
		new Float:endpos[3];
		new Float:startpos[3];
		new Float:clientpos[3];
		if(target>-1)
		{
			GetClientEyePosition(target,startpos);
			GetClientEyePosition(client,clientpos);
		}
		else
		{
			GetClientEyePosition(client,startpos);
		}
		new Float:dir[3];
		/*
		angle[0]=0.0;
		angle[2]=0.0;
		if(angle[1] >0){
			angle[1]= -(180-angle[1]);
		}else{
			angle[1]= (180+angle[1]);
		}*/
		//DP("angles %f %f %f",angle[0],angle[1],angle[2]);
		new Action:returnVal = Plugin_Continue;
		Call_StartForward(g_OnW3TeleportGetAngleVectorsPre);
		Call_PushCell(client);
		Call_PushCell(target);
		Call_PushArrayEx(angle,sizeof(angle),SM_PARAM_COPYBACK);
		Call_Finish(_:returnVal);
		if(returnVal == Plugin_Continue)
		{
			//PrintToChatAll("...continue recieved...");
			//PrintToChatAll("...continue recieved...");
			//PrintToChatAll("...continue recieved...");
			GetClientEyeAngles(client,angle);
		}
		//DP("angles %f %f %f",angle[0],angle[1],angle[2]);

		//NegateVector(angle);
		GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);
		//DP("%f, %f, %f",angle[0],angle[1],angle[2]);
		//new Float:TDist=GetConVarFloat(TDistBullyCvar);
		if(ScaleVectorDistance>-1.0)
		{
			ScaleVector(dir, ScaleVectorDistance);
		}
		else
		{
			ScaleVector(dir, distance);
		}

		AddVectors(startpos, dir, endpos);

		GetClientAbsOrigin(client,oldpos[client]);


		if(target>-1)
		{
			ClientTracer=target;
		}
		else
		{
			ClientTracer=client;
		}
		TR_TraceRayFilter(startpos,endpos,MASK_ALL,RayType_EndPoint,Teleport_AimTargetFilter);
		TR_GetEndPosition(endpos);

		if(enemyImmunityInRange(client,endpos)){
			W3MsgEnemyHasImmunity(client);
			return false;
		}

		new Float:distanceteleport;
		new Float:distanceteleport2;

		if(target>-1)
		{
			distanceteleport=GetVectorDistance(startpos,endpos);
			distanceteleport2=GetVectorDistance(clientpos,startpos);
			if(distanceteleport2 > distance){
				new String:buffer[100];
				Format(buffer, sizeof(buffer), "You are too far away from your target!");
				//DP("%f > %f",distanceteleport,distance);
				PrintHintText(client,buffer);
				return false;
			}
			if(distanceteleport2<200.0){
				new String:buffer[100];
				Format(buffer, sizeof(buffer), "You are too close too teleport!");
				PrintHintText(client,buffer);
				return false;
			}
		}
		else
		{
			distanceteleport=GetVectorDistance(startpos,endpos);
			if(distanceteleport<200.0){
				new String:buffer[100];
				Format(buffer, sizeof(buffer),"Distance too short.");
				PrintHintText(client,buffer);
				return false;
			}
		}

		GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);///get dir again
		ScaleVector(dir, distanceteleport-33.0);

		AddVectors(startpos,dir,endpos);
		emptypos[0]=0.0;
		emptypos[1]=0.0;
		emptypos[2]=0.0;

		endpos[2]-=30.0;
		getEmptyLocationHull(client,endpos);

		if(GetVectorLength(emptypos)<1.0){
			new String:buffer[100];
			Format(buffer, sizeof(buffer), "No empty location found");
			PrintHintText(client,buffer);
			return false; //it returned 0 0 0
		}

		//emptypos[1]+=10;
		//GetClientEyeAngles(Target,angle);
		//GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);
		//TeleportEntity(client,emptypos,angle,dir);

		returnVal = Plugin_Continue;
		Call_StartForward(g_OnW3TeleportEntityCustom);
		Call_PushCell(client);
		Call_PushCell(target);
		Call_PushArray(dir,sizeof(dir));
		Call_PushArray(emptypos,sizeof(emptypos));
		Call_Finish(_:returnVal);
		if(returnVal == Plugin_Continue)
		{
			TeleportEntity(client,emptypos,NULL_VECTOR,NULL_VECTOR);
		}

		War3_EmitSoundToAll(teleportSound,client);
		War3_EmitSoundToAll(teleportSound,client);

		teleportpos[client][0]=emptypos[0];
		teleportpos[client][1]=emptypos[1];
		teleportpos[client][2]=emptypos[2];

		inteleportcheck[client]=true;
		CreateTimer(0.14,checkTeleport,client);

		return true;
	}

	return false;
}

public Action:checkTeleport(Handle:h,any:client){
	if(MapChanging || War3SourcePause) return Plugin_Stop;

	inteleportcheck[client]=false;
	new Float:pos[3];

	GetClientAbsOrigin(client,pos);

	if(GetVectorDistance(teleportpos[client],pos)<0.001)//he didnt move in this 0.1 second
	{
		TeleportEntity(client,oldpos[client],NULL_VECTOR,NULL_VECTOR);
		PrintHintText(client,"Cannot teleport there");
		if(PlayerProp[client].tele_raceid>-1 && PlayerProp[client].tele_skillid>-1)
		{
			War3_CooldownReset(client,PlayerProp[client].tele_raceid,PlayerProp[client].tele_skillid);
		}
	}
	else
	{
		PrintHintText(client,"Teleported!");

		Call_StartForward(g_OnW3Teleported);
		Call_PushCell(client);
		Call_PushCell(PlayerProp[client].tele_target);
		Call_PushFloat(PlayerProp[client].tele_distance);
		Call_PushCell(PlayerProp[client].tele_raceid);
		Call_PushCell(PlayerProp[client].tele_skillid);
		Call_Finish();

		/*
		new Float:perchance=GetConVarFloat(loseTargetPercCvar);
		if(perchance != 0.0){
			if(W3Chance(perchance)){
				FreezeClient(client);
				//DP("Randnum: %f",randomnum);
				//DP("PerChance: %f",perchance);
				//DP("YEP!!!!!");
			}else{
				//DP("Randnum: %f",randomnum);
				//DP("PerChance: %f",perchance);
				//DP("NOPE!!!!!");
				//DP("RaceID: %d", thisRaceID);
			}
		}*/
	}
	return Plugin_Continue;
}

public bool:Teleport_AimTargetFilter(entity,mask)
{
	return !(entity==ClientTracer);
}


//new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};//,27,-27,30,-30,33,-33,40,-40}; //for human it needs to be smaller
new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25,27,-27,30,-30,33,-33,40,-40,-50,-75,-90,-110}; //for human it needs to be smaller

public bool:getEmptyLocationHull(client,Float:originalpos[3]){


	new Float:mins[3];
	new Float:maxs[3];
	GetClientMins(client,mins);
	GetClientMaxs(client,maxs);

	new absincarraysize=sizeof(absincarray);

	new limit=5000;
	for(new x=0;x<absincarraysize;x++){
		if(limit>0){
			for(new y=0;y<=x;y++){
				if(limit>0){
					for(new z=0;z<=y;z++){
						new Float:pos[3]={0.0,0.0,0.0};
						AddVectors(pos,originalpos,pos);
						pos[0]+=float(absincarray[x]);
						pos[1]+=float(absincarray[y]);
						pos[2]+=float(absincarray[z]);

						TR_TraceHullFilter(pos,pos,mins,maxs,MASK_SOLID,Teleport_CanHitThis,client);
						//new ent;
						if(!TR_DidHit(_))
						{
							AddVectors(emptypos,pos,emptypos); ///set this gloval variable
							limit=-1;
							break;
						}

						if(limit--<0){
							break;
						}
					}

					if(limit--<0){
						break;
					}
				}
			}

			if(limit--<0){
				break;
			}

		}

	}

}

public bool:Teleport_CanHitThis(entityhit, mask, any:data)
{
	if(entityhit == data )
	{// Check if the TraceRay hit the itself.
		return false; // Don't allow self to be hit, skip this result
	}
	if(ValidPlayer(entityhit)&&ValidPlayer(data)&&GetClientTeam(entityhit)==GetClientTeam(data)){
		return false; //skip result, prend this space is not taken cuz they on same team
	}
	return true; // It didn't hit itself
}


public bool:enemyImmunityInRange(client,Float:playerVec[3])
{
	new Action:returnVal = Plugin_Continue;
	Call_StartForward(g_OnW3TeleportLocationChecking);
	Call_PushCell(client);
	Call_PushArray(playerVec, sizeof(playerVec));
	Call_Finish(_:returnVal);
	if(returnVal != Plugin_Continue)
	{
		return true;
	}
	return false;

	//ELIMINATE ULTIMATE IF THERE IS IMMUNITY AROUND
	/*
	new Float:otherVec[3];
	new team = GetClientTeam(client);
	new skilllevel=War3_GetSkillLevel(client,thisRaceID,ULT_IMPROVED_TELEPORT);

	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&W3HasImmunity(i,Immunity_Ultimates))
		{
			GetClientAbsOrigin(i,otherVec);
			if(skilllevel==0)
			{
				if(GetVectorDistance(playerVec,otherVec)<350)
				{
					War3_NotifyPlayerImmuneFromSkill(client, i, ULT_IMPROVED_TELEPORT);
					return true;
				}
			}
			if(skilllevel==1)
			{
				if(GetVectorDistance(playerVec,otherVec)<150)
				{
					War3_NotifyPlayerImmuneFromSkill(client, i, ULT_IMPROVED_TELEPORT);
					return true;
				}
			}
		}
	}
	return false;
	*/
}
