#include "../Includes/Common.hlsl"

Texture2D<float4> t0 : register(t0);

SamplerState s0_s : register(s0);

cbuffer cb0 : register(b0)
{
  float4 cb0[4];
}

// Probably custom contrast and gamma etc
void main(
  float4 v0 : SV_POSITION0,
  float4 v1 : COLOR0,
  float2 v2 : TEXCOORD0,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1;
  r0.xyzw = t0.Sample(s0_s, v2.xy).xyzw;
  r0.xyzw = v1.xyzw * r0.xyzw;
  r0.xyz = r0.xyz * r0.www;
  o0.w = r0.w;

#if 1 // LUMA improved version of user calibration settings (do it in linear, with a pow on the additive color to balance the intensity, which anyway shouldn't ever be used)
  o0.xyz = lerp(MidGray, r0.xyz, cb0[3].x) + gamma_to_linear(cb0[3].y, GCT_MIRROR).x;
#else

  float3 colorSigns = sign(r0.xyz);
  r0.xyz = abs(r0.xyz);
  // Approximate version of sRGB encoding, with no branches (bad!!!)
  // https://github.com/TwoTailsGames/Unity-Built-in-Shaders/blob/6a63f93bc1f20ce6cd47f981c7494e8328915621/CGIncludes/UnityCG.cginc#L95
  // This clips more than 0.05 nits near black (assuming SDR at 80 nits)
#if 0
  r0.xyz = max(float3(0,0,0), r0.xyz);
  r0.xyz = log2(r0.xyz);
  r0.xyz = float3(0.416666657,0.416666657,0.416666657) * r0.xyz;
  r0.xyz = exp2(r0.xyz);
#else
  r0.xyz = pow(r0.xyz, 1.0 / 2.4);
#endif
  r0.xyz = (r0.xyz * 1.055) - 0.055;
#if 0
  r0.xyz = max(float3(0,0,0), r0.xyz);
#endif
  r0.xyz = lerp(0.5, r0.xyz, cb0[3].x); // "cb0[3].x" is usually 1. Contrast
#if 0
  r0.xyz = saturate(r0.xyz);
#endif
  // Approximate inverse formula of sRGB gamma encoding with no pow (bad!!!)
  r1.xyz = r0.xyz * float3(0.305306017,0.305306017,0.305306017) + float3(0.682171106,0.682171106,0.682171106);
  r1.xyz = r0.xyz * r1.xyz + float3(0.0125228781,0.0125228781,0.0125228781);
  o0.xyz = r0.xyz * r1.xyz;
  o0.rgb *= colorSigns;
  o0.rgb += cb0[3].y; // "cb0[3].x" is usually 0 (black floor)
  
#endif
}