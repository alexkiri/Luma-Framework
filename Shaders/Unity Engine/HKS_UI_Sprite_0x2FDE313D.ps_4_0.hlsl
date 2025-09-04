#include "../Includes/Common.hlsl"
#include "../Includes/Reinhard.hlsl"
#include "../Includes/ColorGradingLUT.hlsl"

Texture2D<float4> t0 : register(t0);

SamplerState s0_s : register(s0);

void main(
  float4 v0 : SV_POSITION0,
  float2 v1 : TEXCOORD0,
  out float4 o0 : SV_Target0)
{
  float4 r0;
  r0.xyzw = t0.Sample(s0_s, v1.xy).xyzw;
  o0.xyz = r0.xyz;
  o0.w = 1;

#if 0 // Moved to tonemapping pass
  if (LumaData.CustomData1)
  {
    o0.rgb = gamma_to_linear(o0.rgb, GCT_MIRROR); // Unlikely to need mirroring but... whatever
    o0.rgb = PumboAutoHDR(o0.rgb, 600.0, LumaSettings.GamePaperWhiteNits);
    o0.rgb = linear_to_gamma(o0.rgb, GCT_MIRROR);
  }
#endif
}