#ifndef LUMA_GAME_CB_STRUCTS
#define LUMA_GAME_CB_STRUCTS

#ifdef __cplusplus
#include "../../../Source/Core/includes/shader_types.h"
#endif

namespace CB
{
	struct LumaGameSettings
	{
		uint LensDistortion;
	};
	
	struct LumaGameData
	{
    	// Camera jitters in NCD space (based on the rendering resolution, but relative to the output resolution full range UVs, so apply these before "CV_HPosScale.xy")
    	// (not in projection matrix space, so they don't need to be divided by the rendering resolution). You might need to multiply this by 0.5 and invert the horizontal axis before using it, if it's targeting UV space.
    	float2 CameraJitters;
    	// Previous frame's camera jitters in NCD space (relative to its own resolution).
    	float2 PreviousCameraJitters;
#if 0
    	row_major float4x4 ViewProjectionMatrix;
    	row_major float4x4 PrevViewProjectionMatrix;
#endif
    	// Same as the one on "PostAA" "AA" but fixed to include jitters as well
    	row_major float4x4 ReprojectionMatrix;
	};
}

#endif // LUMA_GAME_CB_STRUCTS
