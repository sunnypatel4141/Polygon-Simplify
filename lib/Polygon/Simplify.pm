package Polygon::Simplify;

use 5.006;
use strict;
use warnings;

use Math::BigFloat ':constant';

=head1 NAME

Polygon::Simplify

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01'; 

=head1 SYNOPSIS

	use Poygon::Simplify;

	# Raw points requiring simplification
	my $points = [
		{
			x => 12.1, y => 3.41
		},
		...
	];

# POINT MUST BE AN Array of x and y points and not lat lng

	my $cleaned_points = Polygon::Simplify::simplify($points);

# $cleaned_points is an array of hash refs

=head1 DESCRIPTION

perl port of simplify.js

=head2 getSqDist(\%p1, \%p2)

square distance between 2 points

=cut

sub getSqDist {
	my ($p1, $p2) = @_;

	my $dx = $p1->{x} - $p2->{x};
	my $dy = $p1->{y} - $p2->{y};

	return ($dx * $dx) + ($dy * $dy);
}

=head2 getSqSegDist(\%p \%p1, \%p2)

square distance from a point to a segment

=cut
sub getSqSegDist {
	my ($p, $p1, $p2) = @_;

	my $x = $p1->{x};
	my $y = $p1->{y};
	my $dx = $p2->{x} - $x;
	my $dy = $p2->{y} - $y;

	if($dx != 0 || $dy != 0 ) {

		my $first_block = Math::BigFloat->new($p->{x} - $x);
		my $second_block = Math::BigFloat->new($p->{y} - $y);
		
		my $first_multiply = $first_block->bmul($dx); 
		my $second_multiply = $second_block->bmul($dy);
		
		my $top = $first_multiply->badd($second_multiply);
		my $dx_square = Math::BigFloat->new($dx)->bmul($dx);
		my $dy_square = Math::BigFloat->new($dy)->bmul($dy);
		my $bottom = $dx_square->badd($dy_square);
	#	my $t = (($p->{x} - $x) * $dx + ($p->{y} - $y) * $dy) / ($dx * $dx + $dy * $dy);

		my $t = $top->bdiv($bottom)->bstr();

		if($t > 1) {
			$x = $p2->{x};
			$y = $p2->{y};
		} elsif( $t > 0) {
			$x += $dx * $t;
			$y += $dy * $t;
		}
	}

	$dx = $p->{x} - $x;
	$dy = $p->{y} - $y;

	return ($dx * $dx) + ($dy * $dy);
}

=head2 simplifyRadialDist($\@points, $sqTolerance)

Basic distanec-based simplifaction

=cut

sub simplifyRadialDist {
	my ( $points, $sqTolerance) = @_;

	my $prev_point = $points->[0];
	my $new_points = [$prev_point];
	my $point;

	my $len = @{$points};
	for (my $i = 1; $i < $len; $i++) {
		$point = $points->[$i];

		if (getSqDist($point, $prev_point) > $sqTolerance) {
			push( @{$new_points}, $point);
			$prev_point = $point;
		}

	}
	
	# If the polygon is not complete then complete it
	push (@{$new_points}, $point) if ($prev_point != $point);

	return $new_points;
}

sub simplifyDPStep {
	my ($points, $first, $last, $sqTolerance, $simplified) = @_;

	my $maxSqDist = $sqTolerance;
	my $index;

	for(my $i = $first + 1; $i < $last; $i++) {
		my $sqDist = getSqSegDist($points->[$i], $points->[$first], $points->[$last]);

		if ($sqDist > $maxSqDist) {
			$index = $i;
			$maxSqDist = $sqDist;
 		}

	}

	if ($maxSqDist > $sqTolerance) {
		simplifyDPStep($points, $first, $index, $sqTolerance, $simplified);
		push @{$simplified}, $points->[$index];
		simplifyDPStep($points, $index, $sqTolerance, $simplified)
			if($index - $first > 1);
	}
}

=head2 simplifyDouglasPeucker(\@points, $sqTolerance)

Simplification using Ramer-Douglas-Peucker algorithm

=cut
sub simplifyDouglasPeucker {
	my ($points, $sqTolerance) = @_;

	my $last = @{$points} - 1;

	my $simplified = [$points->[0]];
	simplifyDPStep($points, 0, $last, $sqTolerance, $simplified);
	push @{$simplified}, $points->[$last];

	return $simplified;

}

=head2 simplify(\@points, $tolerance, $highest_quality)

both algorithms combined for awsome performance

	my $points = [
		{
			x => 51.34,
			y => 1.34,
		},
		...
	];

	simplify($points, $tolerance, $highest_quality);

=cut

sub simplify {
	my ($points, $tolerance, $highestQuality) = @_;

	return $points if (@{$points} <= 2);

	my $sqTolerance = 1;

	if ( $tolerance ) {
		$sqTolerance = $tolerance * $tolerance;
	}

	$points = $highestQuality ? $points : simplifyRadialDist($points, $sqTolerance);
	$points = simplifyDouglasPeucker($points, $sqTolerance);

	return $points;


}

=head1 AUTHOR

Sunny Patel C<< <sunnypatel4141@gmail.com> >>

=head1 BUGS

please report any bugs or feature requests to C<bug-polygon-simpligy at rt.cpan.org>, or through 
the we interace at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Polygon-Simplify>. I will be notified, and then you'll 
automatically be notified of progress on your bug as I make changes.o

=cut

1;
