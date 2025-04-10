#include <windows.h>
#include <flutter_windows.h>

// Windows-specific signal handler
BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) {
  switch (fdwReason) {
    case DLL_PROCESS_ATTACH:
      // Initialize signal handling
      break;
    case DLL_PROCESS_DETACH:
      // Cleanup
      break;
  }
  return TRUE;
}

// Custom handler for Windows close events
void HandleWindowsClose() {
  // Perform any necessary cleanup
  FlutterDesktopTerminateProcess();
} 