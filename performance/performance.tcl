
package require speedtable

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

PerformanceLog create speedperformance

#
# speedtable_performance_callback - callback function when speedtable
#   performance callbacks are enabled
#
proc speedtable_performance_callback {command count elapsedTime} {
    array set frame [info frame [expr {[info frame] - 1}]]

    logger [format "performance - search at %s line %s returned %d rows and consumed %.6g CPU secs" $frame(file) $frame(line) $count $elapsedTime]
}

#
# speedtable_performance_callback_all - maintain a table for each search
#   (filename and line number) seen and accumulate the number of calls,
#   number of rows returned and amount of CPU time incurred
#
proc speedtable_performance_callback_all {command count elapsedTime} {
    array set frame [info frame [expr {[info frame] - 1}]]

    set key $frame(file):$frame(line)
    array set row [speedperformance array_get $key]
    set row(et) [expr {$row(et) + $elapsedTime}]
    incr row(count) $count
    incr row(calls)
    speedperformance array_set $key [array get row]

    #logger [format "performance - search at %s line %s returned %d rows and consumed %.6g CPU secs" $frame(file) $frame(line) $count $elapsedTime]
}

#
# speedtable_performance_report - emit a report for each speedtable search
#   seen the filename, line number, number of invocations, total number of
#   rows returned and the elapsed CPU time in seconds
#
proc speedtable_performance_report {} {
    speedperformance search -sort -et -array row -code {
	puts [format "%40s %6d %9d %.5g" [split $row(key) :] $row(calls) $row(count) $row(et)]
    }
}

package provide speedtable_performance 1.0
