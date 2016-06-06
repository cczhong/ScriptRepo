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
my $col_gene = 3;
my $col_chrom = 4;
my $col_index = 5;
my $col_from = 7;
my $col_to = 8;

GetOptions(
  "annovar=s" => \$annovar_file,
  "genome=s" => \$genome,
  "out=s" => \$out_file,
  "col_gene=i" => \$col_gene,
  "col_chrom=i" => \$col_chrom,
  "col_index=i" => \$col_index,
  "col_from=i" => \$col_from,
  "col_to=i" => \$col_to
) or die "Error in argument parsing: $!\n";

if(!defined $annovar_file || !defined $genome || !defined $out_file)  {
  print "AnnovartoMutSigInput: Convert VCF file to MutSigCV input format\n";
  print "Usage: perl AnnovartoMutSigInput.pl --annovar=[ANNOVAR_EXON_FUNCTION] --genome=[HUMAN_GENOME_SEQ] --out=[OUTPUT_FILE]\n";
  print "\t--annovar:\tthe annovar file for annotating the VCF against RefSeq\n";
  print "\t--genome:\tthe human genome sequence, in FASTA format\n";
  print "\t--out:\tthe output file\n";
  print "\t--col_gene:\tindex of the column that contains the gene information, default 3\n";
  print "\t--col_chrom:\tindex of the column that contains chromosome information, default 4\n";
  print "\t--col_index:\tindex of the column that contains locus index information, default 5\n";
  print "\t--col_from:\tindex of the column that contains reference nucleotide, default 7\n";
  print "\t--col_to:\tindex of the column that contains mutated nucleotide, default 8\n";
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
  next if(/^\#/);
  chomp;
  my $line = $_;
  my @decom = split /\s+/, $_;
  my $n = scalar @decom;
  my @g_info = split /\:/, $decom[$col_gene];
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
    if(!exists $hg{$decom[$col_chrom]} || uc(substr($hg{$decom[$col_chrom]}, $decom[$col_index] - 1, 1)) ne uc($decom[$n - 7]))  {
      die "Inconsistent annotation/lack of chromosome in sequence database\n";
    }
    # annotate the variant
    if((uc($decom[$col_from]) eq 'C' and uc(substr($hg{$decom[$col_chrom]}, $decom[$col_index] - 1, 1)) eq 'G') ||
       (uc($decom[$col_from]) eq 'G' and uc(substr($hg{$decom[$col_chrom]}, $decom[$col_index] - 1, 1)) eq 'C')
    )  {
      $is_cg = 1;
    }
    if((uc($decom[$col_from]) eq 'A' and uc($decom[$col_to]) eq 'G') ||
       (uc($decom[$col_from]) eq 'G' and uc($decom[$col_to]) eq 'A') ||
       (uc($decom[$col_from]) eq 'C' and uc($decom[$col_to]) eq 'T') ||
       (uc($decom[$col_from]) eq 'T' and uc($decom[$col_to]) eq 'C')
    )  {
      $is_ts = 1;
    }
    if(uc($decom[$col_from]) eq 'C' || uc($decom[$col_from]) eq 'G')  {
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
    }  elsif(!$is_st and !$is_ts)  {
      $category = 6;
    }
  }
  $decom[$col_chrom] =~ /chr(\S+)/;
  my $chrome = $1;
  if($line =~ /het/)  {
    print $OUT "$gene	$patient	$effect	$category	37	$chrome	$decom[$col_index]	$decom[$col_index + 1]	$decom[$$col_from]	$decom[$col_from]	$decom[$col_to]\n";
  } else  {
    print $OUT "$gene	$patient	$effect	$category	37	$chrome	$decom[$col_index]	$decom[$col_index + 1]	$decom[$$col_from]	$decom[$col_to]	$decom[$col_to]\n";
  }
}
close $AIN;
close $OUT;
