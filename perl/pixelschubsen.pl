#!/usr/bin/perl -w

use strict;
use Time::HiRes qw(usleep);
use Data::Dumper;
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
	for (my $i=0;$i<32;$i++) {
		drawline(0,$i,$i,0,$client->CHSV($i*4,255,64)) if ($i<16);
		drawline($i%16,15,15,$i%16,$client->CHSV($i*4,255,64)) if ($i>15);
		usleep(1000*20);
		$client->show();
		$client->fade2black(int($bright/$maxx));
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

sub drawline {
	## ToDo: Fix the error by drawing vertical line (divide by zero);
	my($x1,$y1,$x2,$y2,$r,$g,$b,$mode)=@_;
	my $dx=$x2-$x1;
	my $dy=$y2-$y1;
	if (($dx == 0) && ($dy == 0)) {
		$client->{'arr'}->[xy2led($x1,$y1)]=[$r,$g,$b,$mode];
	} elsif ($dx > 0) {
		for (my $x=$x1;($x1>$x2) ? $x>=$x2 : $x<=$x2;($x1>$x2) ? $x--: $x++) {
			$client->{'arr'}->[xy2led($x,int($y1+$dy*($x-$x1)/$dx))]=[$r,$g,$b,$mode];
		}
	} else {
		for (my $y=$y1;($y1>$y2) ? $y>=$y2 : $y<=$y2;($y1>$y2) ? $y--: $y++) {
			$client->{'arr'}->[xy2led($y,int($x1+$dx*($y-$y1)/$dy))]=[$r,$g,$b,$mode];
		}
	}
}
