Prey (2017) Luma is mod that rewrites the whole late rendering phase of CryEngine/Prey.
It's made by two relatively separate parts:
The first, by Ersh, has the purpose of hooking into the game's native code and (e.g.) swapping texture formats (e.g. from 8bit to 16bit etc).
The second, by Pumbo, leverages the ReShade Addon system to add or modify rendering passes (and replace post processing shaders) through DirectX hooks.
It'd be possible to achieve the same without ReShade and game specific code hooks, by only using generic DirectX hooks, but it'd be exponentially more complicated (CryEngine re-uses render target textures for different purposes, so we couldn't easily tell which ones to upgrade, and ReShade offers settings serialization and a bunch of other features).
The second part has since then evolved into a generic "DirectX 11" games modding framework.

# Instructions and details
- See the generic Luma ReadMe file.
- Run ".Data\Prey\Tools\setup.ps1" to define the game's path environment variable.
- The Steam version of the game can't be launched from the exe without a modified steam dll (which means Luma post build script could then fail to launch it, it'd need to pass through Steam).
- The "Data" folder needs to be manually copied into the directory of the game at least once. For development of shaders, it's suggested to make a symbolic link of the "Prey-Luma" folder (to allow git to pick up the changes while also having the latest version in game).
- If you want to load the mod with an asi loader instead of through ReShade Addons automatic loading, you can rename the dll to ".asi" name, add the asi loader and use one of the following names: bink2w64.dll, dinput8.dll, version.dll, winhttp.dll, winmm.dll (untested), wininet.dll.
- The mod also comes with some replaced game files. These are packaged in ".pak" files in CryEngine, and they are simple zips (they can be extracted and re-compressed as zip).
- Vcpkg package dependencies are forced to the version I tested the mod on, upgrading is possible but there seem to be no issues.
- There's some warnings in the DKUtil code, we haven't fixed them as they seem harmless.

# Shaders
- The game's original shaders code can be found in the Engine\Shaders.pak in the GOG version of the game (extract it as zip).
- To decompile further game shaders you will need 3DMigoto (see RenoDX). There's a premade batch file to extract all the dumped CSOs in a folder.
- Running a graphics capture debugger requires ReShade to be off. NV Nsight and Intel "Graphics Frame Analyzer" work. Microsoft Pix and RenderDoc might also work but are untested. The GOG version is the easiest to debug graphics for as it can be launched directly from its exe (differently from the Steam version).