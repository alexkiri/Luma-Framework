#include "Includes/Common.hlsl"

Texture2D<float4> t0 : register(t0);

SamplerState s0_s : register(s0);

cbuffer cb1 : register(b1)
{
  float4 cb1[2];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[10];
}

// Note: handling of this for HDR has been moved to the bloom+emissive generation step
void main(
  float4 v0 : SV_POSITION0,
  float2 v1 : TEXCOORD0,
  out float4 o0 : SV_Target0)
{
  const float4 icb[] = { { 0, 0, 0.250000, 0},
                              { -0.852561, 0.852561, 0.062500, 0},
                              { 0, 0.875000, 0.125000, 0},
                              { 0.852561, 0.852561, 0.062500, 0},
                              { -0.875000, 0, 0.125000, 0},
                              { 0.875000, 0, 0.125000, 0},
                              { -0.852561, -0.852561, 0.062500, 0},
                              { 0, -0.875000, 0.125000, 0},
                              { 0.852561, -0.852561, 0.062500, 0} };
  float4 r0,r1,r2,r3;
  o0.w = 1;
  r0.xyzw = t0.Sample(s0_s, v1.xy).xyzw;
  r1.xyz = r0.xyz - 1.0; // Bring to negative range (unless there were values beyond 1)
  r1.xyz = min(r1.xyz, -FLT_EPSILON); // LUMA: fix emissive values >= 1 causing garbage
  r1.xyz = asfloat(-asint(r1.xyz) + int(0x7ef311c2)); // Blue noise
  r1.xyz *= -r0.xyz * 0.25;
  //o0.xyz = r1.xyz; return; // Test output
  int4 r0i;
  r0i.w = 1;
  while (true) {
    if (r0i.w >= 9) break;
    r2.xy = cb0[9].zw * icb[r0i.w+0].xy + v1.xy;
    r2.xyzw = t0.Sample(s0_s, r2.xy).xyzw;
    r3.xyz = r2.xyz - 1.0;
    r3.xyz = min(r3.xyz, -FLT_EPSILON); // LUMA: fix emissive values >= 1 causing garbage
    r3.xyz = asfloat(-asint(r3.xyz) + int(0x7ef311c2));
    r1.xyz -= icb[r0i.w+0].z * r3.xyz * r2.xyz;
    r0i.w++;
  }
  r0.xyz = cb0[7].x * r1.xyz;
  r1.xyz = r1.xyz * cb0[7].x + 1.0;
  r1.xyz = asfloat(-asint(r1.xyz) + int(0x7ef311c2));
  r2.xy = cb1[1].x + v1.xy;
  r2.xy = float2(0.134299994,0.134299994) + r2.xy;
  r2.xy = float2(5.39870024,5.44210005) * r2.xy;
  r2.xy = frac(r2.xy);
  r2.zw = float2(21.5351009,14.3136997) + r2.xy;
  r0.w = dot(r2.yx, r2.zw);
  r2.xy = r2.xy + r0.w;
  r0.w = r2.x * r2.y;
  r2.xyz = float3(95.4307022,97.5901031,93.8368988) * r0.w;
  r2.xyz = frac(r2.xyz);
  r3.xyz = float3(75.0490875,75.0495682,75.0496063) * r0.w;
  r3.xyz = frac(r3.xyz);
  r2.xyz = r3.xyz + r2.xyz;
  r2.xyz -= 0.5;
  r2.xyz = r2.xyz * 0.5 + float3(-0.25,-0.25,-0.25);
  r2.xyz = cb0[8].z * r2.xyz;
  o0.xyz = r0.xyz * r1.xyz + r2.xyz;
}