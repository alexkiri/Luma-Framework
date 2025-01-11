#include "include/ColorGradingLUT.hlsl" // Use this as it has some gamma correction helpers

Texture2D<float4> sourceTexture : register(t0); //TODOFT: rename to scene and call this final shader?
Texture2D<float4> uiTexture : register(t1); // Pre-multiplied UI
Texture2D<float4> debugTexture : register(t2);

// Custom Luma shader to apply the display (or output) transfer function from a linear input (or apply custom gamma correction)
float4 main(float4 pos : SV_Position0) : SV_Target0
{
	// Generic paper white for when we can't account for the UI paper white
	const float paperWhite = LumaSettings.GamePaperWhiteNits / sRGB_WhiteLevelNits;

#if DEVELOPMENT
	float debugWidth;
	float debugHeight;
	debugTexture.GetDimensions(debugWidth, debugHeight);
	// Skip if there's no texture. It might be undefined behaviour, but it seems to work on Nvidia
	if (debugWidth != 0 && debugHeight != 0)
    {
		float2 resolutionScale = 1.0;
		bool fullscreen = (LumaData.CustomData2 & (1 << 0)) != 0;
        bool renderResolutionScale = (LumaData.CustomData2 & (1 << 1)) != 0;
        bool showAlpha = (LumaData.CustomData2 & (1 << 2)) != 0;
        bool premultiplyAlpha = (LumaData.CustomData2 & (1 << 3)) != 0;
		bool invertColors = (LumaData.CustomData2 & (1 << 4)) != 0;
        bool gammaToLinear = (LumaData.CustomData2 & (1 << 5)) != 0;
        bool linearToGamma = (LumaData.CustomData2 & (1 << 6)) != 0;
        bool flipY = (LumaData.CustomData2 & (1 << 7)) != 0;
		bool backgroundPassthrough = false;

		if (fullscreen) // Stretch to fullscreen
		{
			float targetWidth;
			float targetHeight;
			sourceTexture.GetDimensions(targetWidth, targetHeight);
			resolutionScale = float2(debugWidth / targetWidth, debugHeight / targetHeight);
		}
		if (renderResolutionScale) // Scale by rendering resolution
		{
			resolutionScale *= LumaData.RenderResolutionScale;
		}
		
		if (flipY)
		{
			pos.y = debugHeight - pos.y;
		}

		pos.xy = round((pos.xy - 0.5) * resolutionScale) + 0.5;
		bool validTexel = pos.x < debugWidth && pos.y < debugHeight;
		float4 color = debugTexture.Load((int3)pos.xyz); // We don't have a sampler here so we just approimate to the closest texel

		if (showAlpha)
		{
			color.rgb = color.a;
		}
		if (premultiplyAlpha)
		{
			color.rgb *= color.a;
		}
		if (invertColors) // Only works on in SDR range
		{
			color.rgb = 1.0 - color.rgb;
		}
		if (gammaToLinear) // Linearize (output expects linear)
		{
        	color.rgb = pow(abs(color.rgb), 2.2f) * sign(color.rgb);
		}
		if (linearToGamma) // Gammify (usually not necessary)
		{
       		color.rgb = pow(abs(color.rgb), 1.f / 2.2f) * sign(color.rgb);
		}
		if (validTexel || !backgroundPassthrough)
		{
			return color * paperWhite; // Scale by user paper white brightness just to make it more visible
		}
    }
#endif

#if 0 // TEST: zoom into the image to analyze it
	float targetWidth;
	float targetHeight;
	sourceTexture.GetDimensions(targetWidth, targetHeight);
	pos.xy = pos.xy / 2.0 + float2(targetWidth, targetHeight) / 4.0;
#endif

	float4 color = sourceTexture.Load((int3)pos.xyz);

	// This case means the game currently doesn't have Luma custom shaders built in (fallback in case of problems), or manually unloaded, so the value of most macro defines doesn't matter (we don't want it to)
	if (LumaData.CustomData1 != 0)
	{
		// SDR (on SDR)
		if (LumaSettings.DisplayMode <= 0)
		{
			color.rgb = gamma_sRGB_to_linear(color.rgb, GCT_SATURATE);
		}
		// HDR (we assume this is the default case for Luma users/devs, this isn't an officially supported case anyway)
		else
		{
			// Forcefully linearize with gamma 2.2 outside of a dev environment (gamma correction) (the default setting)
#if GAMMA_CORRECTION_TYPE <= 0 && DEVELOPMENT
			color.rgb = gamma_sRGB_to_linear(color.rgb, GCT_MIRROR);
#else // GAMMA_CORRECTION_TYPE >= 1
			color.rgb = gamma_to_linear(color.rgb, GCT_MIRROR);
#endif // GAMMA_CORRECTION_TYPE <= 0
			if (LumaSettings.DisplayMode >= 2)
				color.rgb = saturate(color.rgb);
			color.rgb *= paperWhite;
		}
		return float4(color.rgb, color.a);
	}
	
#if 0
	// Blend in UI
    const float gamePaperWhite = LumaSettings.GamePaperWhiteNits / sRGB_WhiteLevelNits;
    const float UIPaperWhite = LumaSettings.UIPaperWhiteNits / sRGB_WhiteLevelNits;
	float3 sceneColorGamma = linear_to_gamma(color.rgb, GCT_MIRROR);
	float3 uiRelativeColor = color.rgb * (gamePaperWhite / UIPaperWhite);
    float3 sceneColorGammaTonemapped = linear_to_gamma((uiRelativeColor / (uiRelativeColor + 1.f)) / (gamePaperWhite / UIPaperWhite), GCT_MIRROR); // Tonemap the UI background based on the UI intensity to avoid bright backgrounds (e.g. sun) burning through the UI
	float3 UIInverseInfluence = 1.0;
	float4 UIColor = uiTexture.Load((int3)pos.xyz);
    float UIIntensity = saturate(UIColor.a);
	sceneColorGamma *= pow(gamePaperWhite, 1.0 / 2.2);
	sceneColorGammaTonemapped *= pow(gamePaperWhite, 1.0 / 2.2);
	UIColor.rgb *= pow(UIPaperWhite, 1.0 / 2.2);
	// Darken the scene background based on the UI intensity
	float3 composedColor = lerp(sceneColorGamma, sceneColorGammaTonemapped, UIIntensity) * (1.0 - UIIntensity);
    // Calculate how much the additive UI influenced the darkened scene color, so we can determine the intensity to blend the composed color with the scene paper white (it's better to calculate this in gamma space)
	UIInverseInfluence = safeDivision(composedColor, composedColor + UIColor.rgb, 1); //TODO: handle negative colors?
	// Add pre-multiplied UI
	composedColor += UIColor.rgb;
	
	float3 compositionPaperWhite = lerp(pow(UIPaperWhite, 1.0 / 2.2), pow(gamePaperWhite, 1.0 / 2.2), UIInverseInfluence);
	composedColor /= compositionPaperWhite;

  	color.rgb = gamma_to_linear(composedColor, GCT_MIRROR) * pow(compositionPaperWhite, 2.2);
#endif

	// SDR: In this case, paper white (game and UI) would have been 80 nits (neutral for SDR, thus having a value of 1)
	if (LumaSettings.DisplayMode <= 0)
	{
		color.rgb = saturate(color.rgb); // Optional, but saves performance on the gamma pows below (the vanilla SDR tonemapper might have retained some values beyond 1 so we want to clip them anyway, for a "reliable" SDR look)

#if POST_PROCESS_SPACE_TYPE == 1
		// Revert whatever gamma adjustment "GAMMA_CORRECTION_TYPE" would have made, and get the color is sRGB gamma encoding (which would have been meant for 2.2 displays)
		color.rgb = linear_to_game_gamma(color.rgb, false);
#endif // POST_PROCESS_SPACE_TYPE == 1

		// In SDR, we ignore "GAMMA_CORRECTION_TYPE" as they are not that relevant
		// We are target the gamma 2.2 look here, which would likely match the average SDR screen, so
		// we linearize with sRGB because scRGB HDR buffers (Luma) in SDR are re-encoded with sRGB and then (likely) linearized by the display with 2.2, which would then apply the gamma correction.
		// For any user that wanted to play in sRGB, they'd need to have an sRGB monitor.
		// We could theoretically add a mode that fakes sRGB output on scRGB->2.2 but it wouldn't really be useful as the game was likely designed for 2.2 displays (unconsciously).
		color.rgb = gamma_sRGB_to_linear(color.rgb, GCT_NONE);
	}
	// HDR and SDR in HDR: in this case the UI paper white would have already been mutliplied in, relatively to the game paper white, so we only apply the game paper white.
	else if (LumaSettings.DisplayMode == 1 || LumaSettings.DisplayMode >= 2)
	{
#if POST_PROCESS_SPACE_TYPE != 1 // Gamma->Linear space

		// At this point, in this case, the color would have been sRGB gamma space, normalized around SDR range (80 nits paper white).

#if GAMMA_CORRECTION_TYPE != 0 && 1 // Apply gamma correction only in the 0-1 range (generally preferred as anything beyond the 0-1 range was never seen and the consequence of correcting gamma on it would be random and extreme)

		color.rgb = ColorGradingLUTTransferFunctionOutCorrected(color.rgb, LUT_EXTRAPOLATION_TRANSFER_FUNCTION_SRGB, GAMMA_CORRECTION_TYPE);
		
#else // GAMMA_CORRECTION_TYPE == 0 // Apply gamma correction around the whole range (alternative branch)

#if GAMMA_CORRECTION_TYPE >= 2
  		color.rgb = RestoreLuminance(gamma_sRGB_to_linear(color.rgb, GCT_MIRROR), gamma_to_linear(color.rgb, GCT_MIRROR));
#elif GAMMA_CORRECTION_TYPE == 1
		color.rgb = gamma_to_linear(color.rgb, GCT_MIRROR);
#else // GAMMA_CORRECTION_TYPE <= 0
  		color.rgb = gamma_sRGB_to_linear(color.rgb, GCT_MIRROR);
#endif // GAMMA_CORRECTION_TYPE >= 2

#endif // GAMMA_CORRECTION_TYPE != 0 && 1
		
		color.rgb *= paperWhite;

// The "GAMMA_CORRECTION_TYPE >= 2" type was always delayed until the end and treated as sRGB gamma before.
// We originally applied this gamma correction directly during tonemapping/grading and other later passes,
// but given that the formula is slow to execute and isn't easily revertible
// (mirroring back and forth is lossy, at least in the current lightweight implementation),
// we moved it to a single application here (it might not look as good but it's certainly good enough).
// Any linear->gamma->linear encoding (e.g. "PostAAComposites") or linear->gamma->luminance encoding (e.g. Anti Aliasing)
// should fall back on gamma 2.2 instead of sRGB for this gamma correction type, but we haven't bothered implementing that (it's not worth it).
#elif GAMMA_CORRECTION_TYPE >= 2 // Linear->Linear space (POST_PROCESS_SPACE_TYPE == 1)

		// Implement the "GAMMA_CORRECTION_TYPE == 2" case, thus convert from sRGB to sRGB with 2.2 luminance.
		// Doing this is here is a bit late, as we can't acknowledge the UI brightness at this point, though that's not a huge deal.
		// Any other "POST_PROCESS_SPACE_TYPE == 1" case would already have the correct(ed) gamma at this point.
		color.rgb /= paperWhite;
   		float3 colorInExcess = color.rgb - saturate(color.rgb); // Only correct in the 0-1 range
		color.rgb = saturate(color.rgb);
#if 1 // This code mirrors "game_gamma_to_linear()"
		float3 gammaCorrectedColor = gamma_to_linear(linear_to_sRGB_gamma(color.rgb));
#else
		float gammaCorrectedColor = gamma_to_linear1(linear_to_sRGB_gamma1(GetLuminance(color.rgb))); // "gammaCorrectedLuminance"
#endif
		color.rgb = RestoreLuminance(color.rgb, gammaCorrectedColor);
		color.rgb += colorInExcess;
		color.rgb *= paperWhite;

#endif // POST_PROCESS_SPACE_TYPE != 1

#if 0 // Optionally clip in SDR to properly emulate SDR
		if (LumaSettings.DisplayMode == 2)
			color.rgb = saturate(color.rgb / paperWhite) * paperWhite;
#endif
	}

	//TODO LUMA: add "FixColorGradingLUTNegativeLuminance()" call here? It's not really needed until proven otherwise (we should never have negative luminances, no code can generate them (?)).
	//Either way this shader doesn't always run and there's stuff that optionally runs before this, like sharpening (which can randomly affect luminance as it's by channel).

#if 0 // Test
	color.rgb = float3(1, 0, 0);
#endif

	return float4(color.rgb, color.a);
}