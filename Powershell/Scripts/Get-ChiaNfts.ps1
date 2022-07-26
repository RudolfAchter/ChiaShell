
$destDir="~/Documents/nft"

$start=(Get-ChiaBlockHeight -Date "2022-07-15").BlockHeight
$start=2268242

while($end -lt ((Get-ChiaBlockchainState).peak.height)){

    $end=$start + 40
    Write-Host("Start: $start - End: $end")
    Get-ChiaNftRecords -start $start -end $end | Get-ChiaNftInfo | ForEach-Object {
        $nft=$_
        $nftDestFile=($destDir + "/" + $_.nft_coin_id + ".json")
        if($null -ne $nft.metadata_uris -and (-not (Test-Path($nftDestFile)))){
            Write-Host($nft.nft_coin_id)
            $nft_metadata=Invoke-RestMethod -Uri $nft.metadata_uris[0]
            Add-Member -InputObject $nft -MemberType NoteProperty -Name metadata -Value $nft_metadata
            $nft
        }
    } | ForEach-Object {
        $_ | ConvertTo-Json -Depth 10 | Out-File ($nftDestFile)
    }
    $start=$end+1
}