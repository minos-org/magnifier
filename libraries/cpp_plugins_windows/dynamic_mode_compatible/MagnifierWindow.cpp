/*
MagnifierWindow.cpp

Thin wrapper around win32 window objects.

Copyright (C) 2005 Chris O'Donnell

This file is part of Virtual Magnifying Glass for Windows.

Virtual Magnifying Glass for Windows is free software;
you can redistribute it and/or modify it under the
terms ofthe GNU General Public License version 2
as published by the Free Software Foundation.

Virtual Magnifying Glass for Windows is distributed in the hope
that it will be useful, but WITHOUT ANY WARRANTY; without even
the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE. See the GNU General Public License for more details.

Please note that the General Public License version 2 does not permit
incorporating Virtual Magnifying Glass for Windows into proprietary
programs.
*/

#include "stdafx.h"
#include "MagnifierWindow.h"

////////////////////////////////////////////////////////////////////////////////
LRESULT CALLBACK MagnifierWindow::windowProc(
    HWND hwnd,
    UINT uMsg,
    WPARAM wParam,
    LPARAM lParam)
{
    // Won't be valid during WM_CREATE
    MagnifierWindow* d = reinterpret_cast<MagnifierWindow*>(GetWindowLongPtr(hwnd, GWLP_USERDATA));

    LRESULT result = 1;
    switch(uMsg)
    {
    case WM_CREATE:
        break;
    default:
        if(d)
        {
            result = d->handleMessage(hwnd, uMsg, wParam, lParam);
        }
        break;
    }

    if(result)
    {
        return DefWindowProc(hwnd, uMsg, wParam, lParam);
    }
    return 0;
}

////////////////////////////////////////////////////////////////////////////////
MagnifierWindow::MagnifierWindow()
    : mHinst(NULL)
    , mHwnd(NULL)
{
}

////////////////////////////////////////////////////////////////////////////////
MagnifierWindow::~MagnifierWindow()
{
}

////////////////////////////////////////////////////////////////////////////////
int MagnifierWindow::create(
    HINSTANCE inst,
    int x, int y,
    int width, int height,
    LPCWSTR className,
    LPCWSTR caption,
    DWORD windowStyle,
    int icon /*= 0*/,
    int iconSmall /*= 0*/,
    DWORD classStyle /*= 0*/)
{
    mHinst = inst;
    mX = x;
    mY = y;
    mWidth = width;
    mHeight = height;
    mClassName = className;
    mCaption = caption;
    mIcon = icon;
    mIconSmall = iconSmall;

    WNDCLASSEX wndclass;
    wndclass.cbSize         = sizeof(wndclass);
    wndclass.style          = CS_OWNDC | classStyle;
    wndclass.lpfnWndProc    = windowProc;
    wndclass.cbClsExtra     = 0;
    wndclass.cbWndExtra     = 0;
    wndclass.hInstance      = mHinst;
    wndclass.hIcon          = LoadIcon (mHinst, MAKEINTRESOURCE(mIcon));
    wndclass.hCursor        = LoadCursor (NULL, IDC_ARROW);
    wndclass.hbrBackground  = (HBRUSH) GetStockObject (/*COLOR_BACKGROUND*/NULL_BRUSH);
    wndclass.lpszMenuName   = NULL;
    wndclass.lpszClassName  = mClassName;
    wndclass.hIconSm        = LoadIcon(mHinst, MAKEINTRESOURCE(mIconSmall));

    RegisterClassEx (&wndclass);

    mHwnd = CreateWindowEx(
        0,
        mClassName,
        mCaption,
        windowStyle/*WS_SYSMENU | WS_CAPTION*/,
        mX,
        mY,
        mWidth,
        mHeight,
        NULL,
        NULL,
        mHinst,
        NULL);

    // Connect the wndProc to this object
    SetWindowLongPtr(mHwnd, GWLP_USERDATA, (LONG)this);

    afterCreate();

    return 0;
}

////////////////////////////////////////////////////////////////////////////////
VOID CALLBACK TimerProc(
    HWND hwnd,
    UINT uMsg,
    UINT_PTR idEvent,
    DWORD dwTime)
{
    MagnifierWindow* m = reinterpret_cast<MagnifierWindow*>(idEvent);
    m->handleTimer();
}

////////////////////////////////////////////////////////////////////////////////
void MagnifierWindow::handleTimer()
{

}

////////////////////////////////////////////////////////////////////////////////
void MagnifierWindow::afterCreate()
{
    SetTimer(hwnd(), (UINT_PTR)this, 100 /*msecs*/, TimerProc);
}

////////////////////////////////////////////////////////////////////////////////
void MagnifierWindow::show(bool shouldShow)
{
    if(!mHwnd)
    {
        return;
    }
    ShowWindow(mHwnd, shouldShow ? SW_SHOW : SW_HIDE);
    UpdateWindow(mHwnd);
}

////////////////////////////////////////////////////////////////////////////////
int MagnifierWindow::destroy()
{
    if(mHwnd)
    {
        DestroyWindow(mHwnd);
        mHwnd = 0;
    }
    return 0;
}

////////////////////////////////////////////////////////////////////////////////
LRESULT MagnifierWindow::handleMessage(
    HWND hwnd,
    UINT uMsg,
    WPARAM wParam,
    LPARAM lParam)
{
    LRESULT result = 1;
    switch(uMsg)
    {
    case WM_COMMAND:
        result = 1;
        break;
    default:
        break;
    }
    return result;
}

////////////////////////////////////////////////////////////////////////////////
HWND MagnifierWindow::hwnd()
{
    return mHwnd;
}


