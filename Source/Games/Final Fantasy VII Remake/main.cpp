#define GAME_FF7_REMAKE 1

#define ENABLE_NGX 1
#define UPGRADE_SAMPLERS 0
#define GEOMETRY_SHADER_SUPPORT 0
#define ALLOW_SHADERS_DUMPING 0

#include "..\..\Core\core.hpp"

#include "..\..\Core\dlss\DLSS.cpp"

namespace
{
	float2 projection_jitters = { 0, 0 };
	const std::string shader_name_mvec_pixel = "Luma_MotionVec_UE4_Decode";
	const std::string shader_name_bloom_pixel = "Luma_Bloom_NoUpscale_PS";
	const std::string shader_name_bloom_vertex = "Luma_Bloom_NoUpscale_VS";
	const std::string shader_name_menu_slowdown_vertex = "Luma_Menu_Slowdown_NoUpscale_VS";
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
	const uint32_t CBPerViewGlobal_buffer_size = 4096;
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
	std::atomic<bool> has_drawn_upscaling = false;
	std::atomic<bool> found_per_view_globals = false;
	std::atomic<bool> drs_active = false;
	com_ptr<ID3D11PixelShader> motion_vectors_ps;
	com_ptr<ID3D11PixelShader> bloom_ps;
	com_ptr<ID3D11VertexShader> bloom_vs;
	com_ptr<ID3D11VertexShader> menu_slowdown_vs;
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
		}
	}

	void OnInit(bool async) override
	{
		GetShaderDefineData(POST_PROCESS_SPACE_TYPE_HASH).SetDefaultValue('0');
		GetShaderDefineData(EARLY_DISPLAY_ENCODING_HASH).SetDefaultValue('0');
		GetShaderDefineData(VANILLA_ENCODING_TYPE_HASH).SetDefaultValue('0');
		GetShaderDefineData(GAMMA_CORRECTION_TYPE_HASH).SetDefaultValue('1');
		GetShaderDefineData(UI_DRAW_TYPE_HASH).SetDefaultValue('0');

		luma_settings_cbuffer_index = 13;
		luma_data_cbuffer_index = 12;
	}

	void OnCreateDevice(ID3D11Device* native_device, DeviceData& device_data) override
	{
		device_data.game = new GameDeviceDataFF7Remake;
	}

	bool OnDrawCustom(ID3D11Device* native_device, ID3D11DeviceContext* native_device_context, DeviceData& device_data, reshade::api::shader_stage stages, const ShaderHashesList<OneShaderPerPipeline>& original_shader_hashes, bool is_custom_pass, bool& updated_cbuffers) override
	{
		auto& game_device_data = GetGameDeviceData(device_data);
		if (!game_device_data.has_drawn_title && original_shader_hashes.Contains(shader_hashes_Title)) {
			game_device_data.has_drawn_title = true;
		}

		if (!game_device_data.has_drawn_title) {
			return true;
		}

#if ENABLE_NGX
		if (device_data.dlss_sr && !device_data.dlss_sr_suppressed && original_shader_hashes.Contains(shader_hashes_TAA))
		{
			game_device_data.has_drawn_upscaling = true;
			// 1 depth
			// 2 current color source ()
			// 3 previous color source (previous frame)
			// 4 motion vectors
			com_ptr<ID3D11ShaderResourceView> ps_shader_resources[11];
			native_device_context->PSGetShaderResources(0, ARRAYSIZE(ps_shader_resources), reinterpret_cast<ID3D11ShaderResourceView**>(ps_shader_resources));

			com_ptr<ID3D11RenderTargetView> render_target_views[D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT];
			com_ptr<ID3D11DepthStencilView> depth_stencil_view;
			native_device_context->OMGetRenderTargets(D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT, &render_target_views[0], &depth_stencil_view);
			const bool dlss_inputs_valid = ps_shader_resources[1].get() != nullptr && ps_shader_resources[2].get() != nullptr && ps_shader_resources[4].get() != nullptr && render_target_views[0].get() != nullptr;
			ASSERT_ONCE(dlss_inputs_valid);

			if (dlss_inputs_valid)
			{

				com_ptr<ID3D11Resource> output_colorTemp;
				render_target_views[0]->GetResource(&output_colorTemp);
				com_ptr<ID3D11Texture2D> output_color;
				HRESULT hr = output_colorTemp->QueryInterface(&output_color);
				ASSERT_ONCE(SUCCEEDED(hr));
				D3D11_TEXTURE2D_DESC output_texture_desc;
				output_color->GetDesc(&output_texture_desc);

				//ASSERT_ONCE(std::lrintf(device_data.output_resolution.x) == output_texture_desc.Width && std::lrintf(device_data.output_resolution.y) == output_texture_desc.Height);
 				std::array<uint32_t, 2> dlss_render_resolution = FindClosestIntegerResolutionForAspectRatio((double)device_data.output_resolution.x * (double)device_data.dlss_render_resolution_scale, (double)device_data.output_resolution.y  * (double)device_data.dlss_render_resolution_scale, (double)device_data.output_resolution.x / (double)device_data.output_resolution.y );
				bool dlss_hdr = true;

				NGX::DLSS::UpdateSettings(device_data.dlss_sr_handle, native_device_context, device_data.output_resolution.x, device_data.output_resolution.y, dlss_render_resolution[0], dlss_render_resolution[1], dlss_hdr, game_device_data.drs_active); //TODO: figure out dsr later

				bool skip_dlss = output_texture_desc.Width < 32 || output_texture_desc.Height < 32; // DLSS doesn't support output below 32x32
				bool dlss_output_changed = false;
				constexpr bool dlss_use_native_uav = true;
				bool dlss_output_supports_uav = dlss_use_native_uav && (output_texture_desc.BindFlags & D3D11_BIND_UNORDERED_ACCESS) != 0;
				if (!dlss_output_supports_uav)
				{

					output_texture_desc.BindFlags |= D3D11_BIND_UNORDERED_ACCESS;

					if (device_data.dlss_output_color.get())
					{
						D3D11_TEXTURE2D_DESC dlss_output_texture_desc;
						device_data.dlss_output_color->GetDesc(&dlss_output_texture_desc);
						dlss_output_changed = dlss_output_texture_desc.Width != output_texture_desc.Width || dlss_output_texture_desc.Height != output_texture_desc.Height || dlss_output_texture_desc.Format != output_texture_desc.Format;
					}
					if (!device_data.dlss_output_color.get() || dlss_output_changed)
					{
						device_data.dlss_output_color = nullptr; // Make sure we discard the previous one
						hr = native_device->CreateTexture2D(&output_texture_desc, nullptr, &device_data.dlss_output_color);
						ASSERT_ONCE(SUCCEEDED(hr));
					}
					if (!device_data.dlss_output_color.get())
					{
						skip_dlss = true;
					}
				}
				else
				{
					device_data.dlss_output_color = output_color;
				}
				if (!skip_dlss)
				{
					game_device_data.dlss_source_color = nullptr;
					ps_shader_resources[2]->GetResource(&game_device_data.dlss_source_color);
					game_device_data.depth_buffer = nullptr;
					ps_shader_resources[1]->GetResource(&game_device_data.depth_buffer);
					com_ptr<ID3D11Resource> object_velocity_buffer_temp;
					ps_shader_resources[4]->GetResource(&object_velocity_buffer_temp);
					com_ptr<ID3D11Texture2D> object_velocity_buffer;
					hr = object_velocity_buffer_temp->QueryInterface(&object_velocity_buffer);
					ASSERT_ONCE(SUCCEEDED(hr));

					//TODO: add exposure texture support

					// Decode the motion vector from pixel shader
					{
						D3D11_TEXTURE2D_DESC object_velocity_texture_desc;
						object_velocity_buffer->GetDesc(&object_velocity_texture_desc);
						ASSERT_ONCE((object_velocity_texture_desc.BindFlags & D3D11_BIND_RENDER_TARGET) == D3D11_BIND_RENDER_TARGET);
#if 1 // Use the higher quality for MVs, the game's one were R16G16F. This has a ~1% cost on performance but helps with reducing shimmering on fine lines (stright lines looking segmented, like Bart's hair or Shark's teeth) when the camera is moving in a linear fashion. Generating MVs from the depth is still a limited technique so it can't be perfect.
						object_velocity_texture_desc.Format = DXGI_FORMAT_R32G32B32A32_FLOAT;
#else
						object_velocity_texture_desc.Format = DXGI_FORMAT_R16G16_FLOAT;
#endif
						game_device_data.dlss_motion_vectors = nullptr; // Make sure we discard the previous one
						hr = native_device->CreateTexture2D(&object_velocity_texture_desc, nullptr, &game_device_data.dlss_motion_vectors);
						ASSERT_ONCE(SUCCEEDED(hr));

						D3D11_RENDER_TARGET_VIEW_DESC object_velocity_render_target_view_desc;
						render_target_views[0]->GetDesc(&object_velocity_render_target_view_desc);
						object_velocity_render_target_view_desc.Format = object_velocity_texture_desc.Format;
						object_velocity_render_target_view_desc.ViewDimension = D3D11_RTV_DIMENSION_TEXTURE2D;
						object_velocity_render_target_view_desc.Texture2D.MipSlice = 0;

						game_device_data.dlss_motion_vectors_rtv = nullptr; // Make sure we discard the previous one
						native_device->CreateRenderTargetView(game_device_data.dlss_motion_vectors.get(), &object_velocity_render_target_view_desc, &game_device_data.dlss_motion_vectors_rtv);
						ID3D11RenderTargetView* const dlss_motion_vectors_rtv_const = game_device_data.dlss_motion_vectors_rtv.get();
						// Set up for motion vector shader
						native_device_context->OMSetRenderTargets(1, &dlss_motion_vectors_rtv_const, depth_stencil_view.get());
						ID3D11PixelShader* prev_shader_px = nullptr;

						native_device_context->PSGetShader(&prev_shader_px, nullptr, nullptr);
						native_device_context->PSSetShader(game_device_data.motion_vectors_ps.get(), nullptr, 0);
						native_device_context->DrawIndexed(3, 6, 0);
						native_device_context->PSSetShader(prev_shader_px, nullptr, 0);
					}

					bool reset_dlss = device_data.force_reset_dlss_sr || dlss_output_changed;
					device_data.force_reset_dlss_sr = false;
					uint32_t render_width_dlss;
					uint32_t render_height_dlss;
					if (game_device_data.found_per_view_globals) {
						render_width_dlss = std::lrintf(device_data.render_resolution.x);
						render_height_dlss = std::lrintf(device_data.render_resolution.y);
					}
					else
					{
						render_height_dlss = std::lrintf(device_data.render_resolution.y);
						render_width_dlss = std::lrintf(device_data.render_resolution.x);
					}
					float dlss_pre_exposure = 0.f;
					bool dlss_succeeded = NGX::DLSS::Draw(device_data.dlss_sr_handle, native_device_context, device_data.dlss_output_color.get(), game_device_data.dlss_source_color.get(), game_device_data.dlss_motion_vectors.get(), game_device_data.depth_buffer.get(), nullptr, dlss_pre_exposure, projection_jitters.x, projection_jitters.y, reset_dlss, render_width_dlss, render_height_dlss);
					if (dlss_succeeded)
					{
						device_data.has_drawn_dlss_sr = true;
					}
					game_device_data.dlss_motion_vectors_rtv = nullptr;
					game_device_data.dlss_motion_vectors = nullptr;
					game_device_data.dlss_source_color = nullptr;
					game_device_data.depth_buffer = nullptr;

					ID3D11RenderTargetView* const* rtvs_const = (ID3D11RenderTargetView**)std::addressof(render_target_views[0]);
					native_device_context->OMSetRenderTargets(D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT, rtvs_const, depth_stencil_view.get());

					if (device_data.has_drawn_dlss_sr)
					{
						if (!dlss_output_supports_uav)
						{
							native_device_context->CopyResource(output_color.get(), device_data.dlss_output_color.get()); // DX11 doesn't need barriers
						}
						else
						{
							device_data.dlss_output_color = nullptr;
						}
						// update global buffer cb to have render resolution and texture resolution as the same size as output res

						if (game_device_data.found_per_view_globals && device_data.cb_per_view_global_buffer.get() != nullptr && device_data.cb_per_view_global_buffer_map_data != nullptr)
						{
							float4* float_data = reinterpret_cast<float4*>(device_data.cb_per_view_global_buffer_map_data);
							float_data[122] = { float_data[126].x, float_data[126].y, float_data[126].z, float_data[126].w}; // render target size
							float_data[125] = { float_data[126].x, float_data[126].y, float_data[126].z, float_data[126].w };
							native_device_context->UpdateSubresource(device_data.cb_per_view_global_buffer.get(), 0, nullptr, float_data, CBPerViewGlobal_buffer_size, CBPerViewGlobal_buffer_size);
							// stop caching the per view global buffer
							device_data.cb_per_view_global_buffer_map_data = nullptr;
							device_data.cb_per_view_global_buffer = nullptr;
	
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
// TODO: Figure out DOF and Motion Blur afert DLSS early upscale
		if (device_data.has_drawn_dlss_sr && game_device_data.drs_active && original_shader_hashes.Contains(shader_hashes_DOF))
		{
			return true;

		}

		if (device_data.has_drawn_dlss_sr && game_device_data.drs_active && original_shader_hashes.Contains(shader_hashes_Motion_Blur))
		{
			//get render target and copy dlss output to it and skip shader
			com_ptr<ID3D11RenderTargetView> render_target_views[D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT];
			native_device_context->OMGetRenderTargets(D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT, &render_target_views[0], nullptr);
			com_ptr<ID3D11Resource> render_target_resource;
			render_target_views[0]->GetResource(&render_target_resource);
			if (render_target_resource.get() != nullptr && device_data.dlss_output_color.get() != nullptr)
			{
				native_device_context->CopyResource(render_target_resource.get(), device_data.dlss_output_color.get());
				return true; // Skip the original shader
			}
			else
			{
				ASSERT_ONCE(false); // This should never happen, but if it does, we should investigate why.
			}

		}

		if (device_data.has_drawn_dlss_sr && game_device_data.drs_active && game_device_data.found_per_view_globals)
		{
			// check if the render target texture is of output resolution size and store if true in a flag
			bool is_output_resolution = false;
			com_ptr<ID3D11RenderTargetView> render_target_views[D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT];
			com_ptr<ID3D11DepthStencilView> depth_stencil_view;
			native_device_context->OMGetRenderTargets(D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT, &render_target_views[0], &depth_stencil_view);
			if (render_target_views[0].get() != nullptr)
			{
				com_ptr<ID3D11Resource> render_target_resource;
				render_target_views[0]->GetResource(&render_target_resource);
				com_ptr<ID3D11Texture2D> render_target_texture;
				HRESULT hr = render_target_resource->QueryInterface(&render_target_texture);
				ASSERT_ONCE(SUCCEEDED(hr));
				if (render_target_texture.get() == nullptr)
				{
					// If the render target is not a texture, we can't check its size
					ASSERT_ONCE(false);
					return false; // Don't cancel the original draw call
				}
				D3D11_TEXTURE2D_DESC render_target_desc;
				render_target_texture->GetDesc(&render_target_desc);
				if (std::lrintf(device_data.output_resolution.x) == render_target_desc.Width && std::lrintf(device_data.output_resolution.y) == render_target_desc.Height)
				{
					is_output_resolution = true;
				}
			}

			// set scissor and viewport to the output resolution
			if (is_output_resolution) {
				D3D11_VIEWPORT viewport;
				viewport.Width = std::lrintf(device_data.output_resolution.x);
				viewport.Height = std::lrintf(device_data.output_resolution.y);
				viewport.MinDepth = 0.0f;
				viewport.MaxDepth = 1.0f;
				viewport.TopLeftX = 0.0f;
				viewport.TopLeftY = 0.0f;
				native_device_context->RSSetViewports(1, &viewport);
				D3D11_RECT scissor_rect;
				scissor_rect.left = 0;
				scissor_rect.top = 0;
				scissor_rect.right = std::lrintf(device_data.output_resolution.x);
				scissor_rect.bottom = std::lrintf(device_data.output_resolution.y);
				native_device_context->RSSetScissorRects(1, &scissor_rect);
			}

		}

		if (device_data.has_drawn_dlss_sr && game_device_data.found_per_view_globals && game_device_data.drs_active && original_shader_hashes.Contains(shader_hashes_Downsample_Bloom)) {
			//get vertex shader cb2 from resources map and cast to float4[4] array and update [2].x and [2].y to output res and save it back to the buffer
			com_ptr<ID3D11Buffer> cb0_buffer;
			native_device_context->PSGetConstantBuffers(0, 1, &cb0_buffer);
			if (cb0_buffer.get() != nullptr)
			{
				D3D11_BUFFER_DESC cb0_buffer_desc;
				cb0_buffer->GetDesc(&cb0_buffer_desc);
				if (cb0_buffer_desc.ByteWidth == 512) 
				{
					if (downsample_buffer_data != nullptr) {
						//update the downsample buffer data with the output resolution in [20].z and [20].w and call update subresource
						float4* data = reinterpret_cast<float4*>(downsample_buffer_data.get());
						data[20].z = device_data.output_resolution.x;
						data[20].w = device_data.output_resolution.y;
						native_device_context->UpdateSubresource(cb0_buffer.get(), 0, nullptr, data, cb0_buffer_desc.ByteWidth, cb0_buffer_desc.ByteWidth);
					}
				}
			}
		}

		if (device_data.has_drawn_dlss_sr && game_device_data.found_per_view_globals && game_device_data.drs_active && original_shader_hashes.Contains(shader_hashes_Bloom))
		{
			native_device_context->VSSetShader(game_device_data.bloom_vs.get(), nullptr, 0);
			native_device_context->PSSetShader(game_device_data.bloom_ps.get(), nullptr, 0);
		}

		if (device_data.has_drawn_dlss_sr && game_device_data.found_per_view_globals && game_device_data.drs_active && original_shader_hashes.Contains(shader_hashes_MenuSlowdown))
		{
			native_device_context->VSSetShader(game_device_data.menu_slowdown_vs.get(), nullptr, 0);
		}

		if (device_data.has_drawn_dlss_sr && game_device_data.found_per_view_globals && game_device_data.drs_active && original_shader_hashes.Contains(shader_hashes_Tonemap))
		{

			com_ptr<ID3D11Buffer> cb0_buffer;
			native_device_context->PSGetConstantBuffers(0, 1, &cb0_buffer);
			if (cb0_buffer.get() != nullptr)
			{
				D3D11_BUFFER_DESC cb0_buffer_desc;
				cb0_buffer->GetDesc(&cb0_buffer_desc);
				if (cb0_buffer_desc.ByteWidth == 1024)
				{
					if (upsample_buffer_data != nullptr)
					{
						float4* data = reinterpret_cast<float4*>(upsample_buffer_data.get());
						data[30].z = device_data.output_resolution.x;
						data[30].w = device_data.output_resolution.y;
						data[31].x = device_data.output_resolution.x;
						data[31].y = device_data.output_resolution.y;

						native_device_context->UpdateSubresource(cb0_buffer.get(), 0, nullptr, data, cb0_buffer_desc.ByteWidth, cb0_buffer_desc.ByteWidth);
					}
				}
			}

		}
#endif
		return false; // Don't cancel the original draw call
	}

	void OnPresent(ID3D11Device* native_device, DeviceData& device_data) override
	{
		auto& game_device_data = GetGameDeviceData(device_data);

		game_device_data.has_drawn_upscaling = false;
		device_data.has_drawn_dlss_sr = false;
		game_device_data.found_per_view_globals = false;
	}

	void PrintImGuiAbout() override
	{
		ImGui::Text("Final Fantasy VII Remake Luma mod - by izueh etc", ""); // TODO
	}

	void CreateShaderObjects(DeviceData& device_data, const std::optional<std::set<std::string>>& shader_names_filter) override
	{
		auto& game_device_data = GetGameDeviceData(device_data);
		CreateShaderObject(device_data.native_device, shader_name_mvec_pixel, game_device_data.motion_vectors_ps, shader_names_filter);
		CreateShaderObject(device_data.native_device, shader_name_bloom_pixel, game_device_data.bloom_ps, shader_names_filter);
		CreateShaderObject(device_data.native_device, shader_name_bloom_vertex, game_device_data.bloom_vs, shader_names_filter);
		CreateShaderObject(device_data.native_device, shader_name_menu_slowdown_vertex, game_device_data.menu_slowdown_vs, shader_names_filter);
	}

	static void OnMapBufferRegion(reshade::api::device* device, reshade::api::resource resource, uint64_t offset, uint64_t size, reshade::api::map_access access, void** data)
	{
		ID3D11Device* native_device = (ID3D11Device*)(device->get_native());
		ID3D11Buffer* buffer = reinterpret_cast<ID3D11Buffer*>(resource.handle);
		auto& game_device_data = GetGameDeviceData(*device->get_private_data<DeviceData>());

		if (!game_device_data.has_drawn_title) {
			return;
		}
		// No need to convert to native DX11 flags
		if (access == reshade::api::map_access::write_only || access == reshade::api::map_access::write_discard || access == reshade::api::map_access::read_write)
		{
			D3D11_BUFFER_DESC buffer_desc;
			buffer->GetDesc(&buffer_desc);
			DeviceData& device_data = *device->get_private_data<DeviceData>();

			// There seems to only ever be one buffer type of this size, but it's not guaranteed (we might have found more, but it doesn't matter, they are discarded later)...
			// They seemingly all happen on the same thread.
			// Some how these are not marked as "D3D11_BIND_CONSTANT_BUFFER", probably because it copies them over to some other buffer later?
			if (buffer_desc.ByteWidth == CBPerViewGlobal_buffer_size)
			{
				device_data.cb_per_view_global_buffer = buffer;
#if DEVELOPMENT
				// These are the classic "features" of cbuffer 13 (the one we are looking for), in case any of these were different, it could possibly mean we are looking at the wrong buffer here.
				ASSERT_ONCE(buffer_desc.Usage == D3D11_USAGE_DYNAMIC && buffer_desc.BindFlags == D3D11_BIND_CONSTANT_BUFFER && buffer_desc.CPUAccessFlags == D3D11_CPU_ACCESS_WRITE && buffer_desc.MiscFlags == 0 && buffer_desc.StructureByteStride == 0);
#endif // DEVELOPMENT
				//ASSERT_ONCE(!device_data.cb_per_view_global_buffer_map_data);
				device_data.cb_per_view_global_buffer_map_data = *data;
			}
		}
	}

	static void OnUnmapBufferRegion(reshade::api::device* device, reshade::api::resource resource)
	{
		auto& game_device_data = GetGameDeviceData(*device->get_private_data<DeviceData>());
		ID3D11Device* native_device = (ID3D11Device*)(device->get_native());
		ID3D11Buffer* buffer = reinterpret_cast<ID3D11Buffer*>(resource.handle);
		DeviceData& device_data = *device->get_private_data<DeviceData>();
		bool is_global_cbuffer = device_data.cb_per_view_global_buffer != nullptr && device_data.cb_per_view_global_buffer == buffer;
		//ASSERT_ONCE(!device_data.cb_per_view_global_buffer_map_data || is_global_cbuffer);
		if (is_global_cbuffer && device_data.cb_per_view_global_buffer_map_data != nullptr)
		{
			float4(&float_data)[140] = *((float4(*)[140])device_data.cb_per_view_global_buffer_map_data);
			float res_x = device->get_private_data<DeviceData>()->output_resolution.x;
			float res_y = device->get_private_data<DeviceData>()->output_resolution.y;
			//122 target texture res
			//125 render res
			//126 output res
			//118 jitter
			// validate that output res is device output res, validate render res is less than or equal to output res, validate target texture res is equal to render res
			// jitter seems to only be available when the target texture res is equal to the render res so we can use that to validate the cbuffer
			bool is_valid_cbuffer = true
				&& float_data[126].x == res_x && float_data[126].y == res_y
				&& float_data[126].z == 1.0f / res_x && float_data[126].w == 1.0f / res_y
				&& float_data[125].x <= res_x && float_data[125].y <= res_y
				&& float_data[125].z == 1.0f / float_data[125].x && float_data[125].w == 1.0f / float_data[125].y
				&& float_data[122].x == float_data[125].x && float_data[122].y == float_data[125].y
				&& (float_data[118].x != 0.f || float_data[118].y != 0.f);
			if (is_valid_cbuffer)
			{
				game_device_data.found_per_view_globals = true;
				// Extract jitter from constant buffer 1
				projection_jitters.x = float_data[118].x;
				projection_jitters.y = float_data[118].y;
				device_data.render_resolution.x = float_data[125].x;
				device_data.render_resolution.y  = float_data[125].y;
				float resolution_scale = device_data.render_resolution.y  / device_data.output_resolution.y;
				if (!game_device_data.drs_active && resolution_scale == 1.0f) {
					device_data.dlss_render_resolution_scale = 1.0f;
				}
				else if (resolution_scale < 0.5f - FLT_EPSILON)
				{
					device_data.dlss_render_resolution_scale = resolution_scale;
					game_device_data.drs_active = true;
				}
				else
				{
					// This should pick quality or balanced mode, with a range from 100% to 50% resolution scale
					device_data.dlss_render_resolution_scale = 1.f / 1.5f;
					game_device_data.drs_active = true;
				}
			}
		}
	}

	static bool  OnUpdateBufferRegion(reshade::api::device* device, const void* data, reshade::api::resource resource, uint64_t offset, uint64_t size)
	{
		ID3D11Device* native_device = (ID3D11Device*)(device->get_native());
		DeviceData& device_data = *device->get_private_data<DeviceData>();
		if (device_data.has_drawn_dlss_sr && size == 512) {
			const float4* float_data = reinterpret_cast<const float4*>(data);
			if (float_data[20].z == device_data.render_resolution.x && float_data[20].w == device_data.render_resolution.y )
			{
				downsample_buffer_data = std::make_unique<float4[]>(32);
				std::memcpy(downsample_buffer_data.get(), data, size);
			}
			else
			{
				downsample_buffer_data = nullptr;
	
			}

		}
		else if (device_data.has_drawn_dlss_sr && size == 1024) {
			const float4* float_data = reinterpret_cast<const float4*>(data);
			//float_data[30].zw and [31].xy have render_res
			if (float_data[30].z == device_data.render_resolution.x && float_data[30].w == device_data.render_resolution.y  && float_data[31].x == device_data.render_resolution.x && float_data[31].y == device_data.render_resolution.y )
			{
				upsample_buffer_data = std::make_unique<float4[]>(64); 
				std::memcpy(upsample_buffer_data.get(), data, size);
			}
			else
			{
				upsample_buffer_data = nullptr;
			}
		}
		return false;
	}

};

BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved)
{
	if (ul_reason_for_call == DLL_PROCESS_ATTACH)
	{
		Globals::GAME_NAME = PROJECT_NAME;
		Globals::DESCRIPTION = "Final Fantasy VII Remake Luma mod";
		Globals::WEBSITE = "";
		Globals::VERSION = 1;

		shader_hashes_TAA.pixel_shaders.emplace(std::stoul("4729683B", nullptr, 16));
		shader_hashes_Title.pixel_shaders.emplace(std::stoul("5FEE74F9", nullptr, 16));
		shader_hashes_DOF.pixel_shaders.emplace(std::stoul("B400FAF6", nullptr, 16));
		shader_hashes_Motion_Blur.pixel_shaders.emplace(std::stoul("B0F56393", nullptr, 16));
		shader_hashes_Downsample_Bloom.pixel_shaders.emplace(std::stoul("2174B927", nullptr, 16));
		shader_hashes_Bloom.pixel_shaders.emplace(std::stoul("4D6F937E", nullptr, 16));
		shader_hashes_MenuSlowdown.pixel_shaders.emplace(std::stoul("968B821F", nullptr, 16));
		shader_hashes_Tonemap.pixel_shaders.emplace(std::stoul("F68D39B5", nullptr, 16));

		enable_swapchain_upgrade = true;
		swapchain_upgrade_type = 1;
		enable_texture_format_upgrades = true;
		// Texture upgrades (8 bit unorm and 11 bit float etc to 16 bit float)
		texture_upgrade_formats = {
				reshade::api::format::r8g8b8a8_unorm,
				reshade::api::format::r8g8b8a8_unorm_srgb,
				reshade::api::format::r8g8b8a8_typeless,
				reshade::api::format::r8g8b8x8_unorm,
				reshade::api::format::r8g8b8x8_unorm_srgb,
				reshade::api::format::b8g8r8a8_unorm,
				reshade::api::format::b8g8r8a8_unorm_srgb,
				//reshade::api::format::b8g8r8a8_typeless, // currently causes validation issues due to some odd 1x1x1 textures. TODO: Figure out what these textures do.
				reshade::api::format::b8g8r8x8_unorm,
				reshade::api::format::b8g8r8x8_unorm_srgb,
				reshade::api::format::b8g8r8x8_typeless,

				reshade::api::format::r10g10b10a2_unorm,
				reshade::api::format::r10g10b10a2_typeless,

				reshade::api::format::r11g11b10_float,
		};
		texture_format_upgrades_lut_size = 32;
		texture_format_upgrades_lut_dimensions = LUTDimensions::_2D;

		game = new FF7Remake();
	}
	else
	{
		if (ul_reason_for_call == DLL_PROCESS_DETACH)
		{
			reshade::register_event<reshade::addon_event::map_buffer_region>(FF7Remake::OnMapBufferRegion);
			reshade::register_event<reshade::addon_event::unmap_buffer_region>(FF7Remake::OnUnmapBufferRegion);
			reshade::register_event<reshade::addon_event::update_buffer_region>(FF7Remake::OnUpdateBufferRegion);
		}
	}

	CoreMain(hModule, ul_reason_for_call, lpReserved);

	return TRUE;
}
