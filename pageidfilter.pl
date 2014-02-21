#!/usr/bin/perl
#
# Cups filter that prints user information on each page.
#
# A format must be defined at /etc/pageidfilter.ini under cups printer name key
#   * %U - username
#   * %Q - queue (printer) name,
#   * Any valid POSIX DATE FORMAT
#
# Example: 'queue=%U - %Q - %Hh%M' prints 'framon - queue - 09h53'
#
# Params: job-id, user, title, copies, options, [filename or stdin]
#

use Config::Simple;
use Time::Piece;

die "Usage: $0 job-id user title copies options [filename]\n" if @ARGV < 5;

my $pgrname = $0;
my $jobid = $ARGV[0] or die "ERR - Argv[0] not defined";

warn "INFO [$jobid] - Starting cups job filter $pgrname\n";

my $printer = $ENV{"PRINTER"} or die "ERR [$jobid] - EnvVar (PRINTER) not defined";
my $user = $ARGV[1] or die "ERR [$jobid] - Argv[1] not defined";
my $text = undef;

my $cfgfile = "/etc/pageidfilter.ini";
my $cfg = new Config::Simple($cfgfile)
            or warn "WARN [$jobid] - Cfg file ($cfgfile) not found\n";

if ($cfg) {
    my $fmtr = $cfg->param($printer)
                    or warn "INFO [$jobid] - Pattern not found\n";

    if ($fmtr) {
        warn "INFO [$jobid] - Pattern found ($fmtr)\n";

        $text = $fmtr;
        $text =~ s/%U/$user/g;
        $text =~ s/%Q/$printer/g;
        $text = localtime->strftime($text);
        warn "INFO [$jobid] - Text after substitution ($text)\n";
    }
}

# Shift all parameters until last one [filename or stdin].
# As I'm not a perl expert, Is it so bad?
shift; shift; shift; shift; shift;

warn "INFO [$jobid] - Filtering pages\n";
while (<>) {

    if ($text and /^%%Page: (\d+)\s+(\d+)/) {
        warn "INFO [$jobid] - Inserting text at page $1 ($2)\n";
        print $_;
        print "gsave\n";
        print ".20 setgray\n";
        print "/Courier findfont 6 scalefont setfont\n";
        print "15 15 moveto\n";
        print "($text) show\n";
        print "grestore\n";

    } else {
        print;
    }
}

warn "INFO [$jobid] - Exiting cups job filter $pgrname\n";

