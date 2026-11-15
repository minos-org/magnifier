PATH=C:\Programas\lazarus26\fpc\2.2.2\bin\i386-win32
cd ..

strip --strip-all magnifier.exe

cd libraries\pas_overlays
strip --strip-all pas_overlays.dll

cd ..
cd videocard_checker
strip --strip-all videocard_checker.dll
cd ..
cd ..


cd build
pause