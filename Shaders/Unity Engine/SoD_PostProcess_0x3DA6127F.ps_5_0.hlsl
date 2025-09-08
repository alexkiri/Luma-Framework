#include "../Includes/Common.hlsl"
#include "../Includes/ColorGradingLUT.hlsl"

Texture2DArray<float4> t2 : register(t2);
Texture2DArray<float4> t1 : register(t1); // Bloom or additive color / mask
Texture2DArray<float4> t0 : register(t0); // Scene

SamplerState s0_s : register(s0);

cbuffer cb1 : register(b1)
{
  float4 cb1[49];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[6];
}

// Runs after tonemapping/grading shader. This is the final shader before UI.
void main(
  float4 v0 : SV_POSITION0,
  float2 v1 : TEXCOORD0,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1;
  r0.xy = cb1[46].xy * v1.xy;
  r0.xy = (uint2)r0.xy;
  r0.xy = (uint2)r0.xy; // ?
  r0.zw = float2(-1,-1) + cb1[46].xy;
  r0.zw = cb0[3].zw * r0.zw;
  r0.xy = r0.xy * cb0[3].xy + r0.zw;
  r0.xy = (uint2)r0.xy;
  r0.zw = float2(0,0);
  r0.x = t2.Load(r0.xyzw).x;
  o0.w = (cb0[5].x == 1.0) ? r0.x : 1;
  r0.xy = v1.xy * cb0[3].xy + cb0[3].zw;
  r0.zw = cb0[4].xy * r0.xy;
  r1.xy = cb1[48].xy * r0.xy;
  r0.xy = (int2)r0.zw;
  r0.zw = float2(0,0);
  r0.xyz = t0.Load(r0.xyzw).xyz;
  r1.z = 0;
  r1.xyzw = t1.SampleLevel(s0_s, r1.xyz, 0).xyzw;
  o0.xyz = r1.w * r0.xyz + r1.xyz;

#if UI_DRAW_TYPE == 2 // Scale by the inverse of the relative UI brightness so we can draw the UI at brightness 1x and then multiply it back to its intended range
	ColorGradingLUTTransferFunctionInOutCorrected(o0.rgb, VANILLA_ENCODING_TYPE, GAMMA_CORRECTION_TYPE, true);
  o0.rgb *= LumaSettings.GamePaperWhiteNits / LumaSettings.UIPaperWhiteNits;
	ColorGradingLUTTransferFunctionInOutCorrected(o0.rgb, GAMMA_CORRECTION_TYPE, VANILLA_ENCODING_TYPE, true);
#endif
}