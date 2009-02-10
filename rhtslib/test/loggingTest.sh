# Copyright (c) 2006 Red Hat, Inc. All rights reserved. This copyrighted material 
# is made available to anyone wishing to use, modify, copy, or
# redistribute it subject to the terms and conditions of the GNU General
# Public License v.2.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# Author: Jan Hutar <jhutar@redhat.com>

__testLogFce() {
  # This should help us to test various logging functions
  # which takes <message> and optional <logfile> parameters
  local log=$( mktemp )
  local myfce=$1
  $myfce "MessageABC" &>/dev/null
  assertTrue "rlHeadLog to OUTPUTFILE" "grep -q 'MessageABC' $OUTPUTFILE"
  rm -f $log   # remove the log, so it have to be created
  $myfce "MessageDEF" $log &>/dev/null
  assertTrue "rlHeadLog to nonexisting log" "grep -q 'MessageDEF' $log"
  touch $log   # create the log if it still do not exists
  $myfce "MessageGHI" $log &>/dev/null
  assertTrue "rlHeadLog to existing log" "grep -q 'MessageGHI' $log"
  $myfce "MessageJKL" $log &>/dev/null
  assertTrue "rlHeadLog only adds to the log (do not overwrite it)" "grep -q 'MessageGHI' $log"
  assertTrue "rlHeadLog adds to the log" "grep -q 'MessageJKL' $log"
  assertTrue "$myfce logs to STDOUT" "$myfce $myfce-MNO |grep -q '$myfce-MNO'"
  assertTrue "$myfce creates journal entry" "rlPrintJournal |grep -q '$myfce-MNO'"
}

test_rlHeadLog() {
  __testLogFce rlHeadLog
}

test_rlLog() {
  __testLogFce rlLog
}
test_rlLogDebug() {
  #only works when DEBUG is set
  DEBUG=1
  __testLogFce rlLogDebug
  DEBUG=0
}
test_rlLogInfo() {
  __testLogFce rlLogInfo
}
test_rlLogWarning() {
  __testLogFce rlLogWarning
}
test_rlLogError() {
  __testLogFce rlLogError
}
test_rlLogFatal() {
  __testLogFce rlLogFatal
}

test_rlDie(){
	#dunno how to test this - it contains untestable helpers like rlBundleLogs and rlReport
	echo "rlDie skipped"
}

test_rlPhaseStartEnd(){
  rlStartJournal ; rlPhaseStart FAIL
  #counting passes and failures
  rlAssert0 "failed assert #1" 1
  rlAssert0 "successfull assert #1" 0
  rlAssert0 "failed assert #2" 1
  rlAssert0 "successfull assert #2" 0
  assertTrue "passed asserts were stored" "rlCreateLogFromJournal |grep '2 good'"
  assertTrue "failed asserts were stored" "rlCreateLogFromJournal |grep '2 bad'"
  #new phase resets score
  rlPhaseEnd ; rlPhaseStart FAIL
  assertTrue "passed asserts were reseted" "rlCreateLogFromJournal |grep '0 good'"
  assertTrue "failed asserts were reseted" "rlCreateLogFromJournal |grep '0 bad'"

  assertTrue "creating phase without type doesn't succeed" "rlPhaseEnd ; rlPhaseStart"
  assertFalse "phase without type is not inserted into journal" "rlPrintJournal |grep -q '<phase.*type=\"\"'"
  assertTrue "creating phase with unknown type doesn't succeed" "rlPhaseEnd ; rlPhaseStart ZBRDLENI"
  assertFalse "phase with unknown type is not inserted into journal" "rlPrintJournal |grep -q '<phase.*type=\"ZBRDLENI\"'"
}

test_rlPhaseStartShortcuts(){
  rlStartJournal
  rlPhaseStartSetup
  assertTrue "setup phase with ABORT type found in journal" "rlPrintJournal |grep -q '<phase.*type=\"ABORT\"'"

  rlStartJournal
  rlPhaseStartTest
  assertTrue "test phase with FAIL type found in journal" "rlPrintJournal |grep -q '<phase.*type=\"FAIL\"'"

  rlStartJournal
  rlPhaseStartCleanup
  assertTrue "clean-up phase with WARN type found in journal" "rlPrintJournal |grep -q '<phase.*type=\"WARN\"'"
}

test_LogLowHighMetric(){
  rlStartJournal ; rlPhaseStart FAIL
  assertTrue "low metric inserted to journal" "rlLogLowMetric metrone 123 "
  assertTrue "high metric inserted to journal" "rlLogHighMetric metrtwo 567"
  assertTrue "low metric found in journal" "rlPrintJournal |grep -q '<metric.*name=\"metrone\".*type=\"low\"'"
  assertTrue "high metric found in journal" "rlPrintJournal |grep -q '<metric.*name=\"metrtwo\".*type=\"high\"'"
}

test_rlShowRunningKernel(){
	rlStartJournal; rlPhaseStart FAIL
	rlShowRunningKernel
	assertTrue "kernel version is logged" "rlCreateLogFromJournal |grep -q `uname -r`"
}

__checkLoggedPkgInfo() {
  local log=$1
  local msg=$2
  local name=$3
  local version=$4
  local release=$5
  local arch=$6
  assertTrue "rlShowPkgVersion logs name $msg" "grep -q '$name' $log"
  assertTrue "rlShowPkgVersion logs version $msg" "grep -q '$version' $log"
  assertTrue "rlShowPkgVersion logs release $msg" "grep -q '$release' $log"
  assertTrue "rlShowPkgVersion logs arch $msg" "grep -q '$arch' $log"
}

test_rlShowPkgVersion() {
  local log=$( mktemp )
  local list=$( mktemp )

  # Exit value shoud be defined
  assertFalse "rlShowPkgVersion calling without options" "rlShowPkgVersion"
  : >$OUTPUTFILE

  rpm -qa --qf "%{NAME}\n" > $list
  local first=$( tail -n 1 $list )
  local first_n=$( rpm -q $first --qf "%{NAME}\n" | tail -n 1 )
  local first_v=$( rpm -q $first --qf "%{VERSION}\n" | tail -n 1 )
  local first_r=$( rpm -q $first --qf "%{RELEASE}\n" | tail -n 1 )
  local first_a=$( rpm -q $first --qf "%{ARCH}\n" | tail -n 1 )

  # Test with 1 package
  rlShowPkgVersion $first &>/dev/null
  __checkLoggedPkgInfo $OUTPUTFILE "of 1 pkg" $first_n $first_v $first_r $first_a
  : >$OUTPUTFILE

  # Test with package this_package_do_not_exist
  assertTrue 'rlShowPkgVersion returns 1 when package do not exists' 'rlShowPkgVersion this_package_do_not_exist; [ $? -eq 1 ]'   # please use "'" - we do not want "$?" to be expanded too early
  assertTrue 'rlShowPkgVersion logs warning about this_package_do_not_exist' "grep -q 'this_package_do_not_exist' $OUTPUTFILE"
  : >$OUTPUTFILE

  # Test with few packages
  local few=$( tail -n 10 $list )
  rlShowPkgVersion $few &>/dev/null
  for one in $few; do
    local one_n=$( rpm -q $one --qf "%{NAME}\n" | tail -n 1 )
    local one_v=$( rpm -q $one --qf "%{VERSION}\n" | tail -n 1 )
    local one_r=$( rpm -q $one --qf "%{RELEASE}\n" | tail -n 1 )
    local one_a=$( rpm -q $one --qf "%{ARCH}\n" | tail -n 1 )
    __checkLoggedPkgInfo $OUTPUTFILE "of few pkgs" $one_n $one_v $one_r $one_a
  done
  : >$OUTPUTFILE

  # Test with package this_package_do_not_exist
  assertTrue 'rlShowPkgVersion returns 1 when some packages do not exists' "rlShowPkgVersion this_package_do_not_exist $few this_package_do_not_exist_too; [ \$? -eq 1 ]"
  : >$OUTPUTFILE

  rm -f $list
}



test_rlGetArch() {
  local out=$(rlGetArch)
  assertTrue 'rlGetArch returns 0' "[ $? -eq 0 ]"
  [ "$out" = 'i386' ] && out='i.8.'   # funny reg exp here
  uname -a | grep -q "$out"
  assertTrue 'rlGetArch returns correct arch' "[ $? -eq 0 ]"
}

test_rlGetDistroRelease() {
  local out=$(rlGetDistroRelease)
  assertTrue 'rlGetDistroRelease returns 0' "[ $? -eq 0 ]"
  grep -q -i "$out" /etc/redhat-release
  assertTrue 'rlGetDistroRelease returns release which is in the /etc/redhat-release' "[ $? -eq 0 ]"
}

test_rlGetDistroVariant() {
  local out=$(rlGetDistroVariant)
  assertTrue 'rlGetDistroVariant returns 0' "[ $? -eq 0 ]"
  grep -q -i "$out" /etc/redhat-release
  assertTrue 'rlGetDistroRelease returns variant which is in the /etc/redhat-release' "[ $? -eq 0 ]"
}



test_rlBundleLogs() {
  # TODO: how to test this one?
  return 0
}

test_LOG_LEVEL(){
	unset LOG_LEVEL
	unset DEBUG

	assertFalse "rlLogInfo msg not in journal dump with default LOG_LEVEL" \
	"rlLogInfo 'lllll' ; rlCreateLogFromJournal |grep 'lllll'"

	assertTrue "rlLogWarning msg in journal dump with default LOG_LEVEL" \
	"rlLogWarning 'wwwwww' ; rlCreateLogFromJournal |grep 'wwwww'"

	DEBUG=1
	assertTrue "rlLogInfo msg  in journal dump with default LOG_LEVEL but DEBUG turned on" \
	"rlLogInfo 'lllll' ; rlCreateLogFromJournal |grep 'lllll'"
	unset DEBUG

	local LOG_LEVEL="INFO"
	assertTrue "rlLogInfo msg in journal dump with LOG_LEVEL=INFO" \
	"rlLogInfo 'lllll' ; rlCreateLogFromJournal |grep 'lllll'"

	local LOG_LEVEL="WARNING"
	assertFalse "rlLogInfo msg not in journal dump with LOG_LEVEL higher than INFO" \
	"rlLogInfo 'lllll' ; rlCreateLogFromJournal |grep 'lllll'"

	unset LOG_LEVEL
	unset DEBUG
}