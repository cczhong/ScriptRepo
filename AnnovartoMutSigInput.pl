#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Cwd 'abs_path';
use File::Basename;

# Converts ANNOVAR file MutSigCV input format
# According to instructions documented on https://www.broadinstitute.org/cancer/cga/mutsig_run
# Requires the region-based RefSeq annovar annotation file and human genome sequences

my $annovar_file;
my $genome;
my $out_file;

GetOptions(
  "annovar=s" => \$annovar_file,
  "genome=s" => \$genome,
  "out=s" => \$out_file
) or die "Error in argument parsing: $!\n";

if(!defined $annovar_file || !defined $genome || !defined $out_file)  {
  print "AnnovartoMutSigInput: Convert VCF file to MutSigCV input format\n";
  print "Usage: perl AnnovartoMutSigInput.pl --annovar=[ANNOVAR_EXON_FUNCTION] --genome=[HUMAN_GENOME_SEQ] --out=[OUTPUT_FILE]\n";
  print "	--annovar:		the annovar file for annotating the VCF against RefSeq\n";
  print "	--genome:		the human genome sequence, in FASTA format\n";
  print "	--out:			the output file\n";
  exit();
}

# Load in the human genome
my %hg;
my $chr_name;
open my $IN, "<$genome" or die "Cannot open file: $!\n";
while(<$IN>)  {
  chomp;
  if(/^>(.*)/)  {
    $chr_name = $1;
  }  else  {
    $hg{$chr_name} = "" if !exists $hg{$chr_name};
    $hg{$chr_name} .= $_;
  }
}
close $IN;

# Parse the ANNOVAR output file
open my $OUT, ">$out_file" or die "Cannot create output file: $!\n";
print $OUT "Hugo_Symbol	Tumor_Sample_Barcode	effect	categ	NCBI_Build	Chromosome	Start_position	End_position	Reference_Allele	Tumor_Seq_Allele1	Tumor_Seq_Allele2\n";
my $basename = basename($annovar_file, ".exonic_variant_function");
open my $AIN, "<$annovar_file" or die "Cannot open file: $!\n";
while(<$AIN>)  {
  chomp;
  my @decom = split /\s+/, $_;
  my $n = scalar @decom;
  my @g_info = split /\:/, $decom[$n - 11];
  my $gene = $g_info[0];
  my $patient = $basename;
  my $effect;
  if($decom[1] eq 'synonymous')  {
    $effect = "silent";
  }  else  {
    $effect = "nonsilent";
  }
  my $category = 7;   # in case of NULL/INDEL case
  if($decom[2] eq 'SNV')  {
    my $is_cg = 0;    # if the mutation/variant is found in CpG island
    my $is_ts = 0;    # if the mutation/vairant is transition
    my $is_st = 0;    # if the mutation/variant correspond to strong bond (C-G)
    # varify if the genome sequence fits the annotation
    if(!exists $hg{$decom[$n - 10]} || uc(substr($hg{$decom[$n - 10]}, $decom[$n - 9] - 1, 1)) ne uc($decom[$n - 7]))  {
      die "Inconsistent annotation/lack of chromosome in sequence database\n";
    }
    # annotate the variant
    if((uc($decom[$n - 7]) eq 'C' and uc(substr($hg{$decom[$n - 10]}, $decom[$n - 9], 1)) eq 'G') ||
       (uc($decom[$n - 7]) eq 'G' and uc(substr($hg{$decom[$n - 10]}, $decom[$n - 9] - 2, 1)) eq 'C')
    )  {
      $is_cg = 1;
    }
    if((uc($decom[$n - 7]) eq 'A' and uc($decom[$n - 6]) eq 'G') ||
       (uc($decom[$n - 7]) eq 'G' and uc($decom[$n - 6]) eq 'A') ||
       (uc($decom[$n - 7]) eq 'C' and uc($decom[$n - 6]) eq 'T') ||
       (uc($decom[$n - 7]) eq 'T' and uc($decom[$n - 6]) eq 'C')
    )  {
      $is_ts = 1;
    }
    if(uc($decom[$n - 7]) eq 'C' || uc($decom[$n - 7]) eq 'G')  {
      $is_st = 1;
    }
    if($is_cg and $is_ts)  {
      $category = 1;
    }  elsif($is_cg and !$is_ts)  {
      $category = 2;
    }  elsif($is_st and $is_ts)  {
      $category = 3;
    }  elsif($is_st and !$is_ts)  {
      $category = 4;
    }  elsif(!$is_st and $is_ts)  {
      $category = 5;
    }  elsif($is_st and !$is_ts)  {
      $category = 6;
    }
  }
  $decom[$n - 10] =~ /chr(\S+)/;
  my $chrome = $1;
  print $OUT "$gene	$patient	$effect	$category	37	$chrome	$decom[$n - 9]	$decom[$n - 8]	$decom[$n - 7]	$decom[$n - 6]	$decom[$n - 6]\n";
}
close $AIN;
close $OUT;
