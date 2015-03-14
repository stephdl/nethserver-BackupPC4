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

package BackupPC::SMEarchive;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(%path %opts &checkExec &checkDest &init &readConf &logAndPerform &sendMail &genRandName &mvLog &localArchive &mountUsb &umountUsb &remoteArchive);

use strict;
use Mail::Send;
use Getopt::Std;


our %path=();
$path{backuppcBin} = '/usr/share/BackupPC/bin/';
$path{split} = '/usr/bin/split';
$path{date} = '/bin/date';
$path{rm} = '/bin/rm';
$path{rmdir} = '/bin/rmdir';
$path{cat} = '/bin/cat';
$path{mkdir} = '/bin/mkdir';
$path{par2} = '/bin/ping';
$path{ssh} = '/usr/bin/ssh';
$path{mount} = '/bin/mount';
$path{umount} = '/bin/umount';
$path{grep} = '/bin/grep';
$path{wc} = '/usr/bin/wc';
$path{sudo} = '/usr/bin/sudo';
$path{gzip} = '/bin/gzip';
$path{bzip2} = ( -x '/usr/bin/pbzip2' ) ? '/usr/bin/pbzip2' : '/usr/bin/bzip2';
$path{rsync} = '/usr/bin/rsync';
$path{tar} = '/bin/tar';
$path{openssl} = '/usr/bin/openssl';
$path{nice} = '/bin/nice';

sub checkExec{
	# On vérifie que les executables sont bien executables
	my $ok = 1;
	foreach (keys %path){
		if (!-x $path{$_}){$ok = 0;}
	}
	return $ok;
}

sub checkDest{
	# On vérifie les droits d'écriture sur la destination
	my ($destination) = @_;
	my $ok = 0;
	logAndPerform("$path{mkdir} $destination") if (!-d $destination);
	if ((-w $destination) && (-d $destination)){$ok = 1;}
	return $ok;
}

# Fonciton qui récupère les arguments, et remplace le fichier de conf si spécifié
sub init{
	my ($configFile) = @_;
	my %opts;
	getopts ("hf:", \%opts) || help();

	$opts{h} = '0' if (! defined $opts{h});
	if (defined $opts{f}){
		if (-e $opts{f}){
			print STDERR "using $opts{f} as config file instead of default\n";
			$configFile = $opts{f};
		}
		else{
			print STDERR "\nIgnoring specified config file $opts{f} because this file doesn't exist. Using default one\n";
		}
	}
	help () if ($opts{h});
	return $configFile;
}

sub help(){
  	print <<EOF;
  	usage: $0 [-h] [-f config]
 
  	options:
	-h 			print this help
	-f config		use config instead of default one.
     
EOF
    exit(1);
}

# Fonction qui parse le fichier de config
sub readConf($){
	my $hRef = shift;
	my %params;
	foreach my $key ( keys %$hRef){    
		$params{$key} = $hRef->{$key};
	}
	open (PARAMS,"< $params{configFile}") || die "erreur a l'ouverture de $params{configFile}\n";
   	my @params_lus=<PARAMS>;
   	close PARAMS;
    print STDERR "Parsing config file\n\n";
   	foreach (@params_lus){
    	foreach my $key (keys(%params)){
            # valeur = partie droite de la ligne contenant $key dans le fichier
          	if ($_ =~ /\s*$key\s*=\s*(.*)/){
         		$params{$key} = $1;
                print STDERR "key=\"$key\", value=\"$params{$key}\"\n";
           	}
       	}
	}
	print STDERR "\n\n";
	return (%params);
}

# Fonction qui log les commandes et qui les éxecute
sub logAndPerform($){
	my ($cmd) = @_;
	print STDERR "\nexecuting command\n$cmd\n\n";
	system($cmd);
}

# Fonction qui envoie le mail contenant le log
sub sendMail($$$){
	my ($sendMailTo,$about,$content) = @_;
	my $mail = new Mail::Send;
	$mail->to("$sendMailTo");
	$mail->set("From","BackupPC");
	$mail->subject("$about");
	my $body = $mail->open;
	print $body $content;
	$body->close;
}

# fonction qui génère un nom aléatoire pour les fichiers temporaires
sub genRandName (){
	my @c=("A".."Z","a".."z",0..9);
	my $randomName = join("",@c[map{rand @c}(1..8)]);
	return $randomName;
}

# fonction qui déplace le fichier de log au bon endroit
sub mvLog($$$){
	my ($type,$file,$today) = @_;
	if (! -d "/var/log/BackupPC/$type/"){
		logAndPerform("$path{mkdir} -p /var/log/BackupPC/$type/");
	}
	my $content = `$path{cat} $file`;
	open(LOGFILE, "> /var/log/BackupPC/$type/$today");
	print LOGFILE $content;
	close LOGFILE;
	system("$path{rm} -f $file");
}

sub localArchive($$$$$$$$){
	my ($hosts,$backupNum,$share,$compress,$split,$cipher,$key,$destination) = @_;
	my $check = 1;
	my $extension = 'tar';
	# on fixe l'extension de l'archive en fonction de la compression utilisée
	if ($compress eq 'gzip'){$extension = 'tar.gz';}
	elsif ($compress eq 'bzip2'){$extension = 'tar.bz2';}
	else{$extension = 'tar';}
	
	if (! checkExec()){
		print STDERR "\nError, one of the needed executable is not executable\n";
		$check = 0;
	}
	if (! checkDest($destination)){
		print STDERR "\nError, $destination is not writable\n";
		$check = 0;
	}
	#if (! checkHosts($params{checkHosts}){
	#	print STDERR "\nError, $hosts is not a valid list of hosts\n";
	#	$check = 0;
	#}

	if ($check eq 1){
		my @hosts = split(/\s/,$hosts);

		# On supprime toutes les archives existantes sur la destination pour éviter la fragmentation
		logAndPerform("$path{rm} -f $destination/*.$extension");

		foreach my $host (@hosts){
			my $cmd = "$path{backuppcBin}/BackupPC_tarCreate -t -h $host -n $backupNum -s $share . ";
			if (($compress eq 'gzip') || ($compress eq 'bzip2')){
				$cmd .= "| $path{nice} -n 10 $path{$compress} -c ";
			}
			if (($cipher ne 'off') && (-e $key)){
                                $cmd .= "| $path{nice} -n 10 $path{openssl} enc -$cipher -salt -pass file:$key";
				$extension .= '.enc';
			}
			if ($split eq '0'){
				$cmd .= "> $destination/$host.$backupNum.$extension";
			}
			else{
				$cmd .= "| $path{split} - -b $split"."m"."$destination/$host.$backupNum.$extension.";
			}
			logAndPerform($cmd);
		}
	}
	else{
		print STDERR "\nFatal error, aborting\n";
	}
}

sub mountUsb($$){
	my ($destination,$device) = @_;
	my $ok = 0;
	if (!-e $destination){
		logAndPerform("$path{mkdir} -p $destination");
	}
	if (!-e $destination){
		print STDERR "\n\n$destination doesn't exist and cannot be created\n\n";
	}
	else{
		logAndPerform("$path{sudo} $path{mount} $device $destination");
		$ok = `$path{mount} | $path{grep} $destination | $path{wc} -l`;
		chomp($ok);
	}
	return $ok;
}

sub umountUsb($$){
	my ($destination,$device) = @_;
	my $ok = 0;
	my $isMounted = `$path{mount} | $path{grep} $destination | $path{wc} -l`;
	chomp($isMounted);
	if ($isMounted eq '1'){
		print STDERR "\n$device seems to be mounted, lets umount it\n";
		logAndPerform("$path{sudo} $path{umount} -f $destination");
	}
	else{
		print STDERR "\n\nError: $device seems to be already unmounted\n\n";
	}
	$isMounted = `$path{mount} | $path{grep} $destination | $path{wc} -l`;
	chomp($isMounted);
	if ($isMounted eq '1'){
		print STDERR "\nError: $device seems to be buzy, lets try to umount it lazily\n";
		logAndPerform("$path{sudo} $path{umount} -fl $destination");
	}
	$isMounted = `$path{mount} | $path{grep} $destination | $path{wc} -l`;
	chomp($isMounted);
	if ($isMounted eq '1'){
		print STDERR "\nError: $device seems to be buzy, lazy umount has failed\n";
	}
	if ($isMounted eq '0'){
		logAndPerform("$path{rmdir} $destination");
	}
	$isMounted = `$path{mount} | $path{grep} $destination | $path{wc} -l`;
	chomp($isMounted);
	if ($isMounted eq '0'){
		$ok = 1;
	}
	return $ok;
}

sub remoteArchive($$$$$$$$$){
	my ($remoteHost,$remoteUser,$remoteDir,$hosts,$backupNum,$share,$compress,$cipher,$key) = @_;
	my $check = 1;
	my $extension = 'tar';
	# on fixe l'extension de l'archive en fonction de la compression utilisée
	if ($compress eq 'gzip'){$extension = 'tar.gz';}
	elsif ($compress eq 'bzip2'){$extension = 'tar.bz2';}
	else{$extension = 'tar';}
	
	if (! checkExec()){
		print STDERR "\nError, one of the needed executable is not executable\n";
		$check = 0;
	}

	if ($check eq 1){
		my @hosts = split(/\s/,$hosts);

		foreach my $host (@hosts){
			my $cmd = "$path{backuppcBin}/BackupPC_tarCreate -t -h $host -n $backupNum -s $share . ";
			if (($compress eq 'gzip') || ($compress eq 'bzip2')){
				$cmd .= "| $path{$compress} -c ";
			}
			if (($cipher ne 'off') && (-e $key)){
				$cmd .= "| $path{openssl} enc -$cipher -salt -pass file:$key";
                                $extension .= '.enc';
			}
			$cmd .= " | $path{ssh} -l $remoteUser $remoteHost \"(cd $remoteDir && $path{cat} > $remoteDir/$host.$backupNum.$extension)\"";
			
			logAndPerform($cmd);
		}
	}
	else{
		print STDERR "\nFatal error, aborting\n";
	}

}

1;
