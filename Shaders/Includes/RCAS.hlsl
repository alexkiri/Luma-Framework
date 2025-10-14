#ifndef SRC_RCAS_HLSL
#define SRC_RCAS_HLSL

// RCAS (Robust Contrast-Adaptive Sharpening) 
// https://github.com/GPUOpen-Effects/FidelityFX-FSR2?tab=readme-ov-file#robust-contrast-adaptive-sharpening-rcas
// 
// Our implementation is based on: "https://github.com/cdozdil/OptiScaler/blob/master/OptiScaler/shaders/rcas/precompile/rcas.hlsl",
// which is in turn based on: "https://github.com/RdenBlaauwen/RCAS-for-ReShade",
// which is in turn based on AMD FSR 1 RCAS: https://github.com/GPUOpen-Effects/FidelityFX-FSR/blob/master/ffx-fsr/ffx_fsr1.h

// Try to detect noise or grain and not over sharpen it. This seemengly assumes the input is in the SDR 0-1 range.
#ifndef RCAS_DENOISE
#define RCAS_DENOISE 0
#endif
// Lower means less artifacts and "less sharpening", it's unclear what 16 stands for here, and whether this is meant for linear or gamma space (probably gamma space)
// This is set at the limit of providing unnatural results for sharpening (anything more generates artifacts).
#ifndef RCAS_LIMIT
#define RCAS_LIMIT (0.25-(1.0/16.0))
#endif
// This should look better, avoid hue shifts and be more compatible with HDR (scRGB, which can have negative values). This appears to have stronger sharpening when enabled, but also causes more black dots to appear at extreme sharpening values.
// For now it's disabled by default as there's not enough proof to justify it, sharpening is a perceptual trick so hue shifts don't really matter (in fact, possibly they make it better).
#define RCAS_LUMINANCE_BASED 0

float getRCASLuma(float3 rgb)
{
#if 0 // LUMA FT: changed to use the proper Rec.709 luminance formula (but multiplied by 2 as the sum of the original RCAS formula is 2)
    return GetLuminance(rgb) * 2;
#else
    return dot(rgb, float3(0.5, 1.0, 0.5));
#endif
}

// Pass in a linear (or perceptual space color).
// The color range is roughly expected to be within the SDR 0-1 range, if not, pass in a "paperWhite" scale (which matches the "peak" of the range), that will be used as normalization.
// It's possible to pass in motion vectors to do additional sharpening based on movement.
// Sharpness is meant to be between 0 and 1.
// TODO: paper white scaling probably doesn't do anything
float4 RCAS(int2 pixelCoord, int2 minPixelCoord /*= 0*/, int2 maxPixelCoord /*= 0x7FFFFFFF*/, float sharpness, Texture2D<float4> linearColorTexture, Texture2D<float2> motionVectorsTexture, float paperWhite = 1.0, bool specifyCentralLinearColor = false, float4 centralLinearColor = 0, bool dynamicSharpening = false)
{
    float originalSharpness = sharpness;

    if (dynamicSharpening) //TODO: finish this stuff and the debug view below. This currently won't skip sharpening if it was already zero!
    {
        static const float MotionSharpness = 1;
        static const float Threshold = 1;
        static const float ScaleLimit = 1;
        
        float2 mv = motionVectorsTexture.Load(int3(pixelCoord.x, pixelCoord.y, 0)).rg; // No need to check "maxPixelCoord" here
        float motion = max(abs(mv.r), abs(mv.g));
        float add = 0.0f;

        if (motion > Threshold)
            add = (motion / (ScaleLimit - Threshold)) * MotionSharpness;
    
        if ((add > MotionSharpness && MotionSharpness > 0.0f) || (add < MotionSharpness && MotionSharpness < 0.0f))
            add = MotionSharpness;
    
        sharpness += add;
    }
    sharpness = saturate(sharpness);

    // Branch to avoid doing an extra sample if we already had it
    float4 e4 = specifyCentralLinearColor ? centralLinearColor : linearColorTexture.Load(int3(pixelCoord.x, pixelCoord.y, 0)).rgba; // No need to check "maxPixelCoord" here

    // Optional optimization: skip sharpening if it's zero
    if (sharpness == 0.0f)
        return e4;

    float3 e = e4.rgb / paperWhite;
    // RCAS is always "pixel based" (the next 4 pixels)
    //    b
    //  d e f
    //    h
    // We check for "maxPixelCoord" and "minPixelCoord" to support dynamic resolution scaling. We assume "pixelCoord" is already within the limits.
    float3 b = linearColorTexture.Load(int3(pixelCoord.x, max(pixelCoord.y - 1, minPixelCoord.y), 0)).rgb / paperWhite;
    float3 d = linearColorTexture.Load(int3(max(pixelCoord.x - 1, minPixelCoord.x), pixelCoord.y, 0)).rgb / paperWhite;
    float3 f = linearColorTexture.Load(int3(min(pixelCoord.x + 1, maxPixelCoord.x), pixelCoord.y, 0)).rgb / paperWhite;
    float3 h = linearColorTexture.Load(int3(pixelCoord.x, min(pixelCoord.y + 1, maxPixelCoord.y), 0)).rgb / paperWhite;

#if RCAS_DENOISE >= 1
    // Get lumas times 2. Should use luma weights that are twice as large as normal.
    float bL = getRCASLuma(b);
    float dL = getRCASLuma(d);
    float eL = getRCASLuma(e);
    float fL = getRCASLuma(f);
    float hL = getRCASLuma(h);

    // denoise
    float nz = (bL + dL + fL + hL) * 0.25 - eL;
    float range = max(max(max(bL, dL), max(hL, fL)), eL) - min(min(min(bL, dL), min(eL, fL)), hL);
    nz = saturate(abs(nz) * rcp(range));
    nz = -0.5 * nz + 1.0;
#endif

    static const float samplesNum = 4.0; // There's 4 (5) colors to be mixed
    // Immediate constants for peak range.
    static const float2 peakC = float2(1.0, -samplesNum);

#if RCAS_LUMINANCE_BASED
    // These should all be >= 0, but tiny values below zero shouldn't hurt anyway, still, we clip them below as they'd be clipped by the screen anyway
    float bLum = GetLuminance(b);
    float dLum = GetLuminance(d);
    float eLum = GetLuminance(e);
    float fLum = GetLuminance(f);
    float hLum = GetLuminance(h);

    float minLum = max(min(min(bLum, dLum), min(fLum, hLum)), 0.0);
    float maxLum = max(max(bLum, dLum), max(fLum, hLum));

    float hitMin = minLum * rcp(samplesNum * maxLum);
    float hitMax = (peakC.x - maxLum) * rcp(samplesNum * minLum + peakC.y);

    float localLobe = max(-hitMin, hitMax);
#else // !RCAS_LUMINANCE_BASED
    // Min and max of ring.
    float3 minRGB = min(min(b, d), min(f, h));
    float3 maxRGB = max(max(b, d), max(f, h));

#if 0 // It seems like it's ok if these values aren't in the 0-1 range, the code below will still work as expected, and avoid clipping HDR (or anyway ignoring values beyond SDR) //TODOFT3: Lilium claims the code below can break for negative rgb (scRGB) values, investigate and fix it
    minRGB = saturate(minRGB);
    maxRGB = saturate(maxRGB);
#endif

    // Limiters, these need to use high precision reciprocal operations.
    // Decided to use standard rcp for now in hopes of optimizing it.
    // It's fine if either of these can go below zero!
    float3 hitMin = minRGB * rcp(samplesNum * maxRGB);
    float3 hitMax = (peakC.xxx - maxRGB) * rcp(samplesNum * minRGB + peakC.yyy);

    float3 lobeRGB = max(-hitMin, hitMax);
#if 0 // An attempt to make this code, which branches by r g b channel, color space agnostic. Without this, the result heavily depends by where the rgb coordinates are in the CIE color graph, and by how luminous they are. Unfortunately this drastically reduces the sharpening intensity, even if it makes it look even more natural.
    float localLobe = max(lobeRGB.r * Rec709_Luminance.r * 3.0, max(lobeRGB.g * Rec709_Luminance.g * 3.0, lobeRGB.b * Rec709_Luminance.b * 3.0));
#else
    float localLobe = max(lobeRGB.r, max(lobeRGB.g, lobeRGB.b));
#endif
#endif // RCAS_LUMINANCE_BASED

    float lobe = max(-RCAS_LIMIT, min(localLobe, 0.0)) * sharpness;

#if RCAS_DENOISE >= 1
    // denoise
    lobe *= nz;
#endif

    // Resolve, which needs medium precision rcp approximation to avoid visible tonality changes.
    float rcpL = rcp(samplesNum * lobe + 1.0);
    
#if RCAS_LUMINANCE_BASED
    float outputLum = ((bLum + dLum + hLum + fLum) * lobe + eLum) * rcpL;
    // Questionable choice: in case the source center pixel had luminance zero (even if the rgb ratio wasn't flat), elevate it to grey and match the target luminance, or we'd have a division by zero.
    // The alternative would be to keep "e" intact, but that then wouldn't have applied any sharpening.
    float3 output = eLum != 0 ? (e * (outputLum / eLum)) : outputLum;
#else // !RCAS_LUMINANCE_BASED
    float3 output = ((b + d + f + h) * lobe + e) * rcpL;
#endif // RCAS_LUMINANCE_BASED

#if 0 // Debug
    if (dynamicSharpening)
    {
        if (originalSharpness < sharpness)
            output.r *= 1 + (12.0 * (sharpness - originalSharpness));
        else
            output.g *= 1 + (12.0 * (originalSharpness - sharpness));
    }
#endif
  
    return float4(output * paperWhite, e4.a);
}

#endif // SRC_RCAS_HLSL