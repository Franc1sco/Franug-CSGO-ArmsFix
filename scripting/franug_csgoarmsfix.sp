#include <sourcemod>
#include <sdktools>
#include <dhooks>

Handle hPrecacheModel = null;

public Plugin:myinfo = 
{
	name = "SM model precache block for ArmsFix",
	author = "Franc1sco franug",
	description = "",
	version = "1.0",
	url = "http://steamcommunity.com/id/franug"
};

public void OnPluginStart()
{
	Handle hGameConf;
	
	hGameConf = LoadGameConfigFile("armsfix.games");
	if(hGameConf == INVALID_HANDLE)
		SetFailState("Gamedata file armsfix.games.txt is missing.");
	int iOffset;
	
	
	iOffset = GameConfGetOffset(hGameConf, "Precache");
	if(iOffset == -1)
	{
		SetFailState("Failed to find offset for Precache");
		delete hGameConf;
	}
	
	StartPrepSDKCall(SDKCall_Static);
	
	if(!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CreateInterface"))
	{
		SetFailState("Failed to get CreateInterface");
		delete hGameConf;
	}
	
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	
	char identifier[64];
	if(!GameConfGetKeyValue(hGameConf, "EngineInterface", identifier, sizeof(identifier)))
	{
		SetFailState("Failed to get engine identifier name");
		delete hGameConf;
	}
	
	Handle temp = EndPrepSDKCall();
	Address addr = SDKCall(temp, identifier, 0);
	
	delete hGameConf;
	delete temp;
	
	if(!addr)
		SetFailState("Failed to get engine ptr");
	
	hPrecacheModel = DHookCreate(iOffset, HookType_Raw, ReturnType_Int, ThisPointer_Ignore, Hook_PrecacheModel);
	DHookAddParam(hPrecacheModel, HookParamType_CharPtr);
	DHookAddParam(hPrecacheModel, HookParamType_Bool);
	DHookRaw(hPrecacheModel, false, addr);
}

public MRESReturn Hook_PrecacheModel(Handle hParams)
{
	char buffer[128];
	DHookGetParamString(hParams, 1, buffer, 128);
	
	if(StrContains(buffer, "models/weapons/v_models/arms/glove_hardknuckle/") != -1)
	{
		// block this model for be precached
		return MRES_Supercede;
	}
	return MRES_Ignored;
}