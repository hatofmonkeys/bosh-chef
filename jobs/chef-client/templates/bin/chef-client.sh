#!/bin/bash -e

JOB_DIR=/var/vcap/jobs/chef-client
RUN_DIR=/var/vcap/sys/run/chef-client
LOG_DIR=/var/vcap/sys/log/chef-client
PIDFILE=$RUN_DIR/chef-client.pid

# function to test for a lock
# expects the lock file as the first argument
function f_lock_test {

lock_pid_file=$1
# error checking
if [[ ${lock_pid_file} == "" ]]
  then
    echo "no lock file argument provided"
    return 1
fi

if [ -e ${lock_pid_file} ]
  then
    existing_pid=`cat ${lock_pid_file}`
    if kill -0 ${existing_pid} > /dev/null
      then
        echo "Process already running"
        return 1
    else
      rm ${lock_pid_file}
    fi
fi
echo $$  > ${lock_pid_file}
}

# PID/lock - we only want one instance running.
f_lock_test ${PIDFILE}

mkdir -p ${LOG_DIR}

while true
  do

    /var/vcap/packages/ruby/bin/ruby /var/vcap/packages/chef-client/bin/chef-client >> ${LOG_DIR}/chef-client.log 2>&1

    sleep 180
  done