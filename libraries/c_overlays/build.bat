PATH=C:\Programas\Dev-Cpp\bin
g++ -c c_overlays.cpp -IC:\Programas\DXSDK\Include -IC:\Programas\Dev-Cpp\include -o c_overlays.o
dllwrap.exe --output-def c_overlays.def --driver-name c++ --implib c_overlays.a c_overlays.o -L"c:/Programas/dev-cpp/lib" -L"c:/Programas/DXSDK/Lib" --no-export-all-symbols --add-stdcall-alias -o c_overlays.dll
