for i in `ls -1d ../*/index.md  | awk -F '/' '{print $2}'` ; do
  md2inao.pl ../$i/index.md | nkf -s -Lm > $i.txt
done
zip a.zip *.txt
rm *.txt
