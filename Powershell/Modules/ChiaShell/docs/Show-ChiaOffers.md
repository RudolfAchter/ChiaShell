# Show-ChiaOffers
Short description


## Description


Long description





## Parameter

### -start


<table><tr><td>description</td><td>
Parameter description



</td></tr>
<tr><td>required</td><td>false
</td></tr>
<tr><td>position</td><td>1
</td></tr>
<tr><td>type</td><td>Object
</td></tr>
<tr><td>pipelineInput</td><td>false
</td></tr>
<tr><td>defaultValue</td><td>0
</td></tr>
</table>

### -end


<table><tr><td>description</td><td>
Parameter description



</td></tr>
<tr><td>required</td><td>false
</td></tr>
<tr><td>position</td><td>2
</td></tr>
<tr><td>type</td><td>Object
</td></tr>
<tr><td>pipelineInput</td><td>false
</td></tr>
<tr><td>defaultValue</td><td>100
</td></tr>
</table>

## Beispiele

### Beispiel 1
```powershell
Show-ChiaOffers | %{Get-ChiaNftInfo -coin_id $_.requested_item} | %{Start-Process $_.data_uris[0]}
     
```
## Related Links


---
## PlainText Hilfe

```

NAME
    Show-ChiaOffers
    
ÜBERSICHT
    Short description
    
    
SYNTAX
    Show-ChiaOffers [[-start] <Object>] [[-end] <Object>] [<CommonParameters>]
    
    
BESCHREIBUNG
    Long description
    

PARAMETER
    -start <Object>
        Parameter description
        
        Erforderlich?                false
        Position?                    1
        Standardwert                 0
        Pipelineeingaben akzeptieren?false
        Platzhalterzeichen akzeptieren?false
        
    -end <Object>
        Parameter description
        
        Erforderlich?                false
        Position?                    2
        Standardwert                 100
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
    
    PS C:\>Show-ChiaOffers | %{Get-ChiaNftInfo -coin_id $_.requested_item} | %{Start-Process $_.data_uris[0]}
    
    
    
    
    
    
    
VERWANDTE LINKS



```

