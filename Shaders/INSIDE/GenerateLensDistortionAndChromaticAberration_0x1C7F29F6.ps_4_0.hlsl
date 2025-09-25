cbuffer cb0 : register(b0)
{
  float4 cb0[10];
}

#define cmp -

void main(
  float4 v0 : SV_POSITION0,
  float2 v1 : TEXCOORD0,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1;
  r0.xy = v1.xy * float2(2,2) + float2(-1,-1);
  r0.xy = cb0[8].xy * r0.xy;
  r0.zw = r0.xy * float2(0.5,0.5) + float2(0.5,0.5);
  r0.xy = float2(0.5,0.5) * r0.xy;
  r0.xy = cb0[9].xy * r0.xy;
  r0.xy = r0.xy + r0.xy;
  r0.zw = r0.zw * float2(2,2) + float2(-1,-1);
  r0.zw = cb0[7].zz * r0.zw;
  r1.x = dot(r0.zw, r0.zw);
  r1.x = sqrt(r1.x);
  r1.x = max(9.99999997e-007, r1.x);
  r1.x = log2(r1.x);
  r1.y = 5 * cb0[7].x;
  r1.x = r1.y * r1.x;
  r1.x = exp2(r1.x);
  r0.zw = r1.xx * r0.zw;
  r0.zw = cb0[7].yy * r0.zw;
  r0.zw = r0.zw * float2(0.5,0.5) + float2(0.5,0.5);
  r0.zw = -v1.xy + r0.zw;
  r0.zw = float2(0.0117647061,0.0117647061) + r0.zw;
  o0.xy = saturate(float2(42.5,42.5) * r0.zw);
  r0.z = dot(r0.xy, r0.xy);
  r0.z = sqrt(r0.z);
  r0.z = max(9.99999997e-007, r0.z);
  r0.xy = r0.xy / r0.zz;
  r0.z = log2(r0.z);
  r0.z = cb0[6].y * r0.z;
  r0.z = exp2(r0.z);
  r0.xy = r0.zz * r0.xy + float2(0.00588235306,0.00588235306);
  o0.zw = saturate(float2(85,85) * r0.xy);
}