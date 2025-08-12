RWTexture2D<float4> sourceTargetTexture : register(u0);

//TODO: is that even necessary?
// numthreads as 1 1 1 to make it compatible with any dispatch size
[numthreads(1,1,1)]
void main(uint3 vDispatchThreadId : SV_DispatchThreadID)
{
  const int3 pixelPos = int3(vDispatchThreadId);
  
  uint width, height;
  sourceTargetTexture.GetDimensions(width, height);
  if (pixelPos.x >= (int)width || pixelPos.y >= (int)height)
    return;
    
  sourceTargetTexture[uint2(pixelPos.xy)] = float4(1, 0, 1, 1); // Purple
}