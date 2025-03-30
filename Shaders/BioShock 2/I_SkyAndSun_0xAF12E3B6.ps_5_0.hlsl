cbuffer _Globals : register(b0)
{
  float4x4 LocalToWorld : packoffset(c0);
  float4x4 InvViewProjectionMatrix : packoffset(c4);
  float3 CameraWorldPos : packoffset(c8);
  float4 ObjectWorldPositionAndRadius : packoffset(c9);
  float3 ObjectOrientation : packoffset(c10);
  float3 ObjectPostProjectionPosition : packoffset(c11);
  float3 ObjectNDCPosition : packoffset(c12);
  float4 ObjectMacroUVScales : packoffset(c13);
  float3 FoliageImpulseDirection : packoffset(c14);
  float4 FoliageNormalizedRotationAxisAndAngle : packoffset(c15);
  float4 WindDirectionAndSpeed : packoffset(c16);
  float3 CameraWorldDirection : packoffset(c17) = {1,0,0};
  float4 ObjectOriginAndPrimitiveID : packoffset(c18) = {0,0,0,0};
  float3x3 LocalToWorldMatrix : packoffset(c19);
  float3x3 WorldToLocalMatrix : packoffset(c22);
  float3x3 WorldToViewMatrix : packoffset(c25);
  float3x3 ViewToWorldMatrix : packoffset(c28);
  float4x4 WorldToFloatingSectionMatrix : packoffset(c31);
  float4 UniformPixelVector_0 : packoffset(c35);
  float4 UniformPixelVector_1 : packoffset(c36);
  float4 UniformPixelVector_2 : packoffset(c37);
  float4 UniformPixelVector_3 : packoffset(c38);
  float4 UniformPixelVector_4 : packoffset(c39);
  float4 UniformPixelVector_5 : packoffset(c40);
  float4 UniformPixelVector_6 : packoffset(c41);
  float4 UniformPixelVector_7 : packoffset(c42);
  float4 UniformPixelVector_8 : packoffset(c43);
  float4 UniformPixelVector_9 : packoffset(c44);
  float4 UniformPixelVector_10 : packoffset(c45);
  float4 UniformPixelVector_11 : packoffset(c46);
  float4 UniformPixelVector_12 : packoffset(c47);
  float4 UniformPixelVector_13 : packoffset(c48);
  float4 UniformPixelVector_14 : packoffset(c49);
  float4 UniformPixelVector_15 : packoffset(c50);
  float4 UniformPixelVector_16 : packoffset(c51);
  float4 UniformPixelVector_17 : packoffset(c52);
  float4 UniformPixelVector_18 : packoffset(c53);
  float4 UniformPixelVector_19 : packoffset(c54);
  float4 UniformPixelVector_20 : packoffset(c55);
  float4 UniformPixelVector_21 : packoffset(c56);
  float4 UniformPixelVector_22 : packoffset(c57);
  float4 UniformPixelVector_23 : packoffset(c58);
  float4 UniformPixelVector_24 : packoffset(c59);
  float4 UniformPixelVector_25 : packoffset(c60);
  float4 UniformPixelVector_26 : packoffset(c61);
  float4 UniformPixelScalars_0 : packoffset(c62);
  float4 UniformPixelScalars_1 : packoffset(c63);
  float4 UniformPixelScalars_2 : packoffset(c64);
  float4 UniformPixelScalars_3 : packoffset(c65);
  float4 UniformPixelScalars_4 : packoffset(c66);
  float4 UniformPixelScalars_5 : packoffset(c67);
  float4 UniformPixelScalars_6 : packoffset(c68);
  float4 UniformPixelScalars_7 : packoffset(c69);
  float4 UniformPixelScalars_8 : packoffset(c70);
  float4 UniformPixelScalars_9 : packoffset(c71);
  float4 UniformPixelScalars_10 : packoffset(c72);
  float4 UniformPixelScalars_11 : packoffset(c73);
  float4 UniformPixelScalars_12 : packoffset(c74);
  float4 UniformPixelScalars_13 : packoffset(c75);
  float LocalToWorldRotDeterminantFlip : packoffset(c76);
  float4 LightmapCoordinateScaleBias : packoffset(c77);
  float3x3 WorldToLocal : packoffset(c78);
  float3 MeshOrigin : packoffset(c81);
  float3 MeshExtension : packoffset(c82);
  float3 IrradianceUVWScale : packoffset(c83);
  float3 IrradianceUVWBias : packoffset(c84);
}

SamplerState Texture2D_0_s : register(s0);
SamplerState Texture2D_1_s : register(s1);
SamplerState Texture2D_2_s : register(s2);
SamplerState Texture2D_3_s : register(s3);
SamplerState Texture2D_4_s : register(s4);
Texture2D<float4> Texture2D_0 : register(t0);
Texture2D<float4> Texture2D_1 : register(t1);
Texture2D<float4> Texture2D_2 : register(t2);
Texture2D<float4> Texture2D_3 : register(t3);
Texture2D<float4> Texture2D_4 : register(t4);

#define cmp -

void main(
  float4 v0 : TEXCOORD3,
  float4 v1 : TEXCOORD4,
  float4 v2 : TEXCOORD0,
  float4 v3 : TEXCOORD1,
  float4 v4 : TEXCOORD5,
  float4 v5 : TEXCOORD6,
  uint v6 : SV_IsFrontFace0,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3,r4,r5,r6;
  r0.x = dot(v5.xyz, v5.xyz);
  r0.x = rsqrt(r0.x);
  r0.xyz = v5.xyz * r0.xxx;
  r1.xy = v2.xy * float2(2,1) + UniformPixelVector_14.xy;
  r0.w = Texture2D_2.Sample(Texture2D_2_s, r1.xy).x;
  r0.w = r0.w * 2 + -1;
  r1.x = v2.x * 2 + UniformPixelVector_15.x;
  r1.x = r0.w * 0.00300000003 + r1.x;
  r0.w = v2.y * 1 + -0.5;
  r0.w = r0.w + r0.w;
  r1.y = -abs(r0.w);
  r1.zw = Texture2D_2.Sample(Texture2D_2_s, r1.xy).xy;
  r0.w = Texture2D_3.Sample(Texture2D_3_s, r1.xy).x;
  r0.w = saturate(UniformPixelScalars_12.w * r0.w);
  r1.xy = r1.zw * float2(2,2) + float2(-1,-1);
  r1.w = dot(r1.xy, r1.xy);
  r1.w = 1 + -r1.w;
  r1.w = max(0, r1.w);
  r1.z = sqrt(r1.w);
  r0.x = dot(r1.xyz, r0.xyz);
  r0.x = max(0, r0.x);
  r0.x = 1 + -r0.x;
  r0.y = abs(r0.x) * abs(r0.x);
  r0.y = abs(r0.x) * r0.y;
  r0.x = cmp(abs(r0.x) < 9.99999997e-007);
  r0.z = dot(v1.xyz, v1.xyz);
  r0.z = rsqrt(r0.z);
  r2.xyz = v1.xyz * r0.zzz;
  r0.z = dot(v0.xyz, v0.xyz);
  r0.z = rsqrt(r0.z);
  r3.xyz = v0.xyz * r0.zzz;
  r4.xyz = r3.yzx * r2.zxy;
  r4.xyz = r2.yzx * r3.zxy + -r4.xyz;
  r4.xyz = v1.www * r4.xyz;
  r4.xyz = UniformPixelVector_10.yyy * r4.xyz;
  r3.xyz = UniformPixelVector_10.xxx * r3.xyz + r4.xyz;
  r2.xyz = UniformPixelVector_10.zzz * r2.xyz + r3.xyz;
  r0.z = saturate(-r2.z);
  r1.w = r0.z * r0.z;
  r1.w = r1.w * r1.w;
  r1.w = r1.w * r0.z;
  r2.w = cmp(r0.z < 9.99999997e-007);
  r1.w = r2.w ? 0 : r1.w;
  r0.y = r1.w * r0.y;
  r3.xyzw = UniformPixelVector_13.xyzz * r0.yyyy;
  r3.xyzw = UniformPixelScalars_11.zzzz * r3.xyzw;
  r3.xyzw = r0.xxxx ? float4(0,0,0,0) : r3.xyzw;
  r0.x = dot(r2.xyz, r1.xyz);
  r1.xy = saturate(r2.xy * float2(3,3) + float2(0.5,0.5));
  r1.xyz = Texture2D_1.Sample(Texture2D_1_s, r1.xy).xyz;
#if 1 // LUMA: make sun stronger
  r1.xyz *= 1.5;
#endif
  r1.xyzw = r1.xyzz * r0.zzzz;
  r0.y = log2(r0.z);
  r0.y = UniformPixelScalars_9.z * r0.y;
  r0.y = exp2(r0.y);
  r0.y = UniformPixelScalars_9.w * r0.y;
  r0.y = r2.w ? 0 : r0.y;
  r0.x = UniformPixelScalars_11.w + r0.x;
  r0.x = saturate(UniformPixelScalars_12.y * r0.x);
  r2.xyzw = r0.xxxx * UniformPixelVector_13.xyzz + UniformPixelVector_17.xyzz;
  r2.xyzw = UniformPixelScalars_12.zzzz * r2.xyzw + r3.xyzw;
  r0.x = -0.5 + v2.y;
  r0.z = r0.x + r0.x;
  r3.xy = float2(100,5) * r0.xx;
  r0.x = -abs(r0.z) * abs(r0.z) + 1;
  r0.x = r0.x * r0.x;
  r4.xyzw = -UniformPixelVector_6.xyzz + UniformPixelVector_5.xyzz;
  r4.xyzw = r0.xxxx * r4.xyzw + UniformPixelVector_6.xyzz;
  r0.xz = float2(7,7) * v3.xy;
  r5.xyz = Texture2D_0.Sample(Texture2D_0_s, r0.xz).xyz;
  r0.xz = v3.xy * float2(7.5,7.5) + UniformPixelVector_7.xy;
  r6.xyz = Texture2D_0.Sample(Texture2D_0_s, r0.xz).xyz;
  r5.xyzw = r6.xyzz * r5.xyzz;
  r3.x = saturate(r3.x);
  r0.x = min(1, abs(r3.y));
  r0.x = 1 + -r0.x;
  r0.x = r0.x * r0.x;
  r0.x = UniformPixelScalars_13.z * r0.x;
  r0.z = 1 + -r3.x;
  r5.xyzw = r0.zzzz * r5.xyzw;
  r4.xyzw = UniformPixelScalars_1.wwww * r5.xyzw + r4.xyzw;
  r5.xyzw = UniformPixelVector_11.xyzz + -r4.xyww;
  r4.xyzw = r0.yyyy * r5.xyzw + r4.xyzw;
  r1.xyzw = r1.xyzw * UniformPixelVector_13.xyzz + r4.xyzw;
  r2.xyzw = r2.xyzw + -r1.xyww;
  r1.xyzw = r0.wwww * r2.xyzw + r1.xyzw;
  r2.xyz = Texture2D_4.Sample(Texture2D_4_s, v2.wz).xyz;
  r2.xyzw = UniformPixelVector_20.xyzz * r2.xyzz + -r1.xyww;
  r1.xyzw = r3.xxxx * r2.xyzw + r1.xyzw;
  r2.xyzw = -UniformPixelVector_22.xyzz + UniformPixelVector_11.xyzz;
  r2.xyzw = r0.yyyy * r2.xyzw + UniformPixelVector_22.xyzz;
  r2.xyzw = r2.xyzw + -r1.xyww;
  r0.xyzw = r0.xxxx * r2.xyzw + r1.xyzw;
  o0.xyzw = UniformPixelVector_23.xyzz * r0.xyzw + UniformPixelVector_24.xyzz;
}