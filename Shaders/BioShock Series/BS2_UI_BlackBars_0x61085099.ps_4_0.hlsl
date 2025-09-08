#include "Includes/Common.hlsl"

void main(
  float4 v0 : SV_Position0,
  float4 v1 : COLOR0,
  out float4 o0 : SV_Target0)
{
#if DISABLE_BLACK_BARS // TODO: does this draw anything else? Probably!!! Default to true if we can fix it, but we'd need to analyze the VS. Maybe the VS color.
  o0.xyzw = 0;
#else
  o0.xyzw = v1.xyzw;
#endif
}