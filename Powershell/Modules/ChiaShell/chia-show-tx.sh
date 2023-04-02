#!/bin/bash
CSV=/tmp/wallet-tx.csv
rm -f $CSV

sqlite3 -readonly \
    ~/.chia/mainnet/wallet/db/blockchain_wallet_v2_r1_mainnet_$1.sqlite \
    ".mode csv" \
    "SELECT datetime(created_at_time, 'unixepoch', 'localtime'), hex(amount), sent FROM transaction_record WHERE wallet_id = 1" \
    > $CSV

# balance=0
# while IFS= read -r line; do
#     c=0
#     IFS=,
#     for v in $line; do
#         let c=c+1
#         case $c in
#             1) time="$v" ;;
#             2) amount=$(printf '%0.12f' $(bc -l <<< "scale=12;$((16#$v))/10^12")) ;;
#             3)
#                 if [ ${v::1} -eq 0 ]; then
#                     dir="IN "
#                     balance=$(bc -l <<< "$balance + $amount")
#                 else
#                     dir="OUT"
#                     balance=$(bc -l <<< "$balance - $amount")
#                 fi
#                 ;;
#         esac
#     done
#     echo $time, $dir, $amount
# done < $CSV
# 
# echo ------------------------------------------
# echo Total balance = $(printf '%0.12f' $balance)
# 
# # rm -f $CSV