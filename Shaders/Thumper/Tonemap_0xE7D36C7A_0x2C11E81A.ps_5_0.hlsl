#include "../Includes/Common.hlsl"

cbuffer BloomConstants : register(b3)
{
  float4 gBloomColor : packoffset(c0);
  float4 gBloomSaturation_Scene_Bloom : packoffset(c1);
}

cbuffer FadeConstants : register(b8)
{
  float4 gFadeColor_Fade : packoffset(c0);
}

cbuffer LevelsConstants : register(b10)
{
  float4 gBlack_InvRange_InvGamma : packoffset(c0);
  float4 gOutputRange_Black : packoffset(c1);
  float4 gBlacks : packoffset(c2);
  float4 gInvRanges : packoffset(c3);
  float4 gInvGammas : packoffset(c4);
  float4 gOutputRanges : packoffset(c5);
  float4 gOutputBlacks : packoffset(c6);
}

SamplerState gAuxSampler_s : register(s0);
SamplerState gSceneSampler_s : register(s1);
Texture2D<float4> gAuxTex : register(t0);
Texture2D<float4> gSceneTex : register(t1);

void main(
  float v0 : SV_ClipDistance0,
  float w0 : SV_CullDistance0,
  float4 v1 : SV_Position0,
  float2 v2 : TEXCOORD0,
  float2 w2 : TEXCOORD1,
  out float4 o0 : SV_Target0)
{
  o0.w = 1;

  float4 r0,r1;
  r0.rgb = gSceneTex.Sample(gSceneSampler_s, w2.xy).rgb;
#if 0 // Test: untonemapped
  o0.rgb = r0.rgb; return;
#endif

  r0.xyz = lerp(GetLuminance(r0.xyz), r0.xyz, gBloomSaturation_Scene_Bloom.x); // Luma: fixed wrong luminance formula

  r1.xyz = gAuxTex.Sample(gAuxSampler_s, v2.xy).xyz; // Bloom texture
#if 1
  r1.xyz = max(r1.xyz, 0.0);
#endif
  r0.xyz += r1.xyz * gBloomColor.xyz;

  r0.xyz = pow(abs(r0.xyz), gInvGammas.xyz) * sign(r0.xyz); // Luma: fixed abs*sign on pow
#if 0 // Luma: disable clamping
  r0.xyz = min(1.0, r0.xyz);
#endif
  r0.xyz = r0.xyz * gOutputRanges.xyz + gOutputBlacks.xyz;
  r0.xyz -= gBlack_InvRange_InvGamma.x;
#if 0 // Luma: disable clamping
  r0.xyz = max(float3(0,0,0), r0.xyz);
#endif
#if _2C11E81A
  o0.xyz = gBlack_InvRange_InvGamma.y * r0.xyz;
#elif _E7D36C7A
  r1.xyz = gBlack_InvRange_InvGamma.y * r0.xyz;
  r0.xyz = gFadeColor_Fade.xyz - (r0.xyz * gBlack_InvRange_InvGamma.y);
  o0.xyz = gFadeColor_Fade.w * r0.xyz + r1.xyz;
#endif
}