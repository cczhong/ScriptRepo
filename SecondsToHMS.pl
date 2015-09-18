#!/usr/bin/perl -w
use strict;
use Getopt::Long;

my $time_in_sec;		# the elasped time in seconds

GetOptions (
  "sec=i" => \$time_in_sec
) or die "Error in argument parsing: $!\n";

if(!defined $time_in_sec)  {
  print "SecondToHMS.pl: transform raw seconds in to ??h??m??s format\n";
  print "Usage: perl SecondToHMS.pl --sec=[NUM_SECONDS]\n";
  print "	--sec:		number of seconds, integer type\n";
  exit();
}

my $h = int($time_in_sec / 3600);
my $left = $time_in_sec % 3600;
my $m = int ($left / 60);
my $s = $left % 60;

printf("%uh%um%us\n", $h, $m, $s);
