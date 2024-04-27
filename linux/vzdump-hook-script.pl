#!/usr/bin/perl -w

# Example hook script for vzdump (--script option)
# This can also be added as a line in /etc/vzdump.conf

use strict;
print "HOOK: " . join (' ', @ARGV) . "\n";

my $phase = shift;

if ($phase eq 'job-init' || $phase eq 'job-start' || $phase eq 'job-end'  || $phase eq 'job-abort') {

    # undef for Proxmox Backup Server storages
    # undef in phase 'job-init' except when --dumpdir is used directly
    my $dumpdir = $ENV{DUMPDIR};
    my $storeid = $ENV{STOREID};        # undef when --dumpdir is used directly

    print "HOOK-ENV: ";
    print "dumpdir=$dumpdir;" if defined($dumpdir);
    print "storeid=$storeid;" if defined($storeid);
    print "\n";

    # example: wake up remote storage node and enable storage
    if ($phase eq 'job-init') {

    } # end if

    # do what you want
        if ($phase eq 'job-end') {

        } # end if


} elsif ($phase eq 'backup-start' || $phase eq 'backup-end' || $phase eq 'backup-abort' || $phase eq 'log-end' ||  $phase eq 'pre-stop' || $phase eq 'pre-restart' || $phase eq 'post-restart') {

    my $mode = shift; # stop/suspend/snapshot
    my $vmid = shift;
    my $vmtype = $ENV{VMTYPE}; # lxc/qemu
    my $dumpdir = $ENV{DUMPDIR};                # undef for Proxmox Backup Server storages
    my $storeid = $ENV{STOREID};                # undef when --dumpdir is used directly
    my $hostname = $ENV{HOSTNAME};
    my $target = $ENV{TARGET};                  # target is only available in phase 'backup-end'
    my $logfile = $ENV{LOGFILE};        # logfile is only available in phase 'log-end'  # undef for Proxmox Backup Server storages

    print "HOOK-ENV: ";

    for my $var (qw(vmtype dumpdir storeid hostname target logfile)) {
                print "$var=$ENV{uc($var)};" if defined($ENV{uc($var)});
    } # for

    print "\n";

    # example: copy resulting backup file to another host using scp
    if ($phase eq 'backup-end') {
        system("./etc/vzdump-hook-sub-insert-mysql.sh ".$vmid);
    } # end if

    # example: copy resulting log file to another host using scp
    if ($phase eq 'log-end') {

    } # end if

} else {

    die "got unknown phase '$phase'";
} # end if

exit (0);
