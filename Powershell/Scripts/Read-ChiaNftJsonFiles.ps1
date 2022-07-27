
$sourceDir="~/Documents/nft"
$destBase="~/Documents/nft_collection"

if(-not (Test-Path $destBase)){
    New-Item -Path $destBase -ItemType Directory
}

Get-Item "$sourceDir/*.json" | ForEach-Object{
    $file=$_
    Get-Content $file | ConvertFrom-Json | ForEach-Object {
        $nft=$_
        if($null -ne $nft.metadata.collection.name){
            $collectionName=$nft.metadata.collection.name.Trim()
            $collectionFolderName=$collectionName -replace '[^A-Za-z0-9äöüÄÖÜ\-_]','_'
            #$collectionFolderName
            $destDir=("$destBase/" + $collectionFolderName)
            if(-not (Test-Path $destDir)){
                New-Item -Path $destDir -ItemType Directory
            }

            if(-not (Test-Path ($destDir + "/" + $file.Name))){
                $existingFile=($destDir + "/" + $file.Name)
                if($existingFile.LastWriteTime -lt $file.LastWriteTime){
                    $file | Copy-Item -Destination ($destDir) -PassThru
                }
            }
        }
    }
}
