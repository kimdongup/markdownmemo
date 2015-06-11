#!"C:\xampp\perl\bin\perl.exe"
# utf8test.pl
use strict;
use warnings;
use Encode;
use CGI ();
use CGI::Carp 'fatalsToBrowser';

$\ = "\n";

# Invoke this script without a query string to
# get the default (broken) behavior.
#
# Invoke this script with a query string of 'recode'
# to get the 'utf8char' form element recoded into
# utf8. Example:
#
# [url]http://server.com/utf8test.pl?recode[/url]
#
# Or, if you want the old textarea data deleted
# upon successive invocations of the form, add
# a query string of 'delete' like so:
#
# [url]http://server.com/utf8test.pl?delete[/url]
my $RECODE_QUERY = 0;
my $DELETE_QUERY = 0;
$RECODE_QUERY = 1 if $ENV{QUERY_STRING} =~ m/recode/;
$DELETE_QUERY = 1 if $ENV{QUERY_STRING} =~ m/delete/;

my $utf8char;
my $text;
my $query = new CGI;

print $query->header(
-type => 'text/html',
-cht => 'utf8',
);

print $query->start_html(
-title => 'utf8char Test',
-head => CGI::meta ({-http_equiv => 'Content-Type',
-content => 'text/html; cht=utf8' ,
}),
),
$query->h1('utf8char Test');

print <<EOF;
<p> Let's see if it's possible to send
and receive utf8char numeric characters.
</p>
EOF

if (! defined $query->param('utf8char')) {

$utf8char = "";

} else {

$utf8char = $query->param('utf8char');
$utf8char = Encode::decode('utf8', $utf8char);
my $old_utf8char = $query->param('utf8char');

if ($RECODE_QUERY) {
$query->param('utf8char', $utf8char);
}

if ($DELETE_QUERY) {
$query->delete('utf8char');
}

($text = <<EOF) =~ s/^\s*//mg;
<pre> The data received was:
ORIGINAL: $old_utf8char
DECODED: $utf8char
</pre>
EOF


print $text;
}

my $qs = '' eq $ENV{QUERY_STRING} ? '' :
"?$ENV{QUERY_STRING}" ;

print $query->start_form(
-method => 'POST',
-action => $query->url() . $qs );

print $query->textarea(
-name => 'utf8char',
-default => $utf8char,
);

print $query->submit();

print $query->end_form();


print $query->end_html;