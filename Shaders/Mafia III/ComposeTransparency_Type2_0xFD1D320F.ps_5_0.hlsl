#include "Includes/Common.hlsl"

Texture2D<float4> t3 : register(t3); // Additive transparency
Texture2D<float4> t2 : register(t2); // Blurred Scene
Texture2D<float4> t1 : register(t1); // Some transparency mask
Texture2D<float4> t0 : register(t0); // Scene without transparency

SamplerState s2_s : register(s2);
SamplerState s1_s : register(s1);
SamplerState s0_s : register(s0);

cbuffer cb0 : register(b0)
{
  float4 cb0[11];
}

void main(
  float4 v0 : SV_Position0,
  out float4 o0 : SV_Target0,
  out float4 o1 : SV_Target1)
{
  float4 r0,r1,r2,r3,r4;
  float2 uv = cb0[10].zw * v0.xy; // Just the resolution
  float4 transparencyMask = t1.Sample(s0_s, uv).xyzw;
  float2 normalizedTransparencyShift = transparencyMask.xy - (127.0/255.0); // Neutral value for UNORM 8
  float2 shiftedUV = uv + normalizedTransparencyShift * 0.1;
  r2.xyz = t3.Sample(s0_s, uv).xyz;
  r0.xy = transparencyMask.z * float2(10.0, 10.0) - float2(1.0, 2.0);
  r0.y = max(0.0, r0.y);
  r0.x = saturate(r0.x);
  r3.xyz = t2.SampleLevel(s2_s, shiftedUV, r0.y).xyz; // TODO: kill fireflies from here...
  r4.xyzw = t0.SampleLevel(s1_s, shiftedUV, 0).xyzw;
  r0.yzw = -r4.xyz + r3.xyz;
  r0.xyz = r0.x * r0.yzw + r4.xyz;
  o0.w = r4.w;
  r0.w = 0.0 < transparencyMask.z;
  r0.w = r0.w ? 1.0 : (1 - transparencyMask.w);
  o0.xyz = r0.xyz * r0.w + r2.xyz;
  o1.w = 1 + -r0.w;
  o1.xyz = r2.xyz;
}