RWTexture2D<float4> sourceTargetTexture : register(u0);

[numthreads(8,8,1)]
void main(uint3 vDispatchThreadId : SV_DispatchThreadID)
{
	const uint3 pixelPos = vDispatchThreadId;

	uint width, height;
	sourceTargetTexture.GetDimensions(width, height);
	if (pixelPos.x >= width || pixelPos.y >= height)
		return;

#pragma warning( disable : 3206 ) // Not sure why it's needed
	float4 color = sourceTargetTexture.Load(int3(pixelPos));
#pragma warning( default : 3206 )

	color.a = saturate(color.a);

	sourceTargetTexture[pixelPos.xy] = color;
}