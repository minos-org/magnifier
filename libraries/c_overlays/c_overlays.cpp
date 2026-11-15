/*
overlays_c.pas

Main file of the c overlays library for the magnifier

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

/*
  Include files
*/
// C RunTime Header Files
#include <stdlib.h>
#include <malloc.h>
#include <memory.h>

// Windows Header Files:
#include <windows.h>
#include <mmsystem.h> //added to compile under NT
#define INITGUID
#include <objbase.h>
#include <initguid.h>
//#undef WINAPI
//#define WINAPI
#include <ddraw.h>                                                                

#include "dll_interface.h"

/*
  Global Variables
*/

LPDIRECTDRAW7        g_lpdd = NULL;
LPDIRECTDRAWSURFACE7 g_lpddsPrimary = NULL;
LPDIRECTDRAWSURFACE7 g_lpddsOverlay = NULL;

int Initialize()
{
    DDSURFACEDESC2   ddsd;
    HRESULT         ddrval;
    
    ddrval = DirectDrawCreateEx(NULL, (VOID**)&g_lpdd, IID_IDirectDraw7, NULL);
    if (FAILED(ddrval)) return FALSE;

    // For NORMAL cooperative level we no longer need to provide an HWND.
    ddrval = g_lpdd->SetCooperativeLevel(NULL, DDSCL_NORMAL);
    if (FAILED(ddrval)) return FALSE;
    
    if (!g_lpdd) return E_FAIL;
    
    ZeroMemory(&ddsd, sizeof(ddsd));
    ddsd.dwSize = sizeof(ddsd);
    ddsd.dwFlags = DDSD_CAPS;
    ddsd.ddsCaps.dwCaps = DDSCAPS_PRIMARYSURFACE;
    ddrval = g_lpdd->CreateSurface(&ddsd, &g_lpddsPrimary, NULL );

    if (FAILED(ddrval)) return FALSE;
    
    return TRUE;

}

/*
  Releases core DirectDraw objects
*/
int Finalize()
{
    if (g_lpddsPrimary)
    {
        g_lpddsPrimary->Release();
        g_lpddsPrimary=NULL;
    }
    
    if (g_lpdd)
    {
        g_lpdd->Release();
        g_lpdd=NULL;
    }

    return TRUE;
}
