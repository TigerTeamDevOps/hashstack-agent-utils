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

sub calc_keyspace
{
    my ($charsets, $_mask) = @_;
    my @custom = (1, 1, 1, 1);
    my $keyspace = 1;
    my @mask = split (//, $_mask);

    for (my $c = 0; $c < scalar @$charsets; ++$c)
    {
        my $cs_keyspace = 0;

        if (-e @{$charsets}[$c])
        {
            open my $csf, '<', @{$charsets}[$c];

            while (defined ($_ = <$csf>)) { };
            $cs_keyspace = $.;

            close $csf;
        }
        else
        {
            my @chars = split (//, @{$charsets}[$c], 0);

            for (my $i = 0; $i <= $#chars; ++$i)
            {
                if ($chars[$i] eq '?')
                {
                    given ($chars[++$i])
                    {
                        when ('a') { $cs_keyspace += 95;  }
                        when ('l') { $cs_keyspace += 26;  }
                        when ('u') { $cs_keyspace += 26;  }
                        when ('d') { $cs_keyspace += 10;  }
                        when ('s') { $cs_keyspace += 33;  }
                        when ('b') { $cs_keyspace += 256; }
                    }
                }
                else
                {
                    $cs_keyspace += 1;
                }
            }
        }

        $custom[$c] = $cs_keyspace;
    }

    for (my $i = 0; $i < $#mask; ++$i)
    {
        if ($mask[$i] eq '?')
        {
            given ($mask[++$i])
            {
                when ('a') { $keyspace *= 95;  }
                when ('l') { $keyspace *= 26;  }
                when ('u') { $keyspace *= 26;  }
                when ('d') { $keyspace *= 10;  }
                when ('s') { $keyspace *= 33;  }
                when ('b') { $keyspace *= 256; }
                when ('1') { $keyspace *= $custom[0]; }
                when ('2') { $keyspace *= $custom[1]; }
                when ('3') { $keyspace *= $custom[2]; }
                when ('4') { $keyspace *= $custom[3]; }
            }
        }
    }

    return $keyspace;
}

sub main
{
    my ($skip, $limit, $pos, $lt_pos, $rt_ks, $count, $first, $len) = (0, 0, 0, 0, 0, 0, 1, 0);
    our ($opt_s, $opt_l, $opt_1, $opt_2, $opt_3, $opt_4);
    my @cc = ();

    getopts ('s:l:1:2:3:4:');

    $cc[0] = $opt_1 || '';
    $cc[1] = $opt_2 || '';
    $cc[2] = $opt_3 || '';
    $cc[3] = $opt_4 || '';

    $rt_ks = calc_keyspace (\@cc, $ARGV[1]);
    $len = pwlen ($ARGV[1]);

    open (my $lt, "<", $ARGV[0]);

    if ($opt_s)
    {
        $skip = floor ($opt_s / $rt_ks);
    }

    seek ($lt, 0, 0);

    while (<$lt>)
    {
        my $cmd = $sp64.' --pw-min '.$len.' --pw-max '.$len.' ';

        if ($opt_s && $lt_pos++ < $skip)
        {
            $pos += $rt_ks; 
            next;
        }

        chomp (my $left = $_);

        if ($opt_s && $first)
        {
            $cmd .= ' -s '.($opt_s - $pos).' ';
            $first = 0;
        }

        $cmd .= '-1 '.shell_quote ($cc[0]).' ' if ($cc[0]);
        $cmd .= '-2 '.shell_quote ($cc[1]).' ' if ($cc[1]);
        $cmd .= '-3 '.shell_quote ($cc[2]).' ' if ($cc[2]);
        $cmd .= '-4 '.shell_quote ($cc[3]).' ' if ($cc[3]);
        $cmd .= shell_quote ($ARGV[1]);

        open (my $rt, "$cmd |");

        while (<$rt>)
        {
            if ($opt_l && $count++ > $opt_l - 1)
            {
                exit;
            }

            chomp (my $right = $_);

            say $left.$right;
        }

        close ($rt);
    }

    close ($lt);
}

main();

