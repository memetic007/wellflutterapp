#ifndef RUNNER_SIGNAL_HANDLER_H_
#define RUNNER_SIGNAL_HANDLER_H_

#include <windows.h>

// Windows-specific signal handler
BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved);

// Custom handler for Windows close events
void HandleWindowsClose();

#endif  // RUNNER_SIGNAL_HANDLER_H_ 