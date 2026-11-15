#
# Parses command line options. Currently supported options are:
#
# DESTDIR		Destination root directory
# 

DESTDIR=""

for arg; do

  case $arg in

    DESTDIR=*) DESTDIR=${arg#DESTDIR=};;

  esac;

done

#
# Does the install
#

mkdir -p $DESTDIR/usr/share/magnifier

cp ./topleft.bmp $DESTDIR/usr/share/magnifier/
cp ./topright.bmp $DESTDIR/usr/share/magnifier/
cp ./bottomleft.bmp $DESTDIR/usr/share/magnifier/
cp ./bottomright.bmp $DESTDIR/usr/share/magnifier/
cp ./top.bmp $DESTDIR/usr/share/magnifier/
cp ./left.bmp $DESTDIR/usr/share/magnifier/
cp ./bottom.bmp $DESTDIR/usr/share/magnifier/
cp ./right.bmp $DESTDIR/usr/share/magnifier/
cp ./icon3.ico $DESTDIR/usr/share/magnifier/
cp ./icon3.png $DESTDIR/usr/share/magnifier/
cp ./cecae.bmp $DESTDIR/usr/share/magnifier/
cp ./feusp.bmp $DESTDIR/usr/share/magnifier/
cp ./vmg.bmp $DESTDIR/usr/share/magnifier/
cp ./lupa.bmp $DESTDIR/usr/share/magnifier/
cp ./usplegal.bmp $DESTDIR/usr/share/magnifier/
cp ./arrow.bmp $DESTDIR/usr/share/magnifier/
cp ./inverted-arrow.bmp $DESTDIR/usr/share/magnifier/

cp ./docs/README-EN.pdf $DESTDIR/usr/share/magnifier/
cp ./docs/README-EN.rtf $DESTDIR/usr/share/magnifier/
cp ./docs/README-PT.pdf $DESTDIR/usr/share/magnifier/
cp ./docs/README-PT.rtf $DESTDIR/usr/share/magnifier/

mkdir -p $DESTDIR/usr/bin

# We can't build a symbolic link here, because buildrpm aparently can't handle links

cp ./magnifier $DESTDIR/usr/bin/vmg
cp ./vmg.desktop $DESTDIR/usr/share/applications
