#include "Includes/Common.hlsl"

cbuffer ConstantBuffer : register(b0)
{
  float register0 : packoffset(c0);
  float register1 : packoffset(c1);
  float3 register2 : packoffset(c2);
  float4x4 register3 : packoffset(c3);
  float4 ALPHA_TEST_PARAM : packoffset(c7);
  float4 TEXEL_MARGIN : packoffset(c8);
}

SamplerState SAMPLER_ETHANHOUSE_EXT_LZX_CLOUD_ddsSampler_s : register(s0);
SamplerState SAMPLER_ETHANHOUSE_RADIALRAMP_01_L_ddsSampler_s : register(s1);
Texture2D<float4> texture0 : register(t0);
Texture2D<float4> texture1 : register(t1);

void main(
  float2 v0 : TEXCOORD0,
  float4 v1 : COLOR0,
  float4 v2 : TEXCOORD4,
  float4 v3 : COLOR1,
  float3 v4 : TEXCOORD5,
  float4 v5 : TEXCOORD2,
  float4 v6 : TEXCOORD8,
  out float4 o0 : SV_TARGET0,
  out float4 o1 : SV_TARGET1,
  out float o2 : SV_TARGET2)
{
  float4 r0,r1;
  r0.xyz = register2.xyz + -v2.xyz;
  r0.xyz = 0.01 * r0.xyz;
  r0.w = dot(r0.xyz, r0.xyz);
  r0.w = rsqrt(r0.w);
  r0.xyz = r0.xyz * r0.www;
  r0.w = dot(v4.xyz, v4.xyz);
  r0.w = rsqrt(r0.w);
  r1.xyz = v4.xyz * r0.www;
  r0.w = dot(r1.xyz, r0.xyz);
  r0.w = r0.w + r0.w;
  r0.xyz = r0.www * r1.xyz + -r0.xyz;
  r1.x = dot(r0.xyz, register3._m00_m10_m20);
  r1.y = dot(r0.xyz, register3._m01_m11_m21);
  r0.xy = r1.xy * float2(0.214888006,0.214888006) + float2(0.5,0.5);
  r0.x = texture1.Sample(SAMPLER_ETHANHOUSE_RADIALRAMP_01_L_ddsSampler_s, r0.xy).x;
  r0.xyz = v1.xyz * r0.xxx;
  r1.xyz = texture0.Sample(SAMPLER_ETHANHOUSE_EXT_LZX_CLOUD_ddsSampler_s, v0.xy).xyz;
  r0.xyz = r1.xyz * r0.xyz;
  r0.w = saturate(v2.w * 10000 + -5);
  r0.xyz = r0.xyz * r0.www + float3(0.060549099,0.060549099,0.060549099);
  r0.xyz = register0 * r0.xyz + float3(-0.060549099,-0.060549099,-0.060549099);
  r0.xyz = -v3.xyz + r0.xyz;
  o0.xyz = v3.www * r0.xyz + v3.xyz;
  r0.x = 0.060549099 + v1.w;
  o0.w = register1 * r0.x + -0.060549099;
  o1.xyzw = float4(0,0,0,0);
  o2.x = v5.z / v5.w;
  
  // Luma: fix spot light adding negative colors (not alpha) that darkened the scene with float textures (it's unclear why that didn't happen on UNORM, subtraction should darken them anyway, even if it'd stop at 0)
  // Anyway nothing should detract from the scene
  o0.w = saturate(o0.w);
  o0.rgb = max(o0.rgb, 0.0);
}