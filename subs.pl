#!/usr/bin/perl -w
# by Torben Menke www.entorb.net
# 18.01.2012

# äöüß # ensure that file is utf-8 encoded!!!

# searches for duplicated words in text files

# TODO:
our %opt;
$opt{timing} = 0; # set to 1 to enable timing


use strict; use warnings;
my $s;
use Data::Dumper;
use Time::HiRes('time');
# use utf8;
# use feature 'unicode_strings';

#use Term::ANSIColor;
#print colored ("\"$sTreffer\"", 'red')," ";

# tell perl to use the locale setting -> [[:alpha:]] finds all your letters
use POSIX qw(locale_h);
# tell perl which locale setting to use
setlocale(LC_CTYPE, 'de_DE.UTF-8');

use Encode; #sometimes the input strings are encoded (Umlaute!)
#$text = decode ($encoding,$text);
#print encode ($encoding,$text);


#TODO
#print "Encoding: Linux (1) or Windows (2) file? ";
#$_ = <STDIN>; chomp;
#if    ($_ eq "1") { $encoding = 'utf-8';}
#elsif ($_ eq "2") { $encoding = 'iso-8859-1';}
#print "encoding = $encoding\n";





sub timing {
  # prints out timeing since start 
  return  if ($opt{timing} == 0);
  my $tStart = shift;
  my $wo = '';
  if (@_) {$wo = shift; $wo .= ': ';}
  $_ = sprintf "%.2f" , (time() - $tStart);
  print "<p>".$wo."duration=".$_."s</p>\n";
}

sub openFile {
  my $file = shift;
  our %opt;
  open (FH, "<$file");
  my @cont = <FH>;
  close FH;
  @cont = map {s/\s+$//;$_} @cont; # remove whitespaces and \n from lineends
  # not here: @cont = map {decode ($opt{encodingInput},$_)} @cont;
  return (join "\n",@cont); # returns string
} # openFile


#sub checkTEXorTEXT {
#  my $cont = shift;
#  our %opt;
#  }
 
sub detectEncoding {
  # detects/gueses encoding 'utf-8' or 'iso-8859-1' 
  my $cont = shift;

  my $testfor;
  my $testEnc;
  my $hit='';

  for $testfor ('ä', 'ö', 'ü', 'ß', 'Ä', 'Ö', 'Ü') {
    $s = decode('utf-8', $testfor); # this file is in utf-8!
    if ( decode($testEnc='utf-8' , $cont) =~ m/$s/) {
      $hit=$s; last;
    } elsif ( decode($testEnc='iso-8859-1' , $cont) =~ m/$s/) {
      $hit=$s; last;
    }
  }
  if ($hit ne '') {
#    our %opt;
#    $s = "TODO: Found: $hit -> Encoding = $testEnc<br>\n";
#    $s = encode ($opt{encodingOutput}, $s);
#    print $s;
    return $testEnc;
  } else {
    return 'utf-8';
  }
}


sub detectLang {
  # detects lang EN or DE
  my $cont = shift;
  my %hits;
  $hits{DE} = 0;
  $hits{EN} = 0;
  while ($cont =~ m/\band\b/ig ) { $hits{EN} ++;  }
  while ($cont =~ m/\bder\b/ig ) { $hits{DE} ++;  }
  while ($cont =~ m/\bthe\b/ig ) { $hits{EN} ++;  }
  while ($cont =~ m/\bund\b/ig ) { $hits{DE} ++;  }
  while ($cont =~ m/\bis\b/ig )  { $hits{EN} ++;  }
  while ($cont =~ m/\bist\b/ig ) { $hits{DE} ++;  }
  if ($hits{DE} > $hits{EN}) {return 'DE';}
  else {return 'EN';}
}



sub clearLatex {
  # remove LaTeX Code
  my $cont=shift;
  our %opt;
  
  # comments
  $cont =~ s/\\\%/PLATZHALTER-PRONZENT/g; 
  $cont =~ s/\n\s*?\%[^\n]*\n/ /gs; # % nach \n
  $cont =~ s/\%[^\n]*\n//gs;  # % mitten in Zeile
  $cont =~ s/PLATZHALTER-PRONZENT/\\\%/g;
  $cont =~ s/\\(,| )/ /g; # "\," und "\ "
  $cont =~ s/\\begin\{(thebibliography|tabular|equation|align|verbatim|titlepage)\}.*?\\end\{\1\}//sg; # totally remove some environments (+ contents)
  $cont =~ s/\\(begin|end)\{\w+\}.*//g; # environments starts + stops
  $cont =~ s/\\(newcommand|renewcommand).*//mg; # full line after command
  
  # remove these commands AND their arguments
  $cont =~ s/\s*\\(documentclass|usepackage|include|input|includegraphics|index|label|todo|todof)[^\}]*\}//mg; # + arguments of this commands
# not a good idea!  $cont =~ s/\\\w+//g; # all commands

  # remove some latex commands but keep arguments
  @_ = qw(cBild cBildDraw section subsection subsubsection chapter paragraph subparagraph newpage text\w{2} emph hline item footnote todocite klau klauPd rm text edit change);
  $_ = join '|',@_;
  $cont =~ s/\\($_)(\[|\{)/$2/g;
# replace all refs by Xref
  @_ = qw(cite ref tag pageref eqnref eqref autoref secref figref Figref tabref secrefPage figrefPage FigrefPage eqnrefPage tabrefPage);
  $_ = join '|',@_;
  $cont =~ s/(|\brefs?\.\s?)\\($_).*?\}/Xref/sg;

  $cont =~ s/(\[|\]|\{|\})//g; # remove []{} but not contents
  # $cont =~ s/\$(\w+)\$/$1/gi; # remove $S$ -> S # NEIN weil a vs an

  return $cont;
}

sub printTitle {
  # print section title
  my $s = shift;
  print "<h2>$s</h2>\n";
}
sub printInfo {
  # print info text formatted italics
  my $s = shift;
  print "<p><i>$s</i></p>\n";
}
sub printResultLine {
  # print line
  my ($lineNr, $sTreffer, $line) = (shift,shift,shift);
  our %opt;
  my $line2 = $line;
  my $sTreffer2 = $sTreffer;
   # "." -> "\." etc
  $sTreffer2 =~ s/(\.|\?)/\\$1/g;
  $sTreffer2 =~ s/(\(|\)|\[|\]|\{|\})/\\$1/g;
  my $s;
  $line2 =~ s/$sTreffer2/<font color='red'><b>"$sTreffer"<\/b><\/font>/g;
  $s = "<tr><td>$sTreffer</td><td>\n$line2\n</td></tr>\n";
  print encode ($opt{encodingOutput},$s);
}

sub printResultLineWord { 
  # print line
  # $sTreffer is a word, nor part of a word
  my ($lineNr, $sTreffer, $line) = (shift,shift,shift);
  our %opt;
  my $line2 = $line;
  my $sTreffer2 = $sTreffer;
   # "." -> "\." etc
  $sTreffer2 =~ s/(\.|\?)/\\$1/g;
  $sTreffer2 =~ s/(\(|\)|\[|\]|\{|\})/\\$1/g;
  my $s;
  $line2 =~ s/\b$sTreffer2\b/<font color='red'><b>"$sTreffer"<\/b><\/font>/g;
  $s = "<tr><td>$sTreffer</td><td>\n$line2\n</td></tr>\n";
  print encode ($opt{encodingOutput},$s);
}
sub printResultLineWordCaseInsensitive { 
  # print line
  # $sTreffer is a word, not just part of a word
  my ($lineNr, $sTreffer, $line) = (shift,shift,shift);
  our %opt;
  my $line2 = $line;
  my $sTreffer2 = $sTreffer;
   # "." -> "\." etc
  $sTreffer2 =~ s/(\.|\?)/\\$1/g;
  $sTreffer2 =~ s/(\(|\)|\[|\]|\{|\})/\\$1/g;
  my $s;
  $line2 =~ s/\b$sTreffer2\b/<font color='red'><b>"$sTreffer"<\/b><\/font>/ig;
  $s = "<tr><td>$sTreffer</td><td>\n$line2\n</td></tr>\n";
  print encode ($opt{encodingOutput},$s);
}

sub printResultsHeader {
  # print header
  print "\n<table border=1>\n<tr><th>Error</th><th>Full Line</th></tr>\n"; # <th>Line</th>
  }
sub printResultsFooter {
  # print footer
  our %opt;
  print "</table>\n\n";
}

sub findDoppelteWoerter {
  # search: duplicated words
  my @cont = split "\n", shift;
  my $tStart = time();
  our %opt; my $info = ""; my $hits = 0;
  if ($opt{language} eq 'DE') {
  printTitle('Doppelte Wörter');
  $info = "Prüfen ob doppelte Wörter korrekt sind.";
  } else {
  printTitle('Duplicated Words');
  $info = "Check if duplicated words are correct.";
  }

  for (my $i=0;$i<=$#cont;$i++) {
    my $line = $cont [$i];
    my $lineNr = $i+1;

    # wort1 wort 1
    while ($line =~ m/(((?<!\\)\b[[:alpha:]]+)\s+\2\b)/ig) { # ignores \EA EA
      my $sTreffer = $1;
      $hits++; if ($hits == 1) {printResultsHeader}
      printResultLine($lineNr,$sTreffer,$line);
    } # while

    # wort1 wort2 wort1 wort2
    while ($line =~ m/(((\b[[:alpha:]]+)\s+([[:alpha:]]+)\b)\s+\2\b)/ig) {
      my $sTreffer = $1;
      $hits++; if ($hits == 1) {printResultsHeader}
      printResultLine($lineNr,$sTreffer,$line);
    } # while

    # wort1 wort2 wort3 wort1 wort2 wort3
    while ($line =~ m/(((\b[[:alpha:]]+)\s+([[:alpha:]]+)\s+([[:alpha:]]+)\b)\s+\2\b)/ig) {
      my $sTreffer = $1;
      $hits++; if ($hits == 1) {printResultsHeader}
      printResultLine($lineNr,$sTreffer,$line);
    } # while

    # wort1 wort2 wort3 wort4 wort1 wort2 wort3 wort4
    while ($line =~ m/(((\b[[:alpha:]]+)\s+([[:alpha:]]+)\s+([[:alpha:]]+)\s+([[:alpha:]]+)\b)\+s\2\b)/ig) {
      my $sTreffer = $1;
      $hits++; if ($hits == 1) {printResultsHeader}
      printResultLine($lineNr,$sTreffer,$line);
    } # while
  }# foreach line
  if ($hits) {
    printResultsFooter ;
    printInfo($info);
    $opt{hitsTotal}+=$hits;
  }
  print "$hits hit(s)\n";
  timing($tStart);
} # sub findDoppelteWoerter



sub findGleicherSatzanfang {
  # search: same start of sentence
  my @cont = split "\n\n", shift; # Trennen nach Absatz
  my $tStart = time();
  our %opt; my $info = ""; my $hits = 0;
  if ($opt{language} eq 'DE') {
  printTitle('Gleicher Satzanfang');
  $info =  "Sätze mit dem gleichen Wort eröffnen klingt eintönig.";
  } else {
  printTitle('Same First Word of Sentence');
  $info = "It is bad style to open sentences with the same word.";
  }
  @cont = map {s/\n/ /g;$_} @cont; # \n -> " "
  @cont = map {s/  +/ /g;$_} @cont; # remove double spaces
  for (my $i=0;$i<=$#cont;$i++) {
    my $line = $cont [$i];
    my $lineNr = $i+1;

    while ($line =~ m/((\. |^)([[:upper:]][[:alpha:]]+\b)[^\.]+\. \3\b(\s+[[:alpha:]]*))/g) { # [:alpha:]
      my $sTreffer = $3;
      $hits++; if ($hits == 1) {printResultsHeader}
      $sTreffer = "$sTreffer";
      printResultLine($lineNr,$sTreffer,$1);
    } # while
  }# foreach line
  if ($hits) {
    printResultsFooter ;
    printInfo($info);
    $opt{hitsTotal}+=$hits;
}
  print "$hits hit(s)\n";
  timing($tStart);
} # sub findDoppelteWoerter


sub findKleinNachPunkt{
  # search: small after punctuation
  my @cont = split "\n", shift;
  my $tStart = time();
  our %opt; my $info = ""; my $hits = 0;
  if ($opt{language} eq 'DE') {
  printTitle ('Kleinbuchstabe nach Punkt');
  $info =  "Ist es hier korrekt klein nach dem Punkt zu schreiben?";
  } else {
  printTitle ('Small Letters After Dot');
  $info = "Is the lower case letter correct after the '.'?";
  }
  for (my $i=0;$i<=$#cont;$i++) {
    my $line = $cont [$i];
    my $lineNr = $i+1;

    while ($line =~ m/(\b[[:alpha:]][[:alpha:]]+(\.|!|\?) [[:lower:]][[:alpha:]]+\b)/g) {
      my $sTreffer = $1;
      next if $sTreffer =~ m/(iapp\.de|dx\.doi|www\.iapp)/;
    my @l = qw(bzw. ca. cf. etc. vgl. no. m.E. m.a.W. u.U. s.u. z.B. al. lat. vs.); # ignore these
    $_ = join "|",@l;
    s/\./\\./g;
    next if $sTreffer =~ m/\b($_)/;

    $hits++; if ($hits == 1) {printResultsHeader}
    printResultLine($lineNr,$sTreffer,$line);

    } # while
  }# foreach line
  if ($hits) {
    printResultsFooter ;
    printInfo($info);
    $opt{hitsTotal}+=$hits;
  }
  print "$hits hit(s)\n";
  timing($tStart);
} # findKleinNachPunkt


sub findKommaZwZahlen{
  # search: comma between digits
  my @cont = split "\n", shift;
  my $tStart = time();
  our %opt; my $info = ""; my $hits = 0;
  if ($opt{language} eq 'DE') {
  printTitle ('Punkt zwischen Zahlen');
  $info =  "In Deutsch ',' statt '.' als Dezimaltrenner.";
  } else {
  printTitle ('Comma Between Digits');
  $info = "In English ',' is used as decimal separator.";
  }
  for (my $i=0;$i<=$#cont;$i++) {
    my $line = $cont [$i];
    my $lineNr = $i+1;
    
    if ($opt{language} eq 'EN') {
    while ($line =~ m/(\d+,\d+)/g) {
      my $sTreffer = $1;
      next if ($line =~ m/($sTreffer,|,$sTreffer)/); # ignore if an additional commer follows.
      next if ($line =~ m/($sTreffer\-)/);
      $hits++; if ($hits == 1) {printResultsHeader}
      printResultLine($lineNr,$sTreffer,$line);
    } # while
  } # if EN

    elsif ($opt{language} eq 'DE') {
    while ($line =~ m/(\d+\.\d+)/g) {
      my $sTreffer = $1;
      next if ($line =~ m/($sTreffer\.|\.$sTreffer)/); # ignore if an additional point follows.
#       next if ($line =~ m/($sTreffer\-)/); # ignore if an additional commer follows.
      $hits++; if ($hits == 1) {printResultsHeader}
      printResultLine($lineNr,$sTreffer,$line);
    } # while
  } # if DE
    
  }# foreach line
  if ($hits) {
    printResultsFooter ;
    printInfo($info);
    $opt{hitsTotal}+=$hits;
  }
  print "$hits hit(s)\n";
  timing($tStart);
}# findKommaZwZahlen


sub findLeerVorSatzzeichen{
  # search: spaces before start of sentence
  my $tStart = time();
  my @cont = split "\n", shift;
  our %opt; my $info = ""; my $hits = 0;
  if ($opt{language} eq 'DE') {
  printTitle ('Leerzeichen vor Satzzeichen');
  $info =  "Leerzeichen vor Satzzeichen hier korrekt?";
  } else {
  printTitle ('Space Before Punctuation Mark');
  }
  $info = "Space before punctuation correct here?";
  for (my $i=0;$i<=$#cont;$i++) {
    my $line = $cont [$i];
    my $lineNr = $i+1;
    while ($line =~ m/([[:alpha:]]+ (\.|\?|!))/g) {
      my $sTreffer = $1;
      $hits++; if ($hits == 1) {printResultsHeader}
      printResultLine($lineNr,$sTreffer,$line);
    } # while
  }# foreach line
  if ($hits) {
    printResultsFooter ;
    printInfo($info);
    $opt{hitsTotal}+=$hits;
  }
  print "$hits hit(s)\n";
  timing($tStart);
}# findLeerVorSatzzeichen


sub findLeerzeichen{
  # search: spaces
  my @cont = split "\n", shift;
  my $tStart = time();
  our %opt; my $info = ""; my $hits = 0;
  if ($opt{language} eq 'DE') {
  printTitle ('Mehrfache Leerzeichen');
  $info =  "Mehrfache überflüssige Leerzeichen, die in Word or LibreOffice zu unschönen Wortabständen führen würden.";
  } else {
  printTitle ('Multiple Spaces');
  $info = "Multiple spaces, that would be ugly in Word or LibreOffice.";
  }
  for (my $i=0;$i<=$#cont;$i++) {
    my $line = $cont [$i];
    my $lineNr = $i+1;

    while ($line =~ m/(\b  +\b)/g) {
      my $sTreffer = $1;
      $hits++; if ($hits == 1) {printResultsHeader}
      printResultLine($lineNr,$sTreffer,$line);
    } # while
  }# foreach line
  if ($hits) {
    printResultsFooter ;
    printInfo($info);
    $opt{hitsTotal}+=$hits;
  }
  print "$hits hit(s)\n";
  timing($tStart);
}# findLeerzeichen
  
  
sub findFehlendeKlammern{
  # search: mussing braces 
  my @cont = split "\n", shift;
  my $tStart = time();
  our %opt; my $info = ""; my $hits = 0;
  if ($opt{language} eq 'DE') {
  printTitle ('Ungeschlossene Klammern');
  $info =  "";
  } else {
  printTitle ('Unmatched Braces');
  $info = "";
  }
  for (my $i=0;$i<=$#cont;$i++) {
    my $line = $cont [$i];
    my $lineNr = $i+1;
    
    my @Klammernzaehler = (0,0,0); # (), [], {}

    while ($line =~ m/\(/g) { $Klammernzaehler[0] ++ ; }
    while ($line =~ m/\)/g) { $Klammernzaehler[0] -- ; }
    # Im Latex Mode werden [ und  { rausgelöscht, daher nur relevant für copy&paste...
    while ($line =~ m/\[/g) { $Klammernzaehler[1] ++ ; }
    while ($line =~ m/\]/g) { $Klammernzaehler[1] -- ; }
    while ($line =~ m/\{/g) { $Klammernzaehler[2] ++ ; }
    while ($line =~ m/\}/g) { $Klammernzaehler[2] -- ; }
    
    if ($Klammernzaehler[0] > 0 ) {
      my $sTreffer = '(';
      $hits++; if ($hits == 1) {printResultsHeader}
      printResultLine($lineNr,$sTreffer,$line);
    } elsif ($Klammernzaehler[0] < 0 ) {
      my $sTreffer = ')';
      $hits++; if ($hits == 1) {printResultsHeader}
      printResultLine($lineNr,$sTreffer,$line);
      }
    if ($Klammernzaehler[1] > 0 ) {
      my $sTreffer = '[';
      $hits++; if ($hits == 1) {printResultsHeader}
      printResultLine($lineNr,$sTreffer,$line);
    } elsif ($Klammernzaehler[1] < 0 ) {
      my $sTreffer = ']';
      $hits++; if ($hits == 1) {printResultsHeader}
      printResultLine($lineNr,$sTreffer,$line);
      }      
    if ($Klammernzaehler[2] > 0 ) {
      my $sTreffer = '{';
      $hits++; if ($hits == 1) {printResultsHeader}
      printResultLine($lineNr,$sTreffer,$line);
    } elsif ($Klammernzaehler[2] < 0 ) {
      my $sTreffer = '}';
      $hits++; if ($hits == 1) {printResultsHeader}
      printResultLine($lineNr,$sTreffer,$line);
      }      
  }# foreach line
  if ($hits) {
    printResultsFooter ;
    printInfo($info);
    $opt{hitsTotal}+=$hits;
  }
  print "$hits hit(s)\n";
  timing($tStart);
}# findFehlendeKlammern  


sub findWordsToAvoid{
  # search: words to avoid in technical reports
  my @cont = split "\n", shift;
  my $tStart = time();
  our %opt; my $info = ""; my $hits = 0;
  if ($opt{language} eq 'DE') {
  printTitle ('Vermeidbare Wörter');
  $info =  "Worte die man in wissenschaftlichen Arbeiten vermeiden sollte.";
  } else {
  printTitle ('Words to Avoid');
  $info = "Replace words like 'good, becomes, very, ...'. ";
  # RAUS, weil WT meinte ist nicht korrekt:
  # The phrase 'this is' misses a substive -> 'this finding/fact/... is'.
  }
  for (my $i=0;$i<=$#cont;$i++) {
    my $line = $cont [$i];
    my $lineNr = $i+1;
    my @l = ();
    if ($opt{language} eq 'EN') {
    @l=qw(
      becomes
      gets
      huge
      very
    );

    push @l, (
      'a bit' # somewhat
      ,'\. But'
      ,'fair agreement' # reasonable agreement
      ,'well agreement' # good agreement
      ,'low till' # low to
      ,'lowly doped'
      ,'low doped'
      ,'two times' # twice
     # ,'this is'
    );

    if ($opt{username} =~ m/torben/i) {
      push @l, "matrix"; # 'matrix' only for Torbens DDD!
      push @l, (
      '(is|are) (in|de)creasing' # increases & decreases
      ,'can be attributed' # is attributed
      ,'large conductivity' # high
      ,'air-volatile' # air-sensitive
      ,'In the case of' # ohne the
      ,'solar cell(|s)' # photovoltaic
      ,'weather' # whether
      );
      }

    } elsif ($opt{language} eq 'DE') {
    @l=qw(
    ich
    );
    }
    @l = map {decode('utf-8', $_)} @l;
    @l = sort @l;
    $s = join '|', @l;
    while ($line =~ m/\b($s)\b/ig) {
      my $sTreffer = $1;
      $hits++; if ($hits == 1) {printResultsHeader}
      # Alex verwendet gern "ich"
      next if ($opt{username} =~ m/alexw/i and $sTreffer =~ m/ich/g);
      printResultLineWord($lineNr,$sTreffer,$line);
    } # while
    # case sensitive stuff
    if ($opt{username} =~ m/torben/i) {
      while ($line =~ m/\b(IPs?|Analog|Opposite|x-ray)\b/g) { # IE, Analogously, Contrary, X-ray
        my $sTreffer = $1;
        $hits++; if ($hits == 1) {printResultsHeader}
        printResultLineWord($lineNr,$sTreffer,$line);
      } # while  }
#     if ($opt{language} eq 'DE') { # if DE and Torben
#       while ($line =~ m/\b(sie|ihr(|e|er|en|em))\b/g) { # IE, Analogously, Contrary, X-ray
#         my $sTreffer = $1;
#         $hits++; if ($hits == 1) {printResultsHeader}
#         printResultLineWord($lineNr,$sTreffer,$line);
#       } # while 
#       
#     } # if DE and Torben
    } # if torben check for IP -> IE
   } # foreach line
  if ($hits) {
    printResultsFooter ;
    printInfo($info);
    $opt{hitsTotal}+=$hits;
  }
  print "$hits hit(s)\n";
  timing($tStart);
}# findWordsToAvoid


sub findTorbensLieblingsfehler{
  # search: my favorite mistakes/typos
  my $cont = shift;
  my $tStart = time();
  my @cont = split "\n", $cont;
  our %opt; my $info = ""; my $hits = 0;
  my %apo; # apostroph
  if ($opt{language} eq 'DE') {
  printTitle ('Torben\'s Lieblingstippfehler');
  $info = "Worte die Torben gerne falsch schreibt, wie 'der selbe' das auseinander geschrieben wird.";
  } else {
  printTitle ('Torben\'s Favorite Mistakes');
   $info = "Some words I usually misspell, e.g. can not -> cannot, form -> from., effected -> affected, weather -> whether, molar -> molecular ...";
  }
    
  for (my $i=0;$i<=$#cont;$i++) {
    my $line = $cont [$i];
    my $lineNr = $i+1;
    my @l;
    # case-insensitive!!!
    if ($opt{language} eq 'EN') {
      @l = ();
      push @l, (
       'a the'
      ,'adept'
      ,'an be' #can
      ,'an are' #and are
      ,'ans'
      ,'ant'
      ,'all of the' #all the
      ,'archive?'
      ,'archive(d|s)'
      ,'at for'
      ,'agreement to ' #with
      ,'automatization' # automation
      ,'befor'
      ,'beside' # besides
      ,'bot' # but
      ,'can is'
      ,'can not' # cannot is better
      ,'change carrier'  # charge carrier
      ,'classical'
      ,'colleges?'
      ,'consistent to ' #with
      ,'contra-intuitive' # counter-intuitive
      ,'covalently bond(|ed)' # ABER covalent bond!!!
      ,'covert' # convert
      ,'cycles' # circles
      ,'date' #data
      ,'data is' # data are, sagt Leo
      ,'discusser' # discussed
      ,'diverting' # diverging
      ,'dopants molecules' #dopant molecules
      ,'effected'
      ,'election'# electron
      ,'fir' # for
      ,'form' # from
      ,'from in'
      ,'from to'
      ,'hight' # height      
      ,'greater extend' # extent
      ,'fullfill' # fulfill
      ,'furthermor' # furthermore
      ,'generel' #
      ,'highly dopes' # highly doped
      ,'I is'
      ,'I case'
      ,'in respect to' # with
      ,'in to'
      ,'informations' # information
      ,'is a interpreted'
      ,'is was' # it was
      ,'is can'
      ,'is choses' # chosen
      ,'lager' #larger
      ,'larger that' #than
      ,'larges'
      ,'lass' # less
      ,'lesser extend' # extent
      ,'let to' #led
      ,'liner' #linear
      ,'little affect' # effect
      ,'mate' # make
      ,'molar' # molar=Backenzahn -> molecular aber molar mass ist ok...
      ,'molar weight' # -> molar mass
      ,'mounded'
      ,'oder'
      ,'of was'
      ,'of can'
      ,'orientated' # oriented
      ,'p doping', 'p doped', 'n doping', 'n doped' # "-"
      ,'persons' #people
      ,'possible, that' # no comma
      ,'polymeres?'
      ,'quarz'
      ,'rage'
      ,'ration' #ratio
      ,'rind' # ring
      ,'rises the' #raises
      ,'seams?'
      ,'seems is'
      ,'semi conductor', 'semi conductors' # 1 word
      ,'spacial' # spatial
      ,'substracting' # subtracting
      ,'superlinar', 'superliner'# superlinear
      ,'systematical error' # systematic
      ,'temperature dependency'# T dependence!
      ,'that which'
      ,'the a'
      ,'the this'
      ,'the ones' # those
      ,'the these'
      ,'the affect' # the effect
      ,'therefor'
      ,'theses'
      ,'they was'
      ,'this data' # these data
      ,'tho'
      ,'to from'
      ,'to strong' # to -> too
      ,'to weak\w*'
      ,'to slow\w*'
      ,'trends'
      ,'turing'      
      ,'uppon'
      ,'ware'
      ,'was it' # as it
      ,'weather' # whether      
      # where -> were
      ,'where shown'
      ,'where derived'
      ,'where observed'
      ,'where used'
      ,'where removed'
      ,'wound' #  -> would
      ,'where introduced'
      )
      #foreach (@l) {push @l, $_."s");} # add word+"s"
    } elsif($opt{language} eq 'DE') {
      @l = ();
      push @l, (
       'der selbe' # zusammen
      ,'die selbe'
      ,'das selbe'
      ,'lieben' # liegen
      ,'mir'
      ,'Mirkofon'
      ,'quartz'
#       ,'sein' # seien RAUS!
      ,'sonder nicht'
      ,'uns' # und
      ,'wir mir' # wird mir
      ,'zurück führen'
      ,'zurück zu führen' # zurückzuführen
      );
    }
    @l = map {decode('utf-8', $_)} @l;
#     @l = sort @l;
    $s = join '|', @l;
    while ($line =~ m/\b($s)\b/ig) {
      my $sTreffer = $1;
      next if ($sTreffer =~ m/form/i and $line =~ m/(to|which|do not|another) form/i);
      next if ($sTreffer =~ m/molar/i and $line =~ m/molar (mass|masses|ratio)/i);
      next if ($sTreffer =~ m/trends/i and $line =~ m/(the|to|these) trends/i);
      next if ($sTreffer =~ m/to strong/i and $line =~ m/due to strong/i);
      next if ($opt{username} =~ m/alexw/i and $sTreffer =~ m/mir/g);

      $hits++; if ($hits == 1) {printResultsHeader}
      printResultLineWord($lineNr,$sTreffer,$line);
    } # while
    
    # case sensitive
    @l = ();
    if ($opt{language} eq 'EN') {
    push @l, (
       'This is a Placeholder'
      );      
    } elsif($opt{language} eq 'DE') {
    push @l, (
       '[Aa]m Besten'
      ,'[Zz]um Einen' , '[Zz]um Anderen' # einen anderen      
      );
    }
    
    @l = map {decode('utf-8', $_)} @l;
    $s = join '|', @l;
    while ($line =~ m/\b($s)\b/g) {
      my $sTreffer = $1;
      $hits++; if ($hits == 1) {printResultsHeader}
      printResultLineWord($lineNr,$sTreffer,$line);
    } # while: case sensitive
      
  #apostroph
  while ($line =~ m/\b('s|´s|`s)\b/gi) {
    $apo{"\L$1"} ++; # lower case
  }
    
    # this vs those
    if ($opt{language} eq 'EN') {  
    while ($line =~ m/\b(this +\w+s)\b/ig) {
      my $sTreffer = $1;
      next if ($line =~ m/this results in/i);
      next if ($sTreffer =~ m/this \w+ss\b/i);
      next if ($sTreffer =~ m/this is\b/i);
      next if ($sTreffer =~ m/this (agrees|allows|cancels|corresponds|enables|explains|hypothesis|leads|shows|suggests|thesis)/i);
      $hits++; if ($hits == 1) {printResultsHeader}
      printResultLineWord($lineNr,$sTreffer,$line);
    } # while
#     kein plan warum das nicht klappt wenn these mittem im satz steht :-(
#     while ($line =~ m/\b((those|these) \w+[^s])\b/ig) {
#       my $sTreffer = $1;
#       next if ($line =~ m/$sTreffer\s+\w+s/i); # das 3. Wort endet auf "s"
#       $hits++; if ($hits == 1) {printResultsHeader}
#       printResultLine($lineNr,$sTreffer,$line);
#     } # while
    } # if lang = EN
    
  }# foreach line
  
  # Apostrophs
  @_ = keys (%apo);
  if ($#_ > 0 or $apo{"`s"}>0) {
  $apo{"'s"} += 0;$apo{"´s"} += 0;$apo{"`s"} += 0;
  print "<p>Different Apostroph's used:<br>\n";
  print "'s : ".$apo{"'s"}." (preferred)<br>\n";
  print "´s : ".$apo{"´s"}." (ok)<br>\n";
  print "`s : ".$apo{"`s"}." (incorrect)</p>\n";
  $hits += $apo{"`s"};
  }
    
  if ($hits) {
    printResultsFooter ;
    printInfo($info);
    $opt{hitsTotal}+=$hits;
  }  
  print "$hits hit(s)\n";
  timing($tStart);

}# findTorbensLieblingsfehler


sub findLatexProbs{
  # search: LaTeX stuff
  my @cont = split "\n", shift;
  my $tStart = time();
  our %opt; my $info = ""; my $hits = 0;
  if ($opt{language} eq 'DE') {
  printTitle ('Latex Unsauberkeiten');
  $info = "Einheiten nicht kursiv und mit '\\,' als Abstand zur Zahl (Empfehlung: Paket siunitx). Wörter/Kürzel in Subscripten nicht kursiv: E_{act} -> E_\\text{act}. Eine Übersicht über veraltete Pakete gibt <a href='ftp://ftp.rrzn.uni-hannover.de/pub/mirror/tex-archive/info/l2tabu/german/l2tabu.pdf'>l2tabu.pdf</a>.";
  } else {
  printTitle ('Latex Stuff');
  $info = "Units not in italics and with '\\,' as space to number (best use package siunitx). Words in subscripts not in italics: E_{act} -> E_\\text{act}. For obsolete packages see <a href='ftp://ftp.rrzn.uni-hannover.de/pub/mirror/tex-archive/info/l2tabu/english/l2tabuen.pdf'>l2tabu.pdf</a>.";
  }
  for (my $i=0;$i<=$#cont;$i++) {
    my $line = $cont [$i];
    my $lineNr = $i+1;

    # E_{act}
    while ($line =~ m/(_\{[a-z][a-z]+\}?)/g) {
      my $sTreffer = $1;
      $hits++; if ($hits == 1) {printResultsHeader}
      printResultLine($lineNr,$sTreffer,$line);
    }
    # Einheiten $3 mm$ ->$3$\,mm
    while ($line =~ m/(\d ?(nm|mm|cm|m|eV|meV|W|mW|kW|J|kJ)\$)/g) {
      my $sTreffer = $2;
      $hits++; if ($hits == 1) {printResultsHeader}
      printResultLine($lineNr,$sTreffer,$line);
    }
    # Umgebungen
    while ($line =~ m/(\\begin\{(eqnarray|appendix)\})/g) {
      my $sTreffer = $1;
      $hits++; if ($hits == 1) {printResultsHeader}
      printResultLine($lineNr,$sTreffer,$line);
    }
    # $$ a = b $$
    while ($line =~ m/(\$\$)/g) {
      my $sTreffer = $1;
      $hits++; if ($hits == 1) {printResultsHeader}
      printResultLine($lineNr,$sTreffer,$line);
    }
    # Befehle
    while ($line =~ m/(\\(centerline|over|bf|it|rm|sc|sf|sl|tt)\b)/g) {
      my $sTreffer = $1;
      $hits++; if ($hits == 1) {printResultsHeader}
      printResultLine($lineNr,$sTreffer,$line);
    }
    # scrlettr -> scrlttr2 , SIunits -> siunitx
    while ($line =~ m/(\{scrlettr|SIunits\})/g) {
      my $sTreffer = $1;
      $hits++; if ($hits == 1) {printResultsHeader}
      printResultLine($lineNr,$sTreffer,$line);
    }
    # Packages
    while ($line =~ m/(\\usepackage.*\{(psfig|doublespace|fancyheadings|scrpage|isolatin1|umlaut|t1enc|subfig|times|mathptm|pslatex|palatino|mathpple|utopia|pifont|euler|ae|zefonts)\})/g) {
      my $sTreffer = $1;
      $hits++; if ($hits == 1) {printResultsHeader}
      printResultLine($lineNr,$sTreffer,$line);
    }
    # Bib: dinat -> natdin
    while ($line =~ m/(\\bibliographystyle\{dinat\})/g) {
      my $sTreffer = $1;
      $hits++; if ($hits == 1) {printResultsHeader}
      printResultLine($lineNr,$sTreffer,$line);
    }
  }# foreach line
  if ($hits) {
    printResultsFooter ;
    printInfo($info);
    $opt{hitsTotal}+=$hits;
  }
  print "$hits hit(s)\n";
  timing($tStart);
}# findLatexProbs


sub findPunctuation{
  # search: comma after certain words
  my @cont = split "\n", shift;
  my $tStart = time();
  our %opt; my $info = ""; my $hits = 0;
  if ($opt{language} eq 'DE') {
  printTitle ('Zeichensetzung');
  $info =  "";
  } else {
  printTitle ('Punctuation');
  $info = "Comma after words like 'Hence, Therefore, Thus' if they are opening the sentence.";
  }
  for (my $i=0;$i<=$#cont;$i++) {
    my $line = $cont [$i];
    my $lineNr = $i+1;
    my @after;
    my @before;
    my @notBefore;
    if ($opt{language} eq 'EN') {
      @after = qw(
      Accordingly
      Additionally
      Afterwards
      Analogously
      Consequently
      Contrary
      First
      Finally
      Further
      Furthermore
      Hence
      Interestingly
      Overall
      Phenomenologically
      Recently
      Surprisingly
      Therefore
      Thus
      Therby
      Usually
      );
      push @after,(
      'In the following'
      ,'In this (thesis|work)'
      ,'(P|p)rior to further (measurements|investigations)'
      ,'After the measurements'
      ,'In general'
      ,'In Xref' # figref\{.*?\}
      );

      @notBefore = qw (that);
    } elsif($opt{language} eq 'DE') {
      @after = ();
    }
    @after  = map {decode('utf-8', $_)} @after;  @after  = sort @after ;
    @before = map {decode('utf-8', $_)} @before; @before = sort @before;
    if (@after) {
      my $s = join '|', @after;
      while ($line =~ m/(\b($s) )/g) { # case sensitive
        my $sTreffer = $1;
        next if ($sTreffer =~ m/First/i and $line =~ m/First (attempts)/i);
        next if ($sTreffer =~ m/Analogously/i and $line =~ m/Analogously (to)/i);
        next if ($sTreffer =~ m/Contrary/i and $line =~ m/Contrary (to)/i);
        next if ($sTreffer =~ m/In the following/i and $line =~ m/In the following (section|chapter)s?/i);
        $hits++; if ($hits == 1) {printResultsHeader}
        printResultLine($lineNr,$sTreffer,$line);
      } # while
      while ($line =~ m/(\b(In (this|the following|the next|the previous) (chapter|section|thesis)s?) )/g) { # case sensitive
        my $sTreffer = $1;
        next if ($sTreffer =~ m/First/i and $line =~ m/First (attempts)/i);
        $hits++; if ($hits == 1) {printResultsHeader}
        printResultLine($lineNr,$sTreffer,$line);
      } # while

    } # if (@after)
    if (@before) {
      my $s = join '|', @before;
      while ($line =~ m/( ($s)\b)/g) { # case sensitive
        my $sTreffer = $1;
        $hits++; if ($hits == 1) {printResultsHeader}
        printResultLine($lineNr,$sTreffer,$line);
      } # while
    } #if (@before)
    if (@notBefore) {
      my $s = join '|', @notBefore;
      while ($line =~ m/(,\s+($s)\b)/g) { # case sensitive
        my $sTreffer = $1;
        $hits++; if ($hits == 1) {printResultsHeader}
        printResultLine($lineNr,$sTreffer,$line);
      } # while
    } #if (@notBefore)

    if ($opt{language} eq 'EN') {
  # no komma here
  while ($line =~ m/(,\s+((for|in) (devices|samples), where))/ig) { # case insensitive
      my $sTreffer = $1;
      $hits++; if ($hits == 1) {printResultsHeader}
      printResultLine($lineNr,$sTreffer,$line);
    } # while
  } 
  #elsif ($opt{language} eq 'DE') {   }

    # suche nach .. ,, ., sowie ". ." etc
    while ($line =~ m/(^|[^\.])([\.,!]\s*[\.,!])([^\.]|$)/ig) { # case insensitive
      my $sTreffer = $2;
      next if $line =~ m/ et al$sTreffer/; # Schneider et al., 2002
      next if $line =~ m/ i\.e\.,/; # "i.e.,"
      $hits++; if ($hits == 1) {printResultsHeader}
      printResultLine($lineNr,$sTreffer,$line);
    } # while

    # EN+DE
    # suche nach et. al -> et al.
    while ($line =~ m/(\bet\.\s*al\b)/g) { # case sensitive
      my $sTreffer = $1;
      $hits++; if ($hits == 1) {printResultsHeader}
      printResultLine($lineNr,$sTreffer,$line);
    } # while
  
    
  # e.g -> e.g. etc
  my @l = ();
  push @l, (
   'ca'  # ca.
  ,'etc' # etc.
  ,'vs'  # vs.
  );
  
  my $s = '';
  if ($opt{language} eq 'EN') {
  push @l, (
   'e ?g|e\. +g|e ?g\.'# e.g.
  ,'i ?e|i\. +e|i ?e\.' #i.e.
  );
  } elsif ($opt{language} eq 'DE') {
  push @l, (
   'bzw'
  ,'vgl'
  ,'z ?B|z\. ?B|z ?B\.' # z.B.
  ,'s ?u|s\. ?u|s ?u\.' # s.u.
  ,'u ?U|u\. ?U|u ?U\.' # u.U.
  ,'m ?E|m\. ?E|m ?E\.' # m.E.
  );
  }
  $s = join '|', @l;
  while ($line =~ m/ ($s) /g) { # case sensitive
    my $sTreffer = $1;
    $hits++; if ($hits == 1) {printResultsHeader}
    printResultLine($lineNr,$sTreffer,$line);
  } # while

  }# foreach line
  if ($hits) {
    printResultsFooter ;
    printInfo($info);
    $opt{hitsTotal}+=$hits;
  }
  print "$hits hit(s)\n";
  timing($tStart);
} #findPunctuation


sub findBindestrich{
  # search: hyphens
  my $cont2 = shift;
  my $tStart = time();
  my $cont = "\L$cont2"; # Lower case und sicherstellen, dass das original nicht verändert wird
  $cont =~ s/[\n\r\s]+/ /sg; # remove linebreaks etc
  our %opt; my $info = ""; my $hits = 0;
  if ($opt{language} eq 'DE') {
  printTitle ('Bindestriche');
  $info =  "'Hoch-Zeit' vs. 'Hoch Zeit' vs. 'Hochzeit'";
  } else {
  printTitle ('Hyphens');
  $info = "'temperature-independant' vs. 'temperature independant' vs. 'temperatureindependant'";
  }
  my %BindestrichWoerter;
  my %BindestrichFehler;
  if ($opt{language} eq 'EN') {
    @_ = qw(
      air-exposure
      air-stable
      air-instable
      air-volatile
      current-voltage
      device-relevant
      field-effect
      body-centered
      face-centered
      inter-molecular
      intra-molecular
      light-emitting
      long-term
      semi-logarithmic      
    ); # temperature-dependent
    foreach $_ (@_) {
      $BindestrichWoerter{$_} ++;
      }
    }
  while ($cont =~ m/([[:alpha:]]+)\-([[:alpha:]]+)/gi) {
    my ($w1,$w2) = ($1,$2);
    next if (length("$w1-$w2")<=3);
    next if ($opt{language} eq 'DE' and $w2 eq "und");
    next if ($opt{language} eq 'EN' and $w2 eq "and");
    $BindestrichWoerter{"$w1-$w2"} ++;
    }
# print join "\n<br>",keys (%BindestrichWoerter);
my %BindestrichWoerterOhne;
my %BindestrichWoerterZusammen;

# my $t1 = time();
foreach my $wMit (keys (%BindestrichWoerter)){
  my $wOhne = $wMit;
  $wOhne =~ s/\-/ /;
  $BindestrichWoerterOhne{$wOhne} = 0; # initialize value
  my $wZ = $wMit;
  $wZ =~ s/\-//;
  $BindestrichWoerterZusammen{$wZ} = 0; # initialize value
  }

# nur 1x gleichzeitig mit vielen Suchbegriffen durch den Inhalt schleifen ist viel schneller als pro Wort 3x schleifen!!!
$_ = join '|', keys (%BindestrichWoerterOhne);
  while ($cont =~ m/\b($_)\b/gi) {
    $BindestrichWoerterOhne{$1} ++;
#     $BindestrichFehler{$wMit}++;
  }
$_ = join '|', keys (%BindestrichWoerterZusammen);
  while ($cont =~ m/\b($_)\b/gi) {
    $BindestrichWoerterZusammen{$1} ++;
#     $BindestrichFehler{$wMit}++;
  }

foreach my $wMit (keys (%BindestrichWoerter)){
  my $wOhne = $wMit;
  $wOhne =~ s/\-/ /;
  my $wZ = $wMit;
  $wZ =~ s/\-//;
  $BindestrichFehler{$wMit}++ if ($BindestrichWoerterOhne{$wOhne} > 0);
  $BindestrichFehler{$wMit}++ if ($BindestrichWoerterZusammen{$wZ} > 0);
  }

# foreach my $wMit (keys (%BindestrichWoerter)) {
#   my $wOhne = $wMit;
#   $wOhne =~ s/\-/ /;
#   my $wZ = $wMit;
#   $wZ =~ s/\-//;
#   while ($cont =~ m/\b$wOhne\b/gi) {
#     $BindestrichWoerterOhne{$wOhne} ++;
#     $BindestrichFehler{$wMit}++;
#   }
#   while ($cont =~ m/\b$wZ\b/gi) {
#     $BindestrichWoerterZusammen{$wZ} ++;
#     $BindestrichFehler{$wMit}++;
#   }
#   @_ = keys (%BindestrichFehler);
#   $hits = $#_ + 1;
# }
# print "<p> Zwischenzeit: ",sprintf("%.3f",time()-$t1), "</p>\n";


foreach my $wMit (keys %BindestrichFehler) {
  my $wOhne = $wMit;
  my $wZ = $wMit;
  $wOhne =~ s/\-/ /;
  $wZ =~ s/\-//;
  print "$wMit = <font color='red'><b>$BindestrichWoerter{$wMit}x</b></font>";
  print " ; $wOhne = <font color='red'><b>$BindestrichWoerterOhne{$wOhne}x</b></font>" if $BindestrichWoerterOhne{$wOhne};
  print " ; $wZ = <font color='red'><b>$BindestrichWoerterZusammen{$wZ}x</b></font>" if $BindestrichWoerterZusammen{$wZ};
  print "<br>\n";
  }
@_ = keys (%BindestrichFehler);
$hits = 1 + $#_; @_ = ();
# printInfo($info);
  $opt{hitsTotal}+=$hits;
  print "$hits hit(s)\n";
  timing($tStart);
  # dauer sehr lange, 40-60% der gesamtzeit :-(
} #findBindestrich


sub findAvsAn{
  # search: A vs An
  my @cont = split "\n", shift;
  my $tStart = time();
  our %opt; my $info = ""; my $hits = 0;
  if ($opt{language} eq 'DE') {
    return;
    # $info =  "";
  } else {
    printTitle ('A vs An');
    $info = "right: 'a house', 'an example'<br>wrong: 'an european', 'an UHV', 'a LED'\n";
  }
  for (my $i=0;$i<=$#cont;$i++) {
    my $line = $cont [$i];
    my $lineNr = $i+1;
    my @after;
    my @before;
    # an XYZ
    my $ausnahmen = 'uniform|univer|unique\b|unity|useful\b|UHV\b|UV\b|euro';
    while ($line =~ m/((^| )a ([aeiou]\w+|hour|led\b))/ig) {
      my $sTreffer = $1;
      # a unique is correct
      next if ($sTreffer =~ m/a (one\b|)/i);
      $hits++; if ($hits == 1) {printResultsHeader}
      printResultLine($lineNr,$sTreffer,$line);
    } # while
    # a XYZ
    while ($line =~ m/((^| )an ([bcdfghjklmnpqrstvwxyz]\w+|$ausnahmen))/ig) {
      my $sTreffer = $1;
      # an hour is correct
      next if ($sTreffer =~ m/an (hour|led\b)/i);
      $hits++; if ($hits == 1) {printResultsHeader}
      printResultLine($lineNr,$sTreffer,$line);
    } # while
  }# foreach line
  if ($hits) {
    printResultsFooter ;
    printInfo($info);
    $opt{hitsTotal}+=$hits;
  }
  print "$hits hit(s)\n";
  timing($tStart);
} #findPunctuation



sub findWortwiederholungen{
  # search: word repetitions
  my $cont = shift;
  my $tStart = time();
#   my @cont = split "\n", $cont;
  our %opt; my $info = ""; my $hits = 0;

  my $maxAbstand = 10; # woerter
  
  if ($opt{language} eq 'DE') {
    printTitle ('Wortwiederholungen');
    $info =  "Wiederholung eines Wortes mit <$maxAbstand Wörter dazwischen.";    
  } else {
    printTitle ('Word Repitition');
    $info = "Word repeated with less than $maxAbstand words in between.";
  }   
  
  $cont =~ s/\s\$.*?\$\s/ /sg; # Latex Math raus
  $cont =~ s/\\\w*/ /g; # Latex Befehle
  
  $cont =~ s/[\d]+/ /g; # Zahlen raus
  $cont =~ s/[^\w]+/ /g; # alle nicht-Wortzeichen raus
  $cont =~ s/\r/ /g;
  $cont =~ s/\n/ /g;
  $cont =~ s/\s+/ /sg;
  $cont =~ s/^ +//;
  $cont =~ s/ +$//;
  my @woerter = split / /, $cont;
  my @egal = ();
  if ($opt{language} eq 'DE') {
    @egal = qw(
      auf
      und
      bei mit
      der die das dass des den dem
      ein eine einen einem einer
      in im
      ist
      von
      xref
      );
  } else {
    @egal = qw (
      are
      one two three four
      and
      for
      the
      xref
      );
  }

  my %wortwiederholungsranking;
  
  while (my $wort = lc(shift (@woerter))) {
    if (length($wort)<=5) {
#       print "$wort zu kurz<br>";
      next;      
      }
    if (grep( /^$wort$/i, @egal ) ) {
#       print "$wort in egal<br>";
      next;
      }
#     print "$wort ";
    my @woerterTemp = @woerter[0..$maxAbstand];
    my $next;
    my $i = 1;
    while ($i <= $maxAbstand and $next = lc(shift @woerterTemp)) {
#       if ($i>10 and grep( /^$wort$/, @egal2 ) ) {
#         next;
#       }
      if ($wort eq $next) {
#        print "$wort = $next i=$i<br>";
        $hits++; if ($hits == 1) {printResultsHeader};
        @_ = @woerter[0..$i];
        $_ = "d=$i $wort ".join (" ", @_);
        printResultLineWordCaseInsensitive(0,$wort,$_);
        $wortwiederholungsranking{$wort}++;
      }
    $i++;
    }
  }
  
  
  if ($hits) {
    printResultsFooter ;
    printInfo($info);
#     nicht dazu zählen
#     $opt{hitsTotal}+=$hits;
  }

  if ($opt{timing} == 1) { # print ranking of repeated words only when in debug mode
  print "Ranking<br\n>";
  foreach my $key (sort {$wortwiederholungsranking{$b} <=> $wortwiederholungsranking{$a}} keys %wortwiederholungsranking) {
    my $value = $wortwiederholungsranking{$key};
    next if ($value<=2);
    $_ = "$key ($value)<br>";
    $_ = encode ($opt{encodingOutput}, $_);
    print $_;
    }
  }

  print "$hits hit(s)\n";
  timing($tStart);
} # findWortwiederholungen


sub ZaehleSatzWortSilbe {
  # search: count worts, silibles, etc
  my $tStart = time();
  our %opt;
  use Cwd;
  # TODO Wickie:
  use lib getcwd().'/libs/'; #use lib $ENV{HOME}.'/bin/';
  use Lingua::EN::Syllable; # count silben

  my $cont = shift;
  my $size = length($cont);
  my $pages;
  my $fre = '---';

  $cont = "\L$cont"; # Lowercase
  $cont .= '.'; # ensure final "."
  $cont =~ s/[\n\r]+/ /sg; # remove linebreaks
  $cont =~ s/(~|\\quad|\\approx)/ /g; # spacings
  $cont =~ s/\\/ /g; # latex commands -> "words"
  $cont =~ s/\$//g; # latex $ -> ''
  # umlaute ersetzen, damit silbenfindung besser funktioniert
  $_ = decode('utf-8', 'ä'); $cont =~ s/$_/a/g;
  $_ = decode('utf-8', 'ö'); $cont =~ s/$_/o/g;
  $_ = decode('utf-8', 'ü'); $cont =~ s/$_/u/g;
  $_ = decode('utf-8', 'ß'); $cont =~ s/$_/ss/g;
  $_ = decode('utf-8', 'Ä'); $cont =~ s/$_/A/g;
  $_ = decode('utf-8', 'Ö'); $cont =~ s/$_/O/g;
  $_ = decode('utf-8', 'Ü'); $cont =~ s/$_/U/g;
  $_ = decode('utf-8', 'Å'); $cont =~ s/$_/A/g;
  $_ = decode('utf-8', 'é'); $cont =~ s/$_/e/g;
  $_ = decode('utf-8', 'è'); $cont =~ s/$_/e/g;
  $_ = decode('utf-8', 'ž'); $cont =~ s/$_/z/g;
  $_ = decode('utf-8', 'â'); $cont =~ s/$_/a/g;
  $_ = decode('utf-8', 'Â'); $cont =~ s/$_/A/g;
  $_ = decode('utf-8', 'ç'); $cont =~ s/$_/c/g;

  $cont =~ s/(\w+)\d+(\w+)/$1$3/g; # P3HT -> PHT
  # remove all numbers and units: \d\w or \w\d -> ''
  $cont =~ s/\d+[\.,]\d+//g;
  $cont =~ s/(\w+)\d+//g;
  $cont =~ s/\d+(\w+)//g;

  $cont =~ s/'s /is /g; # that's -> that is
  $cont =~ s/\b[^Ia]\b/ /g; # remove 1-char words # do care about word "I", "a" ;-)
  $cont =~ s/[!\?]/./g; # only "." as sentence end

  $cont =~ s/[^a-z\.]+/ /gi; # remove all non-word chars besides "."


  $cont =~ s/  +/ /g; # spaces
  $cont =~ s/(^ +| $)//g; # spaces at end.
  $cont =~ s/\. +/./g; # spaces after "."
  $cont =~ s/ +\././g; # spaces before "."
  $cont =~ s/\.\.+/./g; # ... -> .
  my @l = split /[\.]/, $cont;

#  print join "<br>\n", @l;
  my $numSentences = 0; # overwrite, as some are skipped
  my $numWords = 0;
  my $numWordChars = 0;
  my $numSyllables = 0;
  my $numThe=0;
  foreach my $s (@l) {
    my @w = split / /, $s;
    next if ($#w < 2); # min 3 words
    $numSentences ++;
    $numWords += (1 + $#w);
    if ($opt{language} eq 'EN') {
      if ($w[0] =~ m/the/) {
        $numThe++;}}
    elsif ($opt{language} eq 'DE') {
      if ($w[0] =~ m/(der|die|das|den)/) {
        $numThe++;}}
    foreach my $w (@w) {
      $numWordChars += length ($w);
      $numSyllables += syllable($w);
    }
  }
  $numSentences = 1 if $numSentences == 0;
  $opt{'numWords'} = $numWords;
  $opt{'percentThe'} = sprintf ("%.1f", 100*$numThe/$numSentences);
  $pages = sprintf("%.1f",$size / (80*45));
  my $lengthInMeter = sprintf("%.1f",$size / (80) * 0.15); # 80 chars/line, 15cm per line
  my $proofReadingDuration = sprintf "%d", ($size * (54.5/25000)); # gestoppt in Diss, Rechnungskapitel
  my $sizeOfBible = ($opt{language} eq 'EN' ? 4962938 : 4276280);
#   without vers numbers (with vers numbers)
#   DE 4023855 (4314168) Luther 1545
#   DE 4276280 (4566597) Schlachter 1951
#   EN 4962938 (5592150) King James
  my $percentOfBible = sprintf "%.3f",(100*$size/$sizeOfBible);
  print "<p>
$size         bytes<br>
$pages        full text pages <small>(\@80 chars/line, 45 lines = 3600 chars/page)</small><br>
$percentOfBible % of the holy bible<br>
$lengthInMeter meter text <small>(\@80 chars/line, 15cm/line)</small><br>
$proofReadingDuration minutes estimated proof reading time<br>
$numSentences sentences<br>
$opt{'percentThe'} % of sentences starting with '".($opt{language} eq 'EN' ? "The" : "Der, Die, Das, Den")."'<br>
$numWords     words<br>
$numSyllables syllables (estimated)<br>
$numWordChars word chars<br>
\n";

if ($numSentences >2 and $numWords > 2) {
  my $avWordsPerSentence = $numWords / $numSentences; # Average Sentence Length
  my $avSyllables = $numSyllables / $numWords; # Average Number of Syllables per Word
  my $avCharsPerWord = $numWordChars / $numWords; # Average Sentence Length
  printf ("%.1f words per sentence<br>\n",$avWordsPerSentence);
  printf ("%.1f syllables per word<br>\n",$avSyllables);
  printf ("%.1f chars per word<br>\n",$avCharsPerWord);

  print "Readability: Flesch Reading Ease=";
  if ($opt{language} eq 'EN') {
    $fre = 206.835 - (1.015 * $avWordsPerSentence) - (84.6 * $avSyllables) ;
    print "<a target='blank' href='http://en.wikipedia.org/wiki/Flesch-Kincaid_readability_test#Flesch_Reading_Ease'>";
    printf ("%.1f",$fre);
    print "</a>";
  }
  elsif ($opt{language} eq 'DE') {
    $fre = 180 - $avWordsPerSentence - (58.5 * $avSyllables);
    print "<a target='blank' href='http://de.wikipedia.org/wiki/Lesbarkeitsindex#Flesch_Reading_Ease'>";
    printf ("%.1f",$fre);
    print "</a> <small>(higher means easier)</small>\n";
  }
}
print "</p\n>";
$opt{fre}=sprintf("%.1f",$fre);
$opt{pages}=$pages;
timing($tStart,'ZaehleSatzWortSilbe');
# dauer sehr lange, 20-30% der gesamtzeit :-(
} # ZaehleSatzWortSilbe
#  $cont =~ s/[^[:alpha:]]+/ /g; # remove all non-word chars



sub countPhrases {
  # count phrases
  my $cont = shift;
  my $tStart = time();
  our %opt;

  my @saetze = split m/(?<=\w)[\.\?!]\s/,$cont; # (?<=text) = lookback
  my %zweiWortPhrasen;
  my %dreiWortPhrasen;
  foreach my $satz (@saetze) {
    $satz =~ s/[^[:alpha:]]+/ /g; # remove all non-word chars
    $satz =~ s/(^\s+|\s+$)//sg; # remove spaces at start and end of sentence
    my @woerter = split m/ +/, $satz;
    next if ($#woerter<1);
    for (my $i=0;$i<=$#woerter-1;$i=$i+2) {
      next if ($woerter[$i] eq 'the');
      next if (length $woerter[$i]   < 2); # words at least 2 char long
      next if (length $woerter[$i+1] < 2); # words at least 2 char long
      $_ =  "$woerter[$i] $woerter[$i+1]";
      $zweiWortPhrasen{$_}++;
    }
    shift @woerter; # remove first
    # nochmal
    next if ($#woerter<1);
    for (my $i=0;$i<=$#woerter-1;$i=$i+2) {
      next if ($woerter[$i] eq 'the');
      next if (length $woerter[$i]   < 2); # words at least 2 char long
      next if (length $woerter[$i+1] < 2); # words at least 2 char long
      $_ =  "$woerter[$i] $woerter[$i+1]";
      $zweiWortPhrasen{$_}++;
    }

    # 3 Wort Phrasen
    @woerter = split m/ +/, $satz;
    next if ($#woerter<2);
    for (my $i=0;$i<=$#woerter-2;$i=$i+3) {
      next if (length $woerter[$i]   < 2); # words at least 2 char long
      next if (length $woerter[$i+1] < 2); # words at least 2 char long
      next if (length $woerter[$i+2] < 2); # words at least 2 char long
      $_ =  "$woerter[$i] $woerter[$i+1] $woerter[$i+2]";
      $dreiWortPhrasen{$_}++;
    }
    shift @woerter; # remove first
    # nochmal
    next if ($#woerter<2);
    for (my $i=0;$i<=$#woerter-2;$i=$i+3) {
      next if (length $woerter[$i]   < 2); # words at least 2 char long
      next if (length $woerter[$i+1] < 2); # words at least 2 char long
      next if (length $woerter[$i+2] < 2); # words at least 2 char long
      $_ =  "$woerter[$i] $woerter[$i+1] $woerter[$i+2]";
      $dreiWortPhrasen{$_}++;
    }
    shift @woerter; # remove first
    # nochmal
    next if ($#woerter<2);
    for (my $i=0;$i<=$#woerter-2;$i=$i+3) {
      next if (length $woerter[$i]   < 2); # words at least 2 char long
      next if (length $woerter[$i+1] < 2); # words at least 2 char long
      next if (length $woerter[$i+2] < 2); # words at least 2 char long
      $_ =  "$woerter[$i] $woerter[$i+1] $woerter[$i+2]";
      $dreiWortPhrasen{$_}++;
    }
  }
  # remove some common 2 word phrases
  if ($opt{language} eq 'DE') {
  @_ = (
     'als bei'
    ,'als die'
    ,'an der'
    ,'an die'
    ,'auf dem'
    ,'auf den'
    ,'auf der'
    ,'auf die'
    ,'aus den'
    ,'aus der'
    ,'bei den'
    ,'bei der'
    ,'bis zu'
    ,'da die'
    ,'dass die'
    ,'der in'
    ,'die in'
    ,'es ist'
    ,'für den'
    ,'für den'
    ,'für die'
    ,'für die'
    ,'für eine'
    ,'für eine'
    ,'in dem'
    ,'in den'
    ,'in der'
    ,'ist das'
    ,'ist die'
    ,'ist es'
    ,'ist in'
    ,'mit dem'
    ,'mit der'
    ,'mit einer'
    ,'sind die'
    ,'und dem'
    ,'und der'
    ,'und die'
    ,'von bis'
    ,'von dem'
    ,'von den'
    ,'von der'
    ,'vor dem'
    ,'wird die'
    ,'zu den'

    );
  } else {
  @_ = (
     'and the'
    ,'as the'
    ,'at the'
    ,'by the'
    ,'for the'
    ,'in the'
    ,'is the'
    ,'it is'
    ,'of the'
    ,'of is'
    ,'on the'
    ,'to a'
    ,'to an'
    ,'to be'
    ,'to the'
    ,'with the'
    ,'has been'
    );
  }
  (delete $zweiWortPhrasen{decode ('utf-8',$_)}) foreach (@_);

  # remove phrases that occur only 2x =(2ms for 2000 Words)
  foreach (keys(%zweiWortPhrasen)) {
    (delete $zweiWortPhrasen{$_}) if ($zweiWortPhrasen{$_} <= 2);
  }
  foreach (keys(%dreiWortPhrasen)) {
    (delete $dreiWortPhrasen{$_}) if ($dreiWortPhrasen{$_} <= 2);
  }


  my @top100Phrasen2;
  foreach my $phrase (sort {$zweiWortPhrasen{$b} <=> $zweiWortPhrasen{$a}} keys %zweiWortPhrasen) {
    $_ = "$phrase ($zweiWortPhrasen{$phrase})<br>";
    push @top100Phrasen2, $_."\n" if ($zweiWortPhrasen{$phrase});
    last if (@top100Phrasen2 == 99);
  } # 1.7s for 2000 words

  my @top100Phrasen3;
  foreach my $phrase (sort {$dreiWortPhrasen{$b} <=> $dreiWortPhrasen{$a}} keys %dreiWortPhrasen) {
    $_ = "$phrase ($dreiWortPhrasen{$phrase})<br>";
    push @top100Phrasen3, $_."\n" if ($dreiWortPhrasen{$phrase});
    last if (@top100Phrasen3 == 99);
  }
  @saetze = undef;
  %zweiWortPhrasen = undef;
  %dreiWortPhrasen = undef;

  $opt{'2WPhrasen'} = '';
  $opt{'3WPhrasen'} = '';
  while (my $s = shift @top100Phrasen3) {
    $s = encode ($opt{encodingOutput}, $s);
    $opt{'3WPhrasen'} .= "$s";
  }

  while (my $s = shift @top100Phrasen2) {
   $s = encode ($opt{encodingOutput}, $s);
   $opt{'2WPhrasen'} .= "$s";
  }
  timing($tStart,'countPhrases');
  } # countPhrases


sub statistics {
  # print stats
  my $cont = shift;
  our %opt;
  printTitle ('Stats');

  ZaehleSatzWortSilbe ($cont);

  $cont = "\L$cont"; # lower case
  $cont =~ s/\\\w+/ /g; # remove latex commands
  $cont =~ s/\b\d+(|\.\d+)\b/ /g; # remove numbers
  $cont =~ s/[\n\r]+/ /sg; # remove linebreaks
  $cont =~ s/\s+/ /sg; # remove multiple spaces
  $cont =~ s/([\.\?!])\s+/$1 /sg; # remove multiple spaces after punctuation

  countPhrases($cont) if ($opt{'advancedStats'});

  $cont =~ s/[^[:alpha:]]+/ /g; # remove all non-word chars
  $cont =~ s/(^ +| $)//g; # spaces at end.
  my $numWords = 1 + $cont =~ s/ +/ /g ;
#  print "$numWords Words\n<br>";
  $_ = length ($cont) + 1 - $numWords;
#  print "$_ bytes in words<br>\n";
  my $lengthPerWord = $_ / $numWords;
#  printf ("%.1f Chars per Word<br>\n",$lengthPerWord);
#  print "<br>\n";

  $cont =~ s/\b[[:alpha:]]?[[:alpha:]]\b/ /g; # remove all 2-char-Words
  my @l = split m/ +/, $cont;
  my %h;
  foreach my $word (@l) {
    next if $word eq '';
    next if (grep {$word eq $_}
      qw(der die das des den dem dass dieser diese dieses dies
      mit auf als für aus
      ist und sind nur oder sie bis
      ein eine eines einer einem einen
      von vor vom bei bis nach zur wird werden
      wurde wurden durch sich war wie kann zum
      the this that are and for has but from with was were
      xref
      ) );
    next if ($word eq decode('utf-8','für'));
    $h{"$word"}++;
  }

  my @top100;
  foreach my $word (sort {$h{$b} <=> $h{$a}} keys %h) {
    $_ = "$word ($h{$word})<br>";
    push @top100, $_."\n";
    last if ($#top100 == 99);
    last if ($h{$word} == 1);
  }

  # find alternativs
  $opt{'alternativen'} = "";
  my %altHash;

  if ($opt{language} eq 'EN')  {

  # ===Therefore===
  @_ = qw (hence thus thereby therefore additionally consequently accordingly finally);
  foreach $_ (@_) {$altHash{$_} += $h{$_};}
  foreach my $_ (sort {$altHash{$b} <=> $altHash{$a}} keys %altHash) {
    $_ = "$_ ($altHash{$_})<br>";
    $opt{'alternativen'} .= "$_\n";
  }
  $opt{'alternativen'} .= "<br>\n";
  %altHash = ();

  # ===measured===
  @_ = qw (measured observed found detected determined yield probed investigated examined);
  foreach $_ (@_) {$altHash{$_} += $h{$_};}
  $altHash{'yield'} += $h{'yielded'};
  foreach my $_ (sort {$altHash{$b} <=> $altHash{$a}} keys %altHash) {
    $_ = "$_ ($altHash{$_})<br>";
    $opt{'alternativen'} .= "$_\n";
  }
  $opt{'alternativen'} .= "<br>\n";
  %altHash = ();

  # ===measurement===
  $altHash{'measurement'} += $h{'measurement'};
  $altHash{'measurement'} += $h{'measurements'};
  $altHash{'investigation'} += $h{'investigation'};
  $altHash{'investigation'} += $h{'investigations'};
  $altHash{'experiment'} += $h{'experiment'};
  $altHash{'experiment'} += $h{'experiments'};
  $altHash{'study'} += $h{'study'};
  $altHash{'study'} += $h{'studies'};
  foreach my $_ (sort {$altHash{$b} <=> $altHash{$a}} keys %altHash) {
    $_ = "$_ ($altHash{$_})<br>";
    $opt{'alternativen'} .= "$_\n";
  }
  $opt{'alternativen'} .= "<br>\n";
  %altHash = ();

  # ===shows===
  $altHash{'show'} +=  $h{'show'};
  $altHash{'show'} +=  $h{'shows'};
  $altHash{'show'} +=  $h{'shown'};
  $altHash{'show'} +=  $h{'showed'};
  $altHash{'show'} +=  $h{'showing'};
  $altHash{'illustrate'} +=  $h{'illustrate'};
  $altHash{'illustrate'} +=  $h{'illustrates'};
  $altHash{'illustrate'} +=  $h{'illustrated'};
  $altHash{'illustrate'} +=  $h{'illustrating'};
  $altHash{'present'} +=  $h{'present'};
  $altHash{'present'} +=  $h{'presents'};
  $altHash{'present'} +=  $h{'presented'};
  $altHash{'present'} +=  $h{'presenting'};
  $altHash{'depict'} +=  $h{'depict'};
  $altHash{'depict'} +=  $h{'depicted'};
  $altHash{'depict'} +=  $h{'depicts'};
  $altHash{'depict'} +=  $h{'depicting'};
  $altHash{'demonstrate'} +=  $h{'demonstrate'};
  $altHash{'demonstrate'} +=  $h{'demonstrates'};
  $altHash{'demonstrate'} +=  $h{'demonstrated'};
  $altHash{'demonstrate'} +=  $h{'demonstrating'};
  foreach my $_ (sort {$altHash{$b} <=> $altHash{$a}} keys %altHash) {
    $_ = "$_ ($altHash{$_})<br>";
    $opt{'alternativen'} .= "$_\n";
  }
  $opt{'alternativen'} .= "<br>\n";
  %altHash = ();

  # ===decrease===
  $altHash{'decrease'} +=  $h{'decrease'};
  $altHash{'decrease'} +=  $h{'decreases'};
  $altHash{'decrease'} +=  $h{'decreased'};
  $altHash{'decrease'} +=  $h{'decreasing'};
  $altHash{'drop'} +=  $h{'drop'};
  $altHash{'drop'} +=  $h{'drops'};
  $altHash{'drop'} +=  $h{'dropped'};
  $altHash{'drop'} +=  $h{'dropping'};
  $altHash{'reduction'} +=  $h{'reduce'};
  $altHash{'reduction'} +=  $h{'reduces'};
  $altHash{'reduction'} +=  $h{'reduced'};
  $altHash{'reduction'} +=  $h{'reducting'};
  $altHash{'reduction'} +=  $h{'reduction'};
  $altHash{'reduction'} +=  $h{'reductions'};
  $altHash{'lower'} +=  $h{'lowers'};
  $altHash{'lower'} +=  $h{'lowered'};
  $altHash{'lower'} +=  $h{'lowering'};
  $altHash{'shrink'} +=  $h{'shrink'};
  $altHash{'shrink'} +=  $h{'shrinks'};
  $altHash{'shrink'} +=  $h{'shrinked'};
  $altHash{'shrink'} +=  $h{'shrinking'};
  $altHash{'shrinkage'} +=  $h{'shrinkage'};

  foreach my $_ (sort {$altHash{$b} <=> $altHash{$a}} keys %altHash) {
    $_ = "$_ ($altHash{$_})<br>";
    $opt{'alternativen'} .= "$_\n";
  }
  $opt{'alternativen'} .= "<br>\n";
  %altHash = ();

  # ===increase===
  $altHash{'increase'} +=  $h{'increase'};
  $altHash{'increase'} +=  $h{'increases'};
  $altHash{'increase'} +=  $h{'increased'};
  $altHash{'increase'} +=  $h{'increasing'};
  $altHash{'rise'} +=  $h{'rise'};
  $altHash{'rise'} +=  $h{'rose'};
  $altHash{'rise'} +=  $h{'rises'};
  $altHash{'rise'} +=  $h{'rising'};
  $altHash{'raise'} +=  $h{'raise'};
  $altHash{'raise'} +=  $h{'raises'};
  $altHash{'raise'} +=  $h{'raised'};
  $altHash{'raise'} +=  $h{'raising'};
  $altHash{'gain'} +=  $h{'gain'};
  $altHash{'gain'} +=  $h{'gains'};
  $altHash{'gain'} +=  $h{'gained'};
  $altHash{'gain'} +=  $h{'gaining'};
  foreach my $_ (sort {$altHash{$b} <=> $altHash{$a}} keys %altHash) {
    $_ = "$_ ($altHash{$_})<br>";
    $opt{'alternativen'} .= "$_\n";
  }
  $opt{'alternativen'} .= "<br>\n";
  %altHash = ();

  } elsif ($opt{language} eq 'DE') {
  # ===zeigt===
  $altHash{'zeigt'} +=  $h{'zeigt'};
  $altHash{'zeigt'} +=  $h{'gezeigt'};
  $altHash{'dargestellt'} +=  $h{'dargestellt'};
  foreach my $_ (sort {$altHash{$b} <=> $altHash{$a}} keys %altHash) {
    $_ = "$_ ($altHash{$_})<br>";
    $opt{'alternativen'} .= "$_\n";
  }
  $opt{'alternativen'} .= "<br>\n";
  %altHash = ();
  }

  %h=undef;

  $opt{'resTop100'} = '';
  while (my $s = shift @top100) {
   $s = encode ($opt{encodingOutput}, $s);
   $opt{'resTop100'} .=  "$s";
  }



  # TODO $_ = time()-$timestamp;   print "TM Time: $_<br>";


}# statistics



