#!/usr/bin/env perl

# Copyright 2012  Johns Hopkins University (Author: Guoguo Chen)
# Apache 2.0.
#

use strict;
use warnings;
use Getopt::Long;

my $Usage = <<EOU;
Usage: subset_atwv.pl [options] <keywords|-> <bsum.txt>
 e.g.: subset_atwv.pl keywords.list bsum.txt

This script will compute the ATWV for a subset of the original keywords in bsum.txt.
Note that bsum.txt is a file generated by the NIST scoring tool F4DE. keywords.list 
is a list of the keywords that you want to compute the ATWV for. For example:
KW101-0001
KW101-0002
...

Allowed options:
   --subset-name     : Name of the subset                        (string, default = "")
   --width           : Width of the printed numbers              (int,    default = 5 )
EOU

my $subset_name = "";
my $width = 5;
GetOptions('subset-name=s' => \$subset_name,
  'width=i'   =>  \$width); 

@ARGV == 2 || die $Usage;

# Workout the input/output source
my $kws_filename = shift @ARGV;
my $bsum_filename = shift @ARGV;

my $source = "STDIN";
if ($kws_filename ne "-") {
  open(KWS, "<$kws_filename") || die "Fail to open keywords file: $kws_filename\n";
  $source = "KWS";
}
open(BSUM, "<$bsum_filename") || die "Fail to open bsum file: $bsum_filename\n";

# Read in the keywords.
my $kws = "";
while (<$source>) {
  chomp;
  my @col = split();
  @col == 1 || die "Bad line $_\n";
  if ($kws eq "") {
    $kws = $col[0];
  } else {
    $kws .= "|$col[0]";
  }
}

# Process bsum.txt
my $targ_sum = 0;
my $corr_sum = 0;
my $fa_sum = 0;
my $miss_sum = 0;
my $twv_sum = 0;
my $count = 0;
my $subset_count = 0;
my $flag = 0;
if ($kws ne "") {
  while (<BSUM>) {
    chomp;
    # Workout the total keywords that have occurrence in the search collection
    if (/^Summary  Totals/) {$flag = 0;}
    if (/^Keyword/) {$flag = 1;}
    my @col;
    if ($flag == 1) {
      # Figure out keywords that don't have occurrences in the search collection 
      @col = split(/\|/, $_);
      $col[2] =~ s/^\s+//;
      $col[2] =~ s/\s+$//;
      $col[2] ne "" || next;
      $count ++;
    } else {
      next;
    }

    # Only collect statistics for given subset
    m/$kws/ || next;

    # Keywods that are in the given subset, and have occurrences
    $targ_sum += $col[2];
    $corr_sum += $col[3];
    $fa_sum += $col[4];
    $miss_sum += $col[5];
    $twv_sum += $col[6];
    $subset_count ++;
  }
}

# Compute ATWV
my $subset_atwv = ($subset_count == 0) ? 0 : $twv_sum/$subset_count;
my $atwv = ($count == 0) ? 0 : $twv_sum/$count;
my $bp_atwv = ($count == 0) ? 0 : $subset_count/$count;

# Format the numbers
my $format = "%-${width}d";
$subset_count = sprintf($format, $subset_count);
$targ_sum = sprintf($format, $targ_sum);
$corr_sum = sprintf($format, $corr_sum);
$fa_sum = sprintf($format, $fa_sum);
$miss_sum = sprintf($format, $miss_sum);
$subset_atwv = sprintf("% .4f", $subset_atwv);
$atwv = sprintf("% .4f", $atwv);
$bp_atwv = sprintf("% .4f", $bp_atwv);

# Print
if ($subset_name ne "") {print "$subset_name: ";}
print "#Keywords=$subset_count, #Targ=$targ_sum, #Corr=$corr_sum, #FA=$fa_sum, #Miss=$miss_sum, ";
print "Contributed ATWV=$atwv, Best Possible Contributed ATWV=$bp_atwv, ATWV=$subset_atwv\n";

if ($kws_filename ne "-") {close(KWS);}
close(BSUM);
