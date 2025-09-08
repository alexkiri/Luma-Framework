#pragma once

enum class DrawStateStackType
{
   // Same as "FullGraphics" but skips some states that are usually not changed by our code.
   SimpleGraphics,
   // Not 100% of the graphics state, but almost everything we'll ever need.
   FullGraphics,
   // Not 100% of the compute state, but almost everything we'll ever need.
   Compute,
};
// Caches all the states we might need to modify to draw a simple pixel shader.
// First call "Cache()" (once) and then call "Restore()" (once).
// TODO: check "ID3D11Device1::CreateDeviceContextState" for DX11
template<DrawStateStackType Mode = DrawStateStackType::FullGraphics>
struct DrawStateStack
{
   // This is the max according to "PSSetShader()" documentation
   static constexpr UINT max_shader_class_instances = 256;

   DrawStateStack()
   {
#if ENABLE_SHADER_CLASS_INSTANCES
      if constexpr (Mode == DrawStateStackType::SimpleGraphics || Mode == DrawStateStackType::FullGraphics)
      {
         std::memset(&vs_instances, 0, sizeof(void*) * max_shader_class_instances);
         std::memset(&ps_instances, 0, sizeof(void*) * max_shader_class_instances);
      }
      else if constexpr (Mode == DrawStateStackType::Compute)
      {
         std::memset(&cs_instances, 0, sizeof(void*) * max_shader_class_instances);
      }
#endif
#if 0 // Not needed
      std::fill(std::begin(constant_buffers_num_constant), std::end(constant_buffers_num_constant), 4096); // Default from docs
#endif
   }

   // Cache aside the previous resources/states:
   void Cache(ID3D11DeviceContext* device_context, UINT device_max_uav_num)
   {
      com_ptr<ID3D11DeviceContext1> device_context_1;
      HRESULT hr = device_context->QueryInterface(&device_context_1);
#if 0 // This happens in some games
      if (SUCCEEDED(hr) && device_context_1)
      {
         ASSERT_ONCE(false); // If this was the case, we'd need to handle the extra parameters of functions like "PSGetConstantBuffers1"
      }
#endif

      uav_num = device_max_uav_num;
      if constexpr (Mode == DrawStateStackType::SimpleGraphics || Mode == DrawStateStackType::FullGraphics)
      {
         device_context->OMGetBlendState(&blend_state, blend_factor, &blend_sample_mask);
         device_context->IAGetPrimitiveTopology(&primitive_topology);
         device_context->RSGetScissorRects(&scissor_rects_num, nullptr); // This will get the number of scissor rects used
         device_context->RSGetScissorRects(&scissor_rects_num, &scissor_rects[0]);
         device_context->RSGetViewports(&viewports_num, nullptr); // This will get the number of viewports used
         device_context->RSGetViewports(&viewports_num, &viewports[0]);
         device_context->PSGetShaderResources(0, srv_num, &shader_resource_views[0]);
         if (device_context_1)
         {
            device_context_1->PSGetConstantBuffers1(0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT, &constant_buffers[0], constant_buffers_first_constant, constant_buffers_num_constant);
         }
         else
         {
            device_context->PSGetConstantBuffers(0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT, &constant_buffers[0]);
         }
         device_context->OMGetDepthStencilState(&depth_stencil_state, &stencil_ref);
         device_context->OMGetRenderTargets(D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT, &render_target_views[0], &depth_stencil_view);
         if constexpr (Mode == DrawStateStackType::FullGraphics)
         {
            for (size_t i = 0; i < D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT; i++)
            {
               bool rtv_empty = render_target_views[i].get() == nullptr;
               if (!rtv_empty)
               {
                  render_target_views[i].reset(); // Re-set it as we will re-assign it
                  valid_render_target_views_bound++; // The documentation is confusing, but it seems like the UAV start slot you request needs to be >= the number of valid bound RTVs
               }
            }
            depth_stencil_view.reset();
            device_context->OMGetRenderTargetsAndUnorderedAccessViews(valid_render_target_views_bound, &render_target_views[0], &depth_stencil_view, valid_render_target_views_bound, uav_num - valid_render_target_views_bound, &unordered_access_views[0]);
         }
#if ENABLE_SHADER_CLASS_INSTANCES
         device_context->VSGetShader(&vs, vs_instances, &vs_instances_count);
         device_context->PSGetShader(&ps, ps_instances, &ps_instances_count);
         ASSERT_ONCE(vs_instances_count == 0 && ps_instances_count == 0);
#else
         device_context->VSGetShader(&vs, nullptr, 0);
         device_context->PSGetShader(&ps, nullptr, 0);
#endif
         device_context->PSGetSamplers(0, samplers_num, &samplers_state[0]);
         device_context->IAGetInputLayout(&input_layout);
         device_context->RSGetState(&rasterizer_state);

#if 0 // These are not needed until proven otherwise, we don't change, nor rely on these states
         ID3D11Buffer* VSConstantBuffer;
         ID3D11Buffer* VertexBuffer;
         ID3D11Buffer* IndexBuffer;
         UINT IndexBufferOffset, VertexBufferStride, VertexBufferOffset;
         DXGI_FORMAT IndexBufferFormat;
         device_context->VSGetConstantBuffers(0, 1, &VSConstantBuffer);
         device_context->IAGetIndexBuffer(&IndexBuffer, &IndexBufferFormat, &IndexBufferOffset);
         device_context->IAGetVertexBuffers(0, 1, &VertexBuffer, &VertexBufferStride, &VertexBufferOffset);
         device_context->VSGetConstantBuffers(...);
         device_context->GSGetShader(&gs, nullptr, 0); // And others
#endif
      }
      else if constexpr (Mode == DrawStateStackType::Compute)
      {
         device_context->CSGetShaderResources(0, srv_num, &shader_resource_views[0]);
         if (device_context_1)
         {
            device_context_1->CSGetConstantBuffers1(0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT, &constant_buffers[0], constant_buffers_first_constant, constant_buffers_num_constant);
         }
         else
         {
            device_context->CSGetConstantBuffers(0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT, &constant_buffers[0]);
         }
         device_context->CSGetUnorderedAccessViews(0, uav_num, &unordered_access_views[0]);
#if ENABLE_SHADER_CLASS_INSTANCES
         device_context->CSGetShader(&cs, cs_instances, &cs_instances_count);
         ASSERT_ONCE(vs_instances_count == 0 && cs_instances_count == 0);
#else
         device_context->CSGetShader(&cs, nullptr, 0);
#endif
         device_context->CSGetSamplers(0, samplers_num, &samplers_state[0]);
      }
   }

   // Restore the previous resources/states:
   void Restore(ID3D11DeviceContext* device_context)
   {
      com_ptr<ID3D11DeviceContext1> device_context_1;
      HRESULT hr = device_context->QueryInterface(&device_context_1);

      if constexpr (Mode == DrawStateStackType::SimpleGraphics || Mode == DrawStateStackType::FullGraphics)
      {
         device_context->OMSetBlendState(blend_state.get(), blend_factor, blend_sample_mask);
         device_context->IASetPrimitiveTopology(primitive_topology);
         device_context->RSSetScissorRects(scissor_rects_num, &scissor_rects[0]);
         device_context->RSSetViewports(viewports_num, &viewports[0]);
         ID3D11ShaderResourceView* const* srvs_const = (ID3D11ShaderResourceView**)std::addressof(shader_resource_views[0]); // We can't use "com_ptr"'s "T **operator&()" as it asserts if the object isn't null, even if the reference would be const
         device_context->PSSetShaderResources(0, srv_num, srvs_const);
         ID3D11Buffer* const* constant_buffers_const = (ID3D11Buffer**)std::addressof(constant_buffers[0]);
         if (device_context_1)
         {
            device_context_1->PSSetConstantBuffers1(0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT, constant_buffers_const, constant_buffers_first_constant, constant_buffers_num_constant);
         }
         else
         {
            device_context->PSSetConstantBuffers(0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT, constant_buffers_const);
         }
         device_context->OMSetDepthStencilState(depth_stencil_state.get(), stencil_ref);
         ID3D11RenderTargetView* const* rtvs_const = (ID3D11RenderTargetView**)std::addressof(render_target_views[0]);
         if constexpr (Mode == DrawStateStackType::FullGraphics)
         {
            ID3D11UnorderedAccessView* const* uavs_const = (ID3D11UnorderedAccessView**)std::addressof(unordered_access_views[0]);
            UINT uav_initial_counts[D3D11_1_UAV_SLOT_COUNT]; // Likely not necessary, we could pass in nullptr
            std::ranges::fill(uav_initial_counts, -1u);
            device_context->OMSetRenderTargetsAndUnorderedAccessViews(valid_render_target_views_bound, rtvs_const, depth_stencil_view.get(), valid_render_target_views_bound, uav_num - valid_render_target_views_bound, uavs_const, &uav_initial_counts[0]);
         }
         else
         {
            device_context->OMSetRenderTargets(D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT, rtvs_const, depth_stencil_view.get());
         }
#if ENABLE_SHADER_CLASS_INSTANCES
         device_context->VSSetShader(vs.get(), vs_instances, vs_instances_count);
         device_context->PSSetShader(ps.get(), ps_instances, ps_instances_count);
         for (UINT i = 0; i < max_shader_class_instances; i++)
         {
            if (vs_instances[i] != nullptr)
            {
               vs_instances[i]->Release();
               vs_instances[i] = nullptr;
            }
            if (ps_instances[i] != nullptr)
            {
               ps_instances[i]->Release();
               ps_instances[i] = nullptr;
            }
         }
#else
         device_context->VSSetShader(vs.get(), nullptr, 0);
         device_context->PSSetShader(ps.get(), nullptr, 0);
#endif
         ID3D11SamplerState* const* ps_samplers_state_const = (ID3D11SamplerState**)std::addressof(samplers_state[0]);
         device_context->PSSetSamplers(0, samplers_num, ps_samplers_state_const);
         device_context->IASetInputLayout(input_layout.get());
         device_context->RSSetState(rasterizer_state.get());
      }
      else if constexpr (Mode == DrawStateStackType::Compute)
      {
         ID3D11ShaderResourceView* const* srvs_const = (ID3D11ShaderResourceView**)std::addressof(shader_resource_views[0]);
         device_context->CSSetShaderResources(0, srv_num, srvs_const);
         ID3D11Buffer* const* constant_buffers_const = (ID3D11Buffer**)std::addressof(constant_buffers[0]);
         if (device_context_1)
         {
            device_context_1->CSSetConstantBuffers1(0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT, constant_buffers_const, constant_buffers_first_constant, constant_buffers_num_constant);
         }
         else
         {
            device_context->CSSetConstantBuffers(0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT, constant_buffers_const);
         }
         ID3D11UnorderedAccessView* const* uavs_const = (ID3D11UnorderedAccessView**)std::addressof(unordered_access_views[0]);
         UINT uav_initial_counts[D3D11_1_UAV_SLOT_COUNT]; // Likely not necessary, we could pass in nullptr
         std::ranges::fill(uav_initial_counts, -1u);
         device_context->CSSetUnorderedAccessViews(0, uav_num, uavs_const, uav_initial_counts);
#if ENABLE_SHADER_CLASS_INSTANCES
         device_context->CSSetShader(cs.get(), cs_instances, cs_instances_count);
         for (UINT i = 0; i < max_shader_class_instances; i++)
         {
            if (cs_instances[i] != nullptr)
            {
               cs_instances[i]->Release();
               cs_instances[i] = nullptr;
            }
         }
#else
         device_context->CSSetShader(cs.get(), nullptr, 0);
#endif
         ID3D11SamplerState* const* cs_samplers_state_const = (ID3D11SamplerState**)std::addressof(samplers_state[0]);
         device_context->CSSetSamplers(0, samplers_num, cs_samplers_state_const);
      }
   }

   static constexpr size_t samplers_num = []
      {
         if constexpr (Mode == DrawStateStackType::FullGraphics || Mode == DrawStateStackType::Compute)
            return D3D11_COMMONSHADER_SAMPLER_SLOT_COUNT;
         else
            return size_t{ 1 };
      }();
   static constexpr size_t srv_num = []
      {
         if constexpr (Mode == DrawStateStackType::FullGraphics || Mode == DrawStateStackType::Compute)
            return D3D11_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT;
         else
            return size_t{ 3 }; // We usually don't use them beyond than the first 3
      }();

   com_ptr<ID3D11BlendState> blend_state;
   FLOAT blend_factor[4] = { 1.f, 1.f, 1.f, 1.f };
   UINT blend_sample_mask;
   com_ptr<ID3D11VertexShader> vs;
   com_ptr<ID3D11PixelShader> ps;
   com_ptr<ID3D11ComputeShader> cs;
#if ENABLE_SHADER_CLASS_INSTANCES
   UINT vs_instances_count = max_shader_class_instances;
   UINT ps_instances_count = max_shader_class_instances;
   UINT cs_instances_count = max_shader_class_instances;
   ID3D11ClassInstance* vs_instances[max_shader_class_instances];
   ID3D11ClassInstance* ps_instances[max_shader_class_instances];
   ID3D11ClassInstance* cs_instances[max_shader_class_instances];
#endif
   D3D11_PRIMITIVE_TOPOLOGY primitive_topology;

   com_ptr<ID3D11DepthStencilState> depth_stencil_state;
   UINT stencil_ref;
   com_ptr<ID3D11DepthStencilView> depth_stencil_view;
   com_ptr<ID3D11SamplerState> samplers_state[samplers_num];
   com_ptr<ID3D11ShaderResourceView> shader_resource_views[srv_num];
   com_ptr<ID3D11RenderTargetView> render_target_views[D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT];
   com_ptr<ID3D11UnorderedAccessView> unordered_access_views[D3D11_1_UAV_SLOT_COUNT];
   com_ptr<ID3D11Buffer> constant_buffers[D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT];
   UINT constant_buffers_first_constant[D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT] = {};
   UINT constant_buffers_num_constant[D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT] = {};
   D3D11_RECT scissor_rects[D3D11_VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE];
   UINT scissor_rects_num = 0;
   D3D11_VIEWPORT viewports[D3D11_VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE];
   UINT viewports_num = 1;
   com_ptr<ID3D11InputLayout> input_layout;
   com_ptr<ID3D11RasterizerState> rasterizer_state;
   UINT valid_render_target_views_bound = 0;
   UINT uav_num = D3D11_1_UAV_SLOT_COUNT;
};

#if DEVELOPMENT
// Expects mutexes to already be locked
void AddTraceDrawCallData(std::vector<TraceDrawCallData>& trace_draw_calls_data, const DeviceData& device_data, ID3D11DeviceContext* native_device_context, uint64_t pipeline_handle,
   std::unordered_map<uint32_t, CachedShader*>& shader_cache, const std::unordered_map<const ID3D11InputLayout*, std::vector<D3D11_INPUT_ELEMENT_DESC>>& input_layouts_descs, const DrawDispatchData& draw_dispatch_data)
{
   TraceDrawCallData trace_draw_call_data;

#if 1
   trace_draw_call_data.pipeline_handle = pipeline_handle;
#else
   trace_draw_call_data.shader_hashes = shader_hash;
   trace_draw_call_data.pipeline_handles.push_back(pipeline_handle);
#endif

   trace_draw_call_data.command_list = native_device_context;

   // Note that the pipelines can be run more than once so this will return the first one matching (there's only one actually, we don't have separate settings for their running instance, as that's runtime stuff)
   const auto pipeline_pair = device_data.pipeline_cache_by_pipeline_handle.find(pipeline_handle);
   const bool is_valid = pipeline_pair != device_data.pipeline_cache_by_pipeline_handle.end() && pipeline_pair->second != nullptr;
   if (is_valid)
   {
      // Expose if needed
      constexpr bool show_unused_bound_resources = false; // If a resource is bound but not read/written to by the shader (this often happens with SRVs and UAVs, rarely with RTVs, given they almost 1:1 match with the shader)
      constexpr bool show_used_unbound_resources = true; // If a resource is not bound (null) but it is read/written to by the shader (which will result in black on read, and nothing on writes)

      const auto pipeline = pipeline_pair->second;
      const CachedShader* cached_shader = (!pipeline->shader_hashes.empty() && shader_cache.contains(pipeline->shader_hashes[0])) ? shader_cache[pipeline->shader_hashes[0]] : nullptr; // DX10/11 exclusive behaviour
      assert(cached_shader);
      if (pipeline->HasPixelShader())
      {
         UINT scissor_viewport_num = 0;
         native_device_context->RSGetScissorRects(&scissor_viewport_num, nullptr); // This will get the number of scissor rects used
         UINT scissor_viewport_num_max = min(scissor_viewport_num, 1);
         D3D11_RECT scissor_rects;
         native_device_context->RSGetScissorRects(&scissor_viewport_num_max, &scissor_rects); // This is useless
         if (scissor_viewport_num_max >= 1)
         {
            trace_draw_call_data.scissors = true;
         }

         native_device_context->RSGetViewports(&scissor_viewport_num, nullptr); // This will get the number of viewports used
         scissor_viewport_num_max = min(scissor_viewport_num, 1);
         D3D11_VIEWPORT viewport;
         native_device_context->RSGetViewports(&scissor_viewport_num_max, &viewport);
         if (scissor_viewport_num_max >= 1)
         {
            trace_draw_call_data.viewport_0 = { viewport.TopLeftX, viewport.TopLeftY, viewport.Width, viewport.Height };
         }

         com_ptr<ID3D11RenderTargetView> rtvs[D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT];
         com_ptr<ID3D11UnorderedAccessView> uavs[D3D11_1_UAV_SLOT_COUNT];
         com_ptr<ID3D11DepthStencilView> dsv;
         native_device_context->OMGetRenderTargetsAndUnorderedAccessViews(D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT, &rtvs[0], &dsv, 0, device_data.uav_max_count, &uavs[0]);

         com_ptr<ID3D11DepthStencilState> depth_stencil_state;
         native_device_context->OMGetDepthStencilState(&depth_stencil_state, nullptr);
         if (depth_stencil_state)
         {
            D3D11_DEPTH_STENCIL_DESC depth_stencil_desc;
            depth_stencil_state->GetDesc(&depth_stencil_desc);
            if (depth_stencil_desc.DepthEnable)
            {
               if (dsv.get())
               {
                  if (depth_stencil_desc.DepthWriteMask == D3D11_DEPTH_WRITE_MASK_ZERO)
                  {
                     // For now we ignore the "D3D11_COMPARISON_NEVER" as realistically it should never be used
                     if (depth_stencil_desc.DepthFunc != D3D11_COMPARISON_ALWAYS)
                     {
                        trace_draw_call_data.depth_state = TraceDrawCallData::DepthStateType::TestOnly;
                     }
                     // We neither read nor write the depth, so it's essentially disabled
                     else
                     {
                        trace_draw_call_data.depth_state = TraceDrawCallData::DepthStateType::Disabled;
                     }
                  }
                  else //if (depth_stencil_desc.DepthWriteMask == D3D11_DEPTH_WRITE_MASK_ALL) // Implied
                  {
                     if (depth_stencil_desc.DepthFunc != D3D11_COMPARISON_ALWAYS)
                     {
                        trace_draw_call_data.depth_state = TraceDrawCallData::DepthStateType::TestAndWrite;
                     }
                     else
                     {
                        trace_draw_call_data.depth_state = TraceDrawCallData::DepthStateType::WriteOnly;
                     }
                  }
               }
               // Depth texture is missing, unknown consequence
               else
               {
                  trace_draw_call_data.depth_state = TraceDrawCallData::DepthStateType::Invalid;
               }
            }

            trace_draw_call_data.stencil_enabled = depth_stencil_desc.StencilEnable && dsv.get(); // TODO: do better states for it

            if (trace_draw_call_data.depth_state != TraceDrawCallData::DepthStateType::Disabled && trace_draw_call_data.depth_state != TraceDrawCallData::DepthStateType::Invalid)
            {
               D3D11_DEPTH_STENCIL_VIEW_DESC dsv_desc;
               dsv->GetDesc(&dsv_desc);
               trace_draw_call_data.dsv_format = dsv_desc.Format;
               ASSERT_ONCE(dsv_desc.Format != DXGI_FORMAT_UNKNOWN); // Unexpected?
               com_ptr<ID3D11Resource> ds_resource;
               dsv->GetResource(&ds_resource);
               uint4 ds_size = {};
               GetResourceInfo(ds_resource.get(), ds_size, trace_draw_call_data.ds_format, nullptr, &trace_draw_call_data.ds_hash, &trace_draw_call_data.ds_debug_name);
               trace_draw_call_data.ds_size.x = ds_size.x;
               trace_draw_call_data.ds_size.y = ds_size.y;
            }
         }

         com_ptr<ID3D11BlendState> blend_state;
         native_device_context->OMGetBlendState(&blend_state, nullptr, nullptr);
         if (blend_state)
         {
            D3D11_BLEND_DESC blend_desc;
            blend_state->GetDesc(&blend_desc);
            // We always cache the last one used by the pipeline, hopefully it didn't change between draw calls
            trace_draw_call_data.blend_desc = blend_desc;
            // We don't care for the alpha blend operation (source alpha * dest alpha) as alpha is never read back from destination
         }

         for (UINT i = 0; i < D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT; i++)
         {
            if ((rtvs[i] != nullptr || (show_used_unbound_resources && cached_shader->rtvs[i])) && (show_unused_bound_resources || cached_shader->rtvs[i]))
            {
               trace_draw_call_data.rtvs[i] = rtvs[i].get();

               D3D11_RENDER_TARGET_VIEW_DESC rtv_desc = {};
               rtv_desc.Format = DXGI_FORMAT(-1);
               if (rtvs[i])
               {
                  rtvs[i]->GetDesc(&rtv_desc);
                  ASSERT_ONCE(rtv_desc.Format != DXGI_FORMAT_UNKNOWN); // Unexpected?
               }
               trace_draw_call_data.rtv_format[i] = rtv_desc.Format;
               com_ptr<ID3D11Resource> rt_resource;
               if (rtvs[i])
               {
                  rtvs[i]->GetResource(&rt_resource);
                  ASSERT_ONCE(rt_resource != nullptr); // Could happen
               }
               if (rt_resource)
               {
                  // If any of the set RTs are the swapchain, set it to true
                  trace_draw_call_data.rt_is_swapchain[i] |= device_data.back_buffers.contains((uint64_t)rt_resource.get());
                  GetResourceInfo(rt_resource.get(), trace_draw_call_data.rt_size[i], trace_draw_call_data.rt_format[i], &trace_draw_call_data.rt_type_name[i], &trace_draw_call_data.rt_hash[i], &trace_draw_call_data.rt_debug_name[i]);
                  
                  trace_draw_call_data.rtv_mip[i] = GetRTVMipLevel(rtv_desc);
                  uint3 base_size = uint3{ trace_draw_call_data.rt_size[i].x, trace_draw_call_data.rt_size[i].y, trace_draw_call_data.rt_size[i].z };
                  trace_draw_call_data.rtv_size[i] = GetTextureMipSize(base_size, trace_draw_call_data.rtv_mip[i]);
               }
            }
         }
         // These would likely get ignored if they weren't set, so clear them
         if (!dsv)
         {
            trace_draw_call_data.depth_state = TraceDrawCallData::DepthStateType::Disabled;
            trace_draw_call_data.stencil_enabled = false;
         }
         for (UINT i = 0; i < device_data.uav_max_count; i++)
         {
            if ((uavs[i] != nullptr || (show_used_unbound_resources && cached_shader->uavs[i])) && (show_unused_bound_resources || cached_shader->uavs[i]))
            {
               trace_draw_call_data.uavs[i] = uavs[i].get();

               D3D11_UNORDERED_ACCESS_VIEW_DESC uav_desc = {};
               uav_desc.Format = DXGI_FORMAT(-1);
               if (uavs[i]) uavs[i]->GetDesc(&uav_desc);
               trace_draw_call_data.uav_format[i] = uav_desc.Format;

               GetResourceInfo(uavs[i].get(), trace_draw_call_data.ua_size[i], trace_draw_call_data.ua_format[i], &trace_draw_call_data.ua_type_name[i], &trace_draw_call_data.ua_hash[i], &trace_draw_call_data.ua_debug_name[i], &trace_draw_call_data.ua_is_rt[i]);
               
               trace_draw_call_data.uav_mip[i] = GetUAVMipLevel(uav_desc);
               uint3 base_size = uint3{ trace_draw_call_data.ua_size[i].x, trace_draw_call_data.ua_size[i].y, trace_draw_call_data.ua_size[i].z };
               trace_draw_call_data.uav_size[i] = GetTextureMipSize(base_size, trace_draw_call_data.uav_mip[i]);
            }
         }

         com_ptr<ID3D11ShaderResourceView> srvs[D3D11_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT];
         native_device_context->PSGetShaderResources(0, D3D11_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT, &srvs[0]);
         for (UINT i = 0; i < D3D11_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT; i++)
         {
            if ((srvs[i] != nullptr || (show_used_unbound_resources && cached_shader->srvs[i])) && (show_unused_bound_resources || cached_shader->srvs[i]))
            {
               trace_draw_call_data.srvs[i] = srvs[i].get();

               D3D11_SHADER_RESOURCE_VIEW_DESC srv_desc = {};
               srv_desc.Format = DXGI_FORMAT(-1);
               if (srvs[i]) srvs[i]->GetDesc(&srv_desc);
               trace_draw_call_data.srv_format[i] = srv_desc.Format;

               GetResourceInfo(srvs[i].get(), trace_draw_call_data.sr_size[i], trace_draw_call_data.sr_format[i], &trace_draw_call_data.sr_type_name[i], &trace_draw_call_data.sr_hash[i], &trace_draw_call_data.sr_debug_name[i], &trace_draw_call_data.sr_is_rt[i], &trace_draw_call_data.sr_is_ua[i]);

               trace_draw_call_data.srv_mip[i] = GetSRVMipLevel(srv_desc);
               uint3 base_size = uint3{ trace_draw_call_data.sr_size[i].x, trace_draw_call_data.sr_size[i].y, trace_draw_call_data.sr_size[i].z };
               trace_draw_call_data.srv_size[i] = GetTextureMipSize(base_size, trace_draw_call_data.srv_mip[i]);
            }
         }
      }
      else if (pipeline->HasVertexShader())
      {
         com_ptr<ID3D11ShaderResourceView> srvs[D3D11_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT];
         native_device_context->VSGetShaderResources(0, D3D11_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT, &srvs[0]);
         for (UINT i = 0; i < D3D11_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT; i++)
         {
            if ((srvs[i] != nullptr || (show_used_unbound_resources && cached_shader->srvs[i])) && (show_unused_bound_resources || cached_shader->srvs[i]))
            {
               trace_draw_call_data.srvs[i] = srvs[i].get();

               D3D11_SHADER_RESOURCE_VIEW_DESC srv_desc = {};
               srv_desc.Format = DXGI_FORMAT(-1);
               if (srvs[i]) srvs[i]->GetDesc(&srv_desc);
               trace_draw_call_data.srv_format[i] = srv_desc.Format;

               GetResourceInfo(srvs[i].get(), trace_draw_call_data.sr_size[i], trace_draw_call_data.sr_format[i], &trace_draw_call_data.sr_type_name[i], &trace_draw_call_data.sr_hash[i], &trace_draw_call_data.sr_debug_name[i], &trace_draw_call_data.sr_is_rt[i], &trace_draw_call_data.sr_is_ua[i]);

               trace_draw_call_data.srv_mip[i] = GetSRVMipLevel(srv_desc);
               uint3 base_size = uint3{ trace_draw_call_data.sr_size[i].x, trace_draw_call_data.sr_size[i].y, trace_draw_call_data.sr_size[i].z };
               trace_draw_call_data.srv_size[i] = GetTextureMipSize(base_size, trace_draw_call_data.srv_mip[i]);
            }
         }

         trace_draw_call_data.draw_dispatch_data = draw_dispatch_data;

         com_ptr<ID3D11Buffer> index_buffer;
         native_device_context->IAGetIndexBuffer(&index_buffer, &trace_draw_call_data.index_buffer_format, &trace_draw_call_data.index_buffer_offset);
         com_ptr<ID3D11InputLayout> input_layout;
         native_device_context->IAGetInputLayout(&input_layout);

         trace_draw_call_data.index_buffer_hash = std::to_string(std::hash<void*>{}(index_buffer.get()));
         trace_draw_call_data.input_layout_hash = std::to_string(std::hash<void*>{}(input_layout.get()));

         //TODOFT5: do multiple of these! And print more data, and find the right vertex buffer
         if (input_layouts_descs.contains(input_layout.get()))
         {
            const auto& input_elements_descs = input_layouts_descs.find(input_layout.get());
            for (size_t i = 0; i < input_elements_descs->second.size(); i++)
            {
               com_ptr<ID3D11Buffer> vertex_buffer;
               trace_draw_call_data.input_layouts_formats.push_back(input_elements_descs->second.at(i).Format);
               native_device_context->IAGetVertexBuffers(input_elements_descs->second.at(i).InputSlot, 1, &vertex_buffer, nullptr, nullptr);
               trace_draw_call_data.vertex_buffer_hashes.push_back(std::to_string(std::hash<void*>{}(vertex_buffer.get())));
            }
         }

         native_device_context->IAGetPrimitiveTopology(&trace_draw_call_data.primitive_topology);
      }
      else if (pipeline->HasComputeShader())
      {
         com_ptr<ID3D11ShaderResourceView> srvs[D3D11_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT];
         native_device_context->CSGetShaderResources(0, D3D11_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT, &srvs[0]);
         for (UINT i = 0; i < D3D11_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT; i++)
         {
            if ((srvs[i] != nullptr || (show_used_unbound_resources && cached_shader->srvs[i])) && (show_unused_bound_resources || cached_shader->srvs[i]))
            {
               trace_draw_call_data.srvs[i] = srvs[i].get();

               D3D11_SHADER_RESOURCE_VIEW_DESC srv_desc = {};
               srv_desc.Format = DXGI_FORMAT(-1);
               if (srvs[i]) srvs[i]->GetDesc(&srv_desc);
               trace_draw_call_data.srv_format[i] = srv_desc.Format;

               GetResourceInfo(srvs[i].get(), trace_draw_call_data.sr_size[i], trace_draw_call_data.sr_format[i], &trace_draw_call_data.sr_type_name[i], &trace_draw_call_data.sr_hash[i], &trace_draw_call_data.sr_debug_name[i], &trace_draw_call_data.sr_is_rt[i], &trace_draw_call_data.sr_is_ua[i]);

               trace_draw_call_data.srv_mip[i] = GetSRVMipLevel(srv_desc);
               uint3 base_size = uint3{ trace_draw_call_data.sr_size[i].x, trace_draw_call_data.sr_size[i].y, trace_draw_call_data.sr_size[i].z };
               trace_draw_call_data.srv_size[i] = GetTextureMipSize(base_size, trace_draw_call_data.srv_mip[i]);
            }
         }

         com_ptr<ID3D11UnorderedAccessView> uavs[D3D11_1_UAV_SLOT_COUNT];
         native_device_context->CSGetUnorderedAccessViews(0, device_data.uav_max_count, &uavs[0]);
         for (UINT i = 0; i < device_data.uav_max_count; i++)
         {
            if ((uavs[i] != nullptr || (show_used_unbound_resources && cached_shader->uavs[i])) && (show_unused_bound_resources || cached_shader->uavs[i]))
            {
               trace_draw_call_data.srvs[i] = srvs[i].get();

               D3D11_UNORDERED_ACCESS_VIEW_DESC uav_desc = {};
               uav_desc.Format = DXGI_FORMAT(-1);
               if (uavs[i]) uavs[i]->GetDesc(&uav_desc);
               trace_draw_call_data.uav_format[i] = uav_desc.Format;

               GetResourceInfo(uavs[i].get(), trace_draw_call_data.ua_size[i], trace_draw_call_data.ua_format[i], &trace_draw_call_data.ua_type_name[i], &trace_draw_call_data.ua_hash[i], &trace_draw_call_data.ua_debug_name[i], &trace_draw_call_data.ua_is_rt[i]);

               trace_draw_call_data.uav_mip[i] = GetUAVMipLevel(uav_desc);
               uint3 base_size = uint3{ trace_draw_call_data.ua_size[i].x, trace_draw_call_data.ua_size[i].y, trace_draw_call_data.ua_size[i].z };
               trace_draw_call_data.uav_size[i] = GetTextureMipSize(base_size, trace_draw_call_data.uav_mip[i]);
            }
         }

         trace_draw_call_data.draw_dispatch_data = draw_dispatch_data;
      }
   }

   if (trace_draw_calls_data.capacity() - trace_draw_calls_data.size() <= 1)
      trace_draw_calls_data.reserve(trace_draw_calls_data.size() + 1000); // Possible optimization
   trace_draw_calls_data.push_back(trace_draw_call_data);
}
#endif

void DrawCustomPixelShader(ID3D11DeviceContext* device_context, ID3D11DepthStencilState* depth_stencil_state, ID3D11BlendState* blend_state, ID3D11VertexShader* vs, ID3D11PixelShader* ps, ID3D11ShaderResourceView* source_resource_texture_view, ID3D11RenderTargetView* target_resource_texture_view, UINT width, UINT height, bool alpha = true)
{
   // Set the new resources/states:
   constexpr FLOAT blend_factor_alpha[4] = { 1.f, 1.f, 1.f, 1.f };
   constexpr FLOAT blend_factor[4] = { 1.f, 1.f, 1.f, 0.f };
   device_context->OMSetBlendState(blend_state, alpha ? blend_factor_alpha : blend_factor, 0xFFFFFFFF);
   // Note: we don't seem to need to call (and cache+restore) IASetVertexBuffers() (at least not in Prey).
   // That's either because games always have vertices buffers set in there already, or because DX is tolerant enough (we are not seeing any etc errors in the DX log).
   device_context->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLESTRIP);
   device_context->RSSetScissorRects(0, nullptr); // Scissors are not needed
   D3D11_VIEWPORT viewport;
   viewport.TopLeftX = 0;
   viewport.TopLeftY = 0;
   viewport.Width = width;
   viewport.Height = height;
   viewport.MinDepth = 0;
   viewport.MaxDepth = 1;
   device_context->RSSetViewports(1, &viewport); // Viewport is always needed
   device_context->PSSetShaderResources(0, 1, &source_resource_texture_view);
   device_context->OMSetDepthStencilState(depth_stencil_state, 0);
   // TODO: add custom/default sampler here
   device_context->OMSetRenderTargets(1, &target_resource_texture_view, nullptr);
   device_context->VSSetShader(vs, nullptr, 0);
   device_context->PSSetShader(ps, nullptr, 0);
   device_context->IASetInputLayout(nullptr);
   device_context->RSSetState(nullptr);

#if DEVELOPMENT
   com_ptr<ID3D11GeometryShader> gs;
   device_context->GSGetShader(&gs, nullptr, 0);
   ASSERT_ONCE(!gs.get());
   com_ptr<ID3D11HullShader> hs;
   device_context->HSGetShader(&hs, nullptr, 0);
   ASSERT_ONCE(!hs.get());
#endif

   // Finally draw:
   device_context->Draw(4, 0);
}

// Sets the viewport to the full render target, useful to anticipate upscaling (before the game would have done it natively)
void SetViewportFullscreen(ID3D11DeviceContext* device_context, uint2 size = {})
{
   if (size == uint2{})
   {
      com_ptr<ID3D11RenderTargetView> render_target_view;
      device_context->OMGetRenderTargets(1, &render_target_view, nullptr);

#if DEVELOPMENT
      D3D11_RENDER_TARGET_VIEW_DESC render_target_view_desc;
      render_target_view->GetDesc(&render_target_view_desc);
      ASSERT_ONCE(render_target_view_desc.ViewDimension == D3D11_RTV_DIMENSION_TEXTURE2D); // This should always be the case
#endif // DEVELOPMENT

      D3D11_TEXTURE2D_DESC render_target_texture_2d_desc;
      com_ptr<ID3D11Resource> render_target_resource;
      render_target_view->GetResource(&render_target_resource);
      if (render_target_resource)
      {
         com_ptr<ID3D11Texture2D> render_target_texture_2d;
         HRESULT hr = render_target_resource->QueryInterface(&render_target_texture_2d);
         ASSERT_ONCE(SUCCEEDED(hr));
         if (render_target_texture_2d)
         {
            render_target_texture_2d->GetDesc(&render_target_texture_2d_desc);
         }
         else
         {
            return;
         }
      }
      else
      {
         return;
      }

#if DEVELOPMENT
      // Scissors are often set after viewports in games (e.g. Prey), so check them separately.
      // We need to make sure that all the draw calls after DLSS upscaling run at full resolution and not rendering resolution.
      com_ptr<ID3D11RasterizerState> state;
      device_context->RSGetState(&state);
      if (state.get())
      {
         D3D11_RASTERIZER_DESC state_desc;
         state->GetDesc(&state_desc);
         if (state_desc.ScissorEnable)
         {
            D3D11_RECT scissor_rects[D3D11_VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE];
            UINT scissor_rects_num = 0;
            // This will get the number of scissor rects used
            device_context->RSGetScissorRects(&scissor_rects_num, nullptr);
            ASSERT_ONCE(scissor_rects_num == 1); // Possibly innocuous as long as it's > 0, but we should only ever have one viewport and one RT!
            device_context->RSGetScissorRects(&scissor_rects_num, &scissor_rects[0]);

            // If this ever triggered, we'd need to replace scissors too after DLSS (and make them full resolution).
            ASSERT_ONCE(scissor_rects[0].left == 0 && scissor_rects[0].top == 0 && scissor_rects[0].right == render_target_texture_2d_desc.Width && scissor_rects[0].bottom == render_target_texture_2d_desc.Height);
         }
      }
#endif // DEVELOPMENT

      size.x = render_target_texture_2d_desc.Width;
      size.y = render_target_texture_2d_desc.Height;
   }

   D3D11_VIEWPORT viewports[D3D11_VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE];
   UINT viewports_num = 1;
   device_context->RSGetViewports(&viewports_num, nullptr);
   ASSERT_ONCE(viewports_num == 1); // Possibly innocuous as long as it's > 0, but we should only ever have one viewport and one RT!
   device_context->RSGetViewports(&viewports_num, &viewports[0]);
   for (uint32_t i = 0; i < viewports_num; i++)
   {
      viewports[i].Width = size.x;
      viewports[i].Height = size.y;
   }
   device_context->RSSetViewports(viewports_num, &viewports[0]);
}