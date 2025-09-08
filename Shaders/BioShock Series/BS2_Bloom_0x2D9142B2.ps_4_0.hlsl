cbuffer _Globals : register(b0)
{
  float ImageSpace_hlsl_BlurPixelShader00000000000000000000000000000002_2bits : packoffset(c0) = {0};
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
  float4 SampleOffsets : packoffset(c16);
  float4 SampleWeights[2] : packoffset(c17);
  float4 PWLConstants : packoffset(c19);
  float PWLThreshold : packoffset(c20);
  float ShadowEdgeDetectThreshold : packoffset(c20.y);
  float4 ColorFill : packoffset(c21);
  float2 LowResTextureDimensions : packoffset(c22);
  float2 DownsizeTextureDimensions : packoffset(c22.z);
}

SamplerState s_buffer_s : register(s0);
Texture2D<float4> s_buffer : register(t0);

// Luma: unchanged
void main(
  float4 v0 : TEXCOORD0,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1;
  r0.xyzw = s_buffer.Sample(s_buffer_s, v0.wz).xyzw;
  r0.xyzw = SampleWeights[1].xyzw * r0.xyzw;
  r1.xyzw = s_buffer.Sample(s_buffer_s, v0.xy).xyzw;
  o0.xyzw = r1.xyzw * SampleWeights[0].xyzw + r0.xyzw;
}