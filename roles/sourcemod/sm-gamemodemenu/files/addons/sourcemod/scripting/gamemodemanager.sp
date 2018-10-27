#pragma semicolon 1

#include <sourcemod>

#define STRSIZE 64
#define SET_GAMETYPE "set_gametype"
#define CHANGE_MAP "change_map"
#define KICK_PLAYER "kick_player"
#define BAN_PLAYER "ban_player"

Menu g_MenuOptions = null;
Menu g_MenuGameMode = null;
Menu g_MenuChooseMap = null;

ConVar g_cvar_hostname;
ConVar g_cvar_randomize;
ConVar g_cvar_location;
ConVar g_cvar_defaultmode;

KeyValues g_ModeData;
char g_CurrentMode[STRSIZE];
char g_CurrentMap[STRSIZE];
char g_CurrentConfig[STRSIZE];

public Plugin myinfo = {
	name 		= "Game Mode Manager",
	author 		= "Zeus",
	description = "Changes the server to use a set of configs and maps, particularly useful for competitive",
	version 	= SOURCEMOD_VERSION,
	url 		= "https://github.com/scrims-tf/game-mode-manager-plugin"
};

public void OnPluginStart() {
	RegAdminCmd("sm_gamemodemenu", OpenMenu, ADMFLAG_CHANGEMAP);

	g_cvar_hostname = CreateConVar("sm_hostname", "TF2 Server");
	g_cvar_location = CreateConVar("sm_location", "Pyroland");
	g_cvar_randomize = CreateConVar("sm_randommaprotation", "0");
	g_cvar_defaultmode = CreateConVar("sm_defaultgamemode", "Death Match");

	g_cvar_hostname.AddChangeHook(CvarHandler_Hostname);
	g_cvar_location.AddChangeHook(CvarHandler_Hostname);

	AutoExecConfig(true, "gamemodemanager");

	//Default mode, choose random map
	g_ModeData = new KeyValues("Modes");
	g_ModeData.ImportFromFile("gamemodes.ini");

	g_cvar_defaultmode.GetString(g_CurrentMode, sizeof(g_CurrentMode));
	setHostname();
	changeMap(getRandomMap(g_ModeData, "Death Match"));
}

public void OnMapStart() {
	g_MenuOptions = Menu_Options();

	if (strlen(g_CurrentMode) != 0 && strlen(g_CurrentConfig) != 0){
		ServerCommand("exec \"%s\"", g_CurrentConfig);
		setHostname();

		if (true){
			char map[STRSIZE];
			char mapfile[STRSIZE];

			map = getRandomMap(g_ModeData, g_CurrentMode);
			mapfile = getModeMapName(g_ModeData, g_CurrentMode, map);
			ServerCommand("sm_nextmap \"%s\"", mapfile);

		}
	}
}

public void OnMapEnd() {
	if (g_MenuOptions != null) {
		delete(g_MenuOptions);
		g_MenuOptions = null;
	}
	if (g_MenuGameMode != null) {
		delete(g_MenuGameMode);
		g_MenuGameMode = null;
	}
	if (g_MenuChooseMap != null) {
		delete(g_MenuChooseMap);
		g_MenuChooseMap = null;
	}
}

public Action OpenMenu(int client, int args) {
	if (g_ModeData != null) {
		g_ModeData = null;
	}

	g_ModeData = new KeyValues("Modes");
	g_ModeData.ImportFromFile("gamemodes.ini");

	if (g_MenuOptions == null) {
		PrintToConsole(client, "Options menu failed to load!");
		return Plugin_Handled;
	}

	g_MenuOptions.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

Menu Menu_Options(){
	Menu menu = new Menu(MenuHandler_Options);
	menu.SetTitle("Game Mode Options");
	menu.AddItem(SET_GAMETYPE, "Set Game Mode");
	menu.AddItem(CHANGE_MAP, "Change Map");

	return menu;
}

Menu Menu_GameMode() {
	Menu menu = new Menu(MenuHandler_GameMode);
	menu.SetTitle("Set Game Mode");

	ArrayList modes = getModes(g_ModeData);
	for (int i=0; i < modes.Length; i++) {
		char mode[STRSIZE];
		modes.GetString(i, mode, sizeof(mode));
		menu.AddItem(mode, mode);
	}

	return menu;
}

Menu Menu_ChooseMap() {
	Menu menu = new Menu(MenuHandler_ChooseMap);
	menu.SetTitle("Choose Map");
	menu.AddItem("random", "Random");

	ArrayList maps = getModeMaps(g_ModeData, g_CurrentMode);
	for (int i=0; i < maps.Length; i++) {
		char map[STRSIZE];
		maps.GetString(i, map, sizeof(map));
		menu.AddItem(map, map);
	}

	return menu;
}

public int MenuHandler_Options(Menu menu, MenuAction action, int client, int item) {
	if (action == MenuAction_Select){
		char info[STRSIZE];

		menu.GetItem(item, info, sizeof(info));

		if (StrEqual(info, SET_GAMETYPE)) {
			delete g_MenuGameMode;

			g_MenuGameMode = Menu_GameMode();
			g_MenuGameMode.Display(client, MENU_TIME_FOREVER);
		}
		else if (StrEqual(info, CHANGE_MAP)) {
			delete g_MenuChooseMap;

			g_MenuChooseMap = Menu_ChooseMap();
			g_MenuChooseMap.Display(client, MENU_TIME_FOREVER);
		}

	}
}

public int MenuHandler_GameMode(Menu menu, MenuAction action, int client, int item) {
	if (action == MenuAction_Select){
		char info[STRSIZE];
		menu.GetItem(item, info, sizeof(info));
		g_CurrentMode = info;
		PrintToChatAll("Game mode set to \"%s\"", g_CurrentMode);

		delete g_MenuChooseMap;
		g_MenuChooseMap = Menu_ChooseMap();
		g_MenuChooseMap.Display(client, MENU_TIME_FOREVER);

	}
}

public int MenuHandler_ChooseMap(Menu menu, MenuAction action, int client, int item) {
	if (action == MenuAction_Select){
		char map[STRSIZE];

		menu.GetItem(item, map, sizeof(map));

		if (StrEqual(map, "random")) {
			changeMap(getRandomMap(g_ModeData, g_CurrentMode));
		}
		else {
			changeMap(map);
		}
	}
	return 0;
}

public int CvarHandler_Hostname(ConVar convar, const char[] oldValue, const char[] newValue) {
	setHostname();
}

ArrayList getModes(KeyValues kv) {
	ArrayList modes = new ArrayList(STRSIZE);
	kv.GotoFirstSubKey();

	do {
		char gamemode[STRSIZE];
		kv.GetSectionName(gamemode, sizeof(gamemode));
		modes.PushString(gamemode);

	} while(kv.GotoNextKey());

	kv.Rewind();
	return modes;
}

ArrayList getModeMaps(KeyValues kv, char[] mode) {
	ArrayList maps = new ArrayList(STRSIZE);
	kv.JumpToKey(mode, false);
	kv.JumpToKey("maps", false);
	kv.GotoFirstSubKey();

	do {
		char map[STRSIZE];
		kv.GetSectionName(map, sizeof(map));
		maps.PushString(map);
	} while(kv.GotoNextKey());

	SortADTArray(maps, Sort_Ascending, Sort_String);
	kv.Rewind();
	return maps;
}

char[] getModeMapConfig(KeyValues kv, char[] mode, char[] map) {
	char config[STRSIZE];

	kv.JumpToKey(mode, false);
	kv.JumpToKey("maps", false);
	kv.JumpToKey(map, false);

	kv.GetString("config", config, sizeof(config));

	kv.Rewind();
	return config;
}

char[] getModeMapName(KeyValues kv, char[] mode, char[] map) {
	char mapname[STRSIZE];

	kv.JumpToKey(mode, false);
	kv.JumpToKey("maps", false);
	kv.JumpToKey(map, false);

	kv.GetString("map", mapname, sizeof(mapname));

	kv.Rewind();
	return mapname;
}

char[] getRandomMap(KeyValues kv, char[] mode) {
	char map[STRSIZE];
	char mapfile[STRSIZE];

	ArrayList maps = getModeMaps(kv, mode);
	while (!IsMapValid(mapfile)) {
		int randIdx = GetRandomInt(0, maps.Length - 1);
		maps.GetString(randIdx, map, sizeof(map));
		mapfile = getModeMapName(kv, mode, map);

		maps.Erase(randIdx);

		if (maps.Length == 0){
			mapfile = "NO VALID MAPS";
			return mapfile;
		}
	}

	return map;
}

bool changeMap(char[] map) {
	char mapfile[STRSIZE];
	mapfile = getModeMapName(g_ModeData, g_CurrentMode, map);

	if (!IsMapValid(mapfile)) {
		PrintToChatAll("Cannot change to \"%s\", map not available on this server.", mapfile);
		return false;
	}

	g_CurrentMap = mapfile;
	g_CurrentConfig = getModeMapConfig(g_ModeData, g_CurrentMode, map);

	PrintToChatAll("Changing current map to \"%s\"", map);
	ServerCommand("exec \"%s\"", g_CurrentConfig);
	ServerCommand("changelevel \"%s\"", g_CurrentMap);

	return true;
}

bool setHostname() {
	char hostname[STRSIZE];
	char location[STRSIZE];

	g_cvar_hostname.GetString(hostname, sizeof(hostname));
	g_cvar_location.GetString(location, sizeof(hostname));

	ServerCommand("hostname \"%s | %s | %s\"", hostname, g_CurrentMode, location);
}

