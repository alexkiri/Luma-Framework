cbuffer Global : register(b0)
{
  float4 EnvironmentLuminances : packoffset(c0);
  float4 FakeEarthShadowPlane : packoffset(c1);
  float4 GlobalLightsIntensity : packoffset(c2);
  float4 GlobalWeatherControl : packoffset(c3);
  float4 MaterialWetnessParams[22] : packoffset(c4);
  float4 WindGlobalTurbulence : packoffset(c26);
  float4 WindVelocityTextureCoverage : packoffset(c27);
  float4 WorldLoadingRingSizes[2] : packoffset(c28);

  struct
  {
    float debugValue0;
    float debugValue1;
    float debugValue2;
    float debugValue3;
  } DebugValues : packoffset(c30);

  float3 SunShadowDirection : packoffset(c31);
  float CrowdAnimationStartTime : packoffset(c31.w);
  float3 WindGlobalNoiseTextureChannelSel : packoffset(c32);
  float GlobalReflectionTextureBlendRatio : packoffset(c32.w);
  float3 WindGlobalNoiseTextureCoverage : packoffset(c33);
  float GlobalWaterLevel : packoffset(c33.w);

  struct
  {
    float time;
    float staticReflectionIntensity;
    float gameDeltaTime;
  } GlobalScalars : packoffset(c34);

  float RcpStaticReflectionExposureScale : packoffset(c34.w);
  float2 GlobalNoiseSampler2DSquareSize : packoffset(c35);
  float SandstormIntensity : packoffset(c35.z);
  float StaticReflectionIntensityDest : packoffset(c35.w);
  float2 WindNoiseDeltaVector : packoffset(c36);
  float TimeOfDay : packoffset(c36.z);
  float VertexAOIntensity : packoffset(c36.w);
  float2 WindVector : packoffset(c37);
}

cbuffer Viewport : register(b1)
{
  float4 CameraNearPlaneSize : packoffset(c0);
  float4x4 DepthTextureTransform : packoffset(c1);
  float4 FSMClipPlanes : packoffset(c5);
  float4 FacettedShadowCastParams : packoffset(c6);
  float4 FogValues0 : packoffset(c7);
  float4 FogValues1 : packoffset(c8);
  float4x4 InvProjectionMatrix : packoffset(c9);
  float4x4 InvProjectionMatrixDepth : packoffset(c13);
  float4x3 InvViewMatrix : packoffset(c17);
  float4x4 PreviousViewProjectionMatrix : packoffset(c20);
  float4x4 ProjectionMatrix : packoffset(c24);
  float4 RainOcclusionFadeParams : packoffset(c28);
  float4x4 RainOcclusionProjectionMatrix : packoffset(c29);
  float4 RainOcclusionShadowMapSize : packoffset(c33);
  float4 ReflectionVolumeDebugColors[15] : packoffset(c34);
  float4 VPosOffset : packoffset(c49);
  float4 VPosScale : packoffset(c50);
  float4x3 ViewMatrix : packoffset(c51);
  float4x4 ViewProjectionMatrix : packoffset(c54);
  float4x4 ViewRotProjectionMatrix : packoffset(c58);
  float4x4 ViewRotProjectionMatrixPure : packoffset(c62);
  float4 ViewportSize : packoffset(c66);

  struct
  {
    float near;
    float far;
    float view;
    float oneOverView;
  } CameraDistances : packoffset(c67);


  struct
  {
    float4x4 inverseTransform;
    float3 rcpFadeRangePositive;
    float textureArrayIndexAsFloat;
    float3 rcpFadeRangeNegative;
    float fadeFactor;
    float2 multipliers;
    uint parallaxCorrection;
    float padding0;
  } ReflectionVolumes[15] : packoffset(c68);

  float3 CameraDirection : packoffset(c173);
  float DefaultReflectionTextureArrayIndexAsFloat : packoffset(c173.w);
  float3 CameraPosition : packoffset(c174);
  float DynamicCubeMapReflectionTextureMaxMipIndex : packoffset(c174.w);
  float3 CullingCameraPosition : packoffset(c175);
  float ExposedWhitePointOverExposureScale : packoffset(c175.w);
  float3 FogColorVector : packoffset(c176);
  float ExposureScale : packoffset(c176.w);
  float3 OppositeFogColorDelta : packoffset(c177);
  float MaxParaboloidReflectionMipIndex : packoffset(c177.w);
  float3 SideFogColor : packoffset(c178);
  float MaxStaticReflectionMipIndex : packoffset(c178.w);
  float3 SunFogColorDelta : packoffset(c179);
  float MeasuredExposureScale : packoffset(c179.w);
  float3 TemporalFilteringParams : packoffset(c180);
  float RaindropRippleScale : packoffset(c180.w);
  float3 UncompressDepthWeights : packoffset(c181);
  float ReflectionScaleDistanceMul : packoffset(c181.w);
  float3 UncompressDepthWeightsWS : packoffset(c182);
  float ReflectionScaleStrength : packoffset(c182.w);
  float3 ViewPoint : packoffset(c183);
  float SkyParaboloidTextureMaxMipIndex : packoffset(c183.w);
  float2 DefaultReflectionMultipliers : packoffset(c184);
  bool UseOnlySkyReflection : packoffset(c184.z);
  float2 ReflectionGIControl : packoffset(c185);
  uint2 SelectedPixel : packoffset(c185.z);
}

cbuffer HDREffects : register(b2)
{
  float4 AdditionalBlurParams : packoffset(c0);
  float4 BokehParams : packoffset(c1);
  float4 CoCComputation : packoffset(c2);
  float4 DirectionalBlurUVScaleBias : packoffset(c3);
  float4 SourceSize : packoffset(c4);
  float2 BokehContrast : packoffset(c5);
  float CoCTexelBlurRange : packoffset(c5.z);
  float2 CoCRange : packoffset(c6);
}

cbuffer HDRLighting : register(b3)
{
  float4 AdaptationState : packoffset(c0);
  float4 ExpositionParams : packoffset(c1);
  float4 LensParams1 : packoffset(c2);
  float4 LensParams2 : packoffset(c3);
  float4 UIParams : packoffset(c4);
  float4 ViewportResolution : packoffset(c5);
  float3 CameraXAxis : packoffset(c6);
  float ChromaticAberationStrength : packoffset(c6.w);
  float3 CameraYAxis : packoffset(c7);
  float DistoritionKCube : packoffset(c7.w);
  float3 CameraZAxis : packoffset(c8);
  float DistoritionKCylindrical : packoffset(c8.w);
  float3 MPEGArtefactColorProbability : packoffset(c9);
  float FilmGrainIntensity : packoffset(c9.w);
  float2 ProjectionOffset : packoffset(c10);
  float FilmGrainVignetingRelation : packoffset(c10.z);
  float MPEGArtefactArtefactBlockShift : packoffset(c10.w);
  float MPEGArtefactBlocksPerLargeBlock : packoffset(c11);
  float MPEGArtefactBlockyFactor : packoffset(c11.y);
  float MPEGArtefactBlockyFactorBlend : packoffset(c11.z);
  float MPEGArtefactLineProbability : packoffset(c11.w);
  float MPEGArtefactSmallBlockSize : packoffset(c12);
  float MPEGArtefactSquareProbability : packoffset(c12.y);
  float MPEGArtefactTimeScale : packoffset(c12.z);
  float ProjectionScaleInv : packoffset(c12.w);
}

SamplerState ColorClamp_s : register(s0);
SamplerState ColorClamp2D_s : register(s1);
SamplerState ColorWrap_s : register(s2);
SamplerState HDRLighting__LensDirtTexture__SampObj___s : register(s3);
Texture2D<float4> Global__GlobalNoiseSampler2D__TexObj__ : register(t0);
Texture2D<float4> HDREffects__ColorAndMaskTexture__TexObj__ : register(t1); // DoF
Texture2DMS<float> HDREffects__DepthTextureMS : register(t2);
Texture2D<float4> HDRLighting__BloomMap__TexObj__ : register(t3);
Texture2D<float4> HDRLighting__Frame__TexObj__ : register(t4); // Scene
Texture2D<float4> HDRLighting__LensDirtBloomSource__TexObj__ : register(t5);
Texture2D<float4> HDRLighting__LensDirtTexture__TexObj__ : register(t6);
Texture2D<float4> HDRLighting__PostFxMaskTexture__TexObj__ : register(t7);
Texture3D<float4> HDRLighting__ColorRemapHDRTexture : register(t8);

#define cmp -

void main(
  linear centroid float2 v0 : TEXCOORD0,
  float4 v1 : SV_Position0,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3,r4;
  r0.zw = float2(0,0);
  r1.xyz = (int3)v1.yxy;
  r1.x = (int)r1.x & 1;
  r2.x = (int)r1.x ^ 1;
  r1.x = (int)r1.x;
  r1.x = ViewportSize.z * r1.x;
  r3.z = 0.5 * r1.x;
  r4.xyzw = v0.xyxy * float4(0.5,-0.5,0.5,-0.5) + float4(0.5,0.5,0.5,0);
  r2.yz = ViewportSize.xy * r4.xy;
  r2.yz = float2(1,0.5) * r2.yz;
  r0.xy = (int2)r2.yz;
  r3.x = HDREffects__DepthTextureMS.Load(r0.xy, r2.x).x;
  r3.yw = float2(1,0.5);
  r0.x = dot(r3.xy, InvProjectionMatrixDepth._m22_m32);
  r0.y = dot(r3.xy, InvProjectionMatrixDepth._m23_m33);
  r0.zw = r4.zw + r3.zw;
  r0.x = -r0.x / r0.y;
  r0.x = r0.x * CoCComputation.x + CoCComputation.y;
  r0.x = CoCComputation.z / r0.x;
  r0.x = CoCComputation.w + r0.x;
  r0.x = CoCTexelBlurRange * r0.x;
  r0.x = max(CoCRange.x, r0.x);
  r0.x = min(CoCRange.y, r0.x);
  r0.x = r0.x * r0.x;
  r0.x = saturate(r0.x * BokehParams.z + -0.5);
  r2.xyzw = HDREffects__ColorAndMaskTexture__TexObj__.Sample(ColorClamp_s, r0.zw).xyzw;
  r0.x = max(r2.w, r0.x);
  r0.x = min(1, r0.x);
  r3.xyz = HDRLighting__Frame__TexObj__.Sample(ColorWrap_s, r4.xy).xyz;
  r4.xyzw = HDRLighting__LensDirtBloomSource__TexObj__.Sample(ColorClamp_s, r4.xy).xyzw;

  r2.xyz = -r3.xyz + r2.xyz;
  r2.xyz = r0.x * r2.xyz + r3.xyz;
  //r2.xyz = lerp(r3.xyz, r2.xyz, r0.x);

  r3.xyzw = HDRLighting__BloomMap__TexObj__.Sample(ColorClamp_s, r0.zw).xyzw;
  r0.xyz = HDRLighting__LensDirtTexture__TexObj__.Sample(HDRLighting__LensDirtTexture__SampObj___s, r0.zw).xyz;
  r0.xyz = LensParams1.x * r0.xyz;
  r3.xyz = max(0.0, r3.xyz);
  r0.w = 1 + r3.w;
  r2.xyz = r3.xyz + r2.xyz;
  r2.xyz = r2.xyz / r0.www;
  r0.w = 1 + r4.w;
  r3.xyz = r4.xyz / r0.www;
  r3.xyz = max(0.0, r3.xyz);
  r0.xyz = r3.xyz * r0.xyz + r2.xyz;
  r0.xyz = log2(abs(r0.xyz));
  
  // Tonemapping LUT (not just for grading)
  r0.xyz = saturate(r0.xyz * float3(0.0632478595,0.0632478595,0.0632478595) + float3(0.690302372,0.690302372,0.690302372));
  r0.xyz = r0.xyz * float3(0.96875,0.96875,0.96875) + float3(0.015625,0.015625,0.015625); // 32x LUT
  r0.xyz = HDRLighting__ColorRemapHDRTexture.SampleLevel(ColorClamp2D_s, r0.xyz, 0).xyz;

  r0.w = LensParams2.w * LensParams1.w;
  r2.y = TemporalFilteringParams.y * r0.w;
  r2.x = 1;
  r2.xy = v0.xy * r2.xy;
  r0.w = dot(r2.xy, r2.xy);
  r0.w = sqrt(r0.w);
  r0.w = -LensParams2.x + r0.w;
  r0.w = r0.w / LensParams2.y;
  r0.w = saturate(0.5 + r0.w);
  r1.x = r0.w * r0.w;
  r0.w = dot(r0.ww, r1.xx);
  r0.w = r1.x * 3 + -r0.w;
  r0.w = -r0.w * LensParams2.z + 1;
  r0.xyz = r0.xyz * r0.www;
  r2.xyz = log2(abs(r0.xyz));
  r2.xyz = float3(0.416666657,0.416666657,0.416666657) * r2.xyz;
  r2.xyz = exp2(r2.xyz);
  r2.xyz = r2.xyz * float3(1.05499995,1.05499995,1.05499995) + float3(-0.0549999997,-0.0549999997,-0.0549999997);
  r3.xyz = cmp(float3(0.00313080009,0.00313080009,0.00313080009) >= r0.xyz);
  r0.xyz = float3(12.9200001,12.9200001,12.9200001) * r0.xyz;
  r0.xyz = r3.xyz ? r0.xyz : r2.xyz;
  r2.xy = GlobalNoiseSampler2DSquareSize.yy * v1.xy;
  r2.xy = frac(r2.xy);
  r2.xy = GlobalNoiseSampler2DSquareSize.xx * r2.xy;
  r2.xy = (int2)r2.xy;
  r2.zw = float2(0,0);
  r2.xyz = Global__GlobalNoiseSampler2D__TexObj__.Load(r2.xyz).xyz;
  r2.xyz = float3(-0.5,-0.5,-0.5) + r2.xyz;
  r0.xyz = r2.xyz * float3(0.00392156886,0.00392156886,0.00392156886) + r0.xyz;
  r2.xyz = float3(0.0549999997,0.0549999997,0.0549999997) + r0.xyz;
  r2.xyz = float3(0.947867334,0.947867334,0.947867334) * r2.xyz;
  r2.xyz = log2(abs(r2.xyz));
  r2.xyz = 2.4 * r2.xyz; // Gamma to linear
  r2.xyz = exp2(r2.xyz);
  r3.xyz = cmp(float3(0.0404499993,0.0404499993,0.0404499993) >= r0.xyz);
  r0.xyz = float3(0.0773993805,0.0773993805,0.0773993805) * r0.xyz;
  o0.xyz = r3.xyz ? r0.xyz : r2.xyz;
  r1.w = 0;
  r0.x = HDRLighting__PostFxMaskTexture__TexObj__.Load(r1.yzw).w;
  o0.w = 1 - r0.x;
}