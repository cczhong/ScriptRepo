awk '{if(index($0, "@")==1 && NR%4==1){sub(/@/,">",$0); print $0; tp=1}else{if(tp==1){print $0; tp=0}}}'
