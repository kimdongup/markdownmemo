#!"C:\strawberry\perl\bin\perl.exe"
##
##  printenv -- demo CGI program which just prints its environment
##
use strict;
use utf8;
use Encode;
use URI::Escape;
use CGI;
my $var;
my $val;

print "Content-type: text/plain; charset=iso-8859-1\n\n";
foreach $var (sort(keys(%ENV))) {
	$val = $ENV{$var};
	$val =~ s|\n|\\n|g;
	$val =~ s|"|\\"|g;
	print "${var}=\"${val}\"\n";
}
