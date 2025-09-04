#include "Includes/Common.hlsl"

cbuffer _Globals : register(b0)
{
  float LayerLighting_hlsl_PSMain00000000000000000000005ed8000024_39bits : packoffset(c0) = {0};
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
  } lights[3] : packoffset(c48);

  row_major float4x4 localToWorld : packoffset(c57);
  row_major float4x4 screenToWorld : packoffset(c61);
  float3 worldEyePos : packoffset(c65);
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
  float4 r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10;
  r0.xyz = worldEyePos.xyz + -v9.xyz;
  r0.w = dot(r0.xyz, r0.xyz);
  r0.w = rsqrt(r0.w);
  r0.xyz = r0.xyz * r0.www;
  r1.xyz = -v9.xyz * lights[1].worldVector + lights[1].worldVector;
  r0.w = dot(r1.xyz, r1.xyz);
  r0.w = rsqrt(r0.w);
  r2.xyz = r1.xyz * r0.www + r0.xyz;
  r1.xyz = r1.xyz * r0.www;
  r0.w = dot(r2.xyz, r2.xyz);
  r0.w = rsqrt(r0.w);
  r2.xyz = r2.xyz * r0.www;
  r3.xyzw = mtbSampleSlot1.Sample(mtbSampleSlot1_s, v0.xy).xyzw;
  r3.xyz = r3.xyz * float3(2,2,2) + float3(-1,-1,-1);
  r4.xyzw = mtbSampleSlot1.Sample(mtbSampleSlot1_s, v0.zw).xyzw;
  r3.xyz = r4.xyz * float3(2,2,2) + r3.xyz;
  r3.xyz = float3(-1,-1,-1) + r3.xyz;
  r4.xy = v4.xy / v4.ww;
  r5.xyzw = s_ripple_map.Sample(s_ripple_map_s, r4.xy).xyzw;
  r4.xyzw = s_shadowMask.Sample(s_shadowMask_s, r4.xy).xyzw;
  r5.xy = r5.xy * rippleStrength + r3.xy;
  r6.xyz = waterDiffuseColor.xyz * r5.zzz;
  r5.xy = normalMapStrength * r5.xy;
  r7.xyzw = mtbSampleSlot2.Sample(mtbSampleSlot2_s, v1.xy).xyzw;
  r3.xy = r7.xx * r5.xy;
  r0.w = dot(r3.xyz, r3.xyz);
  r0.w = rsqrt(r0.w);
  r3.xyz = r3.xyz * r0.www;
  r5.xyz = v7.xyz * r3.yyy;
  r5.xyz = r3.xxx * v6.xyz + r5.xyz;
  r5.xyz = r3.zzz * v8.xyz + r5.xyz;
  r0.w = dot(r5.xyz, r5.xyz);
  r0.w = rsqrt(r0.w);
  r5.xyz = r5.xyz * r0.www;
  r0.w = saturate(dot(r5.xyz, r2.xyz));
  r0.w = log2(r0.w);
  r2.xy = float2(1.00000001e-007,50) + specularPower;
  r0.w = r2.x * r0.w;
  r0.w = exp2(r0.w);
  r1.w = saturate(dot(r4.xyzw, lights[1].channelMask));
  r1.w = 1 + -r1.w;
  r1.w = saturate(v8.w * r1.w);
  r7.yzw = lights[1].color * r1.www;
  r8.xyz = r7.yzw * r0.www;
  r9.xyz = -v9.xyz * lights[0].worldVector.www + lights[0].worldVector.xyz;
  r0.w = dot(r9.xyz, r9.xyz);
  r0.w = rsqrt(r0.w);
  r10.xyz = r9.xyz * r0.www + r0.xyz;
  r9.xyz = r9.xyz * r0.www;
  r0.w = saturate(dot(r9.xyz, r5.xyz));
  r1.w = dot(r10.xyz, r10.xyz);
  r1.w = rsqrt(r1.w);
  r9.xyz = r10.xyz * r1.www;
  r1.w = saturate(dot(r5.xyz, r9.xyz));
  r1.w = log2(r1.w);
  r1.w = r2.x * r1.w;
  r1.w = exp2(r1.w);
  r2.z = saturate(dot(r4.xyzw, lights[0].channelMask.xyzw));
  r2.w = saturate(dot(r4.xyzw, lights[2].channelMask));
  r2.zw = float2(1,1) + -r2.zw;
  r2.w = saturate(v6.w * r2.w);
  r4.xyz = lights[2].color * r2.www;
  r2.z = saturate(v7.w * r2.z);
  r9.xyz = lights[0].color.xyz * r2.zzz;
  r8.xyz = r1.www * r9.xyz + r8.xyz;
  r10.xyz = -v9.xyz * lights[2].worldVector + lights[2].worldVector;
  r1.w = dot(r10.xyz, r10.xyz);
  r1.w = rsqrt(r1.w);
  r0.xyz = r10.xyz * r1.www + r0.xyz;
  r10.xyz = r10.xyz * r1.www;
  r1.w = saturate(dot(r10.xyz, r5.xyz));
  r2.z = dot(r0.xyz, r0.xyz);
  r2.z = rsqrt(r2.z);
  r0.xyz = r2.zzz * r0.xyz;
  r0.x = saturate(dot(r5.xyz, r0.xyz));
  r0.y = saturate(dot(r1.xyz, r5.xyz));
  r1.xyz = r0.yyy * r7.yzw;
  r0.yzw = r0.www * r9.xyz + r1.xyz;
  r0.yzw = r1.www * r4.xyz + r0.yzw;
  r0.yzw = r6.xyz * r0.yzw;
  r0.x = log2(r0.x);
  r0.x = r2.x * r0.x;
  r1.x = 40 / r2.y;
  r0.x = exp2(r0.x);
  r1.yzw = r0.xxx * r4.xyz + r8.xyz;
  r0.x = dot(v5.xyz, v5.xyz);
  r0.x = rsqrt(r0.x);
  r2.xyz = v5.xyz * r0.xxx;
  r0.x = dot(r3.xyz, r2.xyz);
  r0.x = 1 + -r0.x;
  r2.x = abs(r0.x) * abs(r0.x);
  r2.x = r2.x * r2.x;
  r2.x = r2.x * abs(r0.x);
  r0.x = saturate(r0.x);
  r2.y = saturate(specularReflectivityConst.y * r2.x + specularReflectivityConst.x);
  r2.x = saturate(reflectivityConst.y * r2.x + reflectivityConst.x);
  r2.x = r2.x * r7.x;
  r2.yzw = specularColor.xyz * r2.yyy;
  r2.yzw = r2.yzw * r7.xxx;
  r0.yzw = r2.yzw * r1.yzw + r0.yzw;
  r1.yzw = specularCubeMapBrightness * r2.yzw;
  r2.y = dot(-v5.xyz, r3.xyz);
  r2.y = r2.y + r2.y;
  r2.yzw = r3.xyz * -r2.yyy + -v5.xyz;
  r4.xyz = v7.xyz * r2.zzz;
  r4.xyz = r2.yyy * v6.xyz + r4.xyz;
  r2.yzw = r2.www * v8.xyz + r4.xyz;
  r4.xyzw = s_specular_cubemap.SampleLevel(s_specular_cubemap_s, r2.yzw, r1.x).xyzw;
  r1.x = r4.w * 16 + 1;
  r1.x = log2(abs(r1.x));
  r1.x = 2.20000005 * r1.x;
  r1.x = exp2(r1.x);
  r2.yzw = r4.xyz * r1.xxx;
  r0.yzw = r2.yzw * r1.yzw + r0.yzw;
  r1.xy = -distortionStrength * r3.xy + v4.xy;
  r1.z = dot(v8.xyz, r3.xyz);
  r1.z = saturate(r1.z * 0.5 + 0.5);
  r1.z = r1.z * r1.z;
  r1.w = distortionBufferScale * v4.w;
  r1.xy = min(r1.xy, r1.ww);
  r2.yz = r1.xy / v4.ww;
  r1.xy = -v4.xy + r1.xy;
  r3.xyzw = s_sceneDepth.Sample(s_sceneDepth_s, r2.yz).xyzw;
  r1.w = cmp(r3.x >= 0.00999999978);
  r1.w = r1.w ? 1.000000 : 0;
  r1.xy = r1.ww * r1.xy + v4.xy;
  r1.xy = r1.xy / v4.ww;
  r3.xyzw = s_distortion.Sample(s_distortion_s, r1.xy).xyzw;
  r4.xyzw = s_distortion2.Sample(s_distortion2_s, r1.xy).xyzw;
  r1.xyw = r3.xyz * r4.www + r4.xyz;
  r2.y = 1 / globalScale;
  r1.xyw = r2.yyy * r1.xyw;
  r3.xyzw = tangentColor.xyzw + -baseColor.xyzw;
  r3.xyzw = r0.xxxx * r3.xyzw + baseColor.xyzw;
  r3.xyzw = float4(-1,-1,-1,-1) + r3.xyzw;
  r3.xyzw = r7.xxxx * r3.xyzw + float4(1,1,1,1);
  r1.xyw = r3.xyz * r1.xyw + -r3.xyz;
  r1.xyw = r3.www * r1.xyw + r3.xyz;
  r0.x = 1 + -Ambient.w;
  r0.x = r1.z * r0.x + Ambient.w;
  r2.yzw = r0.xxx * r6.xyz;
  r2.yzw = Ambient.xyz * r2.yzw + -r1.xyw;
  r1.xyz = r2.xxx * r2.yzw + r1.xyw;
  r2.xyz = fogColor.xyz + -r1.xyz;
  r3.xyz = v4.xyw;
  r3.w = 1;
  r4.x = dot(screenDataToCamera._m00_m01_m02_m03, r3.xyzw);
  r4.y = dot(screenDataToCamera._m10_m11_m12_m13, r3.xyzw);
  r4.z = dot(screenDataToCamera._m20_m21_m22_m23, r3.xyzw);
  r0.x = dot(r4.xyz, r4.xyz);
  r0.x = sqrt(r0.x);
  r0.x = r0.x * fogTransform.x + fogTransform.y;
  r0.x = 1.44269502 * r0.x;
  r0.x = exp2(r0.x);
  r0.x = min(1, r0.x);
  r0.x = -fogColor.w * r0.x + fogColor.w;
  r0.x = fogTransform.z * r0.x;
  r0.x = r7.x * r0.x;
  r1.xyz = r0.xxx * r2.xyz + r1.xyz;
  r0.xyz = r1.xyz + r0.yzw;
  o0.xyz = globalScale * r0.xyz;
  o0.w = 0;
}