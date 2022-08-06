<#
ERLEDIGT Mintgarden api benutzen!
https://api.mintgarden.io/search?query=Chia+Inventory
col16fpva26fhdjp2echs3cr7c30gzl7qe67hu9grtsjcqldz354asjsyzp6wx
https://api.mintgarden.io/collections/col16fpva26fhdjp2echs3cr7c30gzl7qe67hu9grtsjcqldz354asjsyzp6wx/nfts?page=1&size=12

TODO Dexie.space Angebote holen
Beispiel: 
curl "https://dexie.space/v1/offers?offered=col1syclna803y6h3zl24fwswk0thmm7ad845cfc6sv4sndfzu26q8cq3pprct&requested=xch&page=1&page_size=50&sort=price_asc"
#>

$Global:ChiaShell

$srcDir="~/Documents/nft_collection"
$itemsDir="~/git/chiania/docs/items"
$logPath="~/Documents/chiania_items.log"
#$outFile="items_test2.md"
#$replaceFile=($chianiaDir + "/" + $outFile)

$spaceScan=@{
    apiKey="tkn1qqqk2az9qpzedr6lucan4qzf57zs9nmfkptjcfsk2az9qpzevqqq5rzt30"
}

$a_collections=@(

    
    @{name="Chia Inventory"; folder_name="Chia_Inventory"; collection_id="col16fpva26fhdjp2echs3cr7c30gzl7qe67hu9grtsjcqldz354asjsyzp6wx"}
    @{name="Chreatures";     folder_name="Chreatures";     collection_id="col1w0h8kkkh37sfvmhqgd4rac0m0llw4mwl69n53033h94fezjp6jaq4pcd3g"}
    @{name="Brave Seedling"; folder_name="Brave_Seedling"; collection_id="col1jgw23rce22aucy0vrseqa3dte8sd0924sdjw5xuxzljcnhgr8fpqnjcu7q"}
    @{name="Sheesh! Snail";  folder_name="Sheesh__Snail";  collection_id="col1syclna803y6h3zl24fwswk0thmm7ad845cfc6sv4sndfzu26q8cq3pprct"}
    @{name="Chia Slimes";    folder_name="Chia_Slimes";    collection_id="col19z8k90wfezt55jj2zm526yzmk8dq0fcyqamzmtqv7hv4wkafhnjsp8fsz2"}
)

$a_collections | ForEach-Object {
    $coll=$_

    $i=0
    $page=1
    $count=40
    $version=1

    Write-Host("https://api2.spacescan.io/api/nft/collection/" + $coll.collection_id + "?x-auth-id=" + $spaceScan.apiKey + "&coin=xch&page=$page&count=$count&version=$version")
    Write-Host("")
}


$totalData=$a_collections | ForEach-Object {
    $coll=$_
    #$collData=Invoke-RestMethod -Uri ("https://api2.spacescan.io/api/nft/collection/" + $coll.collection_id + "?x-auth-id=" + $spaceScan.apiKey + "&coin=xch&page=1&count=40&version=1")
    $i=0
    $page=1
    $count=40
    $version=1

    do{
        $collData=Invoke-RestMethod -Uri ("https://api2.spacescan.io/api/nft/collection/" + $coll.collection_id + "?x-auth-id=" + $spaceScan.apiKey + "&coin=xch&page=$page&count=$count&version=$version")
        $dat=$null
        if($collData.status -eq "success"){
            $collData.data | ForEach-Object {
                $dat=$_
                $collCount=$dat.count
                #Ausgabe
                Out-File -FilePath $logPath -InputObject ($dat.meta_info.name + ": " + $i + " of " + $collCount) -Append
                $dat
                #zählen
                $i++
            }
        }
        else{
            $collData
        }
        $page++
    }while($i -lt $collCount)
    #}while($false)
}

#Vertrannte Items müssen weg
#$totalData | Where-Object {$_.meta_info.name -like "Khopesh 01"} | Select-Object {$_.meta_info.name},{$_.owner_hash}

$totalData=$totalData | 
    Sort-Object -Property @({$_.meta_info.collection.name},{$_.meta_info.name}) |
    #Filter out Burned Objects
    Where-Object {$_.owner_hash -ne "000000000000000000000000000000000000000000000000000000000000dead"}


$patterns=@()
$ngpat='(.*?)([#0-9]+)'
$specialItems=@('(Shadow Sword)','(Brave Leef)')

$patterns+=$ngpat
$patterns+=$specialItems

$itemList=@{}

#Powershell Objekte erstellen
$totalData | ForEach-Object {
    $item=$_

    if($null -eq $itemList.($item.nft_id)){
        
        ForEach($pattern in $patterns){
            if($item.meta_info.name -match $pattern){
                $match=Select-String -InputObject $item.meta_info.name -Pattern $pattern
                $itemType=$match.Matches.Groups[1].Value
            }
        }
        
        Try{
            if($null -eq $itemList.($itemType)){
                $itemList.Add($itemType,@{})
            }
            if($null -eq $itemList.($itemType).($item.nft_id)){
                $itemList.($itemType).Add($item.nft_id,[PSCustomObject]@{
                    Name = $item.meta_info.name
                    ItemType = $itemType
                    Collection = $item.meta_info.collection.name
                    minter_did = $item.minter_did
                    collection_id = $item.synthetic_id
                    item_uri = $item.nft_info.data_uris[0]
                })
            }
            else{
                
            }
        }Catch{
            Write-Warning("Error Adding ItemType or Adding Item: '" + $item.nft_id + "'")
        }
    }
}


$itemList | ConvertTo-Json -Depth 5 | Out-File -Path "ChianiaItems.groupByItemType.json" -Encoding UTF8