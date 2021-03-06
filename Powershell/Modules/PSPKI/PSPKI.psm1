#region assembly import
Add-Type -Path $PSScriptRoot\Library\SysadminsLV.Asn1Parser.dll -ErrorAction Stop
Add-Type -Path $PSScriptRoot\Library\SysadminsLV.PKI.dll -ErrorAction Stop
Add-Type -AssemblyName System.Security -ErrorAction Stop
#endregion

#region global variable section
[Version]$OSVersion = [Environment]::OSVersion.Version
[bool]$PsIsCore = if ($PSVersionTable.PSEdition -like "*core*") {$true} else {$false}
# compatibility
[bool]$NoDomain = $true # computer is a member of workgroup
try {
    $Domain = ([ADSI]"LDAP://RootDSE").ConfigurationNamingContext
    $PkiConfigContext = "CN=Public Key Services,CN=Services,$Domain"
    $NoDomain = $false
} catch {$NoDomain = $true}

[bool]$NoCAPI = $true   # CertAdm.dll server managemend library is missing
if (Test-Path $PSScriptRoot\Server) {
    try {
        $CertAdmin = New-Object -ComObject CertificateAuthority.Admin
        $NoCAPI = $false
    } catch {$NoCAPI = $true}
}
[bool]$NoCAPIv2 = $true # referring to enrollment web services support
$NoCAPIv2 = if (
        $OSVersion.Major -lt 6 -or
        ($OSVersion.Major -eq 6 -and
        $OSVersion.Minor -lt 1)
    ) {$true} else {$false}


$RegPath = "System\CurrentControlSet\Services\CertSvc\Configuration"
# os version map
$Win2003    = if ($OSVersion.Major -lt 6) {$true} else {$false}
$Win2008    = if ($OSVersion.Major -eq 6 -and $OSVersion.Minor -eq 0) {$true} else {$false}
$Win2008R2  = if ($OSVersion.Major -eq 6 -and $OSVersion.Minor -eq 1) {$true} else {$false}
$Win2012    = if ($OSVersion.Major -eq 6 -and $OSVersion.Minor -eq 2) {$true} else {$false}
$Win2012R2  = if ($OSVersion.Major -eq 6 -and $OSVersion.Minor -eq 3) {$true} else {$false}
$Win2016    = if ($OSVersion.Major -eq 10 -and $OSVersion.Minor -eq 0) {$true} else {$false}
# warning messages
$RestartRequired = @"
New {0} are set, but will not be applied until Certification Authority service is restarted.
In future consider to use '-RestartCA' switch for this cmdlet to restart Certification Authority service immediatelly when new settings are set.

See more: Start-CertificationAuthority, Stop-CertificationAuthority and Restart-CertificationAuthority cmdlets.
"@
$NothingIsSet = @"
Input object was not modified since it was created. Nothing is written to the CA configuration.
"@
#endregion

#region helper functions
function Ping-ICertAdmin ($ConfigString) {
    $success = $true
    try {
        $CertAdmin = New-Object -ComObject CertificateAuthority.Admin
        $var = $CertAdmin.GetCAProperty($ConfigString,0x6,0,4,0)
    } catch {$success = $false}
    $success
}

function Write-ErrorMessage {
    param (
        [PKI.Utils.PSErrorSourceEnum]$Source,
        $ComputerName,
        $ExtendedInformation
    )
$DCUnavailable = @"
"Active Directory domain could not be contacted.
"@
$CAPIUnavailable = @"
Unable to locate required assemblies. This can be caused if attempted to run this module on a client machine where AdminPack/RSAT (Remote Server Administration Tools) are not installed.
"@
$WmiUnavailable = @"
Unable to connect to CA server '$ComputerName'. Make sure if Remote Registry service is running and you have appropriate permissions to access it.
Also this error may indicate that Windows Remote Management protocol exception is not enabled in firewall.
"@
$XchgUnavailable = @"
Unable to retrieve any 'CA Exchange' certificates from '$ComputerName'. This error may indicate that target CA server do not support key archival. All requests which require key archival will immediately fail.
"@
    switch ($source) {
        DCUnavailable {
            Write-Error -Category ObjectNotFound -ErrorId "ObjectNotFoundException" `
            -Message $DCUnavailable
        }
        CAPIUnavailable {
            Write-Error -Category NotImplemented -ErrorId "NotImplementedException" `
            -Message $NoCAPI; exit
        }
        CAUnavailable {
            Write-Error -Category ResourceUnavailable -ErrorId ResourceUnavailableException `
            -Message "Certificate Services are either stopped or unavailable on '$ComputerName'."
        }
        WmiUnavailable {
            Write-Error -Category ResourceUnavailable -ErrorId ResourceUnavailableException `
            -Message $WmiUnavailable
        }
        WmiWriteError {
            try {$text = Get-ErrorMessage $ExtendedInformation}
            catch {$text = "Unknown error '$code'"}
            Write-Error -Category NotSpecified -ErrorId NotSpecifiedException `
            -Message "An error occured during CA configuration update: $text"
        }
        ADKRAUnavailable {
            Write-Error -Category ObjectNotFound -ErrorId "ObjectNotFoundException" `
            -Message "No KRA certificates found in Active Directory."
        }
        ICertAdminUnavailable {
            Write-Error -Category ResourceUnavailable -ErrorId ResourceUnavailableException `
            -Message "Unable to connect to management interfaces on '$ComputerName'"
        }
        NoXchg {
            Write-Error -Category ObjectNotFound -ErrorId ObjectNotFoundException `
            -Message $XchgUnavailable
        }
        NonEnterprise {
            Write-Error -Category NotImplemented -ErrorAction NotImplementedException `
            -Message "Specified Certification Authority type is not supported. The CA type must be either 'Enterprise Root CA' or 'Enterprise Standalone CA'."
        }
    }
}
#endregion

#region module installation stuff
# dot-source all function files
Get-ChildItem -Path $PSScriptRoot -Include *.ps1 -Recurse | Foreach-Object { . $_.FullName }
$aliases = @()
if ($Win2008R2 -and (Test-Path $PSScriptRoot\Server)) {
    New-Alias -Name Add-CEP                 -Value Add-CertificateEnrollmentPolicyService -Force
    New-Alias -Name Add-CES                 -Value Add-CertificateEnrollmentService -Force
    New-Alias -Name Remove-CEP              -Value Remove-CertificateEnrollmentPolicyService -Force
    New-Alias -Name Remove-CES              -Value Remove-CertificateEnrollmentService -Force
    New-Alias -Name Get-DatabaseRow         -Value Get-AdcsDatabaseRow -Force
    $aliases += "Add-CEP", "Add-CES", "Remove-CEP", "Remove-CES", "Get-DatabaseRow"
}
if (($Win2008 -or $Win2008R2) -and (Test-Path $PSScriptRoot\Server)) {
    New-Alias -Name Install-CA                  -Value Install-CertificationAuthority -Force
    New-Alias -Name Uninstall-CA                -Value Uninstall-CertificationAuthority -Force
    $aliases += "Install-CA", "Uninstall-CA"
}
if (!$NoDomain) {
    New-Alias -Name Add-AdCrl                   -Value Add-AdCertificateRevocationList -Force
    New-Alias -Name Remove-AdCrl                -Value Add-AdCertificateRevocationList -Force
    $aliases += "Add-AdCrl ", "Remove-AdCrl"
}
if (!$NoDomain -and (Test-Path $PSScriptRoot\Server)) {
    New-Alias -Name Get-CA                      -Value Get-CertificationAuthority -Force
    New-Alias -Name Get-KRAFlag                 -Value Get-KeyRecoveryAgentFlag -Force
    New-Alias -Name Enable-KRAFlag              -Value Enable-KeyRecoveryAgentFlag -Force
    New-Alias -Name Disable-KRAFlag             -Value Disable-KeyRecoveryAgentFlag -Force
    New-Alias -Name Restore-KRAFlagDefault      -Value Restore-KeyRecoveryAgentFlagDefault -Force

    $aliases += "Get-CA", "Get-KRAFlag", "Enable-KRAFlag", "Disable-KRAFlag", "Restore-KRAFlagDefault"
}
if (Test-Path $PSScriptRoot\Server) {
    New-Alias -Name Connect-CA                  -Value Connect-CertificationAuthority -Force
    
    New-Alias -Name Add-AIA                     -Value Add-AuthorityInformationAccess -Force
    New-Alias -Name Get-AIA                     -Value Get-AuthorityInformationAccess -Force
    New-Alias -Name Remove-AIA                  -Value Remove-AuthorityInformationAccess -Force
    New-Alias -Name Set-AIA                     -Value Set-AuthorityInformationAccess -Force

    New-Alias -Name Add-CDP                     -Value Add-CRLDistributionPoint -Force
    New-Alias -Name Get-CDP                     -Value Get-CRLDistributionPoint -Force
    New-Alias -Name Remove-CDP                  -Value Remove-CRLDistributionPoint -Force
    New-Alias -Name Set-CDP                     -Value Set-CRLDistributionPoint -Force
    
    New-Alias -Name Get-CRLFlag                 -Value Get-CertificateRevocationListFlag -Force
    New-Alias -Name Enable-CRLFlag              -Value Enable-CertificateRevocationListFlag -Force
    New-Alias -Name Disable-CRLFlag             -Value Disable-CertificateRevocationListFlag -Force
    New-Alias -Name Restore-CRLFlagDefault      -Value Restore-CertificateRevocationListFlagDefault -Force
    
    New-Alias -Name Remove-Request              -Value Remove-AdcsDatabaseRow -Force
    
    New-Alias -Name Get-CAACL                   -Value Get-CertificationAuthorityAcl -Force
    New-Alias -Name Add-CAACL                   -Value Add-CertificationAuthorityAcl -Force
    New-Alias -Name Remove-CAACL                -Value Remove-CertificationAuthorityAcl -Force
    New-Alias -Name Set-CAACL                   -Value Set-CertificationAuthorityAcl -Force

    New-Alias -Name Get-OCSPACL                 -Value Get-OnlineResponderAcl -Force
    New-Alias -Name Add-OCSPACL                 -Value Add-OnlineResponderAcl -Force
    New-Alias -Name Remove-OCSPACL              -Value Remove-OnlineResponderAcl -Force
    New-Alias -Name Set-OCSPACL                 -Value Set-OnlineResponderAcl -Force

    # compat/rename aliases
    New-Alias -Name Get-CASecurityDescriptor    -Value Get-CertificationAuthorityAcl -Force
    New-Alias -Name Set-CASecurityDescriptor    -Value Set-CertificationAuthorityAcl -Force
    New-Alias -Name Add-CAAccessControlEntry    -Value Add-CertificationAuthorityAcl -Force
    New-Alias -Name Remove-CAAccessControlEntry -Value Remove-CertificationAuthorityAcl -Force

    $aliases += "Connect-CA", "Add-AIA", "Get-AIA", "Remove-AIA", "Set-AIA", "Add-CDP", "Get-CDP", "Remove-CDP",
        "Set-CDP", "Get-CRLFlag", "Enable-CRLFlag", "Disable-CRLFlag", "Restore-CRLFlagDefault",
        "Remove-Request", "Get-CAACL", "Add-CAACL", "Remove-CAACL", "Set-CAACL",
        "Get-CASecurityDescriptor", "Set-CASecurityDescriptor", "Add-CAAccessControlEntry", "Remove-CAAccessControlEntry",
        "Get-OCSPACL", "Add-OCSPACL", "Remove-OCSPACL", "Set-OCSPACL"
}

if (Test-Path $PSScriptRoot\Client) {
    New-Alias -Name "oid"                       -Value Get-ObjectIdentifier -Force
    New-Alias -Name oid2                        -Value Get-ObjectIdentifierEx -Force

    New-Alias -Name Get-Csp                     -Value Get-CryptographicServiceProvider -Force

    New-Alias -Name Get-CRL                     -Value Get-CertificateRevocationList -Force
    New-Alias -Name Show-CRL                    -Value Show-CertificateRevocationList -Force
    New-Alias -Name Get-CTL                     -Value Get-CertificateTrustList -Force
    New-Alias -Name Show-CTL                    -Value Show-CertificateTrustList -Force
    $aliases += "oid", "oid2", "Get-CSP", "Get-CRL", "Show-CRL", "Get-CTL", "Show-CTL"
}

# define restricted functions
$RestrictedFunctions =      "Get-RequestRow",
                            "Ping-ICertAdmin",
                            "Write-ErrorMessage"
$NoDomainExcludeFunctions = "Get-AdPkicontainer",
                            "Add-AdCertificate",
                            "Remove-AdCertificate",
                            "Add-AdCertificateRevocationList",
                            "Remove-AdCertificateRevocationList",
                            "Add-CAKRACertificate",
                            "Add-CATemplate",
                            "Add-CertificateEnrollmentPolicyService",
                            "Add-CertificateEnrollmentService",
                            "Add-CertificateTemplateAcl",
                            "Disable-KeyRecoveryAgentFlag",
                            "Enable-KeyRecoveryAgentFlag",
                            "Get-ADKRACertificate",
                            "Get-CAExchangeCertificate",
                            "Get-CAKRACertificate",
                            "Get-CATemplate",
                            "Get-CertificateTemplate",
                            "Get-CertificateTemplateAcl",
                            "Get-EnrollmentServiceUri",
                            "Get-KeyRecoveryAgentFlag",
                            "Remove-CAKRACertificate",
                            "Remove-CATemplate",
                            "Remove-CertificateTemplate",
                            "Remove-CertificateTemplateAcl",
                            "Restore-KeyRecoveryAgentFlagDefault",
                            "Set-CAKRACertificate",
                            "Set-CATemplate",
                            "Set-CertificateTemplateAcl",
                            "Get-CertificationAuthority"
$Win2003ExcludeFunctions =  "Add-CertificateEnrollmentPolicyService",
                            "Add-CertificateEnrollmentService",
                            "Install-CertificationAuthority",
                            "Remove-CertificateEnrollmentPolicyService",
                            "Remove-CertificateEnrollmentService",
                            "Uninstall-CertificationAuthority"  
$Win2008ExcludeFunctions =  "Add-CertificateEnrollmentPolicyService",
                            "Add-CertificateEnrollmentService",
                            "Remove-CertificateEnrollmentPolicyService",
                            "Remove-CertificateEnrollmentService"
$Win2012ExcludeFunctions =  "Install-CertificationAuthority",
                            "Uninstall-CertificationAuthority",
                            "Add-CertificateEnrollmentPolicyService",
                            "Add-CertificateEnrollmentService",
                            "Remove-CertificateEnrollmentPolicyService",
                            "Remove-CertificateEnrollmentService"

if ($Win2003) {$RestrictedFunctions += $Win2003ExcludeFunctions}
if ($Win2008) {$RestrictedFunctions += $Win2008ExcludeFunctions}
if ($Win2012) {$RestrictedFunctions += $Win2012ExcludeFunctions}
if ($Win2012R2) {$RestrictedFunctions += $Win2012ExcludeFunctions}
if ($Win2016) {$RestrictedFunctions += $Win2012ExcludeFunctions}
if ($NoDomain) {$RestrictedFunctions += $NoDomainExcludeFunctions}
# do not export any function from Server folder when RSAT is not installed.
# only client components are exported
if ($NoCAPI) {
    $RestrictedFunctions += Get-ChildItem $PSScriptRoot\Server -Filter "*.ps1" | ForEach-Object {$_.BaseName}
    Write-Warning @"
Active Directory Certificate Services remote administration tools (RSAT) are not installed and only
client-side functionality will be available.
"@
}
# export module members
Export-ModuleMember –Function @(
    Get-ChildItem $PSScriptRoot -Include *.ps1 -Recurse | `
        ForEach-Object {$_.Name -replace ".ps1"} | `
        Where-Object {$RestrictedFunctions -notcontains $_}
)
Export-ModuleMember -Alias $aliases
#endregion
# conditional type data
if ($PSVersionTable.PSVersion.Major -ge 5) {
    Update-TypeData -AppendPath $PSScriptRoot\Types\PSPKI.PS5Types.ps1xml
}
# SIG # Begin signature block
# MIIfhgYJKoZIhvcNAQcCoIIfdzCCH3MCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDNxSBRgAtVD+AD
# pb2XTSQV4q5tOJ8ZLcw9blNIv8sU36CCGYYwggX1MIID3aADAgECAhAdokgwb5sm
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
# AgEVMC8GCSqGSIb3DQEJBDEiBCBUM2Fw3oJ8m/BRsiqdIIsk3JxNLnEMM4j0O1og
# gB9BezANBgkqhkiG9w0BAQEFAASCAgBapwBmek7VVd78WJLHyTLi3J3bZApD15Y0
# AXwRYhw9DvKhj4F1pQbJJc7n2SktH7X28CQ5gHdGZz2+jA8SInPJyruyMVUfkESD
# K2uKTSRdaZNBeynYj4OoZqVQLXntyZmtroWUqFK1KpBS73ALOdEDUsZbbojGRoxo
# ncXYk+Z69hKUPIUwUx/2sDwM0OP/uRZdI5E7lpfzzlpwEwZTX/Tgeou8yXoZMFM4
# w2e1L0L/uzJwl4EcnEoN5mS62mNjgh9AtBRmAta2pdXzhZJLOrgKJKk7wvpJRP0U
# PNN97W8f3uRkCuYY3dM9F8kdhRbQoXChOXSrld6cXRuWwNp6i1txj7HfKZTisy9S
# DyG2YtzZrRWSThhFgQamn5TzQCVv6u0T8GIZf4Iwr9HTqyxkXXTm+kcbuZ8rsI4W
# BQ59qfRhwtsmhetr+zkgW5yObtnx3Dk1Z6/O1qKPf2djyG6esXS2BqoOhJx7m3d5
# dDyDeq640is0fPY2QHGm9eTVR9rS22Z1AGUGvsVaqM0322JkX/9U00QBZ7lgRTBp
# R4+NF4Y4VBPVHFxtYC9mJx5gPRHSrOwJY9G20VsKIpJ541zCsmsPmy9ev/PE8APy
# /+RJVw0bSLLZU/SqWg9r9FRL1vlmou3UrSwebnLiDjW3fYfeFazyr+g20dZMlcj8
# ShqPHsACL6GCAg8wggILBgkqhkiG9w0BCQYxggH8MIIB+AIBATB2MGIxCzAJBgNV
# BAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdp
# Y2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IEFzc3VyZWQgSUQgQ0EtMQIQAwGa
# Ajr/WLFr1tXq5hfwZjAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3
# DQEHATAcBgkqhkiG9w0BCQUxDxcNMjAwODAzMTUyNjM3WjAjBgkqhkiG9w0BCQQx
# FgQUQl/OwlWF8P+FG8MVzkH9kxKW2cEwDQYJKoZIhvcNAQEBBQAEggEASAmpTN5W
# OgAT978cQv+12uiCLt4gVRrUlB9gp1qSoU0PK/5xylJ3YdzXXQVUuBWSeKApA4fq
# rinltA3LBy8oe4oTuSviZ3Wwyi0O7Ef7Yc5LadE6ozTGJPJlYpM4feTf0ekwjZmi
# fBiWk71uapShsUZlTNNaZyCtFLMNgTQ9q+whvpMsO5dbZD511YD48sx4mVtmEstf
# Y+SxGhMky71dwzOkd+qpXibNZmYiD7GyyJyICvGmSwzwbPLolqhZsXaNgdn9wwHH
# QeR5kC+jQQwSVB/9Saj8eg7PJYf9+f1juBraKhjFBXsfZV+DbppIiK3HZikRAp+8
# d1NlU/tRE6x+AQ==
# SIG # End signature block
