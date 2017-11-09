#!/usr/bin/perl -w
use strict;
use Getopt::Long;

my $exp_file;
my $mode = 0;
my $out;
my $help;

GetOptions(
  "file=s" => \$exp_file,   # expecting expression table
  "mode=i" => \$mode,       # decide how to merge the expression values
  "out=s" => \$out,         # the output file
  "help" => \$help
) or die "Error in argument parsing: $!\n";


if($help || !defined $exp_file || !defined $out || ($mode != 0 && $mode != 1))  {
  print "CheckExpTableDuplicate.pl: check for whether the key has duplicate, if yes, merge them according to the mode\n";
  print "Usage: perl CheckExpTableDuplicate.pl --file=[EXP FILE] --out=[OUTPUT]\n";
  print "--file:\tthe expression table, the first row is row names and the first column is the IDs that needs to be unique,\n";
  print "--out:\tthe output file\n";
  print "--mode:\t0: compute sum of the values (default); 1: compute ave of the values\n";
  print "--help:\tprint this information\n";
  exit();
}

open my $IN, "<$exp_file" or die "Cannot open file: $!\n";
my $header = <$IN>;
my %hash;
my %count_hash;
while(<$IN>) {
  chomp;
  my @decom = split /\t+/, $_;
  if(!exists $hash{$decom[0]})  {
    $hash{$decom[0]} = \@decom;
    $count_hash{$decom[0]} = 1;
  } else  {
    for(my $i = 1; $i < scalar(@decom); ++ $i) {
      ${$hash{$decom[0]}}[$i] += $decom[$i];
    }
    $count_hash{$decom[0]} ++;    
  }
}
close $IN;

open my $OUT, ">$out" or die "Cannot create file: $!\n";
print $OUT "$header";
foreach(keys %hash) {
  print $OUT "$_\t";
  my @toprint;
  my $n = scalar(@{$hash{$_}});
  my $i;
  for($i = 1; $i < $n - 1; ++ $i) {
    push @toprint, "${$hash{$_}}[$i]" if $mode == 0;
    my $a = ${$hash{$_}}[$i] / $count_hash{$_};
    push @toprint, "$a" if $mode == 1;
  }
  for($i = 0; $i < scalar(@toprint) - 1; ++ $i) {
    print $OUT "$toprint[$i]\t";
  }
  print $OUT "$toprint[$i]\n";
}
close $OUT;
