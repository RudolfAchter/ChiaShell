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



$patterns=@(
    '(.*? Nuclei) ([a-zA-z].*?)([#0-9]+)',
    '()(.*?)([#0-9]+)'
)
#$specialItems=@('()(.*?)([#0-9]+)') #(Shadow Sword)','()(Brave Leef)')
$specialItems=@('()(Shadow Sword)','()(Brave Leef)')

$h_typePatterns=@{
    'Armor'  = @{
        patterns = @('.* Armor')
    }
    'Shield' = @{
        patterns = @('.* Shield')
    }
    'Herb'   = @{
        patterns = @('Brave Seedling','Brave Leef')
    }
    'Familiar' = @{
        patterns = @('snail','Chia Slime')
    }
    'Weapon' = @{
        patterns = @('Catapult','Halberd','Khopesh','Knife','Sword','.* Axe','Axe',
                     '.* Bow','Bow','Stone','.* Club','Club','Enhanced Tree Root')
    }
    'Ring' = @{
        patterns = @('.* Ring','Ring')
    }
    'Mount'  = @{
        patterns = @('Deer')
    }
    'Collectable' = @{
        patterns = @('.* Monster Nuclei','Canned Slime')
    }
}


$patterns+=$specialItems

$itemList=@{}

#Powershell Objekte erstellen
$totalData | ForEach-Object {
    $item=$_

    if($null -eq $itemList.($item.nft_id)){
        $match=$null
        ForEach($pattern in $patterns){
            if($item.meta_info.name -match $pattern){
                $match=Select-String -InputObject $item.meta_info.name -Pattern $pattern
                [string]$prefix=$match.Matches[0].Groups[1].Value.Trim()
                [string]$itemType=$match.Matches[0].Groups[2].Value.Trim()
                #when Pattern has matched abort here
                break
            }
        }

        if($itemType.GetType().Name -ne "String"){
            Write-Warning("ItemType not String: " + $item.nft_id)
            #$itemType MUST be String!!! no clue why there sometimes comes a HashTable (WTF!)
            return
        }

        [string]$itemCategory=""
        ForEach($typePattern in $h_typePatterns.GetEnumerator()){
            ForEach($pattern in $typePattern.Value.patterns){
                if($item.meta_info.name -match $pattern){
                    [string]$itemCategory=$typePattern.Name
                    break
                }
            }
            if($itemCategory -ne ""){break}
        }
        if($itemCategory -eq ""){
            $itemCategory="Other"
        }
        

        if($prefix -eq ""){$prefix="Normal"}
        
        Try{
            #build JSON Tree (as Powershell HashTables)
            if($null -eq $itemList.($itemCategory)){$itemList.Add($itemCategory,@{})}
            if($null -eq $itemList.($itemCategory).($itemType)){$itemList.($itemCategory).Add($itemType,@{})}
            if($null -eq $itemList.($itemCategory).($itemType).($prefix)){$itemList.($itemCategory).($itemType).Add($prefix,@{})}
            if($null -eq $itemList.($itemCategory).($itemType).($prefix).($item.nft_id)){
                $itemList.($itemCategory).($itemType).($prefix).Add($item.nft_id,[PSCustomObject]@{
                    Name = $item.meta_info.name.Trim()
                    ItemCategory = $itemCategory
                    ItemType = $itemType
                    Prefix = $prefix
                    Collection = $item.meta_info.collection.name.Trim()
                    nft_id = $item.nft_id.Trim()
                    minter_did = $item.minter_did.Trim()
                    collection_id = $item.synthetic_id.Trim()
                    item_uri = $item.nft_info.data_uris[0]
                    attributes = $item.meta_info.attributes
                })
            }
            else{
                
            }
        }Catch{
            Write-Warning("Error Adding ItemType or Adding Item: '" + $item.nft_id + "'")
        }
    }
}

$itemList.GetEnumerator()

<#
$itemList.GetEnumerator() | ForEach-Object {
    $_.Value.GetEnumerator() | ForEach-Object{
        $_.Value.Name
    }
} | Select-Object -First 100
#>

$itemList | ConvertTo-Json -Depth 7 | Out-File -Path ($itemsDir + "/" + "ChianiaItems.groupByItemType.json") -Encoding UTF8



#Markdown / HTML Output

Get-ChildItem -Path ($itemsDir + "/Types/") -Directory | Remove-Item -Recurse -Force -Confirm:$false

#ItemTypes

$curDate=Get-Date -Format "yyyy-MM-dd"


$itemList.GetEnumerator() | Sort-Object Name | ForEach-Object {

    $o_itemCategory=$_
    $itemCategoryName=$o_itemCategory.Name

    $out=@"
---
title: Category - $itemCategoryName
description: Item Types in Chia Inventory
date: $curDate
tags:
    - NFT
    - Items
---

# Category - $itemCategoryName

"@

    $o_itemCategory.Value.GetEnumerator() | Sort-Object Name | ForEach-Object{
        $o_itemType=$_
        #Render First Item of Each itemType for Preview
        $o_itemType.Value.GetEnumerator() | Select-Object -Last 1 | ForEach-Object{
            $o_itemPrefix=$_
            $o_itemPrefix.Value.GetEnumerator() | Select-Object -Last 1 | ForEach-Object{
                $indexItem=$_.Value
                $out+='<div class="item_type_thumbnail">' + "`r`n"
                $out+='<a href="../../Types/'+ $itemCategoryName + '/' + ($indexItem.ItemType -replace '[^A-Za-zäöüÄÖÜ\-_]','_')+ "/" + ($indexItem.ItemType -replace '[^A-Za-zäöüÄÖÜ\-_]','_') + "" +'"><img src="' + $indexItem.item_uri + '"></a><br/>' + "`r`n"
                $out += '<div><strong>' + "Item Type" + ':</strong> <a href="../../Types/'+ $itemCategoryName + '/' + ($indexItem.ItemType -replace '[^A-Za-zäöüÄÖÜ\-_]','_')+ "/" + ($indexItem.ItemType -replace '[^A-Za-zäöüÄÖÜ\-_]','_') + "" +'">' + $indexItem.ItemType + '</a></div>' + "`r`n"
                $out += '<div><strong>' + "Collection" + ':</strong> <a href="https://www.spacescan.io/xch/nft/collection/' + $indexItem.collection_id +'">' + $indexItem.Collection + '</a></div>' + "`r`n"
                <#
                ForEach ($attr in $indexItem.attributes){
                        $out += '<div><strong>' + $attr.trait_type + ':</strong> ' + $attr.value + '</div>' + "`r`n"
                }
                #>
                $out+='</div>' + "`r`n"        
            }
        }
    }

    $itemsPath=($itemsDir + "/Types/" + ($itemCategoryName -replace '[^A-Za-zäöüÄÖÜ\-_]','_'))

    if(-not (Test-Path $itemsPath)){
        New-Item -Path $itemsPath -ItemType Directory | Out-Null
    }

    $out | Out-File -FilePath ($itemsPath + "/README.md")

}

#ItemType Indexes


$itemList.GetEnumerator() | ForEach-Object {

    $o_itemCategory=$_
    $itemCategoryName=$o_itemCategory.Name

    $o_itemCategory.Value.GetEnumerator() | ForEach-Object {

        $o_itemType=$_
        $itemTypeName=$o_itemType.Name

        $out=@"
---
title: $itemTypeName
description: Item Types in Chia Inventory
date: $curDate
tags:
    - NFT
    - Items
---

# $itemTypeName

"@


        $itemTypePath=($itemsDir + "/Types/"+ ($itemCategoryName -replace '[^A-Za-zäöüÄÖÜ\-_]','_') + "/" + ($o_itemType.Name -replace '[^A-Za-zäöüÄÖÜ\-_]','_'))

        if(-not (Test-Path $itemTypePath)){
            New-Item -Path $itemTypePath -ItemType Directory | Out-Null
        }

        #Render First Item of Each itemType for Preview
        $o_itemType.Value.GetEnumerator() | ForEach-Object{
            $o_itemPrefix=$_
            $out+="## " + $o_itemPrefix.Name + "`r`n`r`n"
            $o_itemPrefix.Value.GetEnumerator() | ForEach-Object{
                $indexItem=$_.Value
                $out+='<div class="item_thumbnail">' + "`r`n"
                $out+='<a href="../../../'+ $itemCategoryName + '/' + ($indexItem.ItemType -replace '[^A-Za-zäöüÄÖÜ\-_]','_')+ "/" + ($indexItem.ItemType -replace '[^A-Za-zäöüÄÖÜ\-_]','_') + "" +'"><img src="' + $indexItem.item_uri + '"></a><br/>' + "`r`n"
                $out += '<div><strong>' + "Name" + ':</strong> ' + $indexItem.Name + '</div>' + "`r`n"
                $out += '<div><strong>' + "Item Type" + ':</strong> <a href="../../../'+ $itemCategoryName + '/' + ($indexItem.ItemType -replace '[^A-Za-zäöüÄÖÜ\-_]','_')+ "/" + ($indexItem.ItemType -replace '[^A-Za-zäöüÄÖÜ\-_]','_') + "" +'">' + $indexItem.ItemType + '</a></div>' + "`r`n"
                $out += '<div><strong>' + "Collection" + ':</strong> <a href="https://www.spacescan.io/xch/nft/collection/' + $indexItem.collection_id +'">' + $indexItem.Collection + '</a></div>' + "`r`n"
                
                ForEach ($attr in $indexItem.attributes){
                        $out += '<div><strong>' + $attr.trait_type + ':</strong> ' + $attr.value + '</div>' + "`r`n"
                }

                $out+='</div>' + "`r`n"
            }
            $out+='<hr style="clear:both;"/>' + "`r`n"
        }

        $out | Out-File -FilePath ($itemTypePath + "/" + ($indexItem.ItemType -replace '[^A-Za-zäöüÄÖÜ\-_]','_') + ".md")
    }
}

