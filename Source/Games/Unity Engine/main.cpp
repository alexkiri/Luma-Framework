#define GAME_UNITY_ENGINE 1

#define UPGRADE_SAMPLERS 0

#include "..\..\Core\core.hpp"

namespace
{
   // Note: these are serialized in settings so avoid reordering unless necessary
   constexpr int GAME_UNITY_ENGINE_GENERIC = 0;
   constexpr int GAME_WHITE_KNUCKLE = 1;
   constexpr int GAME_SHADOWS_OF_DOUBT = 2;
   constexpr int GAME_VERTIGO = 3;
   constexpr int GAME_POPTLC = 4;

   // List of all the games this generic engine mod supports.
   // Other games might be supported too if they use the same shaders.
   const std::map<std::set<std::string>, GameInfo> games_database = {
       { { "White Knuckle.exe" }, { "White Knuckle", "WK", GAME_WHITE_KNUCKLE, { "Pumbo" } } },
       { { "Shadows of Doubt.exe" }, { "Shadows of Doubt", "SoD", GAME_SHADOWS_OF_DOUBT, { "Pumbo" } } },
       { { "Vertigo.exe" }, { "Vertigo", "Vertigo", GAME_VERTIGO, { "Pumbo" } } },
       { { "TheLostCrown.exe", "TheLostCrown_plus.exe" }, { "Prince of Persia: The Lost Crown", "PoPTLC", GAME_POPTLC, { "Ersh", "Pumbo" } } },
   };

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
         const std::string executable_name = GetProcessExecutableName();
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
      // All recent Unity games do all post processing in linear space, until the swapchain (usually included too)
      GetShaderDefineData(POST_PROCESS_SPACE_TYPE_HASH).SetDefaultValue('1');
      // All recent Unity games used sRGB textures, hence implicitly applied sRGB gamma without ever using the formula in shaders,
      // but as usual, they were likely developed and made for gamma 2.2 displays.
      GetShaderDefineData(GAMMA_CORRECTION_TYPE_HASH).SetDefaultValue('1');
      // Unity games almost always have a clear last shader, so we can pre-scale by the inverse of the UI brightness, so the UI can draw at a custom brightness.
      // The UI usually draws in linear space too, though that's an engine setting.
      GetShaderDefineData(UI_DRAW_TYPE_HASH).SetDefaultValue('2');
   }

   // Needed by "SoD" given it used sRGB views (it should work on other Unity games too)
   bool ForceVanillaSwapchainLinear() const override { return true; }

#if DEVELOPMENT
   void DrawImGuiDevSettings(DeviceData& device_data) override
   {
      reshade::api::effect_runtime* runtime = nullptr;

      // This can only be changed in a development enviroment, given it's not very necessary if not for debugging,
      // and we'd need to add re-initialization code (and also expose the names ImGUI).
      if (ImGui::SliderInt("Game ID", &(int&)game_id, 0, games_database.size()))
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
      Globals::GAME_NAME = PROJECT_NAME;
      Globals::DESCRIPTION = "Unity Engine Luma mod";
      Globals::WEBSITE = "";
      Globals::VERSION = 1;

      // Unity apparently never uses these
      luma_settings_cbuffer_index = 13;
      luma_data_cbuffer_index = 12;

      enable_swapchain_upgrade = true;
      swapchain_upgrade_type = 1;
      enable_texture_format_upgrades = true;
      // Games like SoD have problems if upgrading random resources, they get stuck during loading screens (we could try some more advanced upgrade rules, but it's not particularly necessary).
      // Unity does bloom in HDR so upgrading mips isn't really necessary, and often it's seemingly done at full resolution anyway.
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