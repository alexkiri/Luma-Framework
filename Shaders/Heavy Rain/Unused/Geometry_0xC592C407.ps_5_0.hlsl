cbuffer ConstantBuffer : register(b0)
{
  float4 register0 : packoffset(c0);
  float4 register1 : packoffset(c1);
  float3 register2 : packoffset(c2);
  float4x4 register7 : packoffset(c3);
  float3 register11 : packoffset(c7);
  float3 register12 : packoffset(c8);
  float3 register13 : packoffset(c9);
  float4 register14 : packoffset(c10);
  float3 register15 : packoffset(c11);
  float2 register16 : packoffset(c12);
  float4 register17 : packoffset(c13);
  float3 register18 : packoffset(c14);
  float2 register19 : packoffset(c15);
  float4x4 INVERSE_TRANSPOSE_OBJECT_TO_VIEW_MATRIX : packoffset(c16);
  float4 ALPHA_TEST_PARAM : packoffset(c20);
  float4 TEXEL_MARGIN : packoffset(c21);
}

SamplerState SAMPLER_CLOTH_LD_04_D_ddsSampler_s : register(s0);
SamplerState SAMPLER_CLOTH_LD_04_N_ddsSampler_s : register(s1);
SamplerState SAMPLER_AOSampler_s : register(s2);
SamplerState SAMPLER_qdAmbientCubemapSampler_s : register(s3);
Texture2D<float4> texture0 : register(t0);
Texture2D<float4> texture1 : register(t1);
Texture2D<float4> texture2 : register(t2);
TextureCube<float4> texture3 : register(t3);

void main(
  float4 v0 : TEXCOORD0,
  float4 v1 : COLOR0,
  float4 v2 : TEXCOORD4,
  float4 v3 : COLOR1,
  float3 v4 : TEXCOORD5,
  float3 v5 : TEXCOORD6,
  float3 v6 : TEXCOORD7,
  float4 v7 : TEXCOORD2,
  float4 v8 : TEXCOORD3,
  float4 v9 : TEXCOORD8,
  out float4 o0 : SV_TARGET0,
  out float4 o1 : SV_TARGET1,
  out float4 o2 : SV_TARGET2)
{
  float4 r0,r1,r2,r3,r4,r5,r6,r7;
  r0.x = texture2.Sample(SAMPLER_AOSampler_s, v0.zw).x;
  r0.yzw = texture1.Sample(SAMPLER_CLOTH_LD_04_N_ddsSampler_s, v0.xy).xyz;
  r0.yzw = float3(-0.5,-0.5,-0.5) + r0.yzw;
  r0.yzw = r0.yzw + r0.yzw;
  r1.x = dot(r0.yzw, r0.yzw);
  r1.x = rsqrt(r1.x);
  r0.yzw = r1.xxx * r0.yzw;
  r1.x = dot(v4.xyz, v4.xyz);
  r1.x = rsqrt(r1.x);
  r1.xyz = v4.xyz * r1.xxx;
  r1.w = dot(v5.xyz, v5.xyz);
  r1.w = rsqrt(r1.w);
  r2.xyz = v5.xyz * r1.www;
  r1.w = dot(v6.xyz, v6.xyz);
  r1.w = rsqrt(r1.w);
  r3.xyz = v6.xyz * r1.www;
  r1.x = dot(r1.xyz, r0.yzw);
  r1.y = dot(r2.xyz, r0.yzw);
  r1.z = dot(r3.xyz, r0.yzw);
  r0.y = dot(r1.xyz, r1.xyz);
  r0.y = rsqrt(r0.y);
  r0.yzw = r1.xyz * r0.yyy;
  r1.xyz = texture0.Sample(SAMPLER_CLOTH_LD_04_D_ddsSampler_s, v0.xy).xyz;
  r1.xyz = v1.xyz * r1.xyz;
  r1.w = dot(r0.yzw, register11.xyz);
  r1.w = r1.w * 0.5 + 0.5;
  r2.xyz = register13.xyz + -register12.xyz;
  r2.xyz = r1.www * r2.xyz + register12.xyz;
  r3.xyz = register2.xyz + -v2.xyz;
  r1.w = dot(r3.xyz, r3.xyz);
  r1.w = rsqrt(r1.w);
  r4.xyz = r3.xyz * r1.www;
  r5.xyz = register14.xyz + -v2.xyz;
  r1.w = dot(r5.xyz, r5.xyz);
  r2.w = rsqrt(r1.w);
  r6.xyz = r5.xyz * r2.www;
  r5.xyz = r5.xyz * r2.www + r4.xyz;
  r5.xyz = float3(0.5,0.5,0.5) * r5.xyz;
  r1.w = -r1.w * register16.x + 1;
  r1.w = max(0, r1.w);
  r1.w = log2(r1.w);
  r1.w = register16.y * r1.w;
  r1.w = exp2(r1.w);
  r2.w = dot(r0.yzw, r6.xyz);
  r2.w = max(0, r2.w);
  r6.xyz = register15.xyz * r2.www;
  r2.xyz = r6.xyz * r1.www + r2.xyz;
  r2.w = dot(r0.yzw, r5.xyz);
  r2.w = max(0, r2.w);
  r2.w = log2(r2.w);
  r2.w = 13.2719994 * r2.w;
  r2.w = exp2(r2.w);
  r5.xyz = register15.xyz * r2.www;
  r6.xyz = register17.xyz + -v2.xyz;
  r2.w = dot(r6.xyz, r6.xyz);
  r3.w = rsqrt(r2.w);
  r7.xyz = r6.xyz * r3.www;
  r4.xyz = r6.xyz * r3.www + r4.xyz;
  r4.xyz = float3(0.5,0.5,0.5) * r4.xyz;
  r2.w = -r2.w * register19.x + 1;
  r2.w = max(0, r2.w);
  r2.w = log2(r2.w);
  r2.w = register19.y * r2.w;
  r2.w = exp2(r2.w);
  r3.w = dot(r0.yzw, r7.xyz);
  r3.w = max(0, r3.w);
  r6.xyz = register18.xyz * r3.www;
  r2.xyz = r6.xyz * r2.www + r2.xyz;
  r3.w = dot(r0.yzw, r4.xyz);
  r3.w = max(0, r3.w);
  r3.w = log2(r3.w);
  r3.w = 13.2719994 * r3.w;
  r3.w = exp2(r3.w);
  r4.xyz = register18.xyz * r3.www;
  r4.xyz = r4.xyz * r2.www;
  r4.xyz = r5.xyz * r1.www + r4.xyz;
  if (register1.w < 0.0) {
    r3.xyz = float3(0.00999999978,0.00999999978,0.00999999978) * r3.xyz;
    r2.w = dot(r3.xyz, r3.xyz);
    r2.w = rsqrt(r2.w);
    r3.xyz = r3.xyz * r2.www;
    r2.w = dot(r0.yzw, r3.xyz);
    r2.w = r2.w + r2.w;
    r3.xyz = r2.www * r0.yzw + -r3.xyz;
    r3.xyz = int(register1.x) ? r3.xyz : r0.yzw;
    r3.w = -r3.y;
    r3.xyz = texture3.Sample(SAMPLER_qdAmbientCubemapSampler_s, r3.xwz).xyz;
  } else {
    r3.xyz = float3(0,0,0);
  }
  r5.xyz = register0.xyz * r0.xxx;
  r5.xyz = float3(0.338840008,0.338840008,0.338840008) * r5.xyz;
  r2.xyz = r2.xyz * r1.xyz;
  r2.xyz = r2.xyz * r0.xxx;
  r2.xyz = float3(0.338840008,0.338840008,0.338840008) * r2.xyz;
  r1.xyz = r5.xyz * r1.xyz + r2.xyz;
  r1.xyz = r4.xyz * float3(0.0661199987,0.0661199987,0.0661199987) + r1.xyz;
  r1.xyz = register0.www * float3(0.0330599993,0.0330599993,0.0330599993) + r1.xyz;
  r1.xyz = r1.xyz + r3.xyz;
  r1.xyz = -v3.xyz + r1.xyz;
  o0.xyz = v3.www * r1.xyz + v3.xyz;
  o2.x = v7.z / v7.w;
  o2.yzw = 0.0;
  r1.x = dot(r0.yzw, INVERSE_TRANSPOSE_OBJECT_TO_VIEW_MATRIX._m00_m10_m20);
  r1.y = dot(r0.yzw, INVERSE_TRANSPOSE_OBJECT_TO_VIEW_MATRIX._m01_m11_m21);
  r1.z = dot(r0.yzw, INVERSE_TRANSPOSE_OBJECT_TO_VIEW_MATRIX._m02_m12_m22);
  r0.x = dot(r1.xyz, r1.xyz);
  r0.x = rsqrt(r0.x);
  r0.xyz = r1.xyz * r0.xxx + float3(1,1,1);
  o1.xyz = float3(0.5,0.5,0.5) * r0.xyz;
  o0.w = 0;
  o1.w = 1;
}