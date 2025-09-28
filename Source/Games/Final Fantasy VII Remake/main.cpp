#define GAME_FF7_REMAKE 1

#define ENABLE_NGX 1
#define UPGRADE_SAMPLERS 1
#ifdef NDEBUG
#define ALLOW_SHADERS_DUMPING 1
#endif

#include <chrono>
#include <random>
#include "includes\settings.hpp"
#include "..\..\Core\core.hpp"

namespace
{
	float2 projection_jitters = { 0, 0 };
	std::unique_ptr<float4[]> downsample_buffer_data;
	std::unique_ptr<float4[]> upsample_buffer_data;
	ShaderHashesList shader_hashes_TAA;
	ShaderHashesList shader_hashes_Title;
	ShaderHashesList shader_hashes_MotionVectors;
	ShaderHashesList shader_hashes_DOF;
	ShaderHashesList shader_hashes_Motion_Blur;
	ShaderHashesList shader_hashes_Downsample_Bloom;
	ShaderHashesList shader_hashes_Bloom;
	ShaderHashesList shader_hashes_MenuSlowdown;
	ShaderHashesList shader_hashes_Tonemap;
	ShaderHashesList shader_hashes_Velocity_Flatten;
	ShaderHashesList shader_hashes_Velocity_Gather;
	const uint32_t CBPerViewGlobal_buffer_size = 4096;
	float enabled_custom_exposure = 1.f;
	float dlss_custom_pre_exposure = 0.f; // Ignored at 0
	float ignore_warnings = 0.f;

	Luma::Settings::Settings settings = {
		new Luma::Settings::Section{
			.label = "Post Processing",
			.settings = {
				new Luma::Settings::Setting{
					.key = "FXBloom",
					.binding = &cb_luma_global_settings.GameSettings.custom_bloom,
					.type = Luma::Settings::SettingValueType::FLOAT,
					.default_value = 50.f,
					.can_reset = true,
					.label = "Bloom",
					.tooltip = "Bloom strength multiplier. Default is 50.",
					.min = 0.f,
					.max = 100.f,
					.parse = [](float value) { return value * 0.02f; } // Scale down to 0.0-2.0 for the shader
				},
				new Luma::Settings::Setting{
					.key = "FXVignette",
					.binding = &cb_luma_global_settings.GameSettings.custom_vignette,
					.type = Luma::Settings::SettingValueType::FLOAT,
					.default_value = 50.f,
					.can_reset = true,
					.label = "Vignette",
					.tooltip = "Vignette strength multiplier. Default is 50.",
					.min = 0.f,
					.max = 100.f,
					.parse = [](float value) { return value * 0.02f; }
				},
				new Luma::Settings::Setting{
					.key = "FXFilmGrain",
					.binding = &cb_luma_global_settings.GameSettings.custom_film_grain_strength,
					.type = Luma::Settings::SettingValueType::FLOAT,
					.default_value = 50.f,
					.can_reset = true,
					.label = "Film Grain",
					.tooltip = "Film grain strength multiplier. Default is 50, for Vanilla look set to 0.",
					.min = 0.f,
					.max = 100.f,
					// .is_visible = []() { return cb_luma_global_settings.DisplayMode == 1; },
					.parse = [](float value) { return value * 0.02f; }
				},
				new Luma::Settings::Setting{
					.key = "FXRCAS",
					.binding = &cb_luma_global_settings.GameSettings.custom_sharpness_strength,
					.type = Luma::Settings::SettingValueType::FLOAT,
					.default_value = 50.f,
					.can_reset = true,
					.label = "Sharpeness",
					.tooltip = "RCAS strength multiplier. Default is 50, for Vanilla look set to 0.",
					.min = 0.f,
					.max = 100.f,
					.is_visible = []() { return dlss_sr == 1; },
					.parse = [](float value) { return value * 0.01f; }
				},
				new Luma::Settings::Setting{
					.key = "CustomLUTStrength",
					.binding = &cb_luma_global_settings.GameSettings.custom_lut_strength,
					.type = Luma::Settings::SettingValueType::FLOAT,
					.default_value = 100.f,
					.can_reset = true,
					.label = "LUT Strength",
					.tooltip = "LUT strength multiplier. Default is 100.",
					.min = 0.f,
					.max = 100.f,
					.is_visible = []() { return cb_luma_global_settings.DisplayMode == 1; },
					.parse = [](float value) { return value * 0.01f; }
				},
				new Luma::Settings::Setting{
					.key = "FXHDRVideos",
					.binding = &cb_luma_global_settings.GameSettings.custom_hdr_videos,
					.type = Luma::Settings::SettingValueType::BOOLEAN,
					.default_value = 1,
					.can_reset = true,
					.label = "HDR Videos",
					.tooltip = "Enable or disable HDR video playback. Default is On.",
					.min = 0,
					.max = 1,
					.is_visible = []() { return cb_luma_global_settings.DisplayMode == 1; }
				}
			}
		},
		new Luma::Settings::Section{
			.label = "Advanced Settings",
			.settings = {
				new Luma::Settings::Setting{
					.key = "IgnoreWarnings",
					.binding = &ignore_warnings,
					.type = Luma::Settings::SettingValueType::BOOLEAN,
					.can_reset = false,
					.label = "Ignore Warnings",
					.tooltip = "Ignore warning messages. Default is Off."
				},
				new Luma::Settings::Setting{
					.key = "DLSSCustomPreExposure",
					.binding = &enabled_custom_exposure,
					.type = Luma::Settings::SettingValueType::BOOLEAN,
					.default_value = 1.f,
					.can_reset = true,
					.label = "DLSS Custom Pre-Exposure",
					.tooltip = "Custom pre-exposure value for DLSS (This is an estimate value), seems to reduce ghosting and other artifacts. Set to Off have fixed pre-exposure of 1.",
					.is_visible = []() { return dlss_sr  != 0; }
				}
			}
		}
	};

}
struct GameDeviceDataFF7Remake final : public GameDeviceData
{
#if ENABLE_NGX
	// DLSS SR
	com_ptr<ID3D11Texture2D> dlss_motion_vectors;
	com_ptr<ID3D11Resource> dlss_source_color;
	com_ptr<ID3D11Resource> depth_buffer;
	com_ptr<ID3D11RenderTargetView> dlss_motion_vectors_rtv;
#endif // ENABLE_NGX
	std::atomic<bool> has_drawn_title = false;
	std::atomic<bool> has_drawn_taa = false;
	std::atomic<bool> has_drawn_upscaling = false;
	std::atomic<bool> found_per_view_globals = false;
	std::atomic<bool> drs_active = false;
	std::atomic<uint32_t> jitterless_frames_count = 0;
	std::atomic<bool> is_in_menu = true; // Start in menu
	float2 upscaled_render_resolution = { 1, 1 };
	float resolution_scale = 1.0f;
	uint4 viewport_rect = { 0, 0, 1, 1 };
};

class FF7Remake final : public Game
{
	static GameDeviceDataFF7Remake& GetGameDeviceData(DeviceData& device_data)
	{
		return *static_cast<GameDeviceDataFF7Remake*>(device_data.game);
	}

public:
	void OnLoad(std::filesystem::path& file_path, bool failed) override
	{
		if (!failed)
		{
			reshade::register_event<reshade::addon_event::map_buffer_region>(FF7Remake::OnMapBufferRegion);
			reshade::register_event<reshade::addon_event::unmap_buffer_region>(FF7Remake::OnUnmapBufferRegion);
			reshade::register_event<reshade::addon_event::update_buffer_region>(FF7Remake::OnUpdateBufferRegion);
			reshade::register_event<reshade::addon_event::create_device>(FF7Remake::OnCreateDevice);
		}
	}

	void OnInit(bool async) override
	{
		GetShaderDefineData(POST_PROCESS_SPACE_TYPE_HASH).SetDefaultValue('1');
		GetShaderDefineData(EARLY_DISPLAY_ENCODING_HASH).SetDefaultValue('1');
		GetShaderDefineData(VANILLA_ENCODING_TYPE_HASH).SetDefaultValue('1');
		GetShaderDefineData(GAMMA_CORRECTION_TYPE_HASH).SetDefaultValue('1');
		GetShaderDefineData(UI_DRAW_TYPE_HASH).SetDefaultValue('1');

		native_shaders_definitions.emplace(CompileTimeStringHash("Decode MVs"), ShaderDefinition{ "Luma_MotionVec_UE4_Decode", reshade::api::pipeline_subobject_type::pixel_shader });

		luma_settings_cbuffer_index = 13;
		luma_data_cbuffer_index = 12;
	}

	void OnInitSwapchain(reshade::api::swapchain* swapchain) override
	{
		auto& device_data = *swapchain->get_device()->get_private_data<DeviceData>();
		auto& game_device_data = GetGameDeviceData(device_data);

		// Start from here, we then update it later in case the game rendered with black bars due to forcing a different aspect ratio from the swapchain buffer
		game_device_data.upscaled_render_resolution = device_data.output_resolution;
	}

	static bool OnCreateDevice(reshade::api::device_api api, uint32_t& api_version)
	{
		if (api != reshade::api::device_api::d3d11)
		{
			if (ignore_warnings == 0.f)
				MessageBoxA(game_window, "This mod only supports Direct3D 11.\nSet -dx11 in the launch options or uninstall the mod.\nIf you are sure the launch option is set correctly, set ignore warning in advanced settings.", NAME, MB_SETFOREGROUND);
		}
		return false;
	}

	void OnCreateDevice(ID3D11Device* native_device, DeviceData& device_data) override
	{
		device_data.game = new GameDeviceDataFF7Remake;
	}

	void PrepareDrawForEarlyUpscaling(ID3D11Device* native_device, ID3D11DeviceContext* native_device_context, DeviceData& device_data)
	{
		auto& game_device_data = FF7Remake::GetGameDeviceData(device_data);

		// check if the render target texture is of output resolution size and store if true in a flag
		bool is_upscaled_render_resolution = false;
		com_ptr<ID3D11RenderTargetView> render_target_views[D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT];
		com_ptr<ID3D11DepthStencilView> depth_stencil_view;
		native_device_context->OMGetRenderTargets(D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT, &render_target_views[0], &depth_stencil_view);
		// Just a guess... always only check the first render target
		if (render_target_views[0].get() != nullptr)
		{
			com_ptr<ID3D11Resource> render_target_resource;
			render_target_views[0]->GetResource(&render_target_resource);

			com_ptr<ID3D11Texture2D> render_target_texture;
			HRESULT hr = render_target_resource->QueryInterface(&render_target_texture);
			ASSERT_ONCE(SUCCEEDED(hr));
			if (render_target_texture.get() == nullptr)
			{
				// If the render target is not a texture 2D, it's not what we are looking for, and we have no reason to continue
				return;
			}

			D3D11_TEXTURE2D_DESC render_target_desc;
			render_target_texture->GetDesc(&render_target_desc);
			if (std::lrintf(game_device_data.upscaled_render_resolution.x) == render_target_desc.Width && std::lrintf(game_device_data.upscaled_render_resolution.y) == render_target_desc.Height)
			{
				is_upscaled_render_resolution = true;
			}
		}

		// set scissor and viewport to the output resolution (scissor are probably not necessary, but they might have been set already).
		// For bloom/exposure mips passes, we don't need to change the viewport as their size is independent from the current res scale.
		if (is_upscaled_render_resolution)
		{
			D3D11_VIEWPORT viewport;
			viewport.Width = std::lrintf(game_device_data.upscaled_render_resolution.x);
			viewport.Height = std::lrintf(game_device_data.upscaled_render_resolution.y);
			viewport.MinDepth = 0.0f;
			viewport.MaxDepth = 1.0f;
			viewport.TopLeftX = 0.0f;
			viewport.TopLeftY = 0.0f;
			native_device_context->RSSetViewports(1, &viewport);
			D3D11_RECT scissor_rect;
			scissor_rect.left = 0;
			scissor_rect.top = 0;
			scissor_rect.right = std::lrintf(game_device_data.upscaled_render_resolution.x);
			scissor_rect.bottom = std::lrintf(game_device_data.upscaled_render_resolution.y);
			native_device_context->RSSetScissorRects(1, &scissor_rect);
		}
	}

	bool OnDrawCustom(ID3D11Device* native_device, ID3D11DeviceContext* native_device_context, CommandListData& cmd_list_data, DeviceData& device_data, reshade::api::shader_stage stages, const ShaderHashesList<OneShaderPerPipeline>& original_shader_hashes, bool is_custom_pass, bool& updated_cbuffers) override
	{
		auto& game_device_data = GetGameDeviceData(device_data);
		// TODO: this seems like an unnecessary check that would only cause problems.
		// A better optimization would be to do something similar, but instead checking the scene gbuffers composition shaders, that are guaranteed to run before post processing,
		// so we can skip all the DLSS checks for shaders that run before (given that there's ~2000+ of them).
		if (!game_device_data.has_drawn_title && original_shader_hashes.Contains(shader_hashes_Title)) {
			game_device_data.has_drawn_title = true;
		}

		if (!game_device_data.has_drawn_title) {
			return false;
		}

		// Nothing more to do after tonemapping
		if (device_data.has_drawn_main_post_processing) {
			return false;
		}

		const bool is_taa = original_shader_hashes.Contains(shader_hashes_TAA);
		if (is_taa) {
			game_device_data.has_drawn_taa = true;
			device_data.taa_detected = true;
		}

		// Nothing to do if TAA isn't enabled
		if (!game_device_data.has_drawn_taa) {
			return false;
		}

		bool is_tonemapping = !is_taa && original_shader_hashes.Contains(shader_hashes_Tonemap);

		if (is_tonemapping)
		{
			game_device_data.has_drawn_upscaling = true; // This pass will make upscaling happen if DLSS didn't already do it before
			device_data.has_drawn_main_post_processing = true; // Post processing is finished, nothing more to fix
		}

#if ENABLE_NGX
		if (is_taa && device_data.dlss_sr && !device_data.dlss_sr_suppressed)
		{
			if (device_data.native_pixel_shaders[CompileTimeStringHash("Decode MVs")].get() == nullptr) {
				device_data.force_reset_dlss_sr = true;
				return false;
			}
			// 1 depth
			// 2 current color source
			// 3 previous color source (previous frame)
			// 4 motion vectors
			com_ptr<ID3D11ShaderResourceView> ps_shader_resources[5];
			native_device_context->PSGetShaderResources(0, ARRAYSIZE(ps_shader_resources), &ps_shader_resources[0]);

			com_ptr<ID3D11RenderTargetView> render_target_views[D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT]; // There should only be 1 or 2
			com_ptr<ID3D11DepthStencilView> depth_stencil_view;
			native_device_context->OMGetRenderTargets(D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT, &render_target_views[0], &depth_stencil_view);
			const bool dlss_inputs_valid = ps_shader_resources[0].get() != nullptr && ps_shader_resources[1].get() != nullptr && ps_shader_resources[2].get() != nullptr && ps_shader_resources[4].get() != nullptr && render_target_views[0].get() != nullptr;
			ASSERT_ONCE(dlss_inputs_valid);

			if (dlss_inputs_valid)
			{
				com_ptr<ID3D11Resource> output_color_resource;
				render_target_views[0]->GetResource(&output_color_resource);
				com_ptr<ID3D11Texture2D> output_color;
				HRESULT hr = output_color_resource->QueryInterface(&output_color);
				ASSERT_ONCE(SUCCEEDED(hr));

				D3D11_TEXTURE2D_DESC taa_output_texture_desc;
				output_color->GetDesc(&taa_output_texture_desc);

				D3D11_VIEWPORT viewport;
				uint32_t num_viewports = 1;
				native_device_context->RSGetViewports(&num_viewports, &viewport);
				device_data.render_resolution = { viewport.Width, viewport.Height };
				game_device_data.upscaled_render_resolution = { (float)taa_output_texture_desc.Width, (float)taa_output_texture_desc.Height };
				game_device_data.resolution_scale = (float)device_data.render_resolution.x / (float)game_device_data.upscaled_render_resolution.x;
				game_device_data.viewport_rect = { static_cast<uint32_t>(viewport.TopLeftX), static_cast<uint32_t>(viewport.TopLeftY), static_cast<uint32_t>(game_device_data.upscaled_render_resolution.x), static_cast<uint32_t>(game_device_data.upscaled_render_resolution.y) };
				// Once DRS has engaged once, we can't really detect if it's been turned off ever again, anyway it's always active by default in this game (unless one has mods to disable it, or fix a scaled render resolution)
				if (!game_device_data.drs_active && game_device_data.resolution_scale == 1.0f)
				{
					device_data.dlss_render_resolution_scale = 1.0f;
				}
				else if (game_device_data.resolution_scale < 0.5f - FLT_EPSILON)
				{
					device_data.dlss_render_resolution_scale = game_device_data.resolution_scale;
					game_device_data.drs_active = true;
				}
				else
				{
					// This should pick quality or balanced mode, with a range from 100% to 50% resolution scale
					device_data.dlss_render_resolution_scale = 1.f / 1.5f;
					game_device_data.drs_active = true;
				}

				// The TAA input and output textures were guaranteed to be of the same size, so we pass in the output one as render res,
				// scaled by the DLSS render resolution scaling factor (which is a fixed multiplication to enabled dynamic res scaling in DLSS, it doesn't change every frame, as long as the res doesn't drop below 50%).
				double target_aspect_ratio = (double)game_device_data.upscaled_render_resolution.x / (double)game_device_data.upscaled_render_resolution.y;
				std::array<uint32_t, 2> dlss_input_resolution = FindClosestIntegerResolutionForAspectRatio((double)taa_output_texture_desc.Width * device_data.dlss_render_resolution_scale, (double)taa_output_texture_desc.Height * device_data.dlss_render_resolution_scale, target_aspect_ratio);
				
				if (dlss_input_resolution[0] > game_device_data.upscaled_render_resolution.x || dlss_input_resolution[1] > game_device_data.upscaled_render_resolution.y)
				{
					device_data.force_reset_dlss_sr = true;
					return false;
				}

				bool dlss_hdr = true; // Unreal Engine does DLSS before tonemapping, in HDR linear space
				NGX::DLSS::UpdateSettings(device_data.dlss_sr_handle, native_device_context, game_device_data.upscaled_render_resolution.x, game_device_data.upscaled_render_resolution.y, dlss_input_resolution[0], dlss_input_resolution[1], dlss_hdr, game_device_data.drs_active);

				bool skip_dlss = taa_output_texture_desc.Width < 32 || taa_output_texture_desc.Height < 32; // DLSS doesn't support output below 32x32
				bool dlss_output_changed = false;

				constexpr bool dlss_use_native_uav = true;
				bool dlss_output_supports_uav = dlss_use_native_uav && (taa_output_texture_desc.BindFlags & D3D11_BIND_UNORDERED_ACCESS) != 0;
				// Create a copy that supports Unordered Access if it wasn't already supported
				if (!dlss_output_supports_uav)
				{
					D3D11_TEXTURE2D_DESC dlss_output_texture_desc = taa_output_texture_desc;
					dlss_output_texture_desc.Width = std::lrintf(game_device_data.upscaled_render_resolution.x);
					dlss_output_texture_desc.Height = std::lrintf(game_device_data.upscaled_render_resolution.y);
					dlss_output_texture_desc.BindFlags |= D3D11_BIND_UNORDERED_ACCESS;

					if (device_data.dlss_output_color.get())
					{
						D3D11_TEXTURE2D_DESC prev_dlss_output_texture_desc;
						device_data.dlss_output_color->GetDesc(&prev_dlss_output_texture_desc);
						dlss_output_changed = prev_dlss_output_texture_desc.Width != dlss_output_texture_desc.Width || prev_dlss_output_texture_desc.Height != dlss_output_texture_desc.Height || prev_dlss_output_texture_desc.Format != dlss_output_texture_desc.Format;
					}
					if (!device_data.dlss_output_color.get() || dlss_output_changed)
					{
						 device_data.dlss_output_color = nullptr; // Make sure we discard the previous one
						 hr = native_device->CreateTexture2D(&dlss_output_texture_desc, nullptr, &device_data.dlss_output_color);
						 ASSERT_ONCE(SUCCEEDED(hr));
					}
					// Texture creation failed, we can't proceed with DLSS
					if (!device_data.dlss_output_color.get())
					{
						skip_dlss = true;
					}
				}
				else
				{
					ASSERT_ONCE(device_data.dlss_output_color == nullptr);
					device_data.dlss_output_color = output_color;
				}

				if (!skip_dlss)
				{
					game_device_data.dlss_source_color = nullptr;
					ps_shader_resources[2]->GetResource(&game_device_data.dlss_source_color);
					game_device_data.depth_buffer = nullptr;
					ps_shader_resources[1]->GetResource(&game_device_data.depth_buffer);
					com_ptr<ID3D11Resource> object_velocity;
					ps_shader_resources[4]->GetResource(&object_velocity);

					//TODO: add exposure texture support (it's possibly calculated just earlier in the auto exposure steps, but they could be after DLSS too, depends on UE), either way auto exposure is ok

					// Decode the motion vector from pixel shader
					{
						if (!AreResourcesEqual(object_velocity.get(), game_device_data.dlss_motion_vectors.get(), false /*check_format*/))
						{
							com_ptr<ID3D11Texture2D> object_velocity_texture;
							hr = object_velocity->QueryInterface(&object_velocity_texture);
							ASSERT_ONCE(SUCCEEDED(hr));
							D3D11_TEXTURE2D_DESC object_velocity_texture_desc;
							object_velocity_texture->GetDesc(&object_velocity_texture_desc);
							ASSERT_ONCE((object_velocity_texture_desc.BindFlags & D3D11_BIND_RENDER_TARGET) == D3D11_BIND_RENDER_TARGET);
#if 1 // Use the higher quality for MVs, the game's one were R16G16F. This has a ~1% cost on performance but helps with reducing shimmering on fine lines (stright lines looking segmented, like Bart's hair or Shark's teeth) when the camera is moving in a linear fashion.
							object_velocity_texture_desc.Format = DXGI_FORMAT_R32G32_FLOAT;
#else // Note: for FF7, 16bit might be enough, to be tried and compared, but the extra precision won't hurt
							object_velocity_texture_desc.Format = DXGI_FORMAT_R16G16_FLOAT;
#endif

							game_device_data.dlss_motion_vectors = nullptr; // Make sure we discard the previous one
							hr = native_device->CreateTexture2D(&object_velocity_texture_desc, nullptr, &game_device_data.dlss_motion_vectors);
							ASSERT_ONCE(SUCCEEDED(hr));

							game_device_data.dlss_motion_vectors_rtv = nullptr; // Make sure we discard the previous one
							if (SUCCEEDED(hr))
							{
								hr = native_device->CreateRenderTargetView(game_device_data.dlss_motion_vectors.get(), nullptr, &game_device_data.dlss_motion_vectors_rtv);
								ASSERT_ONCE(SUCCEEDED(hr));
							}
						}

						com_ptr<ID3D11VertexShader> prev_shader_vx;
						com_ptr<ID3D11PixelShader> prev_shader_px;
						native_device_context->VSGetShader(&prev_shader_vx, nullptr, nullptr);
						native_device_context->PSGetShader(&prev_shader_px, nullptr, nullptr);
						D3D11_PRIMITIVE_TOPOLOGY primitive_topology;
						native_device_context->IAGetPrimitiveTopology(&primitive_topology);

						// Set up for motion vector shader
						ID3D11RenderTargetView* const dlss_motion_vectors_rtv_const = game_device_data.dlss_motion_vectors_rtv.get();
						native_device_context->OMSetRenderTargets(1, &dlss_motion_vectors_rtv_const, nullptr);

						// We only need to swap the pixel/vertex shaders, depth and blend were already in the right state
						native_device_context->VSSetShader(device_data.native_vertex_shaders[CompileTimeStringHash("Copy VS")].get(), nullptr, 0);
						native_device_context->PSSetShader(device_data.native_pixel_shaders[CompileTimeStringHash("Decode MVs")].get(), nullptr, 0);

						// We could probably keep the original vertex shader too, but whatever
						native_device_context->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLESTRIP);
						//native_device_context->IASetInputLayout(nullptr); // Seemengly not needed
						//native_device_context->RSSetState(nullptr); // Seemengly not needed

						// Finally draw:
						native_device_context->Draw(4, 0);
						//native_device_context->DrawIndexed(3, 6, 0); // Original call would have been this, but we swap the pixel and vertex shaders

#if DEVELOPMENT
						const std::shared_lock lock_trace(s_mutex_trace);
						if (trace_running)
						{
							const std::unique_lock lock_trace_2(cmd_list_data.mutex_trace);
							TraceDrawCallData trace_draw_call_data;
							trace_draw_call_data.type = TraceDrawCallData::TraceDrawCallType::Custom;
							trace_draw_call_data.command_list = native_device_context;
							trace_draw_call_data.custom_name = "DLSS Decode Motion Vectors";
							// Re-use the RTV data for simplicity
							GetResourceInfo(game_device_data.dlss_motion_vectors.get(), trace_draw_call_data.rt_size[0], trace_draw_call_data.rt_format[0], &trace_draw_call_data.rt_type_name[0], &trace_draw_call_data.rt_hash[0]);
							cmd_list_data.trace_draw_calls_data.insert(cmd_list_data.trace_draw_calls_data.end() - 1, trace_draw_call_data);
						}
#endif

						// Restore the state
						native_device_context->VSSetShader(prev_shader_vx.get(), nullptr, 0);
						native_device_context->PSSetShader(prev_shader_px.get(), nullptr, 0);

						native_device_context->IASetPrimitiveTopology(primitive_topology);
					}

					bool reset_dlss = device_data.force_reset_dlss_sr || dlss_output_changed;
					device_data.force_reset_dlss_sr = false;

					// Render resolution doesn't necessarily match with the source texture size, DRS draws on the top left of textures
					uint32_t render_width_dlss = 0;
					uint32_t render_height_dlss = 0;
					if (game_device_data.found_per_view_globals)
					{
						render_width_dlss = std::lrintf(device_data.render_resolution.x);
						render_height_dlss = std::lrintf(device_data.render_resolution.y);
					}
					else // Shouldn't happen!
					{
						render_width_dlss = taa_output_texture_desc.Width;
						render_height_dlss = taa_output_texture_desc.Height;
					}

					float dlss_pre_exposure = 0.f;
					if (enabled_custom_exposure != 0.f)
					{
						dlss_pre_exposure = dlss_custom_pre_exposure;
					} else {
#if DEVELOPMENT || TEST
						dlss_pre_exposure = dlss_custom_pre_exposure;
#endif
					}
					bool dlss_succeeded = NGX::DLSS::Draw(device_data.dlss_sr_handle, native_device_context, device_data.dlss_output_color.get(), game_device_data.dlss_source_color.get(), game_device_data.dlss_motion_vectors.get(), game_device_data.depth_buffer.get(), nullptr, dlss_pre_exposure, projection_jitters.x, projection_jitters.y, reset_dlss, render_width_dlss, render_height_dlss);
					if (dlss_succeeded)
					{
						device_data.has_drawn_dlss_sr = true;
					}
					game_device_data.dlss_source_color = nullptr;
					game_device_data.depth_buffer = nullptr;

					// Restore the previous state
					ID3D11RenderTargetView* const* rtvs_const = (ID3D11RenderTargetView**)std::addressof(render_target_views[0]);
					native_device_context->OMSetRenderTargets(D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT, rtvs_const, depth_stencil_view.get());

					if (device_data.has_drawn_dlss_sr)
					{
#if DEVELOPMENT
						const std::shared_lock lock_trace(s_mutex_trace);
						if (trace_running)
						{
							const std::unique_lock lock_trace_2(cmd_list_data.mutex_trace);
							TraceDrawCallData trace_draw_call_data;
							trace_draw_call_data.type = TraceDrawCallData::TraceDrawCallType::Custom;
							trace_draw_call_data.command_list = native_device_context;
							trace_draw_call_data.custom_name = "DLSS";
							// Re-use the RTV data for simplicity
							GetResourceInfo(device_data.dlss_output_color.get(), trace_draw_call_data.rt_size[0], trace_draw_call_data.rt_format[0], &trace_draw_call_data.rt_type_name[0], &trace_draw_call_data.rt_hash[0]);
							cmd_list_data.trace_draw_calls_data.insert(cmd_list_data.trace_draw_calls_data.end() - 1, trace_draw_call_data);
						}
#endif

						// Upscaling happened later (during tonemapping) natively but we anticipate it with DLSS
						game_device_data.has_drawn_upscaling = true;

						if (!dlss_output_supports_uav)
						{
							native_device_context->CopyResource(output_color.get(), device_data.dlss_output_color.get()); // DX11 doesn't need barriers
						}
						else
						{
							device_data.dlss_output_color = nullptr;
						}

						return true;
					}
					else
					{
						//ASSERT_ONCE(false);
						//cb_luma_global_settings.DLSS = 0;
						//device_data.cb_luma_global_settings_dirty = true;
						//device_data.dlss_sr_suppressed = true;
						device_data.force_reset_dlss_sr = true;
					}
				}
				if (dlss_output_supports_uav)
				{
					device_data.dlss_output_color = nullptr;
				}
			}
		}

		// Always upgrade the viewport to the full upscaled resolution if we anticipated upscaling to happen before tonemapping
		// Prevent this from happening on compute shaders as it's never needed (also they don't use viewport)
		if (device_data.has_drawn_dlss_sr && game_device_data.drs_active && game_device_data.found_per_view_globals && (stages & reshade::api::shader_stage::all_compute) == 0)
		{
			PrepareDrawForEarlyUpscaling(native_device, native_device_context, device_data);
		}

#endif // ENABLE_NGX

		return false; // Don't cancel the original draw call
	}

	void OnPresent(ID3D11Device* native_device, DeviceData& device_data) override
	{
		auto& game_device_data = GetGameDeviceData(device_data);

		if (game_device_data.has_drawn_title) {
			ASSERT_ONCE(game_device_data.found_per_view_globals);
		}

		device_data.has_drawn_main_post_processing = false;
		game_device_data.has_drawn_upscaling = false;
		game_device_data.has_drawn_taa = false;
		device_data.taa_detected = false;
		device_data.has_drawn_dlss_sr = false;
		game_device_data.found_per_view_globals = false;
		device_data.cb_luma_global_settings_dirty = true;
		static std::mt19937 random_generator(std::chrono::system_clock::now().time_since_epoch().count());
		static auto random_range = static_cast<float>((std::mt19937::max)() - (std::mt19937::min)());
		cb_luma_global_settings.GameSettings.custom_random = static_cast<float>(random_generator() + (std::mt19937::min)()) / random_range;
	}

	void PrintImGuiAbout() override
	{
      	ImGui::PushTextWrapPos(0.0f); 
		ImGui::Text("Luma for \"Final Fantasy VII Remake\" is developed by Izueh and Pumbo and is open source and free.\n"
         "It adds DLSS and improved HDR tonemapping.\n"
		 "Additional thanks to ShortFuse and Musa from the RenoDX team and their HDR mods for Remake and Rebirth which served as reference.\n",
         "If you enjoy it, consider donating to any of the contributors.", "");
		ImGui::PopTextWrapPos();
			
		ImGui::NewLine();

		const auto button_color = ImGui::GetStyleColorVec4(ImGuiCol_Button);
		const auto button_hovered_color = ImGui::GetStyleColorVec4(ImGuiCol_ButtonHovered);
		const auto button_active_color = ImGui::GetStyleColorVec4(ImGuiCol_ButtonActive);

		ImGui::PushStyleColor(ImGuiCol_Button, IM_COL32(30, 136, 124, 255));
		ImGui::PushStyleColor(ImGuiCol_ButtonHovered, IM_COL32(17, 149, 134, 255));
		ImGui::PushStyleColor(ImGuiCol_ButtonActive, IM_COL32(57, 133, 111, 255));
		static const std::string donation_link_izueh = std::string("Buy Izueh a Coffee on ko-fi ") + std::string(ICON_FK_OK);
		if (ImGui::Button(donation_link_izueh.c_str()))
		{
			system("start https://ko-fi.com/izueh");
		}
		ImGui::PopStyleColor(3);
		ImGui::NewLine();

		ImGui::PushStyleColor(ImGuiCol_Button, IM_COL32(70, 134, 0, 255));
		ImGui::PushStyleColor(ImGuiCol_ButtonHovered, IM_COL32(70 + 9, 134 + 9, 0, 255));
		ImGui::PushStyleColor(ImGuiCol_ButtonActive, IM_COL32(70 + 18, 134 + 18, 0, 255));

		static const std::string donation_link_pumbo = std::string("Buy Pumbo a Coffee on buymeacoffee ") + std::string(ICON_FK_OK);
		if (ImGui::Button(donation_link_pumbo.c_str()))
		{
			system("start https://buymeacoffee.com/realfiloppi");
		}
		static const std::string donation_link_pumbo_2 = std::string("Buy Pumbo a Coffee on ko-fi ") + std::string(ICON_FK_OK);
		if (ImGui::Button(donation_link_pumbo_2.c_str()))
		{
			system("start https://ko-fi.com/realpumbo");
		}
		ImGui::PopStyleColor(3);

		ImGui::NewLine();
		// Restore the previous color, otherwise the state we set would persist even if we popped it
		ImGui::PushStyleColor(ImGuiCol_Button, button_color);
		ImGui::PushStyleColor(ImGuiCol_ButtonHovered, button_hovered_color);
		ImGui::PushStyleColor(ImGuiCol_ButtonActive, button_active_color);
		static const std::string social_link = std::string("Join our \"HDR Den\" Discord ") + std::string(ICON_FK_SEARCH);
		if (ImGui::Button(social_link.c_str()))
		{
			// Unique link for Luma by Pumbo (to track the origin of people joining), do not share for other purposes
			static const std::string obfuscated_link = std::string("start https://discord.gg/J9fM") + std::string("3EVuEZ");
			system(obfuscated_link.c_str());
		}
		static const std::string contributing_link = std::string("Contribute on Github ") + std::string(ICON_FK_FILE_CODE);
		if (ImGui::Button(contributing_link.c_str()))
		{
			system("start https://github.com/Filoppi/Luma-Framework");
		}
		ImGui::PopStyleColor(3);

		ImGui::NewLine();
		ImGui::Text("Credits:"
			"\n\nMain:"
			"\nIzueh"
			"\nPumbo"

			"\n\nAcknowledgments:"
			"\nShortFuse"
			"\nMusa"

			"\n\nThird Party:"
			"\nReShade"
			"\nImGui"
			"\nRenoDX"
			"\n3Dmigoto"
			"\nOklab"
			"\nDICE (HDR tonemapper)"
			, "");
	}

	void UpdateLumaInstanceDataCB(CB::LumaInstanceDataPadded& data, CommandListData& cmd_list_data, DeviceData& device_data) override
	{
		auto& game_device_data = GetGameDeviceData(device_data);
		data.GameData.RenderResolution = { device_data.render_resolution.x, device_data.render_resolution.y, 1.0f / device_data.render_resolution.x, 1.0f / device_data.render_resolution.y };
		data.GameData.OutputResolution = { game_device_data.upscaled_render_resolution.x, game_device_data.upscaled_render_resolution.y, 1.0f / game_device_data.upscaled_render_resolution.x, 1.0f / game_device_data.upscaled_render_resolution.y };
		data.GameData.ResolutionScale = { game_device_data.resolution_scale, 1.0f / game_device_data.resolution_scale};
		data.GameData.DrewUpscaling = device_data.has_drawn_dlss_sr ? 1 : 0;
		data.GameData.ViewportRect = game_device_data.viewport_rect;
	}

	static void OnMapBufferRegion(reshade::api::device* device, reshade::api::resource resource, uint64_t offset, uint64_t size, reshade::api::map_access access, void** data)
	{
		ID3D11Device* native_device = (ID3D11Device*)(device->get_native());
		ID3D11Buffer* buffer = reinterpret_cast<ID3D11Buffer*>(resource.handle);
		DeviceData& device_data = *device->get_private_data<DeviceData>();
		auto& game_device_data = GetGameDeviceData(device_data);

		// The frames until this draw have a defaulted 1920x1080 resolution (and slightly after too)
		if (!game_device_data.has_drawn_title) {
			return;
		}

		// No need to convert to native DX11 flags
		if (access == reshade::api::map_access::write_only || access == reshade::api::map_access::write_discard || access == reshade::api::map_access::read_write)
		{
			D3D11_BUFFER_DESC buffer_desc;
			buffer->GetDesc(&buffer_desc);

			if (buffer_desc.ByteWidth == CBPerViewGlobal_buffer_size)
			{
				device_data.cb_per_view_global_buffer = buffer;
#if DEVELOPMENT
				// These are the classic "features" of cbuffer 13 (the one we are looking for), in case any of these were different, it could possibly mean we are looking at the wrong buffer here.
				ASSERT_ONCE(buffer_desc.Usage == D3D11_USAGE_DYNAMIC && buffer_desc.BindFlags == D3D11_BIND_CONSTANT_BUFFER && buffer_desc.CPUAccessFlags == D3D11_CPU_ACCESS_WRITE && buffer_desc.MiscFlags == 0 && buffer_desc.StructureByteStride == 0);
#endif // DEVELOPMENT
				ASSERT_ONCE(!device_data.cb_per_view_global_buffer_map_data);
				device_data.cb_per_view_global_buffer_map_data = *data;
			}
		}
	}

	static void OnUnmapBufferRegion(reshade::api::device* device, reshade::api::resource resource)
	{
		ID3D11Device* native_device = (ID3D11Device*)(device->get_native());
		ID3D11Buffer* buffer = reinterpret_cast<ID3D11Buffer*>(resource.handle);
		DeviceData& device_data = *device->get_private_data<DeviceData>();
		auto& game_device_data = GetGameDeviceData(device_data);
		bool is_global_cbuffer = device_data.cb_per_view_global_buffer != nullptr && device_data.cb_per_view_global_buffer == buffer;
		ASSERT_ONCE(!device_data.cb_per_view_global_buffer_map_data || is_global_cbuffer);
		if (is_global_cbuffer && device_data.cb_per_view_global_buffer_map_data != nullptr)
		{
			float4(&float_data)[CBPerViewGlobal_buffer_size / sizeof(float4)] = *((float4(*)[CBPerViewGlobal_buffer_size / sizeof(float4)])device_data.cb_per_view_global_buffer_map_data);

			// TAA cbuffer, called once (?) per frame, possibly at the beginning of the frame
			//122 target texture res
			//125 render res
			//126 upscaled render res (doesn't necessarily match the display/swapchain resolution, there might be black bars)
			//118 jitter
			bool is_valid_cbuffer = true
				&& float_data[126].z == 1.0f / float_data[126].x && float_data[126].w == 1.0f / float_data[126].y
				&& float_data[125].z == 1.0f / float_data[125].x && float_data[125].w == 1.0f / float_data[125].y;
				//&& float_data[122].x == float_data[125].x && float_data[122].y == float_data[125].y && float_data[122].z == float_data[125].z && float_data[122].w == float_data[125].w;

			// Make absolutely sure the jitters aren't both 0, which should never happen if they used proper jitter generation math, but we don't know,
			// though this happens in menus or when TAA is disabed (through mods)
			bool jitters_valid = std::abs(float_data[118].x) <= 1.f && std::abs(float_data[118].y) <= 1.f; // TODO: the jitters range is probably 0.5/render_res or so, hence we could restrict the check to that range to make it safer?
			jitters_valid &= (std::abs(float_data[118].x) > 0.f || std::abs(float_data[118].y) > 0.f);
			is_valid_cbuffer &= jitters_valid;

			if (is_valid_cbuffer)
			{
				size_t thread_id = std::hash<std::thread::id>{}(std::this_thread::get_id());
				ASSERT_ONCE(!game_device_data.found_per_view_globals); // We found this twice? Shouldn't happen, we should probably reject one of the two
				bool has_jitters = float_data[118].x != 0.f || float_data[118].y != 0.f;
				if (has_jitters)
				{
					game_device_data.jitterless_frames_count = 0;
					game_device_data.is_in_menu = false;
				}
				// Give it a two frames tolerance just to make 100% sure that the jitters random generation didn't actually pick 0 for both in one frame (it might be possible depending on the random pattern generation they used, but probably impossible for two frames, see "Halton")
				else
				{
					// Note: for now we don't disable DLSS even if jitters are off
					game_device_data.jitterless_frames_count++;
					if (game_device_data.jitterless_frames_count >= 2)
					{
						if (!game_device_data.is_in_menu)
						{
							device_data.force_reset_dlss_sr = true; // TODO: make sure this doesn't happen when pausing the game and the scene in the background remains the same, it'd mean we get a couple blurry frames when we go back to the game

							game_device_data.is_in_menu = true;
						}
					}
				}

				game_device_data.found_per_view_globals = true;
				// Extract jitter from constant buffer 1
				projection_jitters.x = float_data[118].x;
				projection_jitters.y = float_data[118].y;
				if (enabled_custom_exposure != 0.f)
				{
					dlss_custom_pre_exposure = float_data[128].x * 100.0f; // Just a guess, needs testing
				}
			}
			device_data.cb_per_view_global_buffer_map_data = nullptr;
			device_data.cb_per_view_global_buffer = nullptr;
		}
	}

	static bool OnUpdateBufferRegion(reshade::api::device* device, const void* data, reshade::api::resource resource, uint64_t offset, uint64_t size)
	{
		 ID3D11Device* native_device = (ID3D11Device*)(device->get_native());
		 DeviceData& device_data = *device->get_private_data<DeviceData>();
		 auto& game_device_data = GetGameDeviceData(device_data);

		 if (device_data.has_drawn_dlss_sr && size == 512) {
		 	// It's not very nice to const cast, but we know for a fact this is dynamic memory, so it's probably fine to edit it (ReShade doesn't offer an interface for replacing it easily, and doesn't pass in the command list)
		 	float4* mutable_float_data = reinterpret_cast<float4*>(const_cast<void*>(data));
		 	const float4* float_data = reinterpret_cast<const float4*>(data);
		 	if (float_data[20].z == device_data.render_resolution.x && float_data[20].w == device_data.render_resolution.y)
		 	{
		 		mutable_float_data[20].z = game_device_data.upscaled_render_resolution.x;
		 		mutable_float_data[20].w = game_device_data.upscaled_render_resolution.y;
		 	}
		 }
		 else if (device_data.has_drawn_dlss_sr && size == 1024) {
		 	float4* mutable_float_data = reinterpret_cast<float4*>(const_cast<void*>(data));
		 	const float4* float_data = reinterpret_cast<const float4*>(data);
		 	//float_data[30].zw and [31].xy have render_res
		 	if (float_data[30].z == device_data.render_resolution.x && float_data[30].w == device_data.render_resolution.y && float_data[31].x == device_data.render_resolution.x && float_data[31].y == device_data.render_resolution.y)
		 	{
		 		mutable_float_data[30].z = game_device_data.upscaled_render_resolution.x;
		 		mutable_float_data[30].w = game_device_data.upscaled_render_resolution.y;
		 		mutable_float_data[31].x = game_device_data.upscaled_render_resolution.x;
		 		mutable_float_data[31].y = game_device_data.upscaled_render_resolution.y;
		 	}
		 }
		return false;
	}

#if DEVELOPMENT || TEST
	void DrawImGuiDevSettings(DeviceData& device_data) override
	{
#if ENABLE_NGX
		ImGui::NewLine();
		//ImGui::SliderFloat("DLSS Custom Exposure", &dlss_custom_exposure, 0.0, 10.0);
		ImGui::SliderFloat("DLSS Custom Pre-Exposure", &dlss_custom_pre_exposure, 0.0, 10.0);
#endif // ENABLE_NGX
	}
#endif // DEVELOPMENT

	void LoadConfigs() override
	{
		Luma::Settings::LoadSettings();
	}

	void DrawImGuiSettings(DeviceData& device_data) override
	{
		Luma::Settings::DrawSettings();
	}
};
BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved)
{
	if (ul_reason_for_call == DLL_PROCESS_ATTACH)
	{
		default_paper_white = 250.f;
		Globals::SetGlobals(PROJECT_NAME, "Final Fantasy VII Remake Luma mod");
		Globals::VERSION = 1;

		shader_hashes_TAA.pixel_shaders.emplace(std::stoul("4729683B", nullptr, 16));
		shader_hashes_Title.pixel_shaders.emplace(std::stoul("5FEE74F9", nullptr, 16));
		shader_hashes_DOF.pixel_shaders.emplace(std::stoul("B400FAF6", nullptr, 16));
		shader_hashes_Motion_Blur.pixel_shaders.emplace(std::stoul("B0F56393", nullptr, 16));
		shader_hashes_Downsample_Bloom.pixel_shaders.emplace(std::stoul("2174B927", nullptr, 16));
		shader_hashes_Bloom.pixel_shaders.emplace(std::stoul("4D6F937E", nullptr, 16));
		shader_hashes_MenuSlowdown.pixel_shaders.emplace(std::stoul("968B821F", nullptr, 16));
		shader_hashes_Tonemap.pixel_shaders.emplace(std::stoul("F68D39B5", nullptr, 16));
		shader_hashes_Velocity_Flatten.compute_shaders.emplace(std::stoul("4EB2EA5B", nullptr, 16));
		shader_hashes_Velocity_Gather.compute_shaders.emplace(std::stoul("FEE03685", nullptr, 16));


#if DEVELOPMENT
		// These make things messy in this game, given it renders at lower resolutions and then upscales and adds black bars beyond 16:9
		debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::Fullscreen;

		forced_shader_names.emplace(std::stoul("4729683B", nullptr, 16), "TAA");
		forced_shader_names.emplace(std::stoul("B400FAF6", nullptr, 16), "DoF");
		forced_shader_names.emplace(std::stoul("B0F56393", nullptr, 16), "Motion Blur");
		forced_shader_names.emplace(std::stoul("2174B927", nullptr, 16), "Downsample Bloom"); // This is the first bloom downsample pass to run, it does a maximum of 50% downscaling, but if the resolution scale was e.g. 75% of the output one, it will convert from 75% to 50%, so the bloom chain isn't really affected by the render res
		forced_shader_names.emplace(std::stoul("A77F0B56", nullptr, 16), "Downsample Bloom"); // The result of this (4x3 texture or something) is used for bloom, maybe also as a local exposure map or something
		forced_shader_names.emplace(std::stoul("D9E87012", nullptr, 16), "Upscale Bloom");
		forced_shader_names.emplace(std::stoul("46727E9A", nullptr, 16), "Upscale Bloom"); // There's multiple versions of this (maybe one for DRS?)
		forced_shader_names.emplace(std::stoul("CCD7FA05", nullptr, 16), "Blur Bloom");
		forced_shader_names.emplace(std::stoul("69467442", nullptr, 16), "Blur Bloom");
		forced_shader_names.emplace(std::stoul("4D6F937E", nullptr, 16), "Apply Bloom");
		forced_shader_names.emplace(std::stoul("968B821F", nullptr, 16), "Slowdown Menu");
		forced_shader_names.emplace(std::stoul("F68D39B5", nullptr, 16), "Upscale and Tonemap");
		forced_shader_names.emplace(std::stoul("4EB2EA5B", nullptr, 16), "Velocity Flatten");
		forced_shader_names.emplace(std::stoul("FEE03685", nullptr, 16), "Velocity Gather");
#endif

		enable_swapchain_upgrade = true;
		swapchain_upgrade_type = SwapchainUpgradeType::scRGB;
		enable_texture_format_upgrades = true;
		// Texture upgrades (8 bit unorm and 11 bit float etc to 16 bit float)
		texture_upgrade_formats = {
#if 0 // Probably not needed
				reshade::api::format::r8g8b8a8_unorm,
				reshade::api::format::r8g8b8a8_unorm_srgb,
				reshade::api::format::r8g8b8a8_typeless,
				reshade::api::format::r8g8b8x8_unorm,
				reshade::api::format::r8g8b8x8_unorm_srgb,
				reshade::api::format::b8g8r8a8_unorm,
				reshade::api::format::b8g8r8a8_unorm_srgb,
				//reshade::api::format::b8g8r8a8_typeless, // currently causes validation issues due to some odd 1x1x1 textures (that's just an assert Luma put for mods devs to double check though). TODO: Figure out what these textures do.
				reshade::api::format::b8g8r8x8_unorm,
				reshade::api::format::b8g8r8x8_unorm_srgb,
				reshade::api::format::b8g8r8x8_typeless,
#endif

				reshade::api::format::r10g10b10a2_unorm,
				reshade::api::format::r10g10b10a2_typeless,

				reshade::api::format::r11g11b10_float,
		};
		// Upgrade all 16:9 render targets too, because the game defaults to that aspect ratio internally unless mods are applied
		texture_format_upgrades_2d_size_filters |= (uint32_t)TextureFormatUpgrades2DSizeFilters::CustomAspectRatio;
		texture_format_upgrades_2d_custom_aspect_ratios = { 16.f / 9.f };
		// LUT is 3D 32x
		texture_format_upgrades_lut_size = 32;
		texture_format_upgrades_lut_dimensions = LUTDimensions::_3D;

		Luma::Settings::Initialize(&settings);

		game = new FF7Remake();
	}
	else if (ul_reason_for_call == DLL_PROCESS_DETACH)
	{
		reshade::unregister_event<reshade::addon_event::map_buffer_region>(FF7Remake::OnMapBufferRegion);
		reshade::unregister_event<reshade::addon_event::unmap_buffer_region>(FF7Remake::OnUnmapBufferRegion);
		reshade::unregister_event<reshade::addon_event::update_buffer_region>(FF7Remake::OnUpdateBufferRegion);
	}

	CoreMain(hModule, ul_reason_for_call, lpReserved);

	return TRUE;
}