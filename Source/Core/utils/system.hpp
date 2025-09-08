#pragma once

#include <windows.h>
#include <shlobj.h>
#include <string>
#include <filesystem>
#include "assert.h"

// For "GetFileVersionInfoSize" etc
#pragma comment(lib, "Version.lib")

namespace System
{
   // TODO: move these to a cpp body, they send linking warnings

   // Returns the path to the "System32" directory
   __forceinline std::filesystem::path GetSystemPath()
   {
      WCHAR buf[4096];
      GetSystemDirectoryW(buf, ARRAYSIZE(buf));
      return buf;
   }

   // Pass in null/0 to get the path to the process executable (.exe)
   std::filesystem::path GetModulePath(HMODULE hModule = 0)
   {
      std::vector<wchar_t> path(32768); // Maximum path length in Windows, there's no define for it, the old one is "MAX_PATH"
      DWORD length = GetModuleFileNameW(hModule, path.data(), (DWORD)path.size());
      if (length == 0 || length >= path.size()) // This should never happen unless we passed in an invalid module
      {
         assert(false);
         return {};
      }

      std::filesystem::path exe_path = std::wstring(path.data());
      return exe_path;
   }

   std::string GetProcessExecutableName()
   {
      std::string exe_name = GetModulePath().filename().string();
      return exe_name;
   }

   bool GetDLLVersion(const std::filesystem::path& file_path, uint64_t& file_version, uint64_t& product_version)
   {
      file_version = 0;
      product_version = 0;

      DWORD verHandle = 0;
      DWORD verSize = GetFileVersionInfoSize(file_path.c_str(), &verHandle);
      if (verSize != NULL)
      {
         LPSTR verData = new char[verSize];
         if (GetFileVersionInfo(file_path.c_str(), verHandle, verSize, verData))
         {
            LPBYTE lpBuffer = NULL;
            UINT size = 0;
            if (VerQueryValue(verData, L"\\", (VOID FAR * FAR*)&lpBuffer, &size))
            {
               if (size != 0 && lpBuffer != nullptr)
               {
                  VS_FIXEDFILEINFO* verInfo = (VS_FIXEDFILEINFO*)lpBuffer;
                  if (verInfo->dwSignature == 0xfeef04bd)
                  {
                     // Combine into a single 64-bit value: v1.v2.v3.v4. This can 
                     file_version |= static_cast<uint64_t>((verInfo->dwFileVersionMS >> 16) & 0xFFFF) << 48; // v1
                     file_version |= static_cast<uint64_t>((verInfo->dwFileVersionMS >> 0) & 0xFFFF) << 32;  // v2
                     file_version |= static_cast<uint64_t>((verInfo->dwFileVersionLS >> 16) & 0xFFFF) << 16; // v3
                     file_version |= static_cast<uint64_t>((verInfo->dwFileVersionLS >> 0) & 0xFFFF);        // v4

                     product_version |= static_cast<uint64_t>((verInfo->dwProductVersionMS >> 16) & 0xFFFF) << 48; // v1
                     product_version |= static_cast<uint64_t>((verInfo->dwProductVersionMS >> 0) & 0xFFFF) << 32;  // v2
                     product_version |= static_cast<uint64_t>((verInfo->dwProductVersionLS >> 16) & 0xFFFF) << 16; // v3
                     product_version |= static_cast<uint64_t>((verInfo->dwProductVersionLS >> 0) & 0xFFFF);        // v4

                     delete[] verData;
                     return true;
                  }
               }
            }
         }
         delete[] verData;
      }
      return false;
   }

   bool CopyToClipboard(const std::string& text)
   {
#ifdef WIN32
      // Convert UTF-8 to UTF-16
      int wideSize = MultiByteToWideChar(CP_UTF8, 0, text.c_str(), -1, nullptr, 0);
      if (wideSize <= 0) return false;

      HGLOBAL hMem = GlobalAlloc(GMEM_MOVEABLE, wideSize * sizeof(wchar_t));
      if (!hMem) return false;

      wchar_t* wstr = static_cast<wchar_t*>(GlobalLock(hMem));
      if (!wstr)
      {
         GlobalFree(hMem);
         return false;
      }

      MultiByteToWideChar(CP_UTF8, 0, text.c_str(), -1, wstr, wideSize);
      GlobalUnlock(hMem);

      if (!OpenClipboard(nullptr))
      {
         GlobalFree(hMem);
         return false;
      }

      EmptyClipboard();
      SetClipboardData(CF_UNICODETEXT, hMem); // Windows owns the memory after this
      CloseClipboard();

      return true;
#else
      return false;
#endif
   }

   void OpenExplorerToFile(const std::filesystem::path& file_path)
   {
#ifdef WIN32
      PIDLIST_ABSOLUTE pidl = nullptr;
      HRESULT hr = SHParseDisplayName(file_path.wstring().c_str(), nullptr, &pidl, 0, nullptr);
      if (SUCCEEDED(hr) && (pidl != nullptr)) {
         SHOpenFolderAndSelectItems(pidl, 0, nullptr, 0);
         CoTaskMemFree(pidl);
      }
#else
      std::string command = "xdg-open " + file_path.parent_path().string();
      std::system(command.c_str());
#endif
   }
}