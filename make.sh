
#
# Detects and parses the architecture
#

ARCH=$(uname -m)

case "$ARCH" in

 "i686") ARCH="i386";;

 "i586") ARCH="i386";;

 "i486") ARCH="i386";;

esac

echo "Target architecture: $ARCH"

#
# Detects and parses the OS
#

OS="linux"

echo "Target operating system: $OS"


#fpc -S2cgi -O1 -gl -vewnhi -l -Fu/usr/lib/lazarus/lcl/units/$ARCH-$OS/ -Fu/usr/lib/lazarus/lcl/units/$ARCH-$OS/ -Fu/usr/lib/#lazarus/lcl/units/$ARCH-$OS/gtk2/ -Fu/usr/lib/lazarus/packager/units/$ARCH-$OS/ -Fu. -o./magnifier -dLCL -dLCLgtk2 #magnifier.dpr

#fpc -MObjFPC -Sgi -Cg -O1 -Xs -l -vewnhibq -Fi/usr/share/lazarus/4.0.0/components/opengl/gtk2x11/include -Fu./magnifier-code/ -Fu/usr/share/lazarus/4.0.0/components/opengl/gtk2x11 -Fu/usr/share/lazarus/4.0.0/components/jpeg -Fu/usr/share/lazarus/4.0.0/lcl/units/x86_64-linux -Fu/usr/share/lazarus/4.0.0/lcl/units/x86_64-linux/gtk2 -Fu/usr/share/lazarus/4.0.0/components/freetype/lib/x86_64-linux -Fu/usr/share/lazarus/4.0.0/components/lazutils/lib/x86_64-linux -Fu/usr/share/lazarus/4.0.0/packager/units/x86_64-linux -o./magnifier -dLCL -dLCLgtk2 magnifier.dpr

lazbuild --build-all magnifier.lpi
