#include "../Includes/Common.hlsl"
#include "../Includes/Oklab.hlsl"

cbuffer _Globals : register(b0)
{
  float Canvas_hlsl_PSMain00000000000000000000000000000001_1bits : packoffset(c0) = {0};
  float4 fogColor : packoffset(c1);
  float3 fogTransform : packoffset(c2);
  float2 fogLuminance : packoffset(c3);
  row_major float3x4 screenDataToCamera : packoffset(c4);
  float globalScale : packoffset(c7);
  float sceneDepthAlphaMask : packoffset(c7.y);
  float globalOpacity : packoffset(c7.z);
  float distortionBufferScale : packoffset(c7.w);
  float3 wToZScaleAndBias : packoffset(c8);
  float4 screenTransform[2] : packoffset(c9);
  row_major float4x4 worldViewProj : packoffset(c11);
  float3 localEyePos : packoffset(c15);
  float4 vertexClipPlane : packoffset(c16);
  float ViewX : packoffset(c17);
  float ViewY : packoffset(c17.y);
  float ViewZ : packoffset(c17.z);
  float NormalX : packoffset(c17.w);
  float NormalY : packoffset(c18);
  float NormalZ : packoffset(c18.y);
  float4 globalColor : packoffset(c19);
}

SamplerState s_sceneDepth_s : register(s0);
Texture2D<float> s_sceneDepth : register(t0);
Texture2D<float4> sceneTexture : register(t1);

float4 GetAdditiveFogByDepth(float depth, float2 depthUV, float4 fogOpacity, float4 fogIntensity)
{
  float4 r0,r1;
  r0.x = 1 + -wToZScaleAndBias.z;
  r0.w = (depth >= 0.00999999978) ? 1.000000 : 0;
  r0.x = r0.w * r0.x + wToZScaleAndBias.z;
  r0.x = depth * r0.x + -wToZScaleAndBias.x;
  r1.z = wToZScaleAndBias.y / r0.x;
  r1.xy = r1.zz * depthUV;
  r1.w = 1;
  r0.x = dot(screenDataToCamera._m00_m01_m02_m03, r1.xyzw);
  r0.y = dot(screenDataToCamera._m10_m11_m12_m13, r1.xyzw);
  r0.z = dot(screenDataToCamera._m20_m21_m22_m23, r1.xyzw);
  r0.x = dot(r0.xyz, r0.xyz);
  r0.x = sqrt(r0.x);
  r0.x = r0.x * fogTransform.x + fogTransform.y;
  r0.x = 1.44269502 * r0.x;
  r0.x = exp2(r0.x);
  r0.x = min(1, r0.x);
  r0.x = -fogColor.w * r0.x + fogColor.w;
  r0.x = fogTransform.z * r0.x;
  r0.x = fogIntensity.w * r0.x;
  r0.y = globalOpacity * fogOpacity.w;
  float4 outColor;
  outColor.w = r0.x * r0.y;
  r0.xyz = fogColor.xyz * fogIntensity.xyz;
  outColor.xyz = globalScale * r0.xyz;
  return outColor;
}

void main(
  float4 v0 : TEXCOORD6,
  float4 fogOpacity : TEXCOORD7,
  float4 fogIntensity : COLOR0,
  out float4 outColor : SV_Target0)
{
  const float2 depthUV = v0.xy / v0.ww;
  const float depth = s_sceneDepth.Sample(s_sceneDepth_s, depthUV).x;
  float4 additiveFog = GetAdditiveFogByDepth(depth, depthUV, fogOpacity, fogIntensity);
  //additiveFog.rgba = max(additiveFog.rgba - (GetAdditiveFogByDepth(0.0, depthUV, fogOpacity, fogIntensity).rgba * (1.0 - pow(depth, 125.0))), 0.0);

  const float3 backgroundColor = sceneTexture.Sample(s_sceneDepth_s, depthUV).rgb;
#if 1 // LUMA: Fix fog to avoid it raising blacks
  // Pre-blend with the background and force the alpha to 1 to fully control the result (we can't fix the fact that it raises blacks without knowing the background color)
  outColor.rgb = lerp(backgroundColor.rgb, additiveFog.rgb, additiveFog.a);
  outColor.a = 1;
  // Restore the original luminance near the camera, to fog can only make the scene brighter further in the distance
#if 0
  float3 backgroundOklab = linear_srgb_to_oklab(backgroundColor.rgb);
  float3 outputOklab = linear_srgb_to_oklab(outColor.rgb);
  outputOklab[0] = lerp(backgroundOklab[0], outputOklab[0], pow(depth, 33.333));
  //outputOklab[1] = backgroundOklab[1];
  //outputOklab[2] = backgroundOklab[2];
  outputOklab[1] *= lerp(2.0, 1.0, pow(depth, LumaSettings.DevSetting01));
  outputOklab[2] *= lerp(2.0, 1.0, pow(depth, LumaSettings.DevSetting01));
  outColor.rgb = oklab_to_linear_srgb(outputOklab);
#else
  float3 correctedColor = RestoreLuminance(outColor.rgb, backgroundColor.rgb, true);
  float correctionRatio = 1.0 - saturate(GetLuminance(correctedColor) / GetLuminance(outColor.rgb));
  // Re-tint the fog by adding the additive color again, and the restoring the luminance again (there might be a way to do it with simpler math but whatever)
  correctedColor = RestoreLuminance(correctedColor + (additiveFog.rgb * additiveFog.a * pow(correctionRatio, 0.333) * 3.333), correctedColor, true);
  outColor.rgb = lerp(correctedColor, outColor.rgb, pow(depth, 66.666)); // Heuristically found value (hopefully the depth far plane is consistent through the game)
  //outColor.rgb = lerp(GetLuminance(outColor.rgb), outColor.rgb, 1.0 + (1.0 - pow(depth, 33.333)));
#endif
#elif 0 // Disable fog
#if 0
  outColor.rgb = 0;
  outColor.a = 0;
#else // Dumber way
  outColor.rgb = backgroundColor;
  outColor.a = 1;
#endif
#else
  outColor = additiveFog;
#endif
}