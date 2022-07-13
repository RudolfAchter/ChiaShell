
<#
    ChiaShell
    Implemented follow this: 
    - https://github.com/Chia-Network/chia-blockchain/tree/main/chia/rpc
    - https://docs.chia.net/docs/12rpcs/rpcs/

    Default Ports:
    Daemon: 55400
    Full Node: 8555
    Farmer: 8559
    Harvester: 8560
    Wallet: 9256
#>

<#
curl --insecure --cert ~/.chia/mainnet/config/ssl/wallet/private_wallet.crt \
--key ~/.chia/mainnet/config/ssl/wallet/private_wallet.key -d '{"wallet_id": 1}' \
-H "Content-Type: application/json" -X POST https://localhost:9256/get_wallet_balance | python -m json.tool
#>

#You could get this settings out of config.yml. But for now thats enough

$Global:ChiaShell=@{
    Api = @{
        Daemon = @{
            Host = "localhost"
            Port = 55400
        }
        FullNode = @{
            Host = "localhost"
            Port = 8555
        }
        Farmer = @{
            Host = "localhost"
            Port = 8559
        }
        Harvester = @{
            Host = "localhost"
            Port = 8560
        }
        Wallet = @{
            Host = "localhost"
            Port = 9256
        }
    }

}



Function Get-ChiaWalletCert {
<#
.SYNOPSIS
Gets Certificate of wallet to communicate with RPC

.DESCRIPTION
Gets Certificate of wallet to communicate with RPC

.EXAMPLE
Get-ChiaWalletCert

.NOTES
General notes
#>
    $clientCert = Get-Item -Path ("~/.chia/mainnet/config/ssl/wallet/private_wallet.crt")
    $clientKey= Get-Item -Path ("~/.chia/mainnet/config/ssl/wallet/private_wallet.key")
    #https://docs.microsoft.com/en-us/dotnet/api/system.security.cryptography.x509certificates.x509certificate2.createfrompemfile?view=net-6.0#system-security-cryptography-x509certificates-x509certificate2-createfrompemfile(system-string-system-string)
    $cert=[System.Security.Cryptography.X509Certificates.X509Certificate2]::CreateFromPemFile($clientCert,$clientKey)
    $cert
}


Function _WalletApiCall {
<#
.SYNOPSIS
Generic API Call for Chia wallet RPC

.DESCRIPTION
Generic API Call for Chia wallet RPC

.PARAMETER function
which rpc function to call

.PARAMETER params
parameters for rpc_call as Hashtable

.EXAMPLE
An example

.NOTES
General notes
#>
    [CmdletBinding()]
    param(
        $function,
        $params
    )

    #-Body ($params | ConvertTo-Json)
    if($null -ne $params){
        $h_args=@{
            "Body" = ($params | ConvertTo-Json)
        }
    }
    else{
        $h_args=@{
            "Body" = (@{"nothing"="nothing"} | ConvertTo-Json)
        }
    }

    $result=Invoke-RestMethod -Uri ("https://"+ $Global:ChiaShell.Api.Wallet.Host +":" + $Global:ChiaShell.Api.Wallet.Port + "/$function") `
        -Method "POST"  `
        -SkipCertificateCheck `
        -Certificate (Get-ChiaWalletCert) @h_args
        
    
    if($result.error){
        Write-Error $result.error
    }

    $result

}


Function Get-ChiaWallets {
    [CmdletBinding()]

    $result = _WalletApiCall -function "get_wallets"
    $result.wallets
}


Function Get-ChiaWalletBalance {
    [CmdletBinding()]
    param(
        $wallet_id=1
    )

    $result = _WalletApiCall -function "get_wallet_balance" -params @{
        wallet_id=$wallet_id
    }
    $result.wallet_balance
}


Function Get-ChiaTransactions {
    [CmdletBinding()]
    param(
        [int]$wallet_id=1,
        [int]$start=0,
        [int]$end=50,
        #https://github.com/Chia-Network/chia-blockchain/search?q=sort_key
        #$sort_key=$null,
        [switch]$reverse=$false
    )

    $h_params=@{
        wallet_id=$wallet_id
        start=$start
        end=$end
    }

    <#
    if($null -ne $sort_key){
        $h_params.Add("sort_key",$sort_key)
    }
    #>
    $h_params.Add("reverse",$reverse)

    $result = _WalletApiCall -function "get_transactions" -params $h_params
    $result.transactions | ForEach-Object {
        $t=$_
        Add-Member -InputObject $t -MemberType NoteProperty -Name "created_at_datetime" -Value ([timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($t.created_at_time)))
        $t
    }
}

Function Get-ChiaTransaction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$transaction_id
    )

    $h_params=@{
        transaction_id=$transaction_id
    }

    $result = _WalletApiCall -function "get_transaction" -params $h_params
    $result.transaction
}


Function Send-ChiaTransaction {
<#
.SYNOPSIS
Sends a Chia Transaction

.DESCRIPTION
Sends a Chia Transaction

.PARAMETER wallet_id
which wallet to use

.PARAMETER amount
amount in mojo (1e-12 xch)

.PARAMETER fee
fee to use

.PARAMETER address
transaction to which address

.PARAMETER memos
Memos (String or Array of multiple memos)

.EXAMPLE
Send-ChiaTransaction -wallet_id $wallet.id -amount $amount -fee $fee -address $myAddress -memos $memo

.NOTES
General notes
#>
    [CmdletBinding()]
    param(
        [int]$wallet_id=1,
        [Parameter(Mandatory=$true)]
        [int64]$amount,
        [int64]$fee=0,
        [Parameter(Mandatory=$true)]
        [string]$address,
        $memos
    )

    $h_params=@{
        wallet_id=$wallet_id
        amount=[int64]$amount
        fee=[int64]$fee
        address=$address
    }

    if($null -ne $memos){
        #memos is expected as array
        if($memos.GetType().Name -eq "String"){
            $memos=@($memos)
        }
        $h_params.Add("memos",$memos)
    }
    $result = _WalletApiCall -function "send_transaction" -params $h_params
    $result.transaction
}