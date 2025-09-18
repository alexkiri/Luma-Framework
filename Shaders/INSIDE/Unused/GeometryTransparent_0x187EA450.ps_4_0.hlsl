Texture2D<float4> t2 : register(t2);
Texture2D<float4> t1 : register(t1);
Texture2D<float4> t0 : register(t0);

SamplerState s0_s : register(s0);

cbuffer cb1 : register(b1)
{
  float4 cb1[8];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[11];
}

#define cmp

void main(
  float4 v0 : SV_POSITION0,
  float3 v1 : TEXCOORD0,
  float4 v2 : TEXCOORD1,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3,r4,r5,r6;
  r0.x = 1 / cb1[7].x;
  r1.xyzw = v2.xyzw / v0.wwww;
  r2.xyz = r1.xyz / v0.www;
  r0.yz = v0.xy * cb0[9].xy + cb0[10].ww;
  r3.xyzw = t0.SampleLevel(s0_s, r0.yz, 0).xyzw;
  r0.yzw = float3(0.5,0.5,1) * v0.xyz;
  r0.yzw = r2.xyz * r3.www + r0.yzw;
  r1.xy = cb1[6].xy * float2(0.5,0.5) + float2(-1,-1);
  r3.zw = float2(0,0);
  r2.w = 0.0416666679;
  r5.xy = float2(0,0);
  r4.xyz = r0.yzw;
  r4.w = 0;
  int4 r1i;
  r1i.z = 0;
  while (true) {
    if (r1i.z >= 24) break;
    r5.zw = min(r4.xy, r1.xy);
    r3.xy = (int2)r5.zw;
    r6.xyzw = t2.Load(r3.xyz).xyzw;
    r3.x = 1 / r6.x;
    r3.x = -cb1[7].y + r3.x;
    r3.x = -r3.x * r0.x + r4.z;
    r3.y = cmp(0 < r3.x);
    r3.x = cmp(r3.x < r1.w);
    r3.x = r3.x ? r3.y : 0;
    if (r3.x != 0) {
      r5.xy = r5.zw;
      break;
    }
    r1i.z++;
    r4.xyzw = r4.xyzw + r2.xyzw;
    r5.xy = r5.zw;
  }
  r0.xy = r5.xy + r5.xy;
  r1.xyzw = t1.Load(int3(r0.xy, 0)).xyzw;
  r0.zw = float2(-1,-1) + cb1[6].zw;
  r0.xy = r0.xy * r0.zw;
  r0.xy = r0.xy * float2(2,2) + float2(-1,-1);
  r0.x = max(abs(r0.x), abs(r0.y));
  r0.x = saturate(max(r0.x, r4.w));
  r0.y = dot(v1.xyz, v1.xyz);
  r0.y = rsqrt(r0.y);
  r0.y = v1.z * r0.y;
  r0.y = 1 + -abs(r0.y);
  r0.y = log2(r0.y);
  r0.y = cb0[8].y * r0.y;
  r2.w = exp2(r0.y);
  r0.x = r0.x * r0.x;
  r0.x = cb0[7].w * r0.x;
  r0.yzw = cb0[7].xyz + -r1.xyz;
  r0.xyz = r0.xxx * r0.yzw + r1.xyz;
  r2.xyz = r0.xyz * r2.www;
  o0.xyzw = cb0[6].xyzw * r2.xyzw;
  
  // Luma: typical UNORM like clamping
  o0.rgb = max(o0.rgb, 0.0);
  o0.a = saturate(o0.a);
}