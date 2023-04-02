# Show-ChiaNftOffers
Short description


## Description


Long description





## Parameter

### -offerType


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
<tr><td>defaultValue</td><td>offered
</td></tr>
</table>

### -start


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
<tr><td>defaultValue</td><td>0
</td></tr>
</table>

### -end


<table><tr><td>description</td><td>
Parameter description



</td></tr>
<tr><td>required</td><td>false
</td></tr>
<tr><td>position</td><td>3
</td></tr>
<tr><td>type</td><td>Object
</td></tr>
<tr><td>pipelineInput</td><td>false
</td></tr>
<tr><td>defaultValue</td><td>50
</td></tr>
</table>

## Beispiele

### Beispiel 1
```powershell
Show-ChiaNftOffers | Where-Object {$_.nft_info.name -like "Khopesh*"}
     
```
## Related Links


---
## PlainText Hilfe

```

NAME
    Show-ChiaNftOffers
    
ÜBERSICHT
    Short description
    
    
SYNTAX
    Show-ChiaNftOffers [[-offerType] <Object>] [[-start] <Object>] [[-end] <Object>] [<CommonParameters>]
    
    
BESCHREIBUNG
    Long description
    

PARAMETER
    -offerType <Object>
        Parameter description
        
        Erforderlich?                false
        Position?                    1
        Standardwert                 offered
        Pipelineeingaben akzeptieren?false
        Platzhalterzeichen akzeptieren?false
        
    -start <Object>
        Parameter description
        
        Erforderlich?                false
        Position?                    2
        Standardwert                 0
        Pipelineeingaben akzeptieren?false
        Platzhalterzeichen akzeptieren?false
        
    -end <Object>
        Parameter description
        
        Erforderlich?                false
        Position?                    3
        Standardwert                 50
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
    
    PS C:\>Show-ChiaNftOffers | Where-Object {$_.nft_info.name -like "Khopesh*"}
    
    
    
    
    
    
    
VERWANDTE LINKS



```

