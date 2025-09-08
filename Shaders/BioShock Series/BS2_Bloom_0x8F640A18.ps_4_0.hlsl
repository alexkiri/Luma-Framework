cbuffer _Globals : register(b0)
{
  float ImageSpace_hlsl_BlurPixelShader00000000000000000000000000000004_3bits : packoffset(c0) = {0};
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

SamplerState s_buffer_s : register(s0);
Texture2D<float4> s_buffer : register(t0);

// Luma: unchanged
void main(
  float4 v0 : TEXCOORD0,
  float4 v1 : TEXCOORD1,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3;
  int4 r1i;

  float4 v[2] = { v0, v1 };

  r0.xyzw = 0.0;
  r1i.x = 0;
  // 2 iterations
  while (true) {
    if (r1i.x >= 3) break;
    r2.xyzw = s_buffer.Sample(s_buffer_s, v[(r1i.x >> 1)+0].xy).xyzw;
    r2.xyzw = r2.xyzw * SampleWeights[r1i.x].xyzw + r0.xyzw;
    r3.xyzw = s_buffer.Sample(s_buffer_s, v[(r1i.x >> 1)+0].wz).xyzw;
    r0.xyzw = r3.xyzw * SampleWeights[r1i.x + 1].xyzw + r2.xyzw;
    r1i.x += 2;
  }
  o0.xyzw = r0.xyzw;
}