/*
MagnifierWindow.h

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

#pragma once

class MagnifierWindow
{
public:
    MagnifierWindow();

    virtual ~MagnifierWindow();

    int create(
        HINSTANCE inst,
        int x, int y,
        int width, int height,
        LPCWSTR className,
        LPCWSTR caption,
        DWORD windowStyle,
        int icon = 0,
        int iconSmall = 0,
        DWORD classStyle = 0);
    int destroy();

    virtual void afterCreate();

    virtual LRESULT handleMessage(
        HWND hwnd,
        UINT uMsg,
        WPARAM wParam,
        LPARAM lParam);

    void show(bool shouldShow);

    HWND hwnd();
    
    void handleTimer();

protected:
    HINSTANCE mHinst;

    HWND mHwnd;
    
    int mX;
    int mY;
    int mWidth;
    int mHeight;
    LPCWSTR mClassName;
    LPCWSTR mCaption;
    int mIcon;
    int mIconSmall;

    static LRESULT CALLBACK windowProc(
        HWND hwnd,
        UINT uMsg,
        WPARAM wParam,
        LPARAM lParam);
};