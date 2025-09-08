#include "Includes/Common.hlsl"

cbuffer _Globals : register(b0)
{
  float MovieAlpha : packoffset(c0);
}

SamplerState CurrentTexture_s : register(s0);
Texture2D<float4> CurrentTexture : register(t0);

void main(
  float4 v0 : SV_Position0,
  float4 v1 : TEXCOORD0,
  out float4 o0 : SV_Target0)
{
  float4 r0;
  r0.xyzw = CurrentTexture.Sample(CurrentTexture_s, v1.xy).xyzw;

#if 0 // TODO: try to adjust from BT.601 to BT.709 in case they used wrong decoding? Information would be clipped at this point though
  r0.xyz = linear_to_gamma(BT601_To_BT709(gamma_to_linear(r0.xyz)));
#endif
  // TODO: Do the same shader for BS1 (0x4E3E2E59?)
  // TODO: fix the plasmids introduction tutorial video being stretched in UW?
  // TODO: add AutoHDR?

  o0.xyz = r0.xyz;
  o0.w = MovieAlpha;

#if UI_DRAW_TYPE == 2 // This is drawn in the UI phase but it's not UI, so make sure it scales with the game brightness instead
    o0.rgb *= pow(LumaSettings.GamePaperWhiteNits / LumaSettings.UIPaperWhiteNits, 1.0 / DefaultGamma);
#endif
}