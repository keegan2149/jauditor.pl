#!/usr/bin/perl

use XML::Simple;
use Data::Dumper;
use strict;
use autodie;

my @current_file;
my @current_stanza;
my @previous_stanza;
my $search_input;
my @golden;
my @golden_lines;
my $current_golden;
my $golden_stanza;
my @golden_grouping;
my $current_grouping;
my %scope_hash;
my @configfiles;
my @regex;
my $current_line;
my $current_line_inner;
my @current_array;
my @current_array2;
my $current_regex;
my @found;
my @scope;
my @current_file;
my @current_stanza;
my @previous_stanza;
my $search_input;
my $regex_result;
my $current_unit;

#read in XML config file
my $seedfile = XMLin('seedfile.xml', ForceArray => [ 'options', 'configfiles'], ForceContent => 1);



#print Dumper($seedfile);


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

if ($seedfile->{"golden"}) { 
  @golden = @ { $seedfile->{"golden"} }; 
  foreach $current_line(@golden) {
    if ($current_line->{'stanza'}) {
      @current_array = split(',', $current_line->{'stanza'});
      $current_line->{'stanza'} =  \@current_array;
    }
    push @golden_lines , $current_line->{content};   
  }
  if ($golden_lines[0] =~ /interface\s\b.*\b/) {
    foreach (@golden_lines) {
      if ($_ =~ /unit\s\d+/) {
        $regex_result = $&;
        push @golden_grouping , $regex_result;
      }
    }   
  }
}

#pull list of regular experssions into a list of hash references same as above
if ($seedfile->{"regex"}) { 
  @regex = @ { $seedfile->{"regex"} };
  foreach $current_line(@regex) {
    if ($current_line->{'stanza'}) {
      @current_array = split(',', $current_line->{'stanza'});
      $current_line->{'stanza'} =  \@current_array;
    }
  }
}

#pull list of device configs into an array
if ($seedfile->{"configfiles"}) { 
  @configfiles =  split( "\n" , $seedfile->{"configfiles"}->[0]->{"content"} ); 
  shift @configfiles; 
  pop @configfiles;
  foreach (@configfiles) {
    $_  =~ s/\s+|\n+//g;
  }
}


#print "@configfiles \n @golden \n @regex";



foreach my $file(@configfiles) {
  open CURRENTFILE, "<./config/$file" or die $!;
  print "processing $file\n";
  sleep 3;
  @current_file = <CURRENTFILE>;
  close CURRENTFILE;

  open OUTFILE, ">./results.txt"  or die $!;
  
  foreach (@current_file) {
    $search_input = $_;
    $search_input =~ s/\r\n/\n/g;
    chomp $search_input;
 
    if ($_ =~ m/\{/) {
      $current_line = $_;
      $current_line =~ s/\r\n/\n/g;
      chomp $current_line;
      $current_line =~ s/\{.*$//g;
      $current_line =~ s/\s+//g;
      push @current_stanza , $current_line;
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
        if ($search_input ~~ m/$current_regex/) {
          #dud.. need to figure out why nothing is written to the output file
          #also need to organize output by regex using the array.  hash maybe?
          print OUTFILE "$file: $search_input \n";
#         print "$search_input matches $current_regex in @current_stanza  \n";
          push @found , "$file: $search_input\n";
        }
      }       
    }  
  }
  foreach (@golden) {
    $current_line_inner = "@{ $_->{'stanza'} }\n";
    chomp $current_line_inner;
  
    if ($current_line_inner =~ /interface/) {    
      $current_regex = qr/^set\s$current_line_inner\s/is;
      @scope = grep { $_ =~ /$current_regex/ } @current_file;
      %scope_hash = map { $_ => 1 } @scope;   
      foreach $current_unit(@golden_grouping) {
        $current_regex = qr/$current_grouping/is;
        foreach(@golden_lines) {
          if ((!$scope_hash{$_}) && ($_ =~ /$current_regex/)) {
            push @found , "$_ does not exist in $current_line_inner $current_grouping \n";
            print "OUTFILE $_ does not exist in $current_line_inner $current_grouping \n";
          }
        }           
      }
    }
  }
}




close OUTFILE;
#print @found;
