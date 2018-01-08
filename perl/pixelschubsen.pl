#!/usr/bin/perl -w

use strict;
use Time::HiRes qw(usleep);
use jdpix;

# Initalise LEDs
my $client=new jdpix({host => "trixel", port => 7777, leds =>256});

my $maxx=16;
my $maxy=16;
my $bright=64;

while (1) {
	wave_diagonal();
	wave_topdown();
}

$client->init_arr();
$client->show();

$client->disconnect();

sub wave_diagonal {
	for (my $x=0;$x<$maxx;$x++) { # 1st half 
			for (my $i=0;$i<=($x%$maxx);$i++) {
				$client->set_hsv(xy2led($i,$x-$i),(($x%$maxx)*(255/$maxx))%255,255,$bright);
			}
		$client->show();
		$client->fade2black(int($bright/$maxx));
		usleep(1000*25);
	}
	for (my $x=$maxx-1;$x>=0;$x--) { # 2nd half
			for (my $i=0;$i<=($x%$maxx);$i++) {
				$client->set_hsv(xy2led($maxx-1-$i,$maxx-1-($x-$i)),(($x%$maxx)*(255/$maxx))%255,255,$bright);
			}
		$client->show();
		$client->fade2black(int($bright/$maxx));
		usleep(1000*25);
	}
}

sub wave_topdown {
	for (my $y=0;$y<$maxy;$y++) {
		for (my $x=0;$x<$maxx;$x++) {
			my $led=xy2led($x,$y);
			$client->set_hsv($led,(($y)*(255/$maxx))%255,255,$bright);
		}
		$client->show();
		$client->fade2black(int($bright/($maxx/2)));
		usleep(1000*20);
	}
}

sub onceall {
	for (my $y=0;$y<$maxy;$y++) {
		for (my $x=0;$x<$maxx;$x++) {
			my $led=xy2led($x,$y);
			$client->fade2black(int($bright/$maxx));
			$client->set_hsv($led,($x*$y)%255,255,$bright);
			$client->show();
			usleep(1000*25);
		}
	}
}

sub xy2led {
	# Rechnet X,Y in LED-pos an.
	# Funktioniert bei folgendem Setup:
	# 4 8x8 Panel wie folgt zusammengeschaltet:
	# --> 1 -> 2
	#  -> 3 -> 4
	# Laufrichtung innerhalb eines Panels:
	#  1, 2, 3, 4, 5, 6, 7, 8
	# 16,15,14,13,12,11,19, 9 
	# 17,18,19,20,21,22,23,24 usw.
	#
	my($x,$y)=@_;
	my $upperpanel=0;
	my ($i,$reverseY);
	$y=16-1-$y;
	if ( $x > 7 ) { # 2 Panelreihe? Dann 8 abziehen.
		$x=$x-8;
		$upperpanel=0; 
	} else {
		$upperpanel=1;
	}
	if(($y%2)==1) { # Ungerade Reihen werden Rückwärts gezählt.
		$reverseY = (8 - 1) - $x;
		$i = ($y * 8) + $reverseY;
	} else {
		$i = ($y * 8) + $x;
	}
	if (($upperpanel)) { # Obere Panelreihe? Dann 128 draufaddieren
		$i=$i+128;
	}
	return $i;
}

