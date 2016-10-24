#!/usr/bin/perl -w


#Función que devuelve el html de una URL en un único string
sub getUrl
{
  my( $url ) = @_;
  # Load LWP
	use LWP::UserAgent;

	# Create a user agent
	my $ua = LWP::UserAgent->new();
	$ua->agent("Mozilla/6.0");

	#my $url="http://img.jgi.doe.gov/cgi-bin/m/main.cgi?section=TaxonDetail&taxon_oid=2014730001";
	# Perform the request
	my $response = $ua->get($url);

	# Check for HTTP error codes
	die 'http status: ' . $response->code . ' ' . $response->message
	unless ($response->is_success);

	# Output the entry
	#print "Output dumped to file data.txt";
	#open (MYFILE, '>>data.txt');
	my $rawHtml = $response->content();
	#print MYFILE $rawHtml;
	#close (MYFILE);

}

1;
