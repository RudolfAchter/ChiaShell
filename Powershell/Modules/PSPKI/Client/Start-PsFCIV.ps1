function Start-PsFCIV {
<#
.ExternalHelp PSPKI.Help.xml
#>
[CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [IO.DirectoryInfo]$Path,
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = '__xml')]
        [string]$XML,
        [Parameter(Position = 2)]
        [string]$Include = "*",
        [Parameter(Position = 3)]
        [string[]]$Exclude,
        [ValidateSet("Rename", "Delete")]
        [string]$Action,
        [ValidateSet("Bad", "Locked", "Missed", "New", "Ok", "Unknown", "All")]
        [String[]]$Show,
        [ValidateSet("MD5", "SHA1", "SHA256", "SHA384", "SHA512")]
        [AllowEmptyCollection()]
        [String[]]$HashAlgorithm = "SHA1",
        [switch]$Recurse,
        [switch]$Rebuild,
        [switch]$Quiet,
        [switch]$NoStatistic,
        [Parameter(ParameterSetName = '__online')]
        [switch]$Online
    )

#region C# wrappers
Add-Type @"
using System;
using System.Collections.Generic;
using System.Xml.Serialization;
namespace PsFCIV {
    public class StatTable {
        public List<String> Total = new List<String>();
        public List<String> New = new List<String>();
        public List<String> Ok = new List<String>();
        public List<String> Bad = new List<String>();
        public List<String> Missed = new List<String>();
        public List<String> Locked = new List<String>();
        public List<String> Unknown = new List<String>();
        public int Del;
    }
    public class IntStatTable {
        public Int32 Total;
        public Int32 New;
        public Int32 Ok;
        public Int32 Bad;
        public Int32 Missed;
        public Int32 Locked;
        public Int32 Unknown;
        public Int32 Del;
    }
    [XmlType(AnonymousType = true)]
    [XmlRoot(Namespace = "", IsNullable = false)]
    public class FCIV {
        public FCIV() { FILE_ENTRY = new List<FCIVFILE_ENTRY>(); }
        
        [XmlElement("FILE_ENTRY")]
        public List<FCIVFILE_ENTRY> FILE_ENTRY { get; set; }
    }
    [XmlType(AnonymousType = true)]
    public class FCIVFILE_ENTRY {
        public FCIVFILE_ENTRY() { }
        public FCIVFILE_ENTRY(string path) { name = path; }

        public String name { get; set; }
        public UInt64 Size { get; set; }
        public String TimeStamp { get; set; }
        public String MD5 { get; set; }
        public String SHA1 { get; set; }
        public String SHA256 { get; set; }
        public String SHA384 { get; set; }
        public String SHA512 { get; set; }

        public override Int32 GetHashCode() { return name.GetHashCode(); }
        public override Boolean Equals(Object other) {
            if (ReferenceEquals(null, other) || other.GetType() != GetType()) { return false; }
            return other.GetType() == GetType() && String.Equals(name, ((FCIVFILE_ENTRY)other).name);
        }
    }
}
"@ -Debug:$false -Verbose:$false -ReferencedAssemblies "System.Xml"
Add-Type -AssemblyName System.Xml
#endregion
    
    if ($PSBoundParameters.Verbose) {$VerbosePreference = "continue"}
    if ($PSBoundParameters.Debug) {$DebugPreference = "continue"}
    # preserving current path
    $oldpath = $pwd.Path
    $Exclude += $XML

    if (Test-Path -LiteralPath $path) {
        Set-Location -LiteralPath $path
        if ($pwd.Provider.Name -ne "FileSystem") {
            Set-Location $oldpath
            throw "Specified path is not filesystem path. Try again!"
        }
    } else {throw "Specified path not found."}
    
    # statistic variables
    $sum = $new = New-Object PsFCIV.FCIV
    # creating statistics variable with properties. Each property will contain file names (and paths) with corresponding status.
    $global:stats = New-Object PsFCIV.StatTable
    $script:statcount = New-Object PsFCIV.IntStatTable
    
    # lightweight proxy function for Get-ChildItem cmdlet
    function dirx ([string]$Path, [string]$Filter, [string[]]$Exclude, $Recurse, [switch]$Force) {
        Get-ChildItem @PSBoundParameters -ErrorAction SilentlyContinue | Where-Object {!$_.psiscontainer}
    }	
    # internal function that will check whether the file is locked. All locked files are added to a group with 'Unknown' status.
    function __filelock ($file) {
        $locked = $false
        trap {Set-Variable -name locked -value $true -scope 1; continue}
        $inputStream = New-Object IO.StreamReader $file.FullName
        if ($inputStream) {$inputStream.Close()}
        if ($locked) {
            Write-Verbose "File $($file.Name) is locked. Skipping this file.."
            Write-Debug "File $($file.Name) is locked. Skipping this file.."
            __statcounter $filename Locked
        }
        $locked
    }	
    # internal function to generate UI window with results by using Out-GridView cmdlet.
    function __formatter ($props, $max) {
        $total = @($input)
        foreach ($property in $props) {
            $(for ($n = 0; $n -lt $max; $n++) {
                $total[0] | Select-Object @{n = $property; e = {$_.$property[$n]}}
            }) | Out-GridView -Title "File list by category: $property"
        }
    }
    # internal hasher
    function __hashbytes ($type, $file) {
        $hasher = [Security.Cryptography.HashAlgorithm]::Create($type)
        $inputStream = New-Object IO.StreamReader $file.FullName
        $hashBytes = $hasher.ComputeHash($inputStream.BaseStream)
        $hasher.Clear()
        $inputStream.Close()
        $hashBytes
    }
    # internal function which reads the XML file (if exist).
    function __fromxml ($xml) {
    # reading existing XML file and selecting required properties
        if (!(Test-Path -LiteralPath $XML)) {return New-Object PsFCIV.FCIV}
        try {
            $fs = New-Object IO.FileStream $XML, "Open"
            $xmlser = New-Object System.Xml.Serialization.XmlSerializer ([Type][PsFCIV.FCIV])
            $sum = $xmlser.Deserialize($fs)
            $fs.Close()
            $sum
        } catch {
            Write-Error -Category InvalidData -Message "Input XML file is not valid FCIV XML file."
        } finally {
            if ($fs -ne $null) {$fs.Close()}
        }
        
    }
    # internal xml writer
    function __writexml ($sum) {
        if ($sum.FILE_ENTRY.Count -eq 0) {
            Write-Verbose "There is no data to write to XML database."
            Write-Debug "There is no data to write to XML database."
        } else {
            Write-Debug "Preparing to DataBase file creation..."
            try {
                $fs = New-Object IO.FileStream $XML, "Create"
                $xmlser = New-Object System.Xml.Serialization.XmlSerializer ([Type][PsFCIV.FCIV])
                $xmlser.Serialize($fs,$sum)
            } finally {
                if ($fs -ne $null) {$fs.Close()}
            }
            Write-Debug "DataBase file created..."
        }
    }
    # internal function to create XML entry object for a file.
    function __makeobject ($file, [switch]$NoHash, [switch]$hex) {
        Write-Debug "Starting object creation for '$($file.FullName)'..."
        $object = New-Object PsFCIV.FCIVFILE_ENTRY
        $object.name = $file.FullName -replace [regex]::Escape($($pwd.ProviderPath + "\"))
        $object.Size = $file.Length
        # use culture-invariant date/time format.
        $object.TimeStamp = "$($file.LastWriteTime.ToUniversalTime())"
        if (!$NoHash) {
        # calculating appropriate hash and convert resulting byte array to a Base64 string
            foreach ($hash in "MD5", "SHA1", "SHA256", "SHA384", "SHA512") {
                if ($HashAlgorithm -contains $hash) {
                    Write-Debug "Calculating '$hash' hash..."
                    $hashBytes = __hashbytes $hash $file
                    if ($hex) {
                        $object.$hash = -join ($hashBytes | Foreach-Object {"{0:X2}" -f $_})
                    } else {
                        Write-Debug ("Calculated hash value: " + (-join ($hashBytes | Foreach-Object {"{0:X2}" -f $_})))
                        $object.$hash = [System.Convert]::ToBase64String($hashBytes)
                    }
                }
            }
        }
        Write-Debug "Object created!"
        $object
    }	
    # internal function that calculates current file hash and formats it to an octet string (for example, B926D7416E8235E6F94F756E9F3AE2F33A92B2C4).
    function __precheck ($entry, $file, $HashAlgorithm) {
        if ($HashAlgorithm.Length -gt 0) {
            $SelectedHash = $HashAlgorithm
        } else {
            :outer foreach ($hash in "SHA512", "SHA384", "SHA256", "SHA1", "MD5") {
                if ($entry.$hash) {$SelectedHash = $hash; break outer}
            }
        }
        Write-Debug "Selected hash: $hash"
        -join ($(__hashbytes $SelectedHash $file) | ForEach-Object {"{0:X2}" -f $_})
        $SelectedHash
    }
    # process -Action parameter to perform an action against bad file (if actual file properties do not match the record in XML).
    function __takeaction ($file, $Action) {
        switch ($Action) {
            "Rename" {Rename-Item $file $($file.FullName + ".bad")}
            "Delete" {Remove-Item $file -Force}
        }
    }	
    # core file verification function.
    function __checkfiles ($entry, $file, $Action) {
        if (($file.Length -eq $entry.Size) -and ("$($file.LastWriteTime.ToUniversalTime())" -eq $entry.TimeStamp)) {
            $hexhash = __precheck $entry $file $HashAlgorithm
            $ActualHash = -join ([Convert]::FromBase64String($entry.($hexhash[1])) | ForEach-Object {"{0:X2}" -f $_})
            if (!$ActualHash) {
                Write-Verbose "XML database entry does not contains '$($hexhash[1])' hash value for the entry '$($entry.name)'."
                __statcounter $entry.name Unknown
                return
            } elseif ($ActualHash -eq $hexhash[0]) {
                Write-Debug "File hash: $ActualHash"
                Write-Verbose "File '$($file.name)' is ok."
                __statcounter $entry.name Ok
                return
            } else {
                Write-Debug "File '$($file.name)' failed hash verification.
                    Expected hash: $hexhash
                    Actual hash: $ActualHash"
                __statcounter $entry.name Bad
                if ($Action) {__takeaction $file $Action}
            }
        } else {
            Write-Verbose "File '$($file.FullName)' size or Modified Date/Time mismatch."
            Write-Debug "Expected file size is: $($entry.Size) byte(s), actual size is: $($file.Length) byte(s)."
            Write-Debug "Expected file modification time is: $($entry.TimeStamp), actual file modification time is: $($file.LastWriteTime.ToUniversalTime())"
            __statcounter $entry.name Bad
            if ($Action) {__takeaction $file $Action}
        }
    }
    # internal function to calculate resulting statistics and show if if necessary.	
    function __stats {
    # if -Show parameter is presented we display selected groups (Total, New, Ok, Bad, Missed, Unknown)
        if ($show -and !$NoStatistic) {
            if ($Show -eq "All" -or $Show.Contains("All")) {
                $global:stats | __formatter "Bad", "Locked", "Missed", "New", "Ok", "Unknown" $script:statcount.Total
            } else {
                $global:stats | Select-Object $show | __formatter $show $script:statcount.Total
            }			
        }
        # script work in numbers
        if (!$Quiet) {
            Write-Host ----------------------------------- -ForegroundColor Green
            if ($Rebuild) {
                Write-Host Total entries processed: $script:statcount.Total -ForegroundColor Cyan
                Write-Host Total removed unused entries: $script:statcount.Del -ForegroundColor Yellow
            } else {Write-Host Total files processed: $script:statcount.Total -ForegroundColor Cyan}
            Write-Host Total new added files: $script:statcount.New -ForegroundColor Green
            Write-Host Total good files: $script:statcount.Ok -ForegroundColor Green
            Write-Host Total bad files: $script:statcount.Bad -ForegroundColor Red
            Write-Host Total unknown status files: $script:statcount.Unknown -ForegroundColor Yellow
            Write-Host Total missing files: $script:statcount.Missed -ForegroundColor Yellow
            Write-Host Total locked files: $script:statcount.Locked -ForegroundColor Yellow
            Write-Host ----------------------------------- -ForegroundColor Green
        }
        # restore original variables
        Set-Location -LiteralPath $oldpath
        $exit = 0
        # create exit code depending on check status
        if ($Rebuild) {$exit = [int]::MaxValue} else {
            if ($script:statcount.Bad -ne 0) {$exit += 1}
            if ($script:statcount.Missed -ne 0) {$exit += 2}
            if ($script:statcount.Unknown -ne 0) {$exit += 4}
            if ($script:statcount.Locked -ne 0) {$exit += 8}
        }
        if ($Quiet) {exit $exit}
    }
    # internal function to update statistic counters.
    function __statcounter ($filename, $status) {
        $script:statcount.$status++
        $script:statcount.Total++
        if (!$NoStatistic) {
            $global:stats.$status.Add($filename)
        }
    }
    if ($Online) {
        Write-Debug "Online mode ON"
        dirx -Path .\* -Filter $Include -Exclude $Exclude $Recurse -Force | ForEach-Object {
            Write-Verbose "Perform file '$($_.fullName)' checking."
            $file = Get-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
            if (__filelock $file) {return}
            __makeobject $file -hex
        }
        return
    }

    <#
    in this part we perform XML file update by removing entries for non-exist files and
    adding new entries for files that are not in the database.
    #>
    if ($Rebuild) {
        Write-Debug "Rebuild mode ON"
        if (Test-Path -LiteralPath $xml) {
            $old = __fromxml $xml
        } else {
            Set-Location $oldpath
            throw "Unable to find XML file. Please, run the command without '-Rebuild' switch."
        }
        $interm = New-Object PsFCIV.FCIV
        # use foreach-object instead of where-object to keep original types.
        Write-Verbose "Perform DB file cleanup from non-existent items."
        $old.FILE_ENTRY | ForEach-Object {
            if ((Test-Path -LiteralPath $_.name)) {
                if ($_.name -eq $xml) {
                    Write-Debug "File '$($_.name)' is DB file. Removed."
                } else {
                    $interm.FILE_ENTRY.Add($_)
                }
            } else {
                Write-Debug "File '$($_.name)' does not exist. Removed."
            }
        }
        $script:statcount.Del = $interm.Length
        $script:statcount.Total = $old.FILE_ENTRY.Count - $interm.Length
        dirx -Path .\* -Filter $Include -Exclude $Exclude $Recurse -Force | ForEach-Object {
            Write-Verbose "Perform file '$($_.FullName)' checking."
            $file = Get-Item -LiteralPath $_.FullName -Force
            if (__filelock $file) {return}
            $filename = $file.FullName -replace [regex]::Escape($($pwd.providerpath + "\"))
            if ($interm.FILE_ENTRY.Contains((New-Object PsFCIV.FCIVFILE_ENTRY $filename))) {
                Write-Verbose "File '$filename' already exist in XML database. Skipping."
                return
            } else {
                $new.FILE_ENTRY.Add((__makeobject $file))
                Write-Verbose "File '$filename' is added."
                __statcounter $filename New
            }
        }
        $interm.FILE_ENTRY.AddRange($new.FILE_ENTRY)
        __writexml $interm
        __stats
        return
    }
    
    # this part contains main routine
    $sum = __fromxml $xml
    <#
    check XML file format. If Size property of the first element is zero, then the file was generated by
    original FCIV.exe tool. In this case we transform existing XML to a new PsFCIV format by adding new
    properties. Each record is checked against hashes stored in the source XML file. If hash check fails,
    an item is removed from final XML.
    #>
    if ($sum.FILE_ENTRY.Count -gt 0 -and $sum.FILE_ENTRY[0].Size -eq 0) {
        # 
        if ($PSBoundParameters.ContainsKey("HashAlgorithm")) {
            $HashAlgorithm = $HashAlgorithm[0].ToUpper()
        } else {
            $HashAlgorithm = @()
        }
        Write-Debug "FCIV (compatibility) mode ON"
        if ($HashAlgorithm -and $HashAlgorithm -notcontains "sha1" -and $HashAlgorithm -notcontains "md5") {
            throw "Specified hash algorithm (or algorithms) is not supported. For native FCIV source, use MD5 and/or SHA1."
        }
        for ($index = 0; $index -lt $sum.FILE_ENTRY.Count; $index++) {
            Write-Verbose "Perform file '$($sum.FILE_ENTRY[$index].name)' checking."
            $filename = $sum.FILE_ENTRY[$index].name
            # check if the path is absolute and matches current path. If the path is absolute and does not belong to
            # current path -- skip this entry.
            if ($filename.Contains(":") -and $filename -notmatch [regex]::Escape($pwd.ProviderPath)) {return}
            # if source file name record contains absolute path, and belongs to the current pathe,
            # just strip base path. New XML format uses relative paths only.
            if ($filename.Contains(":")) {$filename = $filename -replace ([regex]::Escape($($pwd.ProviderPath + "\")))}
            # Test if the file exist. If the file does not exist, skip the current entry and process another record.
            if (!(Test-Path -LiteralPath $filename)) {
                Write-Verbose "File '$filename' not found. Skipping."
                __statcounter $filename Missed
                return
            }
            # get file item and test if it is not locked by another application
            $file = Get-Item -LiteralPath $filename -Force -ErrorAction SilentlyContinue
            if (__filelock $file) {return}
            # create new-style entry record that stores additional data: file length and last modification timestamp.
            $entry = __makeobject $file -NoHash
            $entry.name = $filename
            # process current hash entries and copy required hash values to a new entry object.
            "SHA1", "MD5" | ForEach-Object {$entry.$_ = $sum.FILE_ENTRY[$index].$_}
            $sum.FILE_ENTRY[$index] = $entry
            __checkfiles $newentry $file $Action
        }
        # we are done. Overwrite XML, display stats and exit.
        __writexml $sum
        # display statistics and exit right now.
        __stats
    }
    # if XML file exist, proccess and check all records. XML file will not be modified.
    if ($sum.FILE_ENTRY.Count -gt 0) {
        Write-Debug "Native PsFCIV mode ON"
        # this part is executed only when we want to process certain file. Wildcards are not allowed.
        if ($Include -ne "*") {
            $sum.FILE_ENTRY | Where-Object {$_.name -like $Include} | ForEach-Object {
                Write-Verbose "Perform file '$($_.name)' checking."
                $entry = $_
                # calculate the hash if the file exist.
                if (Test-Path -LiteralPath $entry.name) {
                    # and check file integrity
                    $file = Get-Item -LiteralPath $entry.name -Force -ErrorAction SilentlyContinue
                    __checkfiles $entry $file $Action
                } else {
                    # if there is no record for the file, skip it and display appropriate message
                    Write-Verbose "File '$filename' not found. Skipping."
                    __statcounter $entry.name Missed
                }
            }
        } else {
            $sum.FILE_ENTRY | ForEach-Object {
                <#
                to process files only in the current directory (without subfolders), we remove items
                that contain slashes from the process list and continue regular file checking.
                #>
                if (!$Recurse -and $_.name -match "\\") {return}
                Write-Verbose "Perform file '$($_.name)' checking."
                $entry = $_
                if (Test-Path -LiteralPath $entry.name) {
                    $file = Get-Item -LiteralPath $entry.name -Force -ErrorAction SilentlyContinue
                    __checkfiles $entry $file $Action
                } else {
                    Write-Verbose "File '$($entry.name)' not found. Skipping."
                    __statcounter $entry.name Missed
                }
            }
        }
    } else {
        # if there is no existing XML DB file, start from scratch and create a new one.
        Write-Debug "New XML mode ON"

        dirx -Path .\* -Filter $Include -Exclude $Exclude $Recurse -Force | ForEach-Object {
            $_
            # Write-Verbose "Perform file '$($_.fullName)' checking."
            # $file = Get-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
            # if (__filelock $file) {return}
            # $entry = __makeobject $file
            # $sum.FILE_ENTRY.Add($entry)
            # __statcounter $entry.name New
        }
        __writexml $sum
    }
    __stats
}
# SIG # Begin signature block
# MIIfhgYJKoZIhvcNAQcCoIIfdzCCH3MCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDyiOQ9k5O1jC7L
# 65ADm7KbGxbYomcT8rhMn+L93frsTKCCGYYwggX1MIID3aADAgECAhAdokgwb5sm
# GNCC4JZ9M9NqMA0GCSqGSIb3DQEBDAUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UE
# CBMKTmV3IEplcnNleTEUMBIGA1UEBxMLSmVyc2V5IENpdHkxHjAcBgNVBAoTFVRo
# ZSBVU0VSVFJVU1QgTmV0d29yazEuMCwGA1UEAxMlVVNFUlRydXN0IFJTQSBDZXJ0
# aWZpY2F0aW9uIEF1dGhvcml0eTAeFw0xODExMDIwMDAwMDBaFw0zMDEyMzEyMzU5
# NTlaMHwxCzAJBgNVBAYTAkdCMRswGQYDVQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIx
# EDAOBgNVBAcTB1NhbGZvcmQxGDAWBgNVBAoTD1NlY3RpZ28gTGltaXRlZDEkMCIG
# A1UEAxMbU2VjdGlnbyBSU0EgQ29kZSBTaWduaW5nIENBMIIBIjANBgkqhkiG9w0B
# AQEFAAOCAQ8AMIIBCgKCAQEAhiKNMoV6GJ9J8JYvYwgeLdx8nxTP4ya2JWYpQIZU
# RnQxYsUQ7bKHJ6aZy5UwwFb1pHXGqQ5QYqVRkRBq4Etirv3w+Bisp//uLjMg+gwZ
# iahse60Aw2Gh3GllbR9uJ5bXl1GGpvQn5Xxqi5UeW2DVftcWkpwAL2j3l+1qcr44
# O2Pej79uTEFdEiAIWeg5zY/S1s8GtFcFtk6hPldrH5i8xGLWGwuNx2YbSp+dgcRy
# QLXiX+8LRf+jzhemLVWwt7C8VGqdvI1WU8bwunlQSSz3A7n+L2U18iLqLAevRtn5
# RhzcjHxxKPP+p8YU3VWRbooRDd8GJJV9D6ehfDrahjVh0wIDAQABo4IBZDCCAWAw
# HwYDVR0jBBgwFoAUU3m/WqorSs9UgOHYm8Cd8rIDZsswHQYDVR0OBBYEFA7hOqhT
# OjHVir7Bu61nGgOFrTQOMA4GA1UdDwEB/wQEAwIBhjASBgNVHRMBAf8ECDAGAQH/
# AgEAMB0GA1UdJQQWMBQGCCsGAQUFBwMDBggrBgEFBQcDCDARBgNVHSAECjAIMAYG
# BFUdIAAwUAYDVR0fBEkwRzBFoEOgQYY/aHR0cDovL2NybC51c2VydHJ1c3QuY29t
# L1VTRVJUcnVzdFJTQUNlcnRpZmljYXRpb25BdXRob3JpdHkuY3JsMHYGCCsGAQUF
# BwEBBGowaDA/BggrBgEFBQcwAoYzaHR0cDovL2NydC51c2VydHJ1c3QuY29tL1VT
# RVJUcnVzdFJTQUFkZFRydXN0Q0EuY3J0MCUGCCsGAQUFBzABhhlodHRwOi8vb2Nz
# cC51c2VydHJ1c3QuY29tMA0GCSqGSIb3DQEBDAUAA4ICAQBNY1DtRzRKYaTb3moq
# jJvxAAAeHWJ7Otcywvaz4GOz+2EAiJobbRAHBE++uOqJeCLrD0bs80ZeQEaJEvQL
# d1qcKkE6/Nb06+f3FZUzw6GDKLfeL+SU94Uzgy1KQEi/msJPSrGPJPSzgTfTt2Sw
# piNqWWhSQl//BOvhdGV5CPWpk95rcUCZlrp48bnI4sMIFrGrY1rIFYBtdF5KdX6l
# uMNstc/fSnmHXMdATWM19jDTz7UKDgsEf6BLrrujpdCEAJM+U100pQA1aWy+nyAl
# EA0Z+1CQYb45j3qOTfafDh7+B1ESZoMmGUiVzkrJwX/zOgWb+W/fiH/AI57SHkN6
# RTHBnE2p8FmyWRnoao0pBAJ3fEtLzXC+OrJVWng+vLtvAxAldxU0ivk2zEOS5LpP
# 8WKTKCVXKftRGcehJUBqhFfGsp2xvBwK2nxnfn0u6ShMGH7EezFBcZpLKewLPVdQ
# 0srd/Z4FUeVEeN0B3rF1mA1UJP3wTuPi+IO9crrLPTru8F4XkmhtyGH5pvEqCgul
# ufSe7pgyBYWe6/mDKdPGLH29OncuizdCoGqC7TtKqpQQpOEN+BfFtlp5MxiS47V1
# +KHpjgolHuQe8Z9ahyP/n6RRnvs5gBHN27XEp6iAb+VT1ODjosLSWxr6MiYtaldw
# HDykWC6j81tLB9wyWfOHpxptWDCCBkowggUyoAMCAQICEBdBS6OH2/E/xEs3Bf5c
# krcwDQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0
# ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEYMBYGA1UEChMPU2VjdGln
# byBMaW1pdGVkMSQwIgYDVQQDExtTZWN0aWdvIFJTQSBDb2RlIFNpZ25pbmcgQ0Ew
# HhcNMTkwODEzMDAwMDAwWhcNMjIwODEyMjM1OTU5WjCBmTELMAkGA1UEBhMCVVMx
# DjAMBgNVBBEMBTk3MjE5MQ8wDQYDVQQIDAZPcmVnb24xETAPBgNVBAcMCFBvcnRs
# YW5kMRwwGgYDVQQJDBMxNzEwIFNXIE1pbGl0YXJ5IFJkMRswGQYDVQQKDBJQS0kg
# U29sdXRpb25zIEluYy4xGzAZBgNVBAMMElBLSSBTb2x1dGlvbnMgSW5jLjCCAiIw
# DQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBANC9ao+Uw7Owaxi+v5FF1+eKGIpv
# QnKBFu61VsoHFyotJ8yoeC8tiRjmHggRbmQm0sTAdAXw23Rj5ZW6ndMWgA258car
# a6+oWB071e3ctsHoavc7NkDoCkKS2uh5tTmqclNMg6xaU1IIp9IWFq00K1jkeXex
# HIFLjTF2AA2SEteJO6VY08EiN6ktAOa1P4NbB0fTRUmca0j3W552hvU5Ig8G0DJt
# b4IDMMnu6WllNuxfqyNJiUOYkDET1p52XzvhMFMFnhbsH9JPcR4IA7Pp4xc1mRhe
# D9uE+KVx1astA/GvWtkpeZy/efbaMOxY4VuTW9kdgc8tB4VPamQQpoVmD3ULsaPz
# iv8cOum0CMrTtwKA/meas20A69u3xg8KeuDwxE0rysT4a68lXjFZViyHQQQzeZi4
# wAifk3URIABuKy6DQdQ4FJRjIvAXh5PD2WatY7aJJw9nc0biEB7bEjDNYufJ4OL9
# M9ibVqQxpLz0Vm9D+aCD1CJFySCcIOg7VRWCNyTqtDxDlWd6I7H1s2QwsiEWIOCE
# MtOlve+rZi9RgJhtrdoINgmgSPNH+lITexCMrNDvpEzYxggsTLcEs4jq6XzoD/bR
# G9gvSv/d5Di8Js0gjaqpwDZbLsProdRFX0AlAROarTVW0m9nqVHcP4o0Lc/jKCJ6
# 8073khO+aMOJKW/9AgMBAAGjggGoMIIBpDAfBgNVHSMEGDAWgBQO4TqoUzox1Yq+
# wbutZxoDha00DjAdBgNVHQ4EFgQUd9YCgc1i67qdUtY6jeRnT0YzsVAwDgYDVR0P
# AQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAwEwYDVR0lBAwwCgYIKwYBBQUHAwMwEQYJ
# YIZIAYb4QgEBBAQDAgQQMEAGA1UdIAQ5MDcwNQYMKwYBBAGyMQECAQMCMCUwIwYI
# KwYBBQUHAgEWF2h0dHBzOi8vc2VjdGlnby5jb20vQ1BTMEMGA1UdHwQ8MDowOKA2
# oDSGMmh0dHA6Ly9jcmwuc2VjdGlnby5jb20vU2VjdGlnb1JTQUNvZGVTaWduaW5n
# Q0EuY3JsMHMGCCsGAQUFBwEBBGcwZTA+BggrBgEFBQcwAoYyaHR0cDovL2NydC5z
# ZWN0aWdvLmNvbS9TZWN0aWdvUlNBQ29kZVNpZ25pbmdDQS5jcnQwIwYIKwYBBQUH
# MAGGF2h0dHA6Ly9vY3NwLnNlY3RpZ28uY29tMCAGA1UdEQQZMBeBFWluZm9AcGtp
# c29sdXRpb25zLmNvbTANBgkqhkiG9w0BAQsFAAOCAQEAa4IZBlHU1V6Dy+atjrwS
# YugL+ryvzR1eGH5+nzbwxAi4h3IaknQBIuWzoamR+hRUga9/Rd4jrBbXGTgkqM7A
# tnzXP7P5NZOmxOdFOl1UfgNIv5MfJNPzsvn54bnx9rgKWJlpmKPCr1xtfj2ERlhA
# f6ADOfUyCcTnSwlBi1Bai60wqqDPuj1zcDaD2XGddVmqVrplx1zNoX7vhyErA7V9
# psRWQYIflYY0L58gposEUVMKM6TJRRjndibRnO2CI9plXDBz4j3cTni3fXGM3UuB
# VInKSeC+mTsvJVYTHjBowWohhxMBdqD0xFVbysoRKGtWSJwErdAomjMCrY2q6oYc
# xzCCBmowggVSoAMCAQICEAMBmgI6/1ixa9bV6uYX8GYwDQYJKoZIhvcNAQEFBQAw
# YjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQ
# d3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgQXNzdXJlZCBJRCBD
# QS0xMB4XDTE0MTAyMjAwMDAwMFoXDTI0MTAyMjAwMDAwMFowRzELMAkGA1UEBhMC
# VVMxETAPBgNVBAoTCERpZ2lDZXJ0MSUwIwYDVQQDExxEaWdpQ2VydCBUaW1lc3Rh
# bXAgUmVzcG9uZGVyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAo2Rd
# /Hyz4II14OD2xirmSXU7zG7gU6mfH2RZ5nxrf2uMnVX4kuOe1VpjWwJJUNmDzm9m
# 7t3LhelfpfnUh3SIRDsZyeX1kZ/GFDmsJOqoSyyRicxeKPRktlC39RKzc5YKZ6O+
# YZ+u8/0SeHUOplsU/UUjjoZEVX0YhgWMVYd5SEb3yg6Np95OX+Koti1ZAmGIYXIY
# aLm4fO7m5zQvMXeBMB+7NgGN7yfj95rwTDFkjePr+hmHqH7P7IwMNlt6wXq4eMfJ
# Bi5GEMiN6ARg27xzdPpO2P6qQPGyznBGg+naQKFZOtkVCVeZVjCT88lhzNAIzGvs
# YkKRrALA76TwiRGPdwIDAQABo4IDNTCCAzEwDgYDVR0PAQH/BAQDAgeAMAwGA1Ud
# EwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwggG/BgNVHSAEggG2MIIB
# sjCCAaEGCWCGSAGG/WwHATCCAZIwKAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3LmRp
# Z2ljZXJ0LmNvbS9DUFMwggFkBggrBgEFBQcCAjCCAVYeggFSAEEAbgB5ACAAdQBz
# AGUAIABvAGYAIAB0AGgAaQBzACAAQwBlAHIAdABpAGYAaQBjAGEAdABlACAAYwBv
# AG4AcwB0AGkAdAB1AHQAZQBzACAAYQBjAGMAZQBwAHQAYQBuAGMAZQAgAG8AZgAg
# AHQAaABlACAARABpAGcAaQBDAGUAcgB0ACAAQwBQAC8AQwBQAFMAIABhAG4AZAAg
# AHQAaABlACAAUgBlAGwAeQBpAG4AZwAgAFAAYQByAHQAeQAgAEEAZwByAGUAZQBt
# AGUAbgB0ACAAdwBoAGkAYwBoACAAbABpAG0AaQB0ACAAbABpAGEAYgBpAGwAaQB0
# AHkAIABhAG4AZAAgAGEAcgBlACAAaQBuAGMAbwByAHAAbwByAGEAdABlAGQAIABo
# AGUAcgBlAGkAbgAgAGIAeQAgAHIAZQBmAGUAcgBlAG4AYwBlAC4wCwYJYIZIAYb9
# bAMVMB8GA1UdIwQYMBaAFBUAEisTmLKZB+0e36K+Vw0rZwLNMB0GA1UdDgQWBBRh
# Wk0ktkkynUoqeRqDS/QeicHKfTB9BgNVHR8EdjB0MDigNqA0hjJodHRwOi8vY3Js
# My5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURDQS0xLmNybDA4oDagNIYy
# aHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEQ0EtMS5j
# cmwwdwYIKwYBBQUHAQEEazBpMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdp
# Y2VydC5jb20wQQYIKwYBBQUHMAKGNWh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydEFzc3VyZWRJRENBLTEuY3J0MA0GCSqGSIb3DQEBBQUAA4IBAQCd
# JX4bM02yJoFcm4bOIyAPgIfliP//sdRqLDHtOhcZcRfNqRu8WhY5AJ3jbITkWkD7
# 3gYBjDf6m7GdJH7+IKRXrVu3mrBgJuppVyFdNC8fcbCDlBkFazWQEKB7l8f2P+fi
# EUGmvWLZ8Cc9OB0obzpSCfDscGLTYkuw4HOmksDTjjHYL+NtFxMG7uQDthSr849D
# p3GdId0UyhVdkkHa+Q+B0Zl0DSbEDn8btfWg8cZ3BigV6diT5VUW8LsKqxzbXEgn
# Zsijiwoc5ZXarsQuWaBh3drzbaJh6YoLbewSGL33VVRAA5Ira8JRwgpIr7DUbuD0
# FAo6G+OPPcqvao173NhEMIIGzTCCBbWgAwIBAgIQBv35A5YDreoACus/J7u6GzAN
# BgkqhkiG9w0BAQUFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQg
# SW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2Vy
# dCBBc3N1cmVkIElEIFJvb3QgQ0EwHhcNMDYxMTEwMDAwMDAwWhcNMjExMTEwMDAw
# MDAwWjBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBBc3N1cmVk
# IElEIENBLTEwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDogi2Z+crC
# QpWlgHNAcNKeVlRcqcTSQQaPyTP8TUWRXIGf7Syc+BZZ3561JBXCmLm0d0ncicQK
# 2q/LXmvtrbBxMevPOkAMRk2T7It6NggDqww0/hhJgv7HxzFIgHweog+SDlDJxofr
# Nj/YMMP/pvf7os1vcyP+rFYFkPAyIRaJxnCI+QWXfaPHQ90C6Ds97bFBo+0/vtuV
# SMTuHrPyvAwrmdDGXRJCgeGDboJzPyZLFJCuWWYKxI2+0s4Grq2Eb0iEm09AufFM
# 8q+Y+/bOQF1c9qjxL6/siSLyaxhlscFzrdfx2M8eCnRcQrhofrfVdwonVnwPYqQ/
# MhRglf0HBKIJAgMBAAGjggN6MIIDdjAOBgNVHQ8BAf8EBAMCAYYwOwYDVR0lBDQw
# MgYIKwYBBQUHAwEGCCsGAQUFBwMCBggrBgEFBQcDAwYIKwYBBQUHAwQGCCsGAQUF
# BwMIMIIB0gYDVR0gBIIByTCCAcUwggG0BgpghkgBhv1sAAEEMIIBpDA6BggrBgEF
# BQcCARYuaHR0cDovL3d3dy5kaWdpY2VydC5jb20vc3NsLWNwcy1yZXBvc2l0b3J5
# Lmh0bTCCAWQGCCsGAQUFBwICMIIBVh6CAVIAQQBuAHkAIAB1AHMAZQAgAG8AZgAg
# AHQAaABpAHMAIABDAGUAcgB0AGkAZgBpAGMAYQB0AGUAIABjAG8AbgBzAHQAaQB0
# AHUAdABlAHMAIABhAGMAYwBlAHAAdABhAG4AYwBlACAAbwBmACAAdABoAGUAIABE
# AGkAZwBpAEMAZQByAHQAIABDAFAALwBDAFAAUwAgAGEAbgBkACAAdABoAGUAIABS
# AGUAbAB5AGkAbgBnACAAUABhAHIAdAB5ACAAQQBnAHIAZQBlAG0AZQBuAHQAIAB3
# AGgAaQBjAGgAIABsAGkAbQBpAHQAIABsAGkAYQBiAGkAbABpAHQAeQAgAGEAbgBk
# ACAAYQByAGUAIABpAG4AYwBvAHIAcABvAHIAYQB0AGUAZAAgAGgAZQByAGUAaQBu
# ACAAYgB5ACAAcgBlAGYAZQByAGUAbgBjAGUALjALBglghkgBhv1sAxUwEgYDVR0T
# AQH/BAgwBgEB/wIBADB5BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6
# Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2VydHMu
# ZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDCBgQYDVR0f
# BHoweDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNz
# dXJlZElEUm9vdENBLmNybDA6oDigNoY0aHR0cDovL2NybDQuZGlnaWNlcnQuY29t
# L0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDAdBgNVHQ4EFgQUFQASKxOYspkH
# 7R7for5XDStnAs0wHwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8wDQYJ
# KoZIhvcNAQEFBQADggEBAEZQPsm3KCSnOB22WymvUs9S6TFHq1Zce9UNC0Gz7+x1
# H3Q48rJcYaKclcNQ5IK5I9G6OoZyrTh4rHVdFxc0ckeFlFbR67s2hHfMJKXzBBlV
# qefj56tizfuLLZDCwNK1lL1eT7EF0g49GqkUW6aGMWKoqDPkmzmnxPXOHXh2lCVz
# 5Cqrz5x2S+1fwksW5EtwTACJHvzFebxMElf+X+EevAJdqP77BzhPDcZdkbkPZ0XN
# 1oPt55INjbFpjE/7WeAjD9KqrgB87pxCDs+R1ye3Fu4Pw718CqDuLAhVhSK46xga
# TfwqIa1JMYNHlXdx3LEbS0scEJx3FMGdTy9alQgpECYxggVWMIIFUgIBATCBkDB8
# MQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYD
# VQQHEwdTYWxmb3JkMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxJDAiBgNVBAMT
# G1NlY3RpZ28gUlNBIENvZGUgU2lnbmluZyBDQQIQF0FLo4fb8T/ESzcF/lyStzAN
# BglghkgBZQMEAgEFAKCBhDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqG
# SIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3
# AgEVMC8GCSqGSIb3DQEJBDEiBCA63cuPOq4qhiGqn3stsxzHBnWw2b2Mc2um2b/L
# sDm76TANBgkqhkiG9w0BAQEFAASCAgBvpeZgLCURMeK25TC2UibNQqRPLLyXNosm
# NOPyZRZmD+5xp8S+JX003xtfhhwzhoiOND/iI8UpkfS0MoZJllZgCV19H7cqTe8G
# n5PaR69GlzUaazNHMa2mzMH3jaLVLQWcqx4k+Gpevof+StKdGci4uTo/mTpsh7WU
# BtXB38evuRdbrjmETZRx+pCZx+2yKxEipSSquv4BFfqX5h1w/Ds7+lRfMhQtAU/8
# wYKXy1mLA0HMj6kN08/wIEKgIB0tFN8WyvbKsumYWbXxfge+PszvnjK/Fj6eHhmK
# 4nY8O2JYRmkKuJlTa6acSG8KjW/J1volaH7EdfjiK5Q9X4Fb1Zpw0oi1j5KmZq0P
# wKi+KSowkOYQ5lDSIf5wIoyg0tcitq6Ykak092zgRk7nSEZwOFWkYWUVXfeSPkmj
# hzrF6zh2hfS7Qn130Fx0GAjv3S2Ek5NYrdSMLS9lSsfviKv1wb1shwvedbjUQpoh
# ly4Go49pdd6eJZcFszXNI4hTp00znlfgGfbsftMVF4oIgm3LpCF4B1Y6hGngd57B
# vsbgq394NbaaRbJaln154tPrRvLRt7zhU0XTSMjMK/euQlbrfsxrzrAAF8OrFkbs
# XgiZpRykkT5ncUa0i+yA1/dIUUMtTl8flUGOfqeItiNCmpcAC4cUJXtwQ9ITdJ6y
# +xad2r/qtKGCAg8wggILBgkqhkiG9w0BCQYxggH8MIIB+AIBATB2MGIxCzAJBgNV
# BAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdp
# Y2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IEFzc3VyZWQgSUQgQ0EtMQIQAwGa
# Ajr/WLFr1tXq5hfwZjAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3
# DQEHATAcBgkqhkiG9w0BCQUxDxcNMjAwODAzMTUyNjMwWjAjBgkqhkiG9w0BCQQx
# FgQURzS7eSl2kYcVWfZrUZKhHt95878wDQYJKoZIhvcNAQEBBQAEggEAGRg99JxW
# GoUIN+YN2DQCRBg4MEzol6UZWkuEwLNfxBd8V+zLJd5ng+kFRKDzqZJVtWiiQgrI
# 5o8XzfbbpHIARYNXjgHSisSP9sW4vOiYJJuOllddbjOUGk6vTeTGhxhxISKKZLV8
# wQ+DVo24McIGqGMAbALMzIXTWDHBo4LNIWvaxfPK+Vxs4ov5h4qaY60DJcJMtwEI
# HZYA1aUL82RfUhu1kv12RX3xjJhGVjpeOci6jOSGhXyNuAdcEymCrx9jgMeGupgF
# LT8+RzwZbZ+55e+qN7eEVxry8A9rHnwxocAdlUFI0hOpwtWZkXk5g8E2CMF4zXaP
# T8eHAtLQtXCoRA==
# SIG # End signature block
