#ifndef LUMA_GAME_SETTINGS_CB_STRUCT
#define LUMA_GAME_SETTINGS_CB_STRUCT

#ifdef __cplusplus
// This include is needed to allow reading shader types from c++.
#include "../../../Source/Core/includes/shader_types.h"
#endif


// Mirrors c++ name spaces.
namespace CB
{
	// Define the game specific cbuffer settings here
	struct LumaGameSettings
	{
		float GameSetting01;
		uint GameSetting02;
	};
}

#endif // LUMA_GAME_SETTINGS_CB_STRUCT
