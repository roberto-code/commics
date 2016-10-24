#!/usr/bin/perl -w

use DBI;
use strict;

use HtmlUtilities;

########################################################
# Subroutine to get the size of a file located in a server
sub GetFileSize
{
  my $url=shift;

  my $ua = LWP::UserAgent->new;
  $ua->agent("Mozilla/6.0");

  my $req = new HTTP::Request 'HEAD' => $url;
  $req->header('Accept' => 'text/html');
  my $res = $ua->request($req);
  if ($res->is_success) 
  {
    my $headers = $res->headers;
    return $headers;
  }
return 0;
}
########################################################

my $oids_file="new_metagenomes.txt";



my $dbhost ='localhost';
my $dbname ='METAGENOMESIMG';	
				
my $dbuser ='root';	
#my $dbpass ='vaclp,duv1';
my $dbpass ='20master09';

my $dsn = "DBI:mysql:$dbname:$dbhost";
my $dbh = DBI->connect($dsn, $dbuser, $dbpass)
                or die "Couldn't connect to database: " . DBI->errstr;


my $updateh = $dbh->prepare('UPDATE sequences SET SEQNT = ? WHERE METAID = ? AND GENEID = ?')
                or die "Couldn't prepare statement: " . $dbh->errstr;

my $inserth = $dbh->prepare('INSERT INTO sequences(SEQNT, METAID, GENEID) VALUES (?,?,?)')
                or die "Couldn't prepare statement: " . $dbh->errstr;


my $selecth = $dbh->prepare('SELECT * FROM sequences WHERE METAID = ? AND GENEID = ?')
                or die "Couldn't prepare statement: " . $dbh->errstr;

open(OIDS, $oids_file) || die("Could not open IDs file!");
my @raw_data=<OIDS>;
close(OIDS);



my $id;
foreach $id ( @raw_data )
{
	chomp( $id );
	
	if( $id  !~ m/^#/ )
	{
		

		if( $id !~ m/\d\d\d\d\d\d\d\d\d\d/ )
		{
			print "WARNING: Unexpected oid $id\n";	
		}
		else
		{
			print "Processing $id\n";

			my $tmpfile = "./tmp/sequences/ntsequences$id";
			if ( ! -e $tmpfile )
			{
				my $fileSize = 1;
	  			my $fileSizeServer = 0;
	  			my $counter = 1;
	  			my $maxNumberAttempts = 20;
				do
				{
					print "Attempt to download file: $counter\n";
					my $url = "http://img.jgi.doe.gov/cgi-bin/m/main.cgi?section=TaxonDetail&downloadTaxonGenesFnaFile=1&taxon_oid=$id&_noHeader=1";
					my $htmlData = getUrl( $url );	
					open (TMPFILE, ">$tmpfile");
 					print TMPFILE $htmlData;
 					close (TMPFILE); 
 
					my $header = GetFileSize($url);
	    				$fileSizeServer = $header->content_length;
					$fileSize = -s "$tmpfile";
					$counter++;
				}while( $fileSizeServer > $fileSize && $counter <= $maxNumberAttempts );
				if( $counter == $maxNumberAttempts )
				{ 
					print "ERROR: The nt sequences file $id wasn't correctly downloaded\n";
					unlink( $tmpfile );
				}
				else
				{ print "Done\n";}
					
			}
			else
			{
				print "$tmpfile already exists. The file will not be downloaded.\n";
			}
		
			if ( -e $tmpfile )
			{
				open(INFILE, $tmpfile);
				my $current_sequence = '';
				my $seq_read = 0;
				my $gene_id;
				while (<INFILE>)
				{ 
					if( $_ =~ m/^>\d\d\d\d\d\d\d\d\d\d/ )
					{
						$gene_id = substr( $_,1,10 );
						$seq_read = 0;
					}
					else
					{
						if( $_ =~ m/^\n$/ )
						{
							
							$seq_read = 1;	
						}
						else
						{
							chomp($_);
	
							$current_sequence = $current_sequence.$_ ;
						}	
					}
					if( $seq_read == 1 )
					{
						$selecth->execute($id, $gene_id);
						if( $selecth->rows == 0 )
						{
							$inserth->execute( $current_sequence, $id, $gene_id )
								or die "Couldn't execute statement: " . $inserth->errstr; 
							#print "Inserting gene $gene_id\n";

							$inserth->finish;
						}
						else
						{
							$updateh->execute( $current_sequence, $id, $gene_id )             # Execute the query
        						    or die "Couldn't execute statement: " . $updateh->errstr;
							#print "Updating gene $gene_id\n";
							$updateh->finish;
						}
						$selecth->finish;
						$current_sequence = '';
	
					}
				}#while

				close(INFILE);
			}# if -e tmpfile
		}#else
	}#if( $id  !~ m/^#/ )
	
}#foreach
$dbh->disconnect;



