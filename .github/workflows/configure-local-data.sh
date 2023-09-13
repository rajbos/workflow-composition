#!/bin/bash

# get the data for the last run into the /data directory:
object=$(gh run list -w "Gather data" --json "url" -L 1)
url=$(echo $object | jq '.[0].url')
# split the url to get the run id
IFS='/' read -ra ADDR <<< "$url"
run_id=${ADDR[7]}
# remove the last double quote
run_id=${run_id%?}
echo $run_id

gh run download $run_id --path data
