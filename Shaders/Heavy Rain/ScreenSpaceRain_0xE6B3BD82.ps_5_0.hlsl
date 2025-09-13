cbuffer ConstentValue : register(b0)
{
  float4 register0 : packoffset(c0);
  float4 register1 : packoffset(c1);
  float4 register2 : packoffset(c2);
  float4 register3 : packoffset(c3);
  float4 register4 : packoffset(c4);
}

SamplerState sampler0_s : register(s0);
SamplerState sampler1_s : register(s1);
SamplerState sampler2_s : register(s2);
Texture2D<float4> texture0 : register(t0);
Texture2D<float4> texture1 : register(t1);
Texture2D<float4> texture2 : register(t2);

void main(
  float4 v0 : SV_POSITION0,
  float2 v1 : TEXCOORD0,
  float2 w1 : TEXCOORD1,
  float2 v2 : TEXCOORD2,
  out float4 o0 : SV_TARGET0)
{
  float4 r0,r1,r2;
  r0.x = -v1.y * register0.x + 1;
  r0.xyzw = v1.xyxy / r0.x;
  r1.x = register2.y * r0.w;
  r1.y = register1.y + r1.x;
  r1.z = 0.2;
  r2.xz = r0.zz * register2.xy + register0.ww;
  r1.x = r2.z + r1.z;
  r1.xyzw = texture0.SampleLevel(sampler0_s, r1.xy, 1).xyzw;
  r2.y = r0.w * register2.x + register1.x;
  r2.xyzw = texture0.SampleLevel(sampler0_s, r2.xy, 0).xyzw;
  r1.xyzw = r2.xyzw + r1.xyzw;
  r2.xy = register2.zw * r0.yw;
  r0.xy = r0.xz * register2.zw + register0.ww;
  r0.xz = float2(0.5,0.330000013) + r0.xy;
  r0.yw = register1.zw + r2.xy;
  r2.xyzw = texture0.SampleLevel(sampler0_s, r0.xy, 2).xyzw;
  r0.xyzw = texture0.SampleLevel(sampler0_s, r0.zw, 3).xyzw;
  r1.xyzw = r2.xyzw + r1.xyzw;
  r0.xyzw = r1.xyzw + r0.xyzw;
  r1.x = texture1.Sample(sampler1_s, w1.xy).x;
  r1.x = -r1.x * register3.z + register3.y;
  r1.x = register3.x / r1.x;
  r1.x = register4.x + r1.x;
  r1.x = saturate(register4.y * r1.x);
  r1.y = register0.z - register0.y;
  r1.x = r1.x * r1.y + register0.y;
  r1.yzw = texture2.Sample(sampler2_s, v2.xy).xyz;
  r1.yzw = r1.yzw * register4.z + register4.w;
  r1.xyz = r1.x * r1.yzw;
  o0.xyz = r1.xyz * r0.xyz;
  o0.w = r0.w;
}