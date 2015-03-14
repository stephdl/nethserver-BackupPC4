$Conf{ClientCharset} = 'cp1252';
$Conf{RsyncShareName} = [
  'cDrive'
];
$Conf{RsyncdPasswd} = 'secret';
$Conf{RsyncdUserName} = 'backuppc';
$Conf{XferMethod} = 'rsyncd';
$Conf{BackupFilesExclude} = {
  '*' => [
    '*/hiberfil.sys',
    '*/pagefile.sys',
    '*/WUTemp',
    '*/RECYCLER',
    '*/UsrClass.dat',
    '*/UsrClass.dat.LOG',
    '*/NTUSER.DAT',
    '*/NTUSER.DAT.LOG',
    '*/Temporary?Internet?Files/*',
    '*/Documents?and?Settings/*/Recent',
    '*/Cache',
    '*/parent.lock',
    '*/Thumbs.db',
    '*/IconCache.db',
    '*/System?Volume?Information',
    '*/Temp/*',
    '*.tmp',
    '*.bak',
    '*/WINDOWS/system32/config/SYSTEM',
    '*/WINDOWS/system32/config/SOFTWARE',
    '*/WINDOWS/system32/config/SECURITY',
    '*/WINDOWS/system32/config/SECURITY.LOG',
    '*/WINDOWS/system32/config/SAM',
    '*/WINDOWS/system32/config/SAM.LOG',
    '*/WINDOWS/system32/config/DEFAULT',
  ]
};
$Conf{BackupsDisable} = 1;

