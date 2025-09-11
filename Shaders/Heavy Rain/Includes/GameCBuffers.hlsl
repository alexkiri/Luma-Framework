#ifndef LUMA_GAME_CB_STRUCTS
#define LUMA_GAME_CB_STRUCTS

#ifdef __cplusplus
#include "../../../Source/Core/includes/shader_types.h"
#endif

namespace CB
{
	struct LumaGameSettings
	{
		float2 InvRenderRes;
		float BloomAndLensFlareIntensity;
		float HDRBoostAmount;
		bool DrewTonemap;
	};
	
	struct LumaGameData
	{
    	float Dummy;
	};
}

#endif // LUMA_GAME_CB_STRUCTS
