#include "../Includes/Common.hlsl"

Texture2D<float4> t1 : register(t1); // Scene
Texture2D<float4> t0 : register(t0);

SamplerState s1_s : register(s1);
SamplerState s0_s : register(s0);

cbuffer cb1 : register(b1)
{
  float4 cb1[7];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[9];
}


// Makes the whole screen vibrate when under water, or to simulate non clear glass.
// This spreads NaNs on objects that outputted NaNs in the source scene color.
void main(
  float4 v0 : SV_POSITION0,
  float3 v1 : TEXCOORD0,
  float2 v2 : TEXCOORD1,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3,r4;
  r0.xy = cb1[1].xx + v1.xy;
  r0.xy = float2(5.39870024,5.44210005) * r0.xy;
  r0.xy = frac(r0.xy);
  r0.zw = float2(21.5351009,14.3136997) + r0.xy;
  r0.z = dot(r0.yx, r0.zw);
  r0.xy = r0.xy + r0.zz;
  r0.x = r0.x * r0.y;
  r0.y = 95.4307022 * r0.x;
  r1.xyzw = float4(95.4307022,97.5901031,93.8368988,91.6931) * r0.xxxx;
  r1.xyzw = frac(r1.xyzw);
  r0.x = frac(r0.y);
  r0.x = 6.28318548 * r0.x;
  sincos(r0.x, r0.x, r2.x);
  r0.y = r2.x;
  r0.xy = cb0[6].xx * r0.xy;
  r2.x = cb1[6].x / cb1[6].y;
  r0.zw = r2.xx * r0.yx;
  r2.xy = v1.xy / v1.zz;
  r2.zw = r2.xy + r0.xz;
  r3.xyzw = t1.SampleLevel(s1_s, r2.zw, 0).xyzw;
  r3.xyzw = IsNaN_Strict(r3.xyzw) ? 0.0 : r3.xyzw; // Luma
  r0.xz = -r0.xz * float2(0.866025388,0.866025388) + r2.xy;
  r4.xyzw = t1.SampleLevel(s1_s, r0.xz, 0).xyzw;
  r4.xyzw = IsNaN_Strict(r4.xyzw) ? 0.0 : r4.xyzw; // Luma
  r3.xyzw = r4.xyzw + r3.xyzw;
  r0.xz = r0.yw * float2(-0.707106769,0.707106769) + r2.xy;
  r0.yw = -r0.yw * float2(-0.5,0.5) + r2.xy;
  r2.xyzw = t1.SampleLevel(s1_s, r0.yw, 0).xyzw;
  r2.xyzw = IsNaN_Strict(r2.xyzw) ? 0.0 : r2.xyzw; // Luma
  r0.xyzw = t1.SampleLevel(s1_s, r0.xz, 0).xyzw;
  r0.xyzw = IsNaN_Strict(r0.xyzw) ? 0.0 : r0.xyzw; // Luma
  r0.xyzw = r3.xyzw + r0.xyzw;
  r0.xyzw = r0.xyzw + r2.xyzw;
  r2.x = r0.w * 0.25 + 0.629960537;
  r0.xyzw = float4(0.25,0.25,0.25,0.25) * r0.xyzw;
  r2.x = r2.x * r2.x;
  r2.x = r2.x * r2.x + 0.842509866;
  r0.xyz = cb0[8].xyz * r0.xyz;
  r0.xyz = r0.xyz * r2.xxx;
  r2.xyzw = t0.Sample(s0_s, v2.xy).xyzw;
  r2.xyz = cb0[7].xyz * r2.xyz + -r0.xyz;
  r2.xyz = cb0[8].www * r2.xyz + r0.xyz;
  r0.x = 1 + -cb0[8].w;
  r2.w = r0.w * r0.x;
  o0.xyzw = r1.xyzw * float4(0.00392156886,0.00392156886,0.00392156886,0.00392156886) + r2.xyzw;

  // Luma:
  o0.a = saturate(o0.a);
}