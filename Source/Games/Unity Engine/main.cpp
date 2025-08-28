#define GAME_UNITY_ENGINE 1

#include "..\..\Core\core.hpp"

namespace
{
   // Note: these are serialized in settings so avoid reordering unless necessary.
   // These names will be set in shaders as define, so you can branch on them if really necessary.
   constexpr uint32_t GAME_UNITY_ENGINE_GENERIC = 0;
   constexpr uint32_t GAME_WHITE_KNUCKLE = 1;
   constexpr uint32_t GAME_SHADOWS_OF_DOUBT = 2;
   constexpr uint32_t GAME_VERTIGO = 3;
   constexpr uint32_t GAME_POPTLC = 4;
   constexpr uint32_t GAME_COCOON = 5;
   constexpr uint32_t GAME_INSIDE = 6;
   //TODOFT: add a way to add shader hashes name definitions hardcoded in code for debugging
   // TODO: 0x2C49DEA4 draws the first pass of blur... Cut off negative values from it

   // List of all the games this generic engine mod supports.
   // Other games might be supported too if they use the same shaders.
   // These might be x32 or x64 or both, the mod will only load if the architecture matches anyway.
   const std::map<std::set<std::string>, GameInfo> games_database = {
       { { "White Knuckle.exe" }, MAKE_GAME_INFO("White Knuckle", "WK", GAME_WHITE_KNUCKLE, { "Pumbo" }) },
       { { "Shadows of Doubt.exe" }, MAKE_GAME_INFO("Shadows of Doubt", "SoD", GAME_SHADOWS_OF_DOUBT, { "Pumbo" }) },
       { { "Vertigo.exe" }, MAKE_GAME_INFO("Vertigo", "VRTG", GAME_VERTIGO, { "Pumbo" }) },
       { { "TheLostCrown.exe", "TheLostCrown_plus.exe" }, MAKE_GAME_INFO("Prince of Persia: The Lost Crown", "PoPTLC", GAME_POPTLC, std::vector<std::string>({ "Ersh", "Pumbo" })), },
       { { "universe.exe" }, MAKE_GAME_INFO("COCOON", "COCN", GAME_COCOON, { "Pumbo" }) },
       { { "INSIDE.exe" }, MAKE_GAME_INFO("INSIDE", "INSD", GAME_INSIDE, { "Pumbo" }) },
   };

   const GameInfo& GetGameInfoFromID(uint32_t id)
   {
      for (const auto& [key, value] : games_database)
      {
         if (value.id == id)
         {
            return value;
         }
      }
      static const GameInfo default_game_info = MAKE_GAME_INFO("Generic Unity Game", "", GAME_UNITY_ENGINE_GENERIC, { "" });
      return default_game_info;
   }

   // If not found, treat everything as generic (assuming default engine behaviours)
   const GameInfo* game_info = nullptr;
   uint32_t game_id = GAME_UNITY_ENGINE_GENERIC;
}

class UnityEngine final : public Game
{
public:
   void OnInit(bool async) override
   {
      reshade::api::effect_runtime* runtime = nullptr;
      reshade::get_config_value(runtime, NAME, "GameID", game_id);

      // If the user didn't force the mod to behave like a specific game,
      // try to identify what game this is based on the executable name, given we have a list.
      if (game_id == 0)
      {
         const std::string executable_name = System::GetProcessExecutableName();
         for (const auto& [key, value] : games_database)
         {
            bool done = false;
            for (const auto& sub_key : key)
            {
               if (sub_key == executable_name)
               {
                  game_info = &value;
                  game_id = game_info->id;
                  done = true;
                  break;
               }
            }
            if (done)
               break;
         }
      }
      else
      {
         for (const auto& [key, value] : games_database)
         {
            if (value.id == game_id)
            {
               game_info = &value;
               break;
            }
         }
         // Fall back to generic if the game we specified didn't exist
         if (!game_info)
         {
            game_id = GAME_UNITY_ENGINE_GENERIC;
         }
      }

      if (game_info)
      {
         sub_game_shader_define = game_info->shader_define.c_str(); // This data is persistent
         sub_game_shaders_appendix = game_info->internal_name; // Make sure we dump in a sub folder, to keep them separate
      }
      // Allow to branch on behaviour for a generic mod too in shaders
      else
      {
         static_assert(GAME_UNITY_ENGINE_GENERIC == 0); // Rename the string literal here too if you rename the variable
         sub_game_shader_define = "GAME_UNITY_ENGINE_GENERIC";
      }

      // Games like SoD have problems if upgrading random resources, they get stuck during loading screens (we could try some more advanced upgrade rules, but it's not particularly necessary).
      // Unity does bloom in HDR so upgrading mips isn't really necessary, and often it's seemingly done at full resolution anyway.
      if (game_id != GAME_SHADOWS_OF_DOUBT)
      {
         texture_format_upgrades_2d_size_filters |= (uint32_t)TextureFormatUpgrades2DSizeFilters::SwapchainAspectRatio;
         // Without further mods, these games (occasionally or always) internally render at 16:9 (including the UI), with a final copy to the swapchain adding black blacks
         if (game_id == GAME_COCOON // Main menu is 16:9
            || game_id == GAME_INSIDE // Whole game is 16:9
            || game_id == GAME_POPTLC // Whole game is 16:9
            )
         {
            texture_format_upgrades_2d_size_filters |= (uint32_t)TextureFormatUpgrades2DSizeFilters::CustomAspectRatio;
            texture_format_upgrades_2d_custom_aspect_ratio = 16.f / 9.f;
         }
      }

      // The entire game rendering pipeline was SDR
      if (game_id == GAME_INSIDE)
      {
         texture_upgrade_formats.emplace(reshade::api::format::r10g10b10a2_typeless);
         texture_upgrade_formats.emplace(reshade::api::format::r10g10b10a2_unorm);

#if DEVELOPMENT // INSIDE
         forced_shader_names.emplace(Shader::Hash_StrToNum("0AAF0B02"), "Draw Motion Vectors");
         forced_shader_names.emplace(Shader::Hash_StrToNum("A6B71745"), "Downscale 1/2");
         forced_shader_names.emplace(Shader::Hash_StrToNum("E34B6A4A"), "Downscale Bloom");
#endif
      }

      // Games that use the ACES tonemapping LUT should go here
      if (game_id == GAME_UNITY_ENGINE_GENERIC || game_id == GAME_SHADOWS_OF_DOUBT || game_id == GAME_VERTIGO)
      {
         texture_format_upgrades_lut_size = 32;
         texture_format_upgrades_lut_dimensions = LUTDimensions::_3D;

         std::vector<ShaderDefineData> game_shader_defines_data = {
            {"TONEMAP_TYPE", '1', false, false, "0 - SDR: Vanilla (ACES)\n1 - HDR: HDR ACES (recommended)\n2 - HDR: Vanilla+ (DICE+Oklab) (SDR hue conserving)\n3 - HDR: Vanilla+ (DICE) (vibrant)\n4 - HDR: Vanilla+ (DICE+desaturation)\n5 - HDR: Untonemapped (test only)"},
         };
         shader_defines_data.append_range(game_shader_defines_data);
      }
      if (game_id == GAME_COCOON)
      {
         std::vector<ShaderDefineData> game_shader_defines_data = {
            {"ENABLE_FILM_GRAIN", '1', false, false, "Allow disabling the game's faint film grain effect"},
         };

         shader_defines_data.append_range(game_shader_defines_data);

         GetShaderDefineData(TEST_SDR_HDR_SPLIT_VIEW_MODE_NATIVE_IMPL_HASH).SetDefaultValue('1');
      }
      if (game_id == GAME_INSIDE)
      {
         std::vector<ShaderDefineData> game_shader_defines_data = {
            {"ENABLE_LUMA", '1', false, false, "Enables all Luma's post processing modifications, to improve the image and output HDR"},
            {"ENABLE_FILM_GRAIN", '1', false, false, "Allow disabling the game's film grain effect"},
            {"ENABLE_LENS_DISTORTION", '1', false, false, "Allow disabling the game's lens distortion effect"},
            {"ENABLE_CHROMATIC_ABERRATION", '1', false, false, "Allow disabling the game's chromatic aberration effect"},
            {"ENABLE_FAKE_HDR", '0', false, false, "Enable a \"Fake\" HDR boosting effect, as the game's highlight were fairly dim to begin with"},
         };
         shader_defines_data.append_range(game_shader_defines_data);

         GetShaderDefineData(POST_PROCESS_SPACE_TYPE_HASH).SetDefaultValue('0');
         // No gamma mismatch baked in the textures as the game never applied gamma, it was gamma from the beginning (likely as an extreme optimization)!
         GetShaderDefineData(GAMMA_CORRECTION_TYPE_HASH).SetDefaultValue('1');
         GetShaderDefineData(VANILLA_ENCODING_TYPE_HASH).SetDefaultValue('1');
      }
      else
      {
         // All recent Unity games do all post processing in linear space, until the swapchain (usually included too)
         GetShaderDefineData(POST_PROCESS_SPACE_TYPE_HASH).SetDefaultValue('1');
         // All recent Unity games used sRGB textures, hence implicitly applied sRGB gamma without ever using the formula in shaders,
         // but as usual, they were likely developed and made for gamma 2.2 displays.
         GetShaderDefineData(GAMMA_CORRECTION_TYPE_HASH).SetDefaultValue('1');
      }
      // Unity games almost always have a clear last shader, so we can pre-scale by the inverse of the UI brightness, so the UI can draw at a custom brightness.
      // The UI usually draws in linear space too, though that's an engine setting.
      GetShaderDefineData(UI_DRAW_TYPE_HASH).SetDefaultValue('2');
   }

   // Needed by "SoD" given it used sRGB views (it should work on other Unity games too)
   bool ForceVanillaSwapchainLinear() const override
   {
      // Most recent Unity games do the whole post processing, UI and swapchain presentation in linear (sRGB textures), even if the swapchain isn't sRGB.
      // Inside was UNORM all along (no float in the rendering)
      if (game_id == GAME_INSIDE)
         return false;
      return true;
   }

#if DEVELOPMENT
   void DrawImGuiDevSettings(DeviceData& device_data) override
   {
      reshade::api::effect_runtime* runtime = nullptr;

      // This can only be changed in a development enviroment, given it's not very necessary if not for debugging,
      // and we'd need to add re-initialization code (and also expose the names ImGUI).
      // Don't change it if you want to keep the automatic detection on boot.
      std::string game_name = GetGameInfoFromID(game_id).title;
      if (game_id <= 0) // Automatic mode (no forced game)
      {
         game_name = "Auto";
      }
      // TODO: turn into a drop down list
      if (ImGui::SliderInt("Game ID", &(int&)game_id, 0, games_database.size(), game_name.c_str()))
      {
         reshade::set_config_value(runtime, NAME, "GameID", game_id);
      }
   }
#endif

   void PrintImGuiAbout() override
   {
      auto FormatAuthors = [](const std::vector<std::string>& authors) -> std::string
         {
            if (authors.empty()) return "Unknown";
            if (authors.size() == 1) return authors[0];
            if (authors.size() == 2) return authors[0] + " and " + authors[1];

            std::string result;
            for (size_t i = 0; i < authors.size() - 1; ++i)
            {
               result += authors[i] + ", ";
            }
            result += "and " + authors.back();
            return result;
         };

      const std::string game_title = game_info ? game_info->title : "Unity Engine";
      const std::string mod_authors = game_info ? FormatAuthors(game_info->mod_authors) : "Pumbo";
      ImGui::Text(("Luma for " + game_title + " is developed by " + mod_authors + ". It is open source and free.\nIf you enjoy it, consider donating.").c_str(), "");

      const auto button_color = ImGui::GetStyleColorVec4(ImGuiCol_Button);
      const auto button_hovered_color = ImGui::GetStyleColorVec4(ImGuiCol_ButtonHovered);
      const auto button_active_color = ImGui::GetStyleColorVec4(ImGuiCol_ButtonActive);
      ImGui::PushStyleColor(ImGuiCol_Button, IM_COL32(70, 134, 0, 255));
      ImGui::PushStyleColor(ImGuiCol_ButtonHovered, IM_COL32(70 + 9, 134 + 9, 0, 255));
      ImGui::PushStyleColor(ImGuiCol_ButtonActive, IM_COL32(70 + 18, 134 + 18, 0, 255));
      static const std::string donation_link_pumbo = std::string("Buy Pumbo a Coffee ") + std::string(ICON_FK_OK);
      if (ImGui::Button(donation_link_pumbo.c_str()))
      {
         system("start https://buymeacoffee.com/realfiloppi");
      }
      ImGui::PopStyleColor(3);

      ImGui::NewLine();
      // Restore the previous color, otherwise the state we set would persist even if we popped it
      ImGui::PushStyleColor(ImGuiCol_Button, button_color);
      ImGui::PushStyleColor(ImGuiCol_ButtonHovered, button_hovered_color);
      ImGui::PushStyleColor(ImGuiCol_ButtonActive, button_active_color);
#if 0 //TODOFT: add nexus link here and below and in all other mods
      static const std::string mod_link = std::string("Nexus Mods Page ") + std::string(ICON_FK_SEARCH);
      if (ImGui::Button(mod_link.c_str()))
      {
         system("start https://www.nexusmods.com/prey2017/mods/149");
      }
#endif
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
         system("start https://github.com/Filoppi/Luma");
      }
      ImGui::PopStyleColor(3);

      ImGui::NewLine();
      ImGui::Text(("Credits:"
         "\n\nMod:"
         "\n" + mod_authors +
         "\nLuma Framework:"
         "\nPumbo"

         "\n\nThird Party:"
         "\nReShade"
         "\nImGui"
         "\nRenoDX"
         "\n3Dmigoto"
         "\nOklab"
         "\nACES"
         "\nDICE (HDR tonemapper)").c_str()
         , "");
   }
};

BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved)
{
   if (ul_reason_for_call == DLL_PROCESS_ATTACH)
   {
      Globals::SetGlobals(PROJECT_NAME, "Unity Engine Luma mod");
      Globals::VERSION = 1;

      // Unity apparently never uses these
      luma_settings_cbuffer_index = 13;
      luma_data_cbuffer_index = 12;

      enable_swapchain_upgrade = true;
      swapchain_upgrade_type = 1;
      enable_texture_format_upgrades = true;
      texture_format_upgrades_2d_size_filters = 0 | (uint32_t)TextureFormatUpgrades2DSizeFilters::SwapchainResolution;
      // PoPTLC only requires r8g8b8a8_typeless but will work with others regardless
      texture_upgrade_formats = {
            reshade::api::format::r8g8b8a8_unorm,
            reshade::api::format::r8g8b8a8_unorm_srgb,
            reshade::api::format::r8g8b8a8_typeless,
            reshade::api::format::r11g11b10_float,
      };

      game = new UnityEngine();
   }

   CoreMain(hModule, ul_reason_for_call, lpReserved);

   return TRUE;
}