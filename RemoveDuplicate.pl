#!/usr/bin/perl -w
use strict;
use Getopt::Long;

# removes duplicate keys from a file
my $file;		# the input file
my $col;		# the column in which the de-duplication to be performed
my $out;		# the output file

GetOptions  (
  "file=s" => \$file,
  "col=i" => \$col,
  "out=s" => \$out
) or die "Error in command-line arguments!\n";

if(!defined $file || !defined $col || !defined $out)  {
  print "RemoveDuplicate.pl: removes duplicated entries in a column and output unique entries.\n";
  print "Usage: perl RemoveDuplicate.pl --file=[FILE] --col=[COLUMN_ID] --out=[OUTPUT_FILE]\n";
  print "	--file:		the input file name\n";
  print "	--col:		the column ID\n";
  print "	--out:		the output file\n";
  exit();
}

open my $IN, "<$file" or die "Cannot open file <$file>: $!, please check input\n";
open my $OUT, ">$out" or die "Cannot create file <$out>: $!, please check input\n";
my %id_hash;
for(<$IN>)  {
  chomp;
  my @decom = split /\s+/, $_;
  die "Row does not contain $col columns.\n" if scalar(@decom) < $col + 1;
  $id_hash{$decom[$col]} ++;
}
close $IN;
foreach(keys %id_hash)  {
  print $OUT "$_	$id_hash{$_}\n";
}
close $OUT;
