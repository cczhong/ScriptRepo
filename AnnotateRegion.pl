#!/usr/bin/perl -w
use strict;
use Getopt::Long;

my $annot_file;
my $query_file;
my $column_ID_annot;
my $column_ID_query;
my $out_file;
my $check_strand = 0;
my $help;

GetOptions(
  "annot=s" => \$annot_file,
  "query=s" => \$query_file,
  "col_annot=s" => \$column_ID_annot,
  "col_query=s" => \$column_ID_query,
  "out=s" => \$out_file,
  "check_strand" => \$check_strand,
  "help" => \$help
) or die "Error in argument parsing: $!\n";

if($help || !defined $annot_file || !defined $query_file || !defined $column_ID_annot || !defined $column_ID_query || !defined $out_file)  {
  print "AnnotateRegion.pl: annotate region based on RefSeq\n";
  print "Usage: perl AnnotateRegion.pl --refseq=[REFSEQ FILE] --query=[QUERY FILE] --colID=[COLUMN ID in QUERY] --out=[OUTPUT]\n";
  print "\t--annot:\tThe annotation file; it should contain chromosome, strand (optional), begin, end, and notation information\n";
  print "\t--query:\tThe query file; it should contain chromosome, strand (optional), begin, end, and notation information\n";
  print "\t\t\tif (begin) is larger than (end) it indicates that the region is on the minus strand\n";
  print "\t--col_query:\tThe column IDs in the query file that contains the genomic region information;\n";
  print "\t\t\trequired 4(do not check strand) or 5 (check strand) fields:\n";
  print "\t\t\tchromosome,begin,end,notation or chromosome,strand,begin,end,notation\n";
  print "\t--col_annot:\tThe column IDs in the annotation file that contains the genomic region information;\n";
  print "\t\t\trequired 4(do not check strand) or 5 (check strand) fields:\n";
  print "\t\t\tchromosome,begin,end,notation or chromosome,strand,begin,end,notation\n";
  print "\t--out:\t\tThe output file\n";
  print "\t--check_strand:\tCheck strand consistency, default NO\n";
  print "\t--help:\t\tPrint this information\n";
  exit();
}

# process the indexes 
my @annot_ID = split /\,/, $column_ID_annot;
exit("Annotation file column IDs error, please check requirements using --help; abort.") 
  if(!((scalar(@annot_ID) == 4 && !$check_strand) || (scalar(@annot_ID) == 5 && $check_strand)));
my @query_ID = split /\,/, $column_ID_query;
exit("Query file column IDs error, please check requirements using --help; abort.") 
  if(!((scalar(@query_ID) == 4 && !$check_strand) || (scalar(@query_ID) == 5 && $check_strand)));

my $q_chrom_ID = $query_ID[0];
my $q_strand_ID = $check_strand ? $query_ID[1] : -1;
my $q_begin_ID = $check_strand ? $query_ID[2] : $query_ID[1];
my $q_end_ID = $check_strand ? $query_ID[3] : $query_ID[2];
my $q_tag_ID = $check_strand ? $query_ID[4] : $query_ID[3];
my $a_chrom_ID = $annot_ID[0];
my $a_strand_ID = $check_strand ? $annot_ID[1] : -1;
my $a_begin_ID = $check_strand ? $annot_ID[2] : $annot_ID[1];
my $a_end_ID = $check_strand ? $annot_ID[3] : $annot_ID[2];
my $a_tag_ID = $check_strand ? $annot_ID[4] : $annot_ID[3];

my $i; my $j;
# load in the annotation information
my @region_info;
open my $IN, "<$annot_file" or die "Cannot open annotate file: $!\n";
while(<$IN>) {
  chomp;
  next if(/^\#/);
  my @decom = split /\t+/, $_;
  my @frag_info;
  if($check_strand)  {
    @frag_info = ($decom[$a_chrom_ID], $decom[$a_begin_ID], $decom[$a_end_ID], $decom[$a_tag_ID], $decom[$a_strand_ID]);
  } else  {
    @frag_info = ($decom[$a_chrom_ID], $decom[$a_begin_ID], $decom[$a_end_ID], $decom[$a_tag_ID]);
  }
  push @region_info, \@frag_info;
}
close $IN;
# sorting the region annotation
@region_info = sort {$a->[0] cmp $b->[0] || $a->[1] <=> $b->[1]} @region_info; 

#for(my $i = 0; $i < scalar(@region_info); ++ $i) {
#  print "@{$region_info[$i]}\n";
#}
#die;

# load the query region information
open my $QIN, "<$query_file" or die "Cannot open file: $!\n";
my @query_info; my $index = 0;
while(<$QIN>) {
  chomp;
  next if(/^\#/);
  my @decom = split /\t/, $_;
  my @frag_info;
  if($check_strand)  {
    @frag_info = ($decom[$q_chrom_ID], $decom[$q_begin_ID], $decom[$q_end_ID], $decom[$q_tag_ID], $decom[$q_strand_ID]);
  } else  {
    @frag_info = ($decom[$q_chrom_ID], $decom[$q_begin_ID], $decom[$q_end_ID], $decom[$q_tag_ID]);
  }
  push @query_info, \@frag_info;
}
close $QIN;

# sort the query regions
@query_info = sort {$a->[0] cmp $b->[0] || $a->[1] <=> $b->[1]} @query_info; 

my $region_info_size = scalar(@region_info);
my $query_info_size = scalar(@query_info);
my $qindex = 0; my $rindex = 0;
# attempt to match the regions
while($qindex < scalar(@query_info)) {
  #print "==========================\n";
  #print "$qindex  $rindex\n";
  #print "@{$query_info[$qindex]}\n";
  #print "@{$region_info[$rindex]}\n";
  #print "==========================\n";
  # jump to where the query begins
  while($rindex < $region_info_size && 
    (($region_info[$rindex][0] lt $query_info[$qindex][0]) || 
        ($region_info[$rindex][0] eq $query_info[$qindex][0] && $region_info[$rindex][2] < $query_info[$qindex][1]))) {
    #print "***  @{$region_info[$rindex]}\n";
    ++ $rindex;
  }
  if($rindex >= $region_info_size || $region_info[$rindex][0] ne $query_info[$qindex][0] || $region_info[$rindex][2] < $query_info[$qindex][1])  {
    # which means no region hits, the region is intergenic
    #print "query skiped...\n";    
    push @{$query_info[$qindex]}, "unknown"; ++ $qindex; next;
  }
  my $max_overlap = 0; my $max_id;
  while($rindex < $region_info_size && $region_info[$rindex][0] le $query_info[$qindex][0] && $region_info[$rindex][1] < $query_info[$qindex][2]) {
    # find the region with maximum overlap  
    #print "???  @{$region_info[$rindex]}\n";
    if($check_strand && $region_info[$rindex][4] ne $query_info[$qindex][4]) { ++ $rindex; next; } 
    my $lbound = $region_info[$rindex][1] >= $query_info[$qindex][1] ? $region_info[$rindex][1] : $query_info[$qindex][1];
    my $rbound = $region_info[$rindex][2] <= $query_info[$qindex][2] ? $region_info[$rindex][2] : $query_info[$qindex][2];
    my $overlap = $rbound - $lbound + 1;
    if($overlap > $max_overlap)  {
      $max_overlap = $overlap; $max_id = $rindex;
    }
    #print "!!!  @{$region_info[$rindex]}\n";
    ++ $rindex;    
  }
  my $annot = "unknown";
  if($max_overlap > 0)  {
    $annot = $region_info[$max_id][3];
  }
  push @{$query_info[$qindex]}, $annot;
  # jump back the region index
  if($qindex < $query_info_size - 1)  {
    while($rindex > 0 && $rindex < $region_info_size && (($region_info[$rindex][0] gt $query_info[$qindex + 1][0]) || ($region_info[$rindex][0] eq $query_info[$qindex + 1][0] && $region_info[$rindex][2] >= $query_info[$qindex + 1][1]))) {
      #print "???  @{$region_info[$rindex]}\n";
      -- $rindex;
    }
  }
  ++ $qindex;
}

# resort the query regions based on the index
open my $OUT, ">$out_file" or die "Cannot create file: $!\n";
for($i = 0; $i < scalar(@query_info); ++ $i) {
  if($check_strand) {
    print $OUT "$query_info[$i][0]\t$query_info[$i][4]\t$query_info[$i][1]\t$query_info[$i][2]\t$query_info[$i][3]\t$query_info[$i][5]\n";
  } else  {
    print $OUT "$query_info[$i][0]\t$query_info[$i][1]\t$query_info[$i][2]\t$query_info[$i][3]\t$query_info[$i][4]\n";
  }
}
close $OUT;
