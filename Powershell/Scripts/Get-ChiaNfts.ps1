

Import-Module ChiaShell -Force

$start=(Get-ChiaBlockHeight -Date "2022-07-15").BlockHeight
#$start=2282305

while($end -lt ((Get-ChiaBlockchainState).peak.height)){

    $end=$start + 40
    Write-Host("Start: $start - End: $end")
    Get-ChiaNftRecords -start $start -end $end | ForEach-Object{
        #Import-Module ChiaShell
        #. ~/.local/share/powershell/config/ChiaShell.config.ps1

        $rec=$_
        Write-Host("Checking Coin Date: " + $rec.DateTime + " CoinID: " + $rec.coin.parent_coin_info )
        
        $nft=Get-ChiaNftInfo -coin_id $rec.coin.parent_coin_info

        #Write-Host("Nft Count:" + $nft.Count)

        if($null -ne $nft){
            $destDir="~/Documents/nft"
            $nftDestFile=($destDir + "/" + $nft.nft_coin_id + ".json")
            if($null -ne $nft.metadata_uris -and (-not (Test-Path($nftDestFile)))){
                Write-Host("Found New NFT: " + $nft.nft_coin_id)
                #$nft_metadata=Invoke-RestMethod -Uri $nft.metadata_uris[0] -TimeoutSec 5
                $nft_metadata=Get-ChiaNftMetadata -nfts $nft.nft_coin_id -TimeoutSec 5
                Add-Member -InputObject $nft -MemberType NoteProperty -Name metadata -Value $nft_metadata
                [PSCustomObject]@{
                    destFilePath = $nftDestFile
                    nft = $nft
                }
            }
            else{
                Write-Host("NFT already known:" + $nft.nft_coin_id)
            }
        }
    } | ForEach-Object {
        $nftDestFile=$_.destFilePath
        $nft=$_.nft
        Write-Host("Writing File: " + $nftDestFile)
        $nft | ConvertTo-Json -Depth 10 | Out-File ($nftDestFile)
    }
    $start=$end+1
}