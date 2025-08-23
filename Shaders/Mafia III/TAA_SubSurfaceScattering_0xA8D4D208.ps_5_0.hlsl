#include "Includes/Common.hlsl"

#if !defined(ENABLE_TAA_COMPOSITION)
#define ENABLE_TAA_COMPOSITION 1
#endif

Texture2D<float4> t2 : register(t2); // Encoded motion vectors
Texture2D<float4> t1 : register(t1); // Previous TAA result (smooth)
Texture2D<float4> t0 : register(t0); // Raw jittered HDR linear frame

SamplerState s1_s : register(s1);
SamplerState s0_s : register(s0);

cbuffer cb0 : register(b0)
{
  float4 cb0[11];
}

#define cmp

void main(
  float4 v0 : SV_Position0,
  float4 v1 : TEXCOORD0,
  out float4 o0 : SV_Target0)
{
#if !ENABLE_TAA_COMPOSITION
	float w, h;
	t0.GetDimensions(w, h);
  v1.xy = v0.xy / float2(w, h);
  o0 = t0.Sample(s0_s, v1.xy - jitters).xyzw;
  return;
#endif

  float4 r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12;
  r0.xyzw = t2.Sample(s0_s, v1.xy).xyzw;
  r1.xyzw = v1.xyxy + r0.xyxy;
  r0.xy = r1.zw * cb0[10].xy + float2(-0.5,-0.5);
  r0.xy = floor(r0.xy);
  r2.xyzw = float4(0.5,0.5,-0.5,-0.5) + r0.xyxy;
  r0.xy = float2(2.5,2.5) + r0.xy;
  r3.xy = cb0[10].zw * r0.xy;
  r1.xyzw = r1.xyzw * cb0[10].xyxy - r2.xyxy;
  r4.xyzw = r1.zwzw * r1.zwzw;
  r5.xyzw = r1.zwzw * float4(1.5,1.5,0.5,0.5) + float4(-2.5,-2.5,-0.5,-0.5);
  r0.xy = r4.xy * r5.xy + float2(1,1);
  r4.xy = r5.zw * r4.zw;
  r5.xyzw = -r1.zwzw * float4(0.5,0.5,1.5,1.5) + float4(1,1,2,2);
  r5.xyzw = r1.zwzw * r5.xyzw + float4(-0.5,-0.5,0.5,0.5);
  r0.xy = r1.zw * r5.zw + r0.xy;
  r1.xyzw = r5.xyzw * r1.xyzw;
  r5.xw = cb0[10].zw * r2.zw;
  r1.zw = r1.zw / r0.xy;
  r1.zw = r2.xy + r1.zw;
  r5.yz = cb0[10].wz * r1.wz;
  r2.xyz = t1.SampleLevel(s1_s, r5.zw, 0).xyz;
  r6.xyz = r2.xyz * r0.x;
  r6.xyz = r6.xyz * r1.y;
  r7.xyz = t1.SampleLevel(s1_s, r5.xw, 0).xyz;
  r8.xyz = r7.xyz * r1.x;
  r6.xyz = r8.xyz * r1.y + r6.xyz;
  r3.zw = r5.wy;
  r8.xyz = t1.SampleLevel(s1_s, r3.xz, 0).xyz;
  r9.xyz = t1.SampleLevel(s1_s, r3.xw, 0).xyz;
  r10.xyz = r8.xyz * r4.x;
  r1.yzw = r10.xyz * r1.y + r6.xyz;
  r6.xyz = t1.SampleLevel(s1_s, r5.xy, 0).xyz;
  r10.xyz = t1.SampleLevel(s1_s, r5.zy, 0).xyz;
  r11.xyz = r6.xyz * r1.x;
  r1.yzw = r11.xyz * r0.y + r1.yzw;
  r11.xyz = r10.xyz * r0.x;
  r1.yzw = r11.xyz * r0.y + r1.yzw;
  r11.xyz = r9.xyz * r4.x;
  r1.yzw = r11.xyz * r0.y + r1.yzw;
  r5.y = r3.y;
  r3.xyz = t1.SampleLevel(s1_s, r3.xy, 0).xyz;
  r11.xyz = t1.SampleLevel(s1_s, r5.xy, 0).xyz;
  r5.xyz = t1.SampleLevel(s1_s, r5.zy, 0).xyz;
  r12.xyz = r11.xyz * r1.x;
  r1.xyz = r12.xyz * r4.y + r1.yzw;
  r12.xyz = r5.xyz * r0.x;
  r1.xyz = r12.xyz * r4.y + r1.xyz;
  r4.xzw = r3.xyz * r4.x;
  r1.xyz = r4.xzw * r4.y + r1.xyz;
  r4.xyz = min(r7.xyz, r2.xyz);
  r2.xyz = max(r7.xyz, r2.xyz);
  r2.xyz = max(r2.xyz, r8.xyz);
  r4.xyz = min(r4.xyz, r8.xyz);
  r7.xyz = min(r10.xyz, r6.xyz);
  r6.xyz = max(r10.xyz, r6.xyz);
  r6.xyz = max(r6.xyz, r9.xyz);
  r7.xyz = min(r7.xyz, r9.xyz);
  r4.xyz = min(r7.xyz, r4.xyz);
  r2.xyz = max(r6.xyz, r2.xyz);
  r6.xyz = min(r11.xyz, r5.xyz);
  r5.xyz = max(r11.xyz, r5.xyz);
  r5.xyz = max(r5.xyz, r3.xyz);
  r3.xyz = min(r6.xyz, r3.xyz);
  r3.xyz = min(r4.xyz, r3.xyz);
  r1.xyz = max(r3.xyz, r1.xyz);
  r2.xyz = max(r5.xyz, r2.xyz);
  r1.xyz = min(r2.xyz, r1.xyz);
  r1.xyz = min(65504.0, r1.xyz);
  r2.xyz = t0.SampleLevel(s0_s, v1.xy, 0, int2(-1, 0)).xyz;
  r3.xyz = r2.xyz * r2.xyz;
  r4.xyz = t0.Sample(s0_s, v1.xy).xyz;
  r4.xyz = min(65504.0, r4.xyz);
  r3.xyz = r4.xyz * r4.xyz + r3.xyz;
  r5.xyz = t0.SampleLevel(s0_s, v1.xy, 0, int2(1, 0)).xyz;
  r3.xyz = r5.xyz * r5.xyz + r3.xyz;
  r6.xyz = t0.SampleLevel(s0_s, v1.xy, 0, int2(0, -1)).xyz;
  r3.xyz = r6.xyz * r6.xyz + r3.xyz;
  r7.xyz = t0.SampleLevel(s0_s, v1.xy, 0, int2(0, 1)).xyz;
  r3.xyz = r7.xyz * r7.xyz + r3.xyz;
  r2.xyz = r4.xyz + r2.xyz;
  r2.xyz = r2.xyz + r5.xyz;
  r2.xyz = r2.xyz + r6.xyz;
  r2.xyz = r2.xyz + r7.xyz;
  r5.xyz = 0.2 * r2.xyz;
  r5.xyz = sqrt(r5.xyz);
  r3.xyz = r3.xyz * 0.2 - r5.xyz;
  r3.xyz = sqrt(abs(r3.xyz)); // TODO abs*sign? Also preserve the sign in the squares above (do the same for all TAA shaders, though there's a billion of them!)
  r5.xyz = r2.xyz * 0.2 - r3.xyz;
  r2.xyz = r2.xyz * 0.2 + r3.xyz;
  r3.xyz = r5.xyz + r2.xyz;
  r2.xyz = r2.xyz - r5.xyz;
  r2.xyz = 0.5 * r2.xyz;
  r5.xyz = r1.xyz - r3.xyz * 0.5;
  r6.xyz = max(9.99999975e-006, r2.xyz);
  r5.xyz = r5.xyz / r6.xyz;
  r2.xyz = r5.xyz * r2.xyz;
  r0.x = max(abs(r5.y), abs(r5.z));
  r0.x = max(abs(r5.x), r0.x);
  r2.xyz = r2.xyz / r0.x;
  r0.x = cmp(1 < r0.x);
  r2.xyz = r3.xyz * 0.5 + r2.xyz;
  r1.xyz = r0.x ? r2.xyz : r1.xyz;
  r0.x = r0.w * 0.25 + 0.75;
  r0.x = r0.z * r0.x;
  r0.y = 0.625 * r0.x;
  r0.x = 1.0 - r0.x * 0.625;
  r0.yzw = r1.xyz * r0.y;
  o0.xyz = r4.xyz * r0.x + r0.yzw;
  o0.w = 1;
}