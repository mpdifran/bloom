#!/bin/bash

PORT=${1:-8080}

echo "Looking for processes using port $PORT..."

PIDS=$(lsof -t -i tcp:$PORT)

if [ -z "$PIDS" ]; then
  echo "No processes found using port $PORT."
  exit 0
fi

echo "Found the following PIDs using port $PORT:"
echo "$PIDS"

for PID in $PIDS; do
  echo "Killing PID $PID..."
  kill -9 "$PID"
done

echo "All processes using port $PORT have been terminated."