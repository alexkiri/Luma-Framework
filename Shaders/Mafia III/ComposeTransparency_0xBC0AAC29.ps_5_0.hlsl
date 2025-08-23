#include "Includes/Common.hlsl"

Texture2D<float4> t2 : register(t2); // Additive transparency
Texture2D<float4> t1 : register(t1); // Some transparency mask
Texture2D<float4> t0 : register(t0); // Scene without transparency

SamplerState s1_s : register(s1);
SamplerState s0_s : register(s0);

cbuffer cb0 : register(b0)
{
  float4 cb0[11];
}

void main(
  float4 v0 : SV_Position0,
  out float4 o0 : SV_Target0,
  out float4 o1 : SV_Target1)
{
  float2 uv = cb0[10].zw * v0.xy; // Just the resolution
  float4 transparencyMask = t1.Sample(s0_s, uv).xyzw; // Blue is ignored, so this texture looks yellow usually (RG)
  float2 normalizedTransparencyShift = transparencyMask.xy - (127.0/255.0); // Neutral value for UNORM 8
  float backgroundBrightness = 1.0 - transparencyMask.a;
  // Scene distortion (ideally this should be after TAA/DLSS, but transparency is jittered too, so it needs to be applied before TAA)
  // TODO: write this to the DLSS bias mask? Or even better, run this again on depth and motion vectors textures, to shift them. Same for the other similar shader.
  float2 shiftedUV = uv + normalizedTransparencyShift * 0.1; // Hopefully this is adjusted by aspect ratio
  float3 transparencyColor = t2.Sample(s0_s, uv).rgb;
  float4 backgroundColor = t0.Sample(s1_s, shiftedUV).rgba;

#if ENABLE_LUMA && ENABLE_CITY_LIGHTS_BOOST
  // Boost up all the tranparent lights like lamp posts and car highlights etc, they look nicer in HDR
  if (transparencyMask.a == 0.0)
  {
    transparencyColor.rgb *= 1.5; // ~2 is not excessive, we could try some pow if necessary
  }
#endif

  o0.rgb = backgroundColor.rgb * backgroundBrightness + transparencyColor.rgb;
  o0.a = backgroundColor.a;
  // This is typically unused (it seems, no RT set)
  o1.a = transparencyMask.a;
  o1.rgb = transparencyColor.rgb;
}