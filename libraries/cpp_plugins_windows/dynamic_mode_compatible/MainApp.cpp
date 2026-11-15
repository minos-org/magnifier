#include "stdafx.h"
#include "MainApp.h"
#include "MagnifierWindow.h"

MainApp::MainApp()
    : _magnifierWindow(NULL)
{
}

MainApp::~MainApp()
{
    if(_magnifierWindow)
    {
        _magnifierWindow->destroy();
        delete _magnifierWindow;
        _magnifierWindow = NULL;
    }
}

void MainApp::initialize()
{
    if(!_magnifierWindow)
    {
        _magnifierWindow = new MagnifierWindow();

        _magnifierWindow->create(
            NULL, // HINSTANCE
            100, 100,
            400, 300,
            L"Virtual Magnifying Glass - Dynamic Mode compatible - window",
            L"Virtual Magnifying Glass - Dynamic Mode compatible - window",
            WS_SYSMENU | WS_CAPTION
            );
    }
}

void MainApp::showMagnifier()
{
    _magnifierWindow->show(true);
}
