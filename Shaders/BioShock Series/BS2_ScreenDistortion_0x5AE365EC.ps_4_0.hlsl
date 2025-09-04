cbuffer _Globals : register(b0)
{
  float Particle_hlsl_PSMain00000000000000000000080c00000100_44bits : packoffset(c0) = {0};
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
  row_major float4x4 worldViewProj : packoffset(c11);
  float3 localEyePos : packoffset(c15);
  float4 vertexClipPlane : packoffset(c16);
  float specularPower : packoffset(c17);
  float distortionStrength : packoffset(c17.y);
  float3 specularColor : packoffset(c18);
  float environmentMapLevel : packoffset(c18.w);
  float3 selfIlluminationColor : packoffset(c19);
  float3 subsurfaceColor : packoffset(c20);
  float3 diffuseColor : packoffset(c21);
  float specularCubeMapBrightness : packoffset(c21.w);
  float minAlphaClipValue : packoffset(c22);
  float maxAlphaClipValue : packoffset(c22.y);
  float2 heightMapScaleAndBias : packoffset(c22.z);
  row_major float2x4 diffuseTexTransform : packoffset(c23);
  row_major float2x4 opacityTexTransform : packoffset(c25);
  row_major float2x4 selfIllumTexTransform : packoffset(c27);
  bool UseReactiveXAxis : packoffset(c29) = false;
  bool UseReactiveYAxis : packoffset(c29.y) = false;
  float EnableReactiveEffects : packoffset(c29.z) = {0};
  float FadeInDistance : packoffset(c29.w);
  float invCollisionFadeDistance : packoffset(c30);
  float MinClipDistance : packoffset(c30.y);
  float invBackFadeDistance : packoffset(c30.z);
  float GlobalNDotMultiplier : packoffset(c30.w);
  float MinDistortionClipDistance : packoffset(c31);
  float water_row_sample : packoffset(c31.y);
  row_major float4x4 reactiveTransform : packoffset(c32);
  float3 reactiveNormal : packoffset(c36);
  float reactiveDepthOffset : packoffset(c36.w);
  float4 fadePlane : packoffset(c37);
  float4 ambientColor : packoffset(c38);

  struct
  {
    float4 light_vector;
    float4 color_invradius;
    float4 spot_projection1;
    float4 spot_projection2;
    float4 spot_projection3;
  } Lights[4] : packoffset(c39);

  float bLightEnable0 : packoffset(c59);
  float bLightEnable1 : packoffset(c59.y);
  float bLightEnable2 : packoffset(c59.z);
  float bLightEnable3 : packoffset(c59.w);
  float bLightIsSpot0 : packoffset(c60);
  float bLightIsSpot1 : packoffset(c60.y);
  float bLightIsSpot2 : packoffset(c60.z);
  float bLightIsSpot3 : packoffset(c60.w);
}

SamplerState s_distortion_s : register(s0);
SamplerState s_distortion2_s : register(s1);
SamplerState s_sceneDepth_s : register(s2);
SamplerState mtbSampleSlot1_s : register(s3);
Texture2D<float4> mtbSampleSlot1 : register(t0);
Texture2D<float4> s_sceneDepth : register(t1);
Texture2D<float4> s_distortion : register(t2);
Texture2D<float4> s_distortion2 : register(t3);

// Luma: unchanged
void main(
  float4 v0 : TEXCOORD6,
  float4 v1 : TEXCOORD7,
  float4 v2 : TEXCOORD0,
  float4 v3 : TEXCOORD1,
  float4 v4 : TEXCOORD2,
  float4 v5 : COLOR0,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2;
  r0.xy = v0.xy / v0.ww;
  r0.xyzw = s_sceneDepth.Sample(s_sceneDepth_s, r0.xy).xyzw;
  r0.y = (r0.x >= 0.01);
  r0.y = r0.y ? 1.0 : 0.0;
  r0.z = 1 + -wToZScaleAndBias.z;
  r0.y = r0.y * r0.z + wToZScaleAndBias.z;
  r0.x = r0.x * r0.y + -wToZScaleAndBias.x;
  r0.x = wToZScaleAndBias.y / r0.x;
  r0.x = -v0.w + r0.x;
  r0.x = -MinClipDistance + r0.x;
  r0.x = saturate(invBackFadeDistance * r0.x);
  r0.x = v5.w * r0.x;
  r0.y = globalOpacity * v1.w;
  r0.x = r0.x * r0.y;
  r0.yzw = fogColor.xyz * v0.zzz;
  r0.xyz = r0.yzw * r0.xxx;
  r1.xyzw = mtbSampleSlot1.Sample(mtbSampleSlot1_s, v2.xy).xyzw;
  r1.xy = r1.xy * float2(2,2) + float2(-1,-1);
  r1.xy = -distortionStrength * r1.xy;
  r1.xy = v5.ww * r1.xy;
  r1.xy = float2(10,10) * r1.xy;
  r1.z = 0;
  r1.xyz = v0.xyw + r1.xyz;
  r0.w = distortionBufferScale * r1.z;
  r1.xy = min(r1.xy, r0.ww);
  r1.xy = r1.xy / r1.zz;
  r2.xyzw = s_distortion.Sample(s_distortion_s, r1.xy).xyzw;
  r1.xyzw = s_distortion2.Sample(s_distortion2_s, r1.xy).xyzw;
  r1.xyz = r2.xyz * r1.www + r1.xyz;
  r0.w = 1 / globalScale;
  r0.xyz = r1.xyz * r0.www + r0.xyz;
  o0.xyz = globalScale * r0.xyz;
  o0.w = 0;
}