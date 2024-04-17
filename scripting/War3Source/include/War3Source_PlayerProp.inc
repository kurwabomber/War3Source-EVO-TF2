// IMPORTANT: TO ADD MORE TO THIS LIST, ADD TO THE BOTTOM!

//Basically Instance variables for the Player Class
enum struct W3PlayerProp
{
	bool bPutInServer;
	int CurrentRace;
	int PendingRace;
	int PlayerGold;
	int PlayerDiamonds;//REMOVE PlayerDiamonds; //DRPECE
	int iMaxHP;
	int bIsDucking;

	int JoinDate;

	bool xpLoaded;
	bool talentsLoaded;
	float RaceChosenTime;
	bool RaceSetByAdmin;
	bool SpawnedOnce; //if player has spawned once
	float sqlStartLoadXPTime;

	bool isDeveloper;
	bool isOfficalW3E;
	float LastChangeTeamTime;
	bool bStatefulSpawn; //set true if spawn is a non repeated spawn. set to true on join and death; set false after spawn forward is finished.
	int iGoldDiamondHud;   // Player preferences (Gold Hud on / off)
	bool dbRaceSelected; //used in spawn camper.
	int PlayerPlatinum;
	int iBuffChatInfo; // Player preferences (Detailed Buff messages)
	int iDetailedOnDeathMsgs; // Player preferences (Detailed Buff messages)
	int iBuffChatInfo2; // Player preferences (Detailed Buff messages)
	int iIntroSong; // Player preferences
	int iSaySounds; // Player preferences
	int iHlstatsx;
	int iAutoBuyMaxGoldItem;
	int iServerAds;
	int iIrcCrossServerChat;
	int iFragRadio;
	int iRotateHUD;
	int iChatText;
	int iCombatMessages;
	int iAdminSecurityExtra;
	//iTomeCount;
	//iAutoBuyMaxGoldItem;
	int iGraphics;
#if GGAMETYPE == GGAME_TF2
	TFClassType CurrentClass
#endif
}

native int W3SetPlayerProp(int client,any property,any value);
native any W3GetPlayerProp(int client,any property);

