jauditor.pl
===========

This is a basic meant to help audit juniper device configs in text format.  
It takes an XML based config file as input.  The file should include the search criteria and a list of files to be
processed.  The script will then run the required searches and output to a file results.txt.  An example config file is 
included for reference.

Version 1.0
============
regex - similar to grep.  Takes a regular expression or text search item and returns all matching lines from all 
files processed.

Golden config - Simple a reverse of the regex.  Takes a list of config terms and an attribute that indicates which
which config objects to process.  It finds each individual object and returns objects that are missing one of the
indicated colden config snippets.  

The golden config search currently only supports interfaces.  Support for different stanza's will be added later.

This is very much a work in progress.  Feel free to comment or fork and contribute.
