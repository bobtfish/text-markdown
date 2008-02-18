#!/bin/sh

PERL58=/usr/bin/perl
PERL510=/usr/local/bin/perl

$PERL58 -Ilib t/07fulldoc.t > 58.out
$PERL510 -Ilib t/07fulldoc.t > 510.out

diff -u 58.out 510.out

