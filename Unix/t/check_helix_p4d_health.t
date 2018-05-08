#!/usr/bin/perl -w
###############################################################################
# Copyright (c) Perforce Software, Inc., 2007-2016. All rights reserved
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1  Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 
# 2.  Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL PERFORCE
# SOFTWARE, INC. BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR 
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF 
# THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
# DAMAGE.
###############################################################################
# Description:
#
# Simple perl test suite to exercise the P4Nagios plugin.
#
# Usage:
#
# This perl script is intended to be run from the directory above. For
# example:
# cd Nagios/Unix
# perl t/check_helix_p4d_health.t
#
# Dependencies:
#
# P4D must be in the path
# P4 must be in the path
#
# Last Modified: $Date: 2016/04/01 $
# Submitted by: $Author: karl_wirth $
# Revision: $Revision: #1 $
#
###############################################################################

    use File::Path 'rmtree';  

    use Test::Simple tests => 37;

    # Variable setup
    $ENV{P4CONFIG}='.p4config';
    $ROOT=$ENV{PWD};
    $TSTROOT=$ROOT."/t/tmp";
    $MASTER=$TSTROOT."/master";
    $EDGE=$TSTROOT."/edge";
    $LIVE_SERVER="workshop.perforce.com:1666";
    $SCRIPT=$ROOT."/check_helix_p4d_health";

    # Test for P4 and P4D in path
    `p4 -V` || die "---> p4 not found in path. Please install p4 and try again. Tests aborting!";
    `p4d -V` || die "---> p4d not found in path. Please install p4d and try again. Tests aborting!";
    `$SCRIPT --help` || die "---> Script not found or not executable. This test should be run from \nthe 'Unix' directory using:\n  perl t/check_helix_p4d_health.t\n";
    `p4d -V >&2`;

    # Directory setup
    system("mkdir -p $MASTER");
    system("mkdir -p $EDGE");

    #Setup the replicas
    chdir $MASTER;
    system("echo master>server.id");
    system("p4d -r $MASTER -jr $MASTER/../../checkpoint.2012.2");
    system("p4d -r $MASTER -xu");
    system("p4d -r $MASTER -J $MASTER/journal -L $MASTER/log -In master -p 1234 &");
    chdir $EDGE;
    system("p4d -r $EDGE -jr $EDGE/../../checkpoint.2012.2");
    system("p4d -r $EDGE -xu");
    system("echo replica>server.id");
    system("p4d -J $EDGE/journal -L $EDGE/log -r $EDGE -p 1235 &");
    sleep(5);
    system("echo password|p4 -p 1234 -u serviceUser login");
    system("echo password|p4 -p 1234 -u operator login");
    system("echo password|p4 -p 1235 -u operator login");

    ## TESTS ##

    $NAME="Unknown argument";
    $EXPECTED="Unknown argument:";
    $CMD=$SCRIPT." -p 1234 --xxxxxx";
    $RESPONSE=`$CMD`;
    if (ok($RESPONSE =~ /$EXPECTED/,$NAME) == 0 ){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }

    $NAME="Missing argument end";
    $EXPECTED="Unknown argument:";
    $CMD=$SCRIPT." -p 1234 --licensecheck --licthreshold";
    $RESPONSE=`$CMD`;
    if (ok($RESPONSE =~ /$EXPECTED/,$NAME) == 0 ){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }

    $NAME="Missing argument middle";
    $EXPECTED="Unknown argument:";
    $CMD=$SCRIPT." --licensecheck --licthreshold -p 1234";
    $RESPONSE=`$CMD`;
    if (ok($RESPONSE =~ /$EXPECTED/,$NAME) == 0 ){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }

    $NAME="Missing argument License";
    $EXPECTED="Unknown argument:";
    $CMD=$SCRIPT." --licensecheck --licthreshold";
    $RESPONSE=`$CMD`;
    if (ok($RESPONSE =~ /$EXPECTED/,$NAME) == 0 ){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }

    $NAME="Missing argument Monitor";
    $EXPECTED="Unknown argument:";
    $CMD=$SCRIPT." --p4monitorcheck --monthreshold";
    $RESPONSE=`$CMD`;
    if (ok($RESPONSE =~ /$EXPECTED/,$NAME) == 0 ){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }

    $NAME="Missing argument Disk";
    $EXPECTED="Unknown argument:";
    $CMD=$SCRIPT." --p4diskcheck --diskthreshold";
    $RESPONSE=`$CMD`;
    if (ok($RESPONSE =~ /$EXPECTED/,$NAME) == 0 ){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }

    $NAME="Missing argument PID";
    $EXPECTED="Unknown argument:";
    $CMD=$SCRIPT." --p4pidcheck --pidthreshold";
    $RESPONSE=`$CMD`;
    if (ok($RESPONSE =~ /$EXPECTED/,$NAME) == 0 ){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }

    $NAME="P4D Not Running";
    $EXPECTED="CRITICAL: P4D server not responding!";
    $CMD=$SCRIPT." -p 1111";
    $RESPONSE=`$CMD`;
    if (ok($RESPONSE =~ /$EXPECTED/,$NAME) == 0 ){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }

    $NAME="P4D Running";
    $EXPECTED="OK";
    $CMD=$SCRIPT." -p 1234";
    $RESPONSE=`$CMD`;
    $RESPONSE=~ s/\R//g;
    if (ok($RESPONSE eq $EXPECTED,$NAME) == 0){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }

    $NAME="Unlicensed";
    chdir $MASTER;
    $EXPECTED="is unlicensed";
    $CMD=$SCRIPT." -p 1234 --licensecheck";
    $RESPONSE=`$CMD`;
    if (ok($RESPONSE =~ /$EXPECTED/,$NAME) == 0 ){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }   


    $NAME="Licensed";
    chdir $MASTER;
    $EXPECTED="OK";
    $CMD=$SCRIPT." -p ".$LIVE_SERVER." --licensecheck";
    $RESPONSE=`$CMD`;
    $RESPONSE=~ s/\R//g;
    if (ok($RESPONSE eq $EXPECTED,$NAME) == 0){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }

    $NAME="Licensed Expiry";
    chdir $MASTER;
    $EXPECTED="WARNING: License expires in";
    $CMD=$SCRIPT." -p ".$LIVE_SERVER." --licensecheck --licthreshold 999";
    $RESPONSE=`$CMD`;
    if (ok($RESPONSE =~ /$EXPECTED/,$NAME) == 0 ){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }   

    $NAME="PID count Pass";
    chdir $MASTER;
    $EXPECTED="OK";
    $CMD=$SCRIPT." -p 1234 --pidcheck";
    $RESPONSE=`$CMD`;
    $RESPONSE=~ s/\R//g;
    if (ok($RESPONSE eq $EXPECTED,$NAME) == 0){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }

    $NAME="PID count Fail";
    chdir $MASTER;
    $EXPECTED="pids exceeded threshold";
    $CMD=$SCRIPT." -p 1234 --pidcheck --pidthreshold 0";
    $RESPONSE=`$CMD`;
    if (ok($RESPONSE =~ /$EXPECTED/,$NAME) == 0 ){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }   


    $NAME="P4 monitor not enabled";
    chdir $MASTER;
    $EXPECTED="p4 monitor not enabled on this system.";
    $CMD=$SCRIPT." -u IDONTEXIST -p 1234 --p4monitorcheck";
    $RESPONSE=`$CMD`;
    if (ok($RESPONSE =~ /$EXPECTED/,$NAME) == 0 ){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }   


    # Switch monitoring on
    system("p4 -p 1234 -u super configure set monitor=1");

    $NAME="P4 monitor Invalid user";
    chdir $MASTER;
    $EXPECTED="using invalid P4USER";
    $CMD=$SCRIPT." -u IDONTEXIST -p 1234 --p4monitorcheck";
    $RESPONSE=`$CMD`;
    if (ok($RESPONSE =~ /$EXPECTED/,$NAME) == 0 ){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }   


    $NAME="P4 monitor Unauthorised user";
    chdir $MASTER;
    $EXPECTED="does not have permissions to run";
    $CMD=$SCRIPT." -u test -p 1234 --p4monitorcheck";
    $RESPONSE=`$CMD`;
    if (ok($RESPONSE =~ /$EXPECTED/,$NAME) == 0 ){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }   


    $NAME="P4 monitor count Pass";
    chdir $MASTER;
    $EXPECTED="OK";
    $CMD=$SCRIPT." -u operator -p 1234 --p4monitorcheck";
    $RESPONSE=`$CMD`;
    $RESPONSE=~ s/\R//g;
    if (ok($RESPONSE eq $EXPECTED,$NAME) == 0){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }

    $NAME="P4 monitor count Fail";
    chdir $MASTER;
    $EXPECTED="running p4d commands exceeded threshold";
    $CMD=$SCRIPT." -u operator -p 1234 --p4monitorcheck --monthreshold 0";
    $RESPONSE=`$CMD`;
    if (ok($RESPONSE =~ /$EXPECTED/,$NAME) == 0 ){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }   

    $NAME="P4 diskcheck Pass";
    chdir $MASTER;
    $EXPECTED="OK";
    $CMD=$SCRIPT." -u operator -p 1234 --p4diskcheck --diskthreshold 99";
    $RESPONSE=`$CMD`;
    if (ok($RESPONSE =~ /$EXPECTED/,$NAME) == 0 ){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }   


    $NAME="P4 diskcheck Fail";
    chdir $MASTER;
    $EXPECTED="WARNING: Disk space too low for P4D";
    $CMD=$SCRIPT." -p 1234 -u operator --p4diskcheck --diskthreshold 10";
    $RESPONSE=`$CMD`;
    if (ok($RESPONSE =~ /$EXPECTED/,$NAME) == 0 ){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }   

    $NAME="P4 diskcheck Invalid User";
    chdir $MASTER;
    $EXPECTED="Disk check using invalid P4USER";
    $CMD=$SCRIPT." -p 1234 --p4diskcheck --diskthreshold 10 -u IDONTEXIST";
    $RESPONSE=`$CMD`;
    if (ok($RESPONSE =~ /$EXPECTED/,$NAME) == 0 ){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }   

    $NAME="P4 diskcheck Unauthorised";
    chdir $MASTER;
    $EXPECTED="not have permissions";
    $CMD=$SCRIPT." -p 1234 --p4diskcheck --diskthreshold 0 -u test";
    $RESPONSE=`$CMD`;
    if (ok($RESPONSE =~ /$EXPECTED/,$NAME) == 0 ){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }   

    $NAME="Replication Test Ignored on master Pass";
    $EXPECTED="OK";
    $CMD=$SCRIPT." -u operator --p4repcheck -p 1234";
    $RESPONSE=`$CMD`;
    $RESPONSE=~ s/\R//g;
    if (ok($RESPONSE eq $EXPECTED,$NAME) == 0){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }

    $NAME="Replication Pass";
    $EXPECTED="OK";
    $CMD=$SCRIPT." -u operator --p4repcheck -p 1235";
    $RESPONSE=`$CMD`;  
    $RESPONSE=~ s/\R//g;
    if (ok($RESPONSE eq $EXPECTED,$NAME) == 0){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }

    $NAME="Replication Fail - serviceUser logged out";
    system("p4 -p 1234 -u serviceUser logout");
    chdir $EDGE;
    $EXPECTED="CRITICAL: Replication user is no longer logged in.";
    $CMD=$SCRIPT." -u operator --p4repcheck -p 1235";
    $RESPONSE=`$CMD`;
    if (ok($RESPONSE =~ /$EXPECTED/,$NAME) == 0 ){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }   
    system("echo password|p4 -p 1234 -u serviceUser login");

    # Break replica
    $NAME="Replication Fail - journal missing";
    system("p4d -r $EDGE \"-cset replica#P4TARGET=localhost:1111\"");
    sleep 2;
    $EXPECTED="CRITICAL: Master server is not available.";
    $CMD=$SCRIPT." -u operator --p4repcheck -p 1235";
    $RESPONSE=`$CMD`;
    if (ok($RESPONSE =~ /$EXPECTED/,$NAME) == 0 ){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }   
 
    # Fix replica
    chdir $EDGE;
    system("p4d -r $EDGE \"-cset replica#P4TARGET=localhost:1234\"");
    sleep 5;

    # Operator logged out tests
    system("p4 -p 1235 -u operator logout");
    $NAME="All logged out";
    $EXPECTED="WARNING: Disk check P4D user operator is not logged in.";
    $CMD=$SCRIPT." -u operator --all -p 1235";
    $RESPONSE=`$CMD`;
    $RESPONSE=~ s/\R//g;
    if (ok($RESPONSE eq $EXPECTED,$NAME) == 0){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }   

    $NAME="Disk check logged out";
    $EXPECTED="WARNING: Disk check P4D user operator is not logged in.";
    $CMD=$SCRIPT." -u operator --p4diskcheck -p 1235";
    $RESPONSE=`$CMD`;
    $RESPONSE=~ s/\R//g;
    if (ok($RESPONSE eq $EXPECTED,$NAME) == 0){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }   

    $NAME="Disk check logged out, use -P instead, invalid password";
    $EXPECTED="WARNING: Disk check P4D user operator is not logged in.";
    $CMD=$SCRIPT." -u operator --p4diskcheck --diskthreshold 99 -p 1235 -P XXXXXX";
    $RESPONSE=`$CMD`;
    $RESPONSE=~ s/\R//g;
    if (ok($RESPONSE eq $EXPECTED,$NAME) == 0){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }   

    $NAME="Disk check logged out, use -P instead, valid password";
    $EXPECTED="OK";
    $CMD=$SCRIPT." -u operator --p4diskcheck --diskthreshold 99 -p 1235 -P password";
    $RESPONSE=`$CMD`;
    $RESPONSE=~ s/\R//g;
    if (ok($RESPONSE eq $EXPECTED,$NAME) == 0){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }   

    $NAME="Monitor check logged out";
    $EXPECTED="WARNING: Monitor check P4D user operator is not logged in.";
    $CMD=$SCRIPT." -u operator --p4monitorcheck -p 1235";
    $RESPONSE=`$CMD`;
    $RESPONSE=~ s/\R//g;
    if (ok($RESPONSE eq $EXPECTED,$NAME) == 0){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }   

    $NAME="Replication check logged out";
    $EXPECTED="WARNING: Replication check P4D user operator is not logged in.";
    $CMD=$SCRIPT." -u operator --p4repcheck -p 1235";
    $RESPONSE=`$CMD`;
    $RESPONSE=~ s/\R//g;
    if (ok($RESPONSE eq $EXPECTED,$NAME) == 0){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }   

    # Log back in
    system("echo password|p4 -p 1235 -u operator login");

    $NAME="Connect using SSL to non SSL";
    $EXPECTED="WARNING: Need to connect to this P4D without using ssl prefix.";
    $CMD=$SCRIPT." -u operator --all -p ssl:localhost:1235";
    $RESPONSE=`$CMD`;
    $RESPONSE=~ s/\R//g;
    if (ok($RESPONSE eq $EXPECTED,$NAME) == 0){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }   

    system("p4 -u super -p 1235 admin stop");
    chdir $EDGE;
    system("mkdir $EDGE/p4ssldir");
    system("chmod 700 $EDGE/p4ssldir");
    $ENV{P4SSLDIR}="$EDGE/p4ssldir";
    system("p4d -r $EDGE -Gc");
    system("p4d -J $EDGE/journal -L $EDGE/log -r $EDGE -p ssl:localhost:1235 &");
    sleep 5;

    $NAME="Connect using SSL Untrusted";
    $EXPECTED="WARNING: User running P4D check needs to trust this P4D server.";
    $CMD=$SCRIPT." -u operator --all -p ssl:localhost:1235";
    $RESPONSE=`$CMD`;
    $RESPONSE=~ s/\R//g;
    if (ok($RESPONSE eq $EXPECTED,$NAME) == 0){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }   

    $NAME="Connect using SSL trust file missing";
    $EXPECTED="User running P4D check needs to trust this P4D server.";
    $CMD=$SCRIPT." -u operator -p ssl:localhost:1235 -T $EDGE/foo";
    $RESPONSE=`$CMD`;
    if (ok($RESPONSE =~ /$EXPECTED/,$NAME) == 0 ){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }   

    $ENV{P4TRUST}="$EDGE/.p4trust";
    system("p4 -p ssl:localhost:1235 trust -y -f");
    system("echo password|p4 -p ssl:localhost:1235 -u operator login");
    $NAME="Connect using SSL trust file available";
    $EXPECTED="OK";
    $CMD=$SCRIPT." -u operator -p ssl:localhost:1235 -T $EDGE/.p4trust";
    $RESPONSE=`$CMD`;
    $RESPONSE=~ s/\R//g;
    if (ok($RESPONSE eq $EXPECTED,$NAME) == 0){
       print "$CMD\nExpecting --> ".$EXPECTED." Got --> ".$RESPONSE;
    }   
 
    # Clean up
    system("p4 -u super -p 1234 admin stop");
    system("p4 -u super -p ssl:localhost:1235 admin stop");
    sleep 5;

    chdir $ROOT;
    `rm -rf $TSTROOT`;
