#!/usr/bin/env perl -w
#
#  Copyright 2014, Stricture Consulting Group LLC
#  All rights reserved.
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are met:
#
#      * Redistributions of source code must retain the above copyright
#        notice, this list of conditions and the following disclaimer.
#
#      * Redistributions in binary form must reproduce the above copyright
#        notice, this list of conditions and the following disclaimer in the
#        documentation and/or other materials provided with the distribution.
#
#      * Neither the name of the Stricture Consulting Group LLC nor the
#        names of its contributors may be used to endorse or promote products
#        derived from this software without specific prior written permission.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
#  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#  DISCLAIMED. IN NO EVENT SHALL STRICTURE CONSULTING GROUP LLC BE LIABLE FOR ANY
#  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


use Modern::Perl;
use Getopt::Std;
use POSIX;
use String::ShellQuote ('shell_quote');

my $sp64 = '/opt/hashstack/programs/statsprocessor/sp64.bin /opt/hashstack/programs/statsprocessor/hashcat.hcstat';


sub pwlen
{
    my $mask = shift;

    $mask =~ s/\?//g;

    return length ($mask);
}

sub main
{
    my ($limit, $pos, $lt_pos, $rt_wc, $count, $cmd, $len) = (0, 0, 0, 0, 0, 0);
    our ($opt_s, $opt_l, $opt_1, $opt_2, $opt_3, $opt_4);

    getopts ('s:l:1:2:3:4:');

    $len = pwlen ($ARGV[0]);

    open (my $rt, "<", $ARGV[1]);

    while (defined ($_ = <$rt>)){};
    $rt_wc = $.;

    $cmd = $sp64.' --pw-min '.$len.' --pw-max '.$len.' ';

    if ($opt_s)
    {
        $cmd .= '-s '.floor ($opt_s / $rt_wc).' ';
    }

    $cmd .= '-1 '.shell_quote ($opt_1).' ' if ($opt_1);
    $cmd .= '-2 '.shell_quote ($opt_2).' ' if ($opt_2);
    $cmd .= '-3 '.shell_quote ($opt_3).' ' if ($opt_3);
    $cmd .= '-4 '.shell_quote ($opt_4).' ' if ($opt_4);
    $cmd .= shell_quote ($ARGV[0]);

    open (my $lt, "$cmd |");

    while (<$lt>)
    {
        chomp (my $left = $_);

        seek ($rt, 0, 0);

        while (<$rt>)
        {
            if ($opt_s && $pos++ < $opt_s - 1)
            {
                next;
            }

            if ($opt_l && $count++ > $opt_l - 1)
            {
                exit;
            }

            chomp (my $right = $_);

            say $left.$right;
        }

    }

    close ($rt);
}

main();

