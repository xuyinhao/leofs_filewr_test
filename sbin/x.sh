a=(1 2 3)
ab=$a
for  i in $(seq 1 ${#${{ab}}[@]})
do
	echo $i
done
