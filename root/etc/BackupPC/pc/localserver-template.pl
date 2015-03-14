$Conf{RsyncShareName} = [
  '/'
];
$Conf{BackupFilesExclude} = {
  '/' => [
    '/var/lib/BackupPC',
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
    '/var/lib/mysql'
  ]
};
$Conf{DumpPreUserCmd} = '/usr/bin/sudo /usr/share/BackupPC/bin/BackupPC_SME_pre-backup';
$Conf{XferMethod} = 'rsync';
$Conf{RsyncClientCmd} = '/usr/bin/sudo $rsyncPath $argList+';
$Conf{RsyncClientRestoreCmd} = '/usr/bin/sudo $rsyncPath $argList+';
$Conf{ClientNameAlias} = '127.0.0.1';
$Conf{BackupsDisable} = 1;

