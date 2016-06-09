#!/usr/bin/perl -w
use strict;
use Getopt::Long;

my $file;			# the file to search
my $pfile;			# the file that contains the patterns, one per line
my $out;			# the output file			

GetOptions (
  "file=s" => \$file,
  "patterns=s" => \$pfile,
  "out=s" => \$out
) or die("Error in command line arguments\n");

# print help information
if(!defined $file || !defined $pfile || !defined $out)  {  
  print "KeywordSearchBatch.pl: match any of the patterns in the file.\n";
  print "Usage: perl KeywordSearchBatch.pl --file=[FILE] --patterns=[PATTERNS] --out=[OUTPUT]\n";
  print "	--file:		the file to search\n";
  print "	--patterns:	the file that contains the patterns to search, one per line\n";
  print "	--out:		the output file for matched rows\n";
  exit();
}

# reads in the pattern
my @patterns;
open my $PIN, "<$pfile" or die "Cannot open file <$pfile>: $!, please check input.\n";
while(<$PIN>)  {
  chomp;
  push @patterns, $_;
}
close $PIN;

# check file line by line
open my $IN, "<$file" or die "Cannot open file <$file>: $!, please check input.\n";
open my $OUT, ">$out" or die "Cannot create file <$out>: $!, please check input.\n";
while(<$IN>)  {
  chomp;
  my $line = $_;
  foreach(@patterns)  {
    if($line =~ /$_/)  {
      print  $OUT "$line\n";
      last;
    }
  }
}
close $OUT;
close $IN;
