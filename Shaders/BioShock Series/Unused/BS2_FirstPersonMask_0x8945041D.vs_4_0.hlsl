cbuffer _Globals : register(b0)
{
  float Base_hlsl_VSMain0000000000000000000020a016adcae4_46bits : packoffset(c0) = {0};
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
  float4 UniformVector_0 : packoffset(c17);
  float4 UniformVector_1 : packoffset(c18);
  float4 UniformVector_2 : packoffset(c19);
  float4 UniformVector_3 : packoffset(c20);
  float UniformScalar_0 : packoffset(c21);
  float UniformScalar_1 : packoffset(c21.y);
  float UniformScalar_2 : packoffset(c21.z);
  float UniformScalar_3 : packoffset(c21.w);
  float UniformScalar_4 : packoffset(c22);
  float UniformScalar_5 : packoffset(c22.y);
  float4 Ambient : packoffset(c23);
  row_major float4x3 localToWorld : packoffset(c24);
}

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
  out float3 o4 : TEXCOORD3,
  out float3 o5 : TEXCOORD4,
  out float3 o6 : TEXCOORD5,
  out float4 o7 : SV_Position0,
  out float o8 : SV_ClipDistance0)
{
  float4 r0,r1,r2,r3,r4;
  r0.w = 1;
  r1.w = dot(worldViewProj._m30_m31_m32_m33, v0.xyzw);
  r0.z = r1.w;
  r1.x = dot(worldViewProj._m00_m01_m02_m03, v0.xyzw);
  r1.y = dot(worldViewProj._m10_m11_m12_m13, v0.xyzw);
  r1.z = dot(worldViewProj._m20_m21_m22_m23, v0.xyzw);
  r0.x = dot(screenTransform[0].xyzw, r1.xyzw);
  r0.y = dot(screenTransform[1].xyzw, r1.xyzw);
  r2.x = dot(screenDataToCamera._m00_m01_m02_m03, r0.xyzw);
  r2.y = dot(screenDataToCamera._m10_m11_m12_m13, r0.xyzw);
  r2.z = dot(screenDataToCamera._m20_m21_m22_m23, r0.xyzw);
  o0.xyw = r0.xyz;
  r0.x = dot(r2.xyz, r2.xyz);
  r0.x = sqrt(r0.x);
  r0.x = r0.x * fogTransform.x + fogTransform.y;
  r0.x = 1.44269502 * r0.x;
  r0.x = exp2(r0.x);
  r0.x = min(1, r0.x);
  r0.x = -fogColor.w * r0.x + fogColor.w;
  o0.z = fogTransform.z * r0.x;
  o1.w = 1;
  r0.xyz = localEyePos.xyz + -v0.xyz;
  r2.xyz = v1.xyz * float3(2,2,2) + float3(-1,-1,-1);
  o1.x = dot(r0.xyz, r2.xyz);
  r3.xyz = v2.xyz * float3(2,2,2) + float3(-1,-1,-1);
  o1.y = dot(r0.xyz, r3.xyz);
  r4.xyz = v3.xyz * float3(2,2,2) + float3(-1,-1,-1);
  o1.z = dot(r0.xyz, r4.xyz);
  o2.xyzw = v11.zyxw;
  o3.xy = v4.xy;
  r0.xyz = localToWorld._m10_m11_m12 * r2.yyy;
  r0.xyz = r2.xxx * localToWorld._m00_m01_m02 + r0.xyz;
  o4.xyz = r2.zzz * localToWorld._m20_m21_m22 + r0.xyz;
  r0.xyz = localToWorld._m10_m11_m12 * r3.yyy;
  r0.xyz = r3.xxx * localToWorld._m00_m01_m02 + r0.xyz;
  o5.xyz = r3.zzz * localToWorld._m20_m21_m22 + r0.xyz;
  r0.xyz = localToWorld._m10_m11_m12 * r4.yyy;
  r0.xyz = r4.xxx * localToWorld._m00_m01_m02 + r0.xyz;
  o6.xyz = r4.zzz * localToWorld._m20_m21_m22 + r0.xyz;
  o7.xyzw = r1.xyzw;
  o8.x = dot(vertexClipPlane.xyzw, r1.xyzw);
#if 0
  o7.w = -1.0;
#endif
}