#!/usr/bin/perl -w
use strict;
use Getopt::Long;

my $annot_file;
my $query_file;
my $column_ID;
my $out_file;
my $check_strand = 0;
my $help;

GetOptions(
  "refseq=s" => \$annot_file,
  "query=s" => \$query_file,
  "colID=i" => \$column_ID,
  "out=s" => \$out_file,
  "check_strand" => \$check_strand,
  "help" => \$help
) or die "Error in argument parsing: $!\n";

if($help || !defined $annot_file || !defined $query_file || !defined $column_ID || !defined $out_file)  {
  print "AnnotateRegion.pl: annotate region based on RefSeq\n";
  print "Usage: perl AnnotateRegion.pl --refseq=[REFSEQ FILE] --query=[QUERY FILE] --colID=[COLUMN ID in QUERY] --out=[OUTPUT]\n";
  print "\t--refseq:\tThe RefSeq gene annotation from UCSC all columns format\n";
  print "\t--query:\tThe query file, one of the column should contain genomic regions in (chromosome):(begin)-(end) format;\n";
  print "\t\t\tif (begin) is larger than (end) it indicates that the region is on the minus strand\n";
  print "\t--colID:\tThe column ID in the query file that contains the genomic region information\n";
  print "\t--check_strand:\tCheck strand consistency, default NO\n";
  print "\t--help:\tPrint this information\n";
  exit();
}

# load in the annotation information
my @region_info;
open my $IN, "<$annot_file" or die "Cannot open annotate file: $!\n";
while(<$IN>) {
  chomp;
  next if(/^\#/);
  my @decom = split /\t+/, $_;
  my $gid = $decom[1]; my $chrom = $decom[2]; my $strand = $decom[3]; my $gname = $decom[12];
  if($gid =~ /^NM\_/)  {
    my @frag_info = ($chrom, $strand, $decom[4], $decom[6] - 1, $gid, $gname, "5\'UTR");
    push @region_info, \@frag_info;
  }
  my @begin = split /\,/, $decom[9];
  my @end = split /\,/, $decom[10];
  for(my $i = 0; $i < $decom[8]; ++ $i) {
    my @frag_info = ($chrom, $strand, $begin[$i], $end[$i], $gid, $gname, "exon");
    push @region_info, \@frag_info;
    if($i < $decom[8] - 1)  {
      @frag_info = ($chrom, $strand, $end[$i] + 1, $begin[$i + 1] - 1, $gid, $gname, "intron");
      push @region_info, \@frag_info;
    }
  }
  if($gid =~ /^NM\_/)  {
    my @frag_info = ($chrom, $strand, $decom[7] + 1, $decom[5], $gid, $gname, "3\'UTR");
    push @region_info, \@frag_info;
  }
}
close $IN;
# sorting the region annotation
@region_info = sort {$a->[0] cmp $b->[0] || $a->[2] <=> $b->[2]} @region_info; 

# define range for each chromosome
my %chrom_begin; my %chrom_end;
my $last = "unknown";
my $i;
for($i = 0; $i < scalar(@region_info); ++ $i) {
  if($region_info[$i][0] ne $last)  {
    $chrom_end{$last} = $i - 1;
    $chrom_begin{$region_info[$i][0]} = $i;
  }
  $last = $region_info[$i][0];
}
$chrom_end{$last} = $i;
delete $chrom_end{"unknown"};

# load the query region information
open my $QIN, "<$query_file" or die "Cannot open file: $!\n";
my @query_info; my $index = 0;
while(<$QIN>) {
  chomp;
  next if(/^\#/);
  my $line = $_;
  my @decom = split /\t/, $_;
  if($decom[$column_ID] =~ /(chr.+)\:(\d+)\-(\d+)/)  {
    # binary search 
    my $chr = $1;
    my $fbegin = $2; my $fend = $3;
    my $strand = "+";
    if($fbegin > $fend) {
      my $tmp = $fbegin; $fbegin = $fend; $fend = $tmp;
      $strand = "-";
    }
    my @q_info = ($index, $line, $chr, $strand, $fbegin, $fend);
    push @query_info, \@q_info;
  }  else {
    my @q_info = ($index, $line, "unknown", "unknown", 0, 0);
    push @query_info, \@q_info;
  }
  ++ $index;
}
close $QIN;

# sort the query regions
@query_info = sort {$a->[2] cmp $b->[2] || $a->[4] <=> $b->[4]} @query_info; 
my $qindex = 0; my $rindex = 0;
while($qindex < scalar(@query_info)) {
  
  # special case
  if($query_info[$qindex][2] eq 'unknown')  {
    push @{$query_info[$qindex]}, "unknown"; ++ $qindex; next;
  }
  # jump to where the query begins
  while($rindex < scalar(@region_info) && 
    (($region_info[$rindex][0] lt $query_info[$qindex][2]) || 
        ($region_info[$rindex][0] eq $query_info[$qindex][2] && $region_info[$rindex][3] < $query_info[$qindex][4]))) {
    ++ $rindex;
  }
  if($region_info[$rindex][0] ne $query_info[$qindex][2] || $region_info[$rindex][3] < $query_info[$qindex][4])  {
    # which means no region hits, the region is intergenic
    push @{$query_info[$qindex]}, "intergenic"; ++ $qindex; next;
  }
  my $max_overlap = 0; my $max_id;
  while($rindex < scalar(@region_info) && $region_info[$rindex][0] le $query_info[$qindex][2] && $region_info[$rindex][2] < $query_info[$qindex][5]) {
    # find the region with maximum overlap  
    #print "???  @{$region_info[$rindex]}\n";
    if($check_strand && $region_info[$rindex][1] ne $query_info[$qindex][3]) { ++ $rindex; next; } 
    my $lbound = $region_info[$rindex][2] >= $query_info[$qindex][4] ? $region_info[$rindex][2] : $query_info[$qindex][4];
    my $rbound = $region_info[$rindex][3] <= $query_info[$qindex][5] ? $region_info[$rindex][3] : $query_info[$qindex][5];
    my $overlap = $rbound - $lbound + 1;
    if($overlap > $max_overlap)  {
      $max_overlap = $overlap; $max_id = $rindex;
    }
    ++ $rindex;
  }
  my $annot = "intergenic";
  if($max_overlap > 0)  {
    $annot = $region_info[$max_id][4] . ":" . $region_info[$max_id][5] . ":" . $region_info[$max_id][6];
  }
  push @{$query_info[$qindex]}, $annot;
  # jump back the region index
  while($rindex > 0 && (($region_info[$rindex][0] gt $query_info[$qindex][2]) || ($region_info[$rindex][0] eq $query_info[$qindex][2] && $region_info[$rindex][3] >= $query_info[$qindex][4]))) {
    -- $rindex;
  }
  #print "@{$query_info[$qindex]}\n";
  ++ $qindex;
}

# resort the query regions based on the index
@query_info = sort {$a->[0] cmp $b->[0]} @query_info; 
open my $OUT, ">$out_file" or die "Cannot create file: $!\n";
for($i = 0; $i < scalar(@query_info); ++ $i) {
  print $OUT "$query_info[$i][1]\t$query_info[$i][6]\n";
}
close $OUT;
