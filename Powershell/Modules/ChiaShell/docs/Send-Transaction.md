# Send-Transaction
Sends a Chia Transaction


[[_TOC_]]

## Description


Sends a Chia Transaction





## Parameter

### -wallet_id


<table><tr><td>description</td><td>
which wallet to use



</td></tr>
<tr><td>required</td><td>false
</td></tr>
<tr><td>position</td><td>1
</td></tr>
<tr><td>type</td><td>Int32
</td></tr>
<tr><td>pipelineInput</td><td>false
</td></tr>
<tr><td>defaultValue</td><td>1
</td></tr>
</table>

### -amount


<table><tr><td>description</td><td>
amount in mojo (1e-12 xch)



</td></tr>
<tr><td>required</td><td>true
</td></tr>
<tr><td>position</td><td>2
</td></tr>
<tr><td>type</td><td>Int64
</td></tr>
<tr><td>pipelineInput</td><td>false
</td></tr>
<tr><td>defaultValue</td><td>0
</td></tr>
</table>

### -fee


<table><tr><td>description</td><td>
fee to use



</td></tr>
<tr><td>required</td><td>false
</td></tr>
<tr><td>position</td><td>3
</td></tr>
<tr><td>type</td><td>Int64
</td></tr>
<tr><td>pipelineInput</td><td>false
</td></tr>
<tr><td>defaultValue</td><td>0
</td></tr>
</table>

### -address


<table><tr><td>description</td><td>
transaction to which address



</td></tr>
<tr><td>required</td><td>true
</td></tr>
<tr><td>position</td><td>4
</td></tr>
<tr><td>type</td><td>String
</td></tr>
<tr><td>pipelineInput</td><td>false
</td></tr>
<tr><td>defaultValue</td><td>
</td></tr>
</table>

### -memos


<table><tr><td>description</td><td>
Memos (String or Array of multiple memos)



</td></tr>
<tr><td>required</td><td>false
</td></tr>
<tr><td>position</td><td>5
</td></tr>
<tr><td>type</td><td>Object
</td></tr>
<tr><td>pipelineInput</td><td>false
</td></tr>
<tr><td>defaultValue</td><td>
</td></tr>
</table>

## Beispiele

### Beispiel 1
```powershell
Send-Transaction -wallet_id $wallet.id -amount $amount -fee $fee -address $myAddress -memos $memo
     
```
## Related Links


---
## PlainText Hilfe

```

NAME
    Send-Transaction
    
ÜBERSICHT
    Sends a Chia Transaction
    
    
SYNTAX
    Send-Transaction [[-wallet_id] <Int32>] [-amount] <Int64> [[-fee] <Int64>] [-address] <String> [[-memos] <Object>] [<CommonParameters>]
    
    
BESCHREIBUNG
    Sends a Chia Transaction
    

PARAMETER
    -wallet_id <Int32>
        which wallet to use
        
        Erforderlich?                false
        Position?                    1
        Standardwert                 1
        Pipelineeingaben akzeptieren?false
        Platzhalterzeichen akzeptieren?false
        
    -amount <Int64>
        amount in mojo (1e-12 xch)
        
        Erforderlich?                true
        Position?                    2
        Standardwert                 0
        Pipelineeingaben akzeptieren?false
        Platzhalterzeichen akzeptieren?false
        
    -fee <Int64>
        fee to use
        
        Erforderlich?                false
        Position?                    3
        Standardwert                 0
        Pipelineeingaben akzeptieren?false
        Platzhalterzeichen akzeptieren?false
        
    -address <String>
        transaction to which address
        
        Erforderlich?                true
        Position?                    4
        Standardwert                 
        Pipelineeingaben akzeptieren?false
        Platzhalterzeichen akzeptieren?false
        
    -memos <Object>
        Memos (String or Array of multiple memos)
        
        Erforderlich?                false
        Position?                    5
        Standardwert                 
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
    
    PS C:\>Send-Transaction -wallet_id $wallet.id -amount $amount -fee $fee -address $myAddress -memos $memo
    
    
    
    
    
    
    
VERWANDTE LINKS



```

