#if 1 // Luma
Texture2D<float4> t0 : register(t0); // Source color (HDR)
RWTexture2D<float4> u0 : register(u0); // Output
#else
Texture2D<unorm float4> t0 : register(t0); // Source color (SDR)
RWTexture2D<unorm float4> u0 : register(u0); // Output
#endif

[numthreads(8, 8, 1)]
void main(uint3 vThreadGroupID : SV_GroupID, uint3 vThreadIDInGroup : SV_GroupThreadID)
{
  int2 pixelCoord = (int2)vThreadGroupID.xy * int2(8,8) + (int2)vThreadIDInGroup.xy; // imad
  u0[pixelCoord] = t0.Load(int3(pixelCoord, 0)).xyzw;
}