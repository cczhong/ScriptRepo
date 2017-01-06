#!/usr/bin/perl -w
use strict;
use Cwd;

# The script takes a set of coverage files computed by BEDTools
# and compute the count or RPKM for each interval (rows) for each sample (columns)

my $folder = shift;
my $file_id = shift;
my $is_rpkm = shift;

my $current_dir = getcwd();

my @header; push @header, "Identifier";
my %results;

chdir "$folder" or die "Cannot change directory: $!\n";
foreach(<*$file_id*>) {
  my $file = $_;
  # guess the identifier
  my $id = $_;  
  if($id =~ /\./)  {
    $id =~ /^(.*?)\./;  $id = $1;
  }
  push @header, $id;
  
  # extract the count information
  my %count_hash;  
  my %len_hash;
  my $total_count = 0;
  open my $IN, "<$file" or die "Cannot open file: $!\n";
  while(<$IN>) {
    my @decom = split /\s+/, $_;
    $count_hash{$decom[3]} += $decom[6];
    $len_hash{$decom[3]} += $decom[7];
    $total_count += $decom[6];
  }
  close $IN;

  # compute RPKM if necessary
  if(defined $is_rpkm && $is_rpkm)  {
    foreach(keys %count_hash) {
      $count_hash{$_} = 1000000000 * $count_hash{$_} / (($len_hash{$_} + 1) * $total_count);
    }
  }

  # paste the output to results
  if(scalar keys %results <= 0)  {
    foreach(keys %count_hash) {
      push @{$results{$_}}, $count_hash{$_};
    }
  } else  {
    # first consider the genes that are present in results
    foreach(keys %results) {
      if(exists $count_hash{$_})  {
        push @{$results{$_}}, $count_hash{$_};
        delete $count_hash{$_};
      } else  {
        push @{$results{$_}}, 0;
      }
    }
    # adding genes that might not be in results
    foreach(keys %count_hash) {
      for(my $i = 0; $i < scalar(@header) - 1; ++ $i) {
        push @{$results{$_}}, 0;
      }
      push @{$results{$_}}, $count_hash{$_};
    }
  }
}
chdir $current_dir or die "Cannot change directory: $!\n";


# output the results
my $i;
for($i = 0; $i < scalar(@header); ++ $i) {
  print "$header[$i]\t";
} 
print "\n";

foreach(sort keys %results) {
  # check if all values are 0
  my $print_tag = 0;
  for($i = 0; $i < scalar(@{$results{$_}}); ++ $i) {
    if(${$results{$_}}[$i] > 0) { $print_tag = 1; last;}
  } 
  next if(!$print_tag);
  print "$_\t";
  for($i = 0; $i < scalar(@{$results{$_}}); ++ $i) {
    print "${$results{$_}}[$i]\t";
  } 
  print "\n";
}
