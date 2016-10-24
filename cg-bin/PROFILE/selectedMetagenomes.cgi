#!/usr/bin/perl -w

use CGI;

$query = new CGI;

#use constant WORK_DIR => "/usr/lib/cgi-bin/commics/work-dir";
use constant WORK_DIR => "/home/master/Escritorio/furbi";


print $query->header;

my $file2open = $query->param('file');
#my $file2open = "66_1295390325830";
open (IN, WORK_DIR."/info_cda_$file2open.txt");

if(tell(IN) != -1)
{
  @file = <IN>;

  print "<select id=\"metagenomes\">";
  foreach my $line(@file)
  {
    my($id,$name)=split("\t",$line);
    print "<option value=\"$id\">$name</option>\n";
  }

  print "</select>\n";

  close(IN);
}
else
{
print "<select id=\"metagenomes\">";
print "</select>\n";
}


