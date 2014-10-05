#!/usr/bin/env perl -w
#
#  Copyright 2014, Stricture Consulting Group LLC.
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

sub main
{
    my ($skip, $limit, $pos, $lt_pos, $lt_wc, $rt_wc, $count) = (0, 0, 0, 0, 0, 0, 0);
    our ($opt_s, $opt_l);

    getopts ('s:l:');

    open (my $lt, "<", $ARGV[0]);
    open (my $rt, "<", $ARGV[1]);

    while (defined ($_ = <$lt>)){};
    $lt_wc = $.;

    while (defined ($_ = <$rt>)){};
    $rt_wc = $.;

    if ($opt_s)
    {
        $skip = floor ($opt_s / $rt_wc);
    }

    seek ($lt, 0, 0);

    while (<$lt>)
    {
        if ($opt_s && $lt_pos++ < $skip)
        {
            $pos += $rt_wc; 
            next;
        }

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

    close ($lt);
    close ($rt);
}

main();

