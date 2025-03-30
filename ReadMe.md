Luma is modding framework that facilitates improving the graphics of DirectX 11 games.
It leverages the ReShade Addon system to add or modify rendering passes (and replace shaders (e.g. post processing)) through DirectX hooks.
It'd be possible to achieve the same without ReShade and game specific code hooks, by only using generic DirectX hooks, but it'd be exponentially more complicated (Some engines re-use render target textures for different purposes, so we couldn't easily tell which ones to upgrade, and ReShade offers settings serialization and a bunch of other features).

# Development requirements
Windows 11 (Windows 10 probably works fine too)
Visual Studio 2022 (older versions might work too)
Windows 11 SDK 10.0.26100.0 (older versions work, but don't support HDR as well)

# Instructions
- Set "VCPKG_ROOT" environment variable to your vcpkg installation folder if it wasn't already (download it from here "https://github.com/microsoft/vcpkg", the version integrated with Visual Studio doesn't seem to be as reliable).
- Install the latest VC++ redist before running the code (https://aka.ms/vs/17/release/vc_redist.x64.exe), we enforced users to update to the latest versions, but "_DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR" could be defined to avoid that.
- Open "Luma.sln" and build it. Note that "Edit and Continue" build settings (\ZI) should not be used as they break the code patches generation (at least for projects that use DKUtil).
- The code hot spots are in core.hpp and each game's main.cpp files.
- Luma uses the same code for developing and shipping mods. There's a "DEVELOPMENT" and "TEST" flag (defines) in "global_defines.h", they respectively add development and testing features. They automatically spread to shaders on the next load/compile. Building in Debug (as opposed to Release), simply adds debug symbols etc, but no additional development features.

# Adding a new game mod
- Copy the template project (e.g. Template.vcxproj) into a new folder and rename its file manually, then add it to Visual Studio's Luma's solution (drag and drop), and rename it there as well.
- Check the template main.cpp file and replace what you need to replace, everything is explained there. Check out other game's mods for further inspiration.
- Each mod's version is stored in "Globals::VERSION" and can be increased there.
- x86 (Win32) games are compatible too, "BioShock 2" is an example of them.
- Add an environment variable called "LUMA_GAME_NAME_BIN_PATH" (e.g. "LUMA_BIOSHOCK_2_BIN_PATH" for Bioshock 2), and make it point to the game's executable folder (where ReShade goes). Go to the project settings post-build event page and set it to copy the binaries in that folder.
- Go to the project settings debugging page and set the Command to the game executable path (e.g. "$(LUMA_PREY_BIN_PATH)\Prey.exe", without the "), so it's run and attached to when debugging.
- Install ReShade 6.4.1+ in the game's directory.
- Build the project and run it for debugging, it should automatically run the game with the mod loaded.
- Some of this stuff could be automated with cmake, but I dislike programs without a proper GUI :D.

# Shaders development
- The mod automatically dumps the game's shaders in development mode.
- Luma shaders can be found in ".\Shaders\Game\". Dumped shaders will go there, and hand created ones should also go there (unless they are generic, they they go in the generic folder).
- Shader are saved and replaced by (cso/binary) hash.
- VSCode is suggested.
- Packaging mods for now is manual and the generic and game specific shader folders need to be put in a "Luma" folder in the mod binary directory.

# To Do and ideas
- Add a utility to automatically package a game mod with all the files it might need
- Add a utility to quickly create a new game project without manual editing (CMake?)
- Move the defines in "global_defines.h" as Solution Configurations in Visual Studio? So one doesn't need to edit the code to swap them
- Allow packaging shaders with the mod binary (like RenoDX does)?
- Move the core.hpp code in a static or dynamic library, instead of including it as code in every game specific project
- Add DirectX 12 support? Not planned for now. Luma is based on the simplicity of DX11