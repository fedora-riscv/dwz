#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/dwz/Sanity/dwz-testsuite
#   Description: dwz testing by upstream testsuite
#   Author: Michal Kolar <mkolar@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2021 Red Hat, Inc.
#
#   This program is free software: you can redistribute it and/or
#   modify it under the terms of the GNU General Public License as
#   published by the Free Software Foundation, either version 2 of
#   the License, or (at your option) any later version.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE.  See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program. If not, see http://www.gnu.org/licenses/.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Include Beaker environment
. /usr/share/beakerlib/beakerlib.sh || exit 1

BUILD_USER=${BUILD_USER:-dwzbld}
TESTS_COUNT_MIN=${TESTS_COUNT_MIN:-20}
PACKAGE="dwz"
REQUIRES="$PACKAGE rpm-build"
if rlIsFedora; then
  REQUIRES="$REQUIRES dnf-utils"
else
  REQUIRES="$REQUIRES yum-utils"
fi

rlJournalStart
  rlPhaseStartSetup
    rlShowRunningKernel
    rlAssertRpm --all
    rlRun "TmpDir=`mktemp -d`"
    rlRun "pushd $TmpDir"
    rlFetchSrcForInstalled $PACKAGE
    rlRun "useradd -M -N $BUILD_USER" 0,9
    [ "$?" == "0" ] && rlRun "del=yes"
    rlRun "chown -R $BUILD_USER:users $TmpDir"
  rlPhaseEnd

  rlPhaseStartSetup "build dwz"
    rlRun "rpm -D \"_topdir $TmpDir\" -U *.src.rpm"
    rlRun "dnf builddep -y $TmpDir/SPECS/*.spec"
    rlRun "su -c 'rpmbuild -D \"_topdir $TmpDir\" -bp $TmpDir/SPECS/*.spec &>$TmpDir/rpmbuild.log' $BUILD_USER"
    rlRun "rlFileSubmit $TmpDir/rpmbuild.log"
    rlRun "cd $TmpDir/BUILD/dwz"
    rlRun "su -c './configure &>$TmpDir/configure.log' $BUILD_USER"
    rlRun "rlFileSubmit $TmpDir/configure.log"
    rlRun "su -c 'make &>$TmpDir/make.log' $BUILD_USER"
    rlRun "rlFileSubmit $TmpDir/make.log"
    rlRun "ln -fs `which dwz` . && touch dwz"

    # workaround
    [ -f testsuite/dwz.tests/pr24468.sh ] && rlRun "mv testsuite/dwz.tests/pr24468.sh testsuite/dwz.tests/pr24468.sh~" 0 "Disabling pr24468.sh due to bz1893921"
  rlPhaseEnd

  rlPhaseStartTest "run testsuite"
    rlRun "su -c 'make check RUNTESTFLAGS=-a |& tee $TmpDir/testsuite.log; test \${PIPESTATUS[0]} -eq 0' $BUILD_USER"
    rlRun "rlFileSubmit $TmpDir/testsuite.log"
    rlLogInfo "`awk '/=== dwz Summary ===/,0' dwz.sum`"
  rlPhaseEnd

  rlPhaseStartTest "evaluate results"
    rlRun "grep -E '^FAIL:' dwz.sum" 1 "There should be no failure"
    rlRun "tests_count=\$(grep -E '^PASS:' dwz.sum | wc -l)"
    [ "$tests_count" -ge "$TESTS_COUNT_MIN" ] && rlLogInfo "Test counter: $tests_count" || rlFail "Test counter $tests_count should be greater than or equal to $TESTS_COUNT_MIN"
  rlPhaseEnd

  rlPhaseStartCleanup
    rlRun "popd"
    rlRun "rm -r $TmpDir"
    [ "$del" == "yes" ] && rlRun "userdel -f $BUILD_USER"
  rlPhaseEnd
rlJournalPrintText
rlJournalEnd
