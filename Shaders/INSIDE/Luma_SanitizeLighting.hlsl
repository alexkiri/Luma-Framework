Texture2D<float4> sourceTexture : register(t0);

// INSIDE lighting was stored in log space with 0 mapping to infinitely bright, and 1 mapping to pure dark.
// Unfortunately sometimes it'd go beyond 1 when Luma upgrades from UNORM to FLOAT textures,
// and that'd produce negative colors in material drawing later on (which sampled the lighting pixel and multiplied it by their albedo etc).
// Clamping to above 0 isn't necessary as it's already done on every single sampling of this texture.
float4 main(float4 pos : SV_Position0) : SV_Target0
{
  float4 color = sourceTexture.Load(int3(pos.xy, 0));
  color = min(color, 1.0);
	return color;
}