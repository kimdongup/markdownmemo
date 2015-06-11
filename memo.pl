#!"C:\strawberry\perl\bin\perl.exe"
package farm;
use utf8;
#use strict;
use Encode;
use URI::Escape;
use CGI;
use CGI::Carp qw(fatalsToBrowser);

use vars qw($ConfigFile $WikiVersion $WikiRelease $HashKey);
# Configuration/constant variables:
use vars qw(@RcDays @HtmlPairs @HtmlSingle
    $TempDir $LockDir $DataDir $HtmlDir $UserDir $KeepDir $PageDir
    $InterFile $RcFile $RcOldFile $IndexFile $FullUrl $SiteName $HomePage
    $LogoUrl $RcDefault $IndentLimit $RecentTop $EditAllowed $UseDiff
    $UseSubpage $UseCache $RawHtml $LogoLeft
    $KeepDays $HtmlTags $HtmlLinks $UseDiffLog $KeepMajor $KeepAuthor
    $FreeUpper $EmailNotify $SendMail $EmailFrom $FastGlob $EmbedWiki
    $ScriptTZ $BracketText $UseAmPm $UseIndex $UseLookup
    $RedirType $AdminPass $EditPass $NetworkFile $BracketWiki
    $FreeLinks $WikiLinks $AdminDelete $FreeLinkPattern $RCName $RunCGI
    $ShowEdits $LinkPattern $InterLinkPattern $InterSitePattern
    $UrlProtocols $UrlPattern $ImageExtensions $RFCPattern $ISBNPattern
    $FS $FS1 $FS2 $FS3 $CookieName $SiteBase $StyleSheetUrl $NotFoundPg
    $FooterNote $EditNote $MaxPost $NewText $NotifyDefault $HttpCharset);

### 패치를 위해 추가된 환경설정 변수
use vars qw(
    $UserGotoBar $UserGotoBar2 $UserGotoBar3 $UserGotoBar4
    $SOURCEHIGHLIGHT @SRCHIGHLANG $EditNameLink
    $EditGuideInExtern $SizeTopFrame $SizeBottomFrame
    $LogoPage $CheckTime $LinkDir $IconUrl $CountDir $UploadDir $UploadUrl
    $HiddenPageFile $TemplatePage
    $InterWikiMoniker $SiteDescription $RssLogoUrl $RssDays $RssTimeZone
    $SlashLinks $InterIconUrl $JavaScriptUrl
    $UseLatex $UserHeader $OekakiJarUrl @UrlEncodingGuess $UrlPrefix
    $TwitterID $TwitterPass $TwitterPrefix
    $TwitterConsumerKey $TwitterConsumerSecret $TwitterAccessToken $TwitterAccessTokenSecret
    );

use vars qw($DocID $ImageTag $ClickEdit $UseEmoticon $EmoticonUrl $EditPagePos);        # luke
use vars qw($TableOfContents @HeadingNumbers $NamedAnchors $AnchoredLinkPattern);
use vars qw($TableTag $TableMode);

# Note: $NotifyDefault is kept because it was a config variable in 0.90
# Other global variables:
use vars qw(%Page %Section %Text %InterSite %SaveUrl %SaveNumUrl
    %KeptRevisions %UserCookie %SetCookie %UserData %IndexHash %Translate
    %LinkIndex $InterSiteInit $SaveUrlIndex $SaveNumUrlIndex $MainPage
    $OpenPageName @KeptList @IndexList $IndexInit
    $q $Now $UserID $TimeZoneOffset $ScriptName );

### 패치를 위해 추가된 내부 전역 변수
use vars qw(%RevisionTs $FS_lt $FS_gt $StartTime $Sec_Revision $Sec_Ts
    $ViewCount $AnchoredFreeLinkPattern %UserInterest %HiddenPage
    $pageid $IsPDA $MemoID $QuotedFullUrl %MacroFile $UseShortcut
    $UseShortcutPage $SectionNumber $AnchorPattern $GotoTextFieldId);

local $| = 1;  # Do not buffer output (localized for mod_perl)
umask 0;

$DataDir      = "data";          # Main wiki directory
$UrlPrefix = "http:/127.0.0.1/cgi-bin";  # URL prefix for other variables ($...Url)
$HttpCharset  = "UTF-8";         # Charset for pages, like "iso-8859-2"
$HomePage     = "HomePage";      # Home page (change space to _)
$LogoPage     = ""; 
$SlashLinks   = 0;      # 1 = use script/action links, 0 = script?action
$UseCache    = 0;       # 1 = cache HTML pages,   0 = generate every page
$UploadDir    = "./upload";                     # directory containing uploaded files
$UploadUrl    = "$UrlPrefix/upload";     # URL for the directory containing uploaded files
$MaxPost      = 1024 * 1024 * 3; # Maximum 3MB posts (file upload limit)
$FreeLinks   = 2;       # 1 = use [[word]] links, 0 = LinkPattern only
$RedirType    = 1;               # 1  = CGI.pm, 2  = script, 3  = no redirect
$UseCache    = 0;       # 1 = cache HTML pages,   0 = generate every page

# == You should not have to change anything below this line. =============
$IndentLimit = 20;                  # Maximum depth of nested lists
$PageDir     = "$DataDir/page";     # Stores page data
$HtmlDir     = "$DataDir/html";     # Stores HTML versions
$UserDir     = "$DataDir/user";     # Stores user data
$KeepDir     = "$DataDir/keep";     # Stores kept (old) page data
$TempDir     = "$DataDir/temp";     # Temporary files and locks
$LockDir     = "$TempDir/lock";     # DB is locked if this exists
$InterFile   = "intermap";          # Interwiki site->url map
$RcFile      = "$DataDir/rclog";    # New RecentChanges logfile
$RcOldFile   = "$DataDir/oldrclog"; # Old RecentChanges logfile
$IndexFile   = "$DataDir/pageidx";  # List of all pages
$LinkDir     = "$DataDir/link";    # by gypark. Stores the links of each page
$CountDir    = "$DataDir/count";    # by gypark. Stores view-counts
$HiddenPageFile = "$DataDir/hidden";  # hidden pages list file



# use open IO => ": encoding (cp949)";
# binmode (STDIN, ": encoding (cp949)");
# binmode (STDOUT, ": encoding (cp949)");
# binmode (STDERR,": encoding (cp949)"); 

# print "Content-Type: text/html\n\n";

sub ReportError {
    my ($errmsg) = @_;

    print $q->header(-charset=>"$HttpCharset"), "<H2>", $errmsg, "</H2>", $q->end_html;
}
sub T {
    my ($text) = @_;

    if (1) {   # Later make translation optional?
        if (defined($Translate{$text}) && ($Translate{$text} ne ''))  {
            return $Translate{$text};
        }
    }
    return $text;
}
sub Ts {
    my ($text, $string) = @_;

    $text = T($text);
    $text =~ s/\%s/$string/;
    return $text;
}
sub CreateDir {
    my ($newdir) = @_;
    if (!(-d $newdir)) {
        mkdir($newdir, 0777) or die(Ts('cant create directory %s', $newdir) . ": $!");
    }
}
sub GetPageFile {
    my ($id) = @_;

    return $PageDir . "/" . &GetPageDirectory($id) . "/$id.db";
}
sub GetPageDirectory {
    my ($id) = @_;

    if ($id =~ /^([a-zA-Z])/) {
        return uc($1);
    }
    return "other";
}
sub OpenPage {
    my ($id) = @_;
    my ($fname, $data);

    if ($OpenPageName eq $id) {
        return;
    }
    %Section = ();
    %Text = ();
    $fname = &GetPageFile($id);
    if (-f encode('cp949',decode('utf8', &GetPageFile($id)))) {
        $data = &ReadFileOrDie($fname);
        %Page = split(/$FS1/, $data, -1);  # -1 keeps trailing null fields
    } else {
        &OpenNewPage($id);
    }

    $OpenPageName = $id;

}
sub OpenNewPage {
    my ($id) = @_;
	
    %Page = ();
    $Page{'version'} = 3;      # Data format version
    $Page{'revision'} = 0;     # Number of edited times
    $Page{'tscreate'} = $Now;  # Set once at creation
    $Page{'ts'} = $Now;        # Updated every edit
}
sub ReadFile {
    my ($fileName) = @_;
    my ($data);
    local $/ = undef;   # Read complete files

    if ( open(my $in, '<', $fileName) ) {
        $data = <$in>;
        close $in;
        return (1, $data);
    }
    return (0, "");
}
sub ReadFileOrDie {
    my ($fileName) = @_;
    my ($status, $data);

    ($status, $data) = &ReadFile(encode('cp949',decode('utf8',$fileName)));
    if (!$status) {
        die(Ts('Can not open %s', $fileName) . ": $!");
    }
    return $data;
}
sub OpenDefaultText {
    &OpenText('default');
}
sub OpenText {
    my ($name) = @_;

    if (!defined($Page{"text_$name"})) {
        &OpenNewText($name);
    } else {
        &OpenSection("text_$name");
        %Text = split(/$FS3/, $Section{'data'}, -1);
    }
}
sub OpenNewText {
    my ($name) = @_;  # Name of text (usually "default")
    %Text = ();
    # Later consider translation of new-page message? (per-user difference?)
    if ($NewText ne '') {
        $Text{'text'} = T($NewText);
    } else {
        $Text{'text'} = T('Describe the new page here.') . "\n";
    }

    $Text{'text'} .= "\n"  if (substr($Text{'text'}, -1, 1) ne "\n");
    $Text{'minor'} = 0;      # Default as major edit
    $Text{'newauthor'} = 1;  # Default as new author
    $Text{'summary'} = '';
    &OpenNewSection("text_$name", join($FS3, %Text));
}
sub OpenSection {
    my ($name) = @_;

    if (!defined($Page{$name})) {
        &OpenNewSection($name, "");
    } else {
        %Section = split(/$FS2/, $Page{$name}, -1);
    }
}
sub OpenNewSection {
    my ($name, $data) = @_;

    %Section = ();
    $Section{'name'} = $name;
    $Section{'version'} = 1;      # Data format version
    $Section{'revision'} = 0;     # Number of edited times
    $Section{'tscreate'} = $Now;  # Set once at creation
    $Section{'ts'} = $Now;        # Updated every edit
    $Section{'ip'} = $ENV{REMOTE_ADDR};
    $Section{'host'} = '';        # Updated only for real edits (can be slow)
    $Section{'id'} = $UserID;
    $Section{'username'} = &GetParam("username", "");
    $Section{'data'} = $data;
    $Page{$name} = join($FS2, %Section);  # Replace with save?
}
sub GetParam {
    my ($name, $default) = @_;
    my $result;

    $result = $q->param($name);
### POST 로 넘어올 경우의 데이타 처리
    if (!defined($result)) {
        $result = $q->url_param($name);
    }
    if (!defined($result)) {
        if (defined($UserData{$name})) {
            $result = $UserData{$name};
        } else {
            $result = $default;
        }
    }
    return $result;
}

sub DoWikiRequest {
	my ($item,$temp);
### slashlinks 처리
#    if ($SlashLinks && (length($ENV{'PATH_INFO'}) > 1)) {
        $ENV{'QUERY_STRING'} .= '&' if ($ENV{'QUERY_STRING'});
		### QUERY_STRING 또는 PATH_INFO가 utf-8이 아닌 인코딩이라서
		$item = uri_unescape($ENV{'REQUEST_URI'});
		$item =~ s/$ENV{'SCRIPT_NAME'}//i;
		$ENV{'PATH_INFO'} = $item;
        $ENV{'QUERY_STRING'} .= substr($ENV{'PATH_INFO'}, 1);
        $temp = decode('utf8',$ENV{'QUERY_STRING'});
        $temp = $ENV{'QUERY_STRING'};
        $temp = decode('cp949',$ENV{'QUERY_STRING'});
#    }
#	$ENV{'QUERY_STRING'} = guess_and_convert($ENV{'QUERY_STRING'});

	&InitLinkPatterns();
    if (!&DoCacheBrowse()) {
        &InitRequest() or return;
        if (!&DoBrowseRequest()) {
            &DoOtherRequest();
        }
    }
}
sub InitLinkPatterns {
    my ($UpperLetter, $LowerLetter, $AnyLetter, $LpA, $LpB, $QDelim);

    # Field separators are used in the URL-style patterns below.
#  $FS  = "\xb3";      # The FS character is a superscript "3"
    $FS  = "\x1e";      # by gypark. from oddmuse
    $FS1 = $FS . "1";   # The FS values are used to separate fields
    $FS2 = $FS . "2";   # in stored hashtables and other data structures.
    $FS3 = $FS . "3";   # The FS character is not allowed in user data.
### added by gypark
    $FS_lt = $FS . "lt";
    $FS_gt = $FS . "gt";

    $UpperLetter = "[A-Z";
    $LowerLetter = "[a-z";
    $AnyLetter   = "[A-Za-z";
### 라틴 문자 지원
#   $UpperLetter .= "\xc0-\xde";
#   $LowerLetter .= "\xdf-\xff";
#   $AnyLetter   .= "\x80-\xff";
    $AnyLetter   .= "_0-9";
    $UpperLetter .= "]"; $LowerLetter .= "]"; $AnyLetter .= "]";
#   $AnyLetter   = "(?:[A-Za-z_0-9]|(?:[\xc2-\xdf][\x80-\xbf]))";

    # Main link pattern: lowercase between uppercase, then anything
    $LpA = $UpperLetter . "+" . $LowerLetter . "+" . $UpperLetter
                 . $AnyLetter . "*";
    # Optional subpage link pattern: uppercase, lowercase, then anything
    $LpB = $UpperLetter . "+" . $LowerLetter . "+" . $AnyLetter . "*";

    if ($UseSubpage) {
        # Loose pattern: If subpage is used, subpage may be simple name
        $LinkPattern = "((?:(?:$LpA)?\\/$LpB)|$LpA)";
        # Strict pattern: both sides must be the main LinkPattern
        # $LinkPattern = "((?:(?:$LpA)?\\/)?$LpA)";
    } else {
        $LinkPattern = "($LpA)";
    }
    $QDelim = '(?:"")?';     # Optional quote delimiter (not in output)
    $LinkPattern .= $QDelim;

    # Inter-site convention: sites must start with uppercase letter
    # (Uppercase letter avoids confusion with URLs)
    $InterSitePattern = $UpperLetter . $AnyLetter . "+";
    $InterLinkPattern = "((?:$InterSitePattern:[^\\]\\s\"<>$FS]+)$QDelim)";

    # free link [[pagename]]
    if ($FreeLinks) {
        # Note: the - character must be first in $AnyLetter definition
        $AnyLetter = "[-,.()' _0-9A-Za-z\x80-\xff]";
    }
    if ($UseSubpage) {
        $FreeLinkPattern = "((?:(?:$AnyLetter+)?\\/)?$AnyLetter+)";
    } else {
        $FreeLinkPattern = "($AnyLetter+)";
    }
    $FreeLinkPattern .= $QDelim;

    # anchored link
    $AnchorPattern = '#([0-9A-Za-z\x80-\xff]+)';
    $AnchoredLinkPattern = $LinkPattern . $AnchorPattern . $QDelim if $NamedAnchors;
    $AnchoredFreeLinkPattern = $FreeLinkPattern . $AnchorPattern . $QDelim if $NamedAnchors;

    # Url-style links are delimited by one of:
    #   1.  Whitespace                           (kept in output)
    #   2.  Left or right angle-bracket (< or >) (kept in output)
    #   3.  Right square-bracket (])             (kept in output)
    #   4.  A single double-quote (")            (kept in output)
    #   5.  A $FS (field separator) character    (kept in output)
    #   6.  A double double-quote ("")           (removed from output)
    $UrlProtocols = 'http|https|ftp|afs|news|nntp|mid|cid|mailto|wais|mms|mmst|prospero|telnet|gopher|irc';
    $UrlProtocols .= '|file' if $NetworkFile;
    $UrlPattern = "((?:(?:$UrlProtocols):[^\\]\\s\"<>$FS]+)$QDelim)";
    $ImageExtensions = "(gif|jpg|png|bmp|jpeg|GIF|JPG|PNG|BMP|JPEG)";
    $RFCPattern = "RFC\\s?(\\d+)";
    $ISBNPattern = "ISBN:?([0-9-xX]{10,})";
}
sub DoCacheBrowse {
    my ($query, $idFile, $text);

    return 0  if (!$UseCache);
    $query = $ENV{'QUERY_STRING'};
    if (($query eq "") && ($ENV{'REQUEST_METHOD'} eq "GET")) {
### LogoPage 가 있으면 이것을 embed 형식으로 출력
        if ($LogoPage eq "") {
            $query = $HomePage;  # Allow caching of home page.
        } else {
            $query = $LogoPage;
        }
    }

### LogoPage 가 있으면 이것을 embed 형식으로 출력
    return 0 if ($query eq $LogoPage);

    if (!($query =~ /^$LinkPattern$/)) {
        if (!($FreeLinks && ($query =~ /^$FreeLinkPattern$/))) {
            return 0;  # Only use cache for simple links
        }
    }
    $idFile = &GetHtmlCacheFile($query);
    if (-f $idFile) {
        local $/ = undef;   # Read complete files
        open my $in, '<', $idFile or return 0;
        $text = <$in>;
        close $in;
        print $text;
        return 1;
    }
    return 0;
}
sub InitRequest {
    my @ScriptPath = split('/', "$ENV{SCRIPT_NAME}");

    $CGI::POST_MAX = $MaxPost;
    $CGI::DISABLE_UPLOADS = 0;
    $q = new CGI;
    $q->autoEscape(undef);

### file upload
    my $cgi_error = $q->cgi_error();
    if (defined $cgi_error and $cgi_error =~ m/^413/) {
        print $q->redirect(-url=>"http:$ENV{SCRIPT_NAME}".&ScriptLinkChar()."action=upload&error=3");
        exit 1;
    }
    $UploadUrl = "http:$UploadDir" if ($UploadUrl eq "");

    $Now = time;                     # Reset in case script is persistent
    $ScriptName = pop(@ScriptPath);  # Name used in links
### slashlinks 처리
    if ($SlashLinks) {
        my $numberOfSlashes = ($ENV{'PATH_INFO'} =~ tr[/][/]);
        $ScriptName = ('../' x $numberOfSlashes) . $ScriptName;
    }
    $ScriptName = $FullUrl if ($FullUrl ne '');
#####
    $IndexInit = 0;                  # Must be reset for each request
    $InterSiteInit = 0;
    %InterSite = ();
    $MainPage = ".";       # For subpages only, the name of the top-level page
    $OpenPageName = "";    # Currently open page
    &CreateDir($DataDir);  # Create directory if it doesn't exist
    if (!-d $DataDir) {
        &ReportError(Ts('Could not create %s', $DataDir) . ": $!");
        return 0;
    }
	
# ### hide page
    # my ($status, $data) = &ReadFile($HiddenPageFile);
    # if ($status) {
        # %HiddenPage = split(/$FS1/, $data, -1);
    # }

    return 1;
}
sub DoBrowseRequest {
    my ($id, $action, $text);

    if (!$q->param) {             # No parameter
        if ($LogoPage eq "") {
            &BrowsePage($HomePage);
        } else {
            $EmbedWiki = 1;
            &BrowsePage($LogoPage);
        }

        return 1;
    }
    $id = &GetParam('keywords', '');

    if ($id) {                    # Just script?PageName
### QUERY_STRING 이 utf-8이 아닌 인코딩인 경우
        $id = guess_and_convert($id);

        if ($FreeLinks && (!-f &GetPageFile($id))) {
            $id = &FreeToNormal($id);
        }
        if (($NotFoundPg ne '') && (!-f &GetPageFile($id))) {
            $id = $NotFoundPg;
        }
        $DocID = $id;
        &BrowsePage($id)  ;#if &ValidIdOrDie($id);
        return 1;
    }
	
    $action = lc(&GetParam('action', ''));
    $id = &GetParam('id', '');
### QUERY_STRING 이 utf-8이 아닌 인코딩인 경우
    $id = guess_and_convert($id);
    $q->param('id', $id);

    $DocID = $id;
    if ($action eq 'browse') {
        if ($FreeLinks && (!-f &GetPageFile($id))) {
            $id = &FreeToNormal($id);
        }
        if (($NotFoundPg ne '') && (!-f &GetPageFile($id))) {
            $id = $NotFoundPg;
        }

### id 가 NULL 일 경우 홈으로 이동
        if ($id eq '') {
            $id = $HomePage;
        }

        &BrowsePage($id) ;# if &ValidIdOrDie($id);
        return 1;
    }
    return 0;  # Request not handled
}
sub BrowsePage {
    my ($id) = @_;
    my ($fullHtml, $oldId, $allDiff, $showDiff, $openKept);
    my ($revision, $goodRevision, $diffRevision, $newText);

	&OpenPage($id);
    &OpenDefaultText();

	$MainPage = $id;
    $MainPage =~ s|/.*||;  # Only the main page name (remove subpage)
    $fullHtml = &GetHttpHeader();
    $fullHtml = &GetHeader($id, &QuoteHtml($id), $oldId);
	$fullHtml .= decode('cp949',$Text{'text'});
	$fullHtml .= &GetFooterText($id, $goodRevision);
    print $fullHtml;
	&UpdateHtmlCache($id, $fullHtml); 
	
}
sub DoOtherRequest {
    my ($id, $action, $text, $search);

    $ClickEdit = 0;                                 # luke added
    $UseShortcutPage = 0;       # 단축키
    $action = &GetParam("action", "");
    $id = &GetParam("id", "");
    if ($action ne "") {
        $action = lc($action);
### action 모듈화
        my $action_file = "";
        my ($MyActionDir, $ActionDir) = ("./myaction/", "./action/");
        if (-f "$MyActionDir/$action.pl") {
            $action_file = "$MyActionDir/$action.pl";
        } elsif (-f "$ActionDir/$action.pl") {
            $action_file = "$ActionDir/$action.pl";
        }

        if ($action_file ne "") {
            my $loadaction = eval "require '$action_file'";

            if (not $loadaction) {      # action 로드 실패
                $UseShortcut = 0;
                &ReportError(Ts('Fail to load action: %s', $action));
                return;
            }

            my $func = "action_$action";
            &{\&$func}();
            return;
        }
###
        if ($action eq "edit") {
            $UseShortcut = 0;   # 단축키
            &DoEdit($id, 0, 0, "", 0)  ;#if &ValidIdOrDie($id);
         } elsif ($action eq "upload") {
            $UseShortcut = 0;
            &DoUpload();
        } else {
            # Later improve error reporting
            $UseShortcut = 0;
            &ReportError(Ts('Invalid action parameter %s', $action));
        }
        return;
    }

    # Handle posted pages.
    if (&GetParam("oldtime", "") ne "") {
        $id = &GetParam("title", "");
        $UseShortcut = 0;
        &DoPost()  if &ValidIdOrDie($id);
        return;
    }
    # Later improve error message
    &ReportError(T('Invalid URL.'));
}
sub DoPost {
    my $string = &GetParam("text", undef);
    my $id = &GetParam("title", "");
    my $summary = &GetParam("summary", "");
    my $oldtime = &GetParam("oldtime", "");
    my $oldconflict = &GetParam("oldconflict", "");

    DoPostMain($string, $id, $summary, $oldtime, $oldconflict, 0);
    return;
}
sub DoPostMain {
    my ($string, $id, $summary, $oldtime, $oldconflict, $isEdit, $rebrowseid) = @_;
    my ($editDiff, $old, $newAuthor, $pgtime, $oldrev, $preview, $user);
    my $editTime = $Now;
    my $authorAddr = $ENV{REMOTE_ADDR};
###
    $string =~ s/$FS//g;
    $summary =~ s/$FS//g;
    $summary =~ s/[\r\n]//g;
    # Add a newline to the end of the string (if it doesn't have one)
    $string .= "\n"  if (!($string =~ /\n$/));
	
    # Remove "\r"-s (0x0d) from the string
    $string =~ s/\r//g;

    $Text{'text'} = $string;
    $Text{'minor'} = $isEdit;
    $Text{'newauthor'} = $newAuthor;
    $Text{'summary'} = $summary;
    # $Section{'host'} = &GetRemoteHost(0);
    &SaveDefaultText();
    &SavePage($id);
    &ReBrowsePage($id, "", 1) if ($id ne "!!");
}
sub SaveSection {
    my ($name, $data) = @_;

    $Section{'revision'} += 1;   # Number of edited times
    $Section{'ts'} = $Now;       # Updated every edit
    $Section{'ip'} = $ENV{REMOTE_ADDR};
    $Section{'id'} = $UserID;
    $Section{'username'} = &GetParam("username", "");
    $Section{'data'} = $data;
    $Page{$name} = join($FS2, %Section);
}
sub SaveText {
    my ($name) = @_;

    &SaveSection("text_$name", join($FS3, %Text));
}
sub SaveDefaultText {
    &SaveText('default');
}
sub SavePage {
	my ($OpenPageName) = @_ ; 
    my $file = &GetPageFile($OpenPageName);
    $Page{'revision'} += 1;    # Number of edited times
    $Page{'ts'} = $Now;        # Updated every edit
    &CreatePageDir($PageDir, $OpenPageName);
    &WriteStringToFile($file, join($FS1, %Page));
}
sub ReBrowsePage {
    my ($id, $oldId, $isEdit) = @_;
    $id = &EncodeUrl($id);
    $oldId = &EncodeUrl($oldId);


    if ($oldId ne "") {   # Target of #REDIRECT (loop breaking)
        print &GetRedirectPage("action=browse&id=$id&oldid=$oldId",
                                                     $id, $isEdit);
    } else {
        print &GetRedirectPage($id, $id, $isEdit);
    }
}
sub EncodeUrl {
    my ($string) = @_;
    $string =~ s!([^:/&?#=a-zA-Z0-9_.-])!uc sprintf "%%%02x", ord($1)!eg;
    return $string;
}
sub DecodeUrl {
    my ($string) = @_;
    $string =~ s/%([0-9a-fA-F]{2})/chr(hex($1))/ge;
    return $string;
}
sub GetRedirectPage {
    my ($newid, $name, $isEdit) = @_;
    my ($url, $html);
    my ($nameLink);

    # Normally get URL from script, but allow override.
    $FullUrl = $q->url(-full=>1)  if ($FullUrl eq "");
    $url = $FullUrl . &ScriptLinkChar() . $newid;
    $nameLink = "<a href=\"$url\">$name</a>";
    if ($RedirType < 3) {
        if ($RedirType == 1) {             # Use CGI.pm
            # NOTE: do NOT use -method (does not work with old CGI.pm versions)
            # Thanks to Daniel Neri for fixing this problem.
            $html = $q->redirect(-uri=>$url);
        } else {                           # Minimal header
            $html  .= "Status: 302 Moved\n";
            $html .= "Location: $url\n";
            $html .= "Content-Type: text/html\n";  # Needed for browser failure
            $html .= "\n";
        }
        $html .= "\n" . Ts('Your browser should go to the %s page.', $newid);
        $html .= ' ' . Ts('If it does not, click %s to continue.', $nameLink);
    } else {
        if ($isEdit) {
            $html  = &GetHeader('', T('Thanks for editing...'), '');
            $html .= Ts('Thank you for editing %s.', $nameLink);
        } else {
            $html  = &GetHeader('', T('Link to another page...'), '');
        }
        $html .= "\n<p>";
        $html .= Ts('Follow the %s link to continue.', $nameLink);
        $html .= &GetMinimumFooter();
    }
    return $html;
}
sub GetMinimumFooter {
   $result .= "<a accesskey=\"x\" name=\"PAGE_BOTTOM\" href=\"#PAGE_TOP\">" . T('Top')." [t]" . "</a></DIV>\n" . $q->end_html;

    return $result;
}
sub DoEdit {
    my ($id, $isConflict, $oldTime, $newText, $preview) = @_;
	&OpenPage($id);
    &OpenDefaultText();
#	$pageTime = $Section{'ts'};
	$oldText = $Text{'text'};
	print qq|
<script language="javascript" type="text/javascript">
<!--
function upload()
{
    var w = window.open("$ScriptName${\(&ScriptLinkChar())}action=upload", "upload", "width=640,height=250,resizable=1,statusbar=1,scrollbars=1");
    w.focus();
}
//-->
</script>
|;
	print $q->startform(-method=>"POST", -action=>"$ScriptName", -enctype=>"application/x-www-form-urlencoded",
            -name=>"form_edit", -onSubmit=>"closeok=true; return true;");
	print &GetHiddenValue("title", $id), "\n",
		&GetHiddenValue("oldtime", time), "\n";
    print &GetTextArea('text', $oldText, 20 , 65);
	print $q->submit(-accesskey=>'r', -name=>'Save', -value=>T('Save')), "\n";
	### file upload
    print " ".q(<input accesskey="u" type="button" name="prev1" value=").
            T('Upload File').
            q(" onclick="javascript:upload();">);
}
sub GetHiddenValue {
    my ($name, $value) = @_;

    $q->param($name, $value);
    return $q->hidden($name);
}
sub GetTextArea {
    my ($name, $text, $rows, $cols) = @_;
### &lt; 와 &gt; 가 들어가 있는 페이지를 수정할 경우 자동으로 부등호로 바뀌어 버리는 문제를 해결
    $text =~ s/(<!--.*?-->)/&StoreRaw($1)/ges;
    $text =~ s/(\&)/\&amp;/g;
    $text = &RestoreSavedText($text);
    if (&GetParam("editwide", 1)) {
        return $q->textarea(-accesskey=>'i', -name=>$name, -default=>$text,
                                                -rows=>$rows, -columns=>$cols, -override=>1,
                                                -style=>'width:100%', -wrap=>'virtual');
    }
    return $q->textarea(-accesskey=>'i', -name=>$name, -default=>$text,
                                            -rows=>$rows, -columns=>$cols, -override=>1,
                                            -wrap=>'virtual');
}
sub ValidId {
    my ($id) = @_;

    if (length($id) > 120) {
        return Ts('Page name is too long: %s', $id);
    }
    if ($id =~ m| |) {
        return Ts('Page name may not contain space characters: %s', $id);
    }
    if ($UseSubpage) {
        if ($id =~ m|.*/.*/|) {
            return Ts('Too many / characters in page %s', $id);
        }
        if ($id =~ /^\//) {
            return Ts('Invalid Page %s (subpage without main page)', $id);
        }
        if ($id =~ /\/$/) {
            return Ts('Invalid Page %s (missing subpage name)', $id);
        }
    }
    if ($FreeLinks) {
        $id =~ s/ /_/g;
		print ($id =~ m|\.db$|);
        if (!$UseSubpage) {
            if ($id =~ /\//) {
                return Ts('Invalid Page %s (/ not allowed)', $id);
            }
        }
        if (!($id =~ m|^$FreeLinkPattern$|)) {
            return Ts('Invalid Page %s', $id);
        }
        if ($id =~ m|\.db$|) {
            return Ts('Invalid Page %s (must not end with .db)', $id);
        }
        if ($id =~ m|\.lck$|) {
            return Ts('Invalid Page %s (must not end with .lck)', $id);
        }
        return "";
    } else {
        if (!($id =~ /^$LinkPattern$/)) {
            return Ts('Invalid Page %s', $id);
        }
    }
    return "";
}
sub ValidIdOrDie {
    my ($id) = @_;
    my $error;

    $error = &ValidId($id);
    if ($error ne "") {
        &ReportError($error);
        return 0;
    }
    return 1;
}
sub WriteStringToFile {
    my ($file, $string) = @_;
	
    open(my $out , '>', encode('cp949', decode('utf8',$file)) )  or die(Ts('cant write %s', $file) . ": $!");
    print {$out} $string;
    close $out;
}
sub UpdateHtmlCache {
    my ($id, $html) = @_;
    my $idFile;

    $idFile = &GetHtmlCacheFile($id);
    &CreatePageDir($HtmlDir, $id);
    &WriteStringToFile($idFile, $html);
}
sub CreatePageDir {
    my ($dir, $id) = @_;
    my $subdir;

    &CreateDir($dir);  # Make sure main page exists
    $subdir = $dir . "/" . &GetPageDirectory($id);
    &CreateDir($subdir);
    if ($id =~ m|([^/]+)/|) {
        $subdir = $subdir . "/" . $1;
        &CreateDir($subdir);
    }
}
sub GetHtmlCacheFile {
    my ($id) = @_;

    return $HtmlDir . "/" . &GetPageDirectory($id) . "/$id.htm";
}
sub WikiToHTML {
    my ($pageText) = @_;
    return &RestoreSavedText($pageText);
}
sub RestoreSavedText {
    my ($text) = @_;
    $text =~ s/$FS(\d+)$FS/$SaveUrl{$1}/ge;   # Restore saved text
    $text =~ s/$FS(\d+)$FS/$SaveUrl{$1}/ge;   # Restore nested saved text
    return $text;
}
sub GetFooterText {
    my ($id, $rev) = @_;
    my $result = '';
    $result .= "<br>";
	$result .= &GetEditLink($id, T('Edit text of this page'));
	$result .= "<br>";
    $result .= "<a accesskey=\"x\" name=\"PAGE_BOTTOM\" href=\"#PAGE_TOP\">" . T('Top')." [t]" . "</a></DIV>\n" . $q->end_html;

    return $result;	
	
}

sub GetRemoteHost {
    my ($doMask) = @_;
    my ($rhost, $iaddr);

    $rhost = $ENV{REMOTE_HOST};
    if ($UseLookup && ($rhost eq "")) {
        # Catch errors (including bad input) without aborting the script
        eval 'use Socket; $iaddr = inet_aton($ENV{REMOTE_ADDR});'
                 . '$rhost = gethostbyaddr($iaddr, AF_INET)';
    }
    if ($rhost eq "") {
        $rhost = $ENV{REMOTE_ADDR};
        $rhost =~ s/\d+$/xxx/  if ($doMask);      # Be somewhat anonymous
    }
    return $rhost;
}
sub FreeToNormal {
    my ($id) = @_;

    $id =~ s/ /_/g;
    $id = ucfirst($id);
    if (index($id, '_') > -1) {  # Quick check for any space/underscores
        $id =~ s/__+/_/g;
        $id =~ s/^_//;
        $id =~ s/_$//;
        if ($UseSubpage) {
            $id =~ s|_/|/|g;
            $id =~ s|/_|/|g;
        }
    }
    if ($FreeUpper) {
        # Note that letters after ' are *not* capitalized
        if ($id =~ m|[-_.,\(\)/][a-z]|) {    # Quick check for non-canonical case
            $id =~ s|([-_.,\(\)/])([a-z])|$1 . uc($2)|ge;
        }
    }
    return $id;
}
sub ScriptLinkClass {
    my ($action, $text, $class) = @_;
    my $rel;

    if ($action =~ /action=(.+?)\b/i) {
        if ((lc($1) ne "index") && (lc($1) ne "rc")) {
            $rel = 'rel="nofollow"';
        }
    }

    return "<a $rel href=\"$ScriptName" . &ScriptLinkChar() . "$action\" class=\"$class\">$text</a>";
}
sub QuoteHtml {
    my ($html) = @_;

    $html =~ s/&/&amp;/g;
    $html =~ s/</&lt;/g;
    $html =~ s/>/&gt;/g;
    $html =~ s/&amp;([#a-zA-Z0-9]+);/&$1;/g;  # Allow character references

    return $html;
}

sub GetEditLink {
    my ($id, $name) = @_;

    if ($FreeLinks) {
        $id = &FreeToNormal($id);
        $name =~ s/_/ /g;
    }
    return &ScriptLinkClass("action=edit&id=$id", $name, 'wikipageedit');
}

sub GetHeader {
    my ($id, $title, $oldId) = @_;
    my $header = "";
    my $logoImage = "";
    my $result = "";
    my $embed = &GetParam('embed', $EmbedWiki);
    my $altText = T('[Home]');

    $result = &GetHttpHeader();
    if ($FreeLinks) {
        $title =~ s/_/ /g;   # Display as spaces
    }
    $result .= &GetHtmlHeader("$title : $SiteName", $title);
### pda clip by gypark
    if ($IsPDA) {
        $result .= "<h1>$title</h1>\n<hr>";
    }

    return $result  if ($embed);
### #EXTERN
    return $result if (&GetParam('InFrame','') eq '2');

    my $topMsg = "";
    if ($oldId ne '') {
        $topMsg .= '('.Ts('redirected from %s',&GetEditLink($oldId, $oldId)).')  ';
    }
### #EXTERN
    if (&GetParam('InFrame','') eq '1') {
        $topMsg .= '('.Ts('%s includes external page',&GetEditLink($id,$id)).')';
    }
    $result .= $q->h3($topMsg) if (($oldId ne '') || (&GetParam('InFrame','') eq '1'));

    if ((!$embed) && ($LogoUrl ne "")) {
        $logoImage = "IMG class='logoimage' src=\"$LogoUrl\" alt=\"$altText\" border=0";
        if (!$LogoLeft) {
            $logoImage .= " align=\"right\"";
        }
        $header = "<a accesskey=\"w\" href=\"$ScriptName\"><$logoImage></a>";
    }
    if ($id ne '') {
### 역링크 개선
#       $result .= $q->h1($header . &GetSearchLink($id));
        $result .= $q->h1({-class=>"pagename"}, $header . &GetReverseLink($id));
    } else {
        $result .= $q->h1({-class=>"actionname"}, $header . $title);
    }

### page 처음에 bottom 으로 가는 링크를 추가
### #EXTERN
#    if (&GetParam('InFrame','') eq '') {
#        $result .= "\n<div class=\"gobottom\" align=\"right\"><a accesskey=\"z\" name=\"PAGE_TOP\" href=\"#PAGE_BOTTOM\">". T('Bottom')." [b]" . "</a></div>\n";
#    }

#    if (&GetParam("toplinkbar", 1)) {
#        # Later consider smaller size?
#        $result .= &GetGotoBar($id);
#    }

    return $result;
}

sub GetHttpHeader {
    my $cookie;
    my $t;

    $t = gmtime;
    if (defined($SetCookie{'userid'})) {
### 로긴할 때 자동 로그인 여부 선택
#       $cookie = "$CookieName="
#                       . "rev&" . $SetCookie{'rev'}
#                       . "&id&" . $SetCookie{'id'}
#                       . "&randkey&" . $SetCookie{'randkey'};
#       $cookie .= ";expires=Fri, 08-Sep-2010 19:48:23 GMT";

        $cookie = "$CookieName="
            . "expire&" . $SetCookie{'expire'}
            . "&rev&"   . $SetCookie{'rev'}
            . "&userid&"    . EncodeUrl($SetCookie{'userid'})
            . "&randkey&" . $SetCookie{'randkey'}
            . ";";
### slashlinks 지원 - 로긴,로그아웃시에 쿠키의 path를 동일하게 해줌
        my $cookie_path = $q->url(-absolute=>1);
        if ((my $postfix = $q->script_name()) eq $cookie_path) {    # mod_rewrite 가 사용되지 않은 경우
            $cookie_path =~ s/[^\/]*$//;                            # 스크립트 이름만 제거
        } else {                                        # mod_rewrite
            if ((my $postfix = $q->path_info()) ne '') {    # wiki.pl/ 로 rewrite 된 경우
                $cookie_path =~ s/$postfix$//;
            } else {                                        # wiki.pl? 로 rewrite 된 경우
                my $postfix = $q->query_string();
                $cookie_path =~ s/$postfix$//;
            }
        }
        $cookie .= "path=$cookie_path;";

        if ($SetCookie{'expire'} eq "1") {
            $cookie .= "expires=Tue, 31-Dec-2030 23:59:59 GMT";
        }

        if ($HttpCharset ne '') {
            return $q->header(-cookie=>$cookie,
                -pragma=>"no-cache",
                -cache_control=>"no-cache",
                -last_modified=>"$t",
                -expires=>"+10s",
                -type=>"text/html; charset=$HttpCharset");
        }
        return $q->header(-cookie=>$cookie);
    }
    if ($HttpCharset ne '') {
        return $q->header(-type=>"text/html; charset=$HttpCharset",
            -pragma=>"no-cache",
            -cache_control=>"no-cache",
            -last_modified=>"$t",
            -expires=>"+10s");
    }
    return $q->header();
}
sub GetReverseLink {
    my ($id, $name) = @_;
    $name = $id if ($name eq "");

    if ($FreeLinks) {
        $name =~ s/_/ /g;  # Display with spaces
    }
    return &ScriptLink("action=reverse&id=$id", $name);
}
sub ScriptLinkChar {
    if ($SlashLinks) {
        return '/';
    }
    return '?';
}
sub ScriptLink {
    my ($action, $text) = @_;
    my $rel;

    if ($action =~ /action=(.+?)\b/i) {
        if ((lc($1) ne "index") && (lc($1) ne "rc")) {
            $rel = 'rel="nofollow"';
        }
    } elsif ($action =~ /search=/i) {
        $rel = 'rel="nofollow"';
    }

    return "<a $rel href=\"$ScriptName" . &ScriptLinkChar() . "$action\">$text</a>";
}
sub guess_and_convert {
    my ($string) = @_;

    # legal UTF-8인지 체크
    if ($HttpCharset =~ /utf-8|utf8/i) {
        if (eval { require Unicode::CheckUTF8; }) {
            if (Unicode::CheckUTF8::is_utf8($string)) {
                # ok
                return $string;
            }
        }
    }

    # 추측
    if (eval { require Encode::Guess; }) {
        my @suspects = (@UrlEncodingGuess, 'utf8');
        my $decoder = Encode::Guess::guess_encoding($string, @suspects);
        if (ref($decoder)) {
            # 추측 성공
            return convert_encode($string, $decoder->name, $HttpCharset);
        }
    }

    # 모듈이 없거나, 있지만 추측 실패. 변환 포기
    return $string;
}
sub convert_encode {
    my ($str, $from, $to) = @_;
    $str = encode($to, decode($from, $str));
    return $str;
}

sub GetHtmlHeader {
	$dtd = '-//IETF//DTD HTML//EN';
    $html = qq(<!DOCTYPE HTML PUBLIC "$dtd">\n);
    $title = QuoteHtml($title);
    $html .= "<HTML><HEAD><TITLE>$title</TITLE>\n";
    return $html;
}
sub DoUpload {
    my $file;
    my $upload = &GetParam('upload');
    my $prev_error = &GetParam('error', "");
    my @uploadError = (
            T('Upload completed successfully'),
            T('Invalid filename'),
            T('You can not upload html or any executable scripts'),
            T('File is too large'),
            T('File has no content'),
            T('Failed to get lock'),
        );

    my $result;

    print &GetHttpHeader();
    print &GetHtmlHeader(T('Upload File') . " : $SiteName", "");
    print $q->h2(T('Upload File')) . "\n";

    if ($prev_error) {
        print "<b>$uploadError[$prev_error]</b><br><hr>\n";
    } elsif ($upload) {
        $file = &GetParam('upload_file');
        $result = &UploadFile($file);
        print "<b>$uploadError[$result]</b><br><hr>\n";
    }
    &PrintUploadFileForm();
    print $q->end_html;
}
sub UploadFile {
    my ($file) = @_;
    my ($filename);

    if ($file =~ m/\//) {
        $file =~ m/(.*)\/([^\/]*)/;
        $filename = $2;
    } elsif ($file =~ m/\\/) {
        $file =~ m/(.*)\\([^\\]*)/;
        $filename = $2;
    } else {
        $filename = $file;
    }

    if (($filename eq "") || ($filename =~ /\0/)) {
        return 1;
    }

    if ($filename =~ m/(\.pyc|\.py|\.pl|\.html|\.htm|\.php|\.cgi)$/i) {
        return 2;
    }

    $filename =~ s/ /_/g;
    $filename =~ s/#/_/g;

    my $target      = GetUniqueUploadFilename( $UploadDir, $filename );
    my $target_full = "$UploadDir/$target";

    &CreateDir($UploadDir);

    my $fh;

    binmode $fh;
    while (<$file>) {
        print {$fh} $_;
    }
    close $fh;
    chmod(0644, "$target_full");

    if ((-s "$target_full") > $MaxPost) {
        unlink "$target_full";
        return 3;
    }

    if ((-s "$target_full") == 0) {
        unlink "$target_full";
        return 4;
    }

    print T('Following is the Interlink of your file') . "<br>\n";
    print "<div style='text-align:center; font-size:larger; font-weight:bold;'>\n";
    print "Upload:$target ";
    print $q->button(
                -name=>T("Copy"),
                -onClick=>"copy_clip('','Upload:$target')"
                );
    print "</div>\n";
    return 0;
}
sub PrintUploadFileForm {
    print T('Select the file you want to upload') . "\n";
    print "<br>".Ts('File must be smaller than %s MB', ($MaxPost / 1024 / 1024)) . "\n";
    print $q->start_form('post',"$ScriptName", 'multipart/form-data') . "\n";
    print "<input type='hidden' name='action' value='upload'>";
    print "<input type='hidden' name='upload' value='1'>" . "\n";
    print "<center>" . "\n";
    print $q->filefield("upload_file","",60,80) . "\n";
    print "&nbsp;&nbsp;" . "\n";
    print $q->submit(T('Upload')) . "\n";
    print "</center>" . "\n";
    print $q->endform();
}
&DoWikiRequest();   # Do everything.
1; # In case we are loaded from elsewhere
