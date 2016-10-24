#!/usr/bin/perl -w


use strict;




my $file2open = $ARGV[0];


open(FILEH, $file2open) || die("Could not open the specified file!");
my @file_content = <FILEH>;
close(FILEH);

my %count_cogs;
my $total_genes = 0;
foreach my $line( @file_content )
{
  $total_genes++;
  chomp($line);
  my (undef,$cog) = split("\t", $line);
  if ( $cog ne "" )
  {
    if( defined( $count_cogs{$cog} ) )
    {
      $count_cogs{$cog}++;
    }
    else
    {
      $count_cogs{$cog} = 1;
    }
  }
}

open(OUTPUT,">count_cogs.txt");
print OUTPUT "TOTAL_GENES $total_genes\n";
foreach my $key( keys(%count_cogs) )
{
  my $count = $count_cogs{$key};
  print OUTPUT "$key $count\n";
}


close(OUTPUT);

