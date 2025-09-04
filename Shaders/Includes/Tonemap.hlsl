#ifndef SRC_TONEMAP_HLSL
#define SRC_TONEMAP_HLSL

#include "Common.hlsl"
#include "ACES.hlsl"
#include "DICE.hlsl"
#include "ColorGradingLUT.hlsl"

static const float HableShoulderScale = 4.0;
static const float HableLinearScale = 1.0;
static const float HableToeScale = 1.0;
static const float HableWhitepoint = 2.0;

float4 Tonemap_Hable_Eval(in float4 x, float inShoulderScale, float inLinearScale, float inToeScale)
{
	const float A = 0.22 * inShoulderScale, // Shoulder strength
	           B = 0.3 * inLinearScale,    // Linear strength
	           C = 0.1,                    // Linear angle
	           D = 0.2,                    // Toe strength
	           E = 0.01 * inToeScale,      // Toe numerator
	           F = 0.3;                    // Toe denominator
	return ((x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F)) - E / F;
}

float3 Tonemap_Hable_Inverse_Eval(in float3 x, float inShoulderScale, float inLinearScale, float inToeScale)
{
	const float A = 0.22 * inShoulderScale, // Shoulder strength
	           B = 0.3 * inLinearScale,    // Linear strength
	           C = 0.1,                    // Linear angle
	           D = 0.2,                    // Toe strength
	           E = 0.01 * inToeScale,      // Toe numerator
	           F = 0.3;                    // Toe denominator
	float3 subPart1 = B*C*F-B*E-B*F*x;
	float3 denominator = 2*A*(E+F*x-F);
	float3 part1 = subPart1 / denominator;
	float3 part2 = sqrt(sqr(-subPart1)-4.0*D*sqr(F)*x*(A*E+A*F*x-A*F)) / denominator;
	return max(part1 - part2, part1 + part2); // Take the max of the two, it's likely always the right one (we could probably discard the one with the subtraction)
}

// Note: Hable is 100% per channel so you can pass in a single channel and exclusively retrieve the result on that if you don't need three channels.
float3 Tonemap_Hable_Inverse(in float3 compressedCol, float inShoulderScale = HableShoulderScale, float inLinearScale = HableLinearScale, float inToeScale = HableToeScale, float inWhitepoint = HableWhitepoint)
{
	float3 colorSigns = float3(compressedCol.x >= 0.0 ? 1.0 : -1.0, compressedCol.y >= 0.0 ? 1.0 : -1.0, compressedCol.z >= 0.0 ? 1.0 : -1.0);
	compressedCol = abs(compressedCol);

    float uncompressWhitepoint = Tonemap_Hable_Eval(inWhitepoint, inShoulderScale, inLinearScale, inToeScale).x;
	compressedCol *= uncompressWhitepoint;
	float3 uncompressCol = Tonemap_Hable_Inverse_Eval(compressedCol, inShoulderScale, inLinearScale, inToeScale);
	uncompressCol *= colorSigns;
	return uncompressCol;
}

// The wider the color space, the more saturated colors are generated in shadow
float3 Tonemap_Hable(in float3 color, float inShoulderScale = HableShoulderScale /*= HDRFilmCurve.x*/, float inLinearScale = HableLinearScale /*= HDRFilmCurve.y*/ /*mid tones*/, float inToeScale = HableToeScale /*= HDRFilmCurve.z*/, float inWhitepoint = HableWhitepoint /*= HDRFilmCurve.w*/)
{
	// Filmic response curve as proposed by J. Hable. Uncharted 2 tonemapper.

#if 1 // hardcode curve (also assumed in "Tonemap_Hable_Inverse()")
	inShoulderScale = HableShoulderScale;
	inLinearScale = HableLinearScale;
	inToeScale = HableToeScale;
	inWhitepoint = HableWhitepoint;
#endif

	float3 colorSigns = float3(color.x >= 0.0 ? 1.0 : -1.0, color.y >= 0.0 ? 1.0 : -1.0, color.z >= 0.0 ? 1.0 : -1.0); // sign() returns zero for zero and we don't want that
	float4 x = float4(abs(color), inWhitepoint); // LUMA FT: changed from clipping to zero to abs(), to generate negative (scRGB) colors

	float4 compressedCol = Tonemap_Hable_Eval(x, inShoulderScale, inLinearScale, inToeScale);
	// LUMA FT: if "compressedCol.xyz" was already negative with >= "color" values, we'd risk flipping it again if the original "color" sign was negative,
	// but currently the hardcoded math values don't allow it to ever go negative, so we don't have to worry about it
	// LUMA FT: this can output values higher than 1, but they got clipped in SDR. It seems like this can't reach pure zero for an input of zero, but it gets really close to it.
	// The white point value is calibrated, based on the other settings, so that the output range is mostly within 0-1.
	float3 result = (compressedCol.xyz * colorSigns) / compressedCol.w;
#if 0 // LUMA FT: disabled saturate(), it's unnecessary
	result = saturate(result);
#endif

#if 0 // Test inverse hable
	return Tonemap_Hable_Inverse(result, inShoulderScale, inLinearScale, inToeScale, inWhitepoint);
#endif

	return result;
}

float3 Tonemap_Uncharted2_Eval(float3 x, float a, float b, float c, float d, float e, float f)
{
  return ((x * (a * x + c * b) + d * e) / (x * (a * x + b) + d * f)) - (e / f);
}

// One channel only, given they are all the same
float Tonemap_Uncharted2_Inverse_Eval(float y, float a, float b, float c, float d, float e, float f)
{
  float ef = e / f;
  float yp = y + ef;

  float A = a * (yp - 1.0);
  float B = b * (yp - c);
  float C = d * (f * yp - e);

  float discriminant = B * B - 4.0 * A * C;

  float sqrtD = sqrt(abs(discriminant)) * sign(discriminant);

  float x1 = (-B + sqrtD) / (2.0 * A);
  float x2 = (-B - sqrtD) / (2.0 * A);

  // Choose the root that makes sense in your context (e.g., positive, in [0,1])
  return (x1 >= 0.0) ? x1 : x2;
}

float3 Tonemap_DICE(float3 color, float peakWhite, float paperWhite = 1.0)
{
	DICESettings settings = DefaultDICESettings();
	return DICETonemap(color * paperWhite, peakWhite, settings);
}

float3 Tonemap_ACES(float3 color, float peakWhite, float paperWhite = 1.0)
{
	ACESSettings settings = DefaultACESSettings();
	return ACESTonemap(color, paperWhite, peakWhite, settings);
}

// From RenoDX, by ShortFuse
float3 UpgradeToneMap(
    float3 color_untonemapped,
    float3 color_tonemapped,
    float3 color_tonemapped_graded,
    float post_process_strength = 1.f,
    float auto_correction = 0.f) {
  float ratio = 1.f;

  float y_untonemapped = GetLuminance(color_untonemapped, CS_BT709);
  float y_tonemapped = GetLuminance(color_tonemapped, CS_BT709);
  float y_tonemapped_graded = GetLuminance(color_tonemapped_graded, CS_BT709);

  if (y_untonemapped < y_tonemapped) {
    // If substracting (user contrast or paperwhite) scale down instead
    // Should only apply on mismatched HDR
    ratio = y_untonemapped / y_tonemapped;
  } else {
    float y_delta = y_untonemapped - y_tonemapped;
    y_delta = max(0, y_delta);  // Cleans up NaN
    const float y_new = y_tonemapped_graded + y_delta;

    const bool y_valid = (y_tonemapped_graded > 0);  // Cleans up NaN and ignore black
    ratio = y_valid ? (y_new / y_tonemapped_graded) : 0;
  }
  float auto_correct_ratio = lerp(1.f, ratio, saturate(y_untonemapped));
  ratio = lerp(ratio, auto_correct_ratio, auto_correction);

  float3 color_scaled = color_tonemapped_graded * ratio;
  // Match hue
  color_scaled = RestoreHueAndChrominance(color_scaled, color_tonemapped_graded, 1.0, 0.0, 0.0, FLT_MAX, 0.0, CS_BT709);
  return lerp(color_untonemapped, color_scaled, post_process_strength);
}

#endif // SRC_TONEMAP_HLSL
