#!/usr/bin/perl -w
use strict;
use Getopt::Long;

my $sam_file;			# the SAM file
my $out;			# the output file for the wig file
my $span = 1;			# the span of the wig file
my $name = $sam_file;		# name to be written as the header
my $desc = $sam_file;		# description to be written

GetOptions (
  "sam=s" => \$sam_file,
  "out=s" => \$out,
  "span=i" => \$span,
  "name=s" => \$name,
  "desc=s" => \$desc
) or die("Error in command line arguments\n");

# print help information
if(!defined $sam_file || !defined $out)  {
  print "\n";
  print "SAM2Wiggle.pl: Convert SAM file to WIG file for UCSC genome browser visualization.\n";  
  print "Usage: perl SAM2Wiggle.pl --sam=[SAM_FILE] --out=[OUTPUT_FILE]\n";
  print "	--sam:		the multi-fasta file that contains the sequences\n";
  print "	--out:		the file in which the filtered sequences are written into\n";
  print "	--span:		treat IDs as keywords (instead of strict match)\n";
  print "	--name:		the name of the track to be included in the header\n";
  print "	--desc:		the description of the track to be included in the header\n";
  exit();
}

open my $OUT, ">$out" or die "Cannot create file: $!\n";
print $OUT "track type=wiggle_0 name=\"$name\" description=\"$desc\"\n";

# loads in the SAM information
my %read_map;
open my $IN, "<$sam_file" or die "Cannot open file: $!\n";
while(<$IN>)  {
  next if(/^\@/);	# skip header
  chomp;
  my @decom = split /\s+/, $_;
  my @info;
  push @info, $decom[3]; push @info, $decom[3] + length($decom[9]) - 1;
  push @{$read_map{$decom[2]}}, \@info;
}
close $IN;

# sort the reads mapped to each chromosome
foreach(keys %read_map)  {
  @{$read_map{$_}} = sort {$a->[0] <=> $b->[0] || $a->[1] <=> $b->[1]} @{$read_map{$_}};
}

# convert to WIGGLE files
foreach(sort keys %read_map)  {
  my $chrom = $_;
  my @chunk;
  my $prev_end;
  for(my $i = 0; $i < scalar(@{$read_map{$chrom}}); ++ $i)  {
    if(!@chunk || 
      ($prev_end >= ${$read_map{$chrom}}[$i][0] && $prev_end <= ${$read_map{$chrom}}[$i][1]) 
    )  {
      my @info;
      push @info, ${$read_map{$chrom}}[$i][0];
      push @info, ${$read_map{$chrom}}[$i][1];
      push @chunk, \@info;
      $prev_end = ${$read_map{$chrom}}[$i][1];
    }  else  {
      my $begin = ${$chunk[0]}[0];
      my $end = ${$chunk[-1]}[1];
      my %count_hash;
      for(my $k = 0; $k < scalar(@chunk); ++ $k)  {
        for(my $n = ${$chunk[$k]}[0]; $n <= ${$chunk[$k]}[1]; ++ $n)  {
          ++ $count_hash{$n};
        }
      }
      undef @chunk;
      print $OUT "variableStep	chrom=$chrom	span=$span\n";
      for(my $k = $begin; $k <= $end; $k += $span)  {
        my $count = 0;
        for(my $n = 0; $n < $span; ++ $n)  {
          $count += $count_hash{$k + $n} if exists $count_hash{$k + $n};
        }
        $count /= $span;
        print $OUT "$k	$count\n";
      }
    }
  }
  # deal with the last chunk
  if(@chunk)  {
    my $begin = ${$chunk[0]}[0];
    my $end = ${$chunk[-1]}[1];
    my %count_hash;
    for(my $k = 0; $k < scalar(@chunk); ++ $k)  {
      for(my $n = ${$chunk[$k]}[0]; $n <= ${$chunk[$k]}[1]; ++ $n)  {
        ++ $count_hash{$n};
      }
    }
    undef @chunk;
    print $OUT "variableStep	chrom=$chrom	span=$span\n";
    for(my $k = $begin; $k <= $end; $k += $span)  {
      my $count = 0;
      for(my $n = 0; $n < $span; ++ $n)  {
        $count += $count_hash{$k + $n} if exists $count_hash{$k + $n};
      }
      $count /= $span;
      print $OUT "$k	$count\n";
    }
  }
}
close $OUT;

#foreach(keys %read_map)  {
#  print "$_\n";
#}
#my $chr = "chr1";
#for(my $i = 0; $i < scalar(@{$read_map{$chr}}); ++ $i)  {
#  print "${$read_map{$chr}}[$i][0]	${$read_map{$chr}}[$i][1]\n";
#}
