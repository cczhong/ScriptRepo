#!/usr/bin/perl -w
use strict;

# This script is used for converting LifeTechnology AmpliSeq Design BED file to regular BED file that 
# can be proccesed by BEDTools
#
# The input would look like:
# track name=Amplicons description="Custom AmpliSeq RNA Panel Designs" ionVersion=4.0 db=hg19 type=bedDetail color=77,175,74 priority=2
# NM_004048:B2M	18	124	AMPL30482794	.	TYPE=GeneExpression;GENE_ID=B2M;TRANSCRIPT_ID=ENST00000558401;GENE_STRAND=+;EXON_NUM=1,2;CHROM=chr15;START=45003766,45007620;END=45003811,45007725
# NM_001648:KLK3	18	130	AMPL10946030	.	TYPE=GeneExpression;GENE_ID=KLK3;TRANSCRIPT_ID=ENST00000326003;GENE_STRAND=+;EXON_NUM=4,5;CHROM=chr19;START=51361764,51363227;END=51361851,51363290
# NM_021202:TP53INP2	20	125	AMPL36914029	.	TYPE=GeneExpression;GENE_ID=TP53INP2;TRANSCRIPT_ID=ENST00000374810;GENE_STRAND=+;EXON_NUM=3,4;CHROM=chr20;START=33296616,33297039;END=33296667,33297136
# NR_001566:TERC	20	106	AMPL22191421	.	TYPE=GeneExpression;GENE_ID=TERC;TRANSCRIPT_ID=ENST00000602385;GENE_STRAND=-;EXON_NUM=1;CHROM=chr3;START=169482425;END=169482550
# NR_002819:MALAT1	27	130	AMPL20459435	.	TYPE=GeneExpression;GENE_ID=MALAT1;TRANSCRIPT_ID=ENST00000534336;GENE_STRAND=+;EXON_NUM=1;CHROM=chr11;START=65270414;END=65270564
# NR_023917:PTENP1	24	127	AMPL20204137	.	TYPE=GeneExpression;GENE_ID=PTENP1;TRANSCRIPT_ID=ENST00000532280;GENE_STRAND=-;EXON_NUM=1;CHROM=chr9;START=33675994;END=33676143
# NR_038340:LOC100505817	20	123	AMPL37528103	.	TYPE=GeneExpression;GENE_ID=LOC100505817;TRANSCRIPT_ID=ENST00000563172;GENE_STRAND=+;EXON_NUM=1,2;CHROM=chr18;START=70992393,70999699;END=70992428,70999812
# NM_002046:GAPDH	19	124	AMPL9964196	.	TYPE=GeneExpression;GENE_ID=GAPDH;TRANSCRIPT_ID=ENST00000229239;GENE_STRAND=+;EXON_NUM=5,6;CHROM=chr12;START=6646138,6646266;END=6646176,6646378
# NM_001101:ACTB	22	128	AMPL2343099	.	TYPE=GeneExpression;GENE_ID=ACTB;TRANSCRIPT_ID=ENST00000331789;GENE_STRAND=-;EXON_NUM=4,5;CHROM=chr7;START=5567735,5567911;END=5567816,5567979
#
# The output will be:
# track name=Amplicons description="Custom AmpliSeq RNA Panel Designs" ionVersion=4.0 db=hg19 type=bedDetail color=77,175,74 priority=2
# chr15	45003766	45007725	B2M	0	+
# chr19	51361764	51363290	KLK3	0	+
# chr20	33296616	33297136	TP53INP2	0	+
# chr3	169482425	169482550	TERC	0	-
# chr11	65270414	65270564	MALAT1	0	+
# chr9	33675994	33676143	PTENP1	0	-
# chr18	70992393	70999812	LOC100505817	0	+
# chr12	6646138	6646378	GAPDH	0	+
# chr7	5567735	5567979	ACTB	0	-
#
# The arguments should be the AmpliconBEDFile and the output file


my $file_in = shift;  # this is expected to be the BED file provided by LifeTechnology AmpliSeq design
my $file_out = shift; # this is the formatted BED file

open my $IN, "<$file_in" or die "Cannot open file: $!\n";
open my $OUT, ">$file_out" or die "Cannot create file: $!\n";
my $tmp = <$IN>;
print $OUT "$tmp";
while(<$IN>) {
  chomp;
  my @decom = split /\s+/, $_;
  $decom[5] =~ /GENE_ID=(.*?);.*GENE_STRAND=(.*?);.*CHROM=(.*?);.*START=(.*?);.*END=(.*?)$/;
  my $chrom = $3; my $start = $4; my $end = $5; my $id = $1; my $strand = $2;
  if(!($start =~ /\,/))  {
    print $OUT "$chrom\t$start\t$end\t$id\t0\t$strand\n";
  } else  {
    my @decom1 = split /\,/, $start;
    my @decom2 = split /\,/, $end;
    print $OUT "$chrom\t$decom1[0]\t$decom2[-1]\t$id\t0\t$strand\n";
  }
}
close $IN;
close $OUT;
