#include "Includes/Common.hlsl"

Texture2D<float4> t0 : register(t0); // Full res motion vecotrs

SamplerState s0_s : register(s0);

cbuffer cb0 : register(b0)
{
  float4 cb0[11];
}

#define cmp

void main(
  float4 v0 : SV_Position0,
  float4 v1 : TEXCOORD0,
  out float4 o0 : SV_Target0)
{
  // Motion vectors end up having jitters in them with Luma's TAA (these are the only places where they are used)
  float2 dejittering = float2(LumaData.CustomData3, LumaData.CustomData4);

  float4 r0,r1,r2,r3;
  r0.xy = cb0[10].zw * float2(0,-1);
  r0.xy = r0.xy / float2(2,2);
  r0.xy = saturate(v1.xy + r0.xy);
  r0.xy = t0.SampleLevel(s0_s, r0.xy, 0).yx - dejittering;
  r1.x = frac(abs(r0.x));
  r1.y = cmp(r0.x >= 0);
  r1.z = r1.y ? r1.x : -r1.x;
  r2.xy = saturate(cb0[10].zw * -0.5 + v1.xy);
  r2.xy = t0.SampleLevel(s0_s, r2.xy, 0).xy - dejittering;
  r2.z = frac(abs(r2.y));
  r2.y = cmp(r2.y >= 0);
  r0.x = r2.x;
  r1.x = r2.y ? r2.z : -r2.z;
  r2.yw = r1.xz;
  r3.xy = cb0[10].zw * float2(-1,0);
  r3.xy = r3.xy / 2.0;
  r3.xy = saturate(v1.xy + r3.xy);
  r3.xy = t0.SampleLevel(s0_s, r3.xy, 0).xy - dejittering;
  r3.z = frac(abs(r3.y));
  r3.y = cmp(r3.y >= 0);
  r0.z = r3.x;
  r1.y = r3.y ? r3.z : -r3.z;
  r3.xy = saturate(v1.xy);
  r3.xy = t0.SampleLevel(s0_s, r3.xy, 0).xy - dejittering;
  r3.z = frac(abs(r3.y));
  r3.y = cmp(r3.y >= 0);
  r0.w = r3.x;
  r1.w = r3.y ? r3.z : -r3.z;
  r3.xyzw = r1.xzyw * r1.xzyw;
  r3.xyzw = r0.xyzw * r0.xyzw + r3.xyzw;
  r2.xz = r0.xy;
  r2.xyzw = r3.xxyy * r2.xyzw;
  r0.xy = r2.xy + r2.zw;
  r1.xz = r0.zw;
  r0.xy = r1.xy * r3.zz + r0.xy;
  r0.xy = r1.zw * r3.ww + r0.xy;
  r0.z = r3.x + r3.y;
  r0.z = r0.z + r3.z;
  r0.z = r0.z + r3.w;
  r0.z = max(0.001, r0.z);
  o0.xy = r0.xy / r0.zz;
  o0.zw = 0.0;
}