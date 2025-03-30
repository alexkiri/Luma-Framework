cbuffer _Globals : register(b0)
{
  float GlobalLitLighting_hlsl_PSMain00000000000000000002800300002001_50bits : packoffset(c0) = {0};
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

  struct
  {
    float4 light_vector;
    float4 color_invradius;
    float4 spot_projection1;
    float4 spot_projection2;
    float4 spot_projection3;
  } Lights[4] : packoffset(c29);

  float bLightEnable0 : packoffset(c49);
  float bLightEnable1 : packoffset(c49.y);
  float bLightEnable2 : packoffset(c49.z);
  float bLightEnable3 : packoffset(c49.w);
  float bLightIsSpot0 : packoffset(c50);
  float bLightIsSpot1 : packoffset(c50.y);
  float bLightIsSpot2 : packoffset(c50.z);
  float bLightIsSpot3 : packoffset(c50.w);
}

SamplerState mtbSampleSlot1_s : register(s0);
SamplerState mtbSampleSlot2_s : register(s1);
SamplerState mtbSampleSlot3_s : register(s2);
Texture2D<float4> mtbSampleSlot1 : register(t0);
Texture2D<float4> mtbSampleSlot2 : register(t1);
Texture2D<float4> mtbSampleSlot3 : register(t2);


// 3Dmigoto declarations
#define cmp -


void main(
  float4 v0 : TEXCOORD6,
  float4 v1 : TEXCOORD7,
  float4 v2 : TEXCOORD0,
  float4 v3 : TEXCOORD1,
  float4 v4 : TEXCOORD2,
  float4 v5 : TEXCOORD4,
  float3 v6 : TEXCOORD5,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3;
  uint4 bitmask, uiDest;
  float4 fDest;

  r0.x = dot(v1.xyz, v1.xyz);
  r0.x = rsqrt(r0.x);
  r0.y = dot(v6.xyz, v6.xyz);
  r0.y = rsqrt(r0.y);
  r0.yzw = v6.xyz * r0.yyy;
  r1.xyz = v1.xyz * r0.xxx + r0.yzw;
  r0.x = dot(r1.xyz, r1.xyz);
  r0.x = rsqrt(r0.x);
  r1.xyz = r1.xyz * r0.xxx;
  r2.xyzw = mtbSampleSlot2.Sample(mtbSampleSlot2_s, v2.xy).xyzw;
  r2.xyz = r2.xyz * float3(2,2,2) + float3(-1,-1,-1);
  r0.x = dot(r2.xyz, r2.xyz);
  r0.x = rsqrt(r0.x);
  r3.xyz = r2.xyz * r0.xxx;
  r0.x = saturate(dot(r0.yzw, r2.xyz));
  r0.y = saturate(dot(r3.xyz, r1.xyz));
  r0.y = log2(r0.y);
  r0.z = 1.00000001e-007 + specularPower;
  r0.y = r0.z * r0.y;
  r0.y = exp2(r0.y);
  r1.xyzw = mtbSampleSlot3.Sample(mtbSampleSlot3_s, v2.xy).xyzw;
  r1.xyz = specularColor.xyz * r1.xyz;
  r0.yzw = r1.xyz * r0.yyy;
  r1.xyzw = mtbSampleSlot1.Sample(mtbSampleSlot1_s, v2.xy).xyzw;
  r1.xyz = diffuseColor.xyz * r1.xyz;
  r0.xyz = r1.xyz * r0.xxx + r0.yzw;
  r1.xyz = v5.xyz * r0.xyz;
  r0.xyz = -r0.xyz * v5.xyz + fogColor.xyz;
  r0.xyz = v0.zzz * r0.xyz + r1.xyz;
  o0.xyz = globalScale * r0.xyz;
  o0.w = globalOpacity * v1.w;
  return;
}