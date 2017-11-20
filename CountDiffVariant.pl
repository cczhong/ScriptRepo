#!/usr/bin/perl -w
use strict;
use Getopt::Long;

my $files_affected;
my $files_unaffected;
my $min_affected;
my $max_unaffected;
my $key_columns;
my $info_columns;
my $filter_columns;
my $filter_criteria;
my $filter_thresholds;
my $filter_mode = 1;
my $out_file;
my $help;

GetOptions(
  "annovar_affected=s" => \$files_affected,
  "annovar_unaffected=s" => \$files_unaffected,
  "min_affected=i" => \$min_affected,
  "max_unaffected=i" => \$max_unaffected,
  "key_columns=s" => \$key_columns,
  "info_columns=s" => \$info_columns,
  "filter_columns=s" => \$filter_columns,
  "filter_thresholds=s" => \$filter_thresholds,
  "filter_criteria=s" => \$filter_criteria,
  "filter_mode=i" => \$filter_mode,
  "out=s" => \$out_file,
  "help" => \$help
) or die "Error in argument parsing: $!\n";

if($help || !defined $files_affected || !defined $files_unaffected || !defined $min_affected 
    || !defined $max_unaffected || !defined $out_file
    || !defined $key_columns || !defined $info_columns
    || (defined $filter_columns && (!defined $filter_criteria || !defined $filter_thresholds))
)  {
  print "CountDiffVariant.pl: counting the variants that occur with differnt frequencies in affected and unaffected groups\n";
  print "Usage: perl CountDiffVariant.pl --vcf_affected=[ANNOVAR_IN_AFFECTED] --vcf_unaffected=[ANNOVAR_IN_UNAFFECTED]\n";
  print "\t--min_affected=[MIN_OCCURRENCE_AFFECTED] --max_unaffected=[MAX_OCCURRENCE_UNAFFECTED]\n";
  print "\t--key_columns=[KEY_COLUMNS_IDs] --info_columns=[INFO_COLUMN_IDs] --out=[OUTPUT]\n";
  print "  --annovar_affected:\tANNOVAR files (.aviinput format) for the variants in the affected group; files separated by comma \",\"\n";
  print "  --annovar_unaffected:\tANNOVAR files (.aviinput format) for the variants in the unaffected group; files separated by comma \",\"\n";
  print "  --min_affected:\tminimum number of occurrence of a variant in the affected group\n";
  print "  --max_unaffected:\tmaximum number of occurrence of a variant in the unaffected group\n";
  print "  --key_columns:\tcolumn IDs for the variant key; expecting 5 fields (chrom, start, end, ref_allel, observed_allel);\n"; 
  print "  \t\t\tcolumnd IDs separted by comma \",\"\n";
  print "  --info_columns:\tcolumn IDs for the variant info; columnd IDs separted by comma \",\"\n";
  print "  --filter_columns:\tcolumn IDs used for filtering (discarding the matched entries, only numeric), separated by comma \",\"\n";
  print "  --filter_criteria:\tcriterion used for filtering (only numeric); separated by comma \",\"\n";
  print "  \t\t\texample: \"lt,ge,eq,gt\"; supported operators: gt(>), lt(<), ge(>=), le(<=), eq(==), ne(!=)\n";
  print "  --filter_thresholds:\tnumerical values used for filtering, separated by comma \",\"\n";
  print "  --filter_mode:\t0: filters apply to both affected and unaffected groups; 1: affected only; 2: unaffected only (default: 1 affected only)\n";
  print "  --out:\t\tthe output file\n";
  print "  --help:\t\tprint this information\n";
  exit();
}


my $dp_filter = 100;  # depth of coverage filter

my @affected = split /\,/, $files_affected;
my @unaffected = split /\,/, $files_unaffected;
my @key_ID_decom = split /\,/, $key_columns;
my @info_ID_decom = split /\,/, $info_columns;
die "Fatal error: unexpected key column ID specification; please use --help to check requirements\n" if scalar(@key_ID_decom) != 5;
my @filter_col_decom = split /\,/, $filter_columns if defined $filter_columns;
my @filter_cri_decom = split /\,/, $filter_criteria if defined $filter_criteria;
my @filter_tre_decom = split /\,/, $filter_thresholds if defined $filter_thresholds;
die "Fatal error: filter mode is turned on; however the number of criteria does not match; please use --help to check requirements\n"
  if (scalar(@filter_col_decom) != scalar(@filter_cri_decom) ||  scalar(@filter_tre_decom) != scalar(@filter_cri_decom));

my %affected_hash;
my %affected_info_hash;
my %unaffected_hash;
my %unaffected_info_hash;

my %all_hash;

foreach(@affected) {
  my $file = $_;
  open my $IN, "<$file" or die "Cannot open file: $!\n";
  while(<$IN>) {
    chomp;
    my @decom = split /\t/, $_;
    # filter out the entries
    if($filter_mode == 1 || $filter_mode == 0)  {
      for(my $i = 0; $i < scalar(@filter_col_decom); ++ $i) {
        next if $filter_cri_decom[$i] eq "gt" && ($decom[$filter_col_decom[$i]] > $filter_tre_decom[$i]);
        next if $filter_cri_decom[$i] eq "lt" && ($decom[$filter_col_decom[$i]] < $filter_tre_decom[$i]);
        next if $filter_cri_decom[$i] eq "ge" && ($decom[$filter_col_decom[$i]] >= $filter_tre_decom[$i]);
        next if $filter_cri_decom[$i] eq "le" && ($decom[$filter_col_decom[$i]] <= $filter_tre_decom[$i]);
        next if $filter_cri_decom[$i] eq "eq" && ($decom[$filter_col_decom[$i]] == $filter_tre_decom[$i]);
        next if $filter_cri_decom[$i] eq "ne" && ($decom[$filter_col_decom[$i]] != $filter_tre_decom[$i]);
      }
    }
    # generate the key and info
    my $key = $decom[$key_ID_decom[0]] . ':' . $decom[$key_ID_decom[1]] . '-' . $decom[$key_ID_decom[2]] . '||' . $decom[$key_ID_decom[3]] . '>' . $decom[$key_ID_decom[4]];
    my $info; my $i;
    for($i = 0; $i < scalar(@info_ID_decom) - 1; ++ $i) {
      $info .= $decom[$info_ID_decom[$i]] . '||';
    }
    $info .= $decom[$info_ID_decom[$i]];
    $affected_hash{$key} ++;
    $affected_info_hash{$key} = $info;
    $all_hash{$key} = 1;
  }
  close $IN;
}

foreach(@unaffected) {
  my $file = $_;
  open my $IN, "<$file" or die "Cannot open file: $!\n";
  while(<$IN>) {
    chomp;
    my @decom = split /\t/, $_;
    if($filter_mode == 2 || $filter_mode == 0)  {
      for(my $i = 0; $i < scalar(@filter_col_decom); ++ $i) {
        next if $filter_cri_decom[$i] eq "gt" && ($decom[$filter_col_decom[$i]] > $filter_tre_decom[$i]);
        next if $filter_cri_decom[$i] eq "lt" && ($decom[$filter_col_decom[$i]] < $filter_tre_decom[$i]);
        next if $filter_cri_decom[$i] eq "ge" && ($decom[$filter_col_decom[$i]] >= $filter_tre_decom[$i]);
        next if $filter_cri_decom[$i] eq "le" && ($decom[$filter_col_decom[$i]] <= $filter_tre_decom[$i]);
        next if $filter_cri_decom[$i] eq "eq" && ($decom[$filter_col_decom[$i]] == $filter_tre_decom[$i]);
        next if $filter_cri_decom[$i] eq "ne" && ($decom[$filter_col_decom[$i]] != $filter_tre_decom[$i]);
      }
    }
    my $key = $decom[$key_ID_decom[0]] . ':' . $decom[$key_ID_decom[1]] . '-' . $decom[$key_ID_decom[2]] . '||' . $decom[$key_ID_decom[3]] . '>' . $decom[$key_ID_decom[4]];
    my $info; my $i;
    for($i = 0; $i < scalar(@info_ID_decom) - 1; ++ $i) {
      $info .= $decom[$info_ID_decom[$i]] . '||';
    }
    $info .= $decom[$info_ID_decom[$i]];
    $unaffected_hash{$key} ++;
    $unaffected_info_hash{$key} = $info;
    $all_hash{$key} = 1;
  }
  close $IN;
}

# output the results
open my $OUT, ">$out_file" or die "Cannot create file: $!\n";
print $OUT "#Variant_Key\tAnnotation_Info\tOccurrence_Affected\tOccurrence_Unaffected\n";
foreach (sort keys %all_hash)  {  
  if(exists $affected_hash{$_} && $affected_hash{$_} >= $min_affected && (! exists $unaffected_hash{$_} || $unaffected_hash{$_} <= $max_unaffected))  {
    print $OUT "$_\t$affected_info_hash{$_}\t$affected_hash{$_}\t$unaffected_hash{$_}\n" if exists $unaffected_hash{$_};
    print $OUT "$_\t$affected_info_hash{$_}\t$affected_hash{$_}\t0\n" if ! exists $unaffected_hash{$_};
  }
}
close $OUT;
