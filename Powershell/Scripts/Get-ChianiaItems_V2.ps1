<#
TODO Mintgarden api benutzen!

https://api.mintgarden.io/search?query=Chia+Inventory

col16fpva26fhdjp2echs3cr7c30gzl7qe67hu9grtsjcqldz354asjsyzp6wx

https://api.mintgarden.io/collections/col16fpva26fhdjp2echs3cr7c30gzl7qe67hu9grtsjcqldz354asjsyzp6wx/nfts?page=1&size=12
#>


$srcDir="~/Documents/nft_collection"
$itemsDir="~/git/chiania/docs/items"
#$outFile="items_test2.md"
#$replaceFile=($chianiaDir + "/" + $outFile)

$a_collections=@(
    @{name="Chia_Inventory"; tradeLink="https://dexie.space/offers/col16fpva26fhdjp2echs3cr7c30gzl7qe67hu9grtsjcqldz354asjsyzp6wx/xch"}
    @{name="Chreatures"; tradeLink="https://dexie.space/offers/col1w0h8kkkh37sfvmhqgd4rac0m0llw4mwl69n53033h94fezjp6jaq4pcd3g/xch"}
    @{name="Brave_Seedling"; tradeLink="https://dexie.space/offers/col1jgw23rce22aucy0vrseqa3dte8sd0924sdjw5xuxzljcnhgr8fpqnjcu7q/xch"}
)


$totalData=$a_collections | ForEach-Object {
    $collection=$_
    Get-ChildItem -Path ($srcDir + "/" + $collection.name) -Filter *.json | ForEach-Object {
        $file=$_
        $data=Get-content -Path $file.FullName | ConvertFrom-Json
        $data | Add-member -MemberType NoteProperty -Name tradeLink -Value $collection.tradeLink
        $data
    }
}

#modifications
<#
$mods=@(
    @{pattern='Bark Shield.*'; mod='After the first fight, the unarmed adventurers saw they needed something to defend themselves. So they rip off some bark from the trees and made them provisionally bark shields.'}
    @{pattern='Catapult.*'; mod='At the beginning of their quest the unarmed volunteers collected stones and made catapults for themselves to attack the monsters.'}
)
#>


for($i=0;$i -lt $totalData.count;$i++){
    foreach($mod in $mods){
        if($totalData[$i].metadata.name -match $mod.pattern){
            $totalData[$i].metadata.description+=" " + $mod.mod
        }
    }
    #$totalData[$i].metadata.description
}

$totalData=$totalData | Sort-Object -Property {$_.metadata.name}

#Alle "Spalten" ermitteln
$allTraits=$totalData | ForEach-Object {
    $data=$_
    $h_traits=[ordered]@{}
    $data.metadata.attributes | ForEach-Object {
        $h_traits.Add($_.trait_type,$_.value)
    }
    $o_traits=[PSCustomObject]$h_traits
    $o_traits
} | ForEach-Object{$_.PsObject.Properties.Name} | Sort-Object -Unique


$ngpat='(.*?)([#0-9]+)'

#Powershell Objekte erstellen
$itemObjects=$totalData | ForEach-Object {
    $data=$_

    $h_props=[ordered]@{}
    $h_props.Add("uri",$data.data_uris[0])
    $h_props.Add("nft_data",@{
        "nft_coin_id" = $data.nft_coin_id
        "TradeLink" = $data.tradeLink
    })
    $match=$data.metadata.name | Select-String -Pattern $ngpat
    if($null -ne $match){
        $h_props.Add("Item Type",$match.Matches.Groups[1].Value.Trim())

        $h_props.Add("Name",$data.metadata.name)
        $h_props.Add("Collection",$data.metadata.collection.name)
        $h_props.Add("Description",$data.metadata.description)

        foreach($trait in $allTraits){
            $h_props.Add($trait,($data.metadata.attributes | Where-Object{$_.trait_type -eq $trait}).value)
        }
        [PSCustomObject]$h_props
    }
    else{
        Write-Warning("No Regex Match for Item Type: '" + $data.metadata.name + "' nft_id: " + $data.nft_coin_id)
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
        $out+= "- [Dexie - " + $group.Group[0].Collection + "](" + $group.Group[0].nft_data.tradeLink + ")" + "`r`n`r`n"
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