#define GAME_DXHRDC 1

#define ENABLE_GAME_PIPELINE_STATE_READBACK 1
#define ENABLE_ORIGINAL_SHADERS_MEMORY_EDITS 1

#include "..\..\Core\core.hpp"

class GameDeusExHumanRevolutionDC final : public Game
{
public:
   void OnInit(bool async) override
   {
      luma_settings_cbuffer_index = 13;
      luma_data_cbuffer_index = 12; // ### Update this (find the right value) ###

      GetShaderDefineData(TEST_SDR_HDR_SPLIT_VIEW_MODE_NATIVE_IMPL_HASH).SetDefaultValue('1'); // The game was just clipping, so HDR is an unclipped extension of SDR

      // No gamma mismatch baked in the textures as the game never applied gamma, it was gamma from the beginning until the end (so we assume 2.2)
      GetShaderDefineData(GAMMA_CORRECTION_TYPE_HASH).SetDefaultValue('1');
      GetShaderDefineData(VANILLA_ENCODING_TYPE_HASH).SetDefaultValue('1');

      GetShaderDefineData(UI_DRAW_TYPE_HASH).SetDefaultValue('2');
   }

   void OnLoad(std::filesystem::path& file_path, bool failed) override
   {
      // Note: this code might try to apply multiple times as the ReShade addon gets loaded and unloaded, once is enough
      if (!failed)
      {
         HMODULE module_handle = GetModuleHandle(nullptr); // Handle to the current executable
         auto dos_header = reinterpret_cast<PIMAGE_DOS_HEADER>(module_handle);
         auto nt_headers = reinterpret_cast<PIMAGE_NT_HEADERS>(reinterpret_cast<std::byte*>(module_handle) + dos_header->e_lfanew);

         std::byte* base = reinterpret_cast<std::byte*>(module_handle);
         std::size_t section_size = nt_headers->OptionalHeader.SizeOfImage;

         // From pcgw. Unknown author.
         const std::vector<uint8_t> pattern_1 = {
            0x81, 0xFF, 0x00, 0x05, 0x00, 0x00, 0x7C, 0x05,
            0xBF, 0x00, 0x05, 0x00, 0x00, 0xDB, 0x44, 0x24
         };
         std::vector<std::byte*> pattern_1_addresses = System::ScanMemoryForPattern(base, section_size, pattern_1);

         const std::vector<uint8_t> pattern_2 = {
            0x81, 0xFE, 0x00, 0x05, 0x00, 0x00, 0x7D, 0x08,
            0x8B, 0xCE, 0x89, 0x74, 0x24, 0x20, 0xEB, 0x09,
            0xB9, 0x00, 0x05, 0x00, 0x00, 0x89, 0x4C, 0x24,
            0x20
         };
         std::vector<std::byte*> pattern_2_addresses = System::ScanMemoryForPattern(base, section_size, pattern_2);

         // The game's UI became tiny beyond 1280 horizontal resolutions, as the auto scaling,
         // (which would make it appear of the same size on the display) was limited to that, for some reason.
         // Skip this if the user already modded the executable.
         if (pattern_1_addresses.size() == 1 && pattern_2_addresses.size() == 1)
         {
            int screen_width = GetSystemMetrics(SM_CXSCREEN);
            int screen_height = GetSystemMetrics(SM_CYSCREEN);
            float screen_aspect_ratio = float(screen_width) / float(screen_height);
            // The game's UI is scaled based on what would be your horizontal resolution
            // if you screen was 16:9 (with its current vertical resolution as reference point).
            // Not sure how it calculates that, but tests make it seem like that's the behaviour.
            if (screen_aspect_ratio >= (16.f / 9.f))
            {
               screen_width = static_cast<int>(std::lround(screen_height * (16.0 / 9.0)));
            }

            // Replace the pattern with your own horizontal resolution.
            // As long as we are in 16:9, we could go as high as we want and it'd scale correctly, but in UW we need to set the right value or the UI will get huge.
            std::vector<uint8_t> pattern_1_patch = pattern_1;
            std::vector<uint8_t> pattern_2_patch = pattern_2;
            std::memcpy(&pattern_1_patch[2], &screen_width, sizeof(screen_width));
            std::memcpy(&pattern_1_patch[9], &screen_width, sizeof(screen_width));
            std::memcpy(&pattern_2_patch[2], &screen_width, sizeof(screen_width));
            std::memcpy(&pattern_2_patch[17], &screen_width, sizeof(screen_width));

            DWORD old_protect;
            BOOL success = VirtualProtect(pattern_1_addresses[0], pattern_1_patch.size(), PAGE_EXECUTE_READWRITE, &old_protect);
            if (success)
            {
               std::memcpy(pattern_1_addresses[0], pattern_1_patch.data(), pattern_1_patch.size());

               DWORD temp_protect;
               VirtualProtect(pattern_1_addresses[0], pattern_1_patch.size(), old_protect, &temp_protect);

               success = VirtualProtect(pattern_2_addresses[0], pattern_2_patch.size(), PAGE_EXECUTE_READWRITE, &old_protect);
               if (success)
               {
                  std::memcpy(pattern_2_addresses[0], pattern_2_patch.data(), pattern_2_patch.size());

                  VirtualProtect(pattern_2_addresses[0], pattern_2_patch.size(), old_protect, &temp_protect);
               }
            }
            ASSERT_ONCE(success);
         }
      }
   }

   // All materials color/lighting shaders in this game have a saturate at the end, that always gets bundled with a multiply+add instruction.
   // There's also luminance calculations for the alpha buffer, presumably for FXAA (in case it was used), or bloom (contained on alpha), but they were based of BT.601 instead of BT.709.
   // Given that there's possibly hundreds of them, we live patch them.
   std::unique_ptr<std::byte[]> ModifyShaderByteCode(const std::byte* code, size_t size, reshade::api::pipeline_subobject_type type) override
   {
      if (type != reshade::api::pipeline_subobject_type::pixel_shader) return nullptr;

      const std::vector<std::byte> pattern_mad_sat = { std::byte{0x32}, std::byte{0x20}, std::byte{0x00}, std::byte{0x09} }; // mad_sat
      const std::vector<std::byte> pattern_mad = { std::byte{0x32}, std::byte{0x00}, std::byte{0x00}, std::byte{0x09} }; // mad

      // float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f)
      // float3(0.298999995f, 0.587000012f, 0.114f) (rounded)
      // float3(0.299000f, 0.587000f, 0.114000f) (more rounded, should be identical once compiled)
      const std::vector<std::byte> pattern_bt_601_luminance = {
       std::byte{0x87}, std::byte{0x16}, std::byte{0x99}, std::byte{0x3E},
       std::byte{0xA2}, std::byte{0x45}, std::byte{0x16}, std::byte{0x3F},
       std::byte{0xD5}, std::byte{0x78}, std::byte{0xE9}, std::byte{0x3D}
      };
      const std::vector<std::byte> pattern_bt_709_luminance = {
       std::byte{0xD0}, std::byte{0xB3}, std::byte{0x59}, std::byte{0x3E},
       std::byte{0x59}, std::byte{0x17}, std::byte{0x37}, std::byte{0x3F},
       std::byte{0x98}, std::byte{0xDD}, std::byte{0x93}, std::byte{0x3D}
      };

      // Materials always contain this final cbuffer variabile multiplier as a brightness scale or some alpha thing (cb2[29].x)
      const std::vector<std::byte> pattern_safety_check = { std::byte{0x02}, std::byte{0x00}, std::byte{0x00}, std::byte{0x00}, std::byte{0x1D} };

      std::unique_ptr<std::byte[]> new_code = nullptr;

      std::vector<std::byte*> matches_bt_601_luminance = System::ScanMemoryForPattern(reinterpret_cast<const std::byte*>(code), size, pattern_bt_601_luminance);
      if (!matches_bt_601_luminance.empty())
      {
         const size_t size_offset = matches_bt_601_luminance.back() - code;
         // This is usually between the mad_sat and the luminance, but maybe it's not 100% sure
         std::vector<std::byte*> matches_safety_check = System::ScanMemoryForPattern(reinterpret_cast<const std::byte*>(matches_bt_601_luminance.back()), size - size_offset, pattern_safety_check);
         if (!matches_safety_check.empty())
         {
            // These would usually be just before the luminance matches
            std::vector<std::byte*> matches_mad_sat = System::ScanMemoryForPattern(reinterpret_cast<const std::byte*>(code), size, pattern_mad_sat);
            // If all patterns are found, patch the shader, it's a material shader!
            if (!matches_mad_sat.empty())
            {
               // Allocate new buffer and copy original shader code
               new_code = std::make_unique<std::byte[]>(size);
               std::memcpy(new_code.get(), code, size);

               // Calculate offset of each match relative to original code

               for (std::byte* match : matches_mad_sat)
               {
                  const size_t offset = match - code;
                  std::memcpy(new_code.get() + offset, pattern_mad.data(), pattern_mad.size());
               }

               for (std::byte* match : matches_bt_601_luminance)
               {
                  const size_t offset = match - code;
                  std::memcpy(new_code.get() + offset, pattern_bt_709_luminance.data(), pattern_bt_709_luminance.size());
               }
            }
         }
      }

      return new_code;
   }

   // The order of drawing is:
   // Write some LUT (?) from the CPU
   // Clear Normal Maps and Depth
   // Draw Normal Maps and Depth
   // Draw some shadow map, rudimentary AO, possibly from the angles of normal maps and depth (this looks right at any aspect ratio and resolution, though it's got bad screen space noise). This is stored in the alpha of the normal map buffer
   // Clear the new target texture
   // Draw some basic lighting buffer (mesh by mesh?)
   // Clear the new target texture (swapchain) (to beige)
   // Draw the final "composed" scene color (in gamma space), directly on the swapchain, mesh by mesh, starting from lights, to normal meshes (including skinner/characters), to transparency and fog, and then emissive etc. The alpha channel contrains the bloom/emissivness amount
   // Copy the swapchain texture
   // Apply decals
   // Another copy?
   // Apply color filter? Nah
   // Generate bloom (and DoF?)
   // Apply bloom (~additive)
   // Do post process...?
   // Apply grading (e.g. golden filter, contrast etc)
   // Draw UI (directly on swapchain)
   // Present

   void PrintImGuiAbout() override
   {
      ImGui::Text("Deus Ex: Human Revolution - Director's Cut mod - about and credits section", ""); // TODO: credits... gold and UW
      // It might work with the non Director's Cut version of the game too
      // This is fully compatible with the Yellow Filter Restored mod, and executes after it
   }
};

BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved)
{
   if (ul_reason_for_call == DLL_PROCESS_ATTACH)
   {
      Globals::SetGlobals(PROJECT_NAME, "Deus Ex: Human Revolution - Director's Cut Luma mod");
      Globals::VERSION = 1;

      enable_swapchain_upgrade = true;
      swapchain_upgrade_type = SwapchainUpgradeType::scRGB;
      enable_texture_format_upgrades = true;
      texture_upgrade_formats = {
            reshade::api::format::r8g8b8a8_unorm,
            //reshade::api::format::r8g8b8a8_typeless,
            reshade::api::format::r8g8b8x8_unorm,
            reshade::api::format::b8g8r8a8_unorm,
            //reshade::api::format::b8g8r8a8_typeless,
            reshade::api::format::b8g8r8x8_unorm,
            //reshade::api::format::b8g8r8x8_typeless,

				// Used by lighting buffers
            reshade::api::format::r10g10b10a2_unorm,

            // Probably unused, but won't hurt
            reshade::api::format::r11g11b10_float,
      };
      texture_format_upgrades_2d_size_filters = 0 | (uint32_t)TextureFormatUpgrades2DSizeFilters::SwapchainResolution | (uint32_t)TextureFormatUpgrades2DSizeFilters::SwapchainAspectRatio;

      game = new GameDeusExHumanRevolutionDC();
   }

   CoreMain(hModule, ul_reason_for_call, lpReserved);

   return TRUE;
}