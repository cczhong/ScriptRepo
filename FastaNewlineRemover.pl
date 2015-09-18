#!/usr/bin/perl -w
use strict;
use Getopt::Long;

my $fasta_file;			# the multi-fasta file
my $out;			# the output file for the filtered list
my $min_len = 0;		# minimum length to be output
my $help;			

GetOptions (
  "fasta=s" => \$fasta_file,
  "out=s" => \$out,
  "min_len=i" => \$min_len,
  "help" => \$help
) or die("Error in command line arguments\n");

# print help information
if($help || !defined $fasta_file || !defined $out)  {
  print "\n";  
  print "****************************************\n";
  print "Removes new-line characters in sequences\n in multi-fasta format.\n";
  print "****************************************\n";
  print "Usage: perl FastaNewlineRemover.pl --fasta=[FASTA_FILE] --out=[OUTPUT_FILE]\n";
  print "	--fasta:	the multi-fasta file that contains the sequences\n";
  print "	--out:		the file in which the sequences are written into\n";
  print "	--min_len:	the minimum length for the sequence to be output (default: 0)\n";
  print "	--help:		print this help information\n";
  exit;
}

sub FastaToHash($$)  {
  my $file = shift;
  my $hash = shift;
  # read file line by line
  open my $IN, "<$file" or die "Cannot open FASTA file, please check input: $!\n";
  my $id;
  while(<$IN>)  {
    chomp;
    my $line = $_;
    if($line =~ /^>/)  {
      $id = $_;
      $hash->{$id} = "";
      #print "$id\n";
    }  else  {
      $hash->{$id} = $hash->{$id} . $_;
      #print "$_\n";
    }
  }
  close $IN;
  return;
}

my %seq_hash;
FastaToHash($fasta_file, \%seq_hash);
open my $OUT, ">$out" or die "Cannot open create file for output, please check input: $!\n";
foreach(sort keys %seq_hash)  {
  if(length($seq_hash{$_}) >= $min_len)  {
    print $OUT "$_\n$seq_hash{$_}\n";
  }
}
close $OUT;
