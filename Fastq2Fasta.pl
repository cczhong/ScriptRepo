#!/usr/bin/perl -w
use strict;
use Getopt::Long;

my $fq_file;
my $fa_file;
my $min_len = 10;

GetOptions (
  "fq=s" => \$fq_file,
  "fa=s" => \$fa_file,
  "l=i" => \$min_len,
) or die("Error in command line arguments\n");

if(!defined $fq_file || !defined $fa_file)  {
  print "Fastq2Fasta.pl:  convert FASTQ format to FASTA format\n";
  print "Usage: perl Fastq2Fasta.pl --fq=[FASTQ_FILE] --fa=[FASTA_FILE]\n";
  print " --fq:   the FASTQ file\n";
  print " --fa:   the FASTA file\n";
  print " --l:    the minimum length to be output\n";
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
    my $header = $line;
    #print $OUT "$line\n";
    $line = <$IN>; ++ $n;
    my $seq = $line;
    if(length($seq) >= $min_len)  {
      print $OUT "$header\n$seq";
    }
  }
}
close $IN;
close $OUT;
