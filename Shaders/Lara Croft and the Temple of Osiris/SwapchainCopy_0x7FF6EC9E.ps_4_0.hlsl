#include "../Includes/Common.hlsl"

cbuffer FlipConstantBuffer : register(b0)
{
  float4 gamma : packoffset(c0);
}

SamplerState g_Sampler_s : register(s0);
Texture2D<float4> g_InputTexture : register(t0);

void main(
  float4 v0 : SV_POSITION0,
  float2 v1 : TEXCOORD0,
  out float4 o0 : SV_TARGET0)
{
  float4 r0;
  r0.xyzw = g_InputTexture.Sample(g_Sampler_s, v1.xy).xyzw;
  r0.xyz = pow(abs(r0.rgb), gamma.y) * sign(r0.xyz); // Luma: fixed negative values support
  o0.xyz = gamma.xxx * r0.xyz; // Luma: removed useless saturate
  o0.w = 1;
}