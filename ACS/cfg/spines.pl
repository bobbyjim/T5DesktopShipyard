


my @t1 = (4500, 4000, 3500, 3000, 2500, 2400, 2300, 2200, 2100, 2000, 1900, 1800);
my @t2 = (9500, 9000, 8500, 8000, 7500, 7000, 6500, 6000, 5500, 5000, 4500, 4000);
my @t3 = (8000, 7500, 7000, 6500, 6000, 5500, 5000, 4500, 4000, 3500, 3000, 2500);
doit( \@t1, \@t2, \@t3 );

@t1 = (8500, 7500, 6500, 5500, 4900, 4700, 4500, 4300, 4100, 3900, 3700, 3500);
@t2 = (18500, 17500, 16500, 15500, 14500, 13500, 12500, 11500, 10500, 9500, 8500, 8000);
@t3 = (15500, 14500, 13500, 12500, 11500, 10500, 9500, 8500, 7500, 6500, 5500, 5000);
doit( \@t1, \@t2, \@t3, 'enhanced' );

sub doit
{
   my $t1ref = shift;
   my $t2ref = shift;
   my $t3ref = shift;
   my $enhanced = shift || 0;
 
   my @t1 = @$t1ref;
   my @t2 = @$t2ref;
   my @t3 = @$t3ref;

   my $tl = 10;
  
   for my $code ('A'..'H', 'J'..'M')
   {
      $code .= 'E' if $enhanced;

      my $s = "S$code";
      my $d = "D$code";
      my $b = "B$code";
   
      my $t1 = shift @t1;
      my $t2 = shift @t2;
      my $t3 = shift @t3;
   
      my $cr1 = $t1 / 10;
      my $cr2 = $t2 / 10;
      my $cr3 = $t3 / 10;
   
      print<<EOROW;
      - { code: $s   , label: 'Spine $code',      tl: $tl,     mount tons: $t1, mod: 0,   mount mcr: $cr1  }
      - { code: $d   , label: 'Dish $code',       tl: $tl,     mount tons: $t2, mod: 0,   mount mcr: $cr2  }
      - { code: $b   , label: 'Main Bay $code',   tl: $tl,     mount tons: $t3, mod: 0,   mount mcr: $cr3  }
EOROW

      $tl++;
   }
}
