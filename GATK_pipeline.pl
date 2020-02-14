#!/usr/bin/perl -w
use strict;
 use Cwd;
 use Cwd 'abs_path';

# provide the workspace directory
# in the folder we assume there is a folder named "Data", which stores the raw data
# Within the Data folder should be sub-folders, one for each sample
# Within each sample folder should contain a set of Gzipped, paired-end FASTQ files
# The raw FASTQ file should named *R1_001.fastq.gz and *R2_001.fastq.gz

my $workspace = shift;
$workspace = abs_path($workspace);

# setting parameters and third-party software paths
my $num_threads = 16;
my $ref_genome_db = "/home/Database/GATK/Homo_sapiens_assembly38.fasta";
my $known_sites_dpSNP = "/home/Database/GATK/dbsnp_146.hg38.vcf";
my $known_sites_MINDEL = "/home/Database/GATK/Mills_and_1000G_gold_standard.indels.hg38.vcf";
my $known_sites_hapmap = "/home/Database/GATK/hapmap_3.3.hg38.vcf";
my $known_sites_1KGOmni = "/home/Database/GATK/1000G_omni2.5.hg38.vcf";
my $known_sites_1KGPhase1 = "/home/Database/GATK/1000G_phase1.snps.high_confidence.hg38.vcf";
my $wgs_interval_list = "/home/Database/GATK/wgs_calling_regions.hg38.interval_list";
my $Trimmomatic_path = "/home/cczhong/Tools/Trimmomatic-0.36";
my $BWA_path = "/home/cczhong/Tools/bwa.kit";
my $samtools_path = "/home/cczhong/Tools/samtools-1.5";
my $Picard_path = "/home/cczhong/Tools";
my $GATK_path = "/home/cczhong/Tools/gatk-4.1.3.0";

# MODULE 1: Initial check for validity of the input workspace
print "=== Checking workspace validity... ===\n";
die "Error: No \"Data\" folder found! Abort." if (!-e "$workspace/Data");
opendir my $DIR, "$workspace/Data" or die "Cannot access directory $workspace: $!\n";
my @samples = readdir $DIR;
@samples = sort @samples;
closedir $DIR;
mkdir "$workspace/tmp" or die "Cannot create temporary directory: $!\n" if (!-e "$workspace/tmp");
mkdir "$workspace/Results" or die "Cannot create Result directory: $!\n" if (!-e "$workspace/Results");
my $num_samples = scalar(@samples) - 2;
print "\t$num_samples samples found.\n";
my $is_all_samples_valid = 1;
for(my $i = 0; $i < $num_samples; ++ $i)	{
	# check the validity of each sample
	next if(! -d "$workspace/Data/$samples[$i + 2]");
	chdir "$workspace/Data/$samples[$i + 2]" or die "Cannot change to sample directory: $!\n";	
	my $fw = 0; my $re = 0;	
	foreach(<*R1_001.fastq.gz>)	{
		++ $fw;
	}
	foreach(<*R2_001.fastq.gz>)	{
		++ $re;
	}
	#closedir $DDIR;
	if($fw > 0 && $re > 0)	{
		print "\tSample $samples[$i + 2] is valid.\n";
	}	else	{
		print "\tSample $samples[$i + 2] is invalid!!! Please correct the error before proceeding.\n";
		$is_all_samples_valid = 0;
	}
}
chdir "$workspace" or die "Cannot return to workspace: $!\n";
die "Error: At least one sample is invalid. Correct the error or delete the corresponding file folder before proceed." 
	if !$is_all_samples_valid;
# MODULE 1 DONE


# MODULE 2: Merging all forward and reverse files if we have data from multiple lanes
print "=== Merging samples from multiple lanes (if applicable)... ===\n";
for(my $i = 0; $i < $num_samples; ++ $i)	{
	# check the validity of each sample
	next if(! -d "$workspace/Data/$samples[$i + 2]");
	chdir "$workspace/Data/$samples[$i + 2]" or die "Cannot change to sample directory: $!\n";	
	print "\tprocessing $samples[$i + 2]\n";
	my $fw = 0; my $re = 0;	
	foreach(<*R1_001.fastq.gz>)	{
		system "zcat $_ >>fw.fastq";
	}
	foreach(<*R2_001.fastq.gz>)	{
		system "zcat $_ >>re.fastq";
	}
}
# MODULE 2 DONE

# MODULE 3: Running trimmomatic quality trimming for each sample
print "=== Running Trimmomatic for quality trimming... ===\n";
chdir "$Trimmomatic_path" or die "Cannot access Trimmomatic path: $!\n";
for(my $i = 0; $i < $num_samples; ++ $i)	{
	# check the validity of each sample
	next if(! -d "$workspace/Data/$samples[$i + 2]");
	my $current_path = "$workspace\/Data\/" . $samples[$i + 2];
	print "\tprocessing $samples[$i + 2]\n";
	system "java -jar trimmomatic-0.36.jar PE -threads $num_threads $current_path/fw.fastq $current_path/re.fastq $current_path/fw.paired.fastq.gz $current_path/fw.unpaired.fastq.gz  $current_path/re.paired.fastq.gz $current_path/re.unpaired.fastq.gz ILLUMINACLIP:adapters/TruSeq3-PE.fa:2:30:10:2:keepBothReads LEADING:3 TRAILING:3 MINLEN:36";
	system "rm $current_path/fw.fastq $current_path/re.fastq $current_path/fw.unpaired.fastq.gz $current_path/re.unpaired.fastq.gz";
}
chdir "$workspace" or die "Cannot return to workspace: $!\n";
# MODULE 3 DONE

# MODULE 4: Mapping reads with BWA
print "=== Running BWA for read mapping... ===\n";
for(my $i = 0; $i < $num_samples; ++ $i)	{
	# check the validity of each sample
	next if(! -d "$workspace/Data/$samples[$i + 2]");
	my $current_path = "$workspace\/Data\/" . $samples[$i + 2];
	print "\tprocessing $samples[$i + 2]\n";
	system "$BWA_path/bwa mem -t $num_threads $ref_genome_db $current_path/fw.paired.fastq.gz $current_path/re.paired.fastq.gz | $samtools_path/samtools sort --threads $num_threads -o $current_path/aligned.bam -";
}
# MODULE 4 DONE


# MODULE 5: Marking duplicates and sorting the BAM
print "=== Marking duplicates... ===\n";
for(my $i = 0; $i < $num_samples; ++ $i)	{
	# check the validity of each sample
	next if(! -d "$workspace/Data/$samples[$i + 2]");
	my $current_path = "$workspace\/Data\/" . $samples[$i + 2];
	print "\tprocessing $samples[$i + 2]\n";
	system "java -jar $Picard_path/picard.jar MarkDuplicates I=$current_path/aligned.bam O=$current_path/aligned.md.bam M=$current_path/duplicates.txt";
	system "java -jar $Picard_path/picard.jar SortSam I=$current_path/aligned.md.bam O=$current_path/aligned.md.sorted.bam SORT_ORDER=coordinate";
	system "java -jar $Picard_path/picard.jar AddOrReplaceReadGroups I=$current_path/aligned.md.sorted.bam O=$current_path/aligned.md.sorted.rg.bam RGLB=lib1 RGPL=Illumina RGPU=unit1 RGSM=$samples[$i + 2]";
	system "rm -f $current_path/aligned.bam $current_path/aligned.md.bam $current_path/aligned.md.sorted.bam";
}
# MODULE 5 DONE

# MODULE 6: Running base quality score calibration
print "=== Running GATK BQSR... ===\n";
for(my $i = 0; $i < $num_samples; ++ $i)	{
	# check the validity of each sample
	next if(! -d "$workspace/Data/$samples[$i + 2]");
	my $current_path = "$workspace\/Data\/" . $samples[$i + 2];
	print "\tprocessing $samples[$i + 2]\n";
	system "$GATK_path/gatk BaseRecalibrator -I $current_path/aligned.md.sorted.rg.bam -R $ref_genome_db --known-sites $known_sites_dpSNP --known-sites $known_sites_MINDEL -O $current_path/recal.table";
	system "$GATK_path/gatk ApplyBQSR -R $ref_genome_db -I $current_path/aligned.md.sorted.rg.bam --bqsr-recal-file $current_path/recal.table -O $current_path/aligned.recal.bam";
	system "rm -f $current_path/aligned.md.sorted.rg.bam";
}
# MODULE 6 DONE

# MODULE 7: Running HaplotypeCaller
print "=== Running GATK HaploypeCaller... ===\n";
for(my $i = 0; $i < $num_samples; ++ $i)	{
	# check the validity of each sample
	next if(! -d "$workspace/Data/$samples[$i + 2]");
	my $current_path = "$workspace\/Data\/" . $samples[$i + 2];
	print "\tprocessing $samples[$i + 2]\n";
	system "$GATK_path/gatk HaplotypeCaller -I $current_path/aligned.recal.bam -O $current_path/$samples[$i + 2].vcf -R $ref_genome_db --emit-ref-confidence GVCF -A FisherStrand -A MappingQualityRankSumTest -A MappingQuality -A QualByDepth -A ReadPosition -A ReadPosRankSumTest -A StrandOddsRatio";
}
# MODULE 7 DONE



# MODULE 8: Joining the individual GVCF files into a GenomeDB
print "=== Joining cohort GVCFs... ===\n";
my $join_cmd = "$GATK_path/gatk GenomicsDBImport --genomicsdb-workspace-path $workspace/Results/GenomicsDB --tmp-dir=$workspace/tmp -L $wgs_interval_list ";
for(my $i = 0; $i < $num_samples; ++ $i)	{
	# check the validity of each sample
	next if(! -d "$workspace/Data/$samples[$i + 2]");
	my $current_path = "$workspace\/Data\/" . $samples[$i + 2];
	$join_cmd .= "-V $current_path/$samples[$i + 2].vcf ";
}
system "$join_cmd\n";
# MODULE 8 DONE

# MODULE 9: Genotype joined GVCFs
print "=== Genotyping joined GVCFs... ===\n";
system "$GATK_path/gatk GenotypeGVCFs -R $ref_genome_db -V gendb://$workspace/Results/GenomicsDB -O $workspace/Results/genotypes.vcf.gz --tmp-dir=$workspace/tmp\n";
# MODULE 9 DONE

# MODULE 10: Recalibrate variants
print "=== Recalibraing called SNPs... ===\n";
system "$GATK_path/gatk VariantRecalibrator -R $ref_genome_db -V $workspace/Results/genotypes.vcf.gz --resource:hapmap,known=false,training=true,truth=true,prior=15.0 $known_sites_hapmap --resource:omni,known=false,training=true,truth=false,prior=12.0 $known_sites_1KGOmni --resource:1000G,known=false,training=true,truth=false,prior=10.0 $known_sites_1KGPhase1 --resource:dbsnp,known=true,training=false,truth=false,prior=2.0 $known_sites_dpSNP -an QD -an MQ -an MQRankSum -an ReadPosRankSum -an FS -an SOR -mode SNP -O $workspace/Results/output.recal --tranches-file $workspace/Results/output.tranches --rscript-file $workspace/Results/output.plots.R\n";
system "$GATK_path/gatk ApplyVQSR -R $ref_genome_db -V $workspace/Results/genotypes.vcf.gz -O $workspace/Results/genotypes_VQSR.vcf.gz --truth-sensitivity-filter-level 99.0 --tranches-file $workspace/Results/output.tranches --recal-file $workspace/Results/output.recal -mode SNP\n";
# MODULE 10 DONE

