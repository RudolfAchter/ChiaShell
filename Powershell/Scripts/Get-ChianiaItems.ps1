$srcDir="~/Documents/nft_collection"


$a_collections=@(
    "Chia_Inventory"
)

$a_collections | ForEach-Object {
    $collection=$_
    Get-ChildItem -Path ($srcDir + "/" + $collection) -Filter *.json | ForEach-Object {
        $file=$_
        $data=Get-content -Path $file.FullName | ConvertFrom-Json

        
    }
}

