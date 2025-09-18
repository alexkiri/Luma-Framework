Texture2D<float4> t1 : register(t1);
Texture2D<float4> t0 : register(t0);

SamplerState s1_s : register(s1);
SamplerState s0_s : register(s0);

cbuffer cb1 : register(b1)
{
  float4 cb1[1];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[19];
}

#define cmp

void main(
  float4 v0 : SV_POSITION0,
  float2 v1 : TEXCOORD0,
  float4 v2 : TEXCOORD1,
  float4 v3 : TEXCOORD2,
  float3 v4 : TEXCOORD3,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2;
  r0.xyzw = t0.Sample(s1_s, v1.xy).xyzw;
  r0.x = cb0[18].x * cb1[0].x + r0.x;
  r0.x = 0.5 * abs(r0.x);
  r0.x = frac(r0.x);
  r0.x = r0.x * 2 + -1;
  r0.y = abs(r0.x) * cb0[18].y + 1;
  r0.x = cb0[18].y * abs(r0.x);
  r0.y = -cb0[18].y + r0.y;
  r1.xyzw = cmp(v3.xyxy < v2.xyzw);

  r0.zw = asfloat(asint(r1.yw) & asint(r1.xz));
  r0.zw = asfloat(asint(r0.zw) & int2(0x3f800000,0x3f800000));

  r1.xyzw = t1.Sample(s0_s, v2.zw).xyzw;
  r0.w = r1.w * r0.w;
  r1.xyzw = cmp(v2.xyzw < v3.zwzw);

  r1.xy = asfloat(asint(r1.yw) & asint(r1.xz));
  r1.xy = asfloat(asint(r1.xy) & int2(0x3f800000,0x3f800000));

  r1.z = r1.y * r0.w;
  r2.xyzw = t1.Sample(s0_s, v2.xy).xyzw;
  r0.z = r2.w * r0.z;
  r0.xz = r1.zx * r0.xz;
  r0.x = r0.y * r0.z + -r0.x;
  r0.x = saturate(r0.w * r1.y + r0.x);
  r0.x = cb0[16].w * r0.x;
  o0.xyz = v4.xyz * r0.xxx;
  o0.w = r0.x;
  
  // Luma: typical UNORM like clamping
  o0.rgb = max(o0.rgb, 0.0);
  o0.a = saturate(o0.a);
}