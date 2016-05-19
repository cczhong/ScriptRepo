#!/usr/bin/perl -w
use strict;
use Getopt::Long;

my $fq_file;
my $fa_file;

GetOptions (
  "fq=s" => \$fq_file,
  "fa=s" => \$fa_file
) or die("Error in command line arguments\n");

if(!defined $fq_file || !defined $fa_file)  {
  print "Fastq2Fasta.pl:  convert FASTQ format to FASTA format\n";
  print "Usage: perl Fastq2Fasta.pl --fq=[FASTQ_FILE] --fa=[FASTA_FILE]\n";
  print " --fq:   the FASTQ file\n";
  print " --fa:   the FASTA file\n";
  exit;
}

open my $IN, "<$fq_file" or die "Cannot open FASTQ file: $!\n";
open my $OUT, ">$fa_file" or die "Cannot create FASTA file: $!\n";
my $n = 0;
while(<$IN>)  {
  chomp;
  my $line = $_;
  ++ $n;
  if($n % 4 == 1 && $line =~ /^\@/)  {
    $line =~ s/^\@/\>/;
    print $OUT "$line\n";
    $line = <$IN>; ++ $n;
    print $OUT "$line";
  }
}
close $IN;
close $OUT;
