#!/bin/bash

echo "Reverting most recent migration..."
swift run App migrate --revert
