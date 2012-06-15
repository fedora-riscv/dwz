Summary: DWARF optimization and duplicate removal tool
Name: dwz
Version: 0.3
Release: 1%{?dist}
License: GPLv2+ and GPLv3+
Group: Development/Tools
# git archive --format=tar --remote=git://sourceware.org/git/dwz.git \
#   --prefix=%{name}-%{version}/ %{name}-%{version} \
#   | bzip2 -9 > %{name}-%{version}.tar.bz2
Source: %{name}-%{version}.tar.bz2
BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildRequires: elfutils-libelf-devel%{?_isa}

%description
The dwz package contains a program that attempts to optimize DWARF
debugging information contained in ELF shared libraries and ELF executables
for size, by replacing DWARF information representation with equivalent
smaller representation where possible and by reducing the amount of
duplication using techniques from DWARF standard appendix E - creating
DW_TAG_partial_unit compilation units (CUs) for duplicated information
and using DW_TAG_imported_unit to import it into each CU that needs it.

%prep
%setup -q

%build
make %{?_smp_mflags} CFLAGS='%{optflags}' prefix=%{_prefix} \
  mandir=%{_mandir} bindir=%{_bindir}

%install
rm -rf %{buildroot}
make DESTDIR=%{buildroot} prefix=%{_prefix} mandir=%{_mandir} bindir=%{_bindir} \
  install

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root)
%doc COPYING COPYING3 COPYING.RUNTIME
%{_bindir}/dwz
%{_mandir}/man1/dwz.1*

%changelog
* Fri Jun 15 2012 Jakub Jelinek <jakub@redhat.com> 0.3-1
- update to dwz-0.3 (#830863)

* Mon Jun 11 2012 Jakub Jelinek <jakub@redhat.com> 0.2-1
- new package
