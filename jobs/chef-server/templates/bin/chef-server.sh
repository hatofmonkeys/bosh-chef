#!/bin/bash -e

JOB_DIR=/var/vcap/jobs/chef-server
RUN_DIR=/var/vcap/sys/run/chef-server
LOG_DIR=/var/vcap/sys/log/chef-server
PIDFILE=$RUN_DIR/chef-server.pid

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
    sysctl -w "kernel.shmmax=284934144"

    /opt/chef-server/embedded/bin/chef-solo -c /opt/chef-server/embedded/cookbooks/solo.rb -j /tmp/dna.json

    sleep 180
  done