cbuffer _Globals : register(b0)
{
  float Particle_hlsl_VSMain00000000000000000000000000000a18_12bits : packoffset(c0) = {0};
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

SamplerState s_water_depth_mask_s : register(s0);
Texture2D<float4> s_water_depth_mask : register(t0);

#define cmp

void main(
  float4 v0 : POSITION0,
  float3 v1 : TANGENT0,
  float3 v2 : BINORMAL0,
  float3 v3 : NORMAL0,
  float4 v4 : TEXCOORD0,
  float4 v5 : TEXCOORD1,
  float4 v6 : TEXCOORD2,
  float4 v7 : TEXCOORD3,
  float4 v8 : TEXCOORD4,
  float4 v9 : TEXCOORD5,
  float4 v10 : COLOR0,
  float4 v11 : COLOR1,
  float4 v12 : BLENDINDICES0,
  out float4 o0 : TEXCOORD6,
  out float4 o1 : TEXCOORD7,
  out float4 o2 : TEXCOORD0,
  out float2 o3 : TEXCOORD1,
  out float4 o4 : TEXCOORD2,
  out float4 o5 : COLOR0,
  out float4 o6 : SV_Position0,
  out float o7 : SV_ClipDistance0)
{
  float4 r0,r1,r2;
  r0.x = cmp(0 < UseReactiveXAxis);
  if (r0.x != 0) {
    r0.x = dot(reactiveTransform._m00_m01_m02_m03, v6.xyzw);
    r0.x = 0.5 + r0.x;
    r0.y = water_row_sample;
    r1.xyzw = s_water_depth_mask.SampleLevel(s_water_depth_mask_s, r0.xy, 0).xyzw;
    r0.y = 1 + -r1.x;
    r0.y = saturate(-reactiveDepthOffset + r0.y);
    r0.z = cmp(0 < r0.x);
    r0.x = cmp(r0.x < 1);
    r0.x = r0.x ? r0.z : 0;
    r0.yzw = r0.yyy * reactiveNormal.xyz + v0.xyz;
    r0.xyz = r0.xxx ? r0.yzw : v0.xyz;
  } else {
    r0.xyz = v0.xyz;
  }
  r0.w = v0.w;
  r1.x = dot(worldViewProj._m00_m01_m02_m03, r0.xyzw);
  r1.y = dot(worldViewProj._m10_m11_m12_m13, r0.xyzw);
  r1.z = dot(worldViewProj._m20_m21_m22_m23, r0.xyzw);
  r1.w = dot(worldViewProj._m30_m31_m32_m33, r0.xyzw);
  o7.x = dot(vertexClipPlane.xyzw, r1.xyzw);
  r0.x = dot(screenTransform[0].xyzw, r1.xyzw);
  r0.y = dot(screenTransform[1].xyzw, r1.xyzw);
  r0.z = r1.w;
  r0.w = 1;
  r2.x = dot(screenDataToCamera._m00_m01_m02_m03, r0.xyzw);
  r2.y = dot(screenDataToCamera._m10_m11_m12_m13, r0.xyzw);
  r2.z = dot(screenDataToCamera._m20_m21_m22_m23, r0.xyzw);
  r0.w = dot(r2.xyz, r2.xyz);
  r0.w = sqrt(r0.w);
  r0.w = r0.w * fogTransform.x + fogTransform.y;
  r0.w = 1.44269502 * r0.w;
  r0.w = exp2(r0.w);
  r0.w = min(1, r0.w);
  r0.w = -fogColor.w * r0.w + fogColor.w;
  o0.z = fogTransform.z * r0.w;
  r0.w = cmp(UseReactiveXAxis != 0.000000);
  r2.x = saturate(r1.w / UseReactiveXAxis);
  r2.x = v10.w * r2.x;
  o5.w = r0.w ? r2.x : v10.w;
  o0.xyw = r0.xyz;
  o1.xyzw = float4(0,0,1,1);
  o2.xyzw = v4.xyyx;
  o4.xyzw = float4(0,0,0,0);
  o5.xyz = v10.zyx;
  o6.xyzw = r1.xyzw;
  //o6.x *= 1.5; // LUMA: Try to fix them for UW
  o3.xy = v4.xy;
}