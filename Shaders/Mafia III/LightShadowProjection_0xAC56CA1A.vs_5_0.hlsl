#include "Includes/Common.hlsl"

cbuffer cb1 : register(b1)
{
  float4 cb1[33];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[3];
}

void main(
  uint4 v0 : POSITION0,
  float4 v1 : TEXCOORD0,
  out float4 o0 : SV_Position0,
  out float4 o1 : TEXCOORD0,
  out float4 o2 : TEXCOORD1)
{
  float4 r0,r1;
  r0.xyzw = (uint4)v0.xyzw;
  r1.xy = float2(1,256) * cb0[0].ww;
  r0.x = dot(r0.xy, r1.xy);
  r0.y = dot(r0.zw, r1.xy);
  r0.xy = cb0[0].xy + r0.xy;
  r0.xy = r0.xy * cb0[1].xy + cb0[1].zw;
  r0.z = 1 - r0.y;
  o0.xy = r0.xz * 2.0 - 1.0;
  o0.z = cb0[2].x;
  o0.w = 1;
  o1.xyz = 0.0;
  r0.xy = v1.xy * cb0[1].xy + cb0[1].zw; // TODO: This would be the matrix to jitter, we could literally do that in all shaders manually
  o1.w = r0.x;
  r0.xz = r0.xy * float2(2.0, -2.0) + float2(-1.0, 1.0); // To NDC
  o2.x = r0.y;
  r0.xy = -cb1[6].xy + r0.xz;
  r0.y = cb1[21].w * r0.y;
  r0.z = cb1[21].z * cb1[21].y;
  r1.xz = r0.xy * r0.z;
  r1.y = cb1[21].y;
  r1.w = 1.0;
  r0.y = dot(cb1[30].xyzw, r1.xyzw);
  r0.z = dot(cb1[31].xyzw, r1.xyzw);
  r0.w = dot(cb1[32].xyzw, r1.xyzw);
  o2.yzw = -cb1[0].xyz + r0.yzw;
#if 1
  float2 jitters = float2(LumaData.CustomData3, LumaData.CustomData4);
  o1.w += jitters.x; // Horizontal screen space shift
  o2.x += jitters.y; // Vertical screen space shift
#elif DEVELOPMENT // Tests
  //o1.zw += DVS5; // Shifts... xy no
  //o0.w += DVS1; // Changing any o0 breaks depth tests...
  //o1.w += DVS2; // Horizontal screen space shift
  //o2.x += DVS3; // Vertical screen space shift
  o2.x += 0.00025; // Hack to fix light projections flickering // TODO: fix... These jitter
#endif
}