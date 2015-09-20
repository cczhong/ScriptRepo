#!/usr/bin/perl -w
use strict;
use Getopt::Long;

my $vcf_file;		# the multi-vcf file
my $out_folder;		# the output folder for the individual vcf files

GetOptions(
  "vcf=s" => \$vcf_file,
  "out=s" => \$out_folder
) or die "Error in command line arguments\n";

if(!defined $vcf_file || !defined $out_folder)  {
  print "SplitMultiVCF.pl: split multi-VCF file into individual VCF files\n";
  print "Usage: perl SplitMultiVCF.pl --vcf=[VCF_FILE] --out=[OUTPUT_FOLDER]\n";
  print "	--vcf:	multi-VCF file\n";
  print "	--out:	output folder for individual vcf files\n";
}

# create folder if not exists
if(!(-e $out_folder))  {
  mkdir "$out_folder" or die "Cannot create output folder: $!\n";
}

# parse the VCF file
my @format;
my $header = "";
my @individual_id;
my @individual_info;
my $info_col;
my $num_col;
open my $VIN, "<$vcf_file" or die "Cannot open file: $!\n";
while(<$VIN>)  {
  chomp;
  if(/^\#\#/)  {
    push @format, $_;
  }  elsif(/^\#/)  {
    # resolve the column ID of each individual
    my @decom = split /\s+/, $_;
    $num_col = scalar(@decom);
    my $i;
    # determine the last column for the variant information
    for($i = 0; $i < scalar(@decom); ++ $i)  {
      $header = $header . $decom[$i] . "\t";
      if($decom[$i] eq "FORMAT")  {
        $info_col = $i;
        last;
      }
    }
    # record the individual IDs
    for($i = $info_col + 1; $i < scalar(@decom); ++ $i)  {
      push @individual_id, $decom[$i];
    }
  }  else  {
    # parse each line
    my @decom = split /\s+/, $_;
    if(scalar(@decom) != $num_col)  {
      print "Warning: incompatible num. of columns compared with header...VCF file may be corrupted\n";
      next;
    }
    my $info = "";
    my $i;
    for($i = 0; $i <= $info_col; ++ $i)  {
      $info = $info . $decom[$i] . "\t";
    }
    for($i = $info_col + 1; $i < scalar(@decom); ++ $i)  {
      if($decom[$i] =~ /0\|0/ || $decom[$i] =~ /0\/0/ || $decom[$i] =~ /\.\|\./ || $decom[$i] =~ /\.\/\./)  {
        next;
      }
      # if the individual contains the variant
      my $indiv_info = $info . $decom[$i];
      push @{$individual_info[$i - $info_col - 1]}, $indiv_info;
    }
  }
}
close $VIN;

# print information
my $i;
for($i = 0; $i < scalar(@individual_id); ++ $i)  {
  open my $OUT, ">$out_folder/$individual_id[$i].vcf" or die "Cannot create file: $!\n";
  foreach(@format)  {
    print $OUT "$_\n";
  }
  print $OUT "$header	$individual_id[$i]\n";
  foreach(@{$individual_info[$i]})  {
    print $OUT "$_\n";
  }
  close $OUT;
}
