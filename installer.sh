#!/bin/bash

ls /root 2&>1 /dev/null

if [ "$?" == "0" ]; then
	echo Hallo
fi
