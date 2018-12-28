#!/bin/sh
usage="Usage: nodes.sh command..."

# if no args specified, show usage
##if [ $# -le 0 ]; then
 # echo $usage
 # exit 1
#fi
cpath=`dirname $0`
cpath=`cd "${cpath}";cd "..";pwd`
#if [ ! -f ${cpath}/conf/conf ]; then
#    echo "nodes is not exist !"
#    exit 0
#fi
#. ${cpath}/conf/conf
nodeList="node102"
nodes=(${nodeList})

# start the daemons
for node in ${nodes[@]} ; do
 ssh $node $"${@// /\\ }" 2>&1 | sed "s/^/$node:/" &
done

wait
