#include "Includes/Common.hlsl"

cbuffer _Globals : register(b0)
{
  float LayerLighting_hlsl_PSMain010323095345441841_54bits : packoffset(c0) = {0};
  float4 fogColor : packoffset(c1);
  float3 fogTransform : packoffset(c2);
  float4x3 screenDataToCamera : packoffset(c3);
  float globalScale : packoffset(c6);
  float sceneDepthAlphaMask : packoffset(c6.y);
  float globalOpacity : packoffset(c6.z);
  float distortionBufferScale : packoffset(c6.w);
  float2 wToZScaleAndBias : packoffset(c7);
  float4 screenTransform[2] : packoffset(c8);
  float4x4 worldViewProj : packoffset(c10);
  float3 localEyePos : packoffset(c14);
  float4 vertexClipPlane : packoffset(c15);
  float specularPower : packoffset(c16);
  float distortionStrength : packoffset(c16.y);
  float3 specularColor : packoffset(c17);
  float environmentMapLevel : packoffset(c17.w);
  float3 selfIlluminationColor : packoffset(c18);
  float3 subsurfaceColor : packoffset(c19);
  float3 diffuseColor : packoffset(c20);
  float specularCubeMapBrightness : packoffset(c20.w);
  float minAlphaClipValue : packoffset(c21);
  float maxAlphaClipValue : packoffset(c21.y);
  float2 heightMapScaleAndBias : packoffset(c21.z);
  float4x2 diffuseTexTransform : packoffset(c22);
  float4x2 opacityTexTransform : packoffset(c24);
  float4x2 selfIllumTexTransform : packoffset(c26);

  struct
  {
    float4 ambientVector;
    float4 ambientColorLow;
    float4 ambientControls;
  } Ambient : packoffset(c28);

  float4 luminanceMapUVPacking : packoffset(c31);

  struct
  {
    float4 worldVector;
    float4 color;
    float4 channelMask;
  } lights[5] : packoffset(c32);

  row_major float4x4 localToWorld : packoffset(c47);
  row_major float4x4 screenToWorld : packoffset(c51);
  float3 worldEyePos : packoffset(c55);
}

SamplerState mtbSampleSlot1_s : register(s0);
SamplerState mtbSampleSlot2_s : register(s1);
SamplerState mtbSampleSlot3_s : register(s2);
SamplerState GaussianLookup_s : register(s3);
SamplerState s_luminanceMap1_s : register(s4);
SamplerState s_luminanceMap2_s : register(s5);
SamplerState s_shadowMask_s : register(s6);
Texture2D<float4> mtbSampleSlot2 : register(t0);
Texture2D<float4> s_luminanceMap1 : register(t1);
Texture2D<float4> s_luminanceMap2 : register(t2);
Texture2D<float4> mtbSampleSlot1 : register(t3);
Texture2D<float4> s_shadowMask : register(t4);
Texture2D<float4> mtbSampleSlot3 : register(t5);
Texture2D<float4> GaussianLookup : register(t6);

void main(
  float4 v0 : TEXCOORD0,
  float4 v1 : TEXCOORD1,
  float4 v2 : TEXCOORD6,
  float4 v3 : TEXCOORD7,
  float4 v4 : TEXCOORD3,
  float4 v5 : TEXCOORD4,
  float4 v6 : TEXCOORD5,
  float3 v7 : COLOR0,
  float4 v8 : TEXCOORD9,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3,r4,r5,r6,r7,r8;
  r0.xyz = worldEyePos.xyz + -v8.xyz;
  r0.w = dot(r0.xyz, r0.xyz);
  r0.w = rsqrt(r0.w);
  r0.xyz = r0.xyz * r0.www;
  r1.xyz = -v8.xyz * lights[1].worldVector.rgb + lights[1].worldVector.rgb;
  r0.w = dot(r1.xyz, r1.xyz);
  r0.w = rsqrt(r0.w);
  r2.xyz = r1.xyz * r0.www + r0.xyz;
  r1.xyz = r1.xyz * r0.www;
  r0.w = dot(r2.xyz, r2.xyz);
  r0.w = rsqrt(r0.w);
  r2.xyz = r2.xyz * r0.www;
  r3.xyzw = mtbSampleSlot2.Sample(mtbSampleSlot2_s, v0.xy).xyzw;
  r3.xyz = r3.xyz * float3(2,2,2) + float3(-1,-1,-1);
  r4.xyz = v5.xyz * r3.yyy;
  r3.xyw = r3.xxx * v4.xyz + r4.xyz;
  r3.xyz = r3.zzz * v6.xyz + r3.xyw;
  r0.w = dot(r3.xyz, r3.xyz);
  r0.w = rsqrt(r0.w);
  r3.xyz = r3.xyz * r0.www;
  r0.w = saturate(dot(r3.xyz, r2.xyz));
  r0.w = log2(r0.w);
  r2.y = 0.001953125 * specularPower;
  r2.x = dot(r3.xyz, r3.xyz);
  r2.xyzw = GaussianLookup.Sample(GaussianLookup_s, r2.xy).xyzw;
  r2.xy = saturate(r2.xy);
  r1.w = 0.00100000005 + r2.x;
  r1.w = r1.w * specularPower + 1.00000001e-007;
  r0.w = r1.w * r0.w;
  r0.w = exp2(r0.w);
  r2.xzw = -v8.xyz * lights[2].worldVector.rgb + lights[2].worldVector.rgb;
  r3.w = dot(r2.xzw, r2.xzw);
  r3.w = rsqrt(r3.w);
  r4.xyz = r2.xzw * r3.www + r0.xyz;
  r2.xzw = r3.www * r2.xzw;
  r2.x = saturate(dot(r2.xzw, r3.xyz));
  r2.z = dot(r4.xyz, r4.xyz);
  r2.z = rsqrt(r2.z);
  r4.xyz = r4.xyz * r2.zzz;
  r2.z = saturate(dot(r3.xyz, r4.xyz));
  r2.z = log2(r2.z);
  r2.z = r2.z * r1.w;
  r2.z = exp2(r2.z);
  r4.x = v4.w;
  r4.y = v5.w;
  r4.xyzw = s_luminanceMap1.Sample(s_luminanceMap1_s, r4.xy).xyzw;
  r5.xy = v2.xy / v2.ww;
  r5.xyzw = s_shadowMask.Sample(s_shadowMask_s, r5.xy).xyzw;
  r2.w = saturate(dot(r5.xyzw, lights[2].channelMask));
  r2.w = 1 + -r2.w;
  r2.w = saturate(r4.z * r2.w);
  r6.xyz = lights[2].color.rgb * r2.www;
  r7.xyz = r6.xyz * r2.zzz;
  r2.xzw = r6.xyz * r2.xxx;
  r3.w = saturate(dot(r5.xyzw, lights[1].channelMask));
  r3.w = 1 + -r3.w;
  r3.w = saturate(r4.y * r3.w);
  r4.yzw = lights[1].color.rgb * r3.www;
  r6.xyz = r0.www * r4.yzw + r7.xyz;
  r7.xyz = -v8.xyz * lights[3].worldVector.rgb + lights[3].worldVector.rgb;
  r0.w = dot(r7.xyz, r7.xyz);
  r0.w = rsqrt(r0.w);
  r8.xyz = r7.xyz * r0.www + r0.xyz;
  r7.xyz = r7.xyz * r0.www;
  r0.w = saturate(dot(r7.xyz, r3.xyz));
  r3.w = dot(r8.xyz, r8.xyz);
  r3.w = rsqrt(r3.w);
  r7.xyz = r8.xyz * r3.www;
  r3.w = saturate(dot(r3.xyz, r7.xyz));
  r3.w = log2(r3.w);
  r3.w = r3.w * r1.w;
  r3.w = exp2(r3.w);
  r6.w = saturate(dot(r5.xyzw, lights[3].channelMask));
  r5.x = saturate(dot(r5.xyzw, lights[4].channelMask));
  r5.x = 1 + -r5.x;
  r5.y = 1 + -r6.w;
  r4.x = saturate(r5.y * r4.x);
  r5.yzw = lights[3].color.rgb * r4.xxx;
  r6.xyz = r3.www * r5.yzw + r6.xyz;
  r7.xyz = -v8.xyz * lights[4].worldVector.rgb + lights[4].worldVector.rgb;
  r3.w = dot(r7.xyz, r7.xyz);
  r3.w = rsqrt(r3.w);
  r0.xyz = r7.xyz * r3.www + r0.xyz;
  r7.xyz = r7.xyz * r3.www;
  r3.w = saturate(dot(r7.xyz, r3.xyz));
  r4.x = dot(r0.xyz, r0.xyz);
  r4.x = rsqrt(r4.x);
  r0.xyz = r4.xxx * r0.xyz;
  r0.x = saturate(dot(r3.xyz, r0.xyz));
  r0.y = saturate(dot(r1.xyz, r3.xyz));
  r1.xyz = r0.yyy * r4.yzw + r2.xzw;
  r0.yzw = r0.www * r5.yzw + r1.xyz;
  r0.x = log2(r0.x);
  r0.x = r1.w * r0.x;
  r0.x = exp2(r0.x);
  r1.xyzw = s_luminanceMap2.Sample(s_luminanceMap2_s, v7.xy).xyzw;
  r1.x = saturate(r1.y * r5.x);
  r1.xyz = lights[4].color.rgb * r1.xxx;
  r2.xzw = r0.xxx * r1.xyz + r6.xyz;
  r0.xyz = r3.www * r1.xyz + r0.yzw;
  r1.xyzw = mtbSampleSlot1.Sample(mtbSampleSlot1_s, v0.xy).xyzw;
  r1.xyz = diffuseColor.xyz * r1.xyz;
  r0.xyz = r1.xyz * r0.xyz;
  r1.xyzw = mtbSampleSlot3.Sample(mtbSampleSlot3_s, v0.xy).xyzw;
  r3.xy = specularColor.xy * r1.zz;
  r3.xy = r3.xy * r1.xy;
  r0.w = r1.z * r1.z;
  r3.z = specularColor.z * r0.w;
  r1.xyz = r3.xyz * r2.yyy;
  r0.xyz = r1.xyz * r2.xzw + r0.xyz;
  r1.xyz = fogColor.xyz + -r0.xyz;
  r0.xyz = v2.zzz * r1.xyz + r0.xyz;
  o0.xyz = globalScale * LumaSettings.GameSettings.FogIntensity * r0.xyz;
  o0.w = globalOpacity * v3.w;
}