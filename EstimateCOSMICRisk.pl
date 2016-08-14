#!/usr/bin/perl -w
use strict;
use Getopt::Long;

my $cosmic_annovar_file;	# cosmic database as provided in ANNOVAR format
my $file;			# the individual hit (snp) of cosmic
my $help;

GetOptions (
  "COSMIC=s" => \$cosmic_annovar_file,
  "ANNOVAR_hits=s" => \$file,
  "help" => \$help
) or die("Error in command line arguments\n");

if($help || !defined $cosmic_annovar_file || !defined $file)  {
  print "EstimateCOSMICRisk.pl: estimating the risk of cancer through referring to COSMIC database\n";
  print "Usage: perl EstimateCOSMICRisk.pl --COSMIC=[COSMIC_DB] --ANNOVAR_hits=[ANNOVAR_OUTPUT]\n";
  print "\t--COSMIC:\tthe COSMIC database used by ANNOVAR, usually under ANNOVARDIR\/humandb\n";
  print "\t--ANNOVAR_hits:\tthe ANNOVAR output file using filter mode through referring to COSMIC database\n";
  print "\t--help:\t\tprint this message\n";
  exit();
}

open my $BIN, "<$cosmic_annovar_file" or die "Cannot open background file: $!\n";
my %type_hash;
my @cosmic_content;
while(<$BIN>)  {
  chomp;
  my @decom = split /\s+/, $_;
  push @cosmic_content, $decom[5];		# record the information
  my @decom2 = split /\,/, $decom[5];
  foreach(@decom2)  {
    if(/\((.+)\)/)  {
      $type_hash{$1} = 0;			# record the presented cancer type
    }
  }
}
close $BIN;

sub sim_random_snp($$$)  {
  my $th_ref = shift;		# the reference to the type hash
  my $cc_ref = shift;		# the reference to the cosmic database
  my $n_sim = shift;		# the number of simulation
  my %selected;			# hash table for the selected entries
  my %score;			# hash table for simulated scores
  # initialize scores
  foreach(keys %{$th_ref})  {
    $score{$_} = 0;
  }
  # simulation
  while($n_sim > 0)  {
    my $i = int(rand(scalar(@{$cc_ref})));
    if(!exists $selected{$i})  {
      my @decom = split /\,/, $cc_ref->[$i];
      foreach(@decom)  {
        if($_ =~ /(\d+)\((.+)\)/)  {
          $score{$2} += $1 * log($1 + 1);     # define alternative score here
        }
      }
      $selected{$i} = 1;
      -- $n_sim;
    }
  }
  return \%score;
}

# read in data for patient
open my $IN, "<$file" or die "Cannot open file: $!\n";
my %patient_hash;
my $num_variants = 0;
while(<$IN>)  {
  my @decom = split /\s+/, $_;
  my @decom2 = split /\,/, $decom[1];
  foreach(@decom2)  {
    if($_ =~ /(\d+)\((.+)\)/)  {
      $patient_hash{$2} += $1 * log($1 + 1);	# define alternative score here
    }
  }
  ++ $num_variants;
}
close $IN; 

# perform simulation through random sampling without replacement
my %background;
for(my $i = 0; $i < 5000; ++ $i)  {
  my $sim_hash = sim_random_snp(\%type_hash, \@cosmic_content, $num_variants);
  foreach(keys %{$sim_hash})  {
    push @{$background{$_}}, $sim_hash->{$_};
  }
}

sub Chebyshev($$)  {
  my $d_ref = shift;			# reference for an array containing the data
  my $value = shift;			# the value whose P-value is to be computed
  # compute mean
  my $sum = 0;
  foreach(@{$d_ref})  {
    $sum += $_;
  }
  my $ave = $sum / scalar(@{$d_ref});
  # compute variance
  my $sqr_sum = 0;
  foreach(@{$d_ref})  {
    $sqr_sum += ($_ - $ave) * ($_ - $ave);
  }
  my $variance = sqrt($sqr_sum / scalar(@{$d_ref}));
  my $dev = ($value - $ave) / $variance;
  my @rt_v;
  $rt_v[0] = $ave;
  $rt_v[1] = $variance;
  if($value > $ave && $dev > 1) {
    $rt_v[2] = 1 / ($dev * $dev);
  }  else  {
    $rt_v[2] = 1;
  }
  return @rt_v;
}

sub FalseDR($$)  {
  my $d_ref = shift;
  my $value = shift;
  my @d = sort(@{$d_ref});
  my $i = 0;
  foreach(@d)  {
    if($_ > $value)  {
      last;
    }
    ++ $i;
  }
  return 1 - ($i / scalar(@d));
}

# compute P-value for each cancer type using Chebyshev's inequality
print "#DESEASE: disease/cancer type\n";
print "#SCORE: score of the individual\n";
print "#SCORE_SIM_MEAN: score mean of 5,000 simulated individuals having the same number of SNVs\n";
print "#SCORE_SIM_STD: score standard deviation of 5,000 simulated individuals having the same number of SNVs\n";
print "#SCORE_PVALUE: P-value of the indivudual given the distribution of 5,000 simulated scores\n";
print "#SCORE_FDR: False discovery rate of the individual score\n";
print "#\n";
print "#DISEASE	SCORE	SCORE_SIM_MEAN	SCORE_SIM_STD	SCORE_PVALUE	SCORE_FDR\n";
foreach(sort keys %patient_hash)  {
  my $k = $_;
  my @p = Chebyshev(\@{$background{$k}}, $patient_hash{$k});
  my $f = FalseDR(\@{$background{$k}}, $patient_hash{$k});
  print "$k	$patient_hash{$k}	$p[0]	$p[1]	$p[2]	$f\n";
  #foreach(@{$background{$k}})  {
  #  print "$_,";
  #}
  #print "\n";
}

