cbuffer ConstantBuffer : register(b0)
{
  float3 register0 : packoffset(c0);
  float3 register1 : packoffset(c1);
  float4x4 register2 : packoffset(c2);
  float4 ALPHA_TEST_PARAM : packoffset(c6);
  float4 TEXEL_MARGIN : packoffset(c7);
}

SamplerState SAMPLER_HANGFINAL_EXT_CUBMAP_128_ddsSampler_s : register(s0);
SamplerState SAMPLER_DROPS_NM_ddsSampler_s : register(s1);
SamplerState SAMPLER_qdVideoTexture2Sampler_s : register(s2);
SamplerState SAMPLER_LIGHTS_N_ddsSampler_s : register(s3);
TextureCube<float4> texture0 : register(t0);
Texture2D<float4> texture1 : register(t1);
Texture2D<float4> texture2 : register(t2);
Texture2D<float4> texture3 : register(t3);

void main(
  float4 v0 : TEXCOORD0,
  float4 v1 : TEXCOORD1,
  float4 v2 : TEXCOORD4,
  float4 v3 : COLOR1,
  float3 v4 : TEXCOORD5,
  float3 v5 : TEXCOORD6,
  float3 v6 : TEXCOORD7,
  float4 v7 : TEXCOORD2,
  float4 v8 : TEXCOORD8,
  out float4 o0 : SV_TARGET0,
  out float4 o1 : SV_TARGET1,
  out float4 o2 : SV_TARGET2)
{
  float4 r0,r1,r2;
  r0.xyzw = float4(1,-1,2,4) * v1.zwzw;
  r0.zw = texture1.Sample(SAMPLER_DROPS_NM_ddsSampler_s, r0.zw).yw;
  r1.xyz = texture2.Sample(SAMPLER_qdVideoTexture2Sampler_s, r0.xy).xyz;
  r0.xy = r0.wz * float2(2,2) + float2(-1,-1);
  r0.w = -r0.x * r0.x + 1;
  r0.w = -r0.y * r0.y + r0.w;
  r0.z = sqrt(abs(r0.w));
  r0.xyz = r0.xyz * float3(0.5,0.5,0.5) + r1.xyz;
  r1.xyz = float3(0.5,0.5,1) + -r0.xyz;
  r0.xyz = register0.xxx * r1.xyz + r0.xyz;
  r1.xyz = float3(0.5,0.5,1) + -r0.xyz;
  r0.xyz = r1.xyz * float3(0.699999988,0.699999988,0.699999988) + r0.xyz;
  r1.xy = texture3.Sample(SAMPLER_LIGHTS_N_ddsSampler_s, v0.xy).yw;
  r1.xy = r1.yx * float2(2,2) + float2(-1,-1);
  r0.w = -r1.x * r1.x + 1;
  r0.w = -r1.y * r1.y + r0.w;
  r1.z = sqrt(abs(r0.w));
  r1.xyz = r1.xyz * float3(0.5,0.5,0.5) + float3(0.5,0.5,0.5);
  r0.xyz = r1.xyz + r0.xyz;
  r0.xyz = float3(-1,-1,-1) + r0.xyz;
  r0.xyz = r0.xyz + r0.xyz;
  r0.w = dot(r0.xyz, r0.xyz);
  r0.w = rsqrt(r0.w);
  r0.xyz = r0.xyz * r0.www;
  r0.w = dot(v4.xyz, v4.xyz);
  r0.w = rsqrt(r0.w);
  r1.xyz = v4.xyz * r0.www;
  r1.x = dot(r1.xyz, r0.xyz);
  r0.w = dot(v5.xyz, v5.xyz);
  r0.w = rsqrt(r0.w);
  r2.xyz = v5.xyz * r0.www;
  r1.y = dot(r2.xyz, r0.xyz);
  r0.w = dot(v6.xyz, v6.xyz);
  r0.w = rsqrt(r0.w);
  r2.xyz = v6.xyz * r0.www;
  r1.z = dot(r2.xyz, r0.xyz);
  r0.x = dot(r1.xyz, r1.xyz);
  r0.x = rsqrt(r0.x);
  r0.xyz = r1.xyz * r0.xxx;
  r1.xyz = register1.xyz + -v2.xyz;
  r1.xyz = float3(0.00999999978,0.00999999978,0.00999999978) * r1.xyz;
  r0.w = dot(r1.xyz, r1.xyz);
  r0.w = rsqrt(r0.w);
  r1.xyz = r1.xyz * r0.www;
  r0.w = dot(r0.xyz, r1.xyz);
  r0.w = r0.w + r0.w;
  r0.xyz = r0.www * r0.xyz + -r1.xyz;
  r0.w = dot(r0.xyz, register2._m01_m11_m21);
  r1.y = -r0.w;
  r1.x = dot(r0.xyz, register2._m00_m10_m20);
  r1.z = dot(r0.xyz, register2._m02_m12_m22);
  r0.xyz = texture0.Sample(SAMPLER_HANGFINAL_EXT_CUBMAP_128_ddsSampler_s, r1.xyz).xyz;
  r0.xyz = -v3.xyz + r0.xyz;
  o0.xyz = v3.www * r0.xyz + v3.xyz;
  o0.w = 0.247960001;
  o1.xyzw = float4(0,0,0,0);
  o2.x = v7.z / v7.w;
  o2.yzw = 0.0;
  
  // LUMA: UNORM blends emulation
  o0.rgb = max(o0.rgb, 0.0);
}