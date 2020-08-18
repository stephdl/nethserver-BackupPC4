%define name nethserver-BackupPC4
%define version 1.2.2
%define release 2
Name: %{name}
Version: %{version}
Release: %{release}%{?dist}
Summary: BackupPC4 integration into Nethserver
Group: Applications/System
License: GPL
URL: http://dev.nethserver.org/projects/nethforge/wiki/%{name} 
Source: %{name}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}
BuildArch: noarch
BuildRequires: nethserver-devtools
BuildRequires: perl
Requires: BackupPC >= 4.3.1
Requires: nethserver-httpd
Requires: bzip2
Requires: mod_authnz_pam
Conflicts: BackupPC < 4.3.1
Conflicts: nethserver-BackupPC

%description
BackupPC v4 is a high-performance, enterprise-grade system for backing up Linux
and WinXX PCs and laptops to a server's disk. BackupPC is highly configurable
and easy to install and maintain.
This package contains specific configuration for Nethserver


%prep
%setup -q -n %{name}-%{version}

%build
perl createlinks
sed -i 's/_RELEASE_/%{version}/' %{name}.json

%install
%{__mkdir} -p $RPM_BUILD_ROOT/etc/BackupPC/pc

(cd root   ; /usr/bin/find . -depth -print | /bin/cpio -dump $RPM_BUILD_ROOT)

mkdir -p %{buildroot}/usr/share/cockpit/%{name}/
mkdir -p %{buildroot}/usr/share/cockpit/nethserver/applications/
mkdir -p %{buildroot}/usr/libexec/nethserver/api/%{name}/
cp -a manifest.json %{buildroot}/usr/share/cockpit/%{name}/
cp -a logo.png %{buildroot}/usr/share/cockpit/%{name}/
cp -a %{name}.json %{buildroot}/usr/share/cockpit/nethserver/applications/
cp -a api/* %{buildroot}/usr/libexec/nethserver/api/%{name}/

/bin/rm -f %{name}-%{version}-filelist
%{genfilelist} $RPM_BUILD_ROOT \
> %{name}-%{version}-filelist


%clean
rm -rf $RPM_BUILD_ROOT

%files -f %{name}-%{version}-filelist
%defattr(-,root,root)
%dir %{_nseventsdir}/%{name}-update
%doc COPYING
%attr(0440,root,root) /etc/sudoers.d/50_nsapi_nethserver_BackupPC4

%pre
%{_sbindir}/usermod -m -d /var/lib/BackupPC backuppc >& /dev/null || :

%preun

%post
# rsa key created
if [[ ! -e /var/lib/BackupPC/.ssh/id_rsa ]]; then
/bin/cat /dev/zero |/bin/su -s /bin/bash backuppc -c '/usr/bin/ssh-keygen -t rsa -b 4096 -C "RSA key for BackupPC automatic login" -f /var/lib/BackupPC/.ssh/id_rsa -q -N ""' 2>&1 1>/dev/null
fi

%postun
if [ $1 == 0 ] ; then
    /usr/bin/rm -f /etc/httpd/conf.d/BackupPC.conf
  /usr/bin/systemctl reload httpd
fi

%changelog
* Sat Jul 04 2020 stephane de Labrusse <stephdl@de-labrusse.fr> 1.2.2-1
- Remove http templates after rpm removal

* Thu Mar 05 2020  stephane de Labrusse <stephdl@de-labrusse.fr> 1.2.1-1.ns7
- Fix bad sudoers permission

* Sat Nov 9 2019 Stephane de Labrusse <stephdl@de-labrusse.fr> 1.2.0-1.ns7
- cockpit. added to legacy apps

* Fri Nov 01 2019 Stephane de Labrusse <stephdl@de-labrusse.fr> 1.1.7-1.ns7
- Removed Runtime directory
- Restart the service always
- Renamed spec file to BackuPC4 

* Sun Oct 27 2019 Stephane de Labrusse <stephdl@de-labrusse.fr> 1.1.6-1.ns7
- Enable the BackupPC4 repository 

* Thu Oct 24 2019 Stephane de Labrusse <stephdl@de-labrusse.fr> 1.1.5-1.ns7
- First integration of BackupPC 4

* Fri Nov 24 2017 Stephane de Labrusse <stephdl@de-labrusse.fr> 1.1.4-1.ns7
- Set the admin user of the system template to admin@domaiName

* Sun Nov 21 2017 Stephane de Labrusse <stephdl@de-labrusse.fr> 1.1.3-1.ns7
- set the good way to ping binary

* Sun Sep 10 2017 Stephane de Labrusse <stephdl@de-labrusse.fr> 1.1.2-1.ns7
- Restart httpd service on trusted-network

* Wed Mar 29 2017 Stephane de Labrusse <stephdl@de-labrusse.fr> 1.1.1-1.ns7
- Template expansion on trusted-network

* Sun Mar 11 2017 Stephane de Labrusse <stephdl@de-labrusse.fr> 1.1.0-2.ns7
- GPL license

* Fri Nov 25 2016 stephane de Labrusse <stephdl@de-labrusse.fr> 1.1.0-1.ns7
- NS7 adaptation

* Sun May 3 2015 stephane de Labrusse <stephdl@de-labrusse.fr> 1.0.1-2.ns6
- disclamer

* Sat Mar 28 2015 stephane de Labrusse <stephdl@de-labrusse.fr> 1.0.1-1.ns6
- Added template and cygwin settings
- Added binary of rsync-cygwin
- Automatic 4096 rsa key creation in /var/lib/BackupPC
- Added a linux backup template
- corrected backuppc url error
- Added a CgiMultiUser option (admin can be the only allowed)

* Sat Mar 14 2015 stephane de Labrusse <stephdl@de-labrusse.fr> 1.0.0-1.ns6
- First release to Nethserver
- Thanks to Daniel berteaud the first author.

* Tue Nov 12 2013 Daniel B. <daniel@firewall-services.com> 0.2-1.sme
- Rebuild for SME9

* Mon Nov 29 2010 Daniel B. <daniel@firewall-services.com> 0.1-12.sme
- Support pbzip2 for archiving
- Use nice to reduce the priority of compression

* Tue Jun 16 2009 Daniel B. <daniel@firewall-services.com> [0.1-11]
- Remove double quotes when calling signal-event with ssh [SME: 5302]

* Fri May 29 2009 Daniel B. <daniel@firewall-services.com> [0.1-10]
- Call signal-event with it full path in smeserver-template.pl [SME: 5302]

* Tue May 12 2009 Daniel B. <daniel@firewall-services.com> [0.1-9]
- Add optionnal encryption of archives generated with BackupPC_SME_localArchive
  BackupPC_SME_usbArchive and BackupPC_SME_remoteArchive using openssl
- Generate a key and save it in /etc/BackupPC/archive.key
- Fixe permission restriction on /etc/BackupPC/*

* Thu May 07 2009 Daniel B. <daniel@firewall-services.com> [0.1-8]
- Link backuppc-checkupgrade script in post-upgrade event
  so the contrib is correctly configured without running backuppc-update
  event [SME: 5221]

* Tue May 05 2009 Daniel B. <daniel@firewall-services.com> [0.1-7]
- Fixe permissions on /etc/BackupPC/pc

* Mon Mar 23 2009 Daniel B. <daniel@firewall-services.com> [0.1-6]
- modify default httpd conf (cleanup) to use the new paths
- Add quotes in share names for *Archive.conf files
- Enhance provided template

* Wed Mar 18 2009 Daniel B. <daniel@firewall-services.com> [0.1-5]
- Enhance sudoers templates

* Mon Feb 23 2009 Daniel B. <daniel@firewall-services.com> [0.1-4]
- Fix logrotate issue (send a sigusr1 signal to httpd-bkpc)

* Tue Jan 20 2009 Daniel B. <daniel@firewall-services.com> [0.1-3]
- Update Exclude path for smeserver config example

* Thu Dec 11 2008 Daniel B. <daniel@firewall-services.com> [0.1-2]
- Revert config and logs paths to their default location
- Expand-templates during bootrape-console-save instead of post-upgrade
- Remove sudoers templates.metadata to prevent conflict, added smeserver-remoteuseraccess
  as a dependency

* Thu Nov 13 2008 Daniel B. <daniel@firewall-services.com> [0.1-1]
- Fix logrotate issue

* Thu Aug 14 2008 Daniel B. <daniel@firewall-services.com> [0.1-0]
- Adapted to work with 3.1.0
- Split smeserver specific stuff in a separate srpm
- Remove pre-compiled binaries from the srpm (par2cmdline must be downloaded separatly if needed)
- A dedicated httpd instance is used (running under backuppc user). This increase security as
  user www no longer has access to backuppc data.
- Authentication is integrated with the server-manager (no need to login two times now)
- Added some config example (with backups disabled). These can be used as templates for other hosts
- Some corrections in backup export scripts (*copyPool scipts still need to be re-written
  to be more reliable, maybe with dump/restore, or dd, and with built-in support for LVM snapshots)

* Wed May 11 2007 Daniel Berteaud <daniel@firewall-services.com>
- [3.0-1]
- corrected default config for localhost (excluding by default /opt/backuppc and /selinux)
- improvement of the rpm scriplets
- start and stop script linked to e-smith-service
- scripts for offline backups
- par2 included

* Tue Jan 30 2007 Daniel Berteaud <daniel@firewall-services.com>
- [3.0-0]
- rpm package
- script BackupPC_SME_remoteBackup to remotly backup the pool (to another UNIX host)
