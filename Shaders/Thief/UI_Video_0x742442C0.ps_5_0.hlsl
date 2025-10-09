#include "../Includes/Common.hlsl"

Texture2D<float4> t3 : register(t3);
Texture2D<float4> t2 : register(t2);
Texture2D<float4> t1 : register(t1);
Texture2D<float4> t0 : register(t0);

SamplerState s3_s : register(s3);
SamplerState s2_s : register(s2);
SamplerState s1_s : register(s1);
SamplerState s0_s : register(s0);

float3 YUVtoRGB(float Y, float Cr, float Cb, uint type = 0)
{
  float V = Cr;
  float U = Cb;

	float3 color = 0.0;
	// usually in YCbCr the ranges are (in float):
	// Y:   0.0-1.0
	// Cb: -0.5-0.5
	// Cr: -0.5-0.5
	// but since this is a digital signal (in unsinged 8bit: 0-255) it's now:
	// Y:  0.0-1.0
	// Cb: 0.0-1.0
	// Cr: 0.0-1.0
  if (type == 0) { // Rec.709 full range
    color.r = (Y - 0.790487825870513916015625f) + (Cr * 1.5748f);
    color.g = (Y + 0.329009473323822021484375f) - (Cr * 0.46812427043914794921875f) - (Cb * 0.18732427060604095458984375f);
    color.b = (Y - 0.931438446044921875f)       + (Cb * 1.8556f);
  } else if (type == 1) { // Rec.709 limited range
    Y *= 1.16438353f;
    color.r = (Y - 0.972945094f) + (Cr * 1.79274106f);
    color.g = (Y + 0.301482677f) - (Cr * 0.532909333f) - (Cb * 0.213248610f);
    color.b = (Y - 1.13340222f)  + (Cb * 2.11240172f);
  } else if (type == 2) { // Rec.601 full range
    color += Cr * float3(1.59579468, -0.813476563, 0.0); 
    color += Y * 1.16412354;
    color += Cb * float3(0,-0.391448975, 2.01782227);
    color += float3(-0.87065506, 0.529705048, -1.08166885); // Bias offsets
    color = color * 0.858823538 + 0.0627451017; // limited to full range
  } else { // Rec.601 limited range
    Y *= 1.16412353515625f;
    color.r = (Y - 0.870655059814453125f) + (Cr * 1.595794677734375f);
    color.g = (Y + 0.529705047607421875f) - (Cr * 0.8134765625f) - (Cb * 0.391448974609375f);
    color.b = (Y - 1.081668853759765625f) + (Cb * 2.017822265625f);
  }

  return color;
}

void main(
  float4 v0 : COLOR1,
  float2 v1 : TEXCOORD0,
  out float4 o0 : SV_Target0)
{
  float4 r0;
  r0.x = t2.Sample(s3_s, v1.xy).x;
  r0.x = -0.501960814 + r0.x;
  r0.xyz = float3(1.59599996,-0.813000023,0) * r0.xxx;
  r0.w = t0.Sample(s0_s, v1.xy).x;
  r0.w = -0.0627451017 + r0.w;
  r0.xyz = r0.www * float3(1.16400003,1.16400003,1.16400003) + r0.xyz;
  r0.w = t1.Sample(s1_s, v1.xy).x;
  r0.w = -0.501960814 + r0.w;
  o0.xyz = r0.www * float3(0,-0.39199999,2.01699996) + r0.xyz;

  r0.x = t3.Sample(s2_s, v1.xy).x;
  o0.w = v0.w * r0.x;

  float Y = t0.Sample(s0_s, v1.xy).x;
  float Cr = t2.Sample(s1_s, v1.xy).x;
  float Cb = t1.Sample(s3_s, v1.xy).x;

  // TODO: properly decode videos, and add AutoHDR
  o0.rgb = YUVtoRGB(Y, Cr, Cb, 1);
}