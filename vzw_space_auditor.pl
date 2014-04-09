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
#golden config is stored in an array of arrays in $search_hash['golden_config']  If they share a stanza or feature it should be 
#included in the $search_hash['golden_config_delimiter'] array so the script can tell if the feature is misconfigured or 
#not configured at all.

#duplicate address detection is handled in much the same way
#the line or lines to be checked are stored as scalar in keyed as $search_hash["duplicate\d_side\w"] with a new number for each pair/set of duplicates
# and a letter to mark which lines will be checked against which device configs (for example odd routers in a vrrp pair)
#the number of config sets is recorded in $search_hash['duplicate_multiplier'] 
#(for example 3 to search for one of 3 lines duplicated in each of 3 border routers)

#in the future look to move the config to a separate file and possibly keep a record of all possible config features to make feature check
#automatic

my %search_hash = (
  'golden_config'  => [ [
                       "set interfaces irb unit <*> family inet6 address <*> vrrp-inet6-group <*> virtual-inet6-address <*>",
                       "set interfaces irb unit <*> family inet6 address <*> vrrp-inet6-group <*> virtual-link-local-address <*>",
                       "set interfaces irb unit <*> family inet6 address <*> vrrp-inet6-group <*> priority <*>",
                       "set interfaces irb unit <*> family inet6 address <*> vrrp-inet6-group <*> no-preempt",
                       "set interfaces irb unit <*> family inet6 address <*> vrrp-inet6-group <*> accept-data",
                       "set interfaces irb unit <*> family inet6 address <*> vrrp-inet6-group <*> track interface irb.1078 priority-cost 20"
                      ] ],
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
  
  open CURRENTFILE, '<:crlf' , "<./config/$file" or die $!;
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
my @golden_line_length;
$index = 0;
foreach(@{$config_hash{'golden_config'}}) {
  $index++;
  my @disposable;
  foreach($current_line(@{$_->[$index]}) {
    push( @disposable, split(' ', $current_line);
    $golden_line_length[$index] = $#disposable;
    $golden_line_index++;
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
my $golden_index_sync = 0;
my $golden_skip = 0;
my $golden_searched_objects = 0;
my $golden_missing = 0;
my $golden_misconfigured = 0;
my $which_golden =0;
my @non_compliant_lines;
my $previous_config_hierarchy;
my $previous_config_object;
my $object_depth = 0;
my $sentence_length = 0;
my @object_length;
my @previous_object_length;
my $deepest_object;
my @config_object;
my @prevoius_config_object;

#need to update to record config hierarchy in an array or rewrite in a language with objects
#process config file in array separated by spaces.  Separate configuration items by place in the hierarchy by finding the brackets.
#a counter is kept for the $level in the hierarchy of the config in general and the $object_depth for how deep the current object is.
#An array of counters @object_length is kept for the number of words used to describe each level in the hierarchy.  This is to compensate
#for config items with more than one word before the open braket example: "route 66.174.110.63/32 {".  Both words describe a single object.
#

foreach $file(@configfiles) {
  $index=0;
  $my @line;
  foreach $current_word(@{$hash{$file}}) {
    $index++;
    $object_depth++;
    $object_length[$level]++;
    if ($current_word =~ /)
    #save the first and second level config directives
    if (${$config_hash{$file}}[$index+1] == "{") && ($level = 0) && ($level <= $object_depth) {
      @previous_object_length = @object_length;
      @previous_config_object = @config_object;
      my $first_word = ($index-$object_length[$level])+1;
      $config_object[$level] = push(@config_object , @{$config_hash{$file}}[$first_word..$index];
      $object_depth = 0;
    } 
    elsif (${$config_hash{$file}}[$index+1] == "{") && ($level > 1) && ($level <= $object_depth ) {
      my $first_word = ($index-$object_length[$level])+1;
      $config_object[$level] = push(@config_object , @{$config_hash{$file}}[$first_word..$index]);
    }
    elsif ($current_word == "{" ) {
      $level++;
      $object_depth++;
    }
    elsif ($current_word == "}" ) {
        $level--;
	push (@line , $current_word);

	if ($level < $object_depth  &&  $golden_match != $golden_line_index) {
	  push(@non_compliant_lines , "$config");
	  $golden_skip = 0;
	}

    }
    #compare lines being processed to golden config word by word
    #outer array moves through arrays of golden config snippets
    #next array moves through the router config one word at a time
    #the inner config moves through the current array of golden config snippets one word at a time
    #comparisons are recoreded using several counters
    #$golden_skip = "number of 'set' or '<*>' occurances" $matched_words = "matched words" 
    #@golden_line_length "an array recording the number of words in a golden config line"
  
    foreach $golden_current_array(@{$config_hash{'golden_config'}}) {
      foreach $search_current(@config_object) {
	    foreach $golden_current_word(@{$golden_current_array}) {
		  $golden_missing = 1 if $golden_current_word = ${$config_hash{'golden_config_delimiter'}}[$which_golden];
		  if ($golden_current_word == "set" && $matched_words = 0) {
		    last unless ($config_object[0] == $golden_current->[$golden_index]->[1] )
		    $golden_skip++;
		    next;
	      } 
	      elsif ($golden_current_word == $search_current) {
            $matched_words++;
		    next;
          }
	      elsif ($golden_current_word == "<*>" ){
		    $golden_skip++;
		    next;
		  }
          elsif ($golden_current_word != $search_current && $golden_current_word == "set" && $matched_words > 0)  {
	        $golden_matched_lines++ if ($matched_words == $golden_line_length[$golden_index_sync] );
            $matched_words = 0;
            $golden_index_sync++;
		    next;
          }	      
		}
      }
    }
  }
}


open OUTFILE, ">./results.txt"  or die $!;

close OUTFILE;
#print @found;
