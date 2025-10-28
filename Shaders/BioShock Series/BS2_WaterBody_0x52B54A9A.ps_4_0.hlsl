#include "Includes/Common.hlsl"

cbuffer _Globals : register(b0)
{
  float Base_hlsl_PSMain00000000000000000000000005d00002_27bits : packoffset(c0) = {0};
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
  row_major float4x3 localToWorld : packoffset(c47);
}

SamplerState s_distortion_s : register(s0);
SamplerState s_distortion2_s : register(s1);
SamplerState s_sceneDepth_s : register(s2);
SamplerState mtbSampleSlot1_s : register(s3);
SamplerState s_ripple_map_s : register(s4);
SamplerState s_specular_cubemap_s : register(s5);
Texture2D<float4> mtbSampleSlot1 : register(t0);
Texture2D<float4> s_ripple_map : register(t1);
TextureCube<float4> s_specular_cubemap : register(t2);
Texture2D<float4> s_sceneDepth : register(t3);
Texture2D<float4> s_distortion : register(t4);
Texture2D<float4> s_distortion2 : register(t5);

#define cmp

void main(
  float4 v0 : TEXCOORD6,
  float4 v1 : TEXCOORD7,
  float4 v2 : TEXCOORD0,
  float4 v3 : TEXCOORD1,
  float4 v4 : TEXCOORD2,
  float4 v5 : COLOR1,
  float4 v6 : TEXCOORD3,
  float4 v7 : TEXCOORD4,
  float3 v8 : TEXCOORD5,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3;
  r0.xyz = v0.xyw;
  r0.w = 1;
  r1.x = dot(screenDataToCamera._m00_m01_m02_m03, r0.xyzw);
  r1.y = dot(screenDataToCamera._m10_m11_m12_m13, r0.xyzw);
  r1.z = dot(screenDataToCamera._m20_m21_m22_m23, r0.xyzw);
  r0.x = dot(r1.xyz, r1.xyz);
  r0.x = sqrt(r0.x);
  r0.x = r0.x * fogTransform.x + fogTransform.y;
  r0.x = 1.44269502 * r0.x;
  r0.x = exp2(r0.x);
  r0.x = min(1, r0.x);
  r0.x = -fogColor.w * r0.x + fogColor.w;
  r0.x = fogTransform.z * r0.x;
  r1.xyzw = mtbSampleSlot1.Sample(mtbSampleSlot1_s, v2.xy).xyzw;
  r0.yzw = r1.xyz * float3(2,2,2) + float3(-1,-1,-1);
  r1.xyzw = mtbSampleSlot1.Sample(mtbSampleSlot1_s, v2.zw).xyzw;
  r1.xyz = r1.xyz * float3(2,2,2) + float3(-1,-1,-1);
  r0.yzw = r1.xyz + r0.yzw;
  r1.xy = v0.xy / v0.ww;
  r1.xyzw = s_ripple_map.Sample(s_ripple_map_s, r1.xy).xyzw;
  r1.xy = r1.xy * rippleStrength + r0.yz;
  r2.xyz = waterDiffuseColor.xyz * r1.zzz;
  r0.yz = normalMapStrength * r1.xy;
  r1.x = dot(r0.yzw, r0.yzw);
  r1.x = rsqrt(r1.x);
  r0.yzw = r1.xxx * r0.yzw;
  r1.xy = -distortionStrength * r0.yz + v0.xy;
  r1.z = distortionBufferScale * v0.w;
  r1.xy = min(r1.xy, r1.zz);
  r1.zw = r1.xy / v0.ww;
  r1.xy = -v0.xy + r1.xy;
  r3.xyzw = s_sceneDepth.Sample(s_sceneDepth_s, r1.zw).xyzw;
  r1.z = cmp(r3.x >= 0.01);
  r1.xy = r1.zz * r1.xy + v0.xy;
  r1.xy = r1.xy / v0.ww;
  r3.xyzw = s_distortion.Sample(s_distortion_s, r1.xy).xyzw;
  r1.xyzw = s_distortion2.Sample(s_distortion2_s, r1.xy).xyzw;
  r1.xyz = r3.xyz * r1.www + r1.xyz;
  r1.w = 1 / globalScale;
  r1.xyz = r1.xyz * r1.www;
  r1.w = dot(v1.xyz, v1.xyz);
  r1.w = rsqrt(r1.w);
  r3.xyz = v1.xyz * r1.www;
  r1.w = dot(r0.yzw, r3.xyz);
  r1.w = 1 + -r1.w;
  r2.w = saturate(r1.w);
  r3.xyzw = tangentColor.xyzw + -baseColor.xyzw;
  r3.xyzw = r2.wwww * r3.xyzw + baseColor.xyzw;
  r1.xyz = r3.xyz * r1.xyz + -r3.xyz;
  r1.xyz = r3.www * r1.xyz + r3.xyz;
  r2.w = dot(v8.xyz, r0.yzw);
  r2.w = saturate(r2.w * 0.5 + 0.5);
  r2.w = r2.w * r2.w;
  r3.x = 1 + -Ambient.w;
  r2.w = r2.w * r3.x + Ambient.w;
  r2.xyz = r2.www * r2.xyz;
  r2.xyz = Ambient.xyz * r2.xyz + -r1.xyz;
  r2.w = abs(r1.w) * abs(r1.w);
  r2.w = r2.w * r2.w;
  r1.w = r2.w * abs(r1.w);
  r2.w = saturate(reflectivityConst.y * r1.w + reflectivityConst.x);
  r1.w = saturate(specularReflectivityConst.y * r1.w + specularReflectivityConst.x);
  r3.xyz = specularColor.xyz * r1.www;
  r3.xyz = specularCubeMapBrightness * r3.xyz;
  r1.xyz = r2.www * r2.xyz + r1.xyz;
  r1.xyz = lerp(r1.xyz, fogColor.xyz, pow(r0.x, 1.0 / LumaSettings.GameSettings.FogIntensity)); // TODO: do all with oklab? It was previously a sum
  r0.x = dot(-v1.xyz, r0.yzw);
  r0.x = r0.x + r0.x;
  r0.xyz = r0.yzw * -r0.xxx + -v1.xyz;
  r2.xyz = v7.xyz * r0.yyy;
  r0.xyw = r0.xxx * v6.xyz + r2.xyz;
  r0.xyz = r0.zzz * v8.xyz + r0.xyw;
  r0.w = 50 + specularPower;
  r0.w = 40 / r0.w;
  r0.xyzw = s_specular_cubemap.SampleLevel(s_specular_cubemap_s, r0.xyz, r0.w).xyzw;
  r0.w = r0.w * 16 + 1;
  r0.w = log2(abs(r0.w));
  r0.w = 2.20000005 * r0.w;
  r0.w = exp2(r0.w);
  r0.xyz = r0.xyz * r0.www;
  r0.xyz = r0.xyz * r3.xyz + r1.xyz;
  o0.xyz = globalScale * r0.xyz;
  o0.w = 0;
}