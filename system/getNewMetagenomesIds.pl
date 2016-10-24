#!/usr/local/bin/perl -w
# ===========================================================================
#
# This library/program is free software; you can redistribute it
# and/or modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or ( at your option ) any later version.
#
# This library/program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
#
# ===========================================================================
#
# Author:  Roberto Garcia Yunta
#
# File Description: Fetching of all the available metagenomes in the Integrated 
# Microbial Genomes with Microbiomes Samples web page
# (http://img.jgi.doe.gov/cgi-bin/m/main.cgi)
#  
# This file emulates the behavior of a user when 
# Creation Date: 2010-12-08
# ---------------------------------------------------------------------------

#Subroutine to get the id's of the metagenomes currently available in the database
sub getCurrentMetagenomes
{
  use DBI;
 
  my $dbhost ='localhost';
  my $dbname ='METAGENOMESIMG';	
				
  my $dbuser ='root';	
  my $dbpass ='20master09';


  my $dsn = "DBI:mysql:$dbname:$dbhost";
  my $dbh = DBI->connect($dsn, $dbuser, $dbpass)
                or die "Couldn't connect to database: " . DBI->errstr;


  my $selecth = $dbh->prepare('SELECT META_ID FROM metadata')
                or die "Couldn't prepare statement: " . $dbh->errstr;

  $selecth->execute()
    or die "Couldn't execute statement: " . $selecth->errstr; 

  # BIND TABLE COLUMNS TO VARIABLES
  my $id;
  $selecth->bind_columns(\$id);

  # LOOP THROUGH RESULTS
  my @currentMetagenomes;
  while($selecth->fetch()) 
  {
    push @currentMetagenomes, $id;
  }
 
  $selecth->finish;
  $dbh->disconnect;

  return @currentMetagenomes;
}


use LWP::UserAgent;

my $page = "http://img.jgi.doe.gov/cgi-bin/m/main.cgi?section=TreeFile&page=domain&domain=*Microbiome";

# Create a user agent
my $ua = LWP::UserAgent->new();
$ua->agent("Mozilla/6.0");
$ua->cookie_jar( {} );

# Perform the request
my $response = $ua->get($page);
my $html = $response->content();

my $query;
if( $html =~ /(main\.cgi\?section=TaxonList&page=taxonListAlpha&domain=\*Microbiome&pidt=\d+\.\d+)/g )
{
  $query = $1;
}

my $microbiomesPage = "http://img.jgi.doe.gov/cgi-bin/m/$query";
$response = $ua->get($microbiomesPage);
# Check for HTTP error codes
die 'http status: ' . $response->code . ' ' . $response->message
unless ($response->is_success);

$html = $response->content();
my $yuiDt;
#new YAHOO.util.DataSource("json_proxy.cgi?sid=yui_dt_xxxxxxxxxx&
if( $html=~ /(json_proxy\.cgi\?sid=yui_dt_\d+_\d+_[a-zA-Z0-9]+&)/g )
{
  $yuiDt = $1;
}

# Emulation of the original javascript call where the callid is the timestamp expressed in milliseconds
my $callId = `date +%s`*1000;

# Getting the actual data which is encoded in json
$response = $ua->get( "http://img.jgi.doe.gov/cgi-bin/m/$yuiDt&results=all&startIndex=0&sort=D&dir=asc&c=&f=&callid=$callId" );

# Check for HTTP error codes
die 'http status: ' . $response->code . ' ' . $response->message
unless ($response->is_success);

$html = $response->content();
# Fetching metagenomes id's
my @availableMetagenomes;
while( $html=~ /taxon_oid=(\d+)\'/g )
{
  push @availableMetagenomes, $1;
}

#array that contains the id's of the metagenomes available in the database
my @currentMetagenomes = getCurrentMetagenomes();

open (MYFILE, '>new_metagenomes.txt');
print MYFILE "# This file contains the id's of the new metagenomes available in the img web but not yet included in the database\n";	
foreach my $metaId(@availableMetagenomes)
{
  # Checking if each one of the metagenomes available in the web is already present in the database
  if ( ! (grep { $_ == $metaId} @currentMetagenomes) )
  {
    # In case it isn't, write it to a file for later processing
    print MYFILE "$metaId\n";
  }
}
close (MYFILE);
