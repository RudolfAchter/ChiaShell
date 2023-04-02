# Invoke-ChiaSplitHalf
Splits Chia Coins like explained in
- <https://rudolfachter.github.io/blockchain-stuff/public/chia/splitting_coins_for_offers/>


## Description


When you transferred the coins to your wallet in just one transaction, you will just have
one "physical" coin with a value in your wallet. This coin can only be used for one offer.
If you want to do multiple offers in parallel, you must have multiple coins in your wallet.
one coin for each offer.
This Function is a workaround to split your coins into multiple coins by sending them to
yourself.





## Parameter

### -myAddress


<table><tr><td>description</td><td>
Your Chia Address (xch1....)



</td></tr>
<tr><td>required</td><td>true
</td></tr>
<tr><td>position</td><td>1
</td></tr>
<tr><td>type</td><td>Object
</td></tr>
<tr><td>pipelineInput</td><td>false
</td></tr>
<tr><td>defaultValue</td><td>
</td></tr>
</table>

### -fee


<table><tr><td>description</td><td>
How much fee you want to use for each split (Default: 0)



</td></tr>
<tr><td>required</td><td>false
</td></tr>
<tr><td>position</td><td>2
</td></tr>
<tr><td>type</td><td>Object
</td></tr>
<tr><td>pipelineInput</td><td>false
</td></tr>
<tr><td>defaultValue</td><td>0
</td></tr>
</table>

### -memo


<table><tr><td>description</td><td>
Default: "coinSplit"



</td></tr>
<tr><td>required</td><td>false
</td></tr>
<tr><td>position</td><td>3
</td></tr>
<tr><td>type</td><td>Object
</td></tr>
<tr><td>pipelineInput</td><td>false
</td></tr>
<tr><td>defaultValue</td><td>coinSplit
</td></tr>
</table>

### -splitTimes


<table><tr><td>description</td><td>
How many times do you want to split (Default: 1)



</td></tr>
<tr><td>required</td><td>false
</td></tr>
<tr><td>position</td><td>4
</td></tr>
<tr><td>type</td><td>Object
</td></tr>
<tr><td>pipelineInput</td><td>false
</td></tr>
<tr><td>defaultValue</td><td>1
</td></tr>
</table>

## Beispiele

### Beispiel 1
```powershell
Invoke-ChiaSplitCoins -myAddress xch1r.....yvtlx6 -AmountXch 0.03 -splitTimes 30
     
```
## Related Links


---
## PlainText Hilfe

```

NAME
    Invoke-ChiaSplitHalf
    
ÜBERSICHT
    Splits Chia Coins like explained in
    - <https://rudolfachter.github.io/blockchain-stuff/public/chia/splitting_coins_for_offers/>
    
    
SYNTAX
    Invoke-ChiaSplitHalf [-myAddress] <Object> [[-fee] <Object>] [[-memo] <Object>] [[-splitTimes] <Object>] 
    [<CommonParameters>]
    
    
BESCHREIBUNG
    When you transferred the coins to your wallet in just one transaction, you will just have
    one "physical" coin with a value in your wallet. This coin can only be used for one offer.
    If you want to do multiple offers in parallel, you must have multiple coins in your wallet.
    one coin for each offer.
    This Function is a workaround to split your coins into multiple coins by sending them to
    yourself.
    

PARAMETER
    -myAddress <Object>
        Your Chia Address (xch1....)
        
        Erforderlich?                true
        Position?                    1
        Standardwert                 
        Pipelineeingaben akzeptieren?false
        Platzhalterzeichen akzeptieren?false
        
    -fee <Object>
        How much fee you want to use for each split (Default: 0)
        
        Erforderlich?                false
        Position?                    2
        Standardwert                 0
        Pipelineeingaben akzeptieren?false
        Platzhalterzeichen akzeptieren?false
        
    -memo <Object>
        Default: "coinSplit"
        
        Erforderlich?                false
        Position?                    3
        Standardwert                 coinSplit
        Pipelineeingaben akzeptieren?false
        Platzhalterzeichen akzeptieren?false
        
    -splitTimes <Object>
        How many times do you want to split (Default: 1)
        
        Erforderlich?                false
        Position?                    4
        Standardwert                 1
        Pipelineeingaben akzeptieren?false
        Platzhalterzeichen akzeptieren?false
        
    <CommonParameters>
        Dieses Cmdlet unterstützt folgende allgemeine Parameter: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable und OutVariable. Weitere Informationen finden Sie unter 
        "about_CommonParameters" (https:/go.microsoft.com/fwlink/?LinkID=113216). 
    
EINGABEN
    
AUSGABEN
    
HINWEISE
    
    
        General notes
    
    -------------------------- BEISPIEL 1 --------------------------
    
    PS C:\>Invoke-ChiaSplitCoins -myAddress xch1r.....yvtlx6 -AmountXch 0.03 -splitTimes 30
    
    
    
    
    
    
    
VERWANDTE LINKS



```

