#include "../Includes/Common.hlsl"

Texture2D<float4> t2 : register(t2); // Scene
Texture2D<float4> t1 : register(t1);
Texture2D<float4> t0 : register(t0);

SamplerState s2_s : register(s2);
SamplerState s1_s : register(s1);
SamplerState s0_s : register(s0);

cbuffer cb1 : register(b1)
{
  float4 cb1[8];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[7];
}

#define cmp

// Makes the whole screen vibrate when under water
// This also draws some glasses (I'm not sure how)
// This spreads NaNs on objects that outputted NaNs in the source scene color.
void main(
  float4 v0 : SV_POSITION0,
  float4 v1 : TEXCOORD0,
  float2 v2 : TEXCOORD1,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3,r4;
  r0.xy = float2(5.39870024,5.44210005) * v2.xy;
  r0.xy = frac(r0.xy);
  r0.zw = float2(21.5351009,14.3136997) + r0.xy;
  r0.z = dot(r0.yx, r0.zw);
  r0.xy = r0.xy + r0.zz;
  r0.x = r0.x * r0.y;
  r0.x = 95.4307022 * r0.x;
  r0.x = frac(r0.x);
  r0.x = 6.28318548 * r0.x;
  sincos(r0.x, r0.x, r1.x);
  r0.z = r0.x;
  r0.w = r1.x;
  r0.xy = v1.xy / v1.ww;
  r1.x = t0.SampleLevel(s1_s, r0.xy, 0).x;
  r1.x = cb1[7].z * r1.x + cb1[7].w;
  r1.x = 1 / r1.x;
  r1.x = -v1.z + r1.x;
  r1.x = saturate(r1.x / cb0[6].y);
  r1.x = cb0[6].x * r1.x;
  r1.x = 1.79999995 * r1.x;
  r1.zw = r1.x * r0.zw;
  r0.z = cb1[6].y / cb1[6].x;
  r1.y = r1.z * r0.z;
  r1.x = -r1.w * r0.z;
  r0.zw = r1.yw + r0.xy;
  
  r2.x = t1.SampleLevel(s2_s, r0.zw, 0).x;
  r0.z = cb1[5].z * r2.x + -v1.z;
  r0.z = saturate(r0.z / cb0[6].y);
  r0.zw = r1.yw * r0.zz + r0.xy;
  r2.xyzw = t2.SampleLevel(s0_s, r0.zw, 0).xyzw;
  r2.xyzw = IsNaN_Strict(r2.xyzw) ? 0.0 : r2.xyzw; // Luma
  r2.xyzw = float4(0,0,0,9.99999997e-007) + r2.xyzw;
  
  o0.xyzw = r2.xyzw; return;
  //o0.xyzw = t2.Load(v0.xyz).xyzw; return; // Test passthrough

  r0.zw = r1.yw * float2(-0.707106769,-0.707106769) + r0.xy;
  r1.yw = float2(-0.707106769,-0.707106769) * r1.yw;
  r3.x = t1.SampleLevel(s2_s, r0.zw, 0).x;
  r0.z = cb1[5].z * r3.x + -v1.z;
  r0.z = saturate(r0.z / cb0[6].y);
  r0.zw = r1.yw * r0.zz + r0.xy;
  r3.xyzw = t2.SampleLevel(s0_s, r0.zw, 0).xyzw;
  r3.xyzw = IsNaN_Strict(r3.xyzw) ? 0.0 : r3.xyzw; // Luma
  r2.xyzw = r3.xyzw + r2.xyzw;
  r3.xyzw = r1.xzxz * float4(0.866025388,0.866025388,-0.5,-0.5) + r0.xyxy;
  r1.xyzw = float4(0.866025388,0.866025388,-0.5,-0.5) * r1.xzxz;
  r4.x = t1.SampleLevel(s2_s, r3.xy, 0).x;
  r3.x = t1.SampleLevel(s2_s, r3.zw, 0).x;
  r0.z = cb1[5].z * r3.x + -v1.z;
  r0.z = saturate(r0.z / cb0[6].y);
  r0.zw = r1.zw * r0.zz + r0.xy;
  r3.xyzw = t2.SampleLevel(s0_s, r0.zw, 0).xyzw;
  r3.xyzw = IsNaN_Strict(r3.xyzw) ? 0.0 : r3.xyzw; // Luma
  r0.z = cb1[5].z * r4.x + -v1.z;
  r0.z = saturate(r0.z / cb0[6].y);
  r0.xy = r1.xy * r0.zz + r0.xy;
  r0.xyzw = t2.SampleLevel(s0_s, r0.xy, 0).xyzw;
  r0.xyzw = IsNaN_Strict(r0.xyzw) ? 0.0 : r0.xyzw; // Luma
  r0.xyzw = r2.xyzw + r0.xyzw;
  r0.xyzw = r0.xyzw + r3.xyzw;
  o0.xyzw = float4(0.25,0.25,0.25,0.25) * r0.xyzw;
}