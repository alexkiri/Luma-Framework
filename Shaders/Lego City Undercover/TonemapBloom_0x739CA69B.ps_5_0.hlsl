#include "../Includes/Common.hlsl"

cbuffer g_BlurParamsPS_CB : register(b0)
{
  struct
  {
    float4 tint;
  } g_BlurParamsPS : packoffset(c0);
}

SamplerState texture0_ss_s : register(s0);
Texture2D<float4> texture0 : register(t0);

void main(
  float4 v0 : SV_Position0,
  float4 v1 : TEXCOORD0,
  float4 v2 : TEXCOORD1,
  float4 v3 : TEXCOORD2,
  float4 v4 : TEXCOORD3,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3,r4;

  // Downscale
  r0.rgb = texture0.Sample(texture0_ss_s, v1.xy).rgb;
  r2.rgb = texture0.Sample(texture0_ss_s, v2.xy).rgb;
  r3.rgb = texture0.Sample(texture0_ss_s, v3.xy).rgb;
  r4.rgb = texture0.Sample(texture0_ss_s, v4.xy).rgb;

#if 1 // Some kind of tonemapping? Or anyway highlights tweaking. I can't really explain it, but no need to change it.
  r1.x = max3(r0.rgb);
  r1.y = max3(r2.rgb);
  r1.z = max3(r3.rgb);
  r1.w = max3(r4.rgb);
  r1.xyzw = sqr_mirrored(r1.xyzw * 0.5); // Luma: added negative values support (there shouldn't be any)
  float3 colorsSum = 0.0;
  colorsSum += r0.xyz * r1.x;
  colorsSum += r2.xyz * r1.y;
  colorsSum += r3.xyz * r1.z;
  colorsSum += r4.xyz * r1.w;
#else
  float3 colorsSum = r0.rgb + r2.rgb + r3.rgb + r4.rgb;
#endif

  o0.xyz = colorsSum * 0.25 * g_BlurParamsPS.tint.w;

#if 0 // Luma: disable basic TM, given we now work in HDR
  o0.xyz /= max(1, max3(o0.xyz));
#endif
#if 1 // Keep it as it's important to preserve the look, this is undone when the final texture is sampled, it's to optimize the encoding for the original UNORM render target, however we can't change it as possibly there's some color tints applying during the mips blurrying
  o0.xyz = sqrt_mirrored(o0.xyz); // Approximate gamma space // Luma: made it support negative values
#endif
  o0.xyz *= g_BlurParamsPS.tint.xyz;
#if 1 // Luma: removed saturate
  o0.xyz = saturate(o0.xyz);
#endif
  o0.w = 1;
}