Name:           magnifier
Version:        3.6
Release:        1
Summary:        Virtual Magnifying Glass
Group:          Accessibility
License:        GPL Version 2
URL:            http://magnifier.sourceforge.net
Source0:        http://internap.dl.sourceforge.net/sourceforge/magnifier/magnifier-3.6.zip
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires:  fpc >= 2.4.2, lazarus >= 0.9.31

%description

Virtual Magnifying Glass is a free, open source, multiplatform, screen magnification tool. It is simple, customizable, and easy-to-use.

%prep
%setup -q magnifier

%build
make TARGET=%{_target_cpu}

%install
./install.sh DESTDIR=$RPM_BUILD_ROOT

%clean
rm -rf $RPM_BUILD_ROOT/

%files
%defattr(-,root,root,-)
/usr/share/magnifier/
/usr/bin/vmg

%changelog

* Wed Dec 14 2011 Felipe Monteiro de Carvalho <felipemonteiro.carvalho at gmail.com> - 3.6-mdk.i386.rpm
- New update for version 3.6.

* Mon Jun 29 2010 Felipe Monteiro de Carvalho <felipemonteiro.carvalho at gmail.com> - 3.5-mdk.i386.rpm
- New update for version 3.5.

* Mon May 24 2010 Felipe Monteiro de Carvalho <felipemonteiro.carvalho at gmail.com> - 3.4-mdk.i386.rpm
- New update for version 3.4.

* Wed Dec 10 2008 Felipe Monteiro de Carvalho <felipemonteiro.carvalho at gmail.com> - 3.3.2-mdk.i386.rpm
- New update for version 3.3.2.

* Wed Jul 2 2007 Felipe Monteiro de Carvalho <felipemonteiro.carvalho at gmail.com> - 3.3-mdk.i386.rpm
- Updated the package.

* Wed Feb 15 2006 Felipe Monteiro de Carvalho <felipemonteiro.carvalho at gmail.com> - 3.2-mdk.i386.rpm
- The Linux RPM package is created.
