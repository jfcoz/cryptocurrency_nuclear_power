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
  'BCD'              =>     30.3  * $M   / 390,
  'CryptoNightConceal' => 4950    *  1   / 330,   # https://whattomine.com/coins/305-ccx-cryptonightconceal
  'CryptoNightFast'  =>   4950    *  1   / 330,
  'CryptoNightFastV2'=>   4950    *  1   / 330,   # https://whattomine.com/coins/273-msr-cryptonightfastv2
  'CryptoNightGPU'   =>   2280    *  1   / 360,   # https://whattomine.com/coins/260-ryo-cryptonightgpu
  'CryptoNightHaven' =>   2700    *  1   / 330,   # https://www.whattomine.com/coins/279-xhv-cryptonighthaven
  'CryptoNightHeavy' =>   2850    *  1   / 330,
  'CryptoNightR'     =>   2490    *  1   / 390,
  'CryptoNightSaber' =>   2700    *  1   / 330,   # https://www.whattomine.com/coins/256-tube-cryptonightsaber
  'CryptoNightV7'    =>   2580    *  1   / 330,
  'CryptoNightV8'    =>   4950    *  1   / 330,
  'CNReverseWaltz'   =>   2550    *  1   / 390,   # https://whattomine.com/coins/261-grft-cnreversewaltz
  'Cuckaroo29'       =>      6.6  *  1   / 390,
  'Cuckaroo29s'      =>      4.35 *  1   / 270,   # https://whattomine.com/coins/301-xwp-cuckaroo29s
  'Cuckarood29'      =>      4.35 *  1   / 270,   # https://whattomine.com/coins/293-grin-cuckarood29
  'Cuckatoo31'       =>      1.05 *  1   / 360,
  'Cuckatoo32'       =>      0.48 *  1   / 360,
  'CuckooCycle'      =>      3.6  *  1   / 300,   # https://whattomine.com/coins/297-ae-cuckoocycle
  'Energi'           =>     84    * $M   / 405,
  'Equihash'         =>    870    *  1   / 360,
  'Equihash (150,5)' =>     30    *  1   / 390,   # https://whattomine.com/coins/294-beam-equihash-150-5
  'Equihash (210,9)' =>    285    *  1   / 360,
  'EquihashZero'     =>    42     *  1   / 390,
  'Ethash'           =>     88.5  * $M   / 405,
  'Groestl'          =>     63.9  * $M   / 450,
  'Hex'              =>     22.8  * $M   / 390,
  'KawPow'           =>     39    * $M   / 510,
  'PHI1612'          =>     45    * $M   / 390,
  'Lyra2REv2'        =>     14.7  * $M   / 390,
  'Lyra2REv3'        =>    117    * $M   / 420,
  'Lyra2z'           =>      1.35 * $M   / 360,
  'MTP'              =>      1.8  * $M   / 390,
  'NeoScrypt'        =>   2460    * $K   / 450,
  'NIST5'            =>     57    * $M   / 345,
  'PHI2'             =>      6    * $M   / 170,   # https://www.coincalculators.io/coin.aspx?crypto=luxcoin-mining-calculator
  'ProgPow'          =>     23.7  * $M   / 420,
  'RandomX'          =>     1410  *  1   / 270,
  'Skunkhash'        =>     54    * $M   / 345,
  'TimeTravel10'     =>     27    * $M   / 450,
  'Ubqhash'          =>     84    * $M   / 405,   # https://whattomine.com/coins/173-ubq-ubqhash
  'X16R'             =>     21    * $M   / 360,
  'X16RT'            =>     24    * $M   / 390,   # https://whattomine.com/coins/286-veil-x16rt
  'X16Rv2'           =>     34.5  * $M   / 420,
  'X22i'             =>     15    * $M   / 390,
  'X25X'             =>      2.49 * $M   / 240,
  'Xevan'            =>      4.8  * $M   / 360,
  'ZelHash'          =>     42    *  1   / 360,
  'Zhash'            =>    240    *  1   / 1050,  # https://mineshop.eu/bitcoin-gold-miner/bitcoin-gold-mining-rig/
# ASIC
  'Blake (2b)'   =>    815    * $G   / 1370,
  'Blake (14r)'  =>     80    * $G   / 205,
  'CryptoNight'  =>     55    * $K   / 140,
  'Eaglesong'    =>    530    * $G   / 170,
  'Keccak'       =>     29    * $G   / 430,
  'LBRY'         =>     20    * $G   / 200,
  'Myr-Groestl'  =>      3.3  * $G   / 50,
  'Pascal'       =>     20    * $G   / 105,
  'Quark'        =>   3300    * $M   / 120,
  'Qubit'        =>   3300    * $M   / 130,
  'Scrypt'       =>   1000    * $M   / 1600,
  'SHA-256'      =>  14000    * $G   / 1370,
  'Sia'          =>    135    * $G   / 125,
  'Skein'        =>      1.7  * $G   / 40,
  'Tensority'    =>    150    * $K   / 800,
  'X11'          =>  34000    * $M   / 2100,
  'X11Gost'      =>      0.45 * $G   / 70,
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
