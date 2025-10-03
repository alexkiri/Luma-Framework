#include "Includes/Common.hlsl"

Texture2D<float4> t3 : register(t3);
Texture2D<float4> t2 : register(t2);
Texture2D<float4> t1 : register(t1);
Texture2D<float4> t0 : register(t0);

SamplerState s3_s : register(s3);
SamplerState s2_s : register(s2);
SamplerState s1_s : register(s1);
SamplerState s0_s : register(s0);

cbuffer cb2 : register(b2)
{
  float4 cb2[1];
}

cbuffer cb1 : register(b1)
{
  float4 cb1[8];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[27];
}

// Shader to draw the boy (almost always renders first)
void main(
  float4 v0 : SV_POSITION0,
  float2 v1 : TEXCOORD0,
  float v1z : TEXCOORD1,
  float v1w : TEXCOORD6,
  float4 v2 : TEXCOORD2,
  float3 v3 : TEXCOORD3,
  float3 v4 : TEXCOORD4,
  float4 v5 : TEXCOORD5,
  out float4 o0 : SV_Target0)
{
  //TODOFT: this decomp is broken, it looks off, however the asm produces exactly the same code.
  float4 r0,r1,r2,r3,r4,r5;
  r0.xy = v2.xy / v2.w;
  r1.xyzw = t1.Sample(s1_s, r0.xy).xyzw;
  r0.xy = v4.xy * float2(1.5,1.5) + r0.xy;
  r0.xyzw = t2.SampleLevel(s2_s, r0.xy, 0).xyzw;
  r0.x = cb1[7].z * r0.x + cb1[7].w;
  r0.x = 1 / r0.x;
  r0.x = -v2.z + r0.x;
  r0.x = -0.25 + abs(r0.x);
  r0.x = saturate(4 * r0.x);
  r0.yzw = log2(max(r1.xyz, 0.000977517106));
  r1.xy = -r0.zw + -r0.wy;
  r1.xy = float2(0.333333343,0.333333343) * r1.xy;
  r1.xy = r0.yz * float2(-0.666666687,-0.666666687) + -r1.xy;
  r1.z = max(abs(r1.x), abs(r1.y));
  r1.z = 1 / r1.z;
  r1.w = min(abs(r1.x), abs(r1.y));
  r1.z = r1.w * r1.z;
  r1.w = r1.z * r1.z;
  r2.x = r1.w * 0.0208350997 - 0.0851330012;
  r2.x = r1.w * r2.x + 0.180141002;
  r2.x = r1.w * r2.x - 0.330299497;
  r1.w = r1.w * r2.x + 0.999866009;
  r2.x = r1.z * r1.w;
  r2.x = r2.x * -2 + 1.57079637;
  r2.y = (abs(r1.y) < abs(r1.x)) ? 1.0 : 0.0;
  r2.x = asfloat(asint(r2.y) & asint(r2.x));
  r1.z = r1.z * r1.w + r2.x;
  r1.w = (r1.y < -r1.y);
  r1.w = asfloat(asint(r1.w) & 0xc0490fdb);
  r1.z = r1.z + r1.w;
  r1.w = min(r1.x, r1.y);
  r1.x = max(r1.x, r1.y);
  r1.x = (r1.x >= -r1.x);
  r1.y = (r1.w < -r1.w);
  r1.x = asfloat(asint(r1.x) & asint(r1.y));
  r1.x = r1.x ? -r1.z : r1.z;
  r1.yzw = saturate(-r0.yzw);
  r0.y = dot(-r0.yzw, float3(0.333333343,0.333333343,0.333333343));
  r0.zw = r1.zw + r1.wy;
  r0.zw = float2(0.333333343,0.333333343) * r0.zw;
  r0.zw = r1.yz * float2(0.666666687,0.666666687) + -r0.zw;
  r0.z = dot(r0.zw, r0.zw);
  r0.z = sqrt(r0.z);
  r0.w = (0 < r0.z);
  r0.w = asfloat(asint(r1.x) & asint(r0.w));
  sincos(r0.w, r1.x, r2.x);
  r1.y = r2.x;
  r0.w = r0.x * -2 + 3;
  r0.x = r0.x * r0.x;
  r1.z = r0.w * r0.x + 1;
  r0.x = r0.w * r0.x;
  r0.x = r0.x / v2.w;
  r0.y = r0.y * r1.z + cb0[15].z;
  r2.xyzw = v1.xyxy < float4(0.75,0.5,0.5,0.5);
  int4 r2i = asint(r2) & 1;
  r3.xyzw = float4(0.5,0.25,0.25,0.25) < v1.xyxy;
  r2i *= asint(r3) & 1;
  r2i = (r2i != 0) ? 1 : 0;
  r1.zw = asfloat(r2i.yw & r2i.xz);
  r0.w = r1.z ? cb0[15].y : cb0[15].x;
  r0.y = r0.y + -r0.w;
  r0.w = r0.w * -2 + 1;
  r0.y = saturate(r0.y / r0.w);
  r0.w = -r1.x * r0.z + r0.y;
  r2.xy = r1.xy * r0.zz + r0.yy;
  r2.z = saturate(-r1.y * r0.z + r0.w);
  r2.xyz = v3.xyz + r2.xyz;
  r0.y = r0.y - 0.2;
  r0.y = r0.y * -5;
  r0.y = max(0, r0.y);
  r0.z = saturate(v1w);
  r3.xyzw = t3.Sample(s3_s, v1.xy).xyzw;
  r0.w = saturate(r3.x * cb0[26].x + cb0[26].y);
  r0.w = r0.w * r0.z;
  r1.xy = cb0[26].zw * r0.ww;
  r0.w = saturate(r3.w * cb0[24].x + cb0[24].y);
  r2.w = saturate(r3.w * cb0[25].x + cb0[25].y);
  r3.xy = cb0[25].zw * r2.ww;
  r0.z = r0.w * r0.z;
  r0.zw = cb0[24].zw * r0.zz;
  r0.z = max(r1.x, r0.z);
  r0.z = 1 - r0.z;
  r0.z = r1.w ? 1 : r0.z;
  r1.xzw = r1.z ? float3(4,4,1) : float3(8,12,2);
  r4.xyzw = t0.Sample(s0_s, v1.xy).xyzw;
  r5.xyz = r4.xyz * r0.zzz;
  r4.xyz = -r4.xyz * r0.zzz + float3(0.400000006,0.300000012,0.300000012);
  r3.xzw = r3.xxx * r4.xyz + r5.xyz;
  r0.z = max(r0.w, r3.y);
  r0.yw = float2(0.600000024,2.5) * r0.yw;
  r2.w = 1.25 * r3.y;
  r0.w = max(r2.w, r0.w);
  r0.z = max(r0.z, r1.y);
  r1.y = 3.33333325 * r1.y;
  r0.w = max(r1.y, r0.w);
  r0.w = 1 - r0.w;
  r1.x = pow(v5.x, r1.x); // Luma: fixed NaNs
  r0.z = r1.x * r0.z;
  r4.xyz = cb0[16].xyz * r0.zzz;
  r4.xyz = r4.xyz + r4.xyz;
  r2.xyz = r2.xyz * r3.xzw + r4.xyz;
  r0.x = r1.z * r0.x;
  r0.z = saturate(v4.z);
  r0.z = r0.z * r0.z;
  r0.z = r0.z * r0.z;
  r1.x = r0.z * r0.z;
  r1.x = v5.w * r1.x;
  r1.y = r1.x * r1.w;
  r0.x = r0.x * r0.z + r1.y;
  r1.yz = (v1.xy < float2(0.5,0.25));
  r0.z = r1.z ? r1.y : 0;
  r0.z = asfloat(asint(r1.z) & asint(r1.y));
  r1.yz = (float2(0.25,0) < v1.xy);
  r1.y = asfloat(asint(r1.z) & asint(r1.y));
  r0.z = asfloat(asint(r0.z) & asint(r1.y));
  r0.z = asfloat(asint(r0.z) & 0x3f800021);
  r0.x = r1.x * r0.z + r0.x;
  r1.xyz = cb0[16].xyz * v3.xyz;
  r1.xyz = r1.xyz * r0.w;
  r0.xzw = r0.x * r1.xyz + r2.xyz;
  r1.xyz = cb0[3].xyz * r0.xzw;
  r1.xz = r1.x + r1.yz;
  r1.y = r1.y * r1.z;
  r1.x = r0.w * cb0[3].z + r1.x;
  r1.y = sqrt(r1.y); // Luma: fixed NaNs
  r1.y = dot(cb0[3].ww, r1.yy);
  r1.x = r1.x + r1.y;
  r1.xyz = r1.x + -r0.xzw;
  r0.xyz = r0.y * r1.xyz + r0.xzw;
  r0.xyz = r0.xyz * cb0[17].xyz + -cb2[0].xyz;
  r0.w = 1 - cb2[0].w;
  r0.w = max(v1z, r0.w);
  r0.w = min(1, r0.w);
  o0.xyz = r0.w * r0.xyz + cb2[0].xyz;
  o0.w = 1;
}