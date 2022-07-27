$srcDir="~/Documents/nft_collection"
$chianiaDir="~/git/chiania/docs/items/test"
$outFile="items_test.md"
$replaceFile=($chianiaDir + "/" + $outFile)

$a_collections=@(
    "Chia_Inventory"
)


$totalData=$a_collections | ForEach-Object {
    $collection=$_
    Get-ChildItem -Path ($srcDir + "/" + $collection) -Filter *.json | ForEach-Object {
        $file=$_
        $data=Get-content -Path $file.FullName | ConvertFrom-Json
        $data
    }
}

#modifications
$mods=@(
    @{pattern='Bark Shield.*'; mod='After the first fight, the unarmed adventurers saw they needed something to defend themselves. So they rip off some bark from the trees and made them provisionally bark shields.'}
    @{pattern='Catapult.*'; mod='At the beginning of their quest the unarmed volunteers collected stones and made catapults for themselves to attack the monsters.'}
)


for($i=0;$i -lt $totalData.count;$i++){
    foreach($mod in $mods){
        if($totalData[$i].metadata.name -match $mod.pattern){
            $totalData[$i].metadata.description+=" " + $mod.mod
        }
    }
    
    $totalData[$i].metadata.description
}

$totalData=$totalData | Sort-Object -Property {$_.metadata.name}

$out=''
$out+='<table class="item_table">'

$totalData | ForEach-Object {
    $data=$_

    $h_traits=[ordered]@{}
    $data.metadata.attributes | ForEach-Object {
        $h_traits.Add($_.trait_type,$_.value)
    }
    $o_traits=[PSCustomObject]$h_traits

    $out+='<tr>' + "`r`n"

    $out+='<td>'
    $out+='<img src="' + $data.data_uris[0] + '" class="game_item">'
    $out+='</td>' + "`r`n"

    $out+='<td>'
    $out+='<span><strong>' + $data.metadata.name + '</strong></span>'
    foreach($trait in $o_traits.PSObject.Properties){
        $out+=' <span><strong>' + $trait.Name + '</strong> ' + $trait.Value + '</span>' + "`r`n"
    }
    $out+=$data.metadata.description
    $out+='</td>' + "`r`n"

    $out+='</tr>' + "`r`n"
}
$out+='</table>'

$content=(Get-Content -Path $replaceFile) -join "`r`n"
$pattern='<!-- ITEMSSTART -->(.*)<!-- ITEMSEND -->'
$replacement='<!-- ITEMSSTART -->'+ "`r`n" +$out+ "`r`n" +'<!-- ITEMSEND -->'
$options=[System.Text.RegularExpressions.RegexOptions]::Singleline -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase

[regex]::Replace($content,$pattern,$replacement,$options) | Out-File -FilePath $replaceFile -Encoding UTF8


