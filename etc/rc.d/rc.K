#!/bin/sh
#
# rc.K 		This file is executed by init when it goes into runlevel
#		1, which is the administrative state. It kills all
#		deamons and then puts the system into single user mode.
#		Note that the file systems are kept mounted.

  # Set the path.
  PATH=/bin:/sbin:/usr/bin:/usr/sbin:/etc

  # Kill all processes.
  echo
  echo "Sending all processes the TERM signal."
  kill -15 -1
  echo -n "Waiting for processes to terminate"
  for loop in 0 1 2 3 4 5 6 7 ; do
    sleep 1
    echo -n "."
  done
  echo
  echo "Sending all processes the KILL signal."
  kill -9 -1

  echo "Single user mode."
