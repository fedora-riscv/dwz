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

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm gcc
        rlAssertRpm gdb
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "cp something.c cmd.txt $TmpDir"
        rlRun "pushd $TmpDir"
        rlRun "gcc -g -O2 something.c -o something.out"
        rlRun "cp something.out something.dwz"
    rlPhaseEnd

    rlPhaseStartTest "no crash + saved space"
        rlRun "dwz something.dwz"
        rlRun "[[ $(wc -c <something.out) -gt $(wc -c <something.dwz) ]]"
    rlPhaseEnd

    rlPhaseStartTest "can we debug it?"
        rlRun "gdb -x cmd.txt -batch -q ./something.dwz > log 2>&1"
        rlRun "[[ $(grep -c 'hello, world' log) -eq 2 ]]"
        rlAssertGrep '$1 = -1' log
        rlAssertGrep '$2 = 0x2a' log
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
