#!/usr/bin/perl -w


# Load LWP
use HTTP::Request::Common qw(GET POST);
use HTTP::Cookies;
use LWP::UserAgent;

########################################################
# Subroutine to get the size of a file located in a server
sub GetFileSize
{
  my $url=shift;
  my $cookie_jar = HTTP::Cookies->new(
   file     => "./cookies.txt",
  );

  my $ua = LWP::UserAgent->new;
  $ua->cookie_jar( $cookie_jar );
  $ua->agent("Mozilla/6.0");

  my $req = new HTTP::Request 'HEAD' => $url;
  $req->header('Accept' => 'text/html');
  $res = $ua->request($req);
  if ($res->is_success) 
  {
    my $headers = $res->headers;
    return $headers;
  }
return 0;
}
########################################################

#my $oids_file="metagenomes_oids.txt";
my $oids_file="new_metagenomes.txt";
open(OIDS, $oids_file) || die("Could not open IDs file!");
@raw_data=<OIDS>;
close(OIDS);

my $err_file="Errors.txt";
open(ERR_FILE,$err_file) || die("Could not open errors file!");

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
			print "Downloading gene info for: $id...\n";
		
	 		# Create a user agent
	 		# if !(ignore_discard => 1) the cookie will not be written down !!!
	 		my $ua = LWP::UserAgent->new( cookie_jar =>HTTP::Cookies->new( file =>'./cookies.txt', autosave => 1, ignore_discard => 1 ));
	 		$ua->agent("Mozilla/6.0");
	 		$ua->timeout( 1800 );

	  		my $url="http://img.jgi.doe.gov/cgi-bin/m/main.cgi?section=GeneInfoPager&page=viewGeneInformation&taxon_oid=$id";

	  		# Perform the request
	  		my $req = GET "$url";
	  		my $response = $ua->request($req);
	  		if ( ! $response->is_success() ) 
	  		{
	     			die "Couldn't connect to the web";
	  		}

	  		# Deleting the user agent, the cookie is written down
	  		undef $ua;

	  		sleep(10);

	  		#Beginning of the access to the actual download page
	  		my $fileSize = 1;
	  		my $fileSizeServer = 0;
	  		my $counter = 1;
	  		my $maxNumberAttempts = 12;
	  		do
	  		{
	    			print "Attempt to download file: $counter\n";
	    			my $cookie_jar = HTTP::Cookies->new(file     => "./cookies.txt",);
	    			my $browser = LWP::UserAgent->new;
	    			$browser->cookie_jar( $cookie_jar );
	    			$browser->agent("Mozilla/6.0");
	    			$browser->timeout( 1800 );
	    			my $url2 ="http://img.jgi.doe.gov/cgi-bin/m/main.cgi?section=TaxonDetail&downloadTaxonInfoFile=1&taxon_oid=$id&_noHeader=1";
	    			$response = $browser->get($url2);

	    			# Check for HTTP error codes
	    			die 'http status: ' . $response->code . ' ' . $response->message
	    			unless ($response->is_success);

	    			# Output the entry
				open (MYFILE, ">./genes_info/$id.info.xls");
				my $rawData = $response->content();
				print MYFILE $rawData;
				close (MYFILE);

	    			$fileSize = -s "./genes_info/$id.info.xls";

	    			my $header = GetFileSize($url2);
				if( $header != 0)
				{
	    				$fileSizeServer = $header->content_length;
				}
				else
				{
					print "Error: Response not received from server\n";
				}
	    			$counter++;

	    			sleep(5);
print "Server size: $fileSizeServer\n";
print "Local size: $fileSize\n";
	  		}while( $fileSizeServer > $fileSize && $counter <= $maxNumberAttempts );

	  		if( $counter > $maxNumberAttempts )
                        { 
                          print "ERROR: The gene info file $id wasn't correctly downloaded. Downloaded $fileSize bytes of $fileSizeServer\n";
                          print ERR_FILE "The gene info file $id wasn't correctly downloaded. Downloaded $fileSize bytes of $fileSizeServer\n";
                        }
		}#else		
	}#if $id m/#
}#foreach
close(ERR_FILE);
