#!/usr/bin/perl

use strict;
use warnings;
use LWP::UserAgent;
use JSON;

my $K=10**3;
my $M=10**6;
my $G=10**9;

my $total_crypto_watts=0;

# source : https://www.edf.fr/groupe-edf/espaces-dedies/l-energie-de-a-a-z/tout-sur-l-energie/produire-de-l-electricite/le-nucleaire-en-chiffres
# La production mondiale d'électricité en 2013 a représenté un total de 23 405,7 TWh
my $world_electricity_production_2013=23405 * 10**12 / 365 / 24;

# Un réacteur de 900 MW produit en moyenne chaque mois 500 000 MWh, ce qui correspond à la consommation de 400 000 ménages environ.
my $reactor_900MW_production_2013=500*$G / 30 / 24;

# source : http://world-nuclear.org/information-library/current-and-future-generation/nuclear-power-in-the-world-today.aspx
my $operable_nuclear_reactor=450;

my @Sources=(
  'https://whattomine.com/coins.json',
  'https://whattomine.com/asic.json'
);

# Exclude due to bad nethash value
my @ExcludesCoins=(
  'Unobtanium',
  'Myriad-SHA'
);

# From sugested miners on whattomine
my $miners_efficiency={
#  algo          => hash rate * unit / Watts
# GPU
  'Ethash'           =>     88.5  * $M   / 405,
  'Groestl'          =>     63.9  * $M   / 450,
  'PHI1612'          =>     45    * $M   / 390,
  'CryptoNightHeavy' =>   2850    *  1   / 330,
  'CryptoNightV7'    =>   2580    *  1   / 330,
  'Equihash'         =>    870    *  1   / 360,
  'Lyra2REv2'        =>     14.7  * $M   / 390,
  'Lyra2z'           =>      1.35 * $M   / 360,
  'NeoScrypt'        =>   2460    * $K   / 450,
  'PHI2'             =>      6    * $M   / 170,   # https://www.coincalculators.io/coin.aspx?crypto=luxcoin-mining-calculator
  'TimeTravel10'     =>     27    * $M   / 450,
  'X16R'             =>     21    * $M   / 360,
  'Skunkhash'        =>     54    * $M   / 345,
  'NIST5'            =>     57    * $M   / 345,
  'Xevan'            =>      4.8  * $M   / 360,
  'Zhash'            =>      240  *  1   / 1050,  # https://mineshop.eu/bitcoin-gold-miner/bitcoin-gold-mining-rig/
# ASIC
  'SHA-256'      =>  14000    * $G   / 1370,
  'Scrypt'       =>   1000    * $M   / 1600,
  'X11'          =>  34000    * $M   / 2100,
  'Blake (2b)'   =>    815    * $G   / 1370,
  'Quark'        =>   3300    * $M   / 120,
  'Qubit'        =>   3300    * $M   / 130,
  'Myr-Groestl'  =>      3.3  * $G   / 50,
  'Skein'        =>      1.7  * $G   / 40,
  'LBRY'         =>     20    * $G   / 200,
  'Blake (14r)'  =>     80    * $G   / 205,
  'Pascal'       =>     20    * $G   / 105,
  'X11Gost'      =>      0.45 * $G   / 70,
  'CryptoNight'  =>     55    * $K   / 140
};

my $crypto_stats={};

my $ua=LWP::UserAgent->new();
# LWP seems forbiden
$ua->agent('curl/7.58.0');

foreach my $url (@Sources) {
  calculate_watts($url);
}


sub calculate_watts {
  my $url=shift;

  my $response=$ua->get($url);
  die $response->status_line if (! $response->is_success);
  
  my $data=decode_json($response->decoded_content);
  
  foreach my $coin_name (keys(%{$data->{coins}})) {
    next if (grep(/^\Q$coin_name\E$/,@ExcludesCoins));
    my $coin_details=$data->{coins}->{$coin_name};
    my $coin_algorithm=$coin_details->{algorithm};
    my $coin_nethash=$coin_details->{nethash};
    if (defined($miners_efficiency->{$coin_algorithm})) {
      my $coin_watts=$coin_nethash/$miners_efficiency->{$coin_algorithm};
      $crypto_stats->{$coin_name}=$coin_watts;
      $total_crypto_watts+=$coin_watts;
    } else {
      warn("Missing efficiency information for algorithm $coin_algorithm");
    }
  }

}


print "World electricity production (in 2013) : ".human_numbers($world_electricity_production_2013)."W\n";
print "One 900MW nuclear reactor average production : ".human_numbers($reactor_900MW_production_2013)."W\n";
print "Number of operated nuclear reactors in the world : $operable_nuclear_reactor\n";
print "\n";


printf ("%15s  : cryptocurrency\n",'Power');
foreach my $coin_name (sort({$crypto_stats->{$b} <=> $crypto_stats->{$a}} keys(%$crypto_stats))) {
  printf ("%15dW : %s (%sW)\n",$crypto_stats->{$coin_name}, $coin_name, human_numbers($crypto_stats->{$coin_name}));
}

print "\n";
print "Total used power for all listed cryptocurrency: ".human_numbers($total_crypto_watts)."W\n";

print "\n";
my $crypto_world_power_ratio=$total_crypto_watts*100/$world_electricity_production_2013;
print "\t= ".sprintf("%.2f",$crypto_world_power_ratio)." % of world electricity\n";

my $nuclear_reactor_needed_for_cryptocurrency = $total_crypto_watts/$reactor_900MW_production_2013;
print "\t= ".sprintf("%.2f",$nuclear_reactor_needed_for_cryptocurrency)." nuclear reactors of 900MW\n";

my $cryptocurrency_percentage_of_all_nuclear_reactors=$nuclear_reactor_needed_for_cryptocurrency*100/$operable_nuclear_reactor;
print "\t= ".sprintf("%.2f",$cryptocurrency_percentage_of_all_nuclear_reactors)."% of world nuclear reactors\n";

sub human_numbers {
  my $value=shift;
  my $unit_pos=0;
  my @units=('','K','M','G','T','P','E','Z','Y');
  while ($value > 1000) {
    $unit_pos++;
    $value=$value/1000;
  }
  return sprintf('%.2f',$value).' '.$units[$unit_pos];
}
