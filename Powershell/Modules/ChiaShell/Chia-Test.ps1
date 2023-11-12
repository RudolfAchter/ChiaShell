Import-Module ChiaShell -Force
#Show-ChiaTransactions -Wallet 25
Follow-ChiaTransactions -Wallet 25

#sqlite3 -readonly ./blockchain_wallet_v2_r1_mainnet_1164180629.sqlite "SELECT datetime(created_at_time, 'unixepoch', 'localtime'), hex(amount), sent FROM transaction_record WHERE wallet_id = 1"

#$walletKey=1164180629

#sqlite3 -readonly ("~/.chia/mainnet/wallet/db/blockchain_wallet_v2_r1_mainnet_" + $walletKey + ".sqlite") "select puzzle_hash from derivation_paths where used=1" |
#  ForEach-Object{$_ -replace "^","0x"}
