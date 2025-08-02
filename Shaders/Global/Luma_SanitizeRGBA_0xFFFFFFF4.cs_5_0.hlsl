RWTexture2D<float4> sourceTargetTexture : register(u0);

[numthreads(8,8,1)]
void main( uint3 vDispatchThreadId : SV_DispatchThreadID )
{
	const uint3 pixelPos = vDispatchThreadId;
	float4 color = sourceTargetTexture.Load(pixelPos);

    if (isnan(color.r))
      color.r = 0.0;
    if (isnan(color.g))
      color.g = 0.0;
    if (isnan(color.b))
      color.b = 0.0;
    color.a = saturate(color.a);

	sourceTargetTexture[pixelPos.xy] = color;
}