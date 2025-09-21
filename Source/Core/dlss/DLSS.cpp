#include "DLSS.h"

#if ENABLE_NGX

#include "../NGX/nvsdk_ngx_helpers.h"

#include <cstring>
#include <cassert>
#include <unordered_set>
#include <wrl/client.h>
#include <d3d11.h>

// Should be <= the max (last) of NVSDK_NGX_PerfQuality_Value
#define NUM_PERF_QUALITY_MODES 6

// 0.5 should be about the neutral (balanced) value? Though Nvidia's documentation doesn't specify which one is (likely 0.35).
// A value of 0 actually seems to tell DLSS that we want its default value, but again the documentation doesn't specify it. We could also try to set it -1 to make sure it's ignored though.
// As of DLSS 2.5.1 sharpness has been completely removed so it might have no effect.
#define DLSS_DEFAULT_SHARPNESS 0.5f

// Our rendering presets are pretty much the default ones mentioned in the DLSS 3.7 SDK, do we want to force them, or do we want to allow NV to change them through updates?
// If we don't force them, DLSS seems to bug out and keep the old ones after changing between DLSS and DRS the first time.
// NOTE: as of DLSS 3.8 presets are forced to E and F so none of this matters anymore. We can assume that C and D have no worthy advantages over E and F. Leaving the presets at default is the best option.
#define DLSS_FORCE_RENDER_PRESET 1
// DLSS 4 might already force this, but we can force it ourselves too (though it'd break old DLSS versions). Newer versions already added a new preset so using the default one just seems like a better choice.
// Note that this has a lot of ghosting and warping on reflections and volumetrics (anything that doesn't match the depth buffer).
#if GAME_MAFIA_III && DEVELOPMENT // Just for development, to have extra sharpness and notice if it's not etc // TODO: delete!
#define DLSS_FORCE_K_J_RENDER_PRESET 1
#else
#define DLSS_FORCE_K_J_RENDER_PRESET 0
#endif
// Theoretically better than F.
// Better sharpness, less ghosting and more image stability (less shimmering and noise).
#define DLSS_FORCE_E_RENDER_PRESET 1
// Low ghosting at the cost of a tiny bit of sharpness. Works at any quality mode.
#define DLSS_FORCE_F_RENDER_PRESET 1

namespace NGX
{
	const char* projectID = "d8238c51-1f2f-438d-a309-38c16e33c716"; // This needs to be a GUID. We generated a unique one. This isn't registered by NV. This was generated for Luma.
	const char* engineVersion = "1.0";

	// DLSS "instance" per output resolution (and other settings)
	// These never need to be manually destroyed
	struct DLSSInternalInstance
	{
		NVSDK_NGX_Handle* superSamplingFeature = nullptr;
		NVSDK_NGX_Parameter* runtimeParams = nullptr;
		Microsoft::WRL::ComPtr<ID3D11DeviceContext>	commandList;
	};

	struct DLSSInstanceData
	{
		bool							isSupported = false;
		unsigned int				renderWidth = 0;
		unsigned int				renderHeight = 0;
		unsigned int				outputWidth = 0;
		unsigned int				outputHeight = 0;
		bool							dynamicResolution = false;
		bool							hdr = false;
		float							sharpness = DLSS_DEFAULT_SHARPNESS; // Optimal value

		DLSSInternalInstance			instance = {}; // Note that there could be more of these if we ever wished
		std::unordered_set<NVSDK_NGX_Handle*>		uniqueHandles;
		std::unordered_set<NVSDK_NGX_Parameter*>	uniqueParameters;
		// Current global capabilities params (independent from the current settings/res).
		NVSDK_NGX_Parameter*			capabilitiesParams = nullptr;
		Microsoft::WRL::ComPtr<ID3D11Device>	device;

		virtual ~DLSSInstanceData()
		{
			// Just to be explicit
			device.Reset();
			instance.commandList.Reset();

			// We need to release these at the end, otherwise DLSS crashes as it holds references to them (there's probably a way to release them as they come but it doesn't really matter)
			for (NVSDK_NGX_Handle* handle : uniqueHandles)
			{
				if (handle != nullptr)
				{
					assert(NVSDK_NGX_SUCCEED(NVSDK_NGX_D3D11_ReleaseFeature(handle)));
				}
			}
			for (NVSDK_NGX_Parameter* parameter : uniqueParameters)
			{
				if (parameter != nullptr)
				{
					assert(NVSDK_NGX_SUCCEED(NVSDK_NGX_D3D11_DestroyParameters(parameter)));
				}
			}

			if (capabilitiesParams != nullptr)
			{
				assert(NVSDK_NGX_SUCCEED(NVSDK_NGX_D3D11_DestroyParameters(capabilitiesParams)));
			}
		}

		DLSSInternalInstance CreateSuperSamplingFeature(ID3D11DeviceContext* commandList, unsigned int outputWidth, unsigned int outputHeight, unsigned int renderWidth, unsigned int renderHeight, int qualityValue, bool _hdr = true)
		{
			NVSDK_NGX_Parameter* runtimeParams = nullptr;
			// Note: this could fail on outdated drivers
			NVSDK_NGX_Result paramResult = NVSDK_NGX_D3D11_AllocateParameters(&runtimeParams);
			assert(NVSDK_NGX_SUCCEED(paramResult));
			if (NVSDK_NGX_FAILED(paramResult))
			{
				return DLSSInternalInstance();
			}

			NVSDK_NGX_Handle* feature = nullptr;

			int createFlags = 
				// Always needed unless MVs are in output (upscaled) resolution
				NVSDK_NGX_DLSS_Feature_Flags_MVLowRes
				//| NVSDK_NGX_DLSS_Feature_Flags_Reserved_0 // Matches the old NVSDK_NGX_DLSS_Feature_Flags_DepthJittered, which has been removed (should already be on by default now)
//TODOFT: expose settings per game (there's more around the file), when the need will come
#if GAME_PREY || GAME_FF7_REMAKE || GAME_MAFIA_III // DLSS expects the depth to be the device/HW one (1 being near, not 1 being the camera (linear depth)), CryEngine (Prey) and other games use inverted depth because it's better for quality
				| NVSDK_NGX_DLSS_Feature_Flags_DepthInverted
#endif
// We modified Prey to make sure this is the case (see "FORCE_MOTION_VECTORS_JITTERED").
// Previously (dynamic objects) MVs were half jittered (with the current frame's jitters only), because they are rendered with g-buffers, on projection matrices that have jitters.
// We could't remove these jitters properly when rendering the final motion vectors for DLSS (we tried...), so neither this flag on or off would have been correct.
// Even if we managed to generate the final MVs without jitters included, it seemengly doesn't look any better anyway.
#if GAME_PREY || GAME_MAFIA_III
				| NVSDK_NGX_DLSS_Feature_Flags_MVJittered
#endif
#if 0
				| NVSDK_NGX_DLSS_Feature_Flags_DoSharpening // Sharpening is currently deprecated (in DLSS 2.5.1 and doesn't do anything), this would re-enable it if it was ever re-allowed by DLSS
#endif
#if GAME_FF7_REMAKE || GAME_MAFIA_III // We either force the exposure to 1 if we run after tonemapping, or feed the correct one if we run before
				| NVSDK_NGX_DLSS_Feature_Flags_AutoExposure
#endif
				;

			const NVSDK_NGX_PerfQuality_Value perfQualityValue = static_cast<NVSDK_NGX_PerfQuality_Value>(qualityValue);

			// DLAA might have been "NVSDK_NGX_PerfQuality_Value_UltraQuality" or "NVSDK_NGX_PerfQuality_Value_MaxQuality" but it shouldn't matter, it's about whether the in/out res are matching.
			// NOTE: we might also want to check against the closest "DLSSOptimalSettingsInfo" for its "MaxWidth" and "MaxHeight"
			// to check if we are actually running DLAA or DLSS? It's probably unnecessary.
			const bool isDLAA = perfQualityValue == NVSDK_NGX_PerfQuality_Value::NVSDK_NGX_PerfQuality_Value_DLAA || (renderWidth >= outputWidth && renderHeight >= outputHeight);

			NVSDK_NGX_DLSS_Hint_Render_Preset renderPreset = NVSDK_NGX_DLSS_Hint_Render_Preset_Default;
#if DLSS_FORCE_RENDER_PRESET

#if DLSS_FORCE_K_J_RENDER_PRESET

			renderPreset = NVSDK_NGX_DLSS_Hint_Render_Preset((int)NVSDK_NGX_DLSS_Hint_Render_Preset_K);

#else // !DLSS_FORCE_K_J_RENDER_PRESET

#if DLSS_FORCE_E_RENDER_PRESET
			renderPreset = NVSDK_NGX_DLSS_Hint_Render_Preset_E;

#if DLSS_FORCE_F_RENDER_PRESET // && DLSS_FORCE_F_RENDER_PRESET
			if (isDLAA)
			{
				renderPreset = NVSDK_NGX_DLSS_Hint_Render_Preset_F;
			}
#endif // DLSS_FORCE_F_RENDER_PRESET

#elif DLSS_FORCE_F_RENDER_PRESET // && !DLSS_FORCE_E_RENDER_PRESET

			renderPreset = NVSDK_NGX_DLSS_Hint_Render_Preset_F;

#else // Automatically pick the best one if no specific one is forced

			switch (perfQualityValue)
			{
			case NVSDK_NGX_PerfQuality_Value_UltraPerformance:
			{
				// F: The default preset for Ultra Perf and DLAA modes.
				// 
				// NOTE: we could actually just use "NVSDK_NGX_DLSS_Hint_Render_Preset_Default" here, as it would internally fall back to "F",
				// but allow for automatic changes from NV in future versions of DLSS?
				renderPreset = NVSDK_NGX_DLSS_Hint_Render_Preset_F;
			}
			break;
			default:
			{
				// C: Preset which generally favors current frame information. Generally well-suited for fast paced game content.
				// For First Person games, it might be better than E.
				renderPreset = NVSDK_NGX_DLSS_Hint_Render_Preset_C;
			}
			break;
			}
			if (isDLAA)
			{
				renderPreset = NVSDK_NGX_DLSS_Hint_Render_Preset_F;
			}

#endif // DLSS_FORCE_E_RENDER_PRESET

#endif // DLSS_FORCE_K_J_RENDER_PRESET

#endif // DLSS_FORCE_RENDER_PRESET

			// Set all of them for simplicity, these params belong to a specific quality mode anyway.
			// If we set "NVSDK_NGX_DLSS_Hint_Render_Preset_Default", it should be equal to not setting anything at all.
			NVSDK_NGX_Parameter_SetUI(runtimeParams, NVSDK_NGX_Parameter_DLSS_Hint_Render_Preset_DLAA, renderPreset);
			NVSDK_NGX_Parameter_SetUI(runtimeParams, NVSDK_NGX_Parameter_DLSS_Hint_Render_Preset_UltraQuality, renderPreset);
			NVSDK_NGX_Parameter_SetUI(runtimeParams, NVSDK_NGX_Parameter_DLSS_Hint_Render_Preset_Quality, renderPreset);
			NVSDK_NGX_Parameter_SetUI(runtimeParams, NVSDK_NGX_Parameter_DLSS_Hint_Render_Preset_Balanced, renderPreset);
			NVSDK_NGX_Parameter_SetUI(runtimeParams, NVSDK_NGX_Parameter_DLSS_Hint_Render_Preset_Performance, renderPreset);
			NVSDK_NGX_Parameter_SetUI(runtimeParams, NVSDK_NGX_Parameter_DLSS_Hint_Render_Preset_UltraPerformance, renderPreset);

			// With this flag on, DLSS process colors "better",
			// and it expects them to be in linear space.
			// If this flag is false, then colors should be in gamma space (values beyond 0-1 are allowed anyway).
			if (_hdr)
			{
				createFlags |= NVSDK_NGX_DLSS_Feature_Flags_IsHDR;
			}

			NVSDK_NGX_DLSS_Create_Params CreateParams;
			std::memset(&CreateParams, 0, sizeof(CreateParams));

			CreateParams.Feature.InTargetWidth = outputWidth;
			CreateParams.Feature.InTargetHeight = outputHeight;
			CreateParams.Feature.InWidth = renderWidth;
			CreateParams.Feature.InHeight = renderHeight;
			// The quality value here is optional and likely irrelevant, as we already specify the input and output resolution (that's why we don't hash it in the map key).
			CreateParams.Feature.InPerfQualityValue = perfQualityValue;
			CreateParams.InFeatureCreateFlags = createFlags;

			NVSDK_NGX_Result createResult = NGX_D3D11_CREATE_DLSS_EXT(
				commandList,
				&feature,
				runtimeParams,
				&CreateParams);

			// It's possible that DLSS will reject that the "NVSDK_NGX_PerfQuality_Value" parameter, so try again with a different quality mode (they are often meaningless, as what matters is only the resolution).
			if (NVSDK_NGX_FAILED(createResult))
			{
				renderPreset = NVSDK_NGX_DLSS_Hint_Render_Preset_Default; // Let's pick the default just to be sure.
				NVSDK_NGX_Parameter_SetUI(runtimeParams, NVSDK_NGX_Parameter_DLSS_Hint_Render_Preset_Balanced, renderPreset);

				CreateParams.Feature.InPerfQualityValue = NVSDK_NGX_PerfQuality_Value_Balanced;

				createResult = NGX_D3D11_CREATE_DLSS_EXT(
					commandList,
					&feature,
					runtimeParams,
					&CreateParams);
			}

			// Continue even if we got an error, we handle them later.
			// If this mode creation failed, it's likely it will always fail anyway.
			assert(NVSDK_NGX_SUCCEED(createResult));

			return DLSSInternalInstance{ feature, runtimeParams, commandList };
		}
	};
}

bool NGX::DLSS::Init(DLSSInstanceData*& data, ID3D11Device* device, IDXGIAdapter* adapter)
{
	if (data)
	{
		Deinit(data); // This will also null the pointer
	}

	// We expect Deinit() to be called first if the device/adapter changed
	if (!data && device)
	{
		const wchar_t* dataPath = L".";
		NVSDK_NGX_Result result = NVSDK_NGX_D3D11_Init_with_ProjectID(projectID, NVSDK_NGX_ENGINE_TYPE_CUSTOM, engineVersion, dataPath, device);

		if (NVSDK_NGX_SUCCEED(result))
		{
			data = new DLSSInstanceData();
			data->device = device;

			result = NVSDK_NGX_D3D11_GetCapabilityParameters(&data->capabilitiesParams);
			assert(NVSDK_NGX_SUCCEED(result));
		}

		if (data && data->capabilitiesParams != nullptr)
		{
			int superSamplingAvailable = 0;
			// The documentation mentions to use the "NVSDK_NGX_Parameter_SuperSampling_Available" parameter,
			// but the public Unreal Engine implementation uses this one. It probably makes no difference.
			data->capabilitiesParams->Get(NVSDK_NGX_EParameter_SuperSampling_Available, &superSamplingAvailable);

			data->isSupported = superSamplingAvailable > 0;

#if 0 // This extra check isn't really needed unless we want to know the reason DLSS SR might not be supported
			if (data->isSupported && adapter != nullptr)
			{
				NVSDK_NGX_FeatureDiscoveryInfo featureDiscoveryInfo;
				std::memset(&featureDiscoveryInfo, 0, sizeof(NVSDK_NGX_FeatureDiscoveryInfo));
				featureDiscoveryInfo.SDKVersion = NVSDK_NGX_Version_API;
				featureDiscoveryInfo.FeatureID = NVSDK_NGX_Feature_SuperSampling;
				featureDiscoveryInfo.Identifier.IdentifierType = NVSDK_NGX_Application_Identifier_Type_Project_Id;
				featureDiscoveryInfo.Identifier.v.ProjectDesc.ProjectId = projectID;
				featureDiscoveryInfo.Identifier.v.ProjectDesc.EngineType = NVSDK_NGX_ENGINE_TYPE_CUSTOM;
				featureDiscoveryInfo.Identifier.v.ProjectDesc.EngineVersion = engineVersion;
				featureDiscoveryInfo.ApplicationDataPath = dataPath;
				NVSDK_NGX_FeatureRequirement featureRequirement;
				result = NVSDK_NGX_D3D11_GetFeatureRequirements(adapter, &featureDiscoveryInfo, &featureRequirement);
				assert(NVSDK_NGX_SUCCEED(result)); // NOTE: this might fail on AMD if we somehow got here, so maybe we shouldn't assert
				data->isSupported &= NVSDK_NGX_SUCCEED(result) && featureRequirement.FeatureSupported == NVSDK_NGX_Feature_Support_Result::NVSDK_NGX_FeatureSupportResult_Supported;
			}
#endif
		}
	}

	return data != nullptr && data->isSupported;
}

void NGX::DLSS::Deinit(DLSSInstanceData*& data, ID3D11Device* optional_device)
{
	if (data != nullptr)
	{
		if (optional_device == nullptr)
		{
			optional_device = data->device.Get();
		}
		else
		{
			assert(data->device.Get() == optional_device);
		}

		// Needs to be done before "NVSDK_NGX_D3D11_Shutdown1()"
		delete data;
		data = nullptr;

		assert(NVSDK_NGX_SUCCEED(NVSDK_NGX_D3D11_Shutdown1(optional_device)));
	}
}

bool NGX::DLSS::HasInit(const DLSSInstanceData* data)
{
	return data != nullptr;
}

bool NGX::DLSS::IsSupported(const DLSSInstanceData* data)
{
	return data && data->isSupported;
}

bool NGX::DLSS::UpdateSettings(DLSSInstanceData* data, ID3D11DeviceContext* commandList, unsigned int outputWidth, unsigned int outputHeight, unsigned int renderWidth, unsigned int renderHeight, bool hdr, bool dynamicResolution)
{
	// Early exit if DLSS is not supported by hardware or driver.
	if (!commandList || !data || !data->isSupported)
		return false;

#ifndef NDEBUG
	Microsoft::WRL::ComPtr<ID3D11Device> device;
	commandList->GetDevice(device.GetAddressOf());
	assert(data->device.Get() == device.Get());

	Microsoft::WRL::ComPtr<ID3D11DeviceContext> immediate_context;
	device->GetImmediateContext(&immediate_context);
	assert(immediate_context.Get() == commandList); // DLSS only supports the immediate context apparently (both here and in the actual draw function)!
#endif

	bool featureInstanceCreated = data->instance.superSamplingFeature != nullptr && data->instance.runtimeParams != nullptr;

	// No need to re-instantiate DLSS "features" if all the params are the same
	if ((int)outputWidth == data->outputWidth && (int)outputHeight == data->outputHeight
		&& (int)renderWidth == data->renderWidth && (int)renderHeight == data->renderHeight
		&& dynamicResolution == data->dynamicResolution && hdr == data->hdr
		&& data->instance.commandList.Get() == commandList && featureInstanceCreated)
	{
		return true;
	}

	data->sharpness = DLSS_DEFAULT_SHARPNESS; // Reset to default, in case a new one won't be found

	int qualityMode = static_cast<int>(NVSDK_NGX_PerfQuality_Value_Balanced); // Default to balanced if none is found

	unsigned int bestModeDelta = (std::numeric_limits<unsigned int>::max)(); // Wrap it around () because "max" might already be defined as macro

	// Instead of first picking a quality mode and then finding the best render resolution for it,
	// we find the most suitable quality mode for the resolutions we fed in.
	for (int i = 0; i < NUM_PERF_QUALITY_MODES; ++i)
	{
		unsigned int optimalWidth = 0;
		unsigned int optimalHeight = 0;
		unsigned int minWidth = 0, maxWidth = 0, minHeight = 0, maxHeight = 0;
		float sharpness = data->sharpness;

		NVSDK_NGX_Result res = NGX_DLSS_GET_OPTIMAL_SETTINGS(data->capabilitiesParams, outputWidth, outputHeight, static_cast<NVSDK_NGX_PerfQuality_Value>(i), &optimalWidth, &optimalHeight, &maxWidth, &maxHeight, &minWidth, &minHeight, &sharpness);

		if (NVSDK_NGX_SUCCEED(res) && optimalWidth != 0 && optimalHeight != 0)
		{
			const bool isDLAA = static_cast<NVSDK_NGX_PerfQuality_Value>(i) == NVSDK_NGX_PerfQuality_Value::NVSDK_NGX_PerfQuality_Value_DLAA;

			// Just make sure DLSS is always using the full output resolution (it should be, but we never know, DLAA might allow for res inputs higher than outputs in the future)
			if (isDLAA)
			{
				assert(optimalWidth == outputWidth);
				optimalWidth = outputWidth;
				optimalHeight = outputHeight;
				maxWidth = outputWidth;
				maxHeight = outputHeight;
			}
			// This probably can't happen, but I fear I have seen it before, so protect against it
			else if (maxWidth == 0 || maxHeight == 0)
			{
				assert(false);
				maxWidth = optimalWidth;
				maxHeight = optimalHeight;
			}

			const unsigned int deltaFromOptimal = std::abs((int)renderWidth - (int)optimalWidth) + std::abs((int)renderHeight - (int)optimalHeight);
			const bool isInRange = renderWidth >= minWidth && renderWidth <= maxWidth && renderHeight >= minHeight && renderHeight <= maxHeight;

			// Pick the first one with a matching optimal resolution (unless we are doing dynamic resolution, in that case, simply checking for a raw match isn't enough)
			if (!dynamicResolution && optimalWidth == renderWidth && optimalHeight == renderHeight)
			{
				data->sharpness = sharpness;
				qualityMode = i;
				break;
			}
			// or fall back on the one cloest to the optimal resolution range
			else if (isInRange && deltaFromOptimal < bestModeDelta)
			{
				data->sharpness = sharpness;
				qualityMode = i;
				bestModeDelta = deltaFromOptimal;
			}
		}
	}

	if ((!dynamicResolution || bestModeDelta == (std::numeric_limits<unsigned int>::max)()) && renderWidth >= outputWidth && renderHeight >= outputHeight)
	{
		assert(qualityMode == NVSDK_NGX_PerfQuality_Value_DLAA);
		qualityMode = NVSDK_NGX_PerfQuality_Value_DLAA; // Just in case (this isn't expected to happen)
	}

	data->instance.commandList.Reset(); // Just to be explicit
	data->instance = data->CreateSuperSamplingFeature(commandList, outputWidth, outputHeight, renderWidth, renderHeight, qualityMode, hdr);
	data->uniqueHandles.insert(data->instance.superSamplingFeature);
	data->uniqueParameters.insert(data->instance.runtimeParams);

	data->outputWidth = outputWidth;
	data->outputHeight = outputHeight;
	data->renderWidth = renderWidth;
	data->renderHeight = renderHeight;
	data->dynamicResolution = dynamicResolution;

	data->hdr = hdr;

	// If any of these are nullptr, then the initialization failed
	return data->instance.superSamplingFeature != nullptr && data->instance.runtimeParams != nullptr;
}

bool NGX::DLSS::Draw(const DLSSInstanceData* data, ID3D11DeviceContext* commandList, ID3D11Resource* outputColor, ID3D11Resource* sourceColor, ID3D11Resource* motionVectors, ID3D11Resource* depthBuffer, ID3D11Resource* exposure, float preExposure, float jitterX, float jitterY, bool reset, unsigned int renderWidth, unsigned int renderHeight, bool flipMVsX, bool flipMVsY)
{
	assert(data->isSupported);
	assert(data->instance.superSamplingFeature != nullptr && data->instance.runtimeParams != nullptr);
	assert(data->instance.commandList.Get() == commandList);

	NVSDK_NGX_D3D11_DLSS_Eval_Params evalParams;
	memset(&evalParams, 0, sizeof(evalParams));

	if (renderWidth == 0)
	{
		renderWidth = data->renderWidth;
	}
	if (renderHeight == 0)
	{
		renderHeight = data->renderHeight;
	}

	evalParams.pInDepth = depthBuffer;
	evalParams.pInDepthHighRes = depthBuffer;
	evalParams.pInMotionVectors = motionVectors;
	evalParams.InRenderSubrectDimensions.Width = renderWidth;
	evalParams.InRenderSubrectDimensions.Height = renderHeight;
	evalParams.Feature.pInColor = sourceColor;
	evalParams.Feature.pInOutput = outputColor; // Needs to be a UAV
	evalParams.pInExposureTexture = exposure; // Only used in HDR mode. Needs to be a 2D texture.
	if (preExposure != 0.f)
	{
		evalParams.InPreExposure = preExposure;
	}
	evalParams.InReset = reset ? 1 : 0;
#if 0 // Disabled to avoid sharpening randomly coming back if users used old DLLs or NV restored it
	evalParams.Feature.InSharpness = data->sharpness; // It's likely clamped between 0 and 1 internally, though a value of 0 might fall back to the internal default
#endif
#if !GAME_PREY && !GAME_MAFIA_III
	evalParams.InMVScaleX = flipMVsX ? -1.0 : 1.0;
	evalParams.InMVScaleY = flipMVsY ? -1.0 : 1.0;
#else // Prey and Mafia have MVs in UV space, so we need to scale by the render resolution to transform to pixel space // TODO: isn't it in NDC space?
	evalParams.InMVScaleX = static_cast<float>(renderWidth);
	evalParams.InMVScaleY = static_cast<float>(renderHeight);
#endif
#if 0
	evalParams.InJitterOffsetX = jitterX * static_cast<float>(renderWidth);
	evalParams.InJitterOffsetY = jitterY * static_cast<float>(renderHeight);
#elif GAME_FF7_REMAKE
	evalParams.InJitterOffsetX = jitterX * static_cast<float>(renderWidth) * 0.5f;
	evalParams.InJitterOffsetY = jitterY * static_cast<float>(renderHeight) * -0.5f;
#elif GAME_PREY // This is what's needed by vanilla Prey
	evalParams.InJitterOffsetX = jitterX * static_cast<float>(renderWidth) * -0.5f;
	evalParams.InJitterOffsetY = jitterY * static_cast<float>(renderHeight) * 0.5f;
#elif GAME_PREY && 0 // This is an alternative version we modified Prey to follow, but it ended up being wrong
	evalParams.InJitterOffsetX = jitterX * static_cast<float>(data->outputWidth) * -0.5f * (static_cast<float>(data->outputWidth) / static_cast<float>(renderWidth));
	evalParams.InJitterOffsetY = jitterY * static_cast<float>(data->outputHeight) * 0.5f * (static_cast<float>(data->outputHeight) / static_cast<float>(renderHeight));
#else
	evalParams.InJitterOffsetX = jitterX;
	evalParams.InJitterOffsetY = jitterY;
#endif

	NVSDK_NGX_Result result = NGX_D3D11_EVALUATE_DLSS_EXT(
		commandList,
		data->instance.superSamplingFeature,
		data->instance.runtimeParams,
		&evalParams
	);

	return NVSDK_NGX_SUCCEED(result);
}

#endif