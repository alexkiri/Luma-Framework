Texture2D<float4> t4 : register(t4);
Texture2D<float4> t3 : register(t3);
Texture2D<float4> t2 : register(t2);
Texture2D<float4> t1 : register(t1);
Texture2D<float4> t0 : register(t0);

SamplerComparisonState s2_s : register(s2);
SamplerState s1_s : register(s1);
SamplerState s0_s : register(s0);

cbuffer cb2 : register(b2)
{
  float4 cb2[25];
}

cbuffer cb1 : register(b1)
{
  float4 cb1[8];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[13];
}

#define cmp

// TODO: needed?
void main(
  float4 v0 : SV_POSITION0,
  float3 v1 : TEXCOORD0,
  nointerpolation float3 v2 : TEXCOORD1,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3,r4;
  r1.xyzw = t2.Load(int3(v0.xy, 0)).xyzw;
  r1.x = cb1[7].z * r1.x + cb1[7].w;
  r1.x = 1 / r1.x;
  r1.x = r1.x / v0.w;
  r0.xyzw = t3.Load(int3(v0.xy, 0)).xyzw;
  r0.xyz = r0.xyz * float3(2,2,2) + float3(-1,-1,-1);
  r1.xyz = r1.xxx * v1.xyz + v2.xyz;
  r0.w = dot(-cb0[11].xyz, r0.xyz);
  r2.xyz = float3(-0.5,-0.5,-0.5) + r1.xyz;
  r2.xyz = cmp(float3(0.5,0.5,0.5) < abs(r2.xyz));
  r2.x = asfloat(asint(r2.y) | asint(r2.x));
  r2.x = asfloat(asint(r2.z) | asint(r2.x));
  r2.y = cmp(r0.w < 0);
  r2.x = asfloat(asint(r2.y) | asint(r2.x));
  if (r2.x != 0) {
    r2.y = 0;
  }
  r1.w = 0.5;
  r3.xyzw = t0.Sample(s0_s, r1.zw).xyzw;
  r2.zw = float2(1,1) + -r1.xy;
  r4.xyzw = t1.Sample(s1_s, r2.zw).xyzw;
  if (r2.x == 0) {
    r1.x = t4.SampleCmpLevelZero(s2_s, r1.xy, r1.z).x;
    r1.y = 1 + -cb2[24].x;
    r1.x = r1.x * r1.y + cb2[24].x;
    r1.x = r3.x * r1.x;
    r1.x = r1.x * r4.w;
    r0.x = dot(r0.xyz, r0.xyz);
    r0.y = 0.5 * r0.x;
    
    int r0ix = asint(r0.x) >> 1;
    r0ix = 0x5f375a86 - r0ix;
    r0.x = asfloat(r0ix);

    r0.z = r0.x * r0.x;
    r0.y = -r0.y * r0.z + 1.5;
    r0.x = r0.x * r0.y;
    r0.x = saturate(r0.w * r0.x);
    r2.y = r1.x * r0.x;
  }
  r0.xyz = cb0[12].xyz * r2.yyy;
  r0.xyz = exp2(-r0.xyz);
  r1.xy = v0.xy * cb1[6].zw + v0.zz;
  r1.xy = cb1[1].xx + r1.xy;
  r1.xy = float2(5.39870024,5.44210005) * r1.xy;
  r1.xy = frac(r1.xy);
  r1.zw = float2(21.5351009,14.3136997) + r1.xy;
  r0.w = dot(r1.yx, r1.zw);
  r1.xy = r1.xy + r0.ww;
  r0.w = r1.x * r1.y;
  r1.xyz = float3(95.4307022,97.5901031,93.8368988) * r0.www;
  r1.xyz = frac(r1.xyz);
  r2.xyz = float3(75.0490875,75.0495682,75.0496063) * r0.www;
  r2.xyz = frac(r2.xyz);
  r1.xyz = r2.xyz + r1.xyz;
  r1.xyz = float3(-0.5,-0.5,-0.5) + r1.xyz;
  o0.xyz = r1.xyz * float3(0.000977517106,0.000977517106,0.000977517106) + r0.xyz;
  o0.w = 0;
  
  // Luma: typical UNORM like clamping
  o0.rgb = max(o0.rgb, 0.0);
  o0.a = saturate(o0.a);
}