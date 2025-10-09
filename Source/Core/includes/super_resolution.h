#pragma once

struct ID3D11Device;
struct ID3D11DeviceContext;
struct ID3D11Resource;
struct IDXGIAdapter;

namespace SR
{
	// Note that these don't necessarily match 1:1 with classes, some might be different configurations of the same implementation.
	enum class UserType
	{
		None,
		Auto,
		DLSS_CNN,
		DLSS_TRANSFORMER,
		FSR_3,
	};

	// Put these in order of preference (most preferred first). For automatic selection.
	enum class Type
	{
		DLSS,
		FSR,
		None = -1
	};

	__forceinline bool AreTypesEqual(UserType user_type, Type type)
	{
		switch (user_type)
		{	
		case SR::UserType::None:
			return type == Type::None;
		case SR::UserType::Auto:
			return true; // Always accept it for now, given that it's the first one we find compatible
		case SR::UserType::DLSS_CNN:
			return type == Type::DLSS;
		case SR::UserType::DLSS_TRANSFORMER:
			return type == Type::DLSS;
		case SR::UserType::FSR_3:
			return type == Type::FSR;
		}
		return false;
	}

	struct SettingsData
	{
		unsigned int output_width = 1;
		unsigned int output_height = 1;

		// In case of dynamic resolution, it's the target res (the mid point one).
		unsigned int render_width = 1;
		unsigned int render_height = 1;
		// TODO: add min/max render res for dynamic res
		// Whether dynamic rendering resolution is requested/desired
		bool dynamic_resolution = false;

		// Whether buffers are in linear space HDR or gamma space sRGB (depending on the implementation they might be required to be UNORM, ro also be fine as FLOAT)
		bool hdr = true;
		bool inverted_depth = false;
		bool mvs_jittered = false;
		// MVs need to have positive values when moving towards the top left of the screen
		float mvs_x_scale = 1.f; // Flip or scale by render res
		float mvs_y_scale = 1.f; // Flip or scale by render res
		// Alternatively, either force the exposure to 1 (or 0.18 mid grey) if we run after tonemapping, or feed the correct one if we run before
		bool auto_exposure = false;
		// Enable beta/experimental features, if any. They might have better quality in most places but have major issues in others.
		bool use_experimental_features = false;
	};

	// Interface to be subclassed. Represents a handle.
	struct InstanceData
	{
		bool							is_supported = false;

		bool							supports_dynamic_resolution = true;
		bool							supports_upscaling = true;
		// Whether the aspect ratio is expected to be the same between the render resolution and the output resolution
		bool							supports_non_uniform_aspect_ratio_upscaling = true;
		// Whether the application can just pick any rendering resolution (without any restrictive boundaries), or whether it needs to query the supported ones from the SR implementation
		bool							supports_arbitrary_resolutions = true;
		// Whether the jittering phase/period is determined by the implementation or can be picked by the application
		bool							supports_arbitrary_jitter_phases = true;
		bool							supports_sdr = true;
		// Whether the implementation will preserve negative values in scRGB linear buffers, instead of clipping them (all sr implementations support hdr float buffers).
		// Most implementations will assume sRGB/Rec.709 colors.
		bool							supports_scrgb_hdr = false;
		bool							requires_unordered_access_output_texture = true; // TODO: implement etc
		bool							automatically_restores_pipeline_state = false; // TODO: implement etc
		unsigned int				min_resolution = 1; // Min width or height

		SettingsData				settings_data = {};

		virtual ~InstanceData() {}
	};

	// A super resolution implementation,
	// this is a generic term to include Temporal Anti Aliasing (with jittered rendering and motion vectors) and upscaling.
	class SuperResolutionImpl
	{
	public:
		virtual bool HasInit(const InstanceData* data) const { return false; }
		// Needs init to be called first
		virtual bool IsSupported(const InstanceData* data) const { return false; }

		// Must be called once before usage. Still expects Deinit() to be called even if it failed.
		// Returns whether this SR implementation is supported by hardware and driver.
		// Fill in a data "handle", there can be more than one at a time.
		virtual bool Init(InstanceData*& data, ID3D11Device* device, IDXGIAdapter* adapter = nullptr) { return false; }
		// Should be called before shutdown or on device destruction.
		virtual void Deinit(InstanceData*& data, ID3D11Device* optional_device = nullptr) {}

		// Note that this might expect the same command list all the times.
		virtual bool UpdateSettings(InstanceData* data, ID3D11DeviceContext* command_list, const SettingsData& settings_data) { return false; }

		struct DrawData
		{
			bool reset = false;

			ID3D11Resource* output_color = nullptr;
			ID3D11Resource* source_color = nullptr;
			ID3D11Resource* motion_vectors = nullptr;
			ID3D11Resource* depth_buffer = nullptr; // SR expects the depth to be the device/HW one (1 being near, not 1 being the camera (linear depth)), though it might actually not matter
			ID3D11Resource* exposure = nullptr;

			// Can be left to 0 to pick the default/target render res.
			unsigned int render_width = 0;
			unsigned int render_height = 0;

			float pre_exposure = 0.f; // Ignored if 0
			float jitter_x = 0.f; // In NCD space // TODO: is it NDC or UV space?
			float jitter_y = 0.f; // In NCD space
			float vert_fov = 0.f; // Ignored if 0 (not always needed)
			float near_plane = 0.f;
			float far_plane = 1.f;
			float time_delta = -1.f; // Ignored if < 0 (not always needed)
			float user_sharpness = -1.f; // Ignored/default if < 0
		};

		// Returns true if drawing didn't fail.
		// Note that this might expect the same command list all the times.
		virtual bool Draw(const InstanceData* data, ID3D11DeviceContext* command_list, const DrawData& draw_data) { return false; }

		// Returns the suggested or requested period, depending on the implementation.
		//virtual int GetJitterPhases() const { return 1; } // TODO
	};
}