(Get-ChiaAllOffers) | forEach-Object{
    $offer=$_
    @("offered","requested") | ForEach-Object {
        $offerType=$_
        $offer.summary.$offerType.PsObject.Properties.Name

        [PSCustomObject]@{
            Type = $offerType
        }
    
    }
}


$offerType="offered"

(Get-ChiaAllOffers) | Where-Object {$_.summary.$offerType.PsObject.Properties.Name.Length -gt 5} | forEach-Object{
    $offer=$_
    #$offer.summary.$offerType.PsObject.Properties.Name
    Show-ChiaNftInfo -coin_ids $offer.summary.$offerType.PsObject.Properties.Name -Verbose
}