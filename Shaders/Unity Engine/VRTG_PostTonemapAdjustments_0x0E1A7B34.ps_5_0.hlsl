Texture2DArray<float4> t3 : register(t3);
Texture2DArray<float4> t2 : register(t2);
Texture2D<float4> t1 : register(t1);
Texture2DArray<float4> t0 : register(t0);

SamplerState s1_s : register(s1);
SamplerState s0_s : register(s0);

cbuffer cb1 : register(b1)
{
  float4 cb1[44];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[6];
}

void main(
  float4 v0 : SV_POSITION0,
  float2 v1 : TEXCOORD0,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2;
  r0.xy = v1.xy * cb0[3].xy + cb0[3].zw;
  r0.zw = r0.xy * cb0[1].xy + cb0[1].zw;
  r1.xy = cb1[43].xy * r0.xy;
  r0.x = t1.Sample(s1_s, r0.zw).w;
  r0.x = -0.5 + r0.x;
  r0.x = r0.x + r0.x;
  r0.yz = cb1[42].xy * v1.xy;
  uint2 r0yzu = (uint2)r0.yz;
  r0.yz = (float2)r0yzu;
  r2.xy = float2(-1,-1) + cb1[42].xy;
  r2.xy = cb0[3].zw * r2.xy;
  r0.yz = r0.yz * cb0[3].xy + r2.xy;
  uint4 r2u;
  r2u.xy = (uint2)r0.yz;
  r2u.zw = 0;
  r0.yzw = t0.Load(r2u.xyww).xyz;
  r1.w = t3.Load(r2u.xyzw).x;
#if 0 // Luma: removed saturate
  r0.yzw = saturate(r0.yzw);
#endif
  r2.xyz = r0.yzw * r0.xxx;
  r2.xyz = cb0[0].xxx * r2.xyz;
  r0.x = dot(r0.yzw, float3(0.212672904,0.715152204,0.0721750036)); // BT.709 luminance
  r0.x = sqrt(max(r0.x, 0));
  r0.x = cb0[0].y * -r0.x + 1;
  r0.xyz = r2.xyz * r0.xxx + r0.yzw;
  r1.z = 0;
  r2.xyzw = t2.SampleLevel(s0_s, r1.xyz, 0).xyzw;
  o0.xyz = r2.www * r0.xyz + r2.xyz;
  o0.w = (cb0[5].x == 1) ? r1.w : 1;
}