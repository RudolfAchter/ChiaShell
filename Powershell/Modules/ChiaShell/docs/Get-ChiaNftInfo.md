# Get-ChiaNftInfo
Short description


## Description


Long description





## Parameter

### -coin_ids


<table><tr><td>description</td><td></td></tr>
<tr><td>required</td><td>true
</td></tr>
<tr><td>position</td><td>1
</td></tr>
<tr><td>type</td><td>Object
</td></tr>
<tr><td>pipelineInput</td><td>true (ByValue)
</td></tr>
<tr><td>defaultValue</td><td>
</td></tr>
</table>

### -NoCache


<table><tr><td>description</td><td></td></tr>
<tr><td>required</td><td>false
</td></tr>
<tr><td>position</td><td>named
</td></tr>
<tr><td>type</td><td>SwitchParameter
</td></tr>
<tr><td>pipelineInput</td><td>false
</td></tr>
<tr><td>defaultValue</td><td>False
</td></tr>
</table>

## Beispiele

### Beispiel 1
```powershell
$start=(Get-ChiaBlockHeight -Date "2022-05-01").BlockHeight
Get-ChiaNftRecords -start $start | Get-ChiaNftInfo     
```
## Related Links


---
## PlainText Hilfe

```

NAME
    Get-ChiaNftInfo
    
ÜBERSICHT
    Short description
    
    
SYNTAX
    Get-ChiaNftInfo [-coin_ids] <Object> [-NoCache] [<CommonParameters>]
    
    
BESCHREIBUNG
    Long description
    

PARAMETER
    -coin_ids <Object>
        
        Erforderlich?                true
        Position?                    1
        Standardwert                 
        Pipelineeingaben akzeptieren?true (ByValue)
        Platzhalterzeichen akzeptieren?false
        
    -NoCache [<SwitchParameter>]
        
        Erforderlich?                false
        Position?                    named
        Standardwert                 False
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
    
    PS C:\>$start=(Get-ChiaBlockHeight -Date "2022-05-01").BlockHeight
    
    Get-ChiaNftRecords -start $start | Get-ChiaNftInfo
    
    
    
    
    
VERWANDTE LINKS



```

