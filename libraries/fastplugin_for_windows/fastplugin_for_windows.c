/*
fastplugin_for_windows.pas

Main file of the c customizable and high performance library for the magnifier

Copyright (C) 1998 - 2006 Harri Pyy, Chris O'Donnell, Felipe Monteiro de Carvalho

This file is part of Virtual Magnifying Glass.

Virtual Magnifying Glass is free software;
you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2
as published by the Free Software Foundation.

Virtual Magnifying Glass is distributed in the hope
that it will be useful, but WITHOUT ANY WARRANTY; without even
the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE. See the GNU General Public License for more details.

Please note that the General Public License version 2 does not permit
incorporating Virtual Magnifying Glass into proprietary
programs.

AUTHORS: Chris O'Donnell, Felipe Monteiro de Carvalho and Harri Pyy
*/

#include "vmg_plugin_interface.h"
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>

DLLIMPORT Cardinal Initialize (struct TPluginData vPluginData)
{
    MessageBox (0, "Initialize DLL!\n", "Hi", MB_ICONINFORMATION);
}
          
DLLIMPORT void Finalize (void)
{
    MessageBox (0, "Finalize DLL!\n", "Hi", MB_ICONINFORMATION);
}


BOOL APIENTRY DllMain (HINSTANCE hInst     /* Library instance handle. */ ,
                       DWORD reason        /* Reason this function is being called. */ ,
                       LPVOID reserved     /* Not used. */ )
{
    switch (reason)
    {
      case DLL_PROCESS_ATTACH:
        break;

      case DLL_PROCESS_DETACH:
        break;

      case DLL_THREAD_ATTACH:
        break;

      case DLL_THREAD_DETACH:
        break;
    }

    /* Returns TRUE on success, FALSE on failure */
    return TRUE;
}
