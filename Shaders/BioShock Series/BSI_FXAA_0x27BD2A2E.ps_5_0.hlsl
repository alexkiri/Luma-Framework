#include "Includes/Common.hlsl"

cbuffer _Globals : register(b0)
{
  float2 fxaaQualityRcpFrame : packoffset(c0);
  float4 fxaaConsoleRcpFrameOpt : packoffset(c1);
  float4 fxaaConsoleRcpFrameOpt2 : packoffset(c2);
  float4 fxaaConsole360RcpFrameOpt2 : packoffset(c3);
  float fxaaQualitySubpix : packoffset(c4);
  float fxaaQualityEdgeThreshold : packoffset(c4.y);
  float fxaaQualityEdgeThresholdMin : packoffset(c4.z);
  float fxaaConsoleEdgeSharpness : packoffset(c4.w);
  float fxaaConsoleEdgeThreshold : packoffset(c5);
  float fxaaConsoleEdgeThresholdMin : packoffset(c5.y);
  float4 fxaaConsole360ConstDir : packoffset(c6);
}

SamplerState SceneTextureSampler_s : register(s0);
Texture2D<float4> SceneTextureTexture : register(t0);

#define cmp

void main(
  float4 v0 : TEXCOORD0,
  float2 v1 : TEXCOORD1,
  out float4 o0 : SV_Target0)
{
#if !ALLOW_AA // Disable FXAA (not directly useful as the game already has a setting for it)
  o0.rgba = SceneTextureTexture.SampleLevel(SceneTextureSampler_s, v1.xy, 0).rgba;
#else
  float4 r0,r1,r2,r3,r4,r5;
  r0.xyzw = SceneTextureTexture.SampleLevel(SceneTextureSampler_s, v1.xy, 0).xyzw;
  r1.xyz = SceneTextureTexture.Gather(SceneTextureSampler_s, v1.xy).xyz;
  r2.xyz = SceneTextureTexture.Gather(SceneTextureSampler_s, v1.xy, int2(-1, -1)).xzw;
  r1.w = max(r1.x, r0.w);
  r2.w = min(r1.x, r0.w);
  r1.w = max(r1.z, r1.w);
  r2.w = min(r2.w, r1.z);
  r3.x = max(r2.y, r2.x);
  r3.y = min(r2.y, r2.x);
  r1.w = max(r3.x, r1.w);
  r2.w = min(r3.y, r2.w);
  r3.x = fxaaQualityEdgeThreshold * r1.w;
  r1.w = -r2.w + r1.w;
  r2.w = max(fxaaQualityEdgeThresholdMin, r3.x);
  r2.w = cmp(r1.w >= r2.w);
  if (r2.w != 0) {
    r2.w = SceneTextureTexture.SampleLevel(SceneTextureSampler_s, v1.xy, 0, int2(1, -1)).w; // Luminance
    r3.x = SceneTextureTexture.SampleLevel(SceneTextureSampler_s, v1.xy, 0, int2(-1, 1)).w;
    r3.yz = r2.yx + r1.xz;
    r1.w = 1 / r1.w;
    r3.w = r3.y + r3.z;
    r3.yz = r0.ww * float2(-2,-2) + r3.yz;
    r4.x = r2.w + r1.y;
    r2.w = r2.z + r2.w;
    r4.y = r1.z * -2 + r4.x;
    r2.w = r2.y * -2 + r2.w;
    r2.z = r3.x + r2.z;
    r1.y = r3.x + r1.y;
    r3.x = abs(r3.y) * 2 + abs(r4.y);
    r2.w = abs(r3.z) * 2 + abs(r2.w);
    r3.y = r2.x * -2 + r2.z;
    r1.y = r1.x * -2 + r1.y;
    r3.x = abs(r3.y) + r3.x;
    r1.y = abs(r1.y) + r2.w;
    r2.z = r2.z + r4.x;
    r1.y = cmp(r3.x >= r1.y);
    r2.z = r3.w * 2 + r2.z;
    r2.x = r1.y ? r2.y : r2.x;
    r1.x = r1.y ? r1.x : r1.z;
    r1.z = r1.y ? fxaaQualityRcpFrame.y : fxaaQualityRcpFrame.x;
    r2.y = r2.z * 0.0833333358 + -r0.w;
    r2.z = r2.x + -r0.w;
    r2.w = r1.x + -r0.w;
    r2.x = r2.x + r0.w;
    r1.x = r1.x + r0.w;
    r3.x = cmp(abs(r2.z) >= abs(r2.w));
    r2.z = max(abs(r2.z), abs(r2.w));
    r1.z = r3.x ? -r1.z : r1.z;
    r1.w = saturate(abs(r2.y) * r1.w);
    r2.y = asfloat(asint(r1.y) & asint(fxaaQualityRcpFrame.x));
    r2.w = r1.y ? 0 : fxaaQualityRcpFrame.y;
    r3.yz = r1.zz * float2(0.5,0.5) + v1.xy;
    r3.y = r1.y ? v1.x : r3.y;
    r3.z = r1.y ? r3.z : v1.y;
    r4.xy = r3.yz + -r2.yw;
    r5.xy = r3.yz + r2.yw;
    r3.y = r1.w * -2 + 3;
    r3.z = SceneTextureTexture.SampleLevel(SceneTextureSampler_s, r4.xy, 0).w;
    r1.w = r1.w * r1.w;
    r3.w = SceneTextureTexture.SampleLevel(SceneTextureSampler_s, r5.xy, 0).w;
    r1.x = r3.x ? r2.x : r1.x;
    r2.x = 0.25 * r2.z;
    r0.w = -r1.x * 0.5 + r0.w;
    r1.w = r3.y * r1.w;
    r0.w = cmp(r0.w < 0);
    r3.x = -r1.x * 0.5 + r3.z;
    r3.y = -r1.x * 0.5 + r3.w;
    r3.zw = cmp(abs(r3.xy) >= r2.xx);
    r2.z = -r2.y * 1.5 + r4.x;
    r4.x = r3.z ? r4.x : r2.z;
    r2.z = -r2.w * 1.5 + r4.y;
    r4.z = r3.z ? r4.y : r2.z;
    r4.yw = asfloat(~asint(r3.zw));
    r2.z = asfloat(asint(r4.w) | asint(r4.y));
    r4.y = r2.y * 1.5 + r5.x;
    r4.y = r3.w ? r5.x : r4.y;
    r5.x = r2.w * 1.5 + r5.y;
    r4.w = r3.w ? r5.y : r5.x;
    if (r2.z != 0) {
      if (r3.z == 0) {
        r3.x = SceneTextureTexture.SampleLevel(SceneTextureSampler_s, r4.xz, 0).w;
      }
      if (r3.w == 0) {
        r3.y = SceneTextureTexture.SampleLevel(SceneTextureSampler_s, r4.yw, 0).w;
      }
      r2.z = -r1.x * 0.5 + r3.x;
      r3.x = r3.z ? r3.x : r2.z;
      r2.z = -r1.x * 0.5 + r3.y;
      r3.y = r3.w ? r3.y : r2.z;
      r3.zw = cmp(abs(r3.xy) >= r2.xx);
      r2.z = -r2.y * 2 + r4.x;
      r4.x = r3.z ? r4.x : r2.z;
      r2.z = -r2.w * 2 + r4.z;
      r4.z = r3.z ? r4.z : r2.z;
      r5.xy = asfloat(~asint(r3.zw));
      r2.z = asfloat(asint(r5.y) | asint(r5.x));
      r5.x = r2.y * 2 + r4.y;
      r4.y = r3.w ? r4.y : r5.x;
      r5.x = r2.w * 2 + r4.w;
      r4.w = r3.w ? r4.w : r5.x;
      if (r2.z != 0) {
        if (r3.z == 0) {
          r3.x = SceneTextureTexture.SampleLevel(SceneTextureSampler_s, r4.xz, 0).w;
        }
        if (r3.w == 0) {
          r3.y = SceneTextureTexture.SampleLevel(SceneTextureSampler_s, r4.yw, 0).w;
        }
        r2.z = -r1.x * 0.5 + r3.x;
        r3.x = r3.z ? r3.x : r2.z;
        r2.z = -r1.x * 0.5 + r3.y;
        r3.y = r3.w ? r3.y : r2.z;
        r3.zw = cmp(abs(r3.xy) >= r2.xx);
        r2.z = -r2.y * 2 + r4.x;
        r4.x = r3.z ? r4.x : r2.z;
        r2.z = -r2.w * 2 + r4.z;
        r4.z = r3.z ? r4.z : r2.z;
        r5.xy = asfloat(~asint(r3.zw));
        r2.z = asfloat(asint(r5.y) | asint(r5.x));
        r5.x = r2.y * 2 + r4.y;
        r4.y = r3.w ? r4.y : r5.x;
        r5.x = r2.w * 2 + r4.w;
        r4.w = r3.w ? r4.w : r5.x;
        if (r2.z != 0) {
          if (r3.z == 0) {
            r3.x = SceneTextureTexture.SampleLevel(SceneTextureSampler_s, r4.xz, 0).w;
          }
          if (r3.w == 0) {
            r3.y = SceneTextureTexture.SampleLevel(SceneTextureSampler_s, r4.yw, 0).w;
          }
          r2.z = -r1.x * 0.5 + r3.x;
          r3.x = r3.z ? r3.x : r2.z;
          r2.z = -r1.x * 0.5 + r3.y;
          r3.y = r3.w ? r3.y : r2.z;
          r3.zw = cmp(abs(r3.xy) >= r2.xx);
          r2.z = -r2.y * 2 + r4.x;
          r4.x = r3.z ? r4.x : r2.z;
          r2.z = -r2.w * 2 + r4.z;
          r4.z = r3.z ? r4.z : r2.z;
          r5.xy = asfloat(~asint(r3.zw));
          r2.z = asfloat(asint(r5.y) | asint(r5.x));
          r5.x = r2.y * 2 + r4.y;
          r4.y = r3.w ? r4.y : r5.x;
          r5.x = r2.w * 2 + r4.w;
          r4.w = r3.w ? r4.w : r5.x;
          if (r2.z != 0) {
            if (r3.z == 0) {
              r3.x = SceneTextureTexture.SampleLevel(SceneTextureSampler_s, r4.xz, 0).w;
            }
            if (r3.w == 0) {
              r3.y = SceneTextureTexture.SampleLevel(SceneTextureSampler_s, r4.yw, 0).w;
            }
            r2.z = -r1.x * 0.5 + r3.x;
            r3.x = r3.z ? r3.x : r2.z;
            r1.x = -r1.x * 0.5 + r3.y;
            r3.y = r3.w ? r3.y : r1.x;
            r2.xz = cmp(abs(r3.xy) >= r2.xx);
            r1.x = -r2.y * 8 + r4.x;
            r4.x = r2.x ? r4.x : r1.x;
            r1.x = -r2.w * 8 + r4.z;
            r4.z = r2.x ? r4.z : r1.x;
            r1.x = r2.y * 8 + r4.y;
            r4.y = r2.z ? r4.y : r1.x;
            r1.x = r2.w * 8 + r4.w;
            r4.w = r2.z ? r4.w : r1.x;
          }
        }
      }
    }
    r1.x = v1.x + -r4.x;
    r2.y = v1.y + -r4.z;
    r1.x = r1.y ? r1.x : r2.y;
    r2.xy = -v1.xy + r4.yw;
    r2.x = r1.y ? r2.x : r2.y;
    r2.yz = cmp(r3.xy < float2(0,0));
    r2.w = r2.x + r1.x;
    r2.yz = cmp(asint(r2.yz) != asint(r0.ww));
    r0.w = 1 / r2.w;
    r2.w = cmp(r1.x < r2.x);
    r1.x = min(r2.x, r1.x);
    r2.x = r2.w ? r2.y : r2.z;
    r1.w = r1.w * r1.w;
    r0.w = r1.x * -r0.w + 0.5;
    r1.x = fxaaQualitySubpix * r1.w;
    r0.w = asfloat(asint(r0.w) & asint(r2.x));
    r0.w = max(r0.w, r1.x);
    r1.xz = r0.ww * r1.zz + v1.xy;
    r2.x = r1.y ? v1.x : r1.x;
    r2.y = r1.y ? r1.z : v1.y;
    r0.xyz = SceneTextureTexture.SampleLevel(SceneTextureSampler_s, r2.xy, 0).xyz;
  }
  o0.xyzw = r0.xyzz;
#endif

#if UI_DRAW_TYPE == 2
  const float gamePaperWhite = LumaSettings.GamePaperWhiteNits / sRGB_WhiteLevelNits;
  const float UIPaperWhite = LumaSettings.UIPaperWhiteNits / sRGB_WhiteLevelNits;
  o0.rgb /= pow(UIPaperWhite, 1.0 / DefaultGamma);
  o0.rgb *= pow(gamePaperWhite, 1.0 / DefaultGamma);
#endif
}