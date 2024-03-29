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


#Requires -Modules Powershell-Yaml


$global:thisModuleName = "ChiaShell"

if ($psversionTable.Platform -eq "Unix") {
    $a_psModulePath = $env:PSModulePath -split ":"
}
else {
    $a_psModulePath = $env:PSModulePath -split ";"
}

if ($null -eq $global:ModConf) {
    $global:ModConf = @{}
}
$global:ModConf.${global:thisModuleName} = @{}

$a_psModulePath | ForEach-Object {
    $psModPath = $_
    $modPath = ($psModPath + "/" + $global:thisModuleName)
    if (Test-Path ($modPath)) {
        $global:ModConf.${global:thisModuleName}.ModPath = $modPath
    }
}

if ($psversionTable.Platform -eq "Unix") {
    #Linux
    #Unter Linux sind die Default Pfade anders 

    if ( -not (Test-Path($env:HOME + "/.local/share/powershell/config" + "/" + $global:thisModuleName + ".config.ps1")) -and 
              (Test-Path("/usr/local/share/powershell/config" + "/" + $global:thisModuleName + ".config.ps1"))
    ) {
        $Global:PowershellConfigDir = ("/usr/local/share/powershell/config")
        $Global:PowershellDataDir = ("/usr/local/share/powershell/data")
    }
    else {
        $Global:PowershellConfigDir = ($env:HOME + "/.local/share/powershell/config")
        $Global:PowershellDataDir = ($env:HOME + "/.local/share/powershell/data")
    }

}
else {
    if ( -not (Test-Path ($env:USERPROFILE + "\Documents\WindowsPowerShell\Config\" + $global:thisModuleName + ".config.ps1")) -and 
              (Test-Path ($env:ProgramData + "\WindowsPowerShell\Config\" + $global:thisModuleName + ".config.ps1"))) {
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

$global:ModConf.ChiaShell.ConfigDir = $Global:PowershellConfigDir
$global:ModConf.ChiaShell.DataDir = $Global:PowershellDataDir + "/" + "ChiaShell"

if (-not (Test-Path $global:ModConf.ChiaShell.DataDir)) {
    mkdir $global:ModConf.ChiaShell.DataDir
}


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
    AddressType=@{
        XCH="xch"
        NFT="nft"
        DID="did:chia:"
    }
    Plot=@{
        PoolContractAddress="YourPoolContractAddress"
        FarmerPublicKey="YourFarmerPublicKey"
        HybridDir="/mnt/firecuda/cudaplot/plot/tmp01"
        CopyCacheDir="mnt/firecuda/cudaplot/plot/tmp02"
        # Dirs where your Plots are (i Read them recursive)
        # You also could Try to read them from Chia config.yaml
        FarmDirs=@(
            "/mnt/pve-chia-farmer/chiafarm01"
            "/mnt/pve-chia-farmer/chiafarm02"
            "/mnt/pve-chia-farmer/chiafarm03"
            "/mnt/pve-chia-farmer/chiafarm04"
            "/mnt/pve-chia-farmer/chiafarm05"
            "/mnt/pve-chia-farmer/chiafarm06"
            "/mnt/pve-chia-farmer/chiafarm07"
            "/mnt/pve-chia-farmer/chiafarm08"
            "/mnt/pve-chia-farmer/chiafarm09"
            "/mnt/pve-chia-farmer/chiafarm10"
        )
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



$global:ModConf.ChiaShell
$global:ModConf.ChiaShell.Add("values", @{})

$global:ModConf.ChiaShell.values.wallet_types = @{
    "Chia" = 0
    "Pool" = 9
    "CAT"  = 6
    "NFT"  = 10
    "DID"  = 8
}


# chia-dotnet from dkackman has Bech32M for Converting PuzzleHash to XCH Address and vice versa
# https://github.com/dkackman/chia-dotnet
if(-not ([System.Management.Automation.PSTypeName]'chia.dotnet.bech32.Bech32M').Type){
    Try{
        Add-Type -Path ($global:ModConf.ChiaShell.ModPath + "/dotnet/bin/Release/net7.0/chia-dotnet.dll")
    } Catch {
        $_.Exception.LoaderExceptions
    }
}


$Global:ChiaShellArgumentCompleters = @{
    WalletId     = {
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
    ApiName      = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        if ($wordToComplete -ne '') {
            $Global:ChiaShell.Api.GetEnumerator().Name | Where-Object $_ -like ($wordToComplete + "*")
        }
        else {
            $Global:ChiaShell.Api.GetEnumerator().Name
        }
    }
    NftWallet    = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        if ($wordToComplete -ne '') {
            (Get-ChiaWallets | Where-Object { $_.type -eq 10 }).id | Where-Object $_ -like ("*" + $wordToComplete + "*")
        }
        else {
            (Get-ChiaWallets | Where-Object { $_.type -eq 10 }).id
        }
    }
    NftWalletDid = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        if ($wordToComplete -ne '') {
            $result = Show-ChiaWallets -wallet_type NFT | Where-Object { $_.name -like ("*" + $wordToComplete + "*") -or $_.did -like ("*" + $wordToComplete + "*") }
        }
        else {
            $result = Show-ChiaWallets -wallet_type NFT
        }

        $result | ForEach-Object {
            ('"' + $_.did + '"' + ' <#' + $_.did_name + '#>')
        }
    }
    WalletType   = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        $list = $global:ModConf.ChiaShell.values.wallet_types.GetEnumerator()

        if ($wordToComplete -ne '') {
            $out = $list | Where-Object { $_.Name -like ("*" + $wordToComplete + "*") }
        }
        else {
            $out = $list
        }
        $out | ForEach-Object {
            ('"' + $_.Name + '" <# ' + $_.Value + ' #>')
        }
    }
}


<#
    Windows Powershell 5.1 Workaround
    -SkipCertificateCheck Switch is missing in Windows Powershell 5.1
    - https://til.intrepidintegration.com/powershell/ssl-cert-bypass

#>
if ($psversionTable.PSVersion -lt [system.version]::New("6.0")) {
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
    $clientCert = Get-Item -Path $Global:ChiaShell.Api.$api.clientCert
    $clientKey = Get-Item -Path $Global:ChiaShell.Api.$api.clientKey

    #https://docs.microsoft.com/en-us/dotnet/api/system.security.cryptography.x509certificates.x509certificate2.createfrompemfile?view=net-6.0#system-security-cryptography-x509certificates-x509certificate2-createfrompemfile(system-string-system-string)
    #DotNet 6 or higher does this native!
    if ($psversionTable.PSVersion -gt "6.2") {
        #Linux and Powershell Core greater 6.2
        $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::CreateFromPemFile($clientCert, $clientKey)
    }
    else {
        if ($psversionTable.PSVersion -lt "6.2") {
            $module = Get-Module PSPKI
            if ($null -eq $module) {
                Import-Module PSPKI
            }
        }
        # Old Windows 10 Clients
        # But Windows 10 only has .NET Framework 4.8 (Windows 10)
        # Powershell Module PSPKI (Workaround). Certificate Handling in Microsoft .Net Framework seems to be a mess
        $password = ConvertTo-SecureString "chia" -asplaintext -force
        $p12CertPath = ($clientCert.Directory.FullName + "/" + $clientCert.BaseName + ".pfx")
        $cert = Convert-PemToPfx -InputPath $clientCert.FullName -KeyPath $clientKey.FullName -OutputPath $p12CertPath -Password $password
    }
    $cert

}


Function ConvertFrom-UnixTimestamp {
    [cmdletBinding()]
    param(
        $timestamp
    )
    ([timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($timestamp)))
}


function Convert-PuzzleHashToAddress {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
        [string[]]$puzzleHash,
        $prefix="xch"
    )
    
    begin {}

    process {
        $puzzleHash | ForEach-Object {
            $ph=$_
            $bech32m=[chia.dotnet.bech32.Bech32M]::new($prefix)
            $bech32m.PuzzleHashToAddress($ph)        
        }
    }

    end {}
}

function Convert-AddressToPuzzleHash {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$true)]
        $address
    )

    begin{}

    process{
        $address | ForEach-Object {
            $addr=$_
            [chia.dotnet.bech32.Bech32M]::AddressToPuzzleHashString($addr)
        }
    }

    end{}

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
        $api = "Wallet",
        $function,
        $params,
        [ValidateSet("error", "info", "verboseonly")]
        $errorType = "error",
        $timeoutSec = 60
    )

    #-Body ($params | ConvertTo-Json)
    if ($null -ne $params) {
        $h_args = @{
            "Body" = ($params | ConvertTo-Json)
        }
    }
    else {
        $h_args = @{
            "Body" = (@{"nothing" = "nothing" } | ConvertTo-Json)
        }
    }

    Try {

        #Windows Powershell 5.1 Workaround
        if ($psversionTable.PSVersion -lt [system.version]::New("6.0")) {
            #TODO maybe Get JSON manually to get deeper Data Structure
            $result = Invoke-RestMethod -Uri ("https://" + $Global:ChiaShell.Api.$api.Host + ":" + $Global:ChiaShell.Api.$api.Port + "/$function") `
                -Method "POST" `
                -TimeoutSec $timeoutSec `
                -Certificate (Get-ChiaCert -api $api) @h_args
        }
        else {
            $result = Invoke-RestMethod -Uri ("https://" + $Global:ChiaShell.Api.$api.Host + ":" + $Global:ChiaShell.Api.$api.Port + "/$function") `
                -Method "POST"  `
                -SkipCertificateCheck `
                -TimeoutSec $timeoutSec `
                -Certificate (Get-ChiaCert -api $api) @h_args 
        }

    }
    Catch {
        Write-Error("Error in API Call to $api :" + $_)
    }

    Switch ($errorType) {
        "error" {
            if ($result.error) {
                Write-Error $result.error
            }
            break
        }

        "info" {
            if ($result.error) {
                Write-Host $result.error
            }
        }

        "verboseonly" {
            if ($result.error) {
                Write-Verbose $result.error
            }
        }
    }
    

    $result

}


Function Get-ChiaBlockHeight {
    param(
        $Date = (Get-Date)
    )
    <#
        Chia Mainnet Start at '2021-03-19 14:00'
        One Block per 18.75 seconds
    #>
    if ($Date.GetType().Name -eq "String") {
        $Date = Get-Date $Date
    }

    $chiaMainnetStart = '2021-03-19 14:00'
    $secPerBlock = 18.75

    $mainnetStart = [timezone]::CurrentTimeZone.ToLocalTime(([datetime]$chiaMainnetStart))
    
    $diff = $Date - $mainnetStart
    [int]$calculatedHeight = $diff.TotalSeconds / $secPerBlock

    $blocks = Get-ChiaBlocks -start ($calculatedHeight - 100) -end $calculatedHeight
    $block = $blocks | Where-Object { $_.foliage_transaction_block } | Select-Object -First 1

    $blockDate = ([timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($block.foliage_transaction_block.timestamp)))

    $diff = $Date - $blockDate
    [int]$calcAdd = $diff.TotalSeconds / $secPerBlock

    $blockHeightResult = [int]$calculatedHeight + [int]$calcAdd
    $blocks = Get-ChiaBlocks -start ($blockHeightResult - 100) -end $blockHeightResult
    $block = $blocks | Where-Object { $_.foliage_transaction_block } | Select-Object -First 1

    $blockDate = ([timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($block.foliage_transaction_block.timestamp)))

    [PSCustomObject]@{
        BlockHeight = $blockHeightResult
        BlockDate   = $blockDate
    }
}

Function Get-ChiaDidWalletName {
    [CmdletBinding()]
    param(
        $wallet_ids = (Get-ChiaWallets -wallet_type "DID").id
    )
    $wallet_ids | ForEach-Object {
        $wallet_id = $_
        $h_params = @{
            wallet_id = $wallet_id
        }
        $result = _ChiaApiCall -api wallet -function "did_get_wallet_name" -params $h_params
        $result
    }
}

Function Get-ChiaDidWalletDid {
    [CmdletBinding()]
    param(
        $wallet_ids = (Get-ChiaWallets -wallet_type "DID").id
    )
    $wallet_ids | ForEach-Object {
        $wallet_id = $_
        $h_params = @{
            wallet_id = $wallet_id
        }
        $result = _ChiaApiCall -api wallet -function "did_get_did" -params $h_params
        $result
    }
}

Function Get-ChiaNftWalletDid {
    [CmdletBinding()]
    param(
        $wallet_ids = (Get-ChiaWallets -wallet_type "DID").id
    )
    $wallet_ids | ForEach-Object {
        $wallet_id = $_
        $h_params = @{
            wallet_id = $wallet_id
        }
        $result = _ChiaApiCall -api wallet -function "nft_get_wallet_did" -params $h_params
        $result.did_id
    }

}

Function Get-ChiaWallets {
    [CmdletBinding()]
    param(
        $wallet_type,
        [switch]$NoAdditionalInfo
    )

    $result = _ChiaApiCall -api wallet -function "get_wallets"

    if (-not $NoAdditionalInfo) {

        #Ich muss vorher ALLE DID Wallets machen damit ich die DID Names habe
        for ($i = 0; $i -lt $result.wallets.Count; $i++) {
            #DID Wallets
            if ($result.wallets[$i].type -eq 8) {
                Add-Member -InputObject $result.wallets[$i] -MemberType NoteProperty `
                    -Name did -Value (Get-ChiaDidWalletDid -wallet_ids $result.wallets[$i].id).my_did
                Add-Member -InputObject $result.wallets[$i] -MemberType NoteProperty `
                    -Name did_name -Value $result.wallets[$i].name
            }
        }
        #Im zweiten Durchlauf die NFT Wallets ergänzen
        for ($i = 0; $i -lt $result.wallets.Count; $i++) {
            #NFT Wallet DIDs
            if ($result.wallets[$i].type -eq 10) {
                Add-Member -InputObject $result.wallets[$i] -MemberType NoteProperty `
                    -Name did -Value (Get-ChiaNftWalletDid -wallet_ids $result.wallets[$i].id)
                Add-Member -InputObject $result.wallets[$i] -MemberType NoteProperty `
                    -Name did_name -Value (($result.wallets | Where-Object { $_.type -eq 8 -and $_.did -eq $result.wallets[$i].did }).name)
            }
        }

    }

    if ($null -ne $wallet_type) {
        $result.wallets | Where-Object { $_.type -eq $global:ModConf.ChiaShell.values.wallet_types.$wallet_type } 
    }
    else {
        $result.wallets
    }

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

Function Get-ChiaKeyLoggedIn {
    [CmdletBinding()]
    $result = _ChiaApiCall -api wallet -function "get_logged_in_fingerprint"
    $result.fingerprint
}

Function Show-ChiaWallets {
    [CmdletBinding()]
    param(
        $wallet_type,
        [ValidateSet("Select", "Table", "List", "Grid")]
        $View = "Select",
        $Columns = @("id", "name", "type", "did", "did_name")
    )

    Switch ($View) {
        "Select" {
            Get-ChiaWallets -wallet_type $wallet_type | Select-Object $Columns
            break
        }
        "Table" {
            Get-ChiaWallets -wallet_type $wallet_type | Format-Table $Columns
            break
        }
        "List" {
            Get-ChiaWallets -wallet_type $wallet_type | Format-List $Columns
            break
        }
        "Grid" {
            Get-ChiaWallets -wallet_type $wallet_type | Select-Object $Columns | Out-ConsoleGridView
            break
        }
    }
}


Function Get-ChiaDidWallet {
    Show-ChiaWallets -wallet_type "DID" <# 8 #> -Columns @("id", "name", "type") | ForEach-Object {
        $didWallet = $_
        Add-Member -InputObject $didWallet -MemberType NoteProperty -Name my_did -Value (Get-ChiaDid -wallet_ids $didWallet.id).my_did
        $didWallet
    }
}


Function Get-ChiaDid {
    [CmdletBinding()]
    param(
        $wallet_ids = (Get-ChiaWallets -wallet_type "DID").id
    )

    $wallet_ids | ForEach-Object {
        $wallet_id = $_
        $h_params = @{
            wallet_id = $wallet_id
        }
        $result = _ChiaApiCall -api wallet -function "did_get_did" -params $h_params
        $result
    }

}

Function Set-ChiaNftDid {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        $nfts,
        $new_did = (Select-ChiaWallet -wallet_type NFT),
        $timeoutSec = 120,
        $fee = 50000000 / 1e12
    )


    

    Begin {
        if ($new_did.GetType().Name -ne "String") {
            $new_did = $new_did.did
            $fee = $fee * 1e12
        }
    }

    Process {
        $nfts | ForEach-Object {
            $nft = $_
            if ($nft.GetType().Name -eq "String") {
                $nft = Get-ChiaNfts | Where-Object nft_coin_id -eq $nft
            }
            
            
            $wallet = Get-ChiaWallets -wallet_type NFT | Where-Object { $_.did -eq $new_did }
            $new_did_id = ($wallet.data | ConvertFrom-Json).did_id

            $setDidSuccess = $false
            while (-not $setDidSuccess) {
                $h_params = @{
                    wallet_id   = $nft.nft_wallet_id
                    nft_coin_id = $nft.nft_coin_id
                    did_id      = $new_did
                    fee         = $fee
                }
                $result = _ChiaApiCall -api wallet -function "nft_set_nft_did" -params $h_params
                $timespan = New-TimeSpan -Seconds 0
                $startTime = Get-Date
                $spend_bundle = $result.spend_bundle
                $spend_bundle

                while ($timespan.TotalSeconds -lt $timeoutSec -and $setDidSuccess -eq $false) {
                    Write-Host("Transferring NFT " + $nft.nft_coin_id + " to " + $new_did_id + " " + $timespan)
                    Start-Sleep -Seconds 30
                    $setDidSuccess = ((Get-ChiaNftInfo -coin_ids $nft.nft_coin_id -NoCache).owner_did -eq $new_did_id)
                    $endTime = Get-Date
                    $timespan = $endTime - $startTime
                }
                if ($setDidSuccess -eq $false) {
                    $h_params = @{
                        wallet_id = $nft.nft_wallet_id
                    }
                    _ChiaApiCall -api wallet -function "delete_unconfirmed_transactions" -params $h_params
                }
            }
        }
    }

    End {}
}


Function Select-ChiaWallet {
    [CmdletBinding()]
    param(
        $wallet_type
    )
    $Columns = @("id", "name", "type", "did_name", "did")
    $global:ChiaShell.Run.SelectedWallet = Get-ChiaWallets -wallet_type $wallet_type | Select-Object $Columns | Out-ConsoleGridView -OutputMode Single -Title "Select Chia Wallet with <space>. Prompt with <enter>"
    $global:ChiaShell.Run.SelectedWallet
}

Function Get-ChiaWalletBalance {
    [CmdletBinding()]
    param(
        $wallet_id = $ChiaShell.Run.SelectedWallet.id
    )

    $result = _ChiaApiCall -api wallet -function "get_wallet_balance" -params @{
        wallet_id = $wallet_id
    }
    $result.wallet_balance
}

Function Get-ChiaNfts {
    [CmdletBinding()]
    param(
        $wallet_ids = (Get-ChiaWallets | Where-Object { $_.type -eq 10 }).id,
        $nft_coin_id
    )

    $wallet_ids | ForEach-Object {
        $wallet_id = $_
        $h_params = @{
            wallet_id = $wallet_id
        }

        $result = _ChiaApiCall -api wallet -function "nft_get_nfts" -params $h_params
        $result.nft_list | ForEach-Object {
            $nft = $_
            Add-Member -InputObject $nft -MemberType NoteProperty -Name "nft_wallet_id" -Value $wallet_id -Force
            $nft
        } | ForEach-Object {
            #Filter auf nft_coin_id
            if ($null -ne $nft_coin_id) {
                $nft | Where-Object nft_coin_id -eq $nft_coin_id
            }
            else {
                $nft
            }
        }
        
    }
}

Function Show-ChiaNfts {
    [CmdletBinding()]
    param(
        $wallet_id = (Get-ChiaWallets | Where-Object { $_.type -eq 10 }).id,
        $View = "Metadata",
        $Columns = @("name", @{
                label      = 'CollectionName'
                expression = { ($_.collection.name) }
            },
            "description", "launcher_id", "nft_coin_id", "nft_wallet_id")
    )
    $result = Get-ChiaNfts -wallet_id $wallet_id
    

    Switch ($View) {
        "Metadata" {
            $result | ForEach-Object {
                $nft = $_
                $metadata = Get-ChiaNftMetadata -nfts $nft
                $metadata | Add-Member -MemberType "NoteProperty" -Name "nft_wallet_id" -Value $nft.nft_wallet_id
                $metadata | Add-Member -MemberType "NoteProperty" -Name "launcher_id" -Value $nft.launcher_id
                $metadata | Select-Object $Columns
            }
        }
        "Select" {
            $result  | Select-Object $Columns
            break
        }
        "Table" {
            $result  | Format-Table $Columns
            break
        }
        "List" {
            $result  | Format-List $Columns
            break
        }
        "Grid" {
            $result | ForEach-Object {
                $nft = $_
                $metadata = Get-ChiaNftMetadata -nfts $nft
                $metadata | Add-Member -MemberType "NoteProperty" -Name "nft_wallet_id" -Value $nft.nft_wallet_id
                $metadata | Add-Member -MemberType "NoteProperty" -Name "launcher_id" -Value $nft.launcher_id
                $metadata
            } | Select-Object $Columns | Out-ConsoleGridView
            break
        }
    }
}

Function Show-ChiaNftOverview {
    param(
        $wallet_ids = (Get-ChiaWallets | Where-Object { $_.type -eq 10 }).id,
        $nft_coin_id
    )

    $overviewDir = ($Global:ModConf.ChiaShell.DataDir + "/html")
    if (-not (Test-Path  $overviewDir)) {
        mkdir $overviewDir
    }
    Get-ChiaNfts -wallet_ids $wallet_ids -nft_coin_id $nft_coin_id | 
    Convert-NftHtml | ConvertTo-StyledHTML | Out-File ($overviewDir + "nft_render.html")
    Start-Process -FilePath "firefox" -ArgumentList ($overviewDir + "nft_render.html")
}

Function Select-ChiaNfts {
    [CmdletBinding()]
    param(
        $wallet_id = (Get-ChiaWallets | Where-Object { $_.type -eq 10 }).id,
        $Columns = @("name", "collection", "description", "launcher_id", "nft_coin_id", "nft_wallet_id")
    )
    Show-ChiaNfts -wallet_id $wallet_id -View "Grid" -Columns $Columns
}


function Get-ChiaCoinRecordsByNames {
    [CmdletBinding()]
    param (
        $names
    )
    
    if($names.GetType().BaseType.Name -ne "Array"){
        $names=@($names)
    }

    $h_params = @{
        names = $names
        include_spent_coins = $true
    }

    $result = _ChiaApiCall -api wallet -function "get_coin_records_by_names" -params $h_params
    $result.coin_records
}

Function Get-ChiaTransactions {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$true)]
        $Wallet = $ChiaShell.Run.SelectedWallet.id,
        [int]$start = 0,
        [int]$end = 0,
        #https://github.com/Chia-Network/chia-blockchain/search?q=sort_key
        #$sort_key=$null,
        [switch]$reverse = $false
    )

    Begin{}

    Process{

        $Wallet | ForEach-Object {
            $wallet_id = $_
            if($wallet_id.GetType().BaseType.Name -eq "Object"){
                $wallet_id=$wallet_id.id
            }

            if ($end -eq 0) {
                $end = (Get-ChiaTransactionCount -wallet_id $wallet_id).count
            }


            $h_params = @{
                wallet_id = $wallet_id
                start     = $start
                end       = $end
            }

            <#
            if($null -ne $sort_key){
                $h_params.Add("sort_key",$sort_key)
            }
            #>
            $h_params.Add("reverse", $reverse)

            $result = _ChiaApiCall -api wallet -function "get_transactions" -params $h_params
            $result.transactions | ForEach-Object {
                $t = $_
                Add-Member -InputObject $t -MemberType NoteProperty -Name "created_at_datetime" -Value ([timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($t.created_at_time)))
                $t
            }
        }
    }
    End{}
}


function Get-ChiaTransactionCount {
    [CmdletBinding()]
    param (
        [int]$wallet_id = $ChiaShell.Run.SelectedWallet.id
    )
    
    $h_params = @{
        "wallet_id" = $wallet_id
    }

    $result = _ChiaApiCall -api wallet -function "get_transaction_count" -params $h_params
    $result
}


Function ChiaTransactions {
    $currentKey = Get-ChiaKeyLoggedIn
    $myAddresses=(chia keys derive -f $currentKey wallet-address -n 10000) | ForEach-Object{($_ -split " ")[3]}
    
    $txns=Get-ChiaTransactions -Wallet 25 | Sort-Obj confirmed_at_height
    $txns=Get-ChiaTransactions -Wallet 1 | Sort-Object confirmed_at_height

    $balance=0
    $txns | ForEach-Object {
        $tx=$_
        if($tx.type -eq "0"){
            foreach($addition in $tx.additions) {
                if($addition.puzzle_hash -notin ($txns | ?{$_.type -eq "1" -and $_.confirmed_at_height -eq $tx.confirmed_at_height}).additions.puzzle_hash){
                    $balance += $addition.amount
                }
                else{
                    Write-Warning("DoubleCount: " + $tx.confirmed_at_height + " puzzle_hash: "+ $addition.puzzle_hash + " amount:" + $addition.amount)
                }
            }
            
        }
        elseif($tx.type -eq "1"){
            if($tx.to_address -notin $myAddresses){
                $balance -= $tx.amount
            }
        }
        elseif($tx.type -eq "3"){
            $balance += $tx.amount
        }
        $tx | Add-Member -MemberType NoteProperty -Name Balance -Value $balance
        $tx | Add-Member -MemberType NoteProperty -Name AddSum -Value ($tx.additions.amount | Measure-Object -Sum).Sum
        $tx
    } | Format-Table -AutoSize created_at_datetime,confirmed_at_height,type,amount,balance
    $balance

    

}


Function WrongChiaTrans {

    $txns=Get-ChiaTransactions -Wallet 1 | Sort-Object confirmed_at_height

    $balance=0
    $txns | ForEach-Object {
        $tx=$_ 
        if($tx.type -eq "0"){ #TxIn
            $balance += $tx.amount
        } 
        elseif($tx.type -eq "1"){ #TxOut
            if($tx.to_address -notin $myAddresses){
                $balance -= $tx.amount
            }
        }
        elseif($tx.type -eq "3"){ #Reward
            $balance += $tx.amount
        }
        $tx | Add-Member -MemberType NoteProperty -Name Balance -Value $balance
        $tx | Add-Member -MemberType NoteProperty -Name AddSum -Value ($tx.additions.amount | Measure-Object -Sum).Sum
        $tx
    } | Format-Table -AutoSize created_at_datetime,confirmed_at_height,type,amount,balance
    $balance
}


Function Follow-ChiaTransactions {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$true)]
        $Wallet = $ChiaShell.Run.SelectedWallet.id,
        [int]$start = 0,
        [int]$end = 0,
        #https://github.com/Chia-Network/chia-blockchain/search?q=sort_key
        #$sort_key=$null,
        [switch]$reverse = $false
    )
    Begin{
        # $myAddresses=(chia keys derive -f $currentKey wallet-address -n 10000) | ForEach-Object{($_ -split " ")[3]}
        $typeDesc = @{
            "0" = "TxIn"
            "1" = "TxOut"
            "2" = "CoinbaseReward"
            "3" = "FeeReward"
            "4" = "TradeIn"
            "5" = "TradeOut"
        }
        $desc = $false
        if ($reverse) {
            $desc = $true
        }

        $MyPuzzleHashes = sqlite3 -readonly ("~/.chia/mainnet/wallet/db/blockchain_wallet_v2_r1_mainnet_" + [string](Get-ChiaKeyLoggedIn) + ".sqlite") "select puzzle_hash from derivation_paths where used=1" |
        ForEach-Object{$_ -replace "^","0x"}

    }

    Process{
        $Wallet | ForEach-Object {
            $wallet_id=$_
            if($wallet_id.GetType().Name -eq "PsCustomObject"){
                $wallet_id=$wallet_id.id
            }
            if ($end -eq 0) {
                $end = (Get-ChiaTransactionCount -wallet_id $wallet_id).count
            }

            $Wallet = Get-ChiaWallets | Where-Object { $_.id -eq $wallet_id }
            if ($Wallet.type -eq 0) {
                $pow = 12
                $WalletName = "Chia"
                $WalletSymbol = "XCH"
            }
            elseif ($Wallet.type -eq 6) {
                $pow = 3
                $WalletName = $Wallet.Name
                $WalletSymbol = ($Wallet.Name -split " ")[0]
            }
            elseif ($Wallet.type -eq 10) {
                $pow = 0
                $WalletName = $Wallet.Name
                $WalletSymbol = ($Wallet.Name -split " ")[0]
            }
            else {
                Write-Error("Only XCH and CAT Wallets are Supported for this CmdLet")
                return
            }
            $myCoins=@{}
            $myBalance=0
            $txns=Get-ChiaTransactions -Wallet $wallet_id -start $start -end $end | Sort-Object created_at_datetime
            $txns | ForEach-Object {
                $tx=$_
                $TxType=$typeDesc.([string]$tx.type)

                $trackedPuzzle="0x3f88092b74f32b2aaefc57c4a95ebd9292eb24ee8948e7cb2ca13dd6cacb5f8e"
                $trackedParent="0x511fd847efe686ec899747e64ce8af2b40f56ae5f2634b53dd6543a60c6807ad"
                $trackedAmount=38000
                if(
                    ($tx.additions.puzzle_hash -contains $trackedPuzzle -and $tx.additions.parent_coin_info -contains $trackedParent) -or
                    ($tx.removals.puzzle_hash -contains $trackedPuzzle -and $tx.removals.parent_coin_info -contains $trackedParent)
                
                ){
                    Write-Host("Found Tracked Coin in " + $tx.confirmed_at_height + " " +$TxType)                    
                }

                if($tx.additions.amount -contains $trackedAmount -or $tx.removals.amount -contains $trackedAmount){
                    Write-Host("Found Tracked Amount in " + $tx.confirmed_at_height + " " +$TxType)                    
                }

                #if($TxType -eq "TxIn"){
                    $tx.additions | ForEach-Object {
                        $addition = $_
                        if($addition.puzzle_hash -in $MyPuzzleHashes){
                            
                            if($null -eq $myCoins.($addition.parent_coin_info)){
                                if($null -eq $myCoins.($addition.parent_coin_info).($addition.puzzle_hash)){
                                    $myCoins.Add($addition.parent_coin_info, @{$addition.puzzle_hash = @{
                                        Amount=$addition.amount
                                        Status="UnSpent"
                                    }})
                                    $myBalance += $addition.amount
                                }
                                else{
                                    if($null -eq $myCoins.($addition.parent_coin_info).($addition.puzzle_hash)){
                                        $myCoins.($addition.parent_coin_info).Add($addition.puzzle_hash, @{
                                            Amount=$addition.amount
                                            Status="UnSpent"
                                        })
                                        $myBalance += $addition.amount
                                    }
                                    else{
                                        Write-Warning("Addition Coin Already UnSpent: " + $tx.confirmed_at_height + " parent_coin_info: " + $addition.parent_coin_info +" puzzle_hash: "+ $addition.puzzle_hash)
                                    }
                                }
                            }
                        }
                        else{
                            Write-Warning("Addition Coin Not Mine: " + $tx.confirmed_at_height + " parent_coin_info: " + $addition.parent_coin_info +" puzzle_hash: "+ $addition.puzzle_hash)
                        }
                    }
                #}
                #elseif($TxType -eq "TxOut"){
                    $tx.removals | ForEach-Object {
                        $removal = $_
                        if($removal.puzzle_hash -in $MyPuzzleHashes){
                            $myBalance -= $removal.amount
                            if($myCoins.($removal.parent_coin_info).($removal.puzzle_hash).Status -eq "UnSpent"){
                                if($myCoins.($removal.parent_coin_info).($removal.puzzle_hash).Amount -eq $removal.amount){
                                    $myCoins.($removal.parent_coin_info).($removal.puzzle_hash).Status="Spent"
                                }
                                else{
                                    Write-Warning("Removal SpendAmount does not Match: " + $tx.confirmed_at_height + " parent_coin_info: " + $removal.parent_coin_info +" puzzle_hash: "+ $removal.puzzle_hash)
                                }
                            }
                            elseif($myCoins.($removal.parent_coin_info).($removal.puzzle_hash).Status -eq "Spent"){
                                Write-Warning("Removal Coin Already Spent: " + $tx.confirmed_at_height + " parent_coin_info: " + $removal.parent_coin_info +" puzzle_hash: "+ $removal.puzzle_hash)
                            }
                            else{
                                Write-Warning("Removal Coin Not Found: " + $tx.confirmed_at_height + " parent_coin_info: " + $removal.parent_coin_info +" puzzle_hash: "+ $removal.puzzle_hash + " amount: " + $removal.amount)
                            }
                        }
                        else{
                            Write-Warning("Removal Coin Not Mine: " + $tx.confirmed_at_height + " parent_coin_info: " + $removal.parent_coin_info +" puzzle_hash: "+ $removal.puzzle_hash)
                        }
                    }
                #}
                Write-Host("Balance: " + $myBalance + " " + $tx.confirmed_at_height + " " +$TxType)
            }

            # Final State of Coins
            $reportHash=@{}
            # For Each Transaction Output Table of my coins
            $myCoins.GetEnumerator() | ForEach-Object {
                $coin = $_
                $reportHash."parent_coin_info"=$coin.Key
                $coin.Value.GetEnumerator() | ForEach-Object {
                    $reportHash."puzzle_hash"=$_.Key
                    $reportHash."amount"=$_.Value.Amount
                    $reportHash."status"=$_.Value.Status
                }
                [PSCustomObject]$reportHash
            }

        }
    }

    End{}
}

Function Show-ChiaTransactions {
<#
.SYNOPSIS
Show-ChiaTransactions zeigt die Transaktionen wie im Wallet selbst an

.DESCRIPTION
Show-ChiaTransactions zeigt die Transaktionen wie im Wallet selbst an.
Diese Transaktionen können NICHT als Export für die Steuer verwendet werden.
z.B. Accointing. Die Summe der Transaktionen geht nicht auf.
Grund ist wahrscheinlich dass Change / Wechselgeld Aktionen und Transaktionen
an mich selbst nicht korrekt erfasst werden. Hier fehlen teilweise Informationen
was zu einer ungültigen Balance führt.
Stattdessen versuche ich es mit Infos aus Spacescan.io

.PARAMETER wallet_id
Parameter description

.PARAMETER start
Parameter description

.PARAMETER end
Parameter description

.PARAMETER reverse
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$true)]
        $Wallet = $ChiaShell.Run.SelectedWallet.id,
        [int]$start = 0,
        [int]$end = 0,
        #https://github.com/Chia-Network/chia-blockchain/search?q=sort_key
        #$sort_key=$null,
        [switch]$reverse = $false
    )

    Begin{
        # $myAddresses=(chia keys derive -f $currentKey wallet-address -n 10000) | ForEach-Object{($_ -split " ")[3]}
        $typeDesc = @{
            "0" = "TxIn"
            "1" = "TxOut"
            "2" = "CoinbaseReward"
            "3" = "FeeReward"
            "4" = "TradeIn"
            "5" = "TradeOut"
        }
        $desc = $false
        if ($reverse) {
            $desc = $true
        }
        $bech32m = [chia.dotnet.bech32.Bech32M]::New("xch")
        $MyPuzzleHashes = sqlite3 -readonly ("~/.chia/mainnet/wallet/db/blockchain_wallet_v2_r1_mainnet_" + [string](Get-ChiaKeyLoggedIn) + ".sqlite") "select puzzle_hash from derivation_paths where used=1" |
        ForEach-Object{$_ -replace "^","0x"}

    }

    Process{
        $Wallet | ForEach-Object {
            $wallet_id=$_
            if($wallet_id.GetType().Name -eq "PsCustomObject"){
                $wallet_id=$wallet_id.id
            }
            if ($end -eq 0) {
                $end = (Get-ChiaTransactionCount -wallet_id $wallet_id).count
            }

            $Wallet = Get-ChiaWallets | Where-Object { $_.id -eq $wallet_id }
            if ($Wallet.type -eq 0) {
                $pow = 12
                $WalletName = "Chia"
                $WalletSymbol = "XCH"
            }
            elseif ($Wallet.type -eq 6) {
                $pow = 3
                $WalletName = $Wallet.Name
                $WalletSymbol = ($Wallet.Name -split " ")[0]
            }
            elseif ($Wallet.type -eq 10) {
                $pow = 0
                $WalletName = $Wallet.Name
                $WalletSymbol = ($Wallet.Name -split " ")[0]
            }
            else {
                Write-Error("Only XCH and CAT Wallets are Supported for this CmdLet")
                return
            }

            $currentKey=Get-ChiaKeyLoggedIn
            #$txns=Get-ChiaTransactions @PSBoundParameters | Sort-Object created_at_datetime
            $txns=Get-ChiaTRansactions -Wallet $wallet_id -start $start -end $end | Sort-Object created_at_datetime

            $additionsSeen=@{}
            $removalsSeen=@{}

            #$MyPuzzleHashes=($txns | Where-Object {$_.type -eq "0"}).to_puzzle_hash
            $bech32m = [chia.dotnet.bech32.Bech32M]::New("xch")
            $txns | ForEach-Object {
                $item = $_
                $TxType=$typeDesc.([string]$item.type)
                $SentToMe=$false
                # 1st unspent coin + 2nd unspent coin = spent coin - fees
                # 10000000000 + 113346290691 = 123400000000 - 53709309
                if($TxType -eq "TxOut"){
                    # Wechselgeld kommt in der nächsten Transaktion zurück
                    $Amount=$item.amount
                    #$ChangeAmount=
                    # if()
                }
                if($TxType -eq "TxIn"){
                    # Wechselgeld kommt zurück
                    #$Amount=$AdditionAmount<#-$RemovalAmount#>
                    $Amount=$item.amount
                }
                # if($TxType -eq "TxIn"){
                if($item.to_puzzle_hash -in $MyPuzzleHashes){
                    $SentToMe=$true
                    # An mich selbst geschickt
                    #return
                }
                # }
                #$Amount=$item.Amount
                #$item
                #$Amount=($item.additions | Measure-Object -Sum Amount).Sum - ($item.removals | Measure-Object -Sum Amount).Sum
                if($Wallet.Type -eq 6){ # CAT Token
                    $AssetId = $Wallet.data -replace '00$',''
                }
                elseif($Wallet.Type -eq 0){ # XCH
                    $AssetId = "xch"
                }
                elseif($Wallet.Type -eq 10){ # NFT
                    <#
                    if($typeDesc.([string]$item.type -eq "TxOut")){
                        $NftInfos = $item.additions | ForEach-Object {Get-ChiaNftInfo -coin_ids $_.parent_coin_info}
                    }
                    else{
                        $NftInfos = $item.removals | ForEach-Object {Get-ChiaNftInfo -coin_ids $_.parent_coin_info}
                    }
                    #FIXME das funktioniert nicht für NFTs
                    $AssetId = $NftInfos | ForEach-Object{$_.launcher_id -replace '^0x',''}
                    #>
                    $AssetId = "NFT (not implemented)"
                }

                # CustomObject mit Informationen die mich interessieren
                [PSCustomObject]@{
                    Type            = $TxType
                    Amount          = [double]($Amount / [Math]::Pow(10, $pow))
                    AmountRaw       = $Amount
                    AssetId         = $AssetId
                    FeeAmount       = [double]($item.fee_amount / [Math]::Pow(10, $pow))
                    Wallet          = $WalletName
                    Symbol          = $WalletSymbol
                    DateCreated     = (ConvertFrom-UnixTimestamp -timestamp $item.created_at_time)
                    HeightConfirmed = $item.confirmed_at_height
                    Id              = $item.name
                    TradeId         = $item.trade_id
                    ToAddress       = $item.to_address
                    SentToMe        = $SentToMe
                }
            }
        }
    }
    End{}

}

Function Get-ChiaTransaction {
    [CmdletBinding()]
    param(
        $transaction_id
    )

    $h_params = @{
        transaction_id = $transaction_id
    }
    $result = _ChiaApiCall -api wallet -function "get_transaction" -params $h_params
}


Function Get-ChiaOffers {
    [CmdletBinding()]
    param(
        $start = 0,
        $end = 50
    )

    $h_params = @{
        start = $start
        end   = $end
    }

    $result = _ChiaApiCall -api wallet -function "get_all_offers"
    $result.trade_records
}

Function Get-ChiaOffer {
    [CmdletBinding()]
    param(
        $trade_id
    )

    $h_params = @{
        trade_id = $trade_id
    }
    $result = _ChiaApiCall -api wallet -function "get_offer" -params $h_params
    $result.trade_record
}

Function New-ChiaOffer {
    param(
        [Parameter(Mandatory = $true)]
        $offerAsset,
        $offerCount = 1,
        [Parameter(Mandatory = $true)]
        $requestAsset,
        $requestCount = 1,
        $fee = 50000000 / 1e12
    )

    <#
    offer or request Asset can be:
    - a Chia Wallet (type 0)
    - a CAT Wallet (type 6)
    - a NFT (need launcher_id aka launcher coin id of NFT)
    #>

    $fee = $fee * 1e12

    if ($offerAsset.GetType().Name -eq "String") {
        if ($offerAsset -like "0x*") {
            #Should be a launcher_id
            $offerAsset = $offerAsset -replace '^0x', ''
        }
        else {
            #would be Name of a Wallet -> need id
            $offerAsset = (Get-ChiaWallets | Where-Object { $_.name -eq $offerAsset }).id
        }
        
    }
    elseif ($offerAsset.type -eq 0) {
        #Chia (0) Offer
        $offercount *= 1e12
        $offerAsset = $offerAsset.id
    }
    elseif ($offerAsset.type -eq 6) {
        #CAT (6) offer
        $offercount *= 1e3
        $offerAsset = $offerAsset.id
    }
    elseif ($offerAsset.launcher_id -like "0x*") {
        #Its a NFT, get its launcher_id
        $offerAsset = $offerAsset.launcher_id -replace '^0x', ''
    }


    if ($requestAsset.GetType().Name -eq "String") {
        if ($requestAsset -like "0x*") {
            #Should be a launcher_id
            $requestAsset = $requestAsset -replace '^0x', ''
        }
        else {
            #Would be Wallet Name -> need id
            $requestAsset = (Get-ChiaWallets | Where-Object { $_.name -eq $requestAsset }).id
        }
        
    }
    elseif ($requestAsset.type -eq 0) {
        #Chia (0) Offer
        $requestCount *= 1e12
        $requestAsset = $requestAsset.id
    }
    elseif ($requestAsset.type -eq 6) {
        #CAT (6) offer
        $requestCount *= 1e3
        $requestAsset = $requestAsset.id
    }
    elseif ($requestAsset.launcher_id -like "0x*") {
        #Its a NFT, get its launcher_id
        $requestAsset = $requestAsset.launcher_id -replace '^0x', ''
    }

    $h_params = @{
        "offer" = @{
            "$requestAsset" = ($requestCount)
            "$offerAsset"   = ($offerCount * -1)
        }
        "fee"   = $fee
    }

    #$h_params

    $result = _ChiaApiCall -api wallet -function "create_offer_for_ids" -params $h_params
    $result.offer
}


Function Remove-ChiaOffer {
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
Show-ChiaOffers | Where-Object status -eq "PENDING_ACCEPT" | Remove-Offer

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
        [Parameter(ValueFromPipeline = $true)]
        $trade_ids,
        [bool]$secure = $true
    )

    Begin {}

    Process {

        $trade_ids | ForEach-Object {
            $trade_id = $_

            #if there is directly a offer object
            if ($trade_id.GetType().Name -ne "String") {
                $trade_id = $trade_id.trade_id
            }

            $h_params = @{
                trade_id = $trade_id
                secure   = $secure
            }
            $result = _ChiaApiCall -api wallet -function "cancel_offer" -params $h_params

            [PSCustomObject]([ordered]@{
                    trade_id = $trade_id
                    success  = $result.success
                })
        }


    }
}

Function Show-ChiaOffers {
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
Show-ChiaOffers | %{Get-ChiaNftInfo -coin_id $_.requested_item} | %{Start-Process $_.data_uris[0]}

.NOTES
General notes
#>
    [CmdletBinding()]
    param(
        $start = 0,
        $end = 100
    )
    $offers = Get-ChiaOffers -start $start -end $end
    $offers | ForEach-Object {
        $offer = $_
        [PSCustomObject]@{
            created_at_time = $offer.created_at_time
            DateCreated     = [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($offer.created_at_time))
            is_my_offer     = $offer.is_my_offer
            status          = $offer.status
            offered         = $offer.summary.offered
            requested_item  = $offer.summary.requested.PsObject.Properties.Name
            requested_count = $offer.summary.requested.PsObject.Properties.Value
            trade_id        = $offer.trade_id
        }

    }
}

Function Get-ChiaTransaction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$transaction_id
    )

    $h_params = @{
        transaction_id = $transaction_id
    }

    $result = _ChiaApiCall -api wallet -function "get_transaction" -params $h_params
    $result.transaction
}


Function Get-ChiaNftInfo {
    <#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER coin_id
Parameter description

.PARAMETER errorType
Parameter description

.EXAMPLE
$start=(Get-ChiaBlockHeight -Date "2022-05-01").BlockHeight
Get-ChiaNftRecords -start $start | Get-ChiaNftInfo

.NOTES
General notes
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Alias("NftId")]
        $coin_ids,
        [Switch]$NoCache
    )

    Begin {

        #Write-Host("Totaler Blödsinn zum testen")

        $NftCacheDir = $global:ModConf.ChiaShell.DataDir + "/nft"
        if (-not (Test-Path $NftCacheDir)) {
            New-Item -ItemType Directory -Path $NftCacheDir
        }
    }

    Process {
        $coin_ids | ForEach-Object {
            $coin_id = $_

            #Write-Host("coin_id:" + $coin_id)

            if ($null -ne $coin_id.nft_coin_id) {
                $coin_id = $coin_id.nft_coin_id
            }
            elseif ($null -ne $coin_id.nft_info.nft_coin_id) {
                $coin_id = $coin_id.nft_info.nft_coin_id
            }
            elseif ($null -ne $coin_id.coin.parent_coin_info) {
                $coin_id = $coin_id.coin.parent_coin_info
            }

            $h_params = @{
                coin_id = $coin_id
            }

            #Write-Host($h_params.coin_id)
        
            $cacheFilePath = ($NftCacheDir + "/" + $coin_id + ".cli.xml")
            if ((Test-Path $cacheFilePath) -and (-not $NoCache)) {
                $nftInfo = Import-CliXml -Path $cacheFilePath
            }
            else {
                $result = _ChiaApiCall -api wallet -function "nft_get_info" -params $h_params -errorType verboseonly
                $nftInfo = $result.nft_info
                $nftInfo | Export-Clixml -Path $cacheFilePath
            }
            #Ausgabe
            $nftInfo
    
        }
    }

    End {}
}


Function Show-ChiaNftInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Alias("NftId")]
        [string]$coin_ids,
        $View = "Metadata",
        $Columns = @("name", @{
                label      = 'CollectionName'
                expression = { ($_.collection.name) }
            },
            "description", "nft_coin_id")
    )
    $result = Get-ChiaNftInfo -coin_ids $coin_ids
    

    Switch ($View) {
        "Metadata" {
            $result | ForEach-Object {
                $nft = $_
                Get-ChiaNftMetadata -nfts $nft
            } | Select-Object $Columns
        }
        "Select" {
            $result  | Select-Object $Columns
            break
        }
        "Table" {
            $result  | Format-Table $Columns
            break
        }
        "List" {
            $result  | Format-List $Columns
            break
        }
        "Grid" {
            $result | ForEach-Object {
                $nft = $_
                Get-ChiaNftMetadata -nfts $nft
            } | Select-Object $Columns | Out-ConsoleGridView
            break
        }
    }
}

Function Get-ChiaNftMetadata {
    <#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER nfts
Parameter description

.EXAMPLE
Get-ChiaNfts | Get-ChiaNftInfo | Get-ChiaNftMetadata

.NOTES
General notes
#>
    param(
        [Parameter(ValueFromPipeline = $true)]
        $nfts,
        $TimeoutSec = 5
    )

    Begin {}

    Process {

        $nfts | ForEach-Object {
            $nft = $_

            if ($nft.GetType().Name -eq "String") {
                $nft = Get-ChiaNftInfo -coin_ids $nft
            }

            $metadata = $null
            $MetadataCacheDir = $global:ModConf.ChiaShell.DataDir + "/nft_metadata"
            if (-not (Test-Path $MetadataCacheDir)) { mkdir $MetadataCacheDir }
            $cacheFilePath = ($MetadataCacheDir + "/" + $nft.nft_coin_id + ".cli.xml")

            if (Test-Path -Path $cacheFilePath) {
                $metadata = Import-Clixml -Path $cacheFilePath
                $metadata
            }
            else {
                for ($i = 0; $i -lt $nft.metadata_uris.Count -and $null -eq $metadata; $i++) {
                    Write-Verbose ("Trying Metadata Uri: " + $nft.metadata_uris[$i])
                    Try {
                        $metadata = Invoke-RestMethod -Uri $nft.metadata_uris[$i] -TimeoutSec $TimeoutSec
                    }
                    Catch {
                        Write-Warning("Could not fetch metadata for nft_coin_id " + $nft.nft_coin_id + "from " + $nft.metadata_uris[$i])
                    }
                }
                if ($null -ne $metadata) {
                    $metadata | Add-Member -MemberType "NoteProperty" -Name "nft_coin_id" -Value ($nft.nft_coin_id)
                    $metadata | Add-Member -MemberType "NoteProperty" -Name "SpaceScanLink" -Value ("https://www.spacescan.io/xch/coin/" + $nft.nft_coin_id)
                    $metadata | Export-Clixml -Path $cacheFilePath
                    $metadata
                }
            }

        }
    }

    End {}
}

Function Show-ChiaNftOffers {
    <#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER offerType
Parameter description

.PARAMETER start
Parameter description

.PARAMETER end
Parameter description

.EXAMPLE
Show-ChiaNftOffers | Where-Object {$_.nft_info.name -like "Khopesh*"}

.NOTES
General notes
#>
    [CmdletBinding()]
    param(
        [ValidateSet("offered", "requested")]
        $offerType = "offered",
        $start = 0,
        $end = 50
    )
    

    (Get-ChiaOffers -start $start -end $end) | Where-Object { $_.summary.$offerType.PsObject.Properties.Name.Length -gt 5 } | forEach-Object {
        $offer = $_
        #$offer.summary.$offerType.PsObject.Properties.Name
        $nftInfo = Show-ChiaNftInfo -coin_ids ("0x" + $offer.summary.$offerType.PsObject.Properties.Name)
        #$offer

        if ($offerType -eq "offered") {
            [PSCustomObject][ordered]@{
                offered_name = $nftInfo.name
                requested    = $offer.summary.requested
                status       = $offer.status
                nft_info     = $nftInfo
                trade_id     = $offer.trade_id
            }
        }
        if ($offerType -eq "requested") {
            [PSCustomObject][ordered]@{
                requested_name = $nftInfo.name
                offered        = $offer.summary.offered
                status         = $offer.status
                nft_info       = $nftInfo
                trade_id       = $offer.trade_id
            }

        }
    }
}

Function Select-ChiaNftOffers {
    [CmdletBinding()]
    param(
        [ValidateSet("offered", "requested")]
        $offerType = "offered"
    )

    Show-ChiaNftOffers -offerType $offerType | Out-ConsoleGridView
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
        [int]$wallet_id = $ChiaShell.Run.SelectedWallet.id,
        [Parameter(Mandatory = $true)]
        [int64]$amount,
        [int64]$fee = 0,
        [Parameter(Mandatory = $true)]
        [string]$address,
        $memos
    )

    $h_params = @{
        wallet_id = $wallet_id
        amount    = [int64]$amount
        fee       = [int64]$fee
        address   = $address
    }

    if ($null -ne $memos) {
        #memos is expected as array
        if ($memos.GetType().Name -eq "String") {
            $memos = @($memos)
        }
        $h_params.Add("memos", $memos)
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
        [Parameter(Mandatory = $true)]
        $myAddress,
        [Parameter(Mandatory = $true)]
        $AmountXch,
        $fee = 0,
        $memo = "coinSplit",
        $splitTimes = 1
    )

    $amount = $AmountXch * 1e12

    $wallet = Get-ChiaWallets | Where-Object name -eq "Chia Wallet"

    for ($i = 1; $i -le $splitTimes; $i++) {

        #chia wallet send --address $myAddress --amount $amount --memo $memo --fee 0
        $transaction = Send-ChiaTransaction -wallet_id $wallet.id -amount $amount -fee $fee -address $myAddress -memos $memo
        if ($null -ne $transaction) {
            #Check Transaction Status
            do {
                Write-Host("$i of $splitTimes Transaction " + $transaction.name + " with " + ("{0:n12}" -f ($transaction.amount * 1e-12)) + " XCH sent to " + $transaction.to_address + " is not confirmed yet")
                Start-Sleep -Seconds 10
                $checkTransaction = Get-ChiaTransaction -transaction_id $transaction.name
            }while ($checkTransaction.confirmed -eq $false)
            Write-Host("$i of $splitTimes Transaction " + $transaction.name + " is confirmed")
        }
        else {
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
        [Parameter(Mandatory = $true)]
        $myAddress,
        $fee = 0,
        $memo = "coinSplit",
        $splitTimes = 1
    )

    $wallet = Get-ChiaWallets | Where-Object name -eq "Chia Wallet"
    $walletBalance = Get-ChiaWalletBalance -wallet_id $wallet.id
    [int64]$splitAmount = $walletBalance.confirmed_wallet_balance

    for ($i = 1; $i -le $splitTimes; $i++) {
        [int64]$splitAmount = $splitAmount / 2
        #chia wallet send --address $myAddress --amount $amount --memo $memo --fee 0
        $transaction = Send-ChiaTransaction -wallet_id $wallet.id -amount $splitAmount -fee $fee -address $myAddress -memos $memo
        if ($null -ne $transaction) {
            #Check Transaction Status
            do {
                Write-Host("$i of $splitTimes Transaction " + $transaction.name + " with " + ("{0:n12}" -f ($transaction.amount * 1e-12)) + " XCH sent to " + $transaction.to_address + " is not confirmed yet")
                Start-Sleep -Seconds 10
                $checkTransaction = Get-ChiaTransaction -transaction_id $transaction.name
            }while ($checkTransaction.confirmed -eq $false)
            Write-Host("$i of $splitTimes Transaction " + $transaction.name + " is confirmed")
        }
        else {
            Write-Error("Error in creating transaction")
        }
    }
}


Function Get-ChiaNetworkInfo {
    _ChiaApiCall -api FullNode -function "get_network_info"
}

Function Get-ChiaBlockchainState {
    $result = _ChiaApiCall -api FullNode -function "get_blockchain_state"
    $result.blockchain_state
}


Function Get-ChiaBlocks {
    [CmdletBinding()]
    param(
        $start = ((Get-ChiaBlockchainState).peak.height - 20),
        $end = ((Get-ChiaBlockchainState).peak.height)
    )

    $page_start = $start
    $page_end = 0
    $page_size = 20

    while ($page_end -lt $end) {
        $page_end = $end
        if ($page_end - $page_start -gt $page_size) {
            $page_end = $page_start + $page_size
        }

        $h_params = @{
            start = $page_start
            end   = $page_end
        }
        Write-Verbose("Getting Blocks from $page_start to $page_end")
        $result = _ChiaApiCall -api FullNode -function "get_blocks" -params $h_params
        $result.blocks

        $page_start += $page_size
    }
}

Function Get-ChiaBlock {
    param(
        $header_hash
    )
    $h_params = @{
        header_hash = $header_hash
    }
    $result = _ChiaApiCall -api FullNode -function "get_block" -params $h_params
    $result.block
}

Function Get-ChiaBlockRecords {
    param(
        $start = ((Get-ChiaBlockchainState).peak.height - 20),
        $end = ((Get-ChiaBlockchainState).peak.height)
    )
    $h_params = @{
        start = $start
        end   = $end
    }
    $result = _ChiaApiCall -api FullNode -function "get_block_records" -params $h_params
    $result.block_records
}


Function Get-ChiaAdditionsAndRemovals {
    param(
        [Parameter(ValueFromPipeline = $true)]
        $header_hash
    )

    Begin {}

    Process {
        $header_hash | ForEach-Object {
            $hHash = $_
            if ($hHash.GetType().Name -ne "String") {
                $hHash = $hHash.header_hash
            }
            $h_params = @{
                header_hash = $hHash
                
            }
            $result = _ChiaApiCall -api FullNode -function "get_additions_and_removals" -params $h_params
            $result | ForEach-Object {
                $res = $_
                foreach ($prop in @("additions", "removals")) {
                    for ($i = 0; $i -lt $result.$prop.count; $i++) {
                        Add-Member -InputObject $res.$prop[$i] -MemberType NoteProperty -Name DateTime `
                            -Value ([timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($res.$prop[$i].timestamp))) -Force
                        
                    }
                }
                $res
            }
        }
    }

    End {}
}


Function Get-ChiaCoinRecordsByPuzzleHash {
    param(
        [Parameter(Mandatory = $true)]
        $puzzle_hash,
        #TODO get height from current height
        $start_height = ((Get-ChiaBlockchainState).peak.height - 20),
        $end_height = ((Get-ChiaBlockchainState).peak.height)
    )
    $h_params = @{
        puzzle_hash  = $puzzle_hash
        start_height = $start_height
        end_height   = $end_height
    }
    $result = _ChiaApiCall -api FullNode -function "get_coin_records_by_puzzle_hash" -params $h_params
    $result.coin_records
}

Function Get-ChiaCoinRecordsByParentIds {
    param(
        [Parameter(Mandatory = $true)]
        $parent_ids,
        [bool]$include_spent_coins = $true,
        #TODO get height from current height
        $start_height = ((Get-ChiaBlockchainState).peak.height - 20),
        $end_height = ((Get-ChiaBlockchainState).peak.height)
    )

    if ($parent_ids.GetType().Name -eq "String") {
        $parent_ids = @($parent_ids)
    }

    $h_params = @{
        parent_ids          = $parent_ids
        include_spent_coins = $include_spent_coins
        start_height        = $start_height
        end_height          = $end_height
    }
    $result = _ChiaApiCall -api FullNode -function "get_coin_records_by_parent_ids" -params $h_params
    $result.coin_records
}


function Get-ChiaOfferSummary {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        $offer
    )
    
    begin {
        $aFiles = @()
    }
    
    process {
        if ($null -ne $file) {
            $offer | ForEach-Object {
                $oFile = $_
                if ($oFile.GetType().Name -eq "String") {
                    $oFile = Get-Item -Path $oFile
                }
                $aFiles += $oFile
            }
        }
    }
    
    end {
        if ($aFiles.count -gt 0) {
            $aFiles | ForEach-Object {
                $file = $_
                $fileContent = (Get-Content $file.FullName) -join "`r`n"

                $h_params = @{
                    offer = $fileContent
                }
                $result = _ChiaApiCall -api Wallet -function "get_offer_summary" -params $h_params
                $summary = $result.summary
                Add-Member -InputObject $summary -MemberType NoteProperty -Name File -Value $file
                $summary
            }

        }
    }
}


function Confirm-ChiaOffer {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        $offer,
        $fee = 0,
        [switch]$Confirm = $true
    )
    
    begin {
        $aFiles = @()
    }
    
    process {
        if ($null -ne $file) {
            $offer | ForEach-Object {
                $oFile = $_
                if ($oFile.GetType().Name -eq "String") {
                    $oFile = Get-Item -Path $oFile
                }
                elseif ($oFile.GetType().Name -eq "PSCustomObject") {
                    $oFile = $oFile.File
                }
                $aFiles += $oFile
            }
        }
    }
    
    end {
        if ($aFiles.count -gt 0) {
            $aFiles | ForEach-Object {
                $file = $_
                $fileContent = (Get-Content $file.FullName) -join "`r`n"


                Write-Host("Offer Summary:")
                Write-Host(Get-ChiaOfferSummary -offer $file | Format-List | Out-String)
                
                $doit = $false
                if ($Confirm) {
                    Write-Host("This will take this Offer")
                    $answer = Read-Host -Prompt "Are you sure? (y|n)"
                    if ($answer -eq "y") { $doit = $true }
                }
                else {
                    $doit = $true
                }

                if ($doit) {
                    $h_params = @{
                        offer = $fileContent
                        fee   = $fee
                    }
                    $result = _ChiaApiCall -api Wallet -function "take_offer" -params $h_params
                    if ($result.success) {
                        $result.trade_record
                    }
                    else {
                        $false
                    }
                }
            }
        }
    }
}

function Get-ChiaNftRecords {
    [CmdletBinding()]
    param(
        $start = ((Get-ChiaBlockchainState).peak.height - 20),
        $end = ((Get-ChiaBlockchainState).peak.height)
    )
    
    begin {
        
    }
    
    process {
        
    }
    
    end {
        Get-ChiaBlocks -start $start -end $end | 
        Get-ChiaAdditionsAndRemovals | 
        ForEach-Object {
            $record = $_
            $record.additions
            $record.removals
        } | Where-Object { $_.coin.amount -eq 1 }
    }
}

function Show-Tree {
    [CmdletBinding()]
    [Alias("tree")]
    [OutputType([string[]])]
    Param
    (
        [Parameter(Position = 0)]
        $Path = (pwd),

        [Parameter()]
        [int]$MaxDepth = [int]::MaxValue,

        #Show the full name of the directory at each sublevel
        [Parameter()]
        [Switch]$ShowDirectory, 

        #List of wildcard matches. If a directoryname matches one of these, it will be skipped.
        [Parameter()]
        [String[]]$NotLike = $null,
 
        #List of wildcard matches. If a directoryname matches one of these, it will be shown.
        [Parameter()]
        [String[]]$Like = $null,
 
        #Internal parameter used in recursion for formating purposes
        [Parameter()]
        [int]$_Depth = 0
    )

    if ($_Depth -ge $MaxDepth) {
        return
    }
    $FirstDirectoryShown = $False
    $start = "| " * $_Depth
    :NextDirectory foreach ($d in Get-ChildItem $path -ErrorAction Ignore | where PSIsContainer -eq $true) {
        foreach ($pattern in $NotLike) {
            if ($d.PSChildName -like $pattern) {
                Write-Verbose "Skipping $($d.PSChildName). Not like $Pattern"
                continue NextDirectory;
            }
        }
        $ShowThisDirectory = $false
        if (!$like) {
            $ShowThisDirectory = $true
        }
        else {
            foreach ($pattern in $Like) {
                if ($d.PSChildName -like $pattern) {
                    Write-Verbose "Including $($d.PSChildName). Like $Pattern"
                    $ShowThisDirectory = $true
                    Break;
                }
            }            
        }
        # When we dir a Get-ChildItem, we get the OS view of the object so here we need to transform
        # it into the PowerShell view of the path (e.g. to deal with PSDrives with deep ROOT directories)
        $ProviderPath = $ExecutionContext.SessionState.Path.GetResolvedProviderPathFromPSPath($d.PSPath, [Ref]$d.PSProvider)
        $RootRelativePath = $ProviderPath.SubString($d.PSDrive.Root.Length)
        $PSDriveFullPath = Join-Path ($d.PSDrive.Name + ":") $RootRelativePath

        if ($ShowThisDirectory) {
            if (($FirstDirectoryShown -eq $FALSE) -and $ShowDirectory) {
                $FirstDirectoryShown = $True
                Write-Output ("{0}{1}" -f $start, $Path)
            }
            Write-Output ("{0}+---{1}" -f $start, (Split-Path $PSDriveFullPath -Leaf))
        }
        show-Tree -path:$PSDriveFullPath -_Depth:($_Depth + 1) -ShowDirectory:$ShowDirectory -MaxDepth:$MaxDepth -NotLike:$NotLike -Like:$Like
    }    
}

Register-ArgumentCompleter -CommandName Get-ChiaWalletBalance -ParameterName wallet_id -ScriptBlock $Global:ChiaShellArgumentCompleters.WalletId
Register-ArgumentCompleter -CommandName _ChiaApiCall -ParameterName api -ScriptBlock $Global:ChiaShellArgumentCompleters.ApiName

function Convert-NftHtml {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        $Nfts,
        $Properties,
        $Class = "nft_metadata"
    )

    Begin {}

    Process {
        $Nfts | ForEach-Object {
            $Nft = $_

            $NftInfo = Get-ChiaNftInfo -coin_ids $Nft
            $NftMetadata = Get-ChiaNftMetadata -nfts $Nft

            $out = ''
            $out += '<div class="' + $Class + '" style="width:400px; height:600px;">' + "`r`n"
            $out += '<img src="' + $Nft.data_uris[0] + '" style="width:400px;max-height:400px;"><br/>' + "`r`n"

            $out += '<a href="' + $NftMetadata.SpaceScanLink + '">' + "CoinId" + ': ' + $nftInfo.nft_coin_id.Substring(0, 20) + '...</a><br/>' + "`r`n"
            $out += "Name" + ': ' + $NftMetadata.name + '<br/>' + "`r`n"
            $out += "Description" + ': ' + $NftMetadata.description + '<br/>' + "`r`n"
            $out += "CollectionName" + ': ' + $NftMetadata.collection.name + '<br/>' + "`r`n"
            $out += "CollectionId" + ': ' + $NftMetadata.collection.id + '<br/>' + "`r`n"


            ForEach ($trait in $NftMetadata.attributes) {
                if ($null -ne $trait.trait_type -and "" -ne $trait.trait_type) {
                    if ($null -ne $Properties) {
                        if ($trait.trait_type -in $Properties) {
                            $out += $trait.trait_type + ': ' + $trait.value + '<br/>' + "`r`n"
                        }
                    }
                    else {
                        $out += $trait.trait_type + ': ' + $trait.value + '<br/>' + "`r`n"
                    }
                    
                }
            }
            $out += '</div>' + "`r`n"
            $out
        }
    }
    End {}
}


function Add-IpfsFile {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        $files
    )

    Begin {}

    Process {
        $files | ForEach-Object {
            $file = $_

            if ($file.GetType().Name -eq "String") {
                $file = Get-Item -Path $file
            }

            $fileHashPath = ($file.Directory.FullName + "/" + $file.BaseName + ".ipfs.txt")
            if (-not (Test-Path $fileHashPath)) {
                $fileHash = ipfs add -Q $file.FullName
                Set-Content -Path ($fileHashPath) -Value $fileHash
            }
            else {
                $fileHash = Get-Content -Path $fileHashPath
            }
            $file | Add-Member -MemberType NoteProperty -Name IpfsHash -Value $fileHash
            $file
        }
    }

    End {}
}

function New-ChiaNftCollection {
    <#
.SYNOPSIS
Prepares a new Chia NFT Collection

.DESCRIPTION
This prepares a new Chia NFT Collection. Basically
a collection.json File is written to the collection
folder defining the properties the collection should have

.PARAMETER folder
Folder where the collection files are in

.PARAMETER name
Name of the collection

.PARAMETER description
longer description of the collection

.PARAMETER icon
File that will be used as icon (will be added to IPFS)

.PARAMETER banner
File that will be used as banner (will be added to IPFS)

.PARAMETER twitter
Twitter Name of artist (starting with @)

.PARAMETER website
Website for the collection

.EXAMPLE
New-ChiaNftCollection -folder . -name Chreatures -description "A collection of creatures" -twitter "@Chreatures1" -website "https://twitter.com/Chreatures1" -icon ./icon.jpeg -banner ./banner.png
#>
    param(
        $folder = ".",
        $name,
        $description,
        $icon = (Get-Item -Path "icon.???").FullName,
        $banner = (Get-Item -Path "banner.???").FullName,
        $twitter,
        $website
    )


    $attributes = @{}

    if ($null -ne $icon) {
        $iconIpfs = Add-IPfsFile -files $icon
        $iconUrl = $global:ChiaShell.Ipfs.UrlPrefix + "/" + $iconIpfs.IPfsHash
        $attributes.icon = $iconUrl
    }
    
    if ($null -ne $banner) {
        $bannerIpfs = Add-IpfsFile -files $banner
        $bannerUrl = $global:ChiaShell.Ipfs.UrlPrefix + "/" + $bannerIpfs.IPfsHash
        $attributes.banner = $bannerUrl
    }


    forEach ($attribute in @("description", "twitter", "website")) {
        if ($null -ne $PSBoundParameters.$attribute) {
            $attributes.Add($attribute, $PSBoundParameters.$attribute)
        }
    }

    $a_attrs = @()

    forEach ($attr in $attributes.GetEnumerator()) {
        $a_attrs += @{
            type  = $attr.Name
            value = $attr.Value
        }
    }

    $h_collectionProps = @{
        name       = $name
        id         = (New-Guid).Guid
        attributes = $a_attrs
    }
    $colDefPath = ($folder + "/collection.json")
    $h_collectionProps | ConvertTo-Json | Set-Content -Encoding UTF8 -Path $colDefPath
    # return generated Json File
    Get-Item -Path $colDefPath
}

function Get-ChiaTxFromSpacescan {
    <#
    .SYNOPSIS
    Converts Chia Transactions to Accointing CSV Entries.
    WAIT FOR WALLET TO SYNCHRONIZE!
    
    .DESCRIPTION
    Converts Chia Transactions to Accointing CSV Entries.
    WAIT FOR WALLET TO SYNCHRONIZE!
    
    Wallet Name First word should be SYMBOL
    
    .EXAMPLE
    An example
    
    .NOTES
    Wallet Types:
    
    type:
    1   Chia
    6   CAT
    9   Pool Wallet
    10  NFT Wallet
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
        $KeyFingerprint=(Get-ChiaKey),
        $FarmingRewardAddresses=@(
            "xch16hxy80yteu9a0pdtkae58mkmdx85m0cjqhagvqya79de2adk07rqa0cd7c"
        )
    )
    Begin{
        $typeDesc = @{
            "0" = "TxIn"
            "1" = "TxOut"
            "2" = "CoinbaseReward"
            "3" = "FeeReward"
            "4" = "TradeIn"
            "5" = "TradeOut"
        }
        $pageCount=50
    }

    Process{
        $KeyFingerprint | ForEach-Object {
            $key=$_
            Use-ChiaKey -fingerprint $key
            $Addresses=Get-ChiaTransactions -Wallet (Get-ChiaWallets) | Where-Object{$_.type -eq "0"} | ForEach-Object{$_.to_address} | Sort-Object -Unique
            $Addresses | ForEach-Object {
                $addr=$_
                $page=1
                $mycoins=@()
                $rows=@()
                # api2.spacescan.io Examples
                # https://api2.spacescan.io/1/xch/address/txns/xch16hxy80yteu9a0pdtkae58mkmdx85m0cjqhagvqya79de2adk07rqa0cd7c?page=1&count=50
                # https://api2.spacescan.io/1/xch/address/txns/xch16hxy80yteu9a0pdtkae58mkmdx85m0cjqhagvqya79de2adk07rqa0cd7c?page=12&count=50&timestamp=1637622098
                # https://api2.spacescan.io/1/xch/address/txns/xch16hxy80yteu9a0pdtkae58mkmdx85m0cjqhagvqya79de2adk07rqa0cd7c?page=13&count=50&timestamp=1631638832                    
                # Collect all Coins from Paging
                $nextTs = $null
                do{
                    $requestUri = ("https://api2.spacescan.io/1/xch/address/txns/" + $addr + "?page=$page" + "&count=$pageCount")
                    if($null -ne $nextTs){$requestUri += "&timestamp=" + $nextTs}
                    Write-Verbose($requestUri)
                    $result=Invoke-RestMethod -Uri $requestUri -TimeoutSec 2
                    foreach($coin in $result.data.coins){
                        # Paging is not exact. Could be i get the same coins two times
                        # Spacescan selects page by timestamp and not by exact id
                        $bech32m=[chia.dotnet.bech32.Bech32M]::new("xch")
                        if($coin.coin_name -notin $mycoins.coin_name){
                            $h_mycoin=[ordered]@{
                                "coin_name" = $coin.coin_name
                                "confirmed_index" = $coin.confirmed_index
                                "spent_index" = $coin.spent_index
                                "coinbase" = $coin.coinbase
                                "from_address" = $bech32m.PuzzleHashToAddress($coin.from_puzzle_hash)
                                "to_address" = $bech32m.PuzzleHashToAddress($coin.puzzle_hash)
                                "time" = Convert-UnixTimestampToDatetime -UnixDate $coin.timestamp
                                "type" = $coin.type
                            }

                            if($null -eq $coin.symbol){
                                $h_mycoin.symbol="XCH"
                                $h_mycoin.amount=[double]$coin.amount / 1E12
                            }
                            else{
                                $h_mycoin.symbol=$coin.symbol
                                $h_mycoin.amount=$coin.amount
                            }

                            if($h_mycoin.to_address -eq $addr){
                                $h_mycoin.direction = "received"
                            }
                            else{
                                $h_mycoin.direction = "sent"
                            }

                            $mycoin=[PSCustomObject]$h_mycoin

                            $mycoins+=$mycoin
                        }
                    }
                    $rows+=$result.data
                    $nextTs=($result.data.coins | Sort-Object timestamp | Select-Object -Last 1).timestamp
                    $page++
                }while($mycoins.count -lt $result.data.rowCount)
                # Ausgabe
                $mycoins
            }
        }
    }
    End{}
        
}

Function Invoke-BladebitPlotter {
    [CmdletBinding()]
    param(
        [ValidateScript({Test-Path -Path $_ -PathType Container})]
        $DestDir="/mnt/qnap/chiafarm01/plot/bladebit/",
        [ValidateScript({Test-Path -Path $_ -PathType Container})]
        $TempDir=$global:ChiaShell.Plot.HybridDir,
        $CompressLevel=5,
        $Count=1
    )
    # Empty Temp Dir
    Get-Item ($TempDir + "*.tmp") | Remove-Item -Confirm:$false
    $PlotTmpPattern=((Get-Item $DestDir).FullName -replace '\\','/') + '/plot-.*.tmp'
    $PlotPattern=((Get-Item $DestDir).FullName -replace '\\','/') + '/plot-.*.plot'
    $ProgressPercent=10
    # This is the actual bladebit command. Have to modify it when i have a different binary or a different method
    nice bladebit_cuda -c $global:ChiaShell.Plot.PoolContractAddress -f $global:ChiaShell.Plot.FarmerPublicKey --compress $CompressLevel -n $Count cudaplot --disk-128 "-t1" $TempDir $DestDir | 
        ForEach-Object { # executes for each line of output
            $line = $_
            Write-Verbose($line)

            if ($line -match 'Generating plot ([0-9]+) / ([0-9]+)'){ 
                $CurrentPlotNr = [int]$Matches[1]
                $TotalPlotNr = [int]$Matches[2]
            }
            if ($line -match 'Completed Phase 1 .*'){ $ProgressPercent= 30 * $CurrentPlotNr / $TotalPlotNr}
            if ($line -match 'Completed Phase 2 .*'){ $ProgressPercent= 60 * $CurrentPlotNr / $TotalPlotNr}
            if ($line -match 'Completed Phase 3 .*'){ $ProgressPercent= 90 * $CurrentPlotNr / $TotalPlotNr}
            $StatusLine = (Get-Date -Format "yyyy-MM-dd HH:mm:ss") + " : " + "Plot $CurrentPlotNr of $TotalPlotNr : " + $line
            Write-Progress -Id 5 -Activity "Plotting" -Status $StatusLine -PercentComplete $ProgressPercent
            if ($line -match ('(' + $PlotTmpPattern + ') -> (' + $PlotPattern + ')')) {
                $tempPlotPath = $Matches[1]
                $PlotPath = $Matches[2]
                Start-Sleep -Milliseconds 300
                # Should return the ready Plot File
                Get-Item -Path $PlotPath
            }
        }
    Write-Progress -Id 5 -Activity "Plotting" -Status "Finished" -PercentComplete 100 -Completed
}

Function Get-GhorsePlots {
    $global:ChiaShell.Plot.FarmDirs | ForEach-Object {
        $PlotDir = $_
        if($PlotDir.GetType().Name -eq "String"){
            $PlotDir = Get-Item -Path $PlotDir
        }
        Get-Item -Path ($PlotDir.FullName + "/plot/ghorse/*.plot")
    }
}

Function Replace-GhorsePlots {
    Write-Progress -Id 1 -Activity "Replacing Ghorse Plots" -Status "Starting" -PercentComplete 0
    $PlotCount = Get-GhorsePlots | Measure-Object | Select-Object -ExpandProperty Count
    $i=0
    Get-GhorsePlots | ForEach-Object {
        $PlotFile = $_
        Write-Progress -Id 1 -Activity "Replacing Ghorse Plots" -Status ("{0} of {1} Plots replaced. Replacing {2}" -f $i, $PlotCount, $PlotFile.Name) -PercentComplete ($i / $PlotCount * 100)
        #Remove on Ghorse Plot and instead plot one Bladebit Plot
        $NewPlotDestPath=$PlotFile.DirectoryName.Replace("/ghorse", "/bladebit")
        # Write-Host("Replacing " + $PlotFile.FullName + " with a new plot in " + $NewPlotDestPath)
        Remove-Item -Path $PlotFile.FullName -Confirm:$false
        # Create PlotJob to reference to the ID later
        $PlotJob = Start-Job -ArgumentList @($NewPlotDestPath) -ScriptBlock {
            param(
                $NewPlotDestPath
            )
            # To be sure we have the Module on the new process
            Import-Module -Name ChiaShell -DisableNameChecking
            # This lasts really long and prints a lot on stdout
            Invoke-BladebitPlotter -DestDir $NewPlotDestPath -Count 1
            # Start-Sleep -Seconds 1
        }

        #Wait for PlotJob to finish and show progress
        do {
            Start-Sleep -Seconds 2
            $PlotJob = Get-Job -Id $PlotJob.Id
            Write-Progress -Id 1 -Activity "Replacing Ghorse Plots" -Status ("{0} of {1} Plots replaced. Replacing {2}" -f $i, $PlotCount, $PlotFile.Name) -PercentComplete ($i / $PlotCount * 100)
            Receive-Job -Job $PlotJob
        } while ($PlotJob.State -eq "Running")
        # Finished -> Remove
        Remove-Job -Id $PlotJob.Id
        $i++
    }
    Write-Progress -Id 1 -Activity "Replacing Ghorse Plots" -Status "Finished" -PercentComplete 100 -Completed
    
}

function Get-ChiaSpendableCoins {
    [CmdletBinding()]
    param (
        $WalletId = $ChiaShell.Run.SelectedWallet.id
    )

    if($Wallet.GetType().Name -eq "PsCustomObject"){
        $WalletId = $Wallet.id
    }

    $result = _ChiaApiCall -api "Wallet" -function "get_spendable_coins" -params @{wallet_id=$WalletId}
    $result.confirmed_records

}


Register-ArgumentCompleter -CommandName Get-ChiaWalletBalance -ParameterName wallet_id -ScriptBlock $Global:ChiaShellArgumentCompleters.WalletId
Register-ArgumentCompleter -CommandName _ChiaApiCall -ParameterName api -ScriptBlock $Global:ChiaShellArgumentCompleters.ApiName

Register-ArgumentCompleter -CommandName Get-ChiaNfts -ParameterName "wallet_id" -ScriptBlock $Global:ChiaShellArgumentCompleters.NftWallet
Register-ArgumentCompleter -CommandName Show-ChiaNfts -ParameterName "wallet_id" -ScriptBlock $Global:ChiaShellArgumentCompleters.NftWallet
Register-ArgumentCompleter -CommandName Select-ChiaNfts -ParameterName "wallet_id" -ScriptBlock $Global:ChiaShellArgumentCompleters.NftWallet

Register-ArgumentCompleter -CommandName Get-ChiaWallets -ParameterName wallet_type -ScriptBlock $Global:ChiaShellArgumentCompleters.WalletType
Register-ArgumentCompleter -CommandName Show-ChiaWallets -ParameterName wallet_type -ScriptBlock $Global:ChiaShellArgumentCompleters.WalletType

Register-ArgumentCompleter -CommandName Set-ChiaNftDid -ParameterName new_did -ScriptBlock $Global:ChiaShellArgumentCompleters.NftWalletDid

