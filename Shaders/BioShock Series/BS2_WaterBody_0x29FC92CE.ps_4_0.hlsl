#include "Includes/Common.hlsl"

cbuffer _Globals : register(b0)
{
  float LayerLighting_hlsl_PSMain00000000000000000000005e58000024_39bits : packoffset(c0) = {0};
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
  float4 water_volume_extents : packoffset(c17);
  float water_row_sample : packoffset(c18);
  float4 waterDiffuseColor : packoffset(c19);
  float4 baseColor : packoffset(c20);
  float4 tangentColor : packoffset(c21);
  float normalMapStrength : packoffset(c22);
  float distortionStrength : packoffset(c22.y);
  float2 reflectivityConst : packoffset(c22.z);
  float2 specularReflectivityConst : packoffset(c23);
  float specularPower : packoffset(c23.z);
  float specularBrightness : packoffset(c23.w);
  float3 specularColor : packoffset(c24);
  float waterOpacity : packoffset(c24.w);
  float specularCubeMapBrightness : packoffset(c25);
  float rippleStrength : packoffset(c25.y);
  float alphaFadeZbias : packoffset(c25.z);
  float alphaFadeZbiasScale : packoffset(c25.w);
  row_major float2x4 diffuseTexTransform1 : packoffset(c26);
  row_major float2x4 diffuseTexTransform2 : packoffset(c28);
  row_major float2x4 normalTexTransform1 : packoffset(c30);
  row_major float2x4 normalTexTransform2 : packoffset(c32);
  row_major float2x4 coverageMaskTexTransform : packoffset(c34);
  row_major float2x4 specularTexTransform1 : packoffset(c36);
  row_major float2x4 specularTexTransform2 : packoffset(c38);
  row_major float4x4 reactiveTransform : packoffset(c40);
  float Time : packoffset(c44);
  float4 VertexAnimation : packoffset(c45);
  float4 Ambient : packoffset(c46);
  float4 luminanceMapUVPacking : packoffset(c47);

  struct
  {
    float4 worldVector;
    float4 color;
    float4 channelMask;
  } lights : packoffset(c48);

  row_major float4x4 localToWorld : packoffset(c51);
  row_major float4x4 screenToWorld : packoffset(c55);
  float3 worldEyePos : packoffset(c59);
}

SamplerState s_distortion_s : register(s0);
SamplerState s_distortion2_s : register(s1);
SamplerState s_sceneDepth_s : register(s2);
SamplerState mtbSampleSlot1_s : register(s3);
SamplerState mtbSampleSlot2_s : register(s4);
SamplerState s_ripple_map_s : register(s5);
SamplerState s_specular_cubemap_s : register(s6);
SamplerState s_shadowMask_s : register(s7);
Texture2D<float4> mtbSampleSlot1 : register(t0);
Texture2D<float4> s_ripple_map : register(t1);
Texture2D<float4> mtbSampleSlot2 : register(t2);
Texture2D<float4> s_shadowMask : register(t3);
TextureCube<float4> s_specular_cubemap : register(t4);
Texture2D<float4> s_sceneDepth : register(t5);
Texture2D<float4> s_distortion : register(t6);
Texture2D<float4> s_distortion2 : register(t7);

#define cmp

void main(
  float4 v0 : TEXCOORD0,
  float4 v1 : TEXCOORD1,
  float4 v2 : TEXCOORD2,
  float4 v3 : COLOR1,
  float4 v4 : TEXCOORD6,
  float4 v5 : TEXCOORD7,
  float4 v6 : TEXCOORD3,
  float4 v7 : TEXCOORD4,
  float4 v8 : TEXCOORD5,
  float4 v9 : TEXCOORD9,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3,r4,r5,r6;
  r0.xyz = -v9.xyz * lights.worldVector.www + lights.worldVector.xyz;
  r0.w = dot(r0.xyz, r0.xyz);
  r0.w = rsqrt(r0.w);
  r0.xyz = r0.xyz * r0.www;
  r1.xyz = worldEyePos.xyz + -v9.xyz;
  r0.w = dot(r1.xyz, r1.xyz);
  r0.w = rsqrt(r0.w);
  r1.xyz = r1.xyz * r0.www + r0.xyz;
  r0.w = dot(r1.xyz, r1.xyz);
  r0.w = rsqrt(r0.w);
  r1.xyz = r1.xyz * r0.www;
  r2.xyzw = mtbSampleSlot1.Sample(mtbSampleSlot1_s, v0.xy).xyzw;
  r2.xyz = r2.xyz * float3(2,2,2) + float3(-1,-1,-1);
  r3.xyzw = mtbSampleSlot1.Sample(mtbSampleSlot1_s, v0.zw).xyzw;
  r3.xyz = r3.xyz * float3(2,2,2) + float3(-1,-1,-1);
  r2.xyz = r3.xyz + r2.xyz;
  r3.xy = v4.xy / v4.ww;
  r4.xyzw = s_ripple_map.Sample(s_ripple_map_s, r3.xy).xyzw;
  r3.xyzw = s_shadowMask.Sample(s_shadowMask_s, r3.xy).xyzw;
  r0.w = saturate(dot(r3.xyzw, lights.channelMask.xyzw));
  r0.w = 1 + -r0.w;
  r0.w = saturate(v7.w * r0.w);
  r3.xyz = lights.color.xyz * r0.www;
  r4.xy = r4.xy * rippleStrength + r2.xy;
  r5.xyz = waterDiffuseColor.xyz * r4.zzz;
  r4.xy = normalMapStrength * r4.xy;
  r6.xyzw = mtbSampleSlot2.Sample(mtbSampleSlot2_s, v1.xy).xyzw;
  r2.xy = r6.xx * r4.xy;
  r0.w = dot(r2.xyz, r2.xyz);
  r0.w = rsqrt(r0.w);
  r2.xyz = r2.xyz * r0.www;
  r4.xyz = v7.xyz * r2.yyy;
  r4.xyz = r2.xxx * v6.xyz + r4.xyz;
  r4.xyz = r2.zzz * v8.xyz + r4.xyz;
  r0.w = dot(r4.xyz, r4.xyz);
  r0.w = rsqrt(r0.w);
  r4.xyz = r4.xyz * r0.www;
  r0.w = saturate(dot(r4.xyz, r1.xyz));
  r0.x = saturate(dot(r0.xyz, r4.xyz));
  r0.xyz = r0.xxx * r3.xyz;
  r0.xyz = r5.xyz * r0.xyz;
  r0.w = log2(r0.w);
  r1.xy = float2(1.00000001e-007,50) + specularPower;
  r0.w = r1.x * r0.w;
  r1.x = 40 / r1.y;
  r0.w = exp2(r0.w);
  r1.yzw = r0.www * r3.xyz;
  r0.w = dot(v5.xyz, v5.xyz);
  r0.w = rsqrt(r0.w);
  r3.xyz = v5.xyz * r0.www;
  r0.w = dot(r2.xyz, r3.xyz);
  r0.w = 1 + -r0.w;
  r2.w = abs(r0.w) * abs(r0.w);
  r2.w = r2.w * r2.w;
  r2.w = r2.w * abs(r0.w);
  r0.w = saturate(r0.w);
  r3.x = saturate(specularReflectivityConst.y * r2.w + specularReflectivityConst.x);
  r2.w = saturate(reflectivityConst.y * r2.w + reflectivityConst.x);
  r2.w = r2.w * r6.x;
  r3.xyz = specularColor.xyz * r3.xxx;
  r3.xyz = r3.xyz * r6.xxx;
  r0.xyz = r3.xyz * r1.yzw + r0.xyz;
  r1.yzw = specularCubeMapBrightness * r3.xyz;
  r3.x = dot(-v5.xyz, r2.xyz);
  r3.x = r3.x + r3.x;
  r3.xyz = r2.xyz * -r3.xxx + -v5.xyz;
  r4.xyz = v7.xyz * r3.yyy;
  r3.xyw = r3.xxx * v6.xyz + r4.xyz;
  r3.xyz = r3.zzz * v8.xyz + r3.xyw;
  r3.xyzw = s_specular_cubemap.SampleLevel(s_specular_cubemap_s, r3.xyz, r1.x).xyzw;
  r1.x = r3.w * 16 + 1;
  r1.x = log2(abs(r1.x));
  r1.x = 2.20000005 * r1.x;
  r1.x = exp2(r1.x);
  r3.xyz = r3.xyz * r1.xxx;
  r0.xyz = r3.xyz * r1.yzw + r0.xyz;
  r1.xy = -distortionStrength * r2.xy + v4.xy;
  r1.z = dot(v8.xyz, r2.xyz);
  r1.z = saturate(r1.z * 0.5 + 0.5);
  r1.z = r1.z * r1.z;
  r1.w = distortionBufferScale * v4.w;
  r1.xy = min(r1.xy, r1.ww);
  r2.xy = r1.xy / v4.ww;
  r1.xy = -v4.xy + r1.xy;
  r3.xyzw = s_sceneDepth.Sample(s_sceneDepth_s, r2.xy).xyzw;
  r1.w = cmp(r3.x >= 0.00999999978);
  r1.w = r1.w ? 1.000000 : 0;
  r1.xy = r1.ww * r1.xy + v4.xy;
  r1.xy = r1.xy / v4.ww;
  r3.xyzw = s_distortion.Sample(s_distortion_s, r1.xy).xyzw;
  r4.xyzw = s_distortion2.Sample(s_distortion2_s, r1.xy).xyzw;
  r1.xyw = r3.xyz * r4.www + r4.xyz;
  r2.x = 1 / globalScale;
  r1.xyw = r2.xxx * r1.xyw;
  r3.xyzw = tangentColor.xyzw + -baseColor.xyzw;
  r3.xyzw = r0.wwww * r3.xyzw + baseColor.xyzw;
  r3.xyzw = float4(-1,-1,-1,-1) + r3.xyzw;
  r3.xyzw = r6.xxxx * r3.xyzw + float4(1,1,1,1);
  r1.xyw = r3.xyz * r1.xyw + -r3.xyz;
  r1.xyw = r3.www * r1.xyw + r3.xyz;
  r0.w = 1 + -Ambient.w;
  r0.w = r1.z * r0.w + Ambient.w;
  r2.xyz = r0.www * r5.xyz;
  r2.xyz = Ambient.xyz * r2.xyz + -r1.xyw;
  r1.xyz = r2.www * r2.xyz + r1.xyw;
  r2.xyz = fogColor.xyz + -r1.xyz;
  r3.xyz = v4.xyw;
  r3.w = 1;
  r4.x = dot(screenDataToCamera._m00_m01_m02_m03, r3.xyzw);
  r4.y = dot(screenDataToCamera._m10_m11_m12_m13, r3.xyzw);
  r4.z = dot(screenDataToCamera._m20_m21_m22_m23, r3.xyzw);
  r0.w = dot(r4.xyz, r4.xyz);
  r0.w = sqrt(r0.w);
  r0.w = r0.w * fogTransform.x + fogTransform.y;
  r0.w = 1.44269502 * r0.w;
  r0.w = exp2(r0.w);
  r0.w = min(1, r0.w);
  r0.w = -fogColor.w * LumaSettings.GameSettings.FogIntensity * r0.w + fogColor.w * LumaSettings.GameSettings.FogIntensity; // TODO: review if this works
  r0.w = fogTransform.z * r0.w;
  r0.w = r6.x * r0.w;
  r1.xyz = r0.www * r2.xyz + r1.xyz;
  r0.xyz = r1.xyz + r0.xyz;
  o0.xyz = globalScale * r0.xyz;
  o0.w = 0;
}