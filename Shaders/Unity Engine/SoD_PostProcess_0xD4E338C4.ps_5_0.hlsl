#include "../Includes/Common.hlsl"

Texture2DArray<float4> t3 : register(t3);
Texture2DArray<float4> t2 : register(t2);
Texture2DArray<float4> t1 : register(t1);
Texture2DArray<float4> t0 : register(t0); // Scene

SamplerState s1_s : register(s1);
SamplerState s0_s : register(s0);

cbuffer cb1 : register(b1)
{
  float4 cb1[80];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[6];
}

#define cmp -

// Runs after tonemapping/grading shader. This is the final shader before UI.
void main(
  float4 v0 : SV_POSITION0,
  float2 v1 : TEXCOORD0,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3;
  r0.zw = float2(0,0);
  r1.xy = v1.xy * cb0[3].xy + cb0[3].zw;
  r1.zw = cb0[4].xy * r1.xy;
  r0.xy = (int2)r1.zw;
  r0.xyz = t0.Load(r0.xyzw).xyz;

#if 1
  const float HDR10_MaxWhite = HDR10_MaxWhiteNits / sRGB_WhiteLevelNits;
  r0.xyz = Linear_to_PQ(r0.xyz / HDR10_MaxWhite, GCT_MIRROR);
#elif 1
  r0.xyz = linear_to_gamma(r0.xyz);
#else
  r2.xyz = pow(abs(r0.xyz), 1.0 / 2.4) * sign(r0.xyz); // LUMA: fixed negative values support
  r2.xyz = r2.xyz * float3(1.05499995,1.05499995,1.05499995) + float3(-0.0549999997,-0.0549999997,-0.0549999997);
  r3.xyz = cmp(float3(0.00313080009,0.00313080009,0.00313080009) >= r0.xyz);
  r0.xyz = float3(12.9232101,12.9232101,12.9232101) * r0.xyz;
  r0.xyz = r3.xyz ? r0.xyz : r2.xyz;
#endif

  r2.xy = cb0[2].xy * r1.xy;
  r1.xy = cb1[48].xy * r1.xy;
  r2.z = cb0[2].z;
  r0.w = t2.SampleBias(s1_s, r2.xyz, cb1[79].y).w;
  r0.w = r0.w * 2 + -1;
  r1.w = 1 + -abs(r0.w);
  r0.w = cmp(r0.w >= 0);
  r0.w = r0.w ? 1 : -1;
  r1.w = sqrt(r1.w);
  r1.w = 1 + -r1.w;
  r0.w = r1.w * r0.w;
#if 1 // LUMA: make dithering 10 bit for HDR
  r0.xyz += r0.w / 1023.f;
#else
  r0.xyz += r0.w / 255.f;
#endif

#if 1 // Update dithering to work in PQ
  r0.xyz = PQ_to_Linear(r0.xyz, GCT_MIRROR) * HDR10_MaxWhite;
#elif 1
  r0.xyz = gamma_to_linear(r0.xyz);
#else
  r2.xyz = float3(0.0549999997,0.0549999997,0.0549999997) + r0.xyz;
  r2.xyz = float3(0.947867334,0.947867334,0.947867334) * r2.xyz;
  r2.xyz = pow(abs(r2.xyz), 2.4) * sign(r2.xyz); // LUMA: fixed negative values support
  r3.xyz = float3(0.0773993805,0.0773993805,0.0773993805) * r0.xyz;
  r0.xyz = cmp(float3(0.0404499993,0.0404499993,0.0404499993) >= r0.xyz);
  r0.xyz = r0.xyz ? r3.xyz : r2.xyz;
#endif

  r1.z = 0;
  r1.xyzw = t1.SampleLevel(s0_s, r1.xyz, 0).xyzw;
  o0.xyz = r1.w * r0.xyz + r1.xyz;
  r0.xy = cb1[46].xy * v1.xy;
  r0.xy = (uint2)r0.xy;
  r0.xy = (uint2)r0.xy; // ?
  r0.zw = float2(-1,-1) + cb1[46].xy;
  r0.zw = cb0[3].zw * r0.zw;
  r0.xy = r0.xy * cb0[3].xy + r0.zw;
  r0.xy = (uint2)r0.xy;
  r0.zw = float2(0,0);
  r0.x = t3.Load(r0.xyzw).x;
  o0.w = (cb0[5].x == 1.0) ? r0.x : 1;

#if UI_DRAW_TYPE == 2 // Scale by the inverse of the relative UI brightness so we can draw the UI at brightness 1x and then multiply it back to its intended range
  o0.rgb *= LumaSettings.GamePaperWhiteNits / LumaSettings.UIPaperWhiteNits;
#endif
}