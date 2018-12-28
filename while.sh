for i in "objsize=512"  "objsize=1024"  "objsize=2048" "objsize=4096" \
"objsize=8192" "objsize=16384" "objsize=32768" "objsize=65536" \
"objsize=131072"  "objsize=262144" "objsize=524288" "1" "2"
do  
#	echo $i >> conf/default.conf
#	./sbin/new.sh all
#	sleep 30
#	./sbin/new.sh remove
	./sbin/testwr.sh check
	sleep 30
done
