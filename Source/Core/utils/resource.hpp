#pragma once

#if DEVELOPMENT
std::optional<std::string> GetD3DName(ID3D11DeviceChild* obj)
{
   if (obj == nullptr) return std::nullopt;

   byte data[128] = {};
   UINT size = sizeof(data);
   if (obj->GetPrivateData(WKPDID_D3DDebugObjectName, &size, data) == S_OK)
   {
      if (size > 0) return std::string{ data, data + size };
   }
   return std::nullopt;
}

// Wide string with normal string fallback
std::optional<std::string> GetD3DNameW(ID3D11DeviceChild* obj)
{
   if (obj == nullptr) return std::nullopt;

   byte data[128] = {};
   UINT size = sizeof(data);
   if (obj->GetPrivateData(WKPDID_D3DDebugObjectNameW, &size, data) == S_OK)
   {
      if (size > 0)
      {
         char c_name[128] = {};
         size_t out_size;
         // wide-character-string-to-multibyte-string_safe
         auto ret = wcstombs_s(&out_size, c_name, sizeof(c_name), reinterpret_cast<wchar_t*>(data), size);
         if (ret == 0 && out_size > 0)
         {
            return std::string(c_name, c_name + out_size);
         }
      }
   }
   return GetD3DName(obj);
}
#endif

void GetResourceInfo(ID3D11Resource* resource, uint4& size, DXGI_FORMAT& format, std::string* type_name = nullptr, std::string* hash = nullptr, bool* render_target_flag = nullptr)
{
   size = { };
   format = DXGI_FORMAT_UNKNOWN;
   if (type_name)
   {
      *type_name = "";
   }
   if (hash)
   {
      *hash = "";
   }
   if (render_target_flag)
   {
      *render_target_flag = false;
   }
   if (!resource) return;
   // Go in order of popularity
   com_ptr<ID3D11Texture2D> texture_2d;
   HRESULT hr = resource->QueryInterface(&texture_2d);
   if (SUCCEEDED(hr) && texture_2d)
   {
      D3D11_TEXTURE2D_DESC texture_2d_desc;
      texture_2d->GetDesc(&texture_2d_desc);
      size = uint4{ texture_2d_desc.Width, texture_2d_desc.Height, texture_2d_desc.ArraySize, texture_2d_desc.SampleDesc.Count == 1 ? texture_2d_desc.MipLevels : texture_2d_desc.SampleDesc.Count }; // MS textures can't have mips
      format = texture_2d_desc.Format;
      ASSERT_ONCE_MSG(format != DXGI_FORMAT_UNKNOWN, "Texture format unknown?");
      if (type_name)
      {
         *type_name = "Texture 2D";
         if (texture_2d_desc.SampleDesc.Count != 1)
         {
            *type_name = "Texture 1D MS";
            if (texture_2d_desc.ArraySize != 1)
            {
               *type_name = "Texture 1D MS Array";
            }
         }
         else if (texture_2d_desc.ArraySize != 1)
         {
            *type_name = "Texture 1D Array";
            if (texture_2d_desc.ArraySize == 6 && (texture_2d_desc.MiscFlags & D3D11_RESOURCE_MISC_TEXTURECUBE) != 0)
            {
               *type_name = "Texture 1D Cube";
            }
         }
      }
      if (hash)
      {
         *hash = std::to_string(std::hash<void*>{}(resource));
      }
      if (render_target_flag)
      {
         *render_target_flag = (texture_2d_desc.BindFlags & D3D11_BIND_RENDER_TARGET) != 0;
      }
      return;
   }
   com_ptr<ID3D11Texture3D> texture_3d;
   hr = resource->QueryInterface(&texture_3d);
   if (SUCCEEDED(hr) && texture_3d)
   {
      D3D11_TEXTURE3D_DESC texture_3d_desc;
      texture_3d->GetDesc(&texture_3d_desc);
      size = uint4{ texture_3d_desc.Width, texture_3d_desc.Height, texture_3d_desc.Depth, texture_3d_desc.MipLevels };
      format = texture_3d_desc.Format;
      ASSERT_ONCE_MSG(format != DXGI_FORMAT_UNKNOWN, "Texture format unknown?");
      if (type_name)
      {
         *type_name = "Texture 3D";
      }
      if (hash)
      {
         *hash = std::to_string(std::hash<void*>{}(resource));
      }
      if (render_target_flag)
      {
         *render_target_flag = (texture_3d_desc.BindFlags & D3D11_BIND_RENDER_TARGET) != 0;
      }
      return;
   }
   com_ptr<ID3D11Texture1D> texture_1d;
   hr = resource->QueryInterface(&texture_1d);
   if (SUCCEEDED(hr) && texture_1d)
   {
      D3D11_TEXTURE1D_DESC texture_1d_desc;
      texture_1d->GetDesc(&texture_1d_desc);
      size = uint4{ texture_1d_desc.Width, texture_1d_desc.ArraySize, 1, texture_1d_desc.MipLevels };
      format = texture_1d_desc.Format;
      ASSERT_ONCE_MSG(format != DXGI_FORMAT_UNKNOWN, "Texture format unknown?");
      if (type_name)
      {
         *type_name = "Texture 1D";
         if (texture_1d_desc.ArraySize != 1)
         {
            *type_name = "Texture 1D Array";
         }
      }
      if (hash)
      {
         *hash = std::to_string(std::hash<void*>{}(resource));
      }
      if (render_target_flag)
      {
         *render_target_flag = (texture_1d_desc.BindFlags & D3D11_BIND_RENDER_TARGET) != 0;
      }
      return;
   }
   com_ptr<ID3D11Buffer> buffer;
   hr = resource->QueryInterface(&buffer);
   if (SUCCEEDED(hr) && buffer)
   {
      D3D11_BUFFER_DESC buffer_desc;
      buffer->GetDesc(&buffer_desc);
      size = uint4{ buffer_desc.ByteWidth, 0, 0, 0 }; // A bit random, but it shall work
      if (type_name)
      {
         *type_name = "Buffer"; // This exact name might be assumed elsewhere, scan the code before changing it
      }
      if (hash)
      {
         *hash = std::to_string(std::hash<void*>{}(resource));
      }
      if (render_target_flag)
      {
         *render_target_flag = false; // Implied by being a buffer!
      }
      return;
   }
   ASSERT_ONCE_MSG(false, "Unknwon texture type");
}
void GetResourceInfo(ID3D11View* view, uint4& size, DXGI_FORMAT& format, std::string* type_name = nullptr, std::string* hash = nullptr, bool* render_target_flag = nullptr)
{
   if (!view)
   {
      GetResourceInfo((ID3D11Resource*)nullptr, size, format, type_name, hash, render_target_flag);
      return;
   }
   // Note that specific cast views have a desc that could tell us the resource type
   com_ptr<ID3D11Resource> view_resource;
   view->GetResource(&view_resource);
   return GetResourceInfo(view_resource.get(), size, format, type_name, hash, render_target_flag);
}

// Note: this is a bit approximate!
bool AreResourcesEqual(ID3D11Resource* resource1, ID3D11Resource* resource2, bool check_format = true)
{
	uint4 size1, size2;
	DXGI_FORMAT format1, format2;
	GetResourceInfo(resource1, size1, format1);
	GetResourceInfo(resource2, size2, format2);
	return size1 == size2 && (!check_format || format1 == format2);
}

template<typename T>
using D3D11_RESOURCE_DESC = std::conditional_t<typeid(T) == typeid(ID3D11Texture2D), D3D11_TEXTURE2D_DESC, std::conditional_t<typeid(T) == typeid(ID3D11Texture3D), D3D11_TEXTURE3D_DESC, D3D11_TEXTURE1D_DESC>>;

template<typename T = ID3D11Resource>
com_ptr<T> CloneTexture(ID3D11Device* native_device, ID3D11Resource* texture_resource, DXGI_FORMAT overridden_format = DXGI_FORMAT_UNKNOWN, UINT add_bind_flags = (D3D11_BIND_SHADER_RESOURCE | D3D11_BIND_RENDER_TARGET), UINT remove_bind_flags = 0, bool black_initial_data = false, bool copy_data = true, ID3D11DeviceContext* native_device_context = nullptr)
{
   com_ptr<T> cloned_resource;
   ASSERT_ONCE(texture_resource);
   if (texture_resource)
   {
      com_ptr<T> texture;
      HRESULT hr = texture_resource->QueryInterface(&texture);
      if (SUCCEEDED(hr) && texture)
      {
         D3D11_RESOURCE_DESC<T> texture_desc;
         if constexpr (typeid(T) == typeid(ID3D11Texture2D) || typeid(T) == typeid(ID3D11Texture3D) || typeid(T) == typeid(ID3D11Texture1D))
         {
            texture->GetDesc(&texture_desc);
         }
         else
         {
            static_assert(false, "Clone Resource Type not supported");
         }

         if (overridden_format != DXGI_FORMAT_UNKNOWN)
         {
            texture_desc.Format = overridden_format;
         }
         texture_desc.BindFlags |= add_bind_flags;
         texture_desc.BindFlags &= ~remove_bind_flags;
         // Hack to clear unwanted flags
         if ((add_bind_flags & (D3D11_BIND_SHADER_RESOURCE | D3D11_BIND_RENDER_TARGET)) != 0)
         {
            ASSERT_ONCE(texture_desc.Usage == 0 && texture_desc.CPUAccessFlags == 0);
            texture_desc.Usage = D3D11_USAGE_DEFAULT;
            texture_desc.CPUAccessFlags = 0;
         }
         bool is_ms = false;
         if constexpr (typeid(T) == typeid(ID3D11Texture2D))
         {
            is_ms = texture_desc.SampleDesc.Count != 1;
         }

         D3D11_SUBRESOURCE_DATA initial_data = {};
         uint8_t* data = nullptr;
         // Initial data isn't supported on MSAA textures
         if (black_initial_data && !is_ms)
         {
            ASSERT_ONCE_MSG(texture_desc.MipLevels != 1, "We only define the initial data for the first mip, the rest will be uncleared memory");

            uint8_t channels = 0;
            uint8_t bits_per_channel = 0;
            const bool supported_format = GetFormatSizeInfo(texture_desc.Format, channels, bits_per_channel);

            if (supported_format)
            {
               // Mips are not included in the initial data
               UINT width, height, depth;
               if constexpr (typeid(T) == typeid(ID3D11Texture2D))
               {
                  width = texture_desc.Width;
                  height = texture_desc.Height;
                  depth = texture_desc.ArraySize;
               }
               else if constexpr (typeid(T) == typeid(ID3D11Texture3D))
               {
                  width = texture_desc.Width;
                  height = texture_desc.Height;
                  depth = texture_desc.Depth;
               }
               else if constexpr (typeid(T) == typeid(ID3D11Texture1D))
               {
                  width = texture_desc.Width;
                  height = 1;
                  depth = 1;
               }

               if (bits_per_channel == 8)
               {
                  data = (uint8_t*)malloc(width * height * depth * channels * sizeof(uint8_t));
                  for (int i = 0; i < width * height * depth * channels; i++)
                  {
                     data[i] = (uint8_t)0;
                  }
               }
               else if (bits_per_channel == 16)
               {
                  uint16_t* data_16 = nullptr;
                  data_16 = (uint16_t*)malloc(width * height * depth * channels * sizeof(uint16_t));
                  for (int i = 0; i < width * height * depth * channels; i++)
                  {
                     data_16[i] = (uint16_t)0;
                  }
                  data = (uint8_t*)data_16;
               }
               ASSERT_ONCE(bits_per_channel % 8 == 0);

               initial_data.pSysMem = data;
               if constexpr (typeid(T) == typeid(ID3D11Texture2D))
               {
                  initial_data.SysMemPitch = texture_desc.Width * channels * (bits_per_channel / 8); // Width * bytes per pixel
                  initial_data.SysMemSlicePitch = initial_data.SysMemPitch * texture_desc.Height; // Pitch * Height
               }
               else if constexpr (typeid(T) == typeid(ID3D11Texture3D))
               {
                  initial_data.SysMemPitch = texture_desc.Width * channels * (bits_per_channel / 8);
                  initial_data.SysMemSlicePitch = initial_data.SysMemPitch * texture_desc.Height;
               }
               else if constexpr (typeid(T) == typeid(ID3D11Texture1D))
               {
                  initial_data.SysMemPitch = texture_desc.Width * channels * (bits_per_channel / 8);
                  initial_data.SysMemSlicePitch = 0;
               }
            }
         }

         if constexpr (typeid(T) == typeid(ID3D11Texture2D))
         {
            hr = native_device->CreateTexture2D(&texture_desc, black_initial_data ? &initial_data : nullptr, &cloned_resource);
         }
         else if constexpr (typeid(T) == typeid(ID3D11Texture3D))
         {
            hr = native_device->CreateTexture3D(&texture_desc, black_initial_data ? &initial_data : nullptr, &cloned_resource);
         }
         else if constexpr (typeid(T) == typeid(ID3D11Texture1D))
         {
            hr = native_device->CreateTexture1D(&texture_desc, black_initial_data ? &initial_data : nullptr, &cloned_resource);
         }
         ASSERT_ONCE(SUCCEEDED(hr));

         if (black_initial_data)
         {
            delete data; data = nullptr;
         }

         if (copy_data && SUCCEEDED(hr) && cloned_resource.get())
         {
            assert(native_device_context);
            native_device_context->CopyResource(cloned_resource.get(), texture_resource);
         }
      }
   }
   return cloned_resource;
}

#if DEVELOPMENT
// Needs to match in shader
enum class DebugDrawTextureOptionsMask : uint32_t
{
   None = 0,
   Fullscreen = 1 << 0,
   RenderResolutionScale = 1 << 1,
   ShowAlpha = 1 << 2,
   PreMultiplyAlpha = 1 << 3,
   InvertColors = 1 << 4,
   LinearToGamma = 1 << 5,
   GammaToLinear = 1 << 6,
   FlipY = 1 << 7,
   Saturate = 1 << 8,
   RedOnly = 1 << 9,
   BackgroundPassthrough = 1 << 10,
   TextureMultiSample = 1 << 11,
   TextureArray = 1 << 12,
   // If this is true and Texture3D is also true, the texture is a cube. If both are false it's 1D.
   Texture2D = 1 << 13,
   Texture3D = 1 << 14,
};
// If true we are drawing the render target texture, otherwise the shader resource texture
enum class DebugDrawMode : uint32_t
{
   RenderTarget,
   UnorderedAccessView,
   ShaderResource,
   Depth,
};
static constexpr const char* debug_draw_mode_strings[] = {
    "Render Target",
    "Unordered Access View",
    "Shader Resource",
    "Depth",
};

bool CopyDebugDrawTexture(DebugDrawMode debug_draw_mode, int32_t debug_draw_view_index, reshade::api::command_list* cmd_list, bool is_dispatch /*= false*/)
{
   ID3D11Device* native_device = (ID3D11Device*)(cmd_list->get_device()->get_native());
   ID3D11DeviceContext* native_device_context = (ID3D11DeviceContext*)(cmd_list->get_native());
   DeviceData& device_data = *cmd_list->get_device()->get_private_data<DeviceData>();

   com_ptr<ID3D11Resource> texture_resource;
   if (debug_draw_mode == DebugDrawMode::RenderTarget || debug_draw_mode == DebugDrawMode::Depth)
   {
      com_ptr<ID3D11RenderTargetView> rtvs[D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT];
      com_ptr<ID3D11DepthStencilView> dsv;
      native_device_context->OMGetRenderTargets(D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT, &rtvs[0], &dsv);

      if (debug_draw_mode == DebugDrawMode::RenderTarget)
      {
         com_ptr<ID3D11RenderTargetView> rtv = rtvs[debug_draw_view_index];
         if (rtv)
         {
            rtv->GetResource(&texture_resource);
            GetResourceInfo(texture_resource.get(), device_data.debug_draw_texture_size, device_data.debug_draw_texture_format); // Note: this isn't synchronized with the conditions that update "debug_draw_texture" below but it should work anyway
            D3D11_RENDER_TARGET_VIEW_DESC rtv_desc;
            rtv->GetDesc(&rtv_desc);
            device_data.debug_draw_texture_format = rtv_desc.Format;
         }
      }
      else if (dsv) // DebugDrawMode::Depth
      {
         dsv->GetResource(&texture_resource);
         GetResourceInfo(texture_resource.get(), device_data.debug_draw_texture_size, device_data.debug_draw_texture_format);
         D3D11_DEPTH_STENCIL_VIEW_DESC dsv_desc;
         dsv->GetDesc(&dsv_desc);
         // Note: this format might be exclusive to DSVs and not work with SRVs, so we adjust it
         device_data.debug_draw_texture_format = dsv_desc.Format;
         switch (device_data.debug_draw_texture_format)
         {
         case DXGI_FORMAT_D16_UNORM:
         {
            device_data.debug_draw_texture_format = DXGI_FORMAT_R16_UNORM;
         }
         break;
         case DXGI_FORMAT_D24_UNORM_S8_UINT:
         {
            device_data.debug_draw_texture_format = DXGI_FORMAT_R24_UNORM_X8_TYPELESS;
         }
         break;
         case DXGI_FORMAT_D32_FLOAT:
         {
            device_data.debug_draw_texture_format = DXGI_FORMAT_R32_FLOAT;
         }
         break;
         case DXGI_FORMAT_D32_FLOAT_S8X24_UINT:
         {
            device_data.debug_draw_texture_format = DXGI_FORMAT_R32_FLOAT_X8X24_TYPELESS;
         }
         break;
         }
      }
   }
   else if (debug_draw_mode == DebugDrawMode::UnorderedAccessView)
   {
      com_ptr<ID3D11UnorderedAccessView> unordered_access_view;

      com_ptr<ID3D11UnorderedAccessView> uavs[D3D11_1_UAV_SLOT_COUNT];
      // Not sure there's a difference between these two but probably the second one is just meant for pixel shader draw calls
      if (is_dispatch)
      {
         native_device_context->CSGetUnorderedAccessViews(0, device_data.uav_max_count, &uavs[0]);
      }
      else
      {
         native_device_context->OMGetRenderTargetsAndUnorderedAccessViews(0, nullptr, nullptr, 0, device_data.uav_max_count, &uavs[0]);
      }

      unordered_access_view = uavs[debug_draw_view_index];

      if (unordered_access_view)
      {
         unordered_access_view->GetResource(&texture_resource);
         GetResourceInfo(texture_resource.get(), device_data.debug_draw_texture_size, device_data.debug_draw_texture_format);
         D3D11_UNORDERED_ACCESS_VIEW_DESC uav_desc;
         unordered_access_view->GetDesc(&uav_desc);
         device_data.debug_draw_texture_format = uav_desc.Format; // Note: this isn't synchronized with the conditions that update "debug_draw_texture" below but it should work anyway
      }
   }
   else /*if (debug_draw_mode == DebugDrawMode::ShaderResource)*/
   {
      com_ptr<ID3D11ShaderResourceView> shader_resource_view;
      // Note: these might assert if you query an invalid index (there's no way of knowing it without tracking the previous sets)
      if (is_dispatch)
      {
         native_device_context->CSGetShaderResources(debug_draw_view_index, 1, &shader_resource_view);
      }
      else
      {
         native_device_context->PSGetShaderResources(debug_draw_view_index, 1, &shader_resource_view);
      }
      if (shader_resource_view)
      {
         shader_resource_view->GetResource(&texture_resource);
         GetResourceInfo(texture_resource.get(), device_data.debug_draw_texture_size, device_data.debug_draw_texture_format);
         D3D11_SHADER_RESOURCE_VIEW_DESC srv_desc;
         shader_resource_view->GetDesc(&srv_desc);
         device_data.debug_draw_texture_format = srv_desc.Format;
      }
   }

   device_data.debug_draw_texture = nullptr; // Always clear it, even if the new creation failed
   if (texture_resource)
   {
      com_ptr<ID3D11Texture2D> texture_2d;
      texture_resource->QueryInterface(&texture_2d);
      com_ptr<ID3D11Texture3D> texture_3d;
      texture_resource->QueryInterface(&texture_3d);
      com_ptr<ID3D11Texture1D> texture_1d;
      texture_resource->QueryInterface(&texture_1d);
      // For now we re-create it every frame as we don't care for performance
      HRESULT hr = E_FAIL;
      if (texture_2d)
      {
         D3D11_TEXTURE2D_DESC texture_desc;
         texture_2d->GetDesc(&texture_desc);
         ASSERT_ONCE_MSG((texture_desc.MiscFlags & D3D11_RESOURCE_MISC_TEXTURECUBE) != 0 || texture_desc.ArraySize != 6, "Texture Cube Debug Drawing is likely not supported");
         texture_desc.Usage = D3D11_USAGE_DEFAULT;
         texture_desc.CPUAccessFlags = 0;
         texture_desc.BindFlags = D3D11_BIND_SHADER_RESOURCE; // We don't need "D3D11_BIND_RENDER_TARGET" nor "D3D11_BIND_UNORDERED_ACCESS" for now
         texture_desc.MiscFlags &= ~D3D11_RESOURCE_MISC_GENERATE_MIPS;
         texture_desc.MiscFlags &= ~D3D11_RESOURCE_MISC_SHARED;
         texture_desc.MiscFlags &= ~D3D11_RESOURCE_MISC_TEXTURECUBE; // Remove the cube flag in an attempt to support it anyway as a 2D Array
         hr = native_device->CreateTexture2D(&texture_desc, nullptr, reinterpret_cast<ID3D11Texture2D**>(&device_data.debug_draw_texture)); // TODO: figure out error, happens sometimes. And make thread safe!
      }
      else if (texture_3d)
      {
         D3D11_TEXTURE3D_DESC texture_desc;
         texture_3d->GetDesc(&texture_desc);
         texture_desc.Usage = D3D11_USAGE_DEFAULT;
         texture_desc.CPUAccessFlags = 0;
         texture_desc.BindFlags = D3D11_BIND_SHADER_RESOURCE;
         texture_desc.MiscFlags &= ~D3D11_RESOURCE_MISC_GENERATE_MIPS;
         texture_desc.MiscFlags &= ~D3D11_RESOURCE_MISC_SHARED;
         hr = native_device->CreateTexture3D(&texture_desc, nullptr, reinterpret_cast<ID3D11Texture3D**>(&device_data.debug_draw_texture));
      }
      else if (texture_1d)
      {
         D3D11_TEXTURE1D_DESC texture_desc;
         texture_1d->GetDesc(&texture_desc);
         texture_desc.Usage = D3D11_USAGE_DEFAULT;
         texture_desc.CPUAccessFlags = 0;
         texture_desc.BindFlags = D3D11_BIND_SHADER_RESOURCE;
         texture_desc.MiscFlags &= ~D3D11_RESOURCE_MISC_GENERATE_MIPS;
         texture_desc.MiscFlags &= ~D3D11_RESOURCE_MISC_SHARED;
         hr = native_device->CreateTexture1D(&texture_desc, nullptr, reinterpret_cast<ID3D11Texture1D**>(&device_data.debug_draw_texture));
      }
      // Back it up as it gets immediately overwritten or re-used later
      if (SUCCEEDED(hr) && device_data.debug_draw_texture)
      {
         native_device_context->CopyResource(device_data.debug_draw_texture.get(), texture_resource.get());
         return true;
      }
      else
      {
         ASSERT_ONCE("Draw Debug: Target Texture is not 1D/2D/3D (???), or its creation failed");
      }
   }
   return false;
}

bool CopyBuffer(com_ptr<ID3D11Buffer> cb, ID3D11DeviceContext* native_device_context, std::vector<float>& buffer_data)
{
   if (cb.get() == nullptr)
   {
      buffer_data.clear();
      return false;
   }

   D3D11_BUFFER_DESC desc = {};
   cb->GetDesc(&desc);

   // Clone it if it can't be read by the CPU
   if ((desc.CPUAccessFlags & D3D11_CPU_ACCESS_READ) == 0 || desc.Usage != D3D11_USAGE_STAGING)
   {
      com_ptr<ID3D11Buffer> cb_copy;
      com_ptr<ID3D11Device> native_device;
      desc.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
      desc.Usage = D3D11_USAGE_STAGING;
      desc.BindFlags = 0;

      native_device_context->GetDevice(&native_device);
      HRESULT hr = native_device->CreateBuffer(&desc, nullptr, &cb_copy);
      if (FAILED(hr))
      {
         buffer_data.clear();
         ASSERT_ONCE(false);
         return false;
      }
      native_device_context->CopyResource(cb_copy.get(), cb.get());
      cb = cb_copy;
   }

   D3D11_MAPPED_SUBRESOURCE mapped = {};
   HRESULT hr = native_device_context->Map(cb.get(), 0, D3D11_MAP_READ, 0, &mapped);
   if (FAILED(hr))
   {
      buffer_data.clear();
      ASSERT_ONCE(false);
      return false;
   }

   bool remainder = desc.ByteWidth % sizeof(float) != 0;
   size_t num_floats = desc.ByteWidth / sizeof(float);
   buffer_data.resize(num_floats + (remainder ? 1 : 0)); // Add 1 for safety (the last value might be half trash
   if (remainder)
   {
      buffer_data[buffer_data.size() - 1] = 0.f; // Clear the last slot as it might not get fully copied
   }
   std::memcpy(buffer_data.data(), mapped.pData, desc.ByteWidth);

   native_device_context->Unmap(cb.get(), 0);
   return true;
}
#endif // DEVELOPMENT