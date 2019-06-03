#!/usr/bin/perl -w
use strict;
use Getopt::Long;

# randomly sub-sampling reads from the given FASTA file

my $fasta_file;		# the original fasta file
my $N = 50;		# the length cutoff (the number after the N)
my $min_len = 0;	# the minimum length of contig to be considered in the calulation

GetOptions (
  "fasta=s" => \$fasta_file,
  "N=f" => \$N,
  "min=i" => \$min_len
) or die("Error in command line arguments\n");

if(!defined $fasta_file)  {
  print "ComputeN50.pl: compute N50 for a given FASTA file\n";
  print "Usage: perl FastaSubSampling --fasta=[FASTA_FILE]\n";
  print "	--fasta:	the FASTA file that contains the contigs\n";
  print "	--N:		the N value (default: 50)\n";
  print "	--min:		the minimum contig length to be considered for the caculation\n\n";
  exit();
}

if($N <= 0 || $N >= 100)  {
  die "Error: the N value needs to be set between 0 and 100, abort\n";
}

my $total_length = 0;
my @lengths;
push @lengths, 0;
my $seq_len = 0;
open my $IN, "<$fasta_file" or die "Cannot open file: $!\n";
while(<$IN>)  {
  chomp;
  if(/^\>/)  {
    if($seq_len >= $min_len)  {
      push @lengths, $seq_len;
      $total_length += $seq_len;
    }
    $seq_len = 0;
    next;
  }
  $seq_len += length($_);
}
close $IN;

my $acc_len = 0;
@lengths = sort {$a <=> $b} @lengths;
for(my $i = scalar(@lengths) - 1; $i >= 0; -- $i)  {
  $acc_len += $lengths[$i];
  if($acc_len >= $total_length * $N / 100)  {
    print "The N$N for this contig set is $lengths[$i].\n";
    last;
  }
}

print "$total_length\n";
