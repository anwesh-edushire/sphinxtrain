#!/usr/bin/perl
## ====================================================================
##
## Copyright (c) 1996-2000 Carnegie Mellon University.  All rights 
## reserved.
##
## Redistribution and use in source and binary forms, with or without
## modification, are permitted provided that the following conditions
## are met:
##
## 1. Redistributions of source code must retain the above copyright
##    notice, this list of conditions and the following disclaimer. 
##
## 2. Redistributions in binary form must reproduce the above copyright
##    notice, this list of conditions and the following disclaimer in
##    the documentation and/or other materials provided with the
##    distribution.
##
## This work was supported in part by funding from the Defense Advanced 
## Research Projects Agency and the National Science Foundation of the 
## United States of America, and the CMU Sphinx Speech Consortium.
##
## THIS SOFTWARE IS PROVIDED BY CARNEGIE MELLON UNIVERSITY ``AS IS'' AND 
## ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
## THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
## PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL CARNEGIE MELLON UNIVERSITY
## NOR ITS EMPLOYEES BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
## SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 
## LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
## DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY 
## THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
## (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
## OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
##
## ====================================================================
##
## Author: Ricky Houghton
##

use strict;
use File::Copy;
use File::Basename;
use File::Spec::Functions;
use File::Path;

use lib catdir(dirname($0), updir(), 'lib');
use SphinxTrain::Config;
use SphinxTrain::Util;

#*************************************************************************
# This script runs the build_tree script for each state of each basephone
#*************************************************************************

my ($phone,$state);
my $return_value = 0;
my $scriptdir = "$ST::CFG_SCRIPT_DIR/05.buildtrees";
my $logdir = "${ST::CFG_LOG_DIR}/05.buildtrees";
Log ("MODULE: 05 Build Trees\n");
Log ("    Cleaning up old log files...\n");
rmtree ("$logdir");
mkdir ($logdir,0777) unless -d $logdir;

$| = 1; # Turn on autoflushing
if (RunScript('make_questions.pl')) {
  $return_value = 1;
  exit ($return_value);
}

Log ("    Tree building\n");

my $mdef_file       = "${ST::CFG_BASE_DIR}/model_architecture/${ST::CFG_EXPTNAME}.untied.mdef";
my $mixture_wt_file = "${ST::CFG_BASE_DIR}/model_parameters/${ST::CFG_EXPTNAME}.cd_${ST::CFG_DIRLABEL}_untied/mixture_weights";
my $tree_base_dir   = "${ST::CFG_BASE_DIR}/trees";
my $unprunedtreedir = "$tree_base_dir/${ST::CFG_EXPTNAME}.unpruned";
mkdir ($tree_base_dir,0777) unless -d $tree_base_dir;
mkdir ($unprunedtreedir,0777) unless -d $unprunedtreedir;

# For every phone submit each possible state
Log ("\tProcessing each phone with each state\n");
open INPUT,"${ST::CFG_RAWPHONEFILE}";
my @jobs;
foreach $phone (<INPUT>) {
    chomp $phone;
    if (($phone =~ m/^(\+).*(\+)$/) || ($phone =~ m/^SIL$/)) {
	Log ("        Skipping $phone\n");
	next;
    }

    push @jobs, [$phone => LaunchScript("tree.$phone", ['buildtree.pl', $phone])];
}
close INPUT;

# Wait for all the phones to finish
# It doesn't really matter what order we do this in
foreach (@jobs) {
    my ($phone,$job) = @$_;
    WaitForScript($job);
    print "$phone ";
}
print "\n";

exit ($return_value);
