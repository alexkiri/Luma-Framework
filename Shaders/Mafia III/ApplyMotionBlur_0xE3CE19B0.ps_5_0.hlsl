#include "Includes/Common.hlsl"

Texture2D<float4> t4 : register(t4); // Full res motion vecotrs
Texture2D<float4> t3 : register(t3);
Texture2D<float4> t2 : register(t2);
Texture2D<float4> t1 : register(t1);
Texture2D<float4> t0 : register(t0);

SamplerState s1_s : register(s1);

SamplerState s0_s : register(s0);

cbuffer cb2 : register(b2)
{
  float4 cb2[11];
}

cbuffer cb1 : register(b1)
{
  float4 cb1[11];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[3];
}

#define cmp

void main(
  float4 v0 : SV_Position0,
  float4 v1 : TEXCOORD0,
  out float4 o0 : SV_Target0)
{
  // Motion vectors end up having jitters in them with Luma's TAA (these are the only places where they are used)
  float2 dejittering = float2(LumaData.CustomData3, LumaData.CustomData4);
  //dejittering.x *= -0.25; //TODOFT5! Test once final, should be good now
  //dejittering.y *= -0.25;

  float4 r0,r1,r2,r3,r4,r5,r6,r7,r8;
  r0.x = cb2[10].x * cb0[1].x;
  r0.x = 0.02 * r0.x;
  r0.y = cb0[1].y * -0.9 + 1;
  r1.xyz = t0.Sample(s0_s, v1.xy).xyz;
  r0.zw = t4.Sample(s0_s, v1.xy).xy - dejittering;
  
#if 0
  o0 = 0;
  o0.xy = r0.zw; return;
#endif

  r1.w = frac(abs(r0.w));
  r2.x = cmp(r0.w >= 0);
  r2.y = r2.x ? r1.w : -r1.w;
  r0.w = trunc(r0.w);
  r0.w = cmp(0 != abs(r0.w));
  r0.w = r0.w ? 1 : r0.x;
  r2.x = r0.z;
  r2.xy = r2.xy * r0.ww;
  r2.zw = t3.Sample(s1_s, v1.xy).xy;
  r3.xy = r2.zw * r0.ww;
  r3.zw = cb1[10].zw * 1.0;
  r4.xy = r3.zw * r2.xy;
  r0.z = dot(r2.xy, r2.xy);
  r0.z = sqrt(r0.z);
  r0.z = max(1, r0.z);
  r0.z = 1 / r0.z;
  r1.xyz = r1.xyz * r0.zzz;
  r1.w = t2.Sample(s0_s, v1.xy).x;
  r2.x = cb0[0].y * r1.w;
  r2.y = 1 + cb0[1].z;
  r4.z = r0.y + r0.y;
  r4.x = abs(r4.x) + abs(r4.y);
  r5.xyz = r1.xyz;
  r4.y = r0.z;
  r4.w = 0;
  while (true) {
    r5.w = cmp(r4.w >= cb0[1].z);
    if (r5.w != 0) break;
    r4.w = 1 + r4.w;
    r5.w = r4.w / r2.y;
    r5.w = r5.w * r4.z - r0.y;
    r6.xy = r5.ww * r3.xy;
    r6.zw = r6.xy * r3.zw;
    r6.xy = saturate(r6.xy * r3.zw + v1.xy);
    r5.w = t2.Sample(s0_s, r6.xy).x;
    r7.x = cb0[0].y * r5.w;
    r7.x = r1.w * cb0[0].y - r7.x;
    r7.x = saturate(r7.x * 100000 + 1);
    r5.w = r5.w * cb0[0].y - r2.x;
    r5.w = saturate(r5.w * 100000 + 1);
    r7.yz = t4.Sample(s0_s, r6.xy).xy - dejittering;
    r7.w = frac(abs(r7.z));
    r8.x = cmp(r7.z >= 0);
    r8.y = r8.x ? r7.w : -r7.w;
    r7.z = trunc(r7.z);
    r7.z = cmp(0 != abs(r7.z));
    r8.x = r7.y;
    r7.yw = r8.xy * r0.xx;
    r7.yz = r7.zz ? r8.xy : r7.yw;
    r6.z = abs(r6.z) + abs(r6.w);
    r8.xy = r2.zw * r0.w - r7.yz;
    r8.xy = cb0[1].yy * r8.xy + r7.yz;
    r8.xy = r8.xy * r3.zw;
    r6.w = abs(r8.x) + abs(r8.y);
    r6.w = r6.z / r6.w;
    r6.w = 1 - r6.w;
    r6.w = max(0, r6.w);
    r7.w = r6.z / r4.x;
    r8.x = 1 - r7.w;
    r8.x = max(0, r8.x);
    r5.w = r8.x * r5.w;
    r5.w = r7.x * r6.w + r5.w;
    r7.xy = r7.yz * r3.zw;
    r6.w = abs(r7.x) + abs(r7.y);
    r6.z = r6.z / r6.w;
    r6.z = -0.95 + r6.z;
    r6.z = saturate(10 * r6.z);
    r6.w = -0.95 + r7.w;
    r6.w = saturate(10 * r6.w);
    r6.zw = 1.0 - r6.zw;
    r6.z = dot(r6.zz, r6.ww);
    r5.w = r6.z + r5.w;
    r6.xyz = t0.Sample(s0_s, r6.xy).xyz;
    r4.y = r5.w + r4.y;
    r5.xyz = r5.www * r6.xyz + r5.xyz;
  }
  r0.xyz = r5.xyz / r4.y;
#if ENABLE_DITHERING
  r0.w = cmp(0 < cb0[2].z);
  if (r0.w != 0) {
    r1.xy = cb0[2].xy + v0.xy; // Temporal UV offset
    int4 r1i = int4(r1.xy, 0, 0);
    r1i.xy = r1i.xy & int2(63,63);
    float3 dither = t1.Load(r1i.xyz).xyz;
    dither = dither * 2.0 - 1.0;
#if ENABLE_LUMA
    r2.xyz = sqrt_mirrored(r0.xyz);
#else
    r2.xyz = sqrt(max(r0.xyz, 0.0));
#endif
    r3.xyz = cb0[2].w + r2.xyz;
    r3.xyz = min(cb0[2].z, r3.xyz);
    r1.xyz = r2.xyz + dither * r3.xyz;
    r0.xyz = sqr_mirrored(r1.xyz);
  }
#endif
  o0.xyz = r0.xyz;
  o0.w = 1;
}