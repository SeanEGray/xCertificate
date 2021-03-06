[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:DSCModuleName      = 'xCertificate'
$script:DSCResourceName    = 'MSFT_xCertReq'

#region HEADER
# Integration Test Template Version: 1.1.0
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit
#endregion

# Begin Testing
try
{
    InModuleScope $script:DSCResourceName {
        $DSCResourceName = 'MSFT_xCertReq'
        function Get-InvalidOperationError
        {
            [CmdletBinding()]
            param
            (
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $ErrorId,

                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $ErrorMessage
            )

            $exception = New-Object -TypeName System.InvalidOperationException `
                -ArgumentList $ErrorMessage
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
            $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                -ArgumentList $exception, $ErrorId, $errorCategory, $null
            return $errorRecord
        } # end function Get-InvalidOperationError

        function Get-InvalidArgumentError
        {
            [CmdletBinding()]
            param
            (
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $ErrorId,

                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $ErrorMessage
            )

            $exception = New-Object -TypeName System.ArgumentException `
                -ArgumentList $ErrorMessage
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
            $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                -ArgumentList $exception, $ErrorId, $errorCategory, $null
            return $errorRecord
        } # end function Get-InvalidArgumentError

        $validThumbprint = (
            [System.AppDomain]::CurrentDomain.GetAssemblies().GetTypes() | Where-Object {
                $_.BaseType.BaseType -eq [System.Security.Cryptography.HashAlgorithm] -and
                ($_.Name -cmatch 'Managed$' -or $_.Name -cmatch 'Provider$')
            } | Select-Object -First 1 | ForEach-Object {
                (New-Object $_).ComputeHash([String]::Empty) | ForEach-Object {
                    '{0:x2}' -f $_
                }
            }
        ) -join ''
        $CAServerFQDN          = 'rootca.contoso.com'
        $CARootName            = 'contoso-CA'
        $validSubject          = 'Test Subject'
        $validIssuer           = "CN=$CARootName, DC=contoso, DC=com"
        $KeyLength             = '1024'
        $Exportable            = $true
        $ProviderName          = '"Microsoft RSA SChannel Cryptographic Provider"'
        $OID                   = '1.3.6.1.5.5.7.3.1'
        $KeyUsage              = '0xa0'
        $CertificateTemplate   = 'WebServer'
        $SubjectAltUrl         = 'contoso.com'
        $SubjectAltName        = "dns=$SubjectAltUrl"

        $validCert      = New-Object -TypeName PSObject -Property @{
            Thumbprint  = $validThumbprint
            Subject     = "CN=$validSubject"
            Issuer      = $validIssuer
            NotBefore   = (Get-Date).AddDays(-30) # Issued on
            NotAfter    = (Get-Date).AddDays(31) # Expires after
        }
        Add-Member -InputObject $validCert -MemberType ScriptMethod -Name Verify -Value {
            return $true
        }
        $expiringCert   = New-Object -TypeName PSObject -Property @{
            Thumbprint  = $validThumbprint
            Subject     = "CN=$validSubject"
            Issuer      = $validIssuer
            NotBefore   = (Get-Date).AddDays(-30) # Issued on
            NotAfter    = (Get-Date).AddDays(30) # Expires after
        }
        Add-Member -InputObject $expiringCert -MemberType ScriptMethod -Name Verify -Value {
            return $true
        }
        $expiredCert    = New-Object -TypeName PSObject -Property @{
            Thumbprint  = $validThumbprint
            Subject     = "CN=$validSubject"
            Issuer      = $validIssuer
            NotBefore   = (Get-Date).AddDays(-30) # Issued on
            NotAfter    = (Get-Date).AddDays(-1) # Expires after
        }
        Add-Member -InputObject $expiredCert -MemberType ScriptMethod -Name Verify -Value {
            return $true
        }
        $sanOid = New-Object -TypeName System.Security.Cryptography.Oid -Property @{FriendlyName = 'Subject Alternative Name'}
        $sanExt = @{
            oid = $(,$sanOid)    
            Critical = $false
        }
        Add-Member -InputObject $sanExt -MemberType ScriptMethod -Name Format -Force -Value {
            return "DNS Name=$SubjectAltUrl"
        }
        $validSANCert      = New-Object -TypeName PSObject -Property @{
            Thumbprint     = $validThumbprint
            Subject        = "CN=$validSubject"
            Issuer         = $validIssuer
            NotBefore      = (Get-Date).AddDays(-30) # Issued on
            NotAfter       = (Get-Date).AddDays(31) # Expires after
            Extensions     = $sanExt
        }
        Add-Member -InputObject $validSANCert -MemberType ScriptMethod -Name Verify -Value {
            return $true
        }
        $incorrectSanExt = @{
            oid = $(,$sanOid)    
            Critical = $false
        }
        Add-Member -InputObject $incorrectSanExt -MemberType ScriptMethod -Name Format -Force -Value {
            return "DNS Name=incorrect.com"
        }
        $incorrectSANCert  = New-Object -TypeName PSObject -Property @{
            Thumbprint     = $validThumbprint
            Subject        = "CN=$validSubject"
            Issuer         = $validIssuer
            NotBefore      = (Get-Date).AddDays(-30) # Issued on
            NotAfter       = (Get-Date).AddDays(31) # Expires after
            Extensions     = $incorrectSanExt
        }
        Add-Member -InputObject $incorrectSANCert -MemberType ScriptMethod -Name Verify -Value {
            return $true
        }
        $emptySANCert      = New-Object -TypeName PSObject -Property @{
            Thumbprint     = $validThumbprint
            Subject        = "CN=$validSubject"
            Issuer         = $validIssuer
            NotBefore      = (Get-Date).AddDays(-30) # Issued on
            NotAfter       = (Get-Date).AddDays(31) # Expires after
            Extensions     = @()
        }
        Add-Member -InputObject $emptySANCert -MemberType ScriptMethod -Name Verify -Value {
            return $true
        }

        $CAType         = 'Enterprise'
        $CepURL         = 'DummyURL'
        $CesURL         = 'DummyURL'

        $testUsername   = 'DummyUsername'
        $testPassword   = 'DummyPassword'
        $testCredential = New-Object System.Management.Automation.PSCredential $testUsername, (ConvertTo-SecureString $testPassword -AsPlainText -Force)
        $Params = @{
            Subject               = $validSubject
            CAServerFQDN          = $CAServerFQDN
            CARootName            = $CARootName
            KeyLength             = $KeyLength
            Exportable            = $Exportable
            ProviderName          = $ProviderName
            OID                   = $OID
            KeyUsage              = $KeyUsage
            CertificateTemplate   = $CertificateTemplate
            Credential            = $testCredential
            AutoRenew             = $False
        }
        $ParamsAutoDiscovery = @{
            Subject               = $validSubject
            KeyLength             = $KeyLength
            Exportable            = $Exportable
            ProviderName          = $ProviderName
            OID                   = $OID
            KeyUsage              = $KeyUsage
            CertificateTemplate   = $CertificateTemplate
            Credential            = $testCredential
            AutoRenew             = $False
        }
        $ParamsAutoRenew = @{
            Subject               = $validSubject
            CAServerFQDN          = $CAServerFQDN
            CARootName            = $CARootName
            KeyLength             = $KeyLength
            Exportable            = $Exportable
            ProviderName          = $ProviderName
            OID                   = $OID
            KeyUsage              = $KeyUsage
            CertificateTemplate   = $CertificateTemplate
            Credential            = $testCredential
            AutoRenew             = $True
        }
        $ParamsNoCred = @{
            Subject               = $validSubject
            CAServerFQDN          = $CAServerFQDN
            CARootName            = $CARootName
            KeyLength             = $KeyLength
            Exportable            = $Exportable
            ProviderName          = $ProviderName
            OID                   = $OID
            KeyUsage              = $KeyUsage
            CertificateTemplate   = $CertificateTemplate
            Credential            = $null
            AutoRenew             = $False
        }
        $ParamsAutoRenewNoCred = @{
            Subject               = $validSubject
            CAServerFQDN          = $CAServerFQDN
            CARootName            = $CARootName
            KeyLength             = $KeyLength
            Exportable            = $Exportable
            ProviderName          = $ProviderName
            OID                   = $OID
            KeyUsage              = $KeyUsage
            CertificateTemplate   = $CertificateTemplate
            Credential            = $null
            AutoRenew             = $True
        }
        $ParamsKeyLength4096NoCred = @{
            Subject               = $validSubject
            CAServerFQDN          = $CAServerFQDN
            CARootName            = $CARootName
            KeyLength             = '4096'
            Exportable            = $Exportable
            ProviderName          = $ProviderName
            OID                   = $OID
            KeyUsage              = $KeyUsage
            CertificateTemplate   = $CertificateTemplate
            Credential            = $null
            AutoRenew             = $False
        }
        $ParamsKeyLength4096AutoRenewNoCred = @{
            Subject               = $validSubject
            CAServerFQDN          = $CAServerFQDN
            CARootName            = $CARootName
            KeyLength             = '4096'
            Exportable            = $Exportable
            ProviderName          = $ProviderName
            OID                   = $OID
            KeyUsage              = $KeyUsage
            CertificateTemplate   = $CertificateTemplate
            Credential            = $null
            AutoRenew             = $True
        }
        $ParamsSubjectAltName = @{
            Subject               = $validSubject
            CAServerFQDN          = $CAServerFQDN
            CARootName            = $CARootName
            KeyLength             = $KeyLength
            Exportable            = $Exportable
            ProviderName          = $ProviderName
            OID                   = $OID
            KeyUsage              = $KeyUsage
            CertificateTemplate   = $CertificateTemplate
            Credential            = $testCredential
            SubjectAltName        = $SubjectAltName
            AutoRenew             = $False
        }
        $ParamsSubjectAltNameNoCred = @{
            Subject               = $validSubject
            CAServerFQDN          = $CAServerFQDN
            CARootName            = $CARootName
            KeyLength             = $KeyLength
            Exportable            = $Exportable
            ProviderName          = $ProviderName
            OID                   = $OID
            KeyUsage              = $KeyUsage
            CertificateTemplate   = $CertificateTemplate
            Credential            = $null
            SubjectAltName        = $SubjectAltName
            AutoRenew             = $False
        }
        $ParamsStandaloneWebEnrollment = @{
            Subject               = $validSubject
            CAServerFQDN          = $CAServerFQDN
            CARootName            = $CARootName
            KeyLength             = $KeyLength
            Exportable            = $Exportable
            ProviderName          = $ProviderName
            OID                   = $OID
            KeyUsage              = $KeyUsage
            CertificateTemplate   = $CertificateTemplate
            Credential            = $testCredential
            AutoRenew             = $False
            CAType                = 'Standalone'
            CepURL                = $CepURL
            CesURL                = $CesURL
        }
        $ParamsEnterpriseWebEnrollment = @{
            Subject               = $validSubject
            CAServerFQDN          = $CAServerFQDN
            CARootName            = $CARootName
            KeyLength             = $KeyLength
            Exportable            = $Exportable
            ProviderName          = $ProviderName
            OID                   = $OID
            KeyUsage              = $KeyUsage
            CertificateTemplate   = $CertificateTemplate
            Credential            = $testCredential
            AutoRenew             = $False
            CAType                = $CAType
            CepURL                = $CepURL
            CesURL                = $CesURL
        }

        $CertInf = @"
[NewRequest]
Subject = "CN=$validSubject"
KeySpec = 1
KeyLength = $KeyLength
Exportable = $($Exportable.ToString().ToUpper())
MachineKeySet = TRUE
SMIME = FALSE
PrivateKeyArchive = FALSE
UserProtected = FALSE
UseExistingKeySet = FALSE
ProviderName = $ProviderName
ProviderType = 12
RequestType = CMC
KeyUsage = $KeyUsage
[RequestAttributes]
CertificateTemplate = $CertificateTemplate
[EnhancedKeyUsageExtension]
OID = $OID
"@

        $CertInfNoTemplate = $CertInf.Replace(@"
[RequestAttributes]
CertificateTemplate = $CertificateTemplate
[EnhancedKeyUsageExtension]
"@, '[EnhancedKeyUsageExtension]')
    

        $CertInfKey = $CertInf -Replace 'KeyLength = ([0-z]*)', 'KeyLength = 4096'
        $CertInfRenew = $Certinf
        $CertInfRenew += @"

RenewalCert = $validThumbprint
"@
        $CertInfKeyRenew = $CertInfRenew -Replace 'KeyLength = ([0-z]*)', 'KeyLength = 4096'
        $CertInfSubjectAltName = $Certinf
        $CertInfSubjectAltName += @"

[Extensions]
2.5.29.17 = "{text}$SubjectAltName"
"@

        Describe "$DSCResourceName\Get-TargetResource" {
            Mock Get-ChildItem -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' } `
                -Mockwith { $validCert }
            Mock Get-CertificateTemplateName -MockWith { $CertificateTemplate }
            Mock Get-CertificateSan -MockWith { $SubjectAltName }
            Mock -CommandName Find-CertificateAuthority -MockWith {
                    return New-Object -TypeName psobject -Property @{
                        CAServerFQDN = 'rootca.contoso.com'
                        CARootName = 'contoso-CA'
                    }
                }

            $result = Get-TargetResource @Params
            $resultAutoDiscovery = Get-TargetResource @ParamsAutoDiscovery
            It 'should return a hashtable' {
                ($result -is [hashtable]) | Should Be $true
            }
            It 'should contain the input values' {
                $result.Subject              | Should BeExactly $validSubject
                $result.CAServerFQDN         | Should BeNullOrEmpty
                $result.CARootName           | Should BeExactly $CARootName
                $result.KeyLength            | Should BeNullOrEmpty
                $result.Exportable           | Should BeNullOrEmpty
                $result.ProviderName         | Should BeNullOrEmpty
                $result.OID                  | Should BeNullOrEmpty
                $result.KeyUsage             | Should BeNullOrEmpty
                $result.CertificateTemplate  | Should BeExactly $CertificateTemplate
                $result.SubjectAltName       | Should BeNullOrEmpty
            }            
            It 'should return a hashtable' {
                ($resultAutoDiscovery -is [hashtable]) | Should Be $true
            }
            It 'should contain the input values and the CA should be auto-discovered' {
                $resultAutoDiscovery.Subject              | Should BeExactly $validSubject
                $resultAutoDiscovery.CAServerFQDN         | Should BeExactly $CAServerFQDN
                $resultAutoDiscovery.CARootName           | Should BeExactly $CARootName
                $resultAutoDiscovery.KeyLength            | Should BeNullOrEmpty
                $resultAutoDiscovery.Exportable           | Should BeNullOrEmpty
                $resultAutoDiscovery.ProviderName         | Should BeNullOrEmpty
                $resultAutoDiscovery.OID                  | Should BeNullOrEmpty
                $resultAutoDiscovery.KeyUsage             | Should BeNullOrEmpty
                $resultAutoDiscovery.CertificateTemplate  | Should BeExactly $CertificateTemplate
                $resultAutoDiscovery.SubjectAltName       | Should BeNullOrEmpty
            }
            It 'Should call the mocked function Find-CertificateAuthority once' {
                Assert-MockCalled -CommandName Find-CertificateAuthority -Exactly -Times 1
            }
        }
        #endregion

        #region Set-TargetResource
        Describe "$DSCResourceName\Set-TargetResource" {
            Mock -CommandName Join-Path -MockWith { 'xCertReq-Test' } `
                -ParameterFilter { $Path -eq $env:Temp }
            Mock -CommandName Test-Path -MockWith { $true } `
                -ParameterFilter { $Path -eq 'xCertReq-Test.req' }
            Mock -CommandName Test-Path -MockWith { $true } `
                -ParameterFilter { $Path -eq 'xCertReq-Test.cer' }
            Mock -CommandName CertReq.exe
            Mock -CommandName Set-Content `
                -ParameterFilter {
                    $Path -eq 'xCertReq-Test.inf' -and `
                    $Value -eq $CertInf
                }

            Context 'autorenew is false, credentials not passed' {
                Mock -CommandName Get-ChildItem -Mockwith { } `
                    -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' }

                It 'should not throw' {
                    { Set-TargetResource @ParamsNoCred } | Should Not Throw
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Join-Path -Exactly 1
                    Assert-MockCalled -CommandName Test-Path -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.req' }
                    Assert-MockCalled -CommandName Test-Path  -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.cer' }
                    Assert-MockCalled -CommandName Set-Content -Exactly 1 `
                        -ParameterFilter {
                            $Path -eq 'xCertReq-Test.inf' -and `
                            $Value -eq $CertInf
                        }
                    Assert-MockCalled -CommandName CertReq.exe -Exactly 3
                }
            }

            Context 'autorenew is true, credentials not passed and certificate does not exist' {
                Mock -CommandName Get-ChildItem -Mockwith { } `
                    -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' }

                It 'should not throw' {
                    { Set-TargetResource @ParamsAutoRenewNoCred } | Should Not Throw
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Join-Path -Exactly 1
                    Assert-MockCalled -CommandName Test-Path -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.req' }
                    Assert-MockCalled -CommandName Test-Path  -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.cer' }
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly 1 `
                        -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' }
                    Assert-MockCalled -CommandName Set-Content -Exactly 1 `
                        -ParameterFilter {
                            $Path -eq 'xCertReq-Test.inf' -and `
                            $Value -eq $CertInf
                        }
                    Assert-MockCalled -CommandName CertReq.exe -Exactly 3
                }
            }

            Context 'autorenew is true, credentials not passed and valid certificate exists' {
                Mock -CommandName Get-ChildItem -Mockwith { $validCert } `
                    -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' }

                It 'should not throw' {
                    { Set-TargetResource @ParamsAutoRenewNoCred } | Should Not Throw
                }
                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Join-Path -Exactly 1
                    Assert-MockCalled -CommandName Test-Path -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.req' }
                    Assert-MockCalled -CommandName Test-Path  -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.cer' }
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly 1 `
                        -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' }
                    Assert-MockCalled -CommandName Set-Content -Exactly 1 `
                        -ParameterFilter {
                            $Path -eq 'xCertReq-Test.inf' -and `
                            $Value -eq $CertInf
                        }
                    Assert-MockCalled -CommandName CertReq.exe -Exactly 3
                }
            }

            Mock -CommandName Set-Content `
                -ParameterFilter {
                    $Path -eq 'xCertReq-Test.inf' -and `
                    $Value -eq $CertInfRenew
                }
            Context 'autorenew is true, credentials not passed and expiring certificate exists' {
                Mock -CommandName Get-ChildItem -Mockwith { $expiringCert } `
                    -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' }

                It 'should not throw' {
                    { Set-TargetResource @ParamsAutoRenewNoCred } | Should Not Throw
                }
                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Join-Path -Exactly 1
                    Assert-MockCalled -CommandName Test-Path -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.req' }
                    Assert-MockCalled -CommandName Test-Path  -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.cer' }
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly 1 `
                        -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' }
                    Assert-MockCalled -CommandName Set-Content -Exactly 1 `
                        -ParameterFilter {
                            $Path -eq 'xCertReq-Test.inf' -and `
                            $Value -eq $CertInfRenew
                        }
                    Assert-MockCalled -CommandName CertReq.exe -Exactly 3
                }
            }

            Context 'autorenew is true, credentials not passed and expired certificate exists' {
                Mock -CommandName Get-ChildItem -Mockwith { $expiredCert } `
                    -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' }

                It 'should not throw' {
                    { Set-TargetResource @ParamsAutoRenewNoCred } | Should Not Throw
                }
                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Join-Path -Exactly 1
                    Assert-MockCalled -CommandName Test-Path -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.req' }
                    Assert-MockCalled -CommandName Test-Path  -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.cer' }
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly 1 `
                        -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' }
                    Assert-MockCalled -CommandName Set-Content -Exactly 1 `
                        -ParameterFilter {
                            $Path -eq 'xCertReq-Test.inf' -and `
                            $Value -eq $CertInfRenew
                        }
                    Assert-MockCalled -CommandName CertReq.exe -Exactly 3
                }
            }

            Mock -CommandName Set-Content `
                -ParameterFilter {
                    $Path -eq 'xCertReq-Test.inf' -and `
                    $Value -eq $CertInfKeyRenew
                }

            Context 'autorenew is true, credentials not passed, keylength passed and expired certificate exists' {
                Mock -CommandName Get-ChildItem -Mockwith { $expiredCert } `
                    -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' }

                It 'should not throw' {
                    { Set-TargetResource @ParamsKeyLength4096AutoRenewNoCred } | Should Not Throw
                }
                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Join-Path -Exactly 1
                    Assert-MockCalled -CommandName Test-Path -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.req' }
                    Assert-MockCalled -CommandName Test-Path  -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.cer' }
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly 1 `
                        -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' }
                    Assert-MockCalled -CommandName Set-Content -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.inf' }
                    Assert-MockCalled -CommandName CertReq.exe -Exactly 3
                    Assert-MockCalled -CommandName Set-Content -Exactly 1 `
                        -ParameterFilter {
                            $Path -eq 'xCertReq-Test.inf' -and `
                            $Value -eq $CertInfKeyRenew
                        }
                }
            }

            Mock -CommandName Test-Path -MockWith { $false } `
                -ParameterFilter { $Path -eq 'xCertReq-Test.req' }
            Mock -CommandName Set-Content `
                -ParameterFilter {
                    $Path -eq 'xCertReq-Test.inf' -and `
                    $Value -eq $CertInf
                }

            Context 'autorenew is false, credentials not passed, certificate request creation failed' {
                Mock -CommandName Get-ChildItem -Mockwith { } `
                    -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' }

                $errorRecord = Get-InvalidArgumentError `
                    -ErrorId 'CertificateReqNotFoundError' `
                    -ErrorMessage ($LocalizedData.CertificateReqNotFoundError -f 'xCertReq-Test.req')

                It 'should throw CertificateReqNotFoundError exception' {
                    { Set-TargetResource @ParamsNoCred } | Should Throw $errorRecord
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Join-Path -Exactly 1
                    Assert-MockCalled -CommandName Test-Path -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.req' }
                    Assert-MockCalled -CommandName Test-Path -Exactly 0 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.cer' }
                    Assert-MockCalled -CommandName Set-Content -Exactly 1 `
                        -ParameterFilter {
                            $Path -eq 'xCertReq-Test.inf' -and `
                            $Value -eq $CertInf
                        }
                    Assert-MockCalled -CommandName CertReq.exe -Exactly 1
                }
            }

            Mock -CommandName Test-Path -MockWith { $true } `
                -ParameterFilter { $Path -eq 'xCertReq-Test.req' }
            Mock -CommandName Test-Path -MockWith { $false } `
                -ParameterFilter { $Path -eq 'xCertReq-Test.cer' }

            Context 'autorenew is false, credentials not passed, certificate creation failed' {
                Mock -CommandName Get-ChildItem -Mockwith { } `
                    -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' }

                $errorRecord = Get-InvalidArgumentError `
                    -ErrorId 'CertificateCerNotFoundError' `
                    -ErrorMessage ($LocalizedData.CertificateCerNotFoundError -f 'xCertReq-Test.cer')

                It 'should throw CertificateCerNotFoundError exception' {
                    { Set-TargetResource @ParamsNoCred } | Should Throw $errorRecord
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Join-Path -Exactly 1
                    Assert-MockCalled -CommandName Test-Path -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.req' }
                    Assert-MockCalled -CommandName Test-Path -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.cer' }
                    Assert-MockCalled -CommandName Set-Content -Exactly 1 `
                        -ParameterFilter {
                            $Path -eq 'xCertReq-Test.inf' -and `
                            $Value -eq $CertInf
                        }
                    Assert-MockCalled -CommandName CertReq.exe -Exactly 2
                }
            }

            Mock -CommandName Test-Path -MockWith { $true } `
                -ParameterFilter { $Path -eq 'xCertReq-Test.req' }
            Mock -CommandName Test-Path -MockWith { $true } `
                -ParameterFilter { $Path -eq 'xCertReq-Test.cer' }
            Mock -CommandName Test-Path -MockWith { $true } `
                -ParameterFilter { $Path -eq 'xCertReq-Test.out' }

            Context 'autorenew is false, credentials passed' {
                Mock -CommandName Get-ChildItem -Mockwith { } `
                    -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' }
                Mock -CommandName Get-Content -Mockwith { 'Output' } `
                    -ParameterFilter { $Path -eq 'xCertReq-Test.out' }
                Mock -CommandName Remove-Item `
                    -ParameterFilter { $Path -eq 'xCertReq-Test.out' }
                Mock -CommandName Import-Module

                function Start-Win32Process { param ( $Path,$Arguments,$Credential ) }
                function Wait-Win32ProcessStop { param ( $Path,$Arguments,$Credential ) }

                Mock -CommandName Start-Win32Process -ModuleName MSFT_xCertReq
                Mock -CommandName Wait-Win32ProcessStop -ModuleName MSFT_xCertReq

                It 'should not throw' {
                    { Set-TargetResource @Params } | Should Not Throw
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Join-Path -Exactly 1
                    Assert-MockCalled -CommandName Test-Path -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.req' }
                    Assert-MockCalled -CommandName Test-Path  -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.cer' }
                    Assert-MockCalled -CommandName Set-Content -Exactly 1 `
                        -ParameterFilter {
                            $Path -eq 'xCertReq-Test.inf' -and `
                            $Value -eq $CertInf
                        }
                    Assert-MockCalled -CommandName CertReq.exe -Exactly 2
                    Assert-MockCalled -CommandName Start-Win32Process -ModuleName MSFT_xCertReq -Exactly 1
                    Assert-MockCalled -CommandName Wait-Win32ProcessStop -ModuleName MSFT_xCertReq -Exactly 1
                    Assert-MockCalled -CommandName Test-Path  -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.out' }
                    Assert-MockCalled -CommandName Get-Content -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.out' }
                    Assert-MockCalled -CommandName Remove-Item -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.out' }
                }
            }

            Mock -CommandName Set-Content `
                -ParameterFilter {
                    $Path -eq 'xCertReq-Test.inf' -and `
                    $Value -eq $CertInfSubjectAltName
                }

            Context 'autorenew is false, subject alt name passed, credentials not passed' {
                Mock -CommandName Get-ChildItem -Mockwith { } `
                    -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' }

                It 'should not throw' {
                    { Set-TargetResource @ParamsSubjectAltNameNoCred } | Should Not Throw
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Join-Path -Exactly 1
                    Assert-MockCalled -CommandName Test-Path -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.req' }
                    Assert-MockCalled -CommandName Test-Path  -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.cer' }
                    Assert-MockCalled -CommandName Set-Content -Exactly 1 `
                        -ParameterFilter {
                            $Path -eq 'xCertReq-Test.inf' -and `
                            $Value -eq $CertInfSubjectAltName
                        }
                    Assert-MockCalled -CommandName CertReq.exe -Exactly 3
                }
            }

            Context 'standalone CA, URL for CEP and CES passed, credentials passed, inf not containing template' {
                Mock -CommandName Set-Content -ParameterFilter {
                    $Path -eq 'xCertReq-Test.inf' -and `
                    $Value -eq $CertInfNoTemplate
                }
                Mock -CommandName Get-ChildItem -Mockwith { } `
                    -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' }

                It 'should not throw' {
                    { Set-TargetResource @ParamsStandaloneWebEnrollment } | Should Not Throw
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Join-Path -Exactly 1
                    Assert-MockCalled -CommandName Test-Path -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.req' }
                    Assert-MockCalled -CommandName Test-Path  -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.cer' }
                    Assert-MockCalled -CommandName Set-Content -Exactly 1 `
                        -ParameterFilter {
                            $Path -eq 'xCertReq-Test.inf' -and `
                            $Value -eq $CertInfNoTemplate
                        }
                    Assert-MockCalled -CommandName CertReq.exe -Exactly 3
                }
            }

            Context 'enterprise CA, URL for CEP and CES passed, credentials passed' {
                Mock -CommandName Set-Content -ParameterFilter {
                    $Path -eq 'xCertReq-Test.inf' -and `
                    $Value -eq $CertInf
                }
                Mock -CommandName Get-ChildItem -Mockwith { } `
                    -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' }

                It 'should not throw' {
                    { Set-TargetResource @ParamsEnterpriseWebEnrollment } | Should Not Throw
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Join-Path -Exactly 1
                    Assert-MockCalled -CommandName Test-Path -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.req' }
                    Assert-MockCalled -CommandName Test-Path  -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.cer' }
                    Assert-MockCalled -CommandName Set-Content -Exactly 1 `
                        -ParameterFilter {
                            $Path -eq 'xCertReq-Test.inf' -and `
                            $Value -eq $CertInf
                        }
                    Assert-MockCalled -CommandName CertReq.exe -Exactly 3
                }
            }

            Context 'Auto-discovered CA, autorenew is false, credentials passed' {
                Mock -CommandName Get-ChildItem -Mockwith { } `
                    -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' }
                Mock -CommandName Get-Content -Mockwith { 'Output' } `
                    -ParameterFilter { $Path -eq 'xCertReq-Test.out' }
                Mock -CommandName Remove-Item `
                    -ParameterFilter { $Path -eq 'xCertReq-Test.out' }
                Mock -CommandName Import-Module
                Mock -CommandName Start-Win32Process
                Mock -CommandName Wait-Win32ProcessStop
                Mock -CommandName Find-CertificateAuthority -MockWith {
                    return New-Object -TypeName psobject -Property @{
                        CARootName = "ContosoCA"
                        CAServerFQDN = "ContosoVm.contoso.com"
                    }
                }

                It 'should not throw' {
                    { Set-TargetResource @ParamsAutoDiscovery } | Should Not Throw
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Join-Path -Exactly 1
                    Assert-MockCalled -CommandName Test-Path -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.req' }
                    Assert-MockCalled -CommandName Test-Path  -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.cer' }
                    Assert-MockCalled -CommandName Set-Content -Exactly 1 `
                        -ParameterFilter {
                            $Path -eq 'xCertReq-Test.inf' -and `
                            $Value -eq $CertInf
                        }
                    Assert-MockCalled -CommandName CertReq.exe -Exactly 2
                    Assert-MockCalled -CommandName Start-Win32Process -ModuleName MSFT_xCertReq -Exactly 1
                    Assert-MockCalled -CommandName Wait-Win32ProcessStop -ModuleName MSFT_xCertReq -Exactly 1
                    Assert-MockCalled -CommandName Test-Path  -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.out' }
                    Assert-MockCalled -CommandName Get-Content -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.out' }
                    Assert-MockCalled -CommandName Remove-Item -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.out' }
                    Assert-MockCalled -CommandName Find-CertificateAuthority -Exactly -Times 1
                }
            }
        }
        #endregion

        Describe "$DSCResourceName\Test-TargetResource" {
            Mock -CommandName Find-CertificateAuthority -MockWith {
                    return New-Object -TypeName psobject -Property @{
                        CARootName = "ContosoCA"
                        CAServerFQDN = "ContosoVm.contoso.com"
                    }
                }

            It 'should return a bool' {
                Test-TargetResource @Params | Should BeOfType Boolean
            }
            It 'should return false when a valid certificate does not exist' {
                Mock Get-ChildItem -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' } `
                    -Mockwith { }
                Test-TargetResource @Params | Should Be $false
            }
            It 'should return true when a valid certificate already exists and is not about to expire' {
                Mock Get-ChildItem -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' } `
                    -Mockwith { $validCert }
                Mock Get-CertificateTemplateName -MockWith { $CertificateTemplate }
                Mock Get-CertificateSan -MockWith { $SubjectAltName }
                Test-TargetResource @Params | Should Be $true
            }
            It 'should return true when a valid certificate already exists and is about to expire and autorenew set' {
                Mock Get-ChildItem -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' } `
                    -Mockwith { $expiringCert }
                Mock Get-CertificateTemplateName -MockWith { $CertificateTemplate }
                Mock Get-CertificateSan -MockWith { $SubjectAltName }
                Test-TargetResource @ParamsAutoRenew | Should Be $true
            }
                  It 'should return true when a valid certificate already exists and DNS SANs match' {
                Mock Get-ChildItem -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' } `
                    -Mockwith { $validSANCert }
                Test-TargetResource @ParamsSubjectAltName | Should Be $true
            }
                  It 'should return false when a certificate exists but contains incorrect DNS SANs' {
                Mock Get-ChildItem -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' } `
                    -Mockwith { $incorrectSANCert }
                Test-TargetResource @ParamsSubjectAltName | Should Be $false
            }
                  It 'should return false when a certificate exists but does not contain specified DNS SANs' {
                Mock Get-ChildItem -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' } `
                    -Mockwith { $emptySANCert }
                Test-TargetResource @ParamsSubjectAltName | Should Be $false
            }
            It 'Should auto-discover the CA and return false' {
                Test-TargetResource @ParamsAutoDiscovery | Should Be $false
            }
            It 'Should execute the auto-discovery function' {
                Assert-MockCalled -CommandName Find-CertificateAuthority -Exactly -Times 1
            }
        }
    }
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
