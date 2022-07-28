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



#Alle "Spalten" ermitteln
$allTraits=$totalData | ForEach-Object {
    $data=$_
    $h_traits=[ordered]@{}
    ForEach($attr in $data.meta_info.attributes){
        $h_traits.Add($attr.trait_type,$attr.value)
    }
    $o_traits=[PSCustomObject]$h_traits
    $o_traits
} | ForEach-Object{$_.PsObject.Properties.Name} | Sort-Object -Unique


$ngpat='(.*?)([#0-9]+)'
$specialItems=@('Shadow Sword')

#Powershell Objekte erstellen
$itemObjects=$totalData | ForEach-Object {
    $data=$_

    if($null -eq $data.nft_info.data_uris){
        return
    }
    $h_props=[ordered]@{}
    $h_props.Add("uri",$data.nft_info.data_uris[0])
    $h_props.Add("nft_data",@{
        "nft_coin_id" = $data.nft_info.nft_coin_id
        "nft_collection_id" = $data.synthetic_id
    })
    $match=$data.meta_info.name | Select-String -Pattern $ngpat
    if($null -ne $match -or ($data.meta_info.name -in $specialItems)){

        if($null -ne $match){
            $h_props.Add("Item Type",$match.Matches.Groups[1].Value.Trim())
        }
        else{ #Special Item
            $h_props.Add("Item Type",$data.meta_info.name)
        }

        $h_props.Add("Name",$data.meta_info.name)
        $h_props.Add("Collection",$data.meta_info.collection.name)
        $h_props.Add("Description",$data.meta_info.description)

        foreach($trait in $allTraits){
            $h_props.Add($trait,($data.meta_info.attributes | Where-Object{$_.trait_type -eq $trait}).value)
        }
        [PSCustomObject]$h_props
    }
    else{
        Write-Warning("No Regex Match for Item Type: '" + $data.meta_info.name + "' nft_id: " + $data.nft_coin_id)
    }
}


$itemGroups=$itemObjects | Group-Object -Property "Item Type"

$indexItems=$itemGroups | ForEach-Object {
    $group=$_
    $item=$group.Group | Select-Object -First 1
    $item
}


#Index über die Item Categorien

$curDate=Get-Date -Format "yyyy-MM-dd"

$out=@"
---
title: Item Types
description: Item Types in Chia Inventory
date: $curDate
tags:
  - NFT
  - Items
---

# Item Types


"@
$indexItems | ForEach-Object {
    $indexItem=$null
    $indexItem=$_

    
    $out+='<div class="item_thumbnail">' + "`r`n"
    $out+='<img src="' + $indexItem.uri + '"><br/>' + "`r`n"
    $out += '<div><strong>' + "Collection" + ':</strong> <a href="' + $indexItem.nft_data.TradeLink +'">' + $indexItem.Collection + '</a></div>' + "`r`n"
    $out += '<div><strong>' + "Item Type" + ':</strong> <a href="../90_' + ($indexItem."Item Type" -replace '[^A-Za-zäöüÄÖÜ\-_]','') +'">' + $indexItem."Item Type" + '</a></div>' + "`r`n"
    ForEach ($prop in $indexItem.PsObject.Properties){
        if($null -ne $prop.Value -and "" -ne $prop.Value -and $prop.Name -notin @("uri","name","description","nft_data","Collection","Item Type")){
            $out += '<div><strong>' + $prop.Name + ':</strong> ' + $prop.Value + '</div>' + "`r`n"
        }
    }
    $out+='</div>' + "`r`n"
}

$out | Out-File -FilePath ($itemsDir + "/" + "50_types.md")


#Einzelne Items

$itemGroups | ForEach-Object {
    $group=$_
    $group

    if($null -ne $group.Name){

        <#
        $groupDir=($itemsDir + "/" + $group.Name)
        if(-not (Test-Path $groupDir)){
            New-Item -Path $groupDir -ItemType Directory
        }
        #>

        $groupName=$group.Name

        $out=@"
---
title: $groupName
description: $groupName in Chia Inventory
date: $curDate
tags:
  - NFT
  - Items
---

# $groupName


"@
        $out+= "- Buy " + $group.Group[0].Collection + " at the blue duck: " + "[Dexie - " + $group.Group[0].Collection + "](https://dexie.space/offers/" + $group.Group[0].nft_data.nft_collection_id + "/xch)" + "`r`n`r`n"
        $group.Group | ForEach-Object {
            $item=$_

            $out+='<div class="item_thumbnail_detail">' + "`r`n"
            $out+='<img src="' + $item.uri + '"><br/>' + "`r`n"
            $out += '<div><a href="https://www.spacescan.io/xch/coin/' + $item.nft_data.nft_coin_id + '"><strong>' + "Name" + ':</strong> ' + $item.Name + '</a></div>' + "`r`n"
            ForEach ($prop in $item.PsObject.Properties){
                if($null -ne $prop.Value -and "" -ne $prop.Value -and $prop.Name -notin @("Name","Item Type","uri","Description","nft_data")){
                    $out += '<div><strong>' + $prop.Name + ':</strong> ' + $prop.Value + '</div>' + "`r`n"
                }
            }
            $out += '<div><strong>' + "Description" + ':</strong> ' + $item.Description + '</div>' + "`r`n"
            $out+='</div>' + "`r`n"
        
        }

        $out | Out-File -FilePath ($itemsDir + "/" + "90_" + ($group.Name -replace '[^A-Za-z0-9äöüÄÖÜ_-]') +".md")
    }
}