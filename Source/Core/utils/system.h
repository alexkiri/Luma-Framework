#pragma once

#include <windows.h>
#include <shlobj.h>
#include <string>
#include <filesystem>

namespace System
{
   // Returns the path to the "System32" directory
   std::filesystem::path GetSystemPath();

   // Pass in null/0 to get the path to the process executable (.exe)
   std::filesystem::path GetModulePath(HMODULE hModule = 0);

   std::string GetProcessExecutableName();

   bool GetDLLVersion(const std::filesystem::path& file_path, uint64_t& file_version, uint64_t& product_version);

   bool CopyToClipboard(const std::string& text);

   void OpenExplorerToFile(const std::filesystem::path& file_path);

   // Returns all matches.
   // This just scans for a value, there's no "??" support in the pattern.
   std::vector<std::byte*> ScanMemoryForPattern(const std::byte* base, size_t size, const std::byte* pattern, size_t pattern_size);
   std::vector<std::byte*> ScanMemoryForPattern(const std::byte* base, size_t size, const std::vector<std::byte>& pattern);
   std::vector<std::byte*> ScanMemoryForPattern(const std::byte* base, size_t size, const std::vector<uint8_t>& pattern);

   // Allocate within +/-2GB to make it reachable by 32 bit offsets
   void* VirtualAllocNear(void* target, size_t size, DWORD protect = PAGE_EXECUTE_READWRITE);
}