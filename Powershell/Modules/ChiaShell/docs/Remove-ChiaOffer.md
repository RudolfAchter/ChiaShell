# Remove-ChiaOffer
Short description


## Description


Long description





## Parameter

### -trade_ids


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

### -secure


<table><tr><td>description</td><td>
Parameter description



</td></tr>
<tr><td>required</td><td>false
</td></tr>
<tr><td>position</td><td>2
</td></tr>
<tr><td>type</td><td>Boolean
</td></tr>
<tr><td>pipelineInput</td><td>false
</td></tr>
<tr><td>defaultValue</td><td>True
</td></tr>
</table>

## Beispiele

### Beispiel 1
```powershell
Show-ChiaOffers | Where-Object status -eq "PENDING_ACCEPT" | Remove-Offer
```text
trade_id                                                           success
--------                                                           -------
0x051e7141341a95396e6fa18662be6d5f0f5ab4b6ecdfaa5d39877a2f5e9dbcd4    True
0x2ffb8afc6bba8ea5a94f76ddf605a94a2a4922c7a43cf66c27d6f427544e6971    True
0x84d632fb57fb20e4b24e137b9403438807bc72a5e45ebd727c870fbc8d2d1324    True
0xf7c1bca5cbb83124ad59d4c2f04bc5161043b365b348e2694b46f1d64ad3ac20    True
0xfa43c54f65f43486bb8e40139edc470fc8ae42b8ad6eea60abdd09442259be3d    True
```     
```
## Related Links


---
## PlainText Hilfe

```

NAME
    Remove-ChiaOffer
    
ÜBERSICHT
    Short description
    
    
SYNTAX
    Remove-ChiaOffer [[-trade_ids] <Object>] [[-secure] <Boolean>] [<CommonParameters>]
    
    
BESCHREIBUNG
    Long description
    

PARAMETER
    -trade_ids <Object>
        Parameter description
        
        Erforderlich?                false
        Position?                    1
        Standardwert                 
        Pipelineeingaben akzeptieren?true (ByValue)
        Platzhalterzeichen akzeptieren?false
        
    -secure <Boolean>
        Parameter description
        
        Erforderlich?                false
        Position?                    2
        Standardwert                 True
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
    
    PS C:\>Show-ChiaOffers | Where-Object status -eq "PENDING_ACCEPT" | Remove-Offer
    
    ```text
    trade_id                                                           success
    --------                                                           -------
    0x051e7141341a95396e6fa18662be6d5f0f5ab4b6ecdfaa5d39877a2f5e9dbcd4    True
    0x2ffb8afc6bba8ea5a94f76ddf605a94a2a4922c7a43cf66c27d6f427544e6971    True
    0x84d632fb57fb20e4b24e137b9403438807bc72a5e45ebd727c870fbc8d2d1324    True
    0xf7c1bca5cbb83124ad59d4c2f04bc5161043b365b348e2694b46f1d64ad3ac20    True
    0xfa43c54f65f43486bb8e40139edc470fc8ae42b8ad6eea60abdd09442259be3d    True
    ```
    
    
    
    
    
VERWANDTE LINKS



```

