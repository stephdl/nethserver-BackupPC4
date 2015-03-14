# 	Author: Daniel Berteaud (daniel@firewall-services.com)

#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

package BackupPC::SMEcopyPool;
use lib "/usr/share/BackupPC/lib";
use BackupPC::SMEarchive;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(&verifTree &stopBackupPC &startBackupPC &copyPool &localCopyPC &remoteCopyPC);

# Fonction qui vérifie (grossièrement) l'arborescence de la source pour la copie de pool
sub verifTree($){
	my ($source) = @_;
	print STDERR "\ntesting $source\n";
	my $ok = 1;
	foreach ("$source","$source/pc","$source/pool","$source/cpool"){
		if (!-d "$_"){
			print STDERR "$_ is not a valid directory, aborting\n";
			$ok = 0;
		}
	}
	return $ok;
}

# Fonction qui arrête le service BackupPC
sub stopBackupPC(){
	if (-e '/var/log/BackupPC/BackupPC.pid'){
		$pid = `$path{cat} /var/log/BackupPC/BackupPC.pid`;
		print STDERR "BackupPC is running (pid=$pid), you have requested to stop it\n";
		logAndPerform("$path{sudo} /etc/rc.d/init.d/backuppc stop");
	}
	elsif ((! -e '/var/log/BackupPC/BackupPC.pid') && ($stop eq 'yes')){
		print STDERR "\nYou have requested to stop BackupPC daemon but it seems that it's not running\n";
	}
}

# Fonction qui démarre le service BackupPC
sub startBackupPC(){
	if (! -e '/var/log/BackupPC/BackupPC.pid'){
		print STDERR "\n\nrestarting BackupPC deamon\n\n";
		logAndPerform("$path{sudo} /etc/rc.d/init.d/backuppc start");
	}
}
# Fonction qui copie les données de backuppc sous forme brut
# Ne copie pas le répertoire pc/ (pb de hardlinks, gérés à part)
# Peut être utilisée pour une copie local ou distante
sub copyPool($$$$){
	my ($source,$destination,$logFile,$rsyncLog) = @_;
	
		 
	# Si /etc/BackupPC exist, on le sauvegarde dans $params{source}/etc
	if(-d '/etc/BackupPC'){
		logAndPerform("$path{mkdir} -p $source/etc") if (!-d "$source/etc");
		logAndPerform("$path{rsync} -ah --del --stats /etc/BackupPC/ $source/etc/ > $rsyncLog");
		print STDERR `$path{cat} $rsyncLog`;
	}
	# idem pour les logs
	if(-d '/var/log/BackupPC'){
		logAndPerform("$path{mkdir} -p $source/log") if (!-d "$source/log");
		logAndPerform("$path{rsync} -ah --del --stats /var/log/BackupPC/ $source/log/ > $rsyncLog");
		print STDERR `$path{cat} $rsyncLog`;
	}
	
	# commande qui sync en non récursif pour créer les rep nécessaires
	logAndPerform("$path{rsync} -qlptgoDHhd --stats --del $source/ $destination/ > $rsyncLog");
	print STDERR `$path{cat} $rsyncLog`;
	
	# la commande suivante sync tout sauf les rep pc, pool et cpool (pour éviter de saturer la ram)
	logAndPerform("$path{rsync} -ah --del --stats --exclude=cpool/ --exclude=pool/  --exclude=pc/ $source/ $destination/ > $rsyncLog");
	print STDERR `$path{cat} $rsyncLog`;
	
	# Maintenant, on sync le rep pool
	logAndPerform("$path{rsync} -ah --del --stats $source/pool/ $destination/pool/ > $rsyncLog");
	print STDERR `$path{cat} $rsyncLog`;
	
	# Puis le cpool
	logAndPerform("$path{rsync} -ah --del --stats $source/cpool/ $destination/cpool/ > $rsyncLog");
	print STDERR `$path{cat} $rsyncLog`;
	
}

# Fonction qui copie le répertoire pc/ vers un rep local (en utilisant BackupPC_tarPCCopy)
sub localCopyPC($$$$$){
	my ($source,$destination,$compress,$extract,$logFile) = @_;
	my $archName = 'pc.tar';
	my $cmd = ();
	my @pipe = ();
	my $tarOpts = 'xPf';
	my $main = '';
	
	# on vide le répertoire "pc"
	if ($destination ne ''){
		logAndPerform("$path{rm} -Rf $destination/pc/*");
	}

	push(@pipe,"$path{backuppcBin}/BackupPC_tarPCCopy $source/pc/ |");
	
	if ($compress eq 'gzip'){
		push (@pipe," $path{gzip} -c |");
		$archName = "pc.tar.gz";
		$tarOpts = 'xPzf';
	}
	elsif ($compress eq 'bzip2'){
		push (@pipe," $path{bzip2} -c |");
		$archName = "pc.tar.bz2";
		$tarOpts = 'xPjf';
	}
	if ($extract eq 'yes'){
		push (@pipe,"(cd $destination/pc/ && $path{tar} $tarOpts -)");
	}
	else{
		push (@pipe,"$path{cat} > $destination/pc/$archName");
	}
	
	foreach (@pipe){
		$main = $main.$_;
	}
	
	logAndPerform($main);
}

# Fonciton qui copie le rep pc/ sur une machine distante (toujours en utilisant BackuPPC_tarPCCopy)
sub remoteCopyPC($$$$$$$){
	my ($source,$remoteHost,$remoteUser,$remoteDir,$compress,$extract,$logFile) = @_;
	my $archName = 'pc.tar';
	my $cmd = ();
	my @pipe = ();
	my $tarOpts = 'xPf';
	my $main = '';
	
	# on vide le répertoire "pc"
	if ($remoteDir ne ''){
		logAndPerform("$path{ssh} -l $remoteUser $remoteHost \"$path{rm} -Rf $remoteDir/pc/*\"");
	}

	push(@pipe,"$path{backuppcBin}/BackupPC_tarPCCopy $source/pc/ |");
	
	if ($compress eq 'gzip'){
		push (@pipe," $path{gzip} -c |");
		$archName = "pc.tar.gz";
		$tarOpts = 'xPzf';
	}
	elsif ($compress eq 'bzip2'){
		push (@pipe," $path{bzip2} -c |");
		$archName = "pc.tar.bz2";
		$tarOpts = 'xPjf';
	}
	if ($extract eq 'yes'){
		push (@pipe,"$path{ssh} -l $remoteUser $remoteHost \"(cd $remoteDir/pc/ && $path{tar} $tarOpts -)\"");
	}
	else{
		push (@pipe,"$path{ssh} -l $remoteUser $remoteHost \"$path{cat} > $remoteDir/pc/$archName\"");
	}
	
	foreach (@pipe){
		$main = $main.$_;
	}
	
	logAndPerform($main);
}


1;
