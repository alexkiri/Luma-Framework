#include "Includes/Common.hlsl"

cbuffer ConstantBuffer : register(b0)
{
  float4 register0 : packoffset(c0);
  float4 register1 : packoffset(c1);
  float3 register2 : packoffset(c2);
  float4x4 register3 : packoffset(c3);
  float3 register7 : packoffset(c7);
  float3 register8 : packoffset(c8);
  float3 register9 : packoffset(c9);
  float4 register10 : packoffset(c10);
  float3 register11 : packoffset(c11);
  float4 register12 : packoffset(c12);
  float4 register13 : packoffset(c13);
  float4 register14 : packoffset(c14);
  float4 register15 : packoffset(c15);
  float4 register16 : packoffset(c16);
  float4 register17 : packoffset(c17);
  float4 register18 : packoffset(c18);
  float4 CONSTANT_light1PoissonBlur4 : packoffset(c19);
  float4 CONSTANT_light1PoissonBlur5 : packoffset(c20);
  float4 CONSTANT_light1PoissonBlur6 : packoffset(c21);
  float4 CONSTANT_light1PoissonBlur7 : packoffset(c22);
  float4 CONSTANT_light1PoissonBlur8 : packoffset(c23);
  float4 CONSTANT_light1PoissonBlur9 : packoffset(c24);
  float4 CONSTANT_light1PoissonBlur10 : packoffset(c25);
  float4 CONSTANT_light1PoissonBlur11 : packoffset(c26);
  float4 CONSTANT_light1PoissonBlur12 : packoffset(c27);
  float4 CONSTANT_light1PoissonBlur13 : packoffset(c28);
  float4 ALPHA_TEST_PARAM : packoffset(c29);
  float4 TEXEL_MARGIN : packoffset(c30);
}

SamplerState SAMPLER_LAURENROOM_B02_LZX_01_D3_ddsSampler_s : register(s0);
SamplerState SAMPLER_RIDO_TRANSP_ddsSampler_s : register(s1);
SamplerState SAMPLER_noise_rido_1_ddsSampler_s : register(s2);
SamplerState SAMPLER_AOSampler_s : register(s3);
SamplerState SAMPLER_qdAmbientCubemapSampler_s : register(s4);
SamplerState TEX_CUBE_INDIRECTION_1Sampler_s : register(s6);
SamplerComparisonState TEX_2D_SHADOW_1Sampler_s : register(s5);
Texture2D<float4> texture0 : register(t0);
Texture2D<float4> texture1 : register(t1);
Texture2D<float4> texture2 : register(t2);
Texture2D<float4> texture3 : register(t3);
TextureCube<float4> texture4 : register(t4);
Texture2D<float4> texture5 : register(t5);
TextureCube<float4> texture6 : register(t6);

void main(
  float4 v0 : TEXCOORD0,
  float2 v1 : TEXCOORD1,
  float4 v2 : COLOR0,
  float4 v3 : TEXCOORD4,
  float4 v4 : COLOR1,
  float3 v5 : TEXCOORD5,
  float4 v6 : TEXCOORD2,
  float4 v7 : TEXCOORD3,
  float4 v8 : TEXCOORD8,
  out float4 o0 : SV_TARGET0,
  out float4 o1 : SV_TARGET1,
  out float4 o2 : SV_TARGET2)
{
  float4 r0,r1,r2,r3,r4,r5,r6,r7,r8;
  r0.xyzw = -register13.yzxz + v3.yzxz;
  r1.x = max(abs(r0.z), abs(r0.x));
  r1.x = max(r1.x, abs(r0.w));
  r1.y = dot(r0.xzw, r0.xzw);
  r1.y = rsqrt(r1.y);
  //r1.y = rsqrt(max(r1.y, FLT_EPSILON)); // LUMA: fixed sqrt of <= 0
  r2.xyzw = r1.yyyy * r0.xyzw;
  r0.xy = (abs(r0.zx) == r1.xx);
  r3.xyzw = TEXEL_MARGIN.xxxx * r2.zxyw;
  r4.xy = TEXEL_MARGIN.xx * r2.zx;
  r5.xz = r3.xw;
  r5.y = r2.x;
  r4.z = r2.w;
  r0.yzw = r0.yyy ? r5.xyz : r4.xyz;
  r3.x = r2.z;
  r0.xyz = r0.xxx ? r3.xyz : r0.yzw;
  r0.xy = texture6.Sample(TEX_CUBE_INDIRECTION_1Sampler_s, r0.xyz).xy;
  r0.y = register13.w + r0.y;
  r0.z = -1 / r1.x;
  r0.z = r0.z * register15.x + register15.y;
  r0.z = -TEXEL_MARGIN.y + r0.z;
  r1.xy = -register15.zw + r0.xy;
  r2.xyzw = register16.xyzw + r1.xyxy;
  r0.x = texture5.SampleCmpLevelZero(TEX_2D_SHADOW_1Sampler_s, r2.xy, r0.z).x;
  r0.y = texture5.SampleCmpLevelZero(TEX_2D_SHADOW_1Sampler_s, r2.zw, r0.z).x;
  r0.x = r0.x + r0.y;
  r2.xyzw = register17.xyzw + r1.xyxy;
  r0.y = texture5.SampleCmpLevelZero(TEX_2D_SHADOW_1Sampler_s, r2.xy, r0.z).x;
  r0.x = r0.x + r0.y;
  r0.y = texture5.SampleCmpLevelZero(TEX_2D_SHADOW_1Sampler_s, r2.zw, r0.z).x;
  r0.x = r0.x + r0.y;
  r2.xyzw = register18.xyzw + r1.xyxy;
  r0.y = texture5.SampleCmpLevelZero(TEX_2D_SHADOW_1Sampler_s, r2.xy, r0.z).x;
  r0.x = r0.x + r0.y;
  r0.y = texture5.SampleCmpLevelZero(TEX_2D_SHADOW_1Sampler_s, r2.zw, r0.z).x;
  r0.x = r0.x + r0.y;
  r2.xyzw = CONSTANT_light1PoissonBlur4.xyzw + r1.xyxy;
  r0.y = texture5.SampleCmpLevelZero(TEX_2D_SHADOW_1Sampler_s, r2.xy, r0.z).x;
  r0.x = r0.x + r0.y;
  r0.y = texture5.SampleCmpLevelZero(TEX_2D_SHADOW_1Sampler_s, r2.zw, r0.z).x;
  r0.x = r0.x + r0.y;
  r2.xyzw = CONSTANT_light1PoissonBlur5.xyzw + r1.xyxy;
  r0.y = texture5.SampleCmpLevelZero(TEX_2D_SHADOW_1Sampler_s, r2.xy, r0.z).x;
  r0.x = r0.x + r0.y;
  r0.y = texture5.SampleCmpLevelZero(TEX_2D_SHADOW_1Sampler_s, r2.zw, r0.z).x;
  r0.x = r0.x + r0.y;
  r2.xyzw = CONSTANT_light1PoissonBlur6.xyzw + r1.xyxy;
  r0.y = texture5.SampleCmpLevelZero(TEX_2D_SHADOW_1Sampler_s, r2.xy, r0.z).x;
  r0.x = r0.x + r0.y;
  r0.y = texture5.SampleCmpLevelZero(TEX_2D_SHADOW_1Sampler_s, r2.zw, r0.z).x;
  r0.x = r0.x + r0.y;
  r2.xyzw = CONSTANT_light1PoissonBlur7.xyzw + r1.xyxy;
  r0.y = texture5.SampleCmpLevelZero(TEX_2D_SHADOW_1Sampler_s, r2.xy, r0.z).x;
  r0.x = r0.x + r0.y;
  r0.y = texture5.SampleCmpLevelZero(TEX_2D_SHADOW_1Sampler_s, r2.zw, r0.z).x;
  r0.x = r0.x + r0.y;
  r2.xyzw = CONSTANT_light1PoissonBlur8.xyzw + r1.xyxy;
  r0.y = texture5.SampleCmpLevelZero(TEX_2D_SHADOW_1Sampler_s, r2.xy, r0.z).x;
  r0.x = r0.x + r0.y;
  r0.y = texture5.SampleCmpLevelZero(TEX_2D_SHADOW_1Sampler_s, r2.zw, r0.z).x;
  r0.x = r0.x + r0.y;
  r2.xyzw = CONSTANT_light1PoissonBlur9.xyzw + r1.xyxy;
  r0.y = texture5.SampleCmpLevelZero(TEX_2D_SHADOW_1Sampler_s, r2.xy, r0.z).x;
  r0.x = r0.x + r0.y;
  r0.y = texture5.SampleCmpLevelZero(TEX_2D_SHADOW_1Sampler_s, r2.zw, r0.z).x;
  r0.x = r0.x + r0.y;
  r2.xyzw = CONSTANT_light1PoissonBlur10.xyzw + r1.xyxy;
  r0.y = texture5.SampleCmpLevelZero(TEX_2D_SHADOW_1Sampler_s, r2.xy, r0.z).x;
  r0.x = r0.x + r0.y;
  r0.y = texture5.SampleCmpLevelZero(TEX_2D_SHADOW_1Sampler_s, r2.zw, r0.z).x;
  r0.x = r0.x + r0.y;
  r2.xyzw = CONSTANT_light1PoissonBlur11.xyzw + r1.xyxy;
  r0.y = texture5.SampleCmpLevelZero(TEX_2D_SHADOW_1Sampler_s, r2.xy, r0.z).x;
  r0.x = r0.x + r0.y;
  r0.y = texture5.SampleCmpLevelZero(TEX_2D_SHADOW_1Sampler_s, r2.zw, r0.z).x;
  r0.x = r0.x + r0.y;
  r2.xyzw = CONSTANT_light1PoissonBlur12.xyzw + r1.xyxy;
  r0.y = texture5.SampleCmpLevelZero(TEX_2D_SHADOW_1Sampler_s, r2.xy, r0.z).x;
  r0.x = r0.x + r0.y;
  r0.y = texture5.SampleCmpLevelZero(TEX_2D_SHADOW_1Sampler_s, r2.zw, r0.z).x;
  r0.x = r0.x + r0.y;
  r0.yw = CONSTANT_light1PoissonBlur13.xy + r1.xy;
  r0.y = texture5.SampleCmpLevelZero(TEX_2D_SHADOW_1Sampler_s, r0.yw, r0.z).x;
  r0.x = r0.x + r0.y;
  r0.y = 0.0399999991 * r0.x;
  r0.x = -r0.x * 0.0399999991 + 1;
  r0.xyz = register14.xyz * r0.xxx + r0.yyy;
  r0.w = dot(v5.xyz, v5.xyz);
  r0.w = rsqrt(r0.w);
  r1.xyz = v5.xyz * r0.www;
  r0.w = texture3.Sample(SAMPLER_AOSampler_s, v0.zw).x;
  r2.xy = float2(40,52) * v0.xy;
  r1.w = texture2.Sample(SAMPLER_noise_rido_1_ddsSampler_s, r2.xy).x;
  r2.x = texture1.Sample(SAMPLER_RIDO_TRANSP_ddsSampler_s, v0.xy).x;
  r2.yzw = texture0.Sample(SAMPLER_LAURENROOM_B02_LZX_01_D3_ddsSampler_s, v1.xy).xyz;
  r3.xyz = -r2.xxx * r2.yzw + float3(1,1,1);
  r3.w = 1 + -v2.w;
  r3.xyz = -r3.xyz * r3.www + float3(1,1,1);
  r3.xyz = r1.www * float3(0.595049977,0.595049977,0.595049977) + r3.xyz;
  r2.yzw = r2.yzw + -r2.xxx;
  r2.xyz = r2.yzw * float3(0.999979973,0.999979973,0.999979973) + r2.xxx;
  r4.xyz = float3(0.0495800003,0.0325313993,0.0286571998) * r3.xyz;
  r1.w = dot(r1.xyz, register7.xyz);
  r1.w = r1.w * 0.5 + 0.5;
  r5.xyz = register9.xyz + -register8.xyz;
  r5.xyz = r1.www * r5.xyz + register8.xyz;
  r6.xyz = register2.xyz + -v3.xyz;
  r1.w = dot(r6.xyz, r6.xyz);
  r1.w = rsqrt(r1.w);
  r7.xyz = register10.xyz + -v3.xyz;
  r2.w = dot(r7.xyz, r7.xyz);
  r3.w = rsqrt(r2.w);
  r7.xyz = r7.xyz * r3.www;
  r8.xyz = r6.xyz * r1.www + r7.xyz;
  r8.xyz = float3(0.5,0.5,0.5) * r8.xyz;
  r1.w = -r2.w * register12.x + 1;
  r1.w = max(0, r1.w);
  r1.w = log2(r1.w);
  r1.w = register12.y * r1.w;
  r1.w = exp2(r1.w);
  r0.xyz = register11.xyz * r0.xyz;
  r2.w = dot(r1.xyz, r7.xyz);
  r2.w = max(0, r2.w);
  r7.xyz = r2.www * r0.xyz;
  r5.xyz = r7.xyz * r1.www + r5.xyz;
  r2.w = dot(r1.xyz, r8.xyz);
  r2.w = max(0, r2.w);
  r2.w = log2(r2.w);
  r2.w = 800 * r2.w;
  r2.w = exp2(r2.w);
  r0.xyz = r2.www * r0.xyz;
  r0.xyz = r0.xyz * r1.www;
  if (register1.w < 0) {
    r6.xyz = float3(0.00999999978,0.00999999978,0.00999999978) * r6.xyz;
    r2.w = dot(r6.xyz, r6.xyz);
    r2.w = rsqrt(r2.w);
    r6.xyz = r6.xyz * r2.www;
    r2.w = dot(r1.xyz, r6.xyz);
    r2.w = r2.w + r2.w;
    r6.xyz = r2.www * r1.xyz + -r6.xyz;
    r1.xyz = int(register1.x) ? r6.xyz : r1.xyz;
    r1.w = -r1.y;
    r1.xyz = texture4.Sample(SAMPLER_qdAmbientCubemapSampler_s, r1.xwz).xyz;
  } else {
    r1.xyz = float3(0,0,0);
  }
  r6.xyz = register0.xyz * r0.www;
  r5.xyz = r5.xyz * r2.xyz;
  r5.xyz = r5.xyz * r0.www;
  r2.xyz = r6.xyz * r2.xyz + r5.xyz;
  r0.xyz = r0.xyz * r3.xyz + r2.xyz;
  r0.xyz = r4.xyz * register0.www + r0.xyz;
  r0.xyz = r0.xyz + r1.xyz;
  r0.xyz = -v4.xyz + r0.xyz;
  o0.xyz = v4.www * r0.xyz + v4.xyz;
  o2.x = v6.z / v6.w;
  o2.yzw = 0.0;
  o0.w = r3.x;
  o1.xyzw = float4(0,0,0,0);
  
  // LUMA: UNORM blends emulation
  o0.w = saturate(o0.w);
  o0.rgb = max(o0.rgb, 0.0);
}