# Modul ChiaShell

Wenn du für die Dokumentation dieses Moduls etwas beitragen willst, dann nimm dir die Kommentare in den Funktionsdefinitionen dieses Moduls vor.
Ich dokumentiere meine Module mit Comment-based Help. Also mach so:
 * [Powershell Comment-based Help - Microsoft Dokumentation](https://docs.microsoft.com/de-de/powershell/module/microsoft.powershell.core/about/about_comment_based_help?view=powershell-7.1)

## Nouns

### ChiaAdditionsAndRemovals

<table>
<tr>
<td><a href="docs/Get-ChiaAdditionsAndRemovals.md">Get-ChiaAdditionsAndRemovals</a></td><td>
Get-ChiaAdditionsAndRemovals [[-header_hash] <Object>] [<CommonParameters>]

</td>
</tr>
</table>

### ChiaBlock

<table>
<tr>
<td><a href="docs/Get-ChiaBlock.md">Get-ChiaBlock</a></td><td>
Get-ChiaBlock [[-header_hash] <Object>]

</td>
</tr>
</table>

### ChiaBlockchainState

<table>
<tr>
<td><a href="docs/Get-ChiaBlockchainState.md">Get-ChiaBlockchainState</a></td><td>
Get-ChiaBlockchainState 

</td>
</tr>
</table>

### ChiaBlockHeight

<table>
<tr>
<td><a href="docs/Get-ChiaBlockHeight.md">Get-ChiaBlockHeight</a></td><td>
Get-ChiaBlockHeight [[-Date] <Object>]

</td>
</tr>
</table>

### ChiaBlockRecords

<table>
<tr>
<td><a href="docs/Get-ChiaBlockRecords.md">Get-ChiaBlockRecords</a></td><td>
Get-ChiaBlockRecords [[-start] <Object>] [[-end] <Object>]

</td>
</tr>
</table>

### ChiaBlocks

<table>
<tr>
<td><a href="docs/Get-ChiaBlocks.md">Get-ChiaBlocks</a></td><td>
Get-ChiaBlocks [[-start] <Object>] [[-end] <Object>]

</td>
</tr>
</table>

### ChiaCert

<table>
<tr>
<td><a href="docs/Get-ChiaCert.md">Get-ChiaCert</a></td><td>
Get-ChiaCert [[-api] <Object>]

</td>
</tr>
</table>

### ChiaCoinRecordsByParentIds

<table>
<tr>
<td><a href="docs/Get-ChiaCoinRecordsByParentIds.md">Get-ChiaCoinRecordsByParentIds</a></td><td>
Get-ChiaCoinRecordsByParentIds [-parent_ids] <Object> [[-include_spent_coins] <bool>] [[-start_height] <Object>] [[-end_height] <Object>] [<CommonParameters>]

</td>
</tr>
</table>

### ChiaCoinRecordsByPuzzleHash

<table>
<tr>
<td><a href="docs/Get-ChiaCoinRecordsByPuzzleHash.md">Get-ChiaCoinRecordsByPuzzleHash</a></td><td>
Get-ChiaCoinRecordsByPuzzleHash [-puzzle_hash] <Object> [[-start_height] <Object>] [[-end_height] <Object>] [<CommonParameters>]

</td>
</tr>
</table>

### ChiaDid

<table>
<tr>
<td><a href="docs/Get-ChiaDid.md">Get-ChiaDid</a></td><td>
Get-ChiaDid [[-wallet_ids] <Object>] [<CommonParameters>]

</td>
</tr>
</table>

### ChiaDidWallet

<table>
<tr>
<td><a href="docs/Get-ChiaDidWallet.md">Get-ChiaDidWallet</a></td><td>
Get-ChiaDidWallet 

</td>
</tr>
</table>

### ChiaDidWalletDid

<table>
<tr>
<td><a href="docs/Get-ChiaDidWalletDid.md">Get-ChiaDidWalletDid</a></td><td>
Get-ChiaDidWalletDid [[-wallet_ids] <Object>] [<CommonParameters>]

</td>
</tr>
</table>

### ChiaDidWalletName

<table>
<tr>
<td><a href="docs/Get-ChiaDidWalletName.md">Get-ChiaDidWalletName</a></td><td>
Get-ChiaDidWalletName [[-wallet_ids] <Object>] [<CommonParameters>]

</td>
</tr>
</table>

### ChiaKey

<table>
<tr>
<td><a href="docs/Get-ChiaKey.md">Get-ChiaKey</a></td><td>
Get-ChiaKey 

</td>
</tr>
<tr>
<td><a href="docs/Use-ChiaKey.md">Use-ChiaKey</a></td><td>
Use-ChiaKey [[-fingerprint] <Object>] [<CommonParameters>]

</td>
</tr>
</table>

### ChiaNetworkInfo

<table>
<tr>
<td><a href="docs/Get-ChiaNetworkInfo.md">Get-ChiaNetworkInfo</a></td><td>
Get-ChiaNetworkInfo 

</td>
</tr>
</table>

### ChiaNftDid

<table>
<tr>
<td><a href="docs/Set-ChiaNftDid.md">Set-ChiaNftDid</a></td><td>
Set-ChiaNftDid [[-nfts] <Object>] [[-new_did] <Object>] [[-timeoutSec] <Object>] [[-fee] <Object>] [<CommonParameters>]

</td>
</tr>
</table>

### ChiaNftInfo

<table>
<tr>
<td><a href="docs/Get-ChiaNftInfo.md">Get-ChiaNftInfo</a></td><td>Short description
</td>
</tr>
<tr>
<td><a href="docs/Show-ChiaNftInfo.md">Show-ChiaNftInfo</a></td><td>
Show-ChiaNftInfo [-coin_ids] <string> [[-View] <Object>] [[-Columns] <Object>] [<CommonParameters>]

</td>
</tr>
</table>

### ChiaNftMetadata

<table>
<tr>
<td><a href="docs/Get-ChiaNftMetadata.md">Get-ChiaNftMetadata</a></td><td>Short description
</td>
</tr>
</table>

### ChiaNftOffers

<table>
<tr>
<td><a href="docs/Select-ChiaNftOffers.md">Select-ChiaNftOffers</a></td><td>
Select-ChiaNftOffers [[-offerType] <Object>] [<CommonParameters>]

</td>
</tr>
<tr>
<td><a href="docs/Show-ChiaNftOffers.md">Show-ChiaNftOffers</a></td><td>Short description
</td>
</tr>
</table>

### ChiaNftOverview

<table>
<tr>
<td><a href="docs/Show-ChiaNftOverview.md">Show-ChiaNftOverview</a></td><td>
Show-ChiaNftOverview [[-wallet_ids] <Object>] [[-nft_coin_id] <Object>]

</td>
</tr>
</table>

### ChiaNftRecords

<table>
<tr>
<td><a href="docs/Get-ChiaNftRecords.md">Get-ChiaNftRecords</a></td><td>
Get-ChiaNftRecords [[-start] <Object>] [[-end] <Object>] [<CommonParameters>]

</td>
</tr>
</table>

### ChiaNfts

<table>
<tr>
<td><a href="docs/Get-ChiaNfts.md">Get-ChiaNfts</a></td><td>
Get-ChiaNfts [[-wallet_ids] <Object>] [[-nft_coin_id] <Object>] [<CommonParameters>]

</td>
</tr>
<tr>
<td><a href="docs/Select-ChiaNfts.md">Select-ChiaNfts</a></td><td>
Select-ChiaNfts [[-wallet_id] <Object>] [[-Columns] <Object>] [<CommonParameters>]

</td>
</tr>
<tr>
<td><a href="docs/Show-ChiaNfts.md">Show-ChiaNfts</a></td><td>
Show-ChiaNfts [[-wallet_id] <Object>] [[-View] <Object>] [[-Columns] <Object>] [<CommonParameters>]

</td>
</tr>
</table>

### ChiaNftWalletDid

<table>
<tr>
<td><a href="docs/Get-ChiaNftWalletDid.md">Get-ChiaNftWalletDid</a></td><td>
Get-ChiaNftWalletDid [[-wallet_ids] <Object>] [<CommonParameters>]

</td>
</tr>
</table>

### ChiaOffer

<table>
<tr>
<td><a href="docs/Confirm-ChiaOffer.md">Confirm-ChiaOffer</a></td><td>
Confirm-ChiaOffer [[-offer] <Object>] [[-fee] <Object>] [-Confirm] [<CommonParameters>]

</td>
</tr>
<tr>
<td><a href="docs/New-ChiaOffer.md">New-ChiaOffer</a></td><td>
New-ChiaOffer [-offerAsset] <Object> [[-offerCount] <Object>] [-requestAsset] <Object> [[-requestCount] <Object>] [[-fee] <Object>] [<CommonParameters>]

</td>
</tr>
<tr>
<td><a href="docs/Remove-ChiaOffer.md">Remove-ChiaOffer</a></td><td>Short description
</td>
</tr>
</table>

### ChiaOffers

<table>
<tr>
<td><a href="docs/Get-ChiaOffers.md">Get-ChiaOffers</a></td><td>
Get-ChiaOffers [[-start] <Object>] [[-end] <Object>] [<CommonParameters>]

</td>
</tr>
<tr>
<td><a href="docs/Show-ChiaOffers.md">Show-ChiaOffers</a></td><td>Short description
</td>
</tr>
</table>

### ChiaOfferSummary

<table>
<tr>
<td><a href="docs/Get-ChiaOfferSummary.md">Get-ChiaOfferSummary</a></td><td>
Get-ChiaOfferSummary [[-offer] <Object>] [<CommonParameters>]

</td>
</tr>
</table>

### ChiaSplitCoins

<table>
<tr>
<td><a href="docs/Invoke-ChiaSplitCoins.md">Invoke-ChiaSplitCoins</a></td><td>Splits Chia Coins like explained in
- <https://rudolfachter.github.io/blockchain-stuff/public/chia/splitting_coins_for_offers/>
</td>
</tr>
</table>

### ChiaSplitHalf

<table>
<tr>
<td><a href="docs/Invoke-ChiaSplitHalf.md">Invoke-ChiaSplitHalf</a></td><td>Splits Chia Coins like explained in
- <https://rudolfachter.github.io/blockchain-stuff/public/chia/splitting_coins_for_offers/>
</td>
</tr>
</table>

### ChiaTransaction

<table>
<tr>
<td><a href="docs/Get-ChiaTransaction.md">Get-ChiaTransaction</a></td><td>
Get-ChiaTransaction [-transaction_id] <string> [<CommonParameters>]

</td>
</tr>
<tr>
<td><a href="docs/Send-ChiaTransaction.md">Send-ChiaTransaction</a></td><td>Sends a Chia Transaction
</td>
</tr>
</table>

### ChiaTransactions

<table>
<tr>
<td><a href="docs/Get-ChiaTransactions.md">Get-ChiaTransactions</a></td><td>
Get-ChiaTransactions [[-wallet_id] <int>] [[-start] <int>] [[-end] <int>] [-reverse] [<CommonParameters>]

</td>
</tr>
</table>

### ChiaWallet

<table>
<tr>
<td><a href="docs/Select-ChiaWallet.md">Select-ChiaWallet</a></td><td>
Select-ChiaWallet [[-wallet_type] <Object>] [<CommonParameters>]

</td>
</tr>
</table>

### ChiaWalletBalance

<table>
<tr>
<td><a href="docs/Get-ChiaWalletBalance.md">Get-ChiaWalletBalance</a></td><td>
Get-ChiaWalletBalance [[-wallet_id] <Object>] [<CommonParameters>]

</td>
</tr>
</table>

### ChiaWallets

<table>
<tr>
<td><a href="docs/Get-ChiaWallets.md">Get-ChiaWallets</a></td><td>
Get-ChiaWallets [[-wallet_type] <Object>] [-NoAdditionalInfo] [<CommonParameters>]

</td>
</tr>
<tr>
<td><a href="docs/Show-ChiaWallets.md">Show-ChiaWallets</a></td><td>
Show-ChiaWallets [[-wallet_type] <Object>] [[-View] <Object>] [[-Columns] <Object>] [<CommonParameters>]

</td>
</tr>
</table>

### NftHtml

<table>
<tr>
<td><a href="docs/Convert-NftHtml.md">Convert-NftHtml</a></td><td>
Convert-NftHtml [[-Nfts] <Object>] [[-Properties] <Object>] [[-Class] <Object>] [<CommonParameters>]

</td>
</tr>
</table>

### Tree

<table>
<tr>
<td><a href="docs/Show-Tree.md">Show-Tree</a></td><td>
Show-Tree [[-Path] <Object>] [-MaxDepth <int>] [-ShowDirectory] [-NotLike <string[]>] [-Like <string[]>] [-_Depth <int>] [<CommonParameters>]

</td>
</tr>
</table>


