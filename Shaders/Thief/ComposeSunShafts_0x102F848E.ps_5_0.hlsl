#include "../Includes/Common.hlsl"

Texture2D<float4> t1 : register(t1);
Texture2D<float4> t0 : register(t0);

SamplerState s1_s : register(s1);
SamplerState s0_s : register(s0);

cbuffer cb0 : register(b0)
{
  float4 cb0[21];
}

void main(
  float2 v0 : TEXCOORD0,
  float2 w0 : TEXCOORD1,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1;
  r0.xy = -v0.xy * cb0[11].zw + cb0[5].xy;
  r0.x = dot(r0.xy, r0.xy);
  r0.x = sqrt(r0.x);
  r0.x = 0.5 * r0.x;
  r0.x = min(1, r0.x);
  r0.y = -cb0[12].w * 0.5 + 1.5;
  r0.y = -cb0[12].w + r0.y;
  r1.xyzw = t0.Sample(s1_s, v0.xy).xyzw;
  r0.z = r1.w * r1.w;
  r1.xyz = cb0[13].xyz * r1.xyz;
  r0.y = r0.z * r0.y + cb0[12].w;
  r0.z = 1 - r0.y;
  r0.x = r0.x * r0.z + r0.y;
  r0.y = 1 - r0.x;
  r0.z = cb0[14].x * cb0[14].x;
  r0.z = cb0[14].x * r0.z;
  o0.w = r0.z * r0.y + r0.x;
  r0.xyz = t1.Sample(s0_s, w0.xy).xyz;
  r0.x = GetLuminance(r0.xyz); // Luma: fixed from BT.601 coeffs
  r0.x = -3 * r0.x;
  r0.x = exp2(r0.x);
  r0.x = saturate(cb0[20].x * r0.x);
  o0.xyz = r1.xyz * r0.x;

#if 1 // Luma: make them completely additive, without darkening the background (it made sense in SDR)
  o0.w = 1;
#endif
}