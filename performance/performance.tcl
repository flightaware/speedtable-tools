
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

#
# register - register one or more tables for a performance callback to
#  the specified routine if ET is above the specified threshold
#
proc register {tables minET callback} {
    foreach table $tables {
	$table performance_callback $minET $callback
    }
}

#
# safe_register - register one or more tables for a performance callback to
#  the specified routine if ET is above the specified threshold
#
# don't error if any fail, just log and keep going
#
# return 1 if all tables registered successfully, 0 if one or more had a problem
#
proc safe_register {tables minET callback} {
    set result 1
    foreach table $tables {
	if {[catch {$table performance_callback $minET $callback} catchResult]} {
	    fa_logger info "failed to register $table for performance callback: $catchResult, continuing..."
	    set result 0
	}
    }
    return $result
}

} ;# namespace ::speedtable_performance

package provide speedtable_performance 1.0
