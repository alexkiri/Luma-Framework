#include "Includes/Common.hlsl"

cbuffer _Globals : register(b0)
{
  float ImageSpace_hlsl_BlurPixelShader00000000000000000000000000000124_9bits : packoffset(c0) = {0};
  float4 fogColor : packoffset(c1);
  float3 fogTransform : packoffset(c2);
  float2 fogLuminance : packoffset(c3);
  row_major float3x4 screenDataToCamera : packoffset(c4);
  float globalScale : packoffset(c7);
  float sceneDepthAlphaMask : packoffset(c7.y);
  float globalOpacity : packoffset(c7.z);
  float distortionBufferScale : packoffset(c7.w);
  float3 wToZScaleAndBias : packoffset(c8);
  float4 screenTransform[2] : packoffset(c9);
  float4 textureToPixel : packoffset(c11);
  float4 pixelToTexture : packoffset(c12);
  float maxScale : packoffset(c13) = {0};
  float bloomAlpha : packoffset(c13.y) = {0};
  float sceneBias : packoffset(c13.z) = {1};
  float3 gammaSettings : packoffset(c14);
  float exposure : packoffset(c14.w) = {0};
  float deltaExposure : packoffset(c15) = {0};
  float4 SampleOffsets[2] : packoffset(c16);
  float4 SampleWeights[4] : packoffset(c18);
  float4 PWLConstants : packoffset(c22);
  float PWLThreshold : packoffset(c23);
  float ShadowEdgeDetectThreshold : packoffset(c23.y);
  float4 ColorFill : packoffset(c24);
  float2 LowResTextureDimensions : packoffset(c25);
  float2 DownsizeTextureDimensions : packoffset(c25.z);
}

SamplerState s_buffer_s : register(s0); // Without Luma, this is a nearest sampler, however, it seemed to make no difference? I can't explain why given that it downscales to x/4 and y/4 resolution with 4 samples, which isn't enough unless it's bilinear. Maybe it's because the coordinates were centered to texels already, which isn't great
Texture2D<float4> s_buffer : register(t0);

#define cmp

void main(
  float4 v0 : TEXCOORD0,
  float4 v1 : TEXCOORD1,
#if ENABLE_IMPROVED_BLOOM // Not in the original PS signature but it should be ok
  float4 vp : SV_Position0,
#endif // ENABLE_IMPROVED_BLOOM
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3;
  int4 r1i;

  // Note: these coordinates are weird and flip between the first and select element
  float4 v[2] = { v0, v1 };

#if ENABLE_IMPROVED_BLOOM
#if 0 // Doesn't work
  float2 uv = vp.xy * pixelToTexture.zw;
#else
  int2 sourceSize;
  s_buffer.GetDimensions(sourceSize.x, sourceSize.y);
  int2 targetSize = int2(uint2(sourceSize) / 4u); // It uses a x/4 and y/4 mip, I don't know what rounding they used for pixel scaling, but likely floor (we seemengly confirmed it, but not to 100%)
  float2 uv = vp.xy / float2(targetSize);
#endif

#if 0 // Might be right, but it seems to shift
  uv = lerp(v[0].xy, v[+0].wz, 0.5);
#endif
#endif // ENABLE_IMPROVED_BLOOM

  r0.xyzw = 0.0;
  r1i.x = 0;
#if ENABLE_LUMA && ENABLE_IMPROVED_BLOOM // New bloom downscale code, this fixes the original formula shifting UVs a bit (output is shifted, possibly not intentional)
  // Offsets (center of each quadrant of a 4x4 block)
  float2 offsets[4] = {
    float2(-1, -1),
    float2(1, -1),
    float2(-1, 1),
    float2(1, 1)
  };

  float4 c = 0;
  [unroll]
  for (int i = 0; i < 4; i++)
  {
    r0 += s_buffer.Sample(s_buffer_s, uv + (offsets[i] / sourceSize));
  }
  r0 /= 4.0;
#elif ENABLE_LUMA && ENABLE_IMPROVED_BLOOM && 0 // Upgrade bloom to 8 samples instead of 4, otherwise it's pixellated due to offsets being too big for high resolutions. This still isn't perfect as we only scan diagonally. This barely changes anything.
  float2 prevUV_A = uv;
  float2 prevUV_B = uv;
  [unroll]
  while (true) {
    if (r1i.x >= 3) break;
    float4 sceneColor;

    // It seems like the second iteration is all black as it samples out of bounds, so we can't blend with the previous uv.
    // This seems to make no sense.
    bool firstIteration = r1i.x == 0;
    float blendAlpha = firstIteration ? 0.5 : 1.0;
    
    sceneColor = s_buffer.Sample(s_buffer_s, lerp(prevUV_A, v[(r1i.x >> 1)+0].xy, blendAlpha)).xyzw;
    sceneColor += s_buffer.Sample(s_buffer_s, v[(r1i.x >> 1)+0].xy).xyzw;
    r0.xyzw += sceneColor * SampleWeights[r1i.x].xyzw / 2.0;

    sceneColor = s_buffer.Sample(s_buffer_s, lerp(prevUV_B, v[(r1i.x >> 1)+0].wz, blendAlpha)).xyzw;
    sceneColor += s_buffer.Sample(s_buffer_s, v[(r1i.x >> 1)+0].wz).xyzw;
    r0.xyzw += sceneColor * SampleWeights[r1i.x + 1].xyzw / 2.0;

    // See "SampleOffsets"
    prevUV_A = v[(r1i.x >> 1)+0].xy;
    prevUV_B = v[(r1i.x >> 1)+0].wz;

    r1i.x += 2;
  }
#elif 1 // 2 iterations
  while (true) {
    if (r1i.x >= 3) break;
    r2.xyzw = s_buffer.Sample(s_buffer_s, v[(r1i.x >> 1)+0].xy).xyzw;
    r2.xyzw = r2.xyzw * SampleWeights[r1i.x].xyzw + r0.xyzw;
    r3.xyzw = s_buffer.Sample(s_buffer_s, v[(r1i.x >> 1)+0].wz).xyzw;
    r0.xyzw = r3.xyzw * SampleWeights[r1i.x + 1].xyzw + r2.xyzw;
    r1i.x += 2;
  }
#else // Disable downscaling
  r0.xyzw = s_buffer.Sample(s_buffer_s, uv).xyzw;
#endif

  float luminance = GetLuminance(r0.xyz); // Fixed BT.601 luminance
  luminance = max(9.99999975e-006, luminance);
  r1.y = cmp(luminance < PWLThreshold);
  r1.zw = luminance * PWLConstants.xz + PWLConstants.yw;
  r1.y = r1.y ? r1.z : r1.w;
  float inverseLuminance = max(0.0, r1.y / luminance);
  r0.xyz *= inverseLuminance;

  // Strip the sign bit and test for infinity
  r1.xyzw = asfloat(asint(r0.xyzw) & int(0x7fffffff));
  r1i.xyzw = asint(r1.xyzw) == int(0x7f800000);
  // Test for NaN
  r2.xyzw = cmp(r0.xyzw != r0.xyzw); // 0xFFFFFFFF for NaN, 0 for not NaN

  // Combine "bad" flags across channels ("r1i.x")
  r1i.x = r1i.y | r1i.x;
  r1i.x = r1i.z | r1i.x;
  r1i.x = r1i.w | r1i.x;
  r1i.x = asint(r2.x) | r1i.x;
  r1i.x = asint(r2.y) | r1i.x;
  r1i.x = asint(r2.z) | r1i.x;
  r1i.x = asint(r2.w) | r1i.x;
#if !ENABLE_LUMA // scRGB support
  // Test for negatives
  r2.xyzw = cmp(r0.xyzw < 0.0);
  r1i.x = asint(r2.x) | r1i.x;
  r1i.x = asint(r2.y) | r1i.x;
  r1i.x = asint(r2.z) | r1i.x;
  r1i.x = asint(r2.w) | r1i.x;
#endif
  o0.xyzw = r1i.x ? 0.0 : r0.xyzw;
}