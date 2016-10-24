#!/usr/bin/perl -w

use DBI;

use HtmlUtilities;
use MetadataParser;


my $dbhost ='localhost';
my $dbname ='METAGENOMESIMG';	
				
my $dbuser ='root';	
my $dbpass ='20master09';


my $dsn = "DBI:mysql:$dbname:$dbhost";
my $dbh = DBI->connect($dsn, $dbuser, $dbpass)
                or die "Couldn't connect to database: " . DBI->errstr;

my $inserth = $dbh->prepare('INSERT INTO metadata(META_ID, MICROBIOME_NAME, NCBI_TAXON_ID, ADD_DATE, MODIFIED_DATE, ISOLATION_COUNTRY, ISOLATION, ISOLATION_YEAR, LATITUDE, LONGITUDE, ALTITUDE, SEQUENCING_STATUS, PH, HABITAT_EXTRA, TEMPERATURE_RANGE, OXYGEN_REQUIREMENT) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)')
                or die "Couldn't prepare statement: " . $dbh->errstr;

my $selecth = $dbh->prepare('SELECT * FROM metadata WHERE META_ID = ?')
                or die "Couldn't prepare statement: " . $dbh->errstr;


#my $oids_file="metagenomes_oids.txt";
my $oids_file="new_metagenomes.txt";
open(OIDS, $oids_file) || die("Could not open IDs file!");
@raw_data=<OIDS>;
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
			print "Parsing metadata from $id...";
			my $htmlData = getUrl( "http://img.jgi.doe.gov/cgi-bin/m/main.cgi?section=TaxonDetail&taxon_oid=".$id );	
			open (TMPFILE, ">./tmp/metadata/metadata$id") || die("Could not open temporary file!");
 			print TMPFILE $htmlData;
 			close (TMPFILE); 


	
			open(INFILE, "./tmp/metadata/metadata$id");

			# read in each line from the file
	 		my $p = new MetadataParser;
	                $p->init();

			while (<INFILE>)
			{
				chomp;
	    			$p->parse($_);
			}
			# flush and parse remaining unparsed HTML
			$p->eof;

	                my %hashData = $p->mdpDataHash();

	                $selecth->execute($id);
			if( $selecth->rows == 0 )
			{
	                  $inserth->execute( $id,$hashData{"MICROBIOME_NAME"},$hashData{"NCBI_TAXON_ID"}, $hashData{"ADD_DATE"}, $hashData{"MODIFIED_DATE"}, $hashData{"ISOLATION_COUNTRY"}, $hashData{"ISOLATION"}, $hashData{"ISOLATION_YEAR"}, $hashData{"LATITUDE"}, $hashData{"LONGITUDE"}, $hashData{"ALTITUDE"}, $hashData{"SEQUENCING_STATUS"}, $hashData{"PH"}, $hashData{"HABITAT"}, $hashData{"TEMPERATURE_RANGE"}, $hashData{"OXYGEN_REQUIREMENT"}, );
			  $inserth->finish;
			  print "  DONE.\n";
	                }
	                else
	                {
	                  print "The metagenome $id already exists in the database... SKIPPED\n";
	                }
	                $selecth->finish;
		}

		close(INFILE);
	}#else
	
}

$dbh->disconnect;

