#include "Includes/Common.hlsl"

cbuffer DrawableBuffer : register(b1)
{
  float4 FogColor : packoffset(c0);
  float4 DebugColor : packoffset(c1);
  float MaterialOpacity : packoffset(c2);
  float AlphaThreshold : packoffset(c3);
}

cbuffer InstanceBuffer : register(b5)
{
  float4 InstanceParams[8] : packoffset(c0);
}

SamplerState p_default_Material_051164A4424935531_Param_sampler_s : register(s0);
Texture2D<float4> p_default_Material_051164A4424935531_Param_texture : register(t0);

void main(
  float4 v0 : SV_POSITION0,
  float4 v1 : COLOR0,
  float4 v2 : TEXCOORD0,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2;
  r0.xyz = v1.xyz;
  r1.w = 1;
  r2.xyzw = p_default_Material_051164A4424935531_Param_texture.Sample(p_default_Material_051164A4424935531_Param_sampler_s, v2.xy).xyzw;
  
#if ENABLE_AUTO_HDR
  uint2 size;
  p_default_Material_051164A4424935531_Param_texture.GetDimensions(size.x, size.y);
  // The size of the main videos (matches "DevelopmentVerticalResolution")
  if (size.x == 1280 && size.y == 720)
  {
    r2.rgb = gamma_to_linear(r2.rgb);
    r2.rgb = PumboAutoHDR(r2.rgb, lerp(sRGB_WhiteLevelNits, 250.0, LumaSettings.GameSettings.HDRBoostIntensity), LumaSettings.GamePaperWhiteNits); // The videos were in low quality and have compression artifacts in highlights, so avoid going too high
    r2.rgb = linear_to_gamma(r2.rgb);
  }
#endif

  r0.w = v1.w * r2.w;
  r1.xyz = r2.xyz;
  r0.xyzw = r1.xyzw * r0.xyzw;
  r0.xyzw = r0.xyzw * InstanceParams[5].xyzw + InstanceParams[6].xyzw;
  o0.w = MaterialOpacity * r0.w;
  o0.xyz = r0.xyz;
}