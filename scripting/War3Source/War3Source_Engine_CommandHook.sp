// War3Source_Engine_CommandHook.sp

#include <basecomm>

#define BLUETEAMCHATCOLOR "blue"
#define REDTEAMCHATCOLOR "red"

int playerNotifications[MAXPLAYERSCUSTOM][3];
Handle Cvar_ChatBlocking;
/*
public Plugin:myinfo=
{
	name="W3S Engine Command Hooks",
	author="Ownz (DarkEnergy)",
	description="War3Source:EVO Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};
*/
public OnClientPostAdminCheck(client)
{
	playerNotifications[client][0]=0;
	playerNotifications[client][1]=0;
	playerNotifications[client][2]=0;
}
int doTestOutput=0;
public War3Source_Engine_CommandHook_OnPluginStart()
{
	Cvar_ChatBlocking=CreateConVar("war3_command_blocking","0","block chat commands from showing up");
	RegAdminCmd("colourtest",colour_test,ADMFLAG_ROOT);

	RegAdminCmd("setvip",setvip,ADMFLAG_ROOT);
	RegAdminCmd("setadmin",setadmin,ADMFLAG_ROOT);
	RegAdminCmd("sethelper",sethelper,ADMFLAG_ROOT);
	RegAdminCmd("setall",setall,ADMFLAG_ROOT);
	RegAdminCmd("toggletest",toggletest,ADMFLAG_ROOT);
	RegConsoleCmd("say",War3Source_SayCommand);
	RegConsoleCmd("say_team",War3Source_TeamSayCommand);
	RegConsoleCmd("+ultimate",War3Source_UltimateCommand);
	RegConsoleCmd("-ultimate",War3Source_UltimateCommand);
	RegConsoleCmd("+ability",War3Source_NoNumAbilityCommand);
	RegConsoleCmd("-ability",War3Source_NoNumAbilityCommand); //dont blame me if ur job is a failure because theres too much buttons to press
	RegConsoleCmd("+ability1",War3Source_AbilityCommand);
	RegConsoleCmd("-ability1",War3Source_AbilityCommand);
	RegConsoleCmd("+ability2",War3Source_AbilityCommand);
	RegConsoleCmd("-ability2",War3Source_AbilityCommand);
	RegConsoleCmd("+ability3",War3Source_AbilityCommand);
	RegConsoleCmd("-ability3",War3Source_AbilityCommand);
	RegConsoleCmd("+ability4",War3Source_AbilityCommand);
	RegConsoleCmd("-ability4",War3Source_AbilityCommand);

	RegConsoleCmd("ability",War3Source_OldWCSCommand);
	RegConsoleCmd("ability1",War3Source_OldWCSCommand);
	RegConsoleCmd("ability2",War3Source_OldWCSCommand);
	RegConsoleCmd("ability3",War3Source_OldWCSCommand);
	RegConsoleCmd("ability4",War3Source_OldWCSCommand);
	RegConsoleCmd("ultimate",War3Source_OldWCSCommand);

	RegConsoleCmd("shopmenu",War3Source_CmdShopmenu);
	RegConsoleCmd("shopmenu2",War3Source_CmdShopmenu2);
	RegConsoleCmd("shopmenu3",War3Source_CmdShopmenu3);

	RegConsoleCmd("+useitem",War3Source_no_number_useitemCommand);
	RegConsoleCmd("-useitem",War3Source_no_number_useitemCommand);

	AddCommandListener(Listener_Voice, "voicemenu");
}

public Action:toggletest(client, args){
	if (doTestOutput)
		doTestOutput=0;
	else
		doTestOutput=1;
}
public Action:setall(client, args){
	char title[16];
	GetCmdArg(1, title, sizeof(title));
	char colour1[16];
	GetCmdArg(2, colour1, sizeof(colour1));
	char mode[16];
	GetCmdArg(3, mode, sizeof(mode));

	ServerCommand("chat_vip_title %s",title);
	ServerCommand("chat_vip_colour %s",colour1);
	ServerCommand("chat_admin_title %s",title);
	ServerCommand("chat_admin_colour %s",colour1);
	ServerCommand("chat_helper_title %s",title);
	ServerCommand("chat_helper_colour %s",colour1);

	ServerCommand("chat_vip_mode %s",mode);
	ServerCommand("chat_helper_mode %s",mode);
	ServerCommand("chat_admin_mode %s",mode);
	return Plugin_Handled;
}
public Action:setvip(client, args){
	char title[16];
	GetCmdArg(1, title, sizeof(title));
	char colour1[16];
	GetCmdArg(2, colour1, sizeof(colour1));
	char mode[16];
	GetCmdArg(3, mode, sizeof(mode));
	ServerCommand("chat_vip_title %s",title);
	ServerCommand("chat_vip_colour %s",colour1);
	ServerCommand("chat_vip_mode %s",mode);
	return Plugin_Handled;
}
public Action:setadmin(client, args){
	char title[16];
	GetCmdArg(1, title, sizeof(title));
	char colour1[16];
	GetCmdArg(2, colour1, sizeof(colour1));
	char mode[16];
	GetCmdArg(3, mode, sizeof(mode));
	ServerCommand("chat_admin_title %s",title);
	ServerCommand("chat_admin_colour %s",colour1);
	ServerCommand("chat_admin_mode %s",mode);
	return Plugin_Handled;
}
public Action:sethelper(client, args){
	char title[16];
	GetCmdArg(1, title, sizeof(title));
	char colour1[16];
	GetCmdArg(2, colour1, sizeof(colour1));
	char mode[16];
	GetCmdArg(3, mode, sizeof(mode));
	ServerCommand("chat_helper_title %s",title);
	ServerCommand("chat_helper_colour %s",colour1);
	ServerCommand("chat_helper_mode %s",mode);
	return Plugin_Handled;
}
public Action:colour_test(client, args){

	if(args<3){
		ReplyToCommand(client, "Usage: sm_colourtest {mode} <colour1> <colour2>");
		ReplyToCommand(client, "Usage: sm_colourtest {mode} <colour1>");
		return Plugin_Handled;
	}
	char sMode[2];
	int mode;
	GetCmdArg(1, sMode, sizeof(sMode));
	mode=StringToInt(sMode);

	char colour1[16];
	GetCmdArg(2, colour1, sizeof(colour1));
	char colour2[16];
	GetCmdArg(3, colour2, sizeof(colour2));
	if (mode) {
		char msg[255];
		Format(msg, sizeof(msg), "{%s}this is a {%s}test {%s}i hope you like it. type {%s}mygold {%s}to see your gold!!",colour1,colour2,colour1,colour2,colour1);
		CPrintToChatAll(msg);
	} else {
		char msg[255];
		Format(msg, sizeof(msg), "{%s}[ADMIN] {%s}PLAYERNAME:{%s} this is testing a colour scheme",colour1,colour2,colour1);
		CPrintToChatAll(msg);
		Format(msg, sizeof(msg), "{%s}[VIP] {%s}PLAYERNAME:{%s} this is testing a colour scheme",colour1,colour2,colour1);
		CPrintToChatAll(msg);
	}
	return Plugin_Handled;
}

char command2[256];
char command3[256];
char command4[256];

public bool:CommandCheck(String:compare[],String:command[])
{
	Format(command2,sizeof(command2),"\\%s",command);
	Format(command3,sizeof(command3),"/%s",command);
	Format(command4,sizeof(command4),"!%s",command);
	if(!strcmp(compare,command,false)||!strcmp(compare,command2,false)||!strcmp(compare,command3,false)||!strcmp(compare,command4,false))
	return true;

	return false;
}

public CommandCheckEx(String:compare[],String:command[])
{
	if(StrEqual(command,"",false))
	return -1;
	Format(command2,sizeof(command2),"\\%s",command);
	Format(command3,sizeof(command3),"/%s",command);
	if(!StrContains(compare,command,false)||!StrContains(compare,command2,false)||!StrContains(compare,command3,false))
	{
		ReplaceString(compare,256,command,"",false);
		ReplaceString(compare,256,command2,"",false);
		ReplaceString(compare,256,command3,"",false);
		int val=StringToInt(compare);
		if(val>0)
		return val;
	}
	return -1;
}
public bool:CommandCheckStartsWith(String:compare[],String:lookingfor[],int size) {
	ReplaceString(compare, size, "/", "");
	ReplaceString(compare, size, "!", "");
	return StrContains(compare, lookingfor, false)==0;
}

public Action:War3Source_CmdShopmenu(client,args)
{
	if(MapChanging) return Plugin_Continue;

	if(War3SourcePause)
	{
		War3_ChatMessage(client,"%s is currently paused, please wait until %s resumes.",W3GAMETITLE,W3GAMETITLE);
		return Plugin_Continue;
	}

	DoFwd_War3_Event(DoShowShopMenu,client);
	return Plugin_Handled;
}
public Action:War3Source_CmdShopmenu2(client,args)
{
	if(MapChanging) return Plugin_Continue;

	if(War3SourcePause)
	{
		War3_ChatMessage(client,"%s is currently paused, please wait until %s resumes.",W3GAMETITLE,W3GAMETITLE);
		return Plugin_Continue;
	}

	DoFwd_War3_Event(DoShowShopMenu2,client);
	return Plugin_Handled;
}
public Action:War3Source_CmdShopmenu3(client,args)
{
	if(MapChanging) return Plugin_Continue;

	if(War3SourcePause)
	{
		War3_ChatMessage(client,"%s is currently paused, please wait until %s resumes.",W3GAMETITLE,W3GAMETITLE);
		return Plugin_Continue;
	}

	DoFwd_War3_Event(DoShowShopMenu3,client);
	return Plugin_Handled;
}
public Action:War3Source_SayCommand(client,args)
{
	char arg1[256]; //was 70
	char msg[256]; //was 70
	GetCmdArg(1,arg1,sizeof(arg1));
	GetCmdArgString(msg, sizeof(msg));
	StripQuotes(msg);

	Action returnblocking=Plugin_Continue;

	if(Internal_War3Source_SayCommand(client,arg1))
	{
		returnblocking=Plugin_Handled;
	}
	return returnblocking;
}

public Action:War3Source_TeamSayCommand(client,args)
{
	char arg1[256]; //was 70
	char msg[256]; // was 70

	GetCmdArg(1,arg1,sizeof(arg1));
	GetCmdArgString(msg, sizeof(msg));
	StripQuotes(msg);

	Action returnblocking=Plugin_Continue;

	if(Internal_War3Source_SayCommand(client,arg1))
	{
		returnblocking = Plugin_Handled;
	}

	return returnblocking;
}

public Action:War3Source_UltimateCommand(client,args)
{
	if(MapChanging) return Plugin_Continue;

	if(War3SourcePause)
	{
		War3_ChatMessage(client,"%s is currently paused, please wait until %s resumes.",W3GAMETITLE,W3GAMETITLE);
		return Plugin_Continue;
	}
	if(IsInvis(client) || TF2_IsPlayerInCondition(client, TFCond_Bonked)) return Plugin_Continue;

	char command[32];
	GetCmdArg(0,command,sizeof(command));

	int race=GetRace(client);
	if(race>0)
	{
		bool pressed=false;
		if(StrContains(command,"+")>-1)
		pressed=true;
		Call_StartForward(p_OnUltimateCommand);
		Call_PushCell(client);
		Call_PushCell(race);
		Call_PushCell(pressed);
		Call_PushCell(false); // bypass ultimate restrictions
		int result;
		Call_Finish(result);
	}

	return Plugin_Handled;
}

public Action:War3Source_AbilityCommand(client,args)
{
	if(MapChanging) return Plugin_Continue;

	if(War3SourcePause)
	{
		War3_ChatMessage(client,"%s is currently paused, please wait until %s resumes.",W3GAMETITLE,W3GAMETITLE);
		return Plugin_Continue;
	}
	if(IsInvis(client) || TF2_IsPlayerInCondition(client, TFCond_Bonked)) return Plugin_Continue;

	char command[32];
	GetCmdArg(0,command,sizeof(command));

	bool pressed=false;

	if(StrContains(command,"+")>-1)
	pressed=true;
	if(!IsCharNumeric(command[8]))
	return Plugin_Handled;
	int num=_:command[8]-48;
	if(num>0 && num<7)
	{
		Call_StartForward(p_OnAbilityCommand);
		Call_PushCell(client);
		Call_PushCell(num);
		Call_PushCell(pressed);
		Call_PushCell(false); // bypass ability restrictions
		int result;
		Call_Finish(result);
	}

	return Plugin_Handled;
}

public Action:War3Source_NoNumAbilityCommand(client,args)
{
	if(MapChanging) return Plugin_Continue;

	if(War3SourcePause)
	{
		War3_ChatMessage(client,"%s is currently paused, please wait until %s resumes.",W3GAMETITLE,W3GAMETITLE);
		return Plugin_Continue;
	}

	if(IsInvis(client) || TF2_IsPlayerInCondition(client, TFCond_Bonked)) return Plugin_Continue;

	char command[32];
	GetCmdArg(0,command,sizeof(command));

	bool pressed=false;
	if(StrContains(command,"+")>-1)
	pressed=true;
	Call_StartForward(p_OnAbilityCommand);
	Call_PushCell(client);
	Call_PushCell(0);
	Call_PushCell(pressed);
	Call_PushCell(false); // bypass ability cooldown restrictions
	int result;
	Call_Finish(result);

	return Plugin_Handled;
}

public Action:War3Source_OldWCSCommand(client,args) {
	War3_ChatMessage(client,"The proper commands are +ability, +ability1 ... and +ultimate");
}

bool:Internal_War3Source_SayCommand(client,String:arg1[256])
{
	if(War3SourcePause)
	{
		War3_ChatMessage(client,"%s is currently paused, please wait until %s resumes.",W3GAMETITLE,W3GAMETITLE);
		return false;
	}

	int top_num;

	bool returnblocking = (GetConVarInt(Cvar_ChatBlocking)>0)?true:false;
 	if(CommandCheck(arg1,"showxp") || CommandCheck(arg1,"xp"))
	{
		War3_ShowXP(client);
		return returnblocking;

	}
	else if(CommandCheckStartsWith(arg1,"cj",sizeof(arg1))||CommandCheckStartsWith(arg1,"cr",sizeof(arg1))||CommandCheckStartsWith(arg1,"changejob",sizeof(arg1))||CommandCheckStartsWith(arg1,"changerace",sizeof(arg1)))
	{
		char CompareStr[64];
		int secondArgument = FindCharInString(arg1,' ') + 1;
		if(secondArgument != 0)
		{
			strcopy(CompareStr,sizeof(CompareStr),arg1[secondArgument]);
			//PrintToChat(client,"secondArgument %i", secondArgument);
			int RacesLoaded = GetRacesLoaded();
			char sRaceName[32];
			int x;
			bool foundit=false;
			for(x=1;x<=RacesLoaded;x++)
			{
				GetRaceName(x,sRaceName,sizeof(sRaceName));
				if(StrContains(sRaceName,CompareStr,false)>-1)
				{
					foundit=true;
					break;
				}
			}
			if(foundit)
			{
				bool allowChooseRace=CanSelectRace(client,x);
				if(allowChooseRace==true)
				{
					if(War3_IsInSpawn(client))
					{
						W3SetPendingRace(client,-1);
						SetRace(client,x);
					}
					else
					{
						W3SetPendingRace(client,x);
						ForcePlayerSuicide(client);
					}
				}
				else
				{
					War3_ChatMessage(client,"You can not select that race.");
				}
			}
			else
			{
				W3Hint(client,HINT_NORMAL,5.0,"Could not find race.");
			}
		}
		else
		{
			DoFwd_War3_Event(DoShowChangeRaceMenu,client);
		}
		return returnblocking;
	}
	else if(CommandCheck(arg1,"buff")||CommandCheck(arg1,"buffs")||CommandCheck(arg1,"showbuffs")||CommandCheck(arg1,"showbuff"))
	{
		War3_ShowBuffs(client);
		return returnblocking;
	}
	else if(CommandCheck(arg1,"war3help")||CommandCheck(arg1,"help")||CommandCheck(arg1,"wchelp")||CommandCheck(arg1,"war3")||CommandCheck(arg1,"war3menu")||CommandCheck(arg1,"w3e")||CommandCheck(arg1,"wcs"))
	{
		DoFwd_War3_Event(DoShowWar3Menu,client);
		return returnblocking;
	}
	else if(CommandCheck(arg1,"itemsinfo")||CommandCheck(arg1,"iteminfo"))
	{
		DoFwd_War3_Event(DoShowItemsInfoMenu,client);
		return returnblocking;
	}
	else if(CommandCheck(arg1,"itemsinfo2")||CommandCheck(arg1,"iteminfo2"))
	{
		DoFwd_War3_Event(DoShowItems2InfoMenu,client);
		return returnblocking;
	}
	else if(CommandCheck(arg1,"itemsinfo3")||CommandCheck(arg1,"iteminfo3"))
	{
		DoFwd_War3_Event(DoShowItems3InfoMenu,client);
		return returnblocking;
	}
	else if(CommandCheck(arg1,"playerinfo"))
	{
		Handle array=CreateArray(300);
		PushArrayString(array,arg1);
		internal_W3SetVar(hPlayerInfoArgStr,array);
		DoFwd_War3_Event(DoShowPlayerinfoEntryWithArg,client);

		CloseHandle(array);
		return returnblocking;
	}
	else if(CommandCheck(arg1,"jobinfo")||CommandCheck(arg1,"raceinfo")||CommandCheck(arg1,"job"))
	{
		DoFwd_War3_Event(DoShowRaceinfoMenu,client);
		return returnblocking;
	}
	else if(CommandCheck(arg1,"mygold")||CommandCheck(arg1,"gold"))
	{
		War3_ChatMessage(client,"Gold: %i",GetPlayerProp(client, W3PlayerProp::PlayerGold));
		return returnblocking;
	}
	else if(CommandCheck(arg1,"mydiamonds")||CommandCheck(arg1,"diamonds")||CommandCheck(arg1,"diamond"))
	{
		War3_ChatMessage(client,"Diamonds: %i",War3_GetDiamonds(client));
		return returnblocking;
	}
	else if(CommandCheck(arg1,"speed"))
	{
		int ClientX=client;
		bool SpecTarget=false;
		if(GetClientTeam(client)==1) // Specator
		{
			if (!IsPlayerAlive(client))
			{
				ClientX = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
				if (ClientX == -1)  // if spectator target does not exist then...
				{
					//DP("Spec target does not exist");
					War3_ChatMessage(client,"While being spectator,\nYou must be spectating a player to get player's speed.");
					return returnblocking;
				}
				else
				{
					//DP("Spec target does Exist!");
					SpecTarget=true;
				}
			}
		}
		float currentmaxspeed=GetEntDataFloat(ClientX,FindSendPropInfo("CTFPlayer","m_flMaxspeed"));
		if(SpecTarget==true)
		{
			War3_ChatMessage(client,"%T (%.2fx)","Spectating target's max speed is {amount}",client,currentmaxspeed,W3GetSpeedMulti(ClientX));
		}
		else
		{
			War3_ChatMessage(client,"%T (%.2fx)","Your max speed is {amount}",client,currentmaxspeed,W3GetSpeedMulti(client));
		}
	}
	else if(CommandCheck(arg1,"maxhp"))
	{
		int maxhp = War3_GetMaxHP(client);
		War3_ChatMessage(client,"Your max health is: %d",maxhp);
	}
	if(GetRace(client)>0)
	{
		if(CommandCheck(arg1,"skillsinfo")||CommandCheck(arg1,"skl"))
		{
			W3ShowSkillsInfo(client);
			return returnblocking;
		}
		else if(CommandCheck(arg1,"resetskills"))
		{
			DoFwd_War3_Event(DoResetSkills,client);
			return returnblocking;
		}
		else if(CommandCheck(arg1,"spendskills"))
		{
			int race=GetRace(client);
			if(GetLevelsSpent(client,race)<War3_GetLevel(client,race))
			DoFwd_War3_Event(DoShowSpendskillsMenu,client);
			else
			War3_ChatMessage(client,"%T","You do not have any skill points to spend, if you want to reset your skills use resetskills",client);
			return returnblocking;
		}
		else if(CommandCheck(arg1,"shopmenu")||CommandCheck(arg1,"sh1"))
		{
			DoFwd_War3_Event(DoShowShopMenu,client);
			return returnblocking;
		}
		else if(CommandCheck(arg1,"shopmenu2")||CommandCheck(arg1,"sh2"))
		{
			DoFwd_War3_Event(DoShowShopMenu2,client);
			return returnblocking;
		}
		else if(CommandCheck(arg1,"shopmenu3")||CommandCheck(arg1,"sh3"))
		{
			DoFwd_War3_Event(DoShowShopMenu3,client);
			return returnblocking;
		}
		else if(CommandCheck(arg1,"levelbank"))
		{
			if(W3SaveEnabled())
			{
				DoFwd_War3_Event(DoShowLevelBank,client);
				return returnblocking;
			}
			else
			{
				W3SetLevelBank(client,30);
				DoFwd_War3_Event(DoShowLevelBank,client);
				return returnblocking;
			}
		}
		else if(CommandCheck(arg1,"war3rank"))
		{
			if(W3SaveEnabled())
			{
				DoFwd_War3_Event(DoShowWar3Rank,client);
			}
			else
			{
				War3_ChatMessage(client,"%T","This server does not save XP, feature disabled",client);
			}
			return returnblocking;
		}
		else if(CommandCheck(arg1,"war3stats"))
		{
			DoFwd_War3_Event(DoShowWar3Stats,client);
			return returnblocking;
		}
		else if(CommandCheck(arg1,"myinfo"))
		{
			internal_W3SetVar(EventArg1,client);
			DoFwd_War3_Event(DoShowPlayerInfoTarget,client);
			return returnblocking;
		}
		else if(CommandCheck(arg1,"buyprevious")||CommandCheck(arg1,"bp"))
		{
			War3_RestoreItemsFromDeath(client,true);
			return returnblocking;
		}
		else if(CommandCheck(arg1,"myitems"))
		{
			internal_W3SetVar(EventArg1,client);
			DoFwd_War3_Event(DoShowPlayerItemsOwnTarget,client);
			return returnblocking;
		}
		else if(CommandCheckStartsWith(arg1,"drop",sizeof(arg1)))
		{
			char arg3[2][16];
			int exnum=ExplodeString(arg1," ",arg3,2,64,true);
			if(exnum>1)
			{
				int itemid = internal_GetItemIdByShortname(arg3[1]);
				if(itemid>-1)
				{
					//drop shopmenu 1 item
					SetOwnsItem(client,itemid,false);
					War3_ChatMessage(client,"You dropped %s",arg3[1]);
					return returnblocking;
				}
				else
				{
					itemid = War3_GetItem2IdByShortname(arg3[1]);
					if(itemid>-1)
					{
						//drop shopmenu 2 item
						War3_SetOwnsItem2(client,itemid,false);
						War3_ChatMessage(client,"You dropped %s",arg3[1]);
						return returnblocking;
					}
				}
			}
			War3_ChatMessage(client,"Could not find any shopitem named %s",arg3[1]);
			return returnblocking;
		}
		else if(CommandCheckStartsWith(arg1,"gems",sizeof(arg1))||CommandCheckStartsWith(arg1,"myitems3",sizeof(arg1)))
		{
			char arg2[2][64];
			int exnum=ExplodeString(arg1," ",arg2,2,64,true);
			int found=0;
			if(exnum>1)
			{
				char name[128];
				for(int i=1;i<=MaxClients;i++)
				{
					if(ValidPlayer(i))
					{
						GetClientName(i,name,sizeof(name));
						if(StrContains(name,arg2[1],false)>-1)
						{
							found=i;
							break;
						}
					}
				}
			}
			if(found>0)
			{
				internal_W3SetVar(EventArg1,found);
				DoFwd_War3_Event(DoShowPlayerItems3OwnTarget,client);
			}
			else
			{
				internal_W3SetVar(EventArg1,client);
				DoFwd_War3_Event(DoShowPlayerItems3OwnTarget,client);
			}
			return returnblocking;
		}
		else if((top_num=CommandCheckEx(arg1,"war3top"))>0)
		{
			if(top_num>100) top_num=100;
			if(W3SaveEnabled())
			{
				internal_W3SetVar(EventArg1,top_num);
				DoFwd_War3_Event(DoShowWar3Top,client);
			}
			else
			{
				War3_ChatMessage(client,"%T","This server does not save XP, feature disabled",client);
			}
			return returnblocking;
		}
		else if(CommandCheckStartsWith(arg1,"saybank",sizeof(arg1)))
		{
			char sPlayerName[128];
			GetClientName(client,sPlayerName,sizeof(sPlayerName));
			War3_ChatMessage(0,"{green}%s {default}has {green}%d {default}gold on hand, {green}%d {default}gold in the bank, {green}%d {default}diamonds, and {green}%d {default}platinum.",sPlayerName,GetPlayerProp(client, W3PlayerProp::PlayerGold),War3_GetGoldBank(client),War3_GetDiamonds(client),War3_GetPlatinum(client));
			return returnblocking;
		}
		else if(CommandCheckStartsWith(arg1,"saygold",sizeof(arg1)))
		{
			char sPlayerName[128];
			GetClientName(client,sPlayerName,sizeof(sPlayerName));
			War3_ChatMessage(0,"{green}%s {default}has {green}%d {default}gold.",sPlayerName,GetPlayerProp(client, W3PlayerProp::PlayerGold));
			return returnblocking;
		}
		else if(CommandCheckStartsWith(arg1,"saydiamond",sizeof(arg1)))
		{
			char sPlayerName[128];
			GetClientName(client,sPlayerName,sizeof(sPlayerName));
			War3_ChatMessage(0,"{green}%s {default}has {green}%d {default}diamonds.",sPlayerName,War3_GetDiamonds(client));
			return returnblocking;
		}
		else if(CommandCheckStartsWith(arg1,"sayplatinum",sizeof(arg1)))
		{
			char sPlayerName[128];
			GetClientName(client,sPlayerName,sizeof(sPlayerName));
			War3_ChatMessage(0,"{green}%s {default}has {green}%d {default}platinum.",sPlayerName,War3_GetPlatinum(client));
			return returnblocking;
		}
		else if(CommandCheckStartsWith(arg1,"balance",sizeof(arg1))||CommandCheckStartsWith(arg1,"bank_balance",sizeof(arg1)))
		{
			char TmpWithDrawTime[256];
			War3_BankWithdrawTimeLeft(client,TmpWithDrawTime,sizeof(TmpWithDrawTime));
			War3_ChatMessage(client,"On hand: {green}%d {default}Gold. !balance: {green}%d {default}Gold. Please wait %s to withdraw",GetPlayerProp(client, W3PlayerProp::PlayerGold), War3_GetGoldBank(client), TmpWithDrawTime);
			return returnblocking;
		}
		else if(CommandCheckStartsWith(arg1,"deposit",sizeof(arg1)) || CommandCheckStartsWith(arg1,"bank_deposit",sizeof(arg1)))
		{
			int Amount=0;
			int secondArgument = FindCharInString(arg1,' ') + 1;
			if(secondArgument != 0)
			{
				if(StrContains(arg1[secondArgument], "all", false)==0)
				{
					Amount=GetPlayerProp(client, W3PlayerProp::PlayerGold);
				}
				else
				{
					Amount=StringToInt(arg1[secondArgument]);
				}

				if(Amount>0)
				{
					if(War3_DepositGoldBank(client,Amount))
					{
						War3_ChatMessage(client,"On hand: {green}%d {default}Gold. !balance: {green}%d {default}Gold.",GetPlayerProp(client, W3PlayerProp::PlayerGold), War3_GetGoldBank(client));
					}
				}
				else
				{
					War3_ChatMessage(client,"On hand: {green}%d {default}Gold. !balance: {green}%d {default}Gold. Please try !deposit 1",GetPlayerProp(client, W3PlayerProp::PlayerGold), War3_GetGoldBank(client));
				}
			}
			else
			{
				War3_ChatMessage(client,"On hand: {green}%d {default}Gold. !balance: {green}%d {default}Gold. Please try !withdraw 1",GetPlayerProp(client, W3PlayerProp::PlayerGold) ,War3_GetGoldBank(client));
			}
			return returnblocking;
		}
		else if(CommandCheckStartsWith(arg1,"withdraw",sizeof(arg1)))
		{
			//DP("%s ... [%s]",arg1,arg1[10]);
			int Amount=0;
			int secondArgument = FindCharInString(arg1,' ') + 1;
			if(secondArgument != 0)
			{
				if(StrContains(arg1[secondArgument], "all", false)==0)
				{
					Amount=W3GetMaxGold(99)-GetPlayerProp(client, W3PlayerProp::PlayerGold);
					if(Amount<=0)
					{
						War3_ChatMessage(client,"On hand: {green}%d {default}Gold. !balance: {green}%d {default}Gold.",GetPlayerProp(client, W3PlayerProp::PlayerGold), War3_GetGoldBank(client));
						return returnblocking;
					}
				}
				else
				{
					Amount=StringToInt(arg1[secondArgument]);
				}

				if(Amount>0)
				{
					if(War3_WithdrawGoldBank(client,Amount))
					{
						War3_ChatMessage(client,"On hand: {green}%d {default}Gold. !balance: {green}%d {default}Gold.",GetPlayerProp(client, W3PlayerProp::PlayerGold) ,War3_GetGoldBank(client));
					}
				}
				else
				{
					War3_ChatMessage(client,"On hand: {green}%d {default}Gold. !balance: {green}%d {default}Gold. Please try !withdraw 1",GetPlayerProp(client, W3PlayerProp::PlayerGold) ,War3_GetGoldBank(client));
				}
			}
			else
			{
				War3_ChatMessage(client,"On hand: {green}%d {default}Gold. !balance: {green}%d {default}Gold. Please try !withdraw 1",GetPlayerProp(client, W3PlayerProp::PlayerGold) ,War3_GetGoldBank(client));
			}
			return returnblocking;
		}
		char itemshort[100];
		int ItemsLoaded = totalItemsLoaded;
		for(int itemid=1;itemid<=ItemsLoaded;itemid++) {
			W3GetItemShortname(itemid,itemshort,sizeof(itemshort));
			if(CommandCheckStartsWith(arg1,itemshort,sizeof(arg1))&&!W3ItemHasFlag(itemid,"hidden")) {
				internal_W3SetVar(EventArg1,itemid);
				internal_W3SetVar(EventArg2,false); //dont show menu again
				if(CommandCheckStartsWith(arg1,"tome",sizeof(arg1)))
				{                                           //item is tome
					int multibuy;

					multibuy=StringToInt(arg1[4]);

					if (multibuy<=0)
						multibuy=1;


					if(multibuy>100)
						multibuy=100;

					internal_W3SetVar(EventArg3,multibuy);
					DoFwd_War3_Event(DoTriedToBuyItem,client);
					return returnblocking;
				}

				if(StrEqual(arg1,itemshort,false)){//item maybe tier2??
					internal_W3SetVar(EventArg1,itemid);
				}

				DoFwd_War3_Event(DoTriedToBuyItem,client);

				return returnblocking;
			}
		}
	}
	else
	{
		if(CommandCheck(arg1,"skillsinfo") ||
				CommandCheck(arg1,"skl") ||
				CommandCheck(arg1,"resetskills") ||
				CommandCheck(arg1,"spendskills") ||
				CommandCheck(arg1,"showskills") ||
				CommandCheck(arg1,"shopmenu") ||
				CommandCheck(arg1,"sh1") ||
				CommandCheck(arg1,"sh2") ||
				CommandCheck(arg1,"sh3") ||
				CommandCheck(arg1,"war3menu") ||
				CommandCheck(arg1,"w3s") ||
				CommandCheck(arg1,"war3rank") ||
				CommandCheck(arg1,"war3stats") ||
				CommandCheck(arg1,"levelbank")||
				CommandCheckEx(arg1,"war3top")>0)
		{
			if(W3IsPlayerXPLoaded(client))
			{
				War3_ChatMessage(client,"Select a race first!!");
				DoFwd_War3_Event(DoShowChangeRaceMenu,client);
			}
			return returnblocking;
		}
	}

	//return Plugin_Continue;
	return false;
}

public Action:War3Source_no_number_useitemCommand(client,args)
{
	if(MapChanging) return Plugin_Continue;

	if(War3SourcePause)
	{
		War3_ChatMessage(client,"%s is currently paused, please wait until %s resumes.",W3GAMETITLE,W3GAMETITLE);
		return Plugin_Continue;
	}

	char command[32];
	GetCmdArg(0,command,sizeof(command));

	bool pressed=false;

	if(StrContains(command,"+")>-1)
	pressed=true;
	Call_StartForward(p_OnUseItemCommand);
	Call_PushCell(client);
	Call_PushCell(0);
	Call_PushCell(pressed);
	int result;
	Call_Finish(result);

	return Plugin_Handled;
}

public printNotification(client,id)
{
	if (id==0)
		CPrintToChat(client,"{white}You have access to {orange}VIP chat! {white}Prefix your message with a {orange}\"#\"{white} to chat!");
	else if (id==1)
		CPrintToChat(client,"{white}You have access to {orange}community chat! {white}Prefix your message with a {orange}\"&\"{white} to chat!");
	else if (id==2)
		CPrintToChat(client,"{white}You have access to {orange}admin chat! {white}Prefix your message with a {orange}\"%s\"{white} to chat!","$");
	playerNotifications[client][id]=1;
}

public int Press_Ability(int client, int ability)
{
	if(MapChanging) return 1;

	if(War3SourcePause)
	{
		War3_ChatMessage(client,"%s is currently paused, please wait until %s resumes.",W3GAMETITLE,W3GAMETITLE);
		return 2;
	}
	if(IsInvis(client) || TF2_IsPlayerInCondition(client, TFCond_Bonked)) return 3;

	Call_StartForward(p_OnAbilityCommand);
	Call_PushCell(client);
	Call_PushCell(ability);
	Call_PushCell(true);
	Call_PushCell(false); // bypass ability restrictions
	int result;
	Call_Finish(result);
	return 0;
}

public int Press_Ultimate(int client)
{
	if(MapChanging) return 1;

	if(War3SourcePause)
	{
		War3_ChatMessage(client,"%s is currently paused, please wait until %s resumes.",W3GAMETITLE,W3GAMETITLE);
		return 2;
	}
	if(IsInvis(client) || TF2_IsPlayerInCondition(client, TFCond_Bonked)) return 3;

	Call_StartForward(p_OnUltimateCommand);
	Call_PushCell(client);
	Call_PushCell(GetRace(client));
	Call_PushCell(true);
	Call_PushCell(false); // bypass ultimate restrictions
	int result;
	Call_Finish(result);
	return 0;
}

public Action Listener_Voice(int client, const char[] command, int argc) {
	char arguments[4];
	GetCmdArgString(arguments, sizeof(arguments));

	if (StrEqual(arguments, "2 0")) {
		int ability = Press_Ability(client, 0);
		if(ability==1)
		{
			PrintToChat(client,"You pressed +ability, but the map is changing");
			return Plugin_Handled;
		}
		else if(ability==2)
		{
			PrintToChat(client,"You pressed +ability, but war3 is paused");
			return Plugin_Handled;
		}
		else if(ability==0)
		{
			PrintToChat(client,"You pressed +ability");
			return Plugin_Handled;
		}
	} else if (StrEqual(arguments, "2 1")) {
		int ability = Press_Ability(client, 2);
		if(ability==1)
		{
			PrintToChat(client,"You pressed +ability2, but the map is changing");
			return Plugin_Handled;
		}
		else if(ability==2)
		{
			PrintToChat(client,"You pressed +ability2, but war3 is paused");
			return Plugin_Handled;
		}
		else if(ability==0)
		{
			PrintToChat(client,"You pressed +ability2");
			return Plugin_Handled;
		}
	} else if (StrEqual(arguments, "2 3")) {
		int ultimate = Press_Ultimate(client);
		if(ultimate==1)
		{
			PrintToChat(client,"You pressed +ultimate, but the map is changing");
			return Plugin_Handled;
		}
		else if(ultimate==2)
		{
			PrintToChat(client,"You pressed +ultimate, but war3 is paused");
			return Plugin_Handled;
		}
		else if(ultimate==0)
		{
			PrintToChat(client,"You pressed +ultimate");
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}
