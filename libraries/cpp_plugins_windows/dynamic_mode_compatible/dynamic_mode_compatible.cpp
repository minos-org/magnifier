// dynamic_mode_compatible.cpp : Defines the exported functions for the DLL application.
//

#include "stdafx.h"
#include "dynamic_mode_compatible.h"
#include "MainApp.h"

// This is an example of an exported variable
DYNAMIC_MODE_COMPATIBLE_API int ndynamic_mode_compatible=0;

// This is an example of an exported function.
DYNAMIC_MODE_COMPATIBLE_API int fndynamic_mode_compatible(void)
{
	return 42;
}

// This is the constructor of a class that has been exported.
// see dynamic_mode_compatible.h for the class definition
Cdynamic_mode_compatible::Cdynamic_mode_compatible()
{
	return;
}

////////////////////////////////////////////////////////////////////////////////

static MainApp* mainApp = NULL;

DYNAMIC_MODE_COMPATIBLE_API Cardinal Initialize (struct TPluginData vPluginData)
{
    MessageBox(NULL, L"Initialize was called", L"test from DLL", MB_OK);
    if(!mainApp)
    {
        mainApp = new MainApp();
        mainApp->initialize();
        mainApp->showMagnifier();
    }
    return 0;
}

DYNAMIC_MODE_COMPATIBLE_API void Finalize (void)
{
    MessageBox(NULL, L"Finalize was called", L"test from DLL", MB_OK);
    if(mainApp)
    {
        delete mainApp;
        mainApp = NULL;
    }
}

