#!/usr/bin/perl

use XML::Simple;
use Data::Dumper;
use strict;
use autodie;

my $stanza;
my $compare;
my @search_options;
my @grep;
my @golden;
my @configfiles;
my @regex;
my $currentline;
my @current_array;
my $current_regex;
my @found;

#read in XML config file
my $search = XMLin('seedfile.xml', ForceArray => [ 'options', 'configfiles'], ForceContent => 1);


##seperate regexs, golden config lines and lines to be grepped into arrays
#my @regex = grep /regex/, @search_options;
#my @golden = grep /golden/, @search_options;
#my @grep = grep /grep/, @search_options;



#foreach (@search_options) {
#  print $_."\n";
#}

#print Dumper($search);


#Begin processing data input from XML config file.  The default data strcuture used by XML::Simple is too cumbersome.

#pull items to be grepped into an array

#pull list of golden config snippets into an array of hash references
# ex:  'golden' => [
#                     {
#                       'content' => 'virtual-inet6-address ',
#                       'stanza' => 'interface'
#                     },
#                     {
#                       'content' => 'virtual-link-local-address',
#                       'stanza' => 'interface'
#                     },
#
if ($search->{"grep"}) { 
  @grep = $search->{"grep"}; 
  foreach $currentline(@grep) {
    if ($currentline->{'stanza'}) {
      @current_array = split(',', $currentline->{'stanza'});
      $currentline->{'stanza'} =  \@current_array;
    }
  }
}

if ($search->{"golden"}) { 
  @golden = @ { $search->{"golden"} }; 
  foreach $currentline(@golden) {
    if ($currentline->{'stanza'}) {
      @current_array = split(',', $currentline->{'stanza'});
      $currentline->{'stanza'} =  \@current_array;
    }  
  }
}

#pull list of regular experssions into a list of hash references same as above
if ($search->{"regex"}) { 
  @regex = @ { $search->{"regex"} };
  foreach $currentline(@regex) {
    if ($currentline->{'stanza'}) {
      @current_array = split(',', $currentline->{'stanza'});
      $currentline->{'stanza'} =  \@current_array;
    }
  }
}

#pull list of device configs into an array
if ($search->{"configfiles"}) { 
  @configfiles =  split( "\n" , $search->{"configfiles"}->[0]->{"content"} ); 
  shift @configfiles; 
  foreach (@configfiles) {
    $_  =~ s/\s+|\n+//g;
  }
}


#print "@configfiles \n @golden \n @regex";

my @currentfile;
my @current_stanza;
my @previous_stanza;
my $search_input;

foreach (@configfiles) {
  open (CURRENTFILE, "./config/$_") or die $!;
  print "processing $_\n";
  sleep 3;
  @currentfile = <CURRENTFILE>;
  close CURRENTFILE;

  open OUTFILE, ">results.txt"  or die $!;
  
  foreach (@currentfile) {
    $search_input = $_;
    $search_input =~ s/\r\n/\n/g;
    chomp $search_input;
 
    if ($_ =~ m/\{/) {
      $currentline = $_;
      $currentline =~ s/\r\n/\n/g;
      chomp $currentline;
      $currentline =~ s/\{.*$//g;
      $currentline =~ s/\s+//g;
      push @current_stanza , $currentline;
     #print "current stanza=@current_stanza\n";
    }
    if ($_ =~ m/\}/) {
      @previous_stanza = @current_stanza;
      pop  @current_stanza;
     #print "current stanza=@current_stanza\n";
     #print "previous stanza=@previous_stanza\n";
    }
    foreach (@regex) {
      if ($_->{'stanza'}) {
       #print "comparing @current_stanza and @{ $_->{'stanza'} }\n"; 
       #print "regex = $_->{'content'}\n";
        $current_regex = qr/$_->{'content'}/is;
#       if (@current_stanza ~~ @{ $_->{'stanza'} })  {
          if (1==1){}  
          if ($search_input ~~ m/$current_regex/) {
            print OUTFILE "$search_input \n";
            print OUTFILE "a\n";
            print "$search_input matches $current_regex in @current_stanza  \n";
            push @found , $search_input;
          }
#       }
      }       
    }  

    foreach (@golden) {
  
    }

    foreach (@grep) {
  
    }
}
}
close OUTFILE;
#print @found;
