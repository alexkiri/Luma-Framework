#include "../Includes/Common.hlsl"

Texture2D<float4> t1 : register(t1);
Texture2D<float4> t0 : register(t0);

SamplerState s0_s : register(s0);

cbuffer cb0 : register(b0)
{
  float4 cb0[22];
}

void main(
  float4 v0 : SV_POSITION0,
  float2 v1 : TEXCOORD0,
  float4 v2 : COLOR0,
  out float4 o0 : SV_Target0)
{
  float4 mapColor = t0.SampleBias(s0_s, v1.xy, cb0[21].x).xyzw;
  float4 backgroundColor = t1.SampleBias(s0_s, v1.xy, cb0[21].x).xyzw;
  o0.xyz = lerp(backgroundColor.rgb, mapColor.rgb, v2.w * saturate(mapColor.a)); // Luma: fix map color alpha potentially going out of bounds if the texture was upgraded to float
  o0.w = 1;
}