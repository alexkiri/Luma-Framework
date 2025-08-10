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
  float4 cb0[6];
}

void main(
  float4 v0 : SV_POSITION0,
  float2 v1 : TEXCOORD0,
  float v1z : TEXCOORD1,
  float4 v2 : TEXCOORD2,
  float3 v3 : TEXCOORD3,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3; //TODOFT: doesn't match... yet
  r0.xy = v2.xy / v2.ww;
  r0.xyzw = t1.Sample(s0_s, r0.xy).xyzw;
  r0.xyz = max(float3(0.000977517106,0.000977517106,0.000977517106), r0.xyz);
  r0.xyz = log2(r0.xyz);
  r0.xyz = saturate(cb0[0].xyz + -r0.xyz);
  r1.xy = r0.xy * float2(2,2) + -r0.yx;
  r1.xy = r1.xy + -r0.zz;
  r0.x = dot(float3(0.333299994,0.333299994,0.333299994), r0.xyz);
  r0.yz = float2(0.333333343,0.333333343) * r1.xy;
  r0.w = max(abs(r0.y), abs(r0.z));
  r0.w = 1 / r0.w;
  r1.x = min(abs(r0.y), abs(r0.z));
  r0.w = r1.x * r0.w;
  r1.x = r0.w * r0.w;
  r1.y = r1.x * 0.0208350997 + -0.0851330012;
  r1.y = r1.x * r1.y + 0.180141002;
  r1.y = r1.x * r1.y + -0.330299497;
  r1.x = r1.x * r1.y + 0.999866009;
  r1.y = r1.x * r0.w;
  r1.y = r1.y * -2 + 1.57079637;
  r1.z = (abs(r0.z) < abs(r0.y));
  r1.y = asfloat(asint(r1.z) & asint(r1.y));
  r0.w = r0.w * r1.x + r1.y;
  r1.x = (r0.z < -r0.z);
  r1.x = asfloat(asint(r1.x) & 0xc0490fdb);
  r0.w = r1.x + r0.w;
  r1.x = min(r0.y, r0.z);
  r1.x = (r1.x < -r1.x);
  r1.y = max(r0.y, r0.z);
  r0.yz = r0.yz * r0.yz;
  r0.y = r0.y + r0.z;
  r0.y = sqrt(r0.y);
  r0.z = (r1.y >= -r1.y);
  r0.z = asfloat(asint(r0.z) & asint(r1.x));
  r0.z = r0.z ? -r0.w : r0.w;
  r0.w = (0 < r0.y);
  r0.z = asfloat(asint(r0.z) & asint(r0.w));
  sincos(r0.z, r1.x, r2.x);
  r0.zw = (v1.xy < float2(0.75,0.5));
  r0.zw = asfloat(asint(r0.zw) & 1);
  r1.yz = (float2(0.5,0.25) < v1.xy);
  r1.yz = asfloat(asint(r1.yz) & 1);
  int2 r0zwi = asint(r0.zw) * asint(r1.yz);
  int2 r0zwic = r0zwi != 0;
  r0.z = asfloat((r0zwic.y) & (r0zwic.x));
  r0.z = r0.z ? cb0[4].y : cb0[4].x;
  r0.x = r0.x + -r0.z;
  r0.w = 1 + -r0.z;
  r0.z = r0.w + -r0.z;
  r0.x = saturate(r0.x / r0.z);
  r0.z = -r0.y * r1.x + r0.x;
  r3.z = saturate(-r0.y * r2.x + r0.z);
  r3.x = r0.y * r1.x + r0.x;
  r3.y = r0.y * r2.x + r0.x;
  r0.x = -0.2 + r0.x;
  r0.x = -5 * r0.x;
  r0.x = max(0, r0.x);
  r0.x = 0.6 * r0.x;
  r0.yzw = v3.xyz + r3.xyz;
  r1.xyzw = t0.Sample(s1_s, v1.xy).xyzw;
  r2.xyz = r1.xyz * r0.yzw;
  r1.w = dot(r2.xyz, float3(0.219999999,0.707000017,0.0710000023));
  r0.yzw = -r0.yzw * r1.xyz + r1.w;
  r0.xyz = r0.xxx * r0.yzw + r2.xyz;
  r0.xyz = r0.xyz * cb0[5].xyz + -cb1[0].xyz;
  r0.w = 1 + -cb1[0].w;
  r0.w = max(v1z, r0.w);
  r0.w = min(1, r0.w);
  o0.xyz = r0.w * r0.xyz + cb1[0].xyz;
  o0.w = 1;
}