$myAddress="yourAddress"
#0.000000000001 is one Mojo
# 1e12 Mojo is one XCH
#Amount to Split each
$amount=1 * 1e12
#Fee per Transaction
$fee=0
$memo="coinSplit"
#How many times do we split
$splitTimes=19

$wallet=Get-Wallets | Where-Object name -eq "Chia Wallet"

for($i=1; $i -le $splitTimes; $i++){

    #chia wallet send --address $myAddress --amount $amount --memo $memo --fee 0
    $transaction=Send-Transaction -wallet_id $wallet.id -amount $amount -fee $fee -address $myAddress -memos $memo
    if($null -ne $transaction){
        #Check Transaction Status
        do{
            Write-Host("$i of $splitTimes Transaction " + $transaction.name + " with " + ("{0:n12}" -f ($transaction.amount * 1e-12)) + " XCH sent to " + $transaction.to_address +" is not confirmed yet")
            Start-Sleep -Seconds 10
            $checkTransaction=Get-Transaction -transaction_id $transaction.name
        }while($checkTransaction.confirmed -eq $false)
        Write-Host("$i of $splitTimes Transaction " + $transaction.name + " is confirmed")
    }
    else{
        Write-Error("Error in creating transaction")
    }
}