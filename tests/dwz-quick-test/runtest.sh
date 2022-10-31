#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/dwz/dwz-quick-test
#   Description: Quick sanity test
#   Author: Miroslav Franc <mfranc@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2013 Red Hat, Inc. All rights reserved.
#
#   This copyrighted material is made available to anyone wishing
#   to use, modify, copy, or redistribute it subject to the terms
#   and conditions of the GNU General Public License version 2.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public
#   License along with this program; if not, write to the Free
#   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
#   Boston, MA 02110-1301, USA.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Include Beaker environment
. /usr/share/beakerlib/beakerlib.sh || exit 1

export PACKAGE="${PACKAGE:-$(rpm -qf --qf='%{name}\n' `which dwz`)}"
REQUIRES="$PACKAGE gcc glibc gdb"

rlJournalStart
  rlPhaseStartSetup
    rlShowRunningKernel
    rlAssertRpm --all
    rlRun "TmpDir=\$(mktemp -d)"
    rlRun "cp -r testcase.c cmds $TmpDir"
    rlRun "pushd $TmpDir"
    rlRun "gcc -g -O0 -o testcase testcase.c"
    rlRun "cp testcase testcase.dwz"
  rlPhaseEnd

  rlPhaseStartTest
    rlRun "dwz testcase.dwz"
    rlRun "BYTES_BASE_FILE=`wc -c <testcase`"
    rlRun "BYTES_DWZED_FILE=`wc -c <testcase.dwz`"
    [ $BYTES_DWZED_FILE -gt $BYTES_BASE_FILE ] && rlFail "DWZed file should not be greater than the original file."
    rlRun "gdb --command=cmds --quiet --batch testcase.dwz |& tee $TmpDir/testcase.log; test \${PIPESTATUS[0]} -eq 0"
    rlRun "grep 'hello, world' $TmpDir/testcase.log"
    rlRun "grep '\$1 = -1' $TmpDir/testcase.log"
    rlRun "grep '\$2 = 0x2a' $TmpDir/testcase.log"
  rlPhaseEnd

  rlPhaseStartCleanup
    rlRun "popd"
    rlRun "rm -r $TmpDir"
  rlPhaseEnd
rlJournalPrintText
rlJournalEnd
