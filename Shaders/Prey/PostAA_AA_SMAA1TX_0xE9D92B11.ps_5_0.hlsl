#include "PostAA_AA.hlsl"

#define _RT_SAMPLE2 1

// PostAA_PS
// Shader used by SMAA 1TX. SMAA 1TX does not use jittered rendering so it doesn't have to acknowledge jitters anywhere.
// Luma's changes here are mostly mirrored in SMAA 1TX and 2TX.
void main(
  float4 inWPos : SV_Position0,
  float2 inBaseTC : TEXCOORD0,
  // "1 / CV_HPosScale.xy"
  nointerpolation float2 inBaseTCScale : TEXCOORD1,
  out float4 outColor : SV_Target0)
{
#if 0 // We don't need this here as neither SMAA 1TX nor FXAA use camera jitters in their rendering path, so there's no point in replacing them with DLSS really, it wouldn't look better than the current native AA
	if (LumaSettings.SRType > 0)
	{
		uint3 pixelCoord = int3(inWPos.xy, 0);
		const float depth = PostAA_DeviceDepthTex.Load(pixelCoord).r;
		const float2 currTC = inBaseTC.xy;
		float2 prevTC = CalcPreviousTC(currTC, depth);
		float2 velocity = prevTC - currTC;
		float2 vObj = PostAA_VelocityObjectsTex.Load(pixelCoord);
		if (vObj.x != 0 || vObj.y != 0)
		{
			velocity = ReadVelocityObjects(vObj);
			velocity /= LumaData.RenderResolutionScale;
		}
		outColor.xy = velocity;
		outColor.zw = 0;
		return;
	}
#endif

	bool skipAA = ShouldSkipPostProcess(inWPos.xy, 1);
#if !ENABLE_AA || !ENABLE_TAA
	skipAA = true;
#endif
	if (skipAA)
	{
		outColor	= SampleCurrentScene(inBaseTC.xy * CV_HPosScale.xy);
		return;
	}
	
	uint3 pixelCoord = int3(inWPos.xy, 0);
	
	// Compute velocity vector for static geometry
	const float depth = PostAA_DeviceDepthTex.Load(pixelCoord).r;

	const float2 currTC = inBaseTC.xy;
	const float2 prevTC = CalcPreviousTC(currTC, depth);

	// currTC and prevTC are in clip space

	float2 diff = prevTC - currTC;

	float2 vObj = PostAA_VelocityObjectsTex.Load(pixelCoord);
	// LUMA FT: we never need to dejitter MVs with SMAA 1TX does not use jitters to begin with. See "FORCE_MOTION_VECTORS_JITTERED" for more detail.
	if (vObj.x != 0 || vObj.y != 0)
	{
		diff = ReadVelocityObjects(vObj); // clip space
		diff /= LumaData.RenderResolutionScale;
	}

	const float2 tc  = currTC * CV_HPosScale.xy; // MapViewportToRaster()
	const float2 tcp = (currTC + diff) * CV_HPosScale.zw;

#if _RT_SAMPLE2
	// SMAA 1TX Mode
	float fMaxFramesL = cbPostAA.params.z;		// Frames to keep in history (low freq). Higher = less aliasing, but blurier result. Lower = sharper result, but more aliasing.
	float fMaxFramesH = cbPostAA.params.w;		// Frames to keep in history (high freq). Higher = less aliasing, but blurier result. Lower = sharper result, but more aliasing.
	
 	// Curr frame and neighbor texels
	float3 cM	= DecodeBackBufferToLinearSDRRange(SampleCurrentScene(tc).rgb);
	float3 cTL = DecodeBackBufferToLinearSDRRange(SampleCurrentScene(tc, float2(-0.5f, -0.5f)).rgb);
	float3 cTR = DecodeBackBufferToLinearSDRRange(SampleCurrentScene(tc, float2( 0.5f, -0.5f)).rgb);
	float3 cBL = DecodeBackBufferToLinearSDRRange(SampleCurrentScene(tc, float2(-0.5f,  0.5f)).rgb);
	float3 cBR = DecodeBackBufferToLinearSDRRange(SampleCurrentScene(tc, float2( 0.5f,  0.5f)).rgb);
	
	float3 cBlur = (cTL + cTR + cBL + cBR) * 0.25f;
  	float sharpenAmount = cbPostAA.params.x;
#if !ENABLE_SHARPENING || POST_TAA_SHARPENING_TYPE <= 0
  	sharpenAmount = min(sharpenAmount, 1.0);
#endif
	const float3 preSharpenColor = cM;
	cM.rgb = lerp(cBlur, cM, sharpenAmount); // LUMA FT: removed saturate(), it wasn't necessary (this is just sharpening)
	cM.rgb = FixUpSharpeningOrBlurring(cM.rgb, preSharpenColor);

	float3 cMin = min3(min3(cTL, cTR, cBL), cBR, cM);
	float3 cMax = max3(max3(cTL, cTR, cBL), cBR, cM);
	
	float3 cAcc = DecodeBackBufferToLinearSDRRange( SamplePreviousScene(tcp).rgb );
	cAcc.rgb = clamp(cAcc, cMin, cMax); // Limit acc buffer color range to current frame
	
#if 1 // LUMA FT: Changed the high frequency abs diff from applying an (approximate) gammification formula after diffing instead of what we had before. Also added a saturate() for safety as in SDR it couldn't be more than 1
	float3 cHiFreq = saturate(abs(EncodeBackBufferFromLinearSDRRange(cBlur.rgb) - EncodeBackBufferFromLinearSDRRange(cM.rgb)));
#else
	float3 cHiFreq = sqrt(abs(cBlur.rgb - cM.rgb));
#endif
	outColor.rgb = EncodeBackBufferFromLinearSDRRange( lerp(cAcc, cM, saturate(rcp(lerp(fMaxFramesL, fMaxFramesH, cHiFreq))) ) ); // LUMA FT: improved in/out linearization
#if 0 // LUMA FT: disabled for performance
	outColor.a = 1-saturate(rcp(lerp(fMaxFramesL, fMaxFramesH, cHiFreq))); // debug output
#else
	outColor.a = 0;
#endif
#endif
}