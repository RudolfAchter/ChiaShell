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
if($psversionTable.PSVersion -lt "6.2"){
    #Requires -Modules PSPKI
}

#Requires -Modules Powershell-Yaml


$global:thisModuleName = "ChiaShell"

if($psversionTable.Platform -eq "Unix"){
    $a_psModulePath=$env:PSModulePath -split ":"
}
else{
    $a_psModulePath=$env:PSModulePath -split ";"
}

$global:ModConf=@{}
$global:ModConf.${global:thisModuleName} = @{}

$a_psModulePath | ForEach-Object {
    $psModPath=$_
    $modPath=($psModPath + "\" + $global:thisModuleName)
    if(Test-Path ($modPath)){
        $global:ModConf.${global:thisModuleName}.ModPath=$modPath
    }
}

if ($psversionTable.Platform -eq "Unix") {
    #Linux
    #Unter Linux sind die Default Pfade anders 

    if ( -not (Test-Path($env:HOME + "/.local/share/powershell/config" + "/" + $global:thisModuleName + ".config.ps1")) -and 
              (Test-Path("/usr/local/share/powershell/config" + "/" + $global:thisModuleName + ".config.ps1"))
    )
    {
        $Global:PowershellConfigDir = ("/usr/local/share/powershell/config")
        $Global:PowershellDataDir = ("/usr/local/share/powershell/data")
    }
    else
    {
        $Global:PowershellConfigDir = ($env:HOME + "/.local/share/powershell/config")
        $Global:PowershellDataDir = ($env:HOME + "/.local/share/powershell/data")
    }

}
else{
    if ( -not (Test-Path ($env:USERPROFILE + "\Documents\WindowsPowerShell\Config\" + $global:thisModuleName + ".config.ps1")) -and 
              (Test-Path ($env:ProgramData + "\WindowsPowerShell\Config\"  + $global:thisModuleName + ".config.ps1"))) {
        $Global:PowershellConfigDir = ($env:ProgramData + "\WindowsPowerShell\Config")
        $Global:PowershellConfigDir = ($env:ProgramData + "\WindowsPowerShell\Data")
    }
    else {
        $Global:PowershellConfigDir = ($env:USERPROFILE + "\Documents\WindowsPowerShell\Config")
        $Global:PowershellDataDir = ($env:USERPROFILE + "\Documents\WindowsPowerShell\Data")
    }
}

If (-not (Test-Path $Global:PowershellConfigDir)) {
    mkdir $Global:PowershellConfigDir
}
If (-not (Test-Path $Global:PowershellDataDir)) {
    mkdir $Global:PowershellDataDir
}

$global:ModConf.ChiaShell.ConfigDir=$Global:PowershellConfigDir
$global:ModConf.ChiaShell.DataDir=$Global:PowershellDataDir



If (-not (Test-Path $Global:PowershellConfigDir)) {
    mkdir $Global:PowershellConfigDir
}


#Write Config File
If (-not (Test-Path ($Global:PowershellConfigDir + "\" + $global:thisModuleName + ".config.ps1"))) {
    Set-Content -Path ($Global:PowershellConfigDir + "\" + $global:thisModuleName + ".config.ps1") -Value (@'
$chiaConfigFile=Get-Item "~/.chia/mainnet/config/config.yaml"
$chiaConfig=Get-Content -Path $chiaConfigFile.FullName | ConvertFrom-Yaml

$Global:ChiaShell=@{
    Api = @{
        Daemon = @{
            Host = "localhost"
            Port = $ChiaConfig.daemon_port
        }
        FullNode = @{
            Host = "localhost"
            Port = $ChiaConfig.full_node.rpc_port
            clientCert = "~/.chia/mainnet/config/ssl/full_node/private_full_node.crt"
            clientKey = "~/.chia/mainnet/config/ssl/full_node/private_full_node.key"
        }
        Farmer = @{
            Host = "localhost"
            Port = $ChiaConfig.farmer.rpc_port
        }
        Harvester = @{
            Host = "localhost"
            Port = $ChiaConfig.harvester.rpc_port
        }
        Wallet = @{
            Host = "localhost"
            Port = $ChiaConfig.wallet.rpc_port
            clientCert = "~/.chia/mainnet/config/ssl/wallet/private_wallet.crt"
            clientKey = "~/.chia/mainnet/config/ssl/wallet/private_wallet.key"
        }
    }
    Run=@{
        SelectedWallet=$null
    }
}
'@
)
    . ($Global:PowershellConfigDir + "\" + $global:thisModuleName + ".config.ps1")

}
#Get existing Config File if exists  already
else {
    . ($Global:PowershellConfigDir + "\" + $global:thisModuleName + ".config.ps1")
}






$Global:ChiaShellArgumentCompleters=@{
    WalletId = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        $WarningPreference = 'SilentlyContinue'
        if ($wordToComplete -ne '') {
            $results = Get-ChiaWallets | Where-Object -like ($wordToComplete + "*")
        }
        else {
            $results = Get-ChiaWallets
        }

        if ($results -ne $null) {
            $results | ForEach-Object {
                $result = $_
                ('' + $result.id + ' <#' + $result.name + '#>')
            }
        }
        else {
            '<#No Wallet found#>'
        }
    }
    ApiName = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        if ($wordToComplete -ne '') {
            $Global:ChiaShell.Api.GetEnumerator().Name | Where-Object $_ -like ($wordToComplete + "*")
        }
        else{
            $Global:ChiaShell.Api.GetEnumerator().Name
        }
    }
}


<#
    Windows Powershell 5.1 Workaround
    -SkipCertificateCheck Switch is missing in Windows Powershell 5.1
    - https://til.intrepidintegration.com/powershell/ssl-cert-bypass

#>
if($psversionTable.PSVersion -lt [system.version]::New("6.0")){
    add-type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}


Function Get-ChiaCert {
    param(
        $api
    )
    $clientCert=Get-Item -Path $Global:ChiaShell.Api.$api.clientCert
    $clientKey=Get-Item -Path $Global:ChiaShell.Api.$api.clientKey

    #https://docs.microsoft.com/en-us/dotnet/api/system.security.cryptography.x509certificates.x509certificate2.createfrompemfile?view=net-6.0#system-security-cryptography-x509certificates-x509certificate2-createfrompemfile(system-string-system-string)
    #DotNet 6 or higher does this native!
    if($psversionTable.PSVersion -gt "6.2"){
        #Linux and Powershell Core greater 6.2
        $cert=[System.Security.Cryptography.X509Certificates.X509Certificate2]::CreateFromPemFile($clientCert,$clientKey)
    }
    else{
        # Old Windows 10 Clients
        # But Windows 10 only has .NET Framework 4.8 (Windows 10)
        # Powershell Module PSPKI (Workaround). Certificate Handling in Microsoft .Net Framework seems to be a mess
        $password = ConvertTo-SecureString "chia" -asplaintext -force
        $p12CertPath = ($clientCert.Directory.FullName + "/" + $clientCert.BaseName + ".pfx")
        $cert=Convert-PemToPfx -InputPath $clientCert.FullName -KeyPath $clientKey.FullName -OutputPath $p12CertPath -Password $password
    }
    $cert

}




Function _ChiaApiCall {
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
        $api="Wallet",
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

    #Windows Powershell 5.1 Workaround
    if($psversionTable.PSVersion -lt [system.version]::New("6.0")){
        #TODO maybe Get JSON manually to get deeper Data Structure
        $result=Invoke-RestMethod -Uri ("https://"+ $Global:ChiaShell.Api.$api.Host +":" + $Global:ChiaShell.Api.$api.Port + "/$function") `
            -Method "POST"  `
            -Certificate (Get-ChiaCert -api $api) @h_args
    }
    else{
        $result=Invoke-RestMethod -Uri ("https://"+ $Global:ChiaShell.Api.$api.Host +":" + $Global:ChiaShell.Api.$api.Port + "/$function") `
            -Method "POST"  `
            -SkipCertificateCheck `
            -Certificate (Get-ChiaCert -api $api) @h_args
    }

    
    if($result.error){
        Write-Error $result.error
    }

    $result

}


Function Get-ChiaWallets {
    [CmdletBinding()]

    $result = _ChiaApiCall -api wallet -function "get_wallets"
    $result.wallets
}


Function Get-ChiaKey {
    [CmdletBinding()]

    $result = _ChiaApiCall -api wallet -function "get_public_keys"
    $result.public_key_fingerprints
}

Function Use-ChiaKey {
    [CmdletBinding()]
    param(
        $fingerprint
    )

    $result = _ChiaApiCall -api wallet -function "log_in" -params @{
        fingerprint = $fingerprint
    }
    $result.fingerprint
}

Function Show-ChiaWallets {
    [CmdletBinding()]
    param(
        [ValidateSet("Select","Table","List","Grid")]
        $View="Select",
        $Columns=@("id","name","type")
    )

    Switch($View){
        "Select" {
            Get-ChiaWallets | Select-Object $Columns
            break
        }
        "Table" {
            Get-ChiaWallets | Format-Table $Columns
            break
        }
        "List" {
            Get-ChiaWallets | Format-List $Columns
            break
        }
        "Grid" {
            Get-ChiaWallets | Select-Object $Columns | Out-ConsoleGridView
            break
        }
    }
}

Function Select-ChiaWallet {
    [CmdletBinding()]
    param(

    )
    $Columns=@("id","name","type")
    $global:ChiaShell.Run.SelectedWallet = Get-ChiaWallets | Select-Object $Columns | Out-ConsoleGridView -OutputMode Single -Title "Select Chia Wallet with <space>. Prompt with <enter>"
    $global:ChiaShell.Run.SelectedWallet
}

Function Get-ChiaWalletBalance {
    [CmdletBinding()]
    param(
        $wallet_id=$ChiaShell.Run.SelectedWallet.id
    )

    $result = _ChiaApiCall -api wallet -function "get_wallet_balance" -params @{
        wallet_id=$wallet_id
    }
    $result.wallet_balance
}


Function Get-ChiaTransactions {
    [CmdletBinding()]
    param(
        [int]$wallet_id=$ChiaShell.Run.SelectedWallet.id,
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

    $result = _ChiaApiCall -api wallet -function "get_transactions" -params $h_params
    $result.transactions | ForEach-Object {
        $t=$_
        Add-Member -InputObject $t -MemberType NoteProperty -Name "created_at_datetime" -Value ([timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($t.created_at_time)))
        $t
    }
}

Function Get-ChiaTransaction {
    [CmdletBinding()]
    param(
        $transaction_id
    )

    $h_params=@{
        transaction_id=$transaction_id
    }
    $result = _ChiaApiCall -api wallet -function "get_transaction" -params $h_params
}


Function Get-ChiaAllOffers {
    [CmdletBinding()]
    param(
        $start=0,
        $end=100
    )

    $h_params=@{
        start=$start
        end=$end
    }


    $result = _ChiaApiCall -api wallet -function "get_all_offers" -params $h_params
    $result.trade_records
}

Function Remove-Offer {
<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER trade_ids
Parameter description

.PARAMETER secure
Parameter description

.EXAMPLE
Show-ChiaAllOffers | Where-Object status -eq "PENDING_ACCEPT" | Remove-Offer

```text
trade_id                                                           success
--------                                                           -------
0x051e7141341a95396e6fa18662be6d5f0f5ab4b6ecdfaa5d39877a2f5e9dbcd4    True
0x2ffb8afc6bba8ea5a94f76ddf605a94a2a4922c7a43cf66c27d6f427544e6971    True
0x84d632fb57fb20e4b24e137b9403438807bc72a5e45ebd727c870fbc8d2d1324    True
0xf7c1bca5cbb83124ad59d4c2f04bc5161043b365b348e2694b46f1d64ad3ac20    True
0xfa43c54f65f43486bb8e40139edc470fc8ae42b8ad6eea60abdd09442259be3d    True
```
.NOTES
General notes
#>
    param(
        [Parameter(ValueFromPipeline=$true)]
        $trade_ids,
        [bool]$secure=$true
    )

    Begin{}

    Process{

        $trade_ids | ForEach-Object {
            $trade_id=$_

            #if there is directly a offer object
            if($trade_id.GetType().Name -ne "String"){
                $trade_id=$trade_id.trade_id
            }

            $h_params=@{
                trade_id=$trade_id
                secure=$secure
            }
            $result = _ChiaApiCall -api wallet -function "cancel_offer" -params $h_params

            [PSCustomObject]([ordered]@{
                trade_id = $trade_id
                success=$result.success
            })
        }


    }
}

Function Show-ChiaAllOffers {
<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER start
Parameter description

.PARAMETER end
Parameter description

.EXAMPLE
Show-ChiaAllOffers | %{Get-ChiaNftInfo -coin_id $_.requested_item} | %{Start-Process $_.data_uris[0]}

.NOTES
General notes
#>
    [CmdletBinding()]
    param(
        $start=0,
        $end=100
    )
    $offers=Get-ChiaAllOffers -start $start -end $end
    $offers | ForEach-Object {
        $offer=$_
        [PSCustomObject]@{
            created_at_time = $offer.created_at_time
            DateCreated=[timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($offer.created_at_time))
            is_my_offer = $offer.is_my_offer
            status = $offer.status
            offered = $offer.summary.offered
            requested_item = $offer.summary.requested.PsObject.Properties.Name
            requested_count = $offer.summary.requested.PsObject.Properties.Value
            trade_id = $offer.trade_id
        }

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

    $result = _ChiaApiCall -api wallet -function "get_transaction" -params $h_params
    $result.transaction
}


Function Get-ChiaNftInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Alias("NftId")]
        [string]$coin_id
    )

    $h_params=@{
        coin_id=$coin_id
    }

    $result = _ChiaApiCall -api wallet -function "nft_get_info" -params $h_params
    $result.nft_info
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
        [int]$wallet_id=$ChiaShell.Run.SelectedWallet.id,
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
    $result = _ChiaApiCall -api wallet -function "send_transaction" -params $h_params
    $result.transaction
}



Function Invoke-ChiaSplitCoins {
<#
.SYNOPSIS
Splits Chia Coins like explained in
- <https://rudolfachter.github.io/blockchain-stuff/public/chia/splitting_coins_for_offers/>

.DESCRIPTION
When you transferred the coins to your wallet in just one transaction, you will just have
one "physical" coin with a value in your wallet. This coin can only be used for one offer.
If you want to do multiple offers in parallel, you must have multiple coins in your wallet.
one coin for each offer.
This Function is a workaround to split your coins into multiple coins by sending them to
yourself.

.PARAMETER myAddress
Your Chia Address (xch1....)

.PARAMETER AmountXch
Amount in XCH for each split

.PARAMETER fee
How much fee you want to use for each split (Default: 0)

.PARAMETER memo
Default: "coinSplit"

.PARAMETER splitTimes
How many times do you want to split (Default: 1)

.EXAMPLE
Invoke-ChiaSplitCoins -myAddress xch1r.....yvtlx6 -AmountXch 0.03 -splitTimes 30

.NOTES
General notes
#>
    param(
        [Parameter(Mandatory=$true)]
        $myAddress,
        [Parameter(Mandatory=$true)]
        $AmountXch,
        $fee=0,
        $memo="coinSplit",
        $splitTimes=1
    )

    $amount=$AmountXch * 1e12

    $wallet=Get-ChiaWallets | Where-Object name -eq "Chia Wallet"

    for($i=1; $i -le $splitTimes; $i++){

        #chia wallet send --address $myAddress --amount $amount --memo $memo --fee 0
        $transaction=Send-ChiaTransaction -wallet_id $wallet.id -amount $amount -fee $fee -address $myAddress -memos $memo
        if($null -ne $transaction){
            #Check Transaction Status
            do{
                Write-Host("$i of $splitTimes Transaction " + $transaction.name + " with " + ("{0:n12}" -f ($transaction.amount * 1e-12)) + " XCH sent to " + $transaction.to_address +" is not confirmed yet")
                Start-Sleep -Seconds 10
                $checkTransaction=Get-ChiaTransaction -transaction_id $transaction.name
            }while($checkTransaction.confirmed -eq $false)
            Write-Host("$i of $splitTimes Transaction " + $transaction.name + " is confirmed")
        }
        else{
            Write-Error("Error in creating transaction")
        }
    }


}




Function Invoke-ChiaSplitHalf {
<#
.SYNOPSIS
Splits Chia Coins like explained in
- <https://rudolfachter.github.io/blockchain-stuff/public/chia/splitting_coins_for_offers/>

.DESCRIPTION
When you transferred the coins to your wallet in just one transaction, you will just have
one "physical" coin with a value in your wallet. This coin can only be used for one offer.
If you want to do multiple offers in parallel, you must have multiple coins in your wallet.
one coin for each offer.
This Function is a workaround to split your coins into multiple coins by sending them to
yourself.

.PARAMETER myAddress
Your Chia Address (xch1....)

.PARAMETER AmountXch
Amount in XCH for each split

.PARAMETER fee
How much fee you want to use for each split (Default: 0)

.PARAMETER memo
Default: "coinSplit"

.PARAMETER splitTimes
How many times do you want to split (Default: 1)

.EXAMPLE
Invoke-ChiaSplitCoins -myAddress xch1r.....yvtlx6 -AmountXch 0.03 -splitTimes 30

.NOTES
General notes
#>
    param(
        [Parameter(Mandatory=$true)]
        $myAddress,
        $fee=0,
        $memo="coinSplit",
        $splitTimes=1
    )

    $wallet=Get-ChiaWallets | Where-Object name -eq "Chia Wallet"
    $walletBalance=Get-ChiaWalletBalance -wallet_id $wallet.id
    [int64]$splitAmount=$walletBalance.confirmed_wallet_balance

    for($i=1; $i -le $splitTimes; $i++){
        [int64]$splitAmount=$splitAmount / 2
        #chia wallet send --address $myAddress --amount $amount --memo $memo --fee 0
        $transaction=Send-ChiaTransaction -wallet_id $wallet.id -amount $splitAmount -fee $fee -address $myAddress -memos $memo
        if($null -ne $transaction){
            #Check Transaction Status
            do{
                Write-Host("$i of $splitTimes Transaction " + $transaction.name + " with " + ("{0:n12}" -f ($transaction.amount * 1e-12)) + " XCH sent to " + $transaction.to_address +" is not confirmed yet")
                Start-Sleep -Seconds 10
                $checkTransaction=Get-ChiaTransaction -transaction_id $transaction.name
            }while($checkTransaction.confirmed -eq $false)
            Write-Host("$i of $splitTimes Transaction " + $transaction.name + " is confirmed")
        }
        else{
            Write-Error("Error in creating transaction")
        }
    }
}


Function Get-ChiaNetworkInfo {
    _ChiaApiCall -api FullNode -function "get_network_info"
}

Function Get-ChiaBlockchainState {
    $result=_ChiaApiCall -api FullNode -function "get_blockchain_state"
    $result.blockchain_state
}


Function Get-ChiaBlocks {
    param(
        $start=((Get-ChiaBlockchainState).peak.height - 100),
        $end=((Get-ChiaBlockchainState).peak.height)
    )
    $h_params=@{
        start=$start
        end=$end
    }
    $result=_ChiaApiCall -api FullNode -function "get_blocks" -params $h_params
    $result.blocks
}


Function Get-ChiaBlockRecords {
    param(
        $start=((Get-ChiaBlockchainState).peak.height - 100),
        $end=((Get-ChiaBlockchainState).peak.height)
    )
    $h_params=@{
        start=$start
        end=$end
    }
    $result=_ChiaApiCall -api FullNode -function "get_block_records" -params $h_params
    $result.block_records
}


Function Get-ChiaAdditionsAndRemovals {
    param(
        [Parameter(ValueFromPipeline=$true)]
        $header_hash
    )

    Begin{}

    Process{
        $header_hash | ForEach-Object {
            $hHash=$_
            if($hHash.GetType().Name -ne "String"){
                $hHash=$hHash.header_hash
            }
            $h_params=@{
                header_hash=$hHash
                
            }
            $result=_ChiaApiCall -api FullNode -function "get_additions_and_removals" -params $h_params
            $result | ForEach-Object {
                $res=$_
                foreach($prop in @("additions","removals")){
                    for($i=0;$i -lt $result.$prop.count;$i++){
                        Add-Member -InputObject $res.$prop[$i] -MemberType NoteProperty -Name DateTime `
                            -Value ([timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($res.$prop[$i].timestamp))) -Force
                        
                    }
                }
                $res
            }
        }
    }

    End{}
}


Function Get-ChiaCoinRecordsByPuzzleHash {
    param(
        [Parameter(Mandatory=$true)]
        $puzzle_hash,
        #TODO get height from current height
        $start_height=((Get-ChiaBlockchainState).peak.height - 100),
        $end_height=((Get-ChiaBlockchainState).peak.height)
    )
    $h_params=@{
        puzzle_hash=$puzzle_hash
        start_height=$start_height
        end_height=$end_height
    }
    $result=_ChiaApiCall -api FullNode -function "get_coin_records_by_puzzle_hash" -params $h_params
    $result.coin_records
}


function Get-ChiaOfferSummary {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
        $offer
    )
    
    begin {
        $aFiles=@()
    }
    
    process {
        if($null -ne $file){
            $offer | ForEach-Object {
                $oFile=$_
                if($oFile.GetType().Name -eq "String"){
                    $oFile=Get-Item -Path $oFile
                }
                $aFiles+=$oFile
            }
        }
    }
    
    end {
        if($aFiles.count -gt 0){
            $aFiles | ForEach-Object {
                $file=$_
                $fileContent=(Get-Content $file.FullName) -join "`r`n"

                $h_params=@{
                    offer=$fileContent
                }
                $result=_ChiaApiCall -api Wallet -function "get_offer_summary" -params $h_params
                $summary=$result.summary
                Add-Member -InputObject $summary -MemberType NoteProperty -Name File -Value $file
                $summary
            }

        }
    }
}


function Confirm-ChiaOffer {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
        $offer,
        $fee=0,
        [switch]$Confirm=$true
    )
    
    begin {
        $aFiles=@()
    }
    
    process {
        if($null -ne $file){
            $offer | ForEach-Object {
                $oFile=$_
                if($oFile.GetType().Name -eq "String"){
                    $oFile=Get-Item -Path $oFile
                }
                elseif($oFile.GetType().Name -eq "PSCustomObject"){
                    $oFile=$oFile.File
                }
                $aFiles+=$oFile
            }
        }
    }
    
    end {
        if($aFiles.count -gt 0){
            $aFiles | ForEach-Object {
                $file=$_
                $fileContent=(Get-Content $file.FullName) -join "`r`n"


                Write-Host("Offer Summary:")
                Write-Host(Get-ChiaOfferSummary -offer $file | Format-List | Out-String)
                
                $doit=$false
                if($Confirm){
                    Write-Host("This will take this Offer")
                    $answer=Read-Host -Prompt "Are you sure? (y|n)"
                    if($answer -eq "y"){$doit=$true}
                }
                else{
                    $doit=$true
                }

                if($doit){
                    $h_params=@{
                        offer=$fileContent
                        fee=$fee
                    }
                    $result=_ChiaApiCall -api Wallet -function "take_offer" -params $h_params
                    if($result.success){
                        $result.trade_record
                    }
                    else{
                        $false
                    }
                }
            }
        }
    }
}

Register-ArgumentCompleter -CommandName Get-ChiaWalletBalance -ParameterName wallet_id -ScriptBlock $Global:ChiaShellArgumentCompleters.WalletId
Register-ArgumentCompleter -CommandName _ChiaApiCall -ParameterName api -ScriptBlock $Global:ChiaShellArgumentCompleters.ApiName