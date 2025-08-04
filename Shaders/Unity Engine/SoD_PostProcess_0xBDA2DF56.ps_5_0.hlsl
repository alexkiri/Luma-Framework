#include "../Includes/Common.hlsl"

Texture2DArray<float4> t4 : register(t4);
Texture2DArray<float4> t3 : register(t3);
Texture2DArray<float4> t2 : register(t2); // Bloom or additive color / mask
Texture2D<float4> t1 : register(t1); // Some mask
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
  r0.xy = v1.xy * cb0[3].xy + cb0[3].zw;
  r0.zw = r0.xy * cb0[1].xy + cb0[1].zw;
  r0.z = t1.SampleBias(s1_s, r0.zw, cb1[79].y).w;
  r0.z = -0.5 + r0.z;
  r0.z = r0.z + r0.z;
  r1.xy = cb0[4].xy * r0.xy;
  r1.xy = (int2)r1.xy;
  r1.zw = float2(0,0);
  r1.xyz = t0.Load(r1.xyzw).xyz;
#if 0
  r1.xyz = saturate(r1.xyz); // Luma: disabled
#elif 0
  r2.xyz = saturate(r1.xyw) * r0.z * max(min(GetLuminance(r1.xyw), 2.0), 1.0); // Luma: saturate on the film grain intensity variable instead, and allow film grain to be at max twice as intense as in SDR
#else
  r2.xyz = r1.xyz * r0.z;
#endif
  r2.xyz = cb0[0].x * r2.xyz;
  r0.z = GetLuminance(r1.xyz);
  r0.z = sqrt(max(r0.z, 0.0)); // Convert to perception space (approximate) // Luma: fixed to avoid NaNs and negative luminance
  r0.z = max(1.0 - cb0[0].y * r0.z, 0.0); // Luma: fixed to avoid negative film grain (note that in the game there's no film grain on white, which could look weird in HDR, but it's possibly intentional)
  r1.xyz = r2.xyz * r0.z + r1.xyz;
  
#if 1
  const float HDR10_MaxWhite = HDR10_MaxWhiteNits / sRGB_WhiteLevelNits;
  r1.xyz = Linear_to_PQ(r1.xyz / HDR10_MaxWhite, GCT_MIRROR);
#elif 1
  r1.xyz = linear_to_gamma(r1.xyz);
#else
  r2.xyz = pow(abs(r1.xyz), 1.0 / 2.4) * sign(r1.xyz); // LUMA: fixed negative values support
  r2.xyz = r2.xyz * float3(1.05499995,1.05499995,1.05499995) + float3(-0.0549999997,-0.0549999997,-0.0549999997);
  r3.xyz = cmp(float3(0.00313080009,0.00313080009,0.00313080009) >= r1.xyz);
  r1.xyz = float3(12.9232101,12.9232101,12.9232101) * r1.xyz;
  r1.xyz = r3.xyz ? r1.xyz : r2.xyz;
#endif
  r2.xy = cb0[2].xy * r0.xy;
  r0.xy = cb1[48].xy * r0.xy;
  r2.z = cb0[2].z;
  r0.w = t3.SampleBias(s1_s, r2.xyz, cb1[79].y).w;
  r0.w = r0.w * 2 + -1;
  r1.w = 1 - abs(r0.w);
  r0.w = cmp(r0.w >= 0);
  r0.w = r0.w ? 1 : -1;
  r1.w = sqrt(r1.w);
  r1.w = 1 - r1.w;
  r0.w = r1.w * r0.w;
#if 1 // LUMA: make dithering 10 bit for HDR
  r1.xyz += r0.w / 1023.f;
#else
  r1.xyz += r0.w / 255.f;
#endif

#if 1
  r1.xyz = PQ_to_Linear(r1.xyz, GCT_MIRROR) * HDR10_MaxWhite;
#elif 1
  r1.xyz = gamma_to_linear(r1.xyz);
#else
  r2.xyz = float3(0.0549999997,0.0549999997,0.0549999997) + r1.xyz;
  r2.xyz = float3(0.947867334,0.947867334,0.947867334) * r2.xyz;
  r2.xyz = pow(abs(r2.xyz), 2.4) * sign(r2.xyz); // LUMA: fixed negative values support
  r3.xyz = float3(0.0773993805,0.0773993805,0.0773993805) * r1.xyz;
  r1.xyz = cmp(float3(0.0404499993,0.0404499993,0.0404499993) >= r1.xyz);
  r1.xyz = r1.xyz ? r3.xyz : r2.xyz;
#endif

  r0.z = 0;
  r0.xyzw = t2.SampleLevel(s0_s, r0.xyz, 0).xyzw;
  o0.xyz = r0.w * r1.xyz + r0.xyz;
  r0.xy = cb1[46].xy * v1.xy;
  r0.xy = (uint2)r0.xy;
  r0.xy = (uint2)r0.xy; // ?
  r0.zw = float2(-1,-1) + cb1[46].xy;
  r0.zw = cb0[3].zw * r0.zw;
  r0.xy = r0.xy * cb0[3].xy + r0.zw;
  r0.xy = (uint2)r0.xy;
  r0.zw = float2(0,0);
  r0.x = t4.Load(r0.xyzw).x;
  o0.w = (cb0[5].x == 1.0) ? r0.x : 1;

#if UI_DRAW_TYPE == 2 // Scale by the inverse of the relative UI brightness so we can draw the UI at brightness 1x and then multiply it back to its intended range
  o0.rgb *= LumaSettings.GamePaperWhiteNits / LumaSettings.UIPaperWhiteNits;
#endif
}