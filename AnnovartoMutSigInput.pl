#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Cwd 'abs_path';
use File::Basename;

# Converts ANNOVAR file MutSigCV input format
# According to instructions documented on https://www.broadinstitute.org/cancer/cga/mutsig_run
# Requires the region-based RefSeq annovar annotation file and human genome sequences

my $annovar_folder;
my $genome;
my $out_file;
my $exonic_cols = "2,3,4,6,7";
my $other_cols= "1,2,3,5,6";

my $col_gene_e = 2;
my $col_chrom_e = 3;
my $col_index_e = 4;
my $col_from_e = 6;
my $col_to_e = 7;

my $col_gene_o = 1;
my $col_chrom_o = 2;
my $col_index_o = 3;
my $col_from_o = 5;
my $col_to_o = 6;

GetOptions(
  "annovar=s" => \$annovar_folder,
  "genome=s" => \$genome,
  "out=s" => \$out_file,
  "exonic_cols=s" => \$exonic_cols,
  "other_cols=s" => \$other_cols
) or die "Error in argument parsing: $!\n";

if(!defined $annovar_folder || !defined $genome || !defined $out_file)  {
  print "AnnovartoMutSigInput: Convert VCF file to MutSigCV input format\n";
  print "Usage: perl AnnovartoMutSigInput.pl --annovar=[ANNOVAR_EXON_FUNCTION] --genome=[HUMAN_GENOME_SEQ] --out=[OUTPUT_FILE]\n";
  print "\t--annovar:\tthe annovar folder containing VCF annotation against RefSeq\n";
  print "\t--genome:\tthe human genome sequence, in FASTA format\n";
  print "\t--out:\t\tthe output file\n";
  print "\t--exonic_cols:\tindexes of the columns in exonic_variant_function file;\n";
  print "\t\t\trepresenting geneName,chrom,begin,nuc_from,nuc_to info;\n";
  print "\t\t\tdefault 2,3,4,6,7\n";
  print "\t--other_cols:\tindexes of the columns in variant_function file;\n";
  print "\t\t\trepresenting geneName,chrom,begin,nuc_from,nuc_to info;\n";
  print "\t\t\tdefault 1,2,3,5,6\n";
  exit();
}

# handle columns
my @decom_e = split /\,/, $exonic_cols;
die "Error in setting exonic_variant function columns.\n" if (scalar(@decom_e) != 5);
$col_gene_e = $decom_e[0];
$col_chrom_e = $decom_e[1];
$col_index_e = $decom_e[2];
$col_from_e = $decom_e[3];
$col_to_e = $decom_e[4];

my @decom_o = split /\,/, $other_cols;
die "Error in setting exonic_variant function columns.\n" if (scalar(@decom_o) != 5);
$col_gene_o = $decom_o[0];
$col_chrom_o = $decom_o[1];
$col_index_o = $decom_o[2];
$col_from_o = $decom_o[3];
$col_to_o = $decom_o[4];

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

sub CalCategory($$$)  {
  my $is_cg = shift;
  my $c1 = shift; my $c2 = shift;
  my $category = 7;  
  my $is_ts = 0; my $is_st = 0;
  if((uc($c1) eq 'A' and uc($c2) eq 'G') ||
     (uc($c1) eq 'G' and uc($c2) eq 'A') ||
     (uc($c1) eq 'C' and uc($c2) eq 'T') ||
     (uc($c1) eq 'T' and uc($c2) eq 'C')
  )  {
    $is_ts = 1;
  }
  if(uc($c1) eq 'C' || uc($c1) eq 'G')  {
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
  return $category;
}

# Parse the ANNOVAR output file
open my $OUT, ">$out_file" or die "Cannot create output file: $!\n";
print $OUT "Hugo_Symbol\tTumor_Sample_Barcode\teffect\tcateg\tNCBI_Build\tChromosome\tStart_position\tEnd_position\tReference_Allele\tTumor_Seq_Allele1\tTumor_Seq_Allele2\n";
my $basename = basename($annovar_folder);
# handle exonic variants
my @exonic_list;
foreach(<$annovar_folder/*.exonic_variant_function>) {
  push @exonic_list, $_;
}
if(scalar(@exonic_list) > 0)  {
  open my $AIN, "<$exonic_list[0]" or die "Cannot open file: $!\n";
  while(<$AIN>)  {
    next if(/^\#/);
    chomp;
    my $line = $_;
    my @decom = split /\t/, $_;
    my @g_info = split /\:/, $decom[$col_gene_e];
    my $gene = $g_info[0];
    my $patient = $basename;
    my $effect;
    if($decom[1] =~ 'synonymous')  {
      $effect = "silent";
    }  else  {
      $effect = "nonsilent";
    }
    my $category = 7;   # in case of NULL/INDEL case
    if($decom[1] =~ 'SNV')  {
      my $is_cg = 0;    # if the mutation/variant is found in CpG island
      # varify if the genome sequence fits the annotation
      if(!exists $hg{$decom[$col_chrom_e]} || uc(substr($hg{$decom[$col_chrom_e]}, $decom[$col_index_e] - 1, 1)) ne uc($decom[$col_from_e]))  {
        die "Inconsistent annotation/lack of chromosome in sequence database\n";
      }
      # annotate the variant
      if((uc($decom[$col_from_e]) eq 'C' and uc(substr($hg{$decom[$col_chrom_e]}, $decom[$col_index_e] - 1, 1)) eq 'G') ||
         (uc($decom[$col_from_e]) eq 'G' and uc(substr($hg{$decom[$col_chrom_e]}, $decom[$col_index_e] - 1, 1)) eq 'C')
      )  {
        $is_cg = 1;
      }
      $category = CalCategory($is_cg, $decom[$col_from_e], $decom[$col_to_e]);
    }
    $decom[$col_chrom_e] =~ /chr(\S+)/;
    my $chrome = $1;
    if($line =~ /het/)  {
      print $OUT "$gene\t$patient\t$effect\t$category\t37\t$chrome\t$decom[$col_index_e]\t$decom[$col_index_e + 1]\t$decom[$col_from_e]\t$decom[$col_from_e]\t$decom[$col_to_e]\n";
    } else  {
      print $OUT "$gene\t$patient\t$effect\t$category\t37\t$chrome\t$decom[$col_index_e]\t$decom[$col_index_e + 1]\t$decom[$col_from_e]\t$decom[$col_to_e]\t$decom[$col_to_e]\n";
    }
  }
  close $AIN;
}
# handle other variants
my @other_list;
foreach(<$annovar_folder/*.variant_function>) {
  push @other_list, $_;
}
if(scalar(@other_list) > 0)  {
  open my $AIN, "<$other_list[0]" or die "Cannot open file: $!\n";
  while(<$AIN>) {
    next if(/^\#/ || /^exonic/ || /^intergenic/);
    chomp;
    my $line = $_;
    my @decom = split /\t/, $_;
    my $gene = $decom[$col_gene_o];
    my $patient = $basename;
    my $effect = 'noncoding';
    my $category = 7;
    if($decom[$col_index_o] == $decom[$col_index_o + 1])  { # point mutation
      my $is_cg = 0;    # if the mutation/variant is found in CpG island
      # varify if the genome sequence fits the annotation
      if(!exists $hg{$decom[$col_chrom_o]} || uc(substr($hg{$decom[$col_chrom_o]}, $decom[$col_index_o] - 1, 1)) ne uc($decom[$col_from_o]))  {
        die "Inconsistent annotation/lack of chromosome in sequence database\n";
      }
      # annotate the variant
      if((uc($decom[$col_from_o]) eq 'C' and uc(substr($hg{$decom[$col_chrom_o]}, $decom[$col_index_o] - 1, 1)) eq 'G') ||
         (uc($decom[$col_from_o]) eq 'G' and uc(substr($hg{$decom[$col_chrom_o]}, $decom[$col_index_o] - 1, 1)) eq 'C')
      )  {
        $is_cg = 1;
      }
      $category = CalCategory($is_cg, $decom[$col_from_o], $decom[$col_to_o]);
    }
    $decom[$col_chrom_o] =~ /chr(\S+)/;
    my $chrome = $1;
    if($line =~ /het/)  {
      print $OUT "$gene\t$patient\t$effect\t$category\t37\t$chrome\t$decom[$col_index_o]\t$decom[$col_index_o + 1]\t$decom[$col_from_o]\t$decom[$col_from_o]\t$decom[$col_to_o]\n";
    } else  {
      print $OUT "$gene\t$patient\t$effect\t$category\t37\t$chrome\t$decom[$col_index_o]\t$decom[$col_index_o + 1]\t$decom[$col_from_o]\t$decom[$col_to_o]\t$decom[$col_to_o]\n";
    }
  }
  close $AIN;
}
# finished processing both exonic_variant_function and variant_function files
close $OUT;
