#include "../Includes/Common.hlsl"

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

// Runs after tonemapping/grading shader. This is the final shader before UI.
void main(
  float4 v0 : SV_POSITION0,
  float2 v1 : TEXCOORD0,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2;
  r0.xy = v1.xy * cb0[3].xy + cb0[3].zw;
  r0.zw = r0.xy * cb0[1].xy + cb0[1].zw;
  r0.z = t1.SampleBias(s1_s, r0.zw, cb1[79].y).w;
  r0.z = -0.5 + r0.z;
  r0.z = r0.z + r0.z;
  r1.xy = cb0[4].xy * r0.xy;
  r2.xy = cb1[48].xy * r0.xy;
  r1.xy = (int2)r1.xy;
  r1.zw = float2(0,0);
  r0.xyw = t0.Load(r1.xyzw).xyz;
#if 0
  r0.xyw = saturate(r0.xyw); // Luma: disabled
#elif 0
  r1.xyz = saturate(r0.xyw) * r0.z * max(min(GetLuminance(r0.xyw), 2.0), 1.0); // Luma: saturate on the film grain intensity variable instead, and allow film grain to be at max twice as intense as in SDR
#else
  r1.xyz = r0.xyw * r0.z;
#endif
  r1.xyz = cb0[0].xxx * r1.xyz;
  r0.z = GetLuminance(r0.xyw);
  r0.z = sqrt(max(r0.z, 0.0)); // Convert to perception space (approximate) // Luma: fixed to avoid NaNs and negative luminance
  r0.z = max(1.0 - cb0[0].y * r0.z, 0.0); // Luma: fixed to avoid negative film grain (note that in the game there's no film grain on white, which could look weird in HDR, but it's possibly intentional)
  r0.xyz = r1.xyz * r0.z + r0.xyw;
  r2.z = 0;
  r1.xyzw = t2.SampleLevel(s0_s, r2.xyz, 0).xyzw;
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