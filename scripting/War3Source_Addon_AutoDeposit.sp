
#include <war3source>
#assert GGAMEMODE == MODE_WAR3SOURCE

public Plugin:myinfo=
{
	name="War3Source:EVO Addon - AutoDeposit",
	author="El Diablo",
	description="War3Source:EVO Addon Plugin",
	version="1.0",
};

new bool:AutoDepositToggle[MAXPLAYERSCUSTOM] = {false, ...};

public OnPluginStart()
{
	RegConsoleCmd("sm_autodeposit", cmd_AutoDeposit, "sm_autodeposit");
}
public OnAllPluginsLoaded()
{
	W3Hook(W3Hook_OnWar3Event, OnWar3Event);
}
public Action:cmd_AutoDeposit(client, args)
{
	if(ValidPlayer(client))
	{
		Toggle(AutoDepositToggle[client]);
		War3_ChatMessage(client,AutoDepositToggle[client]?"{lightgreen}AutoDeposit turned on":"{lightgreen}AutoDeposit turned off");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void OnWar3Event(W3EVENT event,int client)
{//OnPreGiveXPGold OnPostGiveXPGold
	if(event==OnPreGiveXPGold && ValidPlayer(client) && !IsFakeClient(client))
	{
		if(AutoDepositToggle[client])
		{
			//new XP=W3GetVar(EventArg2);
			new Gold=W3GetVar(EventArg3);
			// deposit
			//new currentgold=War3_GetGold(client);
			if (War3_GetGold(client) >= W3GetMaxGold(client) && Gold>0)
			{
				W3SetVar(EventArg3,0);
				new newbankgold = War3_GetGoldBank(client) + Gold;
				War3_SetGoldBank(client,newbankgold);
				//currentgold-=Gold;
				//War3_SetGold(client,currentgold);
				War3_ChatMessage(client,"{default}[{green}AUTODEPOSIT{default}] {green}%d{default} gold deposited. You have {green}%d{default} in bank.",Gold,newbankgold);
			}
		}
	}
	else if(event==InitPlayerVariables)
	{
		AutoDepositToggle[client]=false;
	}
	else if(event==ClearPlayerVariables)
	{
		AutoDepositToggle[client]=false;
	}
}
