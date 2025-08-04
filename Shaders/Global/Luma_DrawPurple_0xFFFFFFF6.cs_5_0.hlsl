RWTexture2D<float4> sourceTargetTexture : register(u0);

//TODO: is that even necessary?
// numthreads as 1 1 1 to make it compatible with any dispatch size
[numthreads(1,1,1)]
void main(uint3 vDispatchThreadId : SV_DispatchThreadID)
{
  const uint3 pixelPos = vDispatchThreadId;
  
  uint width, height;
  sourceTargetTexture.GetDimensions(width, height);
  if (pixelPos.x >= width || pixelPos.y >= height)
    return;
    
  sourceTargetTexture[pixelPos.xy] = float4(1, 0, 1, 1); // Purple
}