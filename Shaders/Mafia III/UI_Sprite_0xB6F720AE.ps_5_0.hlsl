#include "Includes/Common.hlsl"

Texture2D<float4> t0 : register(t0);

SamplerState s0_s : register(s0);

cbuffer cb0 : register(b0)
{
  float4 cb0[1];
}

// This shader is used for a lot of stuff, videos are only one of the things
void main(
  float4 v0 : SV_Position0,
  float4 v1 : TEXCOORD0,
  float4 v2 : TEXCOORD1,
  out float4 o0 : SV_Target0)
{
  const float4 icb[] = { { 1.000000, 0, 0, 0},
                              { 0, 1.000000, 0, 0},
                              { 0, 0, 1.000000, 0},
                              { 0, 0, 0, 1.000000} };
  float4 r0,r1,r2,r3;
  uint4 r1i;
  uint size = 7;
  r0.xyzw = t0.Sample(s0_s, v2.xy).xyzw;
  r1.x = r0.w * 255.0 + 0.5;
  r1i.x = uint(r1.x);
  r1i.y = r1i.x & size;
  r1i.x = (r1i.x >> size) & 1u;
  r1.y = float(r1i.y) / float(size);
  r1.x = r1i.x ? 0.0 : r1.y;
  r1.y = r0.w * 255.0; // This one misses +0.5 for some reason
  r1i.y = uint(r1.y);
  r1i.z = r1i.y & size;
  r1i.y = (r1i.y >> size) & 1u;
  r1.z = float(r1i.z) / float(size);
  r1.y = r1i.y ? r1.z : 0.0;

  r2.xyzw = cb0[0].wwww == float4(1,2,3,4);
  r1.y = r2.w ? r1.y : r0.w;
  r1.w = r2.z ? r1.x : r1.y;

  r3.xyzw = saturate(r0.xyzw); // It seems like this clamp is intentional for some reason
  r1.xyz = r0.xyz;
  r1.xyzw = r2.y ? r3.xyzw : r1.xyzw;
  r0.xyzw = r2.x ? abs(r0.xyzw) : r1.xyzw; // Abs?
  r1.w = r0.w;
  r2.xyz = uint3(cb0[0].xyz);
  r1.x = dot(r0.xyzw, icb[r2.x+0].xyzw);
  r1.y = dot(r0.xyzw, icb[r2.y+0].xyzw);
  r1.z = dot(r0.xyzw, icb[r2.z+0].xyzw);
  o0.xyzw = v1.xyzw * r1.xyzw;

#if 0 // If the videos film grain shader (0x6B4B9B6D) turned out to not be enough, we could fall back onto this, but don't really know when this is playing a movie or any other UI sprite (maybe movies are sRGB views? They are all 1920x1080!)
  bool isWritingOnSwapchain = LumaData.CustomData1 != 0;
  bool isSourceScene = LumaData.CustomData2 != 0;
  if (isWritingOnSwapchain) // Note: this isn't always the case
  {
#if ENABLE_AUTO_HDR // This was already linear->linear
    if (!isSourceScene)
    {
      o0.rgb = PumboAutoHDR(o0.rgb, 600.0, LumaSettings.GamePaperWhiteNits);
    }
#endif

    o0.xyz = linear_to_sRGB_gamma(o0.xyz, GCT_MIRROR); // Needed because the original view was a R8G8B8A8_UNORM_SRGB, with the input being float/linear, so there was an implicity sRGB encoding.
#if UI_DRAW_TYPE == 2 // This is drawn in the UI phase but it's not really UI, so make sure it scales with the game brightness instead
  	o0.rgb *= pow(LumaSettings.GamePaperWhiteNits / LumaSettings.UIPaperWhiteNits, 1.0 / DefaultGamma);
#endif
  }
#endif
}