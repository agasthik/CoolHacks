#!/bin/bash

#PERF JAVA LOG SCRIPT

PERF_LOGDIR="/opt/www/scripts/logs"
BINDADDRESS=`/sbin/ifconfig | grep "inet addr" | grep -v "127.0.0.1" | awk '{print $2}' | cut -d: -f2`
WEB_INSTANCE_NAME="apache"
SERVER_NAME="/opt/www/scripts/usushwsls086lb"
APP_USER1="appuser"




TIME=`date +"%Y/%m/%d,%H:%M:%S"`
CREATE_LOG (){
DATE=`date '+%y%m%d'`
MEM_DATA="$PERF_LOGDIR/MEM${DATE}.csv"
CPU_DATA="$PERF_LOGDIR/CPU${DATE}.csv"
CPU_ALL="$PERF_LOGDIR/CPU_ALL${DATE}.csv"
WEB_LOG="$PERF_LOGDIR/DATA${DATE}.csv"
JVM_LOG="$PERF_LOGDIR/JVM${DATE}.csv"
DB_LOG="$PERF_LOGDIR/DB${DATE}.csv"
}

PRINT_HEADER () {
ARG=$1

case $ARG in
	JVM)
		echo DATE, TIME, FreeMemory, MaxMemory, TotalMemory, Threads >> $PERF_LOGDIR/JVM${DATE}.csv		
		;;
	WEB_LOG)
		echo DATE, TIME, HTTP_CONN, SM_CONN, SM_CONNWAIT, webcount, webcountwait, appcount, appcountwait >> $PERF_LOGDIR/DATA${DATE}.csv		
		;;
	MEM_DATA)
		echo "DATE, Time, TotalMem, UsedMem, FreeMem, SharedMem, BuffersMem, CachedMem, UsedCache, FreeCache, TotalSwap, UsedSwap, FreeSwap" >> $MEM_DATA
		;;
	CPU_DATA)
		echo DATE, TIME, user, nice, system, idle,iowait,load avg >> $CPU_DATA
		;;
	CPU_ALL)
                echo DATE, TIME, CPU0_USER, CPU0_NICE, CPU0_SYSTEM, CPU0_IDLE, CPU0_IOWAIT,CPU1_USER, CPU1_NICE, CPU1_SYSTEM, CPU1_IDLE, CPU1_IOWAIT,CPU2_USER, CPU2_NICE, CPU2_SYSTEM, CPU2_IDLE, CPU2_IOWAIT,CPU3_USER, CPU3_NICE, CPU3_SYSTEM, CPU3_IDLE, CPU3_IOWAIT >> $CPU_ALL
		;;
        DB_LOG)
		echo DATE, TIME, DB_CONN_S041, DB_CONN_S041_EST, DB_CONN_S041_TW, DB_CONN_S042, DB_CONN_S042_EST, DB_CONN_S042_TW, DB_CONN_S085, DB_CONN_S085_EST, DB_CONN_S085_TW, JAVA_PROC >> $PERF_LOGDIR/DB${DATE}.csv
                echo DATE, TIME, DB_CONN_S041, DB_CONN_S041_EST, DB_CONN_S041_TW, DB_CONN_S042, DB_CONN_S042_EST, DB_CONN_S042_TW, DB_CONN_S063, DB_CONN_S063_EST, DB_CONN_S063_TW, JAVA_PROC >> $PERF_LOGDIR2/DB${DATE}.csv
                ;;

	*)
		echo "Wrong usage"
		;;
esac
}

CREATE_LOG
PRINT_HEADER JVM
PRINT_HEADER WEB_LOG
PRINT_HEADER MEM_DATA
PRINT_HEADER CPU_DATA
PRINT_HEADER CPU_ALL
PRINT_HEADER DB_LOG


######### Add Heading to the files #######


while true; do
ROTATE_TIME=`date +%H:%M`
######################### Log  Rotation #############################
if [ $ROTATE_TIME = 09:00 ] 
then
	cp -fr $MEM_DATA $CPU_DATA $CPU_ALL $SERVER_NAME/COMMON
	cp -fr $WEB_LOG $SERVER_NAME/$APP_USER

#####
	CREATE_LOG
	PRINT_HEADER JVM
	PRINT_HEADER WEB_LOG
	PRINT_HEADER MEM_DATA
	PRINT_HEADER CPU_DATA
	PRINT_HEADER CPU_ALL
	PRINT_HEADER DB_LOG

	sleep 60	
else

######################### Put all the data in log files #####################

TIME=`date +"%Y/%m/%d,%H:%M:%S"`
netstat -an > $PERF_LOGDIR/netstat.tmp


################# Data for the Instance  Web / App on this box ###############
HTTP_CONN=`ps ax | grep $WEB_INSTANCE_NAME | wc -l`
SM_CONN=`cat $PERF_LOGDIR/netstat.tmp | grep 44443 | wc -l`
SM_CONNWAIT=`cat $PERF_LOGDIR/netstat.tmp | grep 44443 | grep TIME_WAIT | wc -l`

webcount=`cat $PERF_LOGDIR/netstat.tmp |grep $BINDADDRESS:80 | wc -l`
webcountwait=`cat $PERF_LOGDIR/netstat.tmp |grep $BINDADDRESS:80 | grep TIME_WAIT | wc -l`
appcount=`cat $PERF_LOGDIR/netstat.tmp |grep $BINDADDRESS:8009 | wc -l`
appcountwait=`cat $PERF_LOGDIR/netstat.tmp |grep $BINDADDRESS:8009 | grep TIME_WAIT | wc -l`
echo $TIME, $HTTP_CONN, $SM_CONN, $SM_CONNWAIT, $webcount, $webcountwait, $appcount, $appcountwait >> $PERF_LOGDIR/DATA${DATE}.csv

############# CPU & Memory DATA ##################
echo $TIME"`top -b -n 2 |grep Cpu |sed -n '$p' |awk '{print","$2$4$3$5$6 }' |sed -e 's/%[a-z]*//g'`"`awk -F" " '{print $1}' /proc/loadavg` >>$CPU_DATA
free > $PERF_LOGDIR/free.out
echo "$TIME`cat $PERF_LOGDIR/free.out | grep Mem | awk '{print ","$2","$3","$4","$5","$6","$7}'` `cat $PERF_LOGDIR/free.out | grep buffers/cache | awk '{print ","$3","$4}'` `cat $PERF_LOGDIR/free.out | grep Swap | awk '{print ","$2","$3","$4}'`"  >> $MEM_DATA
#echo "$TIME,`mpstat |sed -n '$p' | awk '{print $4","$5","$6","$10","$7}'`" >> $CPU_ALL
echo "$TIME,`sar -P ALL | grep Average | grep -v all |awk '{print $3","$4","$5","$8", "$6}' | awk '{ORS = ","} {print $1$2$3$4}'`" >> $CPU_ALL


####
TIME=`date +"%Y/%m/%d,%H:%M:%S"`
wget --no-proxy http://$BINDADDRESS:8080/web-console/ServerInfo.jsp
FreeMemory=`grep "Free Memory" ServerInfo.jsp | awk 'BEGIN {FS=">"} {print $5}' | awk '{print $1}'`
MaxMemory=`grep "Max Memory" ServerInfo.jsp | awk 'BEGIN {FS=">"} {print $5}' | awk '{print $1}'`
TotalMemory=`grep "Total Memory" ServerInfo.jsp | awk 'BEGIN {FS=">"} {print $5}' | awk '{print $1}'`
Threads=`grep "Threads" ServerInfo.jsp | awk 'BEGIN {FS=">"} {print $5}' | awk 'BEGIN {FS="<"} {print $1}'`
echo "$TIME, $FreeMemory, $MaxMemory, $TotalMemory, $Threads" >>  $PERF_LOGDIR/JVM${DATE}.csv
rm -rf ServerInfo.jsp*

###   DB

DB_CONN_S041=`cat $PERF_LOGDIR/netstat.tmp | grep 15818 | wc -l`
DB_CONN_S041_EST=`cat $PERF_LOGDIR/netstat.tmp | grep 15818 | grep ESTABLISHED | wc -l`
DB_CONN_S041_TW=`cat $PERF_LOGDIR/netstat.tmp | grep 15818 | grep TIME_WAIT | wc -l`

DB_CONN_S042=`cat $PERF_LOGDIR/netstat.tmp | grep 15823  | wc -l`
DB_CONN_S042_EST=`cat $PERF_LOGDIR/netstat.tmp | grep 15823 | grep ESTABLISHED | wc -l`
DB_CONN_S042_TW=`cat $PERF_LOGDIR/netstat.tmp | grep 15823 | grep TIME_WAIT | wc -l`

DB_CONN_S085=`cat $PERF_LOGDIR/netstat.tmp | grep 15905  | wc -l`
DB_CONN_S085_EST=`cat $PERF_LOGDIR/netstat.tmp | grep 15905 | grep ESTABLISHED | wc -l`
DB_CONN_S085_TW=`cat $PERF_LOGDIR/netstat.tmp | grep 15905 | grep TIME_WAIT | wc -l`

JAVA_PROC=`ps -ef | grep -w $APP_USER1 | grep java | grep -v grep  | wc -l`

echo "$TIME, $DB_CONN_S041, $DB_CONN_S041_EST, $DB_CONN_S041_TW, $DB_CONN_S042, $DB_CONN_S042_EST, $DB_CONN_S042_TW, $DB_CONN_S085, $DB_CONN_S085_EST, $DB_CONN_S085_TW, $JAVA_PROC" >> $PERF_LOGDIR/DB${DATE}.csv

sleep 15

fi
done
