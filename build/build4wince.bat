PATH=C:\Programas\wince\Apps\lazarus\pp\bin\arm-wince;C:\Programas\wince\Apps\lazarus\pp\bin\i386-win32;c:\Programas\arm
cd ..
ppcrossarm.exe -Twince -FuC:\programas\wince\Apps\lazarus\lcl\units\arm-wince -FuC:\Programas\wince\Apps\lazarus\pp\fcl\units\arm-wince -FuC:\programas\wince\Apps\lazarus\lcl\units\arm-wince\wince -FuC:\Programas\wince\Apps\lazarus\pp\rtl\units\arm-wince -FDC:\Programas\arm -XParm-wince- magnifier.dpr
COPY magnifier.exe c:\Arquiv~1\Microsoft\Device~1\shared\magnifier.exe
cd build
