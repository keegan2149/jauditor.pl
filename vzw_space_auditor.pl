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
my $current_golden;
my $golden_stanza;
my @golden_grouping;
my $current_grouping;
my %scope_hash;
my @configfiles;
my @regex;
my $current_line;
my $current_word;
my $current_line_inner;
my @temp_array;
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
my $config_hierarchy = "top";
my $config_object = "none";
my $level=0;

unless ($#ARGV) {
      die "usage: vzw_space_auditor.pl [-audit audit working dir] ";
} elsif ($_ eq "-h") { 
      die "usage: vzw_space_auditor.pl [-audit audit working dir] ";
}

my $workingdir = "$ARGV[0]/config/" if ($ARGV[0] =~ /-audit\s.*/);
#Build a data structure to represent the data needed to perform the required checks

my %search_hash = (
  'golden_config'  => [ ["set interfaces irb unit <*> description <*>",
                       "set interfaces irb unit <*> family inet6 address <*> vrrp-inet6-group <*> virtual-inet6-address <*>",
                       "set interfaces irb unit <*> family inet6 address <*> vrrp-inet6-group <*> virtual-link-local-address <*>",
                       "set interfaces irb unit <*> family inet6 address <*> vrrp-inet6-group <*> priority <*>",
                       "set interfaces irb unit <*> family inet6 address <*> vrrp-inet6-group <*> no-preempt",
                       "set interfaces irb unit <*> family inet6 address <*> vrrp-inet6-group <*> accept-data",
                       "set interfaces irb unit <*> family inet6 address <*> vrrp-inet6-group <*> track interface irb.1078 priority-cost 20",] ],
  'golden_config_delimiter' => ["vrrp-inet6-group","unit"]
  'duplicate1_multiplier' => 2,
  'duplicate1_sideA' = {'match' => "set interfaces irb unit <*> family inet6 address fe80::1/64\n" , 'configs' => [] },
  'duplicate1_sideB' = {'match' => "set interfaces irb unit <*> family inet6 address fe80::2/64\n" , 'configs' => [] }
  
);

my %config_hash;
my @no_duplicate_search;
my $index;


#load config files and separate routers for duplicate checks
opendir DIR , $workingdir;
@configfiles = readdir DIR;
closedir DIR;

#read in each config file and store in a hash of arrays keyed by filename without \n's or white space
foreach my $file(@configfiles) {

#seperate D19 and D29 routers for duplicate address search
  if ($file =~ /D19(re-[0-1])?/) {
    push( @{ $search_hash{'duplicate_sideA'}->{'config'} } , $file );
  }elsif ($file =~ /D29(re-[0-1])?/) {
      push( @{ $search_hash{'duplicate_sideB'}->{'config'} } , $file );
  }else {
      push( @no_duplicate_search , $file);  
  }
  
  open CURRENTFILE, "<./config/$file" or die $!;
  print "processing $file\n";
  sleep 3;
  @current_file = <CURRENTFILE>;
  close CURRENTFILE;
  
  foreach(@current_file) {
	#store config file in an array without spaces line breaks comments or show commands or other garbage
    $config_hash{$file} = [ split(' ' , $_ ) ] unless (($_ =~ /show\b/) || ($_ =~ /\/\*/ && $_ !~ /<.*>/) || ($_ =~ /last\s*commit/) || ( $_ == "#" ) || ($_ == SECRET-DATA));    
  }
  #move array to the right so last element is the number of words in the config file
  unshift @{$config_hash{$file}} , undef; 
}


#split golden config lines by word
my $golden_line_index = 0;
$index = 0;
foreach(@{$config_hash{'golden_config'}}) {
  $index++;
  my @disposable;
  foreach($current_line(@{$_->[$index]}) {
    push( @disposable, split(' ', $current_line);
    $golden_line_index++
  }
  #move first array element to 1 for symetry
  unshift @disposable , undef;
  $search_hash{'golden_config'}[$index] = \@disposable
}


#Begin config audit
my $golden_index = 1;
my $search_index = 0;
my $current_word_inner;
my $golden_matched_lines = 0;
my $matched_words = 0;
my $golden_skip = 0;
my @non_compliant_lines;
my $previous_config_hierarchy;
my $previous_config_object;
my $object_depth = 0;
my $sentence_length = 0;
my $deepest_object;
my @configuration_object;
my @prevoius_configuration_object;

#need to update to record config hierarchy in an array or rewrite in a language with objects

foreach $file(@configfiles) {
  $index=0;
  foreach $current_word(@{$hash{$file}}) {
    $index++;
    $sentence_length++;
    $object_depth++;
    if ($current_word =~ /)
    #save the first and second level config directives
    if (${$config_hash{$file}}[$index+1] == "{") && ($level = 1) && ($level <= $object_depth) {
      @previous_configuration_object = @configuration_object;
      my $first_word = ($index-$sentence_length)+1;
      $configuration_object[$level] = join('' , @{$config_hash{$file}}[$first_word..$index]);
      $sentence_length = 1;
      $object_depth = 1;
    } 
    elsif (${$config_hash{$file}}[$index+1] == "{") && ($level > 1) && ($level <= $object_depth ) {
      my $first_word = ($index-$sentence_length)+1;
      $configuration_object[$level] = join('' , @{$config_hash{$file}}[$first_word..$index]);
    }
    elsif ($current_word == "{" ) {
      $level++;
      $object_depth++;
    }
    elsif ($current_word == "}" ) {
        $level--;
	if ($level < $object_depth  &&  $golden_match != $golden_line_index) {
	  push( @non_compliant_lines , "$config");
	  $golden_skip = 0;
	}

    }
    #compare lines being processed to golden config word by word
    foreach $golden_current_array(@{$config_hash{'golden_config'}}) {
      foreach $search_current(@configuration_object) {
	    foreach $golden_current_word(@{$golden_current_array}) {
		  
		  if ($golden_current_word == "set") {
		    last unless ($config_object[0] == $golden_current->[$$golden_index]->[1] )	
	      }
	      if ($_ == "set" || $_ == "<*>" ){
		    $golden_skip++;
		    next;
		  }
		}
      }
    }
  }
}


@open OUTFILE, ">./results.txt"  or die $!;

close OUTFILE;
#print @found;
