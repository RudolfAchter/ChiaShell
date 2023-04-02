# Get-ChiaNftMetadata
Short description


## Description


Long description





## Parameter

### -nfts


<table><tr><td>description</td><td>
Parameter description



</td></tr>
<tr><td>required</td><td>false
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

### -TimeoutSec


<table><tr><td>description</td><td></td></tr>
<tr><td>required</td><td>false
</td></tr>
<tr><td>position</td><td>2
</td></tr>
<tr><td>type</td><td>Object
</td></tr>
<tr><td>pipelineInput</td><td>false
</td></tr>
<tr><td>defaultValue</td><td>5
</td></tr>
</table>

## Beispiele

### Beispiel 1
```powershell
Get-ChiaNfts | Get-ChiaNftInfo | Get-ChiaNftMetadata
     
```
## Related Links


---
## PlainText Hilfe

```

NAME
    Get-ChiaNftMetadata
    
ÜBERSICHT
    Short description
    
    
SYNTAX
    Get-ChiaNftMetadata [[-nfts] <Object>] [[-TimeoutSec] <Object>] [<CommonParameters>]
    
    
BESCHREIBUNG
    Long description
    

PARAMETER
    -nfts <Object>
        Parameter description
        
        Erforderlich?                false
        Position?                    1
        Standardwert                 
        Pipelineeingaben akzeptieren?true (ByValue)
        Platzhalterzeichen akzeptieren?false
        
    -TimeoutSec <Object>
        
        Erforderlich?                false
        Position?                    2
        Standardwert                 5
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
    
    PS C:\>Get-ChiaNfts | Get-ChiaNftInfo | Get-ChiaNftMetadata
    
    
    
    
    
    
    
VERWANDTE LINKS



```

