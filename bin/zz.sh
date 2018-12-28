#复制 读写参数
#
for i in {1..96}
do
a=`cat bdsnapshot |sed -n "${i}p"|awk '{print $1}'` #kelongyuan
b=`cat bdsnapshot |sed -n "${i}p"|awk '{print $2}'|awk -F '_' '{print $1}'`
wrtmp=`cat tmparg |grep leobd1d${b}$ |awk '{$(NF)="";print $0}'`
echo $wrtmp leobd1d$a >> tmp
done
