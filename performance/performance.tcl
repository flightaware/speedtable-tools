
package require speedtable
package require BSD

CTableBuildPath /usr/local/lib/speedtable_performance/stobj

speedtables Speedtable_performance 1.0 {
    table PerformanceLog {
	key key
	double et notnull 1 default 0.0
	int count notnull 1 default 0
	int calls notnull 1 default 0
    }
}

package require Speedtable_performance

namespace eval ::speedtable_performance {

PerformanceLog create speedperformance

#
# callback - callback function when speedtable
#   performance callbacks are enabled
#
proc callback {command count elapsedTime} {
    array set frame [info frame [expr {[info frame] - 1}]]

    logger [format "performance - search at %s line %s returned %d rows and consumed %.6g CPU secs" $frame(file) $frame(line) $count $elapsedTime]
}

#
# callback_all - maintain a table for each search
#   (filename and line number) seen and accumulate the number of calls,
#   number of rows returned and amount of CPU time incurred
#
proc callback_all {command count elapsedTime} {
    variable startCPU

    array set frame [info frame [expr {[info frame] - 1}]]

    if {![info exists startCPU]} {
	array set rusage [::bsd::rusage]

	set startCPU $rusage(userTimeUsed)
    }

    #logger [format "performance - search at %s line %s returned %d rows and consumed %.6g CPU secs" $frame(file) $frame(line) $count $elapsedTime]

    set key $frame(file):$frame(line)
    # make sure the row exists
    speedperformance set $key
    array set row [speedperformance array_get $key]
    set row(et) [expr {$row(et) + $elapsedTime}]
    incr row(count) $count
    incr row(calls)
    speedperformance set $key [array get row]

}

#
# report - emit a report for each speedtable search
#   seen the filename, line number, number of invocations, total number of
#   rows returned and the elapsed CPU time in seconds
#
proc report {} {
    variable startCPU

    if {![info exists startCPU]} {
	return [list]
    }

    array set rusage [::bsd::rusage]
    set endCPU $rusage(userTimeUsed)

    set totalCPU [expr {$endCPU - $startCPU}]

    set report [list]
    speedperformance search -sort -et -array row -code {
	lassign [split $row(key) ":"] file line
	set where "[join [lrange [file split $file] end-1 end] "/"]:$line"
	set propTotal [expr {$row(et) / $totalCPU}]
	lappend report [list $row(calls) $row(count) $row(et) $propTotal $where]
    }

    speedperformance reset
    unset startCPU

    return $report
}

}

package provide speedtable_performance 1.0
