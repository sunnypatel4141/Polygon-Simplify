#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Polygon::Simplify' ) || print "Bail out!\n";
}

diag( "Testing Polygon::Simplify $Polygon::Simplify::VERSION, Perl $], $^X" );
