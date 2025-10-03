#include "Includes/Common.hlsl"

Texture2D<float4> t1 : register(t1); // 1x LUT
Texture2D<float4> t0 : register(t0); // Background image

SamplerState s1_s : register(s1);
SamplerState s0_s : register(s0);

cbuffer cb1 : register(b1)
{
  float4 cb1[7];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[8];
}

void main(
  float4 v0 : SV_POSITION0,
  float4 v1 : COLOR0,
  float2 v2 : TEXCOORD0,
  out float4 outColor : SV_Target0)
{
  outColor.w = v1.w;

  float4 r0,r1,r2,r3,r4,r5;
  float2 uv = v2.xy;
#if ENABLE_LUMA && 0 // The original UV didn't work in UW, it was randomly shifted (edit: not true, unnecessary)
  uv = v0.xy / cb1[6].xy;
  uv.y = 1.0 - uv.y;
#endif

  // Skip distortions at 16:9 (not sure why, the original game just checked for a height of 1080, but that's because it was fixed to 16:9 all the times until the final swapchain copy)
  if (cb1[6].x == 1920.0 && cb1[6].y == 1080.0)
  {
    r0.xyzw = t0.Sample(s0_s, uv).xyzw;
    r0.xyzw = t1.Sample(s1_s, r0.w).xyzw;
    r0.xyz = v1.xyz * r0.xyz;
  }
  else
  {
    // Hardcoded pics size (they only cover a central vertical stripe of the 16:9 area)
    float width = 1920.0;
    float height = 846.0;

    float2 scale = 1.0;
#if ENABLE_LUMA // Fix credits being Vert- in UW
    float sourceAspectRatio = width / height;
    float targetAspectRatio = cb1[6].x / (cb1[6].y * height / 1080.0);

    if (targetAspectRatio >= sourceAspectRatio)
    {
      scale = targetAspectRatio / sourceAspectRatio;
    }

    // Center the UVs before scaling them
    uv = (uv - 0.5) * scale + 0.5;
    
    if (any(uv.xy < 0) || any(uv.xy > 1))
    {
      outColor.rgb = 0.0;
      return;
    }
#endif

    // Vignette?
    r1.xy = float2(width, height) * uv;
    r1.xy = frac(r1.xy);

    r2.xyzw = t0.Sample(s0_s, uv).xyzw; // This is a paletted texture, 1 channel, to save memory by not storing the whole RGB image, the result is quite low quality. This also means we can't linearly interpolate this
    r2.xyzw = t1.Sample(s1_s, r2.w).xyzw; // Texture palette lookup
    r3.xyzw = float4(0.00052083336,0,0,0.0011820331) + float4(uv, uv);
    r4.xyzw = t0.Sample(s0_s, r3.xy).xyzw;
    r4.xyzw = t1.Sample(s1_s, r4.w).xyzw;
    r3.xyzw = t0.Sample(s0_s, r3.zw).xyzw;
    r3.xyzw = t1.Sample(s1_s, r3.w).xyzw;
    r1.zw = float2(0.00052083336,0.0011820331) + uv;
    r5.xyzw = t0.Sample(s0_s, r1.zw).xyzw;
    r5.xyzw = t1.Sample(s1_s, r5.w).xyzw;
    r4.xyz = r4.xyz - r2.xyz;
    r2.xyz = r1.x * r4.xyz + r2.xyz;
    r4.xyz = r5.xyz - r3.xyz;
    r1.xzw = r1.x * r4.xyz + r3.xyz;
    r1.xzw = r1.xzw - r2.xyz;
    r1.xyz = r1.y * r1.xzw + r2.xyz;
    r0.xyz = v1.xyz * r1.xyz;
  }
  r0.w = -0.5 + cb0[7].x;
  r1.x = abs(r0.w) + abs(r0.w);
  r1.y = (cb0[7].x < 0.5);
  r2.xyzw = r1.yyyy ? float4(0.254790187,0.0982881486,-0.345970184,-0.00816007238) : float4(0.346920878,-1.29442966,0.947132885,-0.00329957902);
  r3.xyz = r2.xyw * r1.xxx;
  r1.z = r2.z * r1.x + 1;
  r0.w = abs(r0.w) * 2 + -0.555559993;
  r0.w = saturate(2.25002241 * r0.w);
  r1.w = 0.0627451017 * r0.w;
  r1.x = r2.w * r1.x + r1.w;
  r1.x = r1.y ? r3.z : r1.x;
  r2.xyz = r0.xyz * r3.x + r3.y;
  r2.xyz = r0.xyz * r2.xyz + r1.z;
  r0.xyz = r0.xyz * r2.xyz + r1.x;
  r0.w = -r0.w * 0.0627451017 + 1;
  r1.xzw = r0.xyz * r0.w;
  r0.xyz = r1.y ? r0.xyz : r1.xzw;
  r0.w = 1 - cb0[7].y;
  r1.x = (0.5 < abs(uv.y - 0.5));
  r0.w = r1.x ? r0.w : 1;
  outColor.xyz = r0.xyz * r0.w;

#if ENABLE_LUMA // Do AutoHDR
  outColor.rgb = gamma_to_linear(outColor.rgb, GCT_MIRROR);
  
  outColor.rgb = PumboAutoHDR(outColor.rgb, 400.0, LumaSettings.GamePaperWhiteNits); // The videos were in terrible quality and have compression artifacts in highlights, so avoid going too high
  
#if UI_DRAW_TYPE == 2 // Scale with scene brightness even if it's in UI
  outColor.rgb *= LumaSettings.GamePaperWhiteNits / LumaSettings.UIPaperWhiteNits;
#endif

  outColor.rgb = linear_to_gamma(outColor.rgb, GCT_MIRROR);
#endif
}