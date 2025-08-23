#pragma once

#include <windows.h>
#include <shlobj.h>
#include <string>
#include <filesystem>

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

   std::string GetProcessExecutableName()
   {
      char path[MAX_PATH];
      DWORD length = GetModuleFileNameA(nullptr, path, MAX_PATH);
      if (length == 0 || length == MAX_PATH)
         return {};

      std::filesystem::path exe_path = std::string(path);
      std::string exe_name = exe_path.filename().string();

      return exe_name;
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