

Import-Module ChiaShell -Force
Import-Module Mdbc


$Server="chiahp.fritz.box"
$DatabaseName="chia"
$User=""
$Password=""

#$connectionString="mongodb+srv://" + $User + ":" + $Password + "@" + $Server + "/" + $DatabaseName + "?retryWrites=true&w=majority"
$connectionString="mongodb://localhost:27017/?readPreference=primary&ssl=false"
Connect-Mdbc -ConnectionString $connectionString -DatabaseName $DatabaseName -CollectionName "nft"
$targetCollection=(Get-MdbcCollection -Name "nft")
$blockchainCol=(Get-MdbcCollection -Name "blockchain")



$checkState=Get-MdbcData -Filter @{
    "name" = "check_state"
} -Collection $blockchainCol

if($null -ne $checkState){
    $start=$checkState.checked_height+1
}
else{
    $start=(Get-ChiaBlockHeight -Date "2022-07-15").BlockHeight
    #$start=2282305
}

while($end -lt ((Get-ChiaBlockchainState).peak.height)){

    $end=$start + 40
    Write-Host("Start: $start - End: $end")
    Get-ChiaNftRecords -start $start -end $end | ForEach-Object{
        #Import-Module ChiaShell
        #. ~/.local/share/powershell/config/ChiaShell.config.ps1

        $rec=$_
        Write-Host("Checking Coin Date: " + $rec.DateTime + " CoinID: " + $rec.coin.parent_coin_info )
        
        $nft=Get-ChiaNftInfo -coin_id $rec.coin.parent_coin_info -Verbose
        #Write-Host("Nft Count:" + $nft.Count)

        if($null -ne $nft){

            $null=$nftEntry
            #Check if already in Database
            Write-Host("Checking MongoDb for launcher_id: " + $nft.launcher_id)
            $nftEntry=Get-MdbcData -Filter @{"launcher_id" = $nft.launcher_id}

            if($null -ne $nft.metadata_uris -and ($null -eq $nftEntry)){
                Write-Host("Found New NFT: " + $nft.launcher_id)

                Add-Member -InputObject $rec.coin -MemberType NoteProperty -Name puzzle_hash_encoded -Value (
                    cdv encode --prefix $Global:ChiaShell.AddressType.XCH $rec.coin.puzzle_hash
                )

                $nft_metadata=Get-ChiaNftMetadata -nfts $nft.nft_coin_id -TimeoutSec 5

                Add-Member -InputObject $nft -MemberType NoteProperty -Name coin_records -Value @(
                    $rec
                )

                Add-Member -InputObject $nft -MemberType NoteProperty -Name metadata -Value $nft_metadata
                
                #launcher_id contains NFT ID
                Add-Member -InputObject $nft -MemberType NoteProperty -Name nft_id_encoded -Value (
                    cdv encode --prefix $Global:ChiaShell.AddressType.NFT $nft.launcher_id
                )
                Add-Member -InputObject $nft -MemberType NoteProperty -Name launcher_address_encoded -Value (
                    cdv encode --prefix $Global:ChiaShell.AddressType.XCH $nft.launcher_puzhash
                )
                Add-Member -InputObject $nft -MemberType NoteProperty -Name updater_address_encoded -Value (
                    cdv encode --prefix $Global:ChiaShell.AddressType.XCH $nft.updater_puzhash
                )
                Add-Member -InputObject $nft -MemberType NoteProperty -Name royalty_address_encoded -Value (
                    cdv encode --prefix $Global:ChiaShell.AddressType.XCH $nft.royalty_puzzle_hash
                )
                if($null -ne $nft.owner_did){
                    Add-Member -InputObject $nft -MemberType NoteProperty -Name owner_did_encoded -Value (
                        cdv encode --prefix $Global:ChiaShell.AddressType.DID $nft.owner_did
                    )    
                }


                $nft | Add-MdbcData -Collection $targetCollection
                
            }
            else{
                Write-Host("NFT already known:" + $nft.launcher_id + " : updating Data...")

                #Prepare Update of nftEntry

                #Add new Record Only if Parent Coin has changed
                if($rec.coin.parent_coin_info -notin $nftEntry.coin_records.coin.parent_coin_info){
                    Add-Member -InputObject $rec.coin -MemberType NoteProperty -Name puzzle_hash_encoded -Value (
                        cdv encode --prefix $Global:ChiaShell.AddressType.XCH $rec.coin.puzzle_hash
                    )
                    #nftEntry gets additional Coin Record
                    $nftEntry.coin_records += $rec
                }
                $nftEntry.data_uris = $nft.data_uris
                $nftEntry.metadata_uris = $nft.metadata_uris
                $nftEntry.owner_did = $nft.owner_did

                if($nftEntry.owner_did -ne $nft.owner_did){
                    if($null -ne $nft.owner_did){
                        Add-Member -InputObject $nft -MemberType NoteProperty -Name owner_did_encoded -Value (
                            cdv encode --prefix $Global:ChiaShell.AddressType.DID $nft.owner_did)
                        $nftEntry.owner_did=$nft.owner_did_encoded
                    }
                }

                #Set-MdbcData Replaces Old Document with new Document
                Set-MdbcData -Filter @{
                    "launcher_id" = $nft.launcher_id
                } -Set $nftEntry -Collection $targetCollection
            }
        }
    }

    Set-MdbcData -Filter @{
        name="check_state"
    } -Set @{
        name="check_state"
        checked_height=$end
    } -Collection $blockchainCol -Add


    $start=$end+1
}