#!/usr/bin/perl -w

use strict;

my %messages = ();
my ($msgid,$from,$to,$size);
my $debugging = 1;

while (<>) {
  chomp;

  if (m!postfix/qmgr\[\d+\]: (\w+): from=<(.*)>, size=(\d+)!) {
    $msgid = $1;    $from = lc $2;    $size = $3;
    $messages{$msgid} = {} unless exists $messages{$msgid};
    $messages{$msgid}->{'from'} = $from;
    $messages{$msgid}->{'size'} = $size;
  } 
  elsif (m!postfix/smtp\[\d+\]: (\w+): to=<(.*)>,!) {
    $msgid = $1;   $to = lc $2;
    $messages{$msgid} = {} unless exists $messages{$msgid};
    $messages{$msgid}->{'to'} = $to;
  }
  elsif (m!postfix/local\[\d+\]: (\w+): to=<(.*)>,!) {
    $msgid = $1;   $to = lc $2;
    $messages{$msgid} = {} unless exists $messages{$msgid};
    $messages{$msgid}->{'to'} = $to;
  }
  elsif (m!postfix/smtpd!) {
    # probably just information
  } 
  elsif (m!postfix/cleanup!) {
    # anything??
  }
  elsif (m!postfix/pickup!) {
    # ... ?
  }
  elsif (m!postfix-script: refreshing!) {
    # ... ?
  }
  elsif (m!postfix/master!) {
    # ... ?
  }
  elsif (m!postfix/smtp.*Connection refused!) {
    # not interested for this report
  }
  elsif (m!postfix/smtp.*Operation timed out!) {
    # not interested for this report
  }
  elsif (m!postfix/smtp.*server dropped connection!) {
    # not interested for this report
  }
  elsif (m!postfix/qmgr\[\d+\]: table has changed -- exiting!) {
    # boring
  }
  elsif (m!newsyslog\[\d+\]: logfile turned over!) {
    # mmm,  fascinating
  }
  elsif (m!cucipop!) {
    # really unimportant
  }
  else {
    print STDERR "MISUNDERSTOOD LINE: $_\n";
  }
}

my %domain = ();
my $messages;
my $total;
my $thisdomain;
foreach $msgid (keys %messages) {
  $to = $messages{$msgid}->{'to'};
  $from = $messages{$msgid}->{'from'};
  $size = $messages{$msgid}->{'size'};
  if ($to !~ /@(.*)$/) {
    print STDERR "$to (message id $msgid) is not an email address?\n";
    next;
  }
  $thisdomain = $1;
#  next if $thisdomain =~ /ifost.org.au/;
  next if $from =~ /ifost.org.au/;
  next if $to =~ /webmail.ifost.org.au/;
  $domain{$thisdomain} = { 'bandwidth' => 0, 'messages' => [] }
                                  unless exists $domain{$thisdomain};
  $total = $domain{$thisdomain}->{'bandwidth'};
  $messages = $domain{$thisdomain}->{'messages'};
  $total += $size;
  @$messages = (@$messages,"$msgid: $size bytes from $from to $to");
  $domain{$thisdomain}->{'bandwidth'} = $total;  
}




foreach $thisdomain (keys %domain) {
  print "Summary of Bandwidth Usage for $thisdomain ";
  $total = $domain{$thisdomain}->{'bandwidth'};
  print " Bytes: $total\n";
  $messages = $domain{$thisdomain}->{'messages'};
  foreach $msgid (@$messages) {
    print "   $msgid\n";
  }
  print "\n\n\n";
}
