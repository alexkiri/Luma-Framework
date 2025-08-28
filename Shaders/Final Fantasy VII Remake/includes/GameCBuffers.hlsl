#ifndef LUMA_GAME_CB_STRUCTS
#define LUMA_GAME_CB_STRUCTS

#ifdef __cplusplus
#include "../../../Source/Core/includes/shader_types.h"
#endif

namespace CB
{
	struct LumaGameSettings
	{
		uint Sharpen;
	};
	
	struct LumaGameData
	{
        float4 RenderResolution;
        float4 OutputResolution;
		uint4 ViewportRect;
		float2 ResolutionScale; //Scale, InvScale
		uint DrewUpscaling;
	};
}

#endif // LUMA_GAME_CB_STRUCTS
