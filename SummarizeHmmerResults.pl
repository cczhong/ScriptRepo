#!/usr/bin/perl -w
use strict;
use Getopt::Long;

# This an in-house script is used to parse HMMER3 hmmsearch results
# Can be used to tabulate the results or used to cut the identified sequences

my $hmm_full_file;		# the hmmsearch result file
my $peptide_file;		# the target peptide file in multi-fasta format
my $out;			# output file
my $e_cutoff = 0.01;		# E-value cutoff
my $max_overlap = 10;		# maximum length of overlap to distinguish two individal regions
my $min_length = 20;		# miminum length of identified region to output
my $col_E = 6;			# column ID for E-value
my $col_BG = 10;		# column ID for target begin
my $col_ND = 11;		# column ID for target end
my $get_seq;			# whether print sequence

GetOptions(
  "results=s" => \$hmm_full_file,
  "seq=s" => \$peptide_file,
  "out=s" => \$out,
  "cutoff=s" => \$e_cutoff,
  "max_overlap=i" => \$max_overlap,
  "min_length=i" => \$min_length,
  "colE=i" => \$col_E,
  "colBG=i" => \$col_BG,
  "colND=i" => \$col_ND,
  "get_seq" => \$get_seq
) or die "Error in command-line arguments!\n";

if(!defined $hmm_full_file || !defined $out || (defined $get_seq && !defined $peptide_file))  {
  print "SummarizeHmmerResults.pl: Script for parsing HMMER3 hmmsearch results\n";
  print "Usage: perl SummarizeHmmerResults.pl --results=[RAW_HMMER_RESULTS] --out=[OUTPUT_FILE]\n";
  print "	--results:	the raw HMMER3 hmmsearch results (in default format)\n";
  print "	--out:		the output file\n";
  print "	--get_seq:	output identified sequences intead of tabulated info\n";
  print "	--seq:		the target sequence file for the search, required if \'getseq\' enabled\n";
  print "	--cutoff:	the E-value cutoff for the hits, default 0.01\n";
  print "	--max_overlap:	the maximum overlap allowed between two distinct regions (or they will be considered to be the same region and can only have one annotation), default 10\n";
  print "	--min_length:	the minimum length of the identified region to be output, default 20\n";
  print "	--colE:		the column ID (0-based) for E-value (default HMMER:6, OR INFERNAL: 3; other values might cause errors)\n";
  print "	--colBG:	the column ID for target sequence begin (default 10 for both HMMER and INFERNAL)\n";
  print "       --colND:        the column ID for target sequence end (default 11 for both HMMER and INFERNAL)\n";
  exit();
}

open my $IN, "<$hmm_full_file" or die "Cannot open result file: $!\n";

my $name;
my $id;
my $target;
my %identified_regions;
while(<$IN>)  {
  chomp;
  if(/^Query:\s+(\S+)/)  {
    $name = $1;
    $id = "NA";
  } elsif(/^Accession:\s+(.*)/)  {
    $id = $1;
  } elsif(/^>>\s+(\S+)/)  {
    $target = $1;
  } elsif((/\?/ || /\!/) && (/\[/ || /\]/))  {
    my @decom = split /\s+/, $_;
    #print "$name	$id	$decom[$col_E]	$decom[$col_BG]	$decom[$col_ND]\n";
    my @info = ($name, $id, $decom[$col_E], $decom[$col_BG], $decom[$col_ND]);
    if($decom[$col_E] <= $e_cutoff)  {
      push @{$identified_regions{$target}}, \@info;
    }
  }
}

# load in the target sequence if necessary
my %seq_hash;
if($get_seq)  {
  open my $PIN, "<$peptide_file" or die "Cannot open sequence file: $!\n";
  while(<$PIN>)  {
    chomp;
    if(/^>(\S+)/)  {
      my $id = $1;
      my $line = <$PIN>;
      chomp $line;
      $seq_hash{$id} = $line;
    }
  }
  close $PIN;
}

sub GetOverlap($$$$)  {
  my $a = shift;
  my $b = shift;
  my $c = shift;
  my $d = shift;
  if($a <= $c and $b >= $d)  {
    return $d - $c + 1;
  }  elsif($c <= $a and $d >= $b)  {
    return $b - $a + 1;
  }  elsif($b < $c or $a > $d)  {
    return 0;
  }  elsif($a <= $c and $c <= $b and $b <= $d)  {
    return $b - $c + 1;
  }  elsif($c <= $a and $a <= $d and $d <= $b)  {
    return $d - $a + 1;
  }
  die "ERROR:	$a	$b	$c	$d\n";
}

# get the domain-annotated sequence
open my $OUT, ">$out" or die "Cannot create file: $!\n";
my $n = 0;
foreach(keys %identified_regions)  {
  my $target_seq = $_;
  #print "$target_seq\n";
  my @regions = @{$identified_regions{$target_seq}};
  @regions = sort {$a->[2] <=> $b->[2]} @regions;
  my @checked;
  foreach(@regions)  {
    my $region = $_;
    my $mo = 0;
    for(my $i = 0; $i < scalar(@checked); ++ $i)  {
      my $overlap = GetOverlap($checked[$i][0], $checked[$i][1], $region->[3], $region->[4]);
      $mo = $overlap if $overlap > $mo;
    }
    # if no signficant overlap with the already identified region
    if($mo <= $max_overlap and $region->[4] - $region->[3] + 1 >= $min_length)  {
      # get the sequence
      if($get_seq)  {
        my $seq = substr($seq_hash{$target_seq}, $region->[3] - 1, $region->[4] - $region->[3] + 1);
        print $OUT ">domain_$n||$target_seq||$region->[0]||$region->[1]\n$seq\n";
      }  else  {
        print $OUT "$region->[0]	$target_seq	$region->[1]	$region->[2]	$region->[3]	$region->[4]\n";
      }
      ++ $n;
      # mark the region
      my @r = ($region->[3], $region->[4]);
      push @checked, \@r;
    }
  }
}
close $OUT;
