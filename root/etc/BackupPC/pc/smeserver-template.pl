$Conf{RsyncShareName} = [
  '/'
];
$Conf{BackupFilesExclude} = {
  '/' => [
    '/var/lib/BackupPC/',
    '/proc',
    '/tmp',
    '/sys',
    '/dev',
    '/boot',
    '/mnt',
    '/media',
    '/selinux',
    '/aquota.*',
    '/lost+found',
    '/initrd',
    '/var/tmp',
    '/var/lib/mysql',
    '/var/spool/squid'
  ]
};
$Conf{DumpPreUserCmd} = '$sshPath -l root $host /sbin/e-smith/signal-event pre-backup';
$Conf{XferMethod} = 'rsync';
$Conf{BackupsDisable} = 1;

