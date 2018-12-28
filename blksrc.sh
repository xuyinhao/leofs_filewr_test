#blksize="512 1024 2048 4096"
for i in 512 1024 2048 4096
do
echo "blksize=$i" >> ./conf/default.conf
sh ./sbin/blktest.sh testsrc >> all.log 2>&1
done

