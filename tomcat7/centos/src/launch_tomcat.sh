#/usr/bin/env bash
set -x

TOMCAT_HOME="/opt/tomcat7"

is_Running ()
{
	local RC=1
	
	if [ `netstat -nlp | grep :443 | wc -l` = 1 ]; then
		RC=0
	else
		RC=1
	fi

	return $RC
}

kill_Hanged_Processes ()
{
	echo "killing hanged processes......"
	javaProcs=`ps -efl| grep -v grep | grep java`
	if(test ! -z "$javaProcs") then
		echo "nonzero"
		processId=`echo $javaProcs | awk '{ print $2}'`
		echo "$processId"
		kill -9 $processId
	fi
}

stop_Tomcat ()
{
	echo "shutting down Tomcat......"
	$TOMCAT_HOME/bin/shutdown.sh
}

start_Tomcat ()
{
	echo "starting tomcat......"
	$TOMCAT_HOME/bin/startup.sh
}

restart ()
{
	stop_Tomcat
	sleep 10
	kill_Hanged_Processes
	start_Tomcat
	sleep 60
}


moniter_Tomcat_Health ()
{
 while(true)
 do
  sleep $1
  is_Running
  if(test $? -eq 0 ) then
   echo "Tomcat is running properly........."
  else
   echo "Tomcat not Responding........."
   downat=`date`
   restart
   upat=`date`
   is_Running
   if(test $? -eq 0 ) then
    msg=" Tomcat Server was down at $downat and was  restarted successfully at $upat"
    echo "$msg"
    send_Mail "$msg"
   else
    msg=" Tomcat Server was down at $downat. Restart failed"
    echo "$msg"
    send_Mail "$msg"   
    exit 0
   fi
  fi
 done
}

main()
{
	if ( is_Running )
	then
		echo "Tomcat is already running."
		return 0
	else
		echo "Tomcat is not running.  Starting Tomcat $TOMCAT_HOME/bin/startup.sh"
		start_Tomcat
	fi
}
#usage: moniter_Tomcat_Health  frequency
#moniter_Tomcat_Health 5

main
