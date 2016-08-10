[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param()

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
        function New-InvalidOperationError
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
                -ArgumentList $ErrorMessage;
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation;
            $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                -ArgumentList $exception, $ErrorId, $errorCategory, $null;
            return $errorRecord;
        } # end function New-InvalidOperationError

        function New-InvalidArgumentError
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
                -ArgumentList $ErrorMessage;
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument;
            $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                -ArgumentList $exception, $ErrorId, $errorCategory, $null;
            return $errorRecord;
        } # end function New-InvalidArgumentError

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
        $invalidCert      = New-Object -TypeName PSObject -Property @{
            Thumbprint  = $validThumbprint
            Subject     = "CN=$validSubject"
            Issuer      = $validIssuer
            NotBefore   = (Get-Date).AddDays(-30) # Issued on
            NotAfter    = (Get-Date).AddDays(31) # Expires after
        }
        Add-Member -InputObject $invalidCert -MemberType ScriptMethod -Name Verify -Value {
            return $false
        }

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
           
        $CertInfKey = $CertInf -Replace 'KeyLength = ([0-z]*)', 'KeyLength = 4096' #Added 4:07pm
        $CertInfRenew = $Certinf
        $CertInfRenew += @"

RenewalCert = $validThumbprint
"@
        $CertInfKeyRenew = $CertInfRenew -Replace 'KeyLength = ([0-z]*)', 'KeyLength = 4096' #Added 4:07pm

        # region Get-TargetResource
        Describe "$($script:DSCResourceName)\Get-TargetResource" {
            Mock Get-ChildItem -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' } `
                -Mockwith { $validCert }
            $result = Get-TargetResource @Params
            It 'should return a hashtable' {
                ($result -is [hashtable]) | Should Be $true
            }
            It 'should contain the input values' {
                $result.Subject              | Should BeExactly $validSubject
                $result.CAServerFQDN         | Should BeNullOrEmpty
                $result.CARootName           | Should BeExactly $CARootName
                $result.KeyLength            | Should BeNullOrEmpty # to change
                $result.Exportable           | Should BeNullOrEmpty # to change
                $result.ProviderName         | Should BeNullOrEmpty # to change
                $result.OID                  | Should BeNullOrEmpty # to change
                $result.KeyUsage             | Should BeNullOrEmpty # to change
                $result.CertificateTemplate  | Should BeNullOrEmpty # to change
            }
        }
        # endregion

        # region Set-TargetResource
        Describe "$($script:DSCResourceName)\Set-TargetResource" {
            Mock -CommandName Join-Path -MockWith { 'xCertReq-Test' } `
                -ParameterFilter { $Path -eq $ENV:Temp }
            Mock -CommandName Test-Path -MockWith { $true } `
                -ParameterFilter { $Path -eq 'xCertReq-Test.req' }
            Mock -CommandName Test-Path -MockWith { $true } `
                -ParameterFilter { $Path -eq 'xCertReq-Test.cer' }
            Mock -CommandName CertReq.exe

            Context 'autorenew is false, credentials not passed' {
                Mock -CommandName Set-Content `
                    -ParameterFilter { $Path -eq 'xCertReq-Test.inf' } `
                    -MockWith { $Global:CertInfContent = $Value }
                Mock -CommandName Get-ChildItem -Mockwith { } `
                    -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' }

                It 'does not throw' {
                    { Set-TargetResource @ParamsNoCred } | Should Not Throw
                }
                It 'xCertReq-Test.inf content is expected' {
                    $Global:CertInfContent | Should Be $Certinf
                }
                It 'calls expected mocks' {
                    Assert-MockCalled -CommandName Join-Path -Exactly 1
                    Assert-MockCalled -CommandName Test-Path -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.req' }
                    Assert-MockCalled -CommandName Test-Path  -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.cer' }
                    Assert-MockCalled -CommandName Set-Content -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.inf' }
                    Assert-MockCalled -CommandName CertReq.exe -Exactly 3
                }
            }
            Context 'autorenew is false, credentials not passed, keylength modified' {
                Mock -CommandName Set-Content `
                    -ParameterFilter { $Path -eq 'xCertReq-Test.inf' } `
                    -MockWith { $Global:CertInfContent = $Value }
                Mock -CommandName Get-ChildItem -Mockwith { } `
                    -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' }

                It 'does not throw' {
                    { Set-TargetResource @ParamsKeyLength4096NoCred } | Should Not Throw
                }
                It 'xCertReq-Test.inf content is expected' {
                    $Global:CertInfContent | Should Be $CertinfKey
                }
                It 'calls expected mocks' {
                    Assert-MockCalled -CommandName Join-Path -Exactly 1
                    Assert-MockCalled -CommandName Test-Path -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.req' }
                    Assert-MockCalled -CommandName Test-Path  -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.cer' }
                    Assert-MockCalled -CommandName Set-Content -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.inf' }
                    Assert-MockCalled -CommandName CertReq.exe -Exactly 3
                }
            }

            Context 'autorenew is true, credentials not passed and certificate does not exist' {
                Mock -CommandName Set-Content `
                    -ParameterFilter { $Path -eq 'xCertReq-Test.inf' } `
                    -MockWith { $Global:CertInfContent = $Value }
                Mock -CommandName Get-ChildItem -Mockwith { } `
                    -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' }

                It 'does not throw' {
                    { Set-TargetResource @ParamsAutoRenewNoCred } | Should Not Throw
                }
                It 'xCertReq-Test.inf content is expected' {
                    $Global:CertInfContent | Should Be $Certinf
                }
                It 'calls expected mocks' {
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
                }
            }

            Context 'autorenew is true, credentials not passed and valid certificate exists' {
                Mock -CommandName Set-Content `
                    -ParameterFilter { $Path -eq 'xCertReq-Test.inf' } `
                    -MockWith { $Global:CertInfContent = $Value }
                Mock -CommandName Get-ChildItem -Mockwith { $validCert } `
                    -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' }

                It 'does not throw' {
                    { Set-TargetResource @ParamsAutoRenewNoCred } | Should Not Throw
                }
                It 'xCertReq-Test.inf content is expected' {
                    $Global:CertInfContent | Should Be $CertInf
                }
                It 'calls expected mocks' {
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
                }
            }

            Context 'autorenew is true, credentials not passed, keylength modified and valid certificate exists' {
                Mock -CommandName Set-Content `
                    -ParameterFilter { $Path -eq 'xCertReq-Test.inf' } `
                    -MockWith { $Global:CertInfContent = $Value }
                Mock -CommandName Get-ChildItem -Mockwith { $validCert } `
                    -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' } 

                It 'does not throw' {
                    { Set-TargetResource @ParamsKeyLength4096AutoRenewNoCred } | Should Not Throw
                }
                It 'xCertReq-Test.inf content is expected' {
                    $Global:CertInfContent | Should Be $CertInfKey
                }
                It 'calls expected mocks' {
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
                }
            }

            Context 'autorenew is true, credentials not passed and expiring certificate exists' {
                Mock -CommandName Set-Content `
                    -ParameterFilter { $Path -eq 'xCertReq-Test.inf' } `
                    -MockWith { $Global:CertInfContent = $Value }
                Mock -CommandName Get-ChildItem -Mockwith { $expiringCert } `
                    -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' } 

                It 'does not throw' {
                    { Set-TargetResource @ParamsAutoRenewNoCred } | Should Not Throw
                }
                It 'xCertReq-Test.inf content is expected' {
                    $Global:CertInfContent | Should Be $CertInfRenew
                }
                It 'calls expected mocks' {
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
                }
            }

            Context 'autorenew is true, credentials not passed and expired certificate exists' {
                Mock -CommandName Set-Content `
                    -ParameterFilter { $Path -eq 'xCertReq-Test.inf' } `
                    -MockWith { $Global:CertInfContent = $Value }
                Mock -CommandName Get-ChildItem -Mockwith { $expiredCert } `
                    -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' } 

                It 'does not throw' {
                    { Set-TargetResource @ParamsKeyLength4096AutoRenewNoCred } | Should Not Throw
                }
                It 'xCertReq-Test.inf content is expected' {
                    $Global:CertInfContent | Should Be $CertInfKeyRenew
                }
                It 'calls expected mocks' {
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
                }
            }


            Context 'autorenew is true, credentials not passed, keylength modified and expired certificate exists' {
                Mock -CommandName Set-Content `
                    -ParameterFilter { $Path -eq 'xCertReq-Test.inf' } `
                    -MockWith { $Global:CertInfContent = $Value }
                Mock -CommandName Get-ChildItem -Mockwith { $expiringCert } `
                    -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' }

                It 'does not throw' {
                    { Set-TargetResource @ParamsAutoRenewNoCred } | Should Not Throw
                }
                It 'xCertReq-Test.inf content is expected' {
                    $Global:CertInfContent | Should Be $CertInfRenew
                }
                It 'calls expected mocks' {
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
                }
            }

            Mock -CommandName Test-Path -MockWith { $false } `
                -ParameterFilter { $Path -eq 'xCertReq-Test.req' }

            Context 'autorenew is false, credentials not passed, certificate request creation failed' {
                Mock -CommandName Set-Content `
                    -ParameterFilter { $Path -eq 'xCertReq-Test.inf' } `
                    -MockWith { $Global:CertInfContent = $Value }
                Mock -CommandName Get-ChildItem -Mockwith { } `
                    -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' }

                $errorRecord = New-InvalidArgumentError `
                    -ErrorId 'CertificateReqNotFoundError' `
                    -ErrorMessage ($LocalizedData.CertificateReqNotFoundError -f 'xCertReq-Test.req')

                It 'throws CertificateReqNotFoundError exception' {
                    { Set-TargetResource @ParamsNoCred } | Should Throw $errorRecord
                }
                It 'xCertReq-Test.inf content is expected' {
                    $Global:CertInfContent | Should Be $Certinf
                }
                It 'calls expected mocks' {
                    Assert-MockCalled -CommandName Join-Path -Exactly 1
                    Assert-MockCalled -CommandName Test-Path -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.req' }
                    Assert-MockCalled -CommandName Test-Path -Exactly 0 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.cer' }
                    Assert-MockCalled -CommandName Set-Content -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.inf' }
                    Assert-MockCalled -CommandName CertReq.exe -Exactly 1
                }
            }
             Context 'autorenew is false, credentials not passed, keylength modified, certificate request creation failed' {
                Mock -CommandName Set-Content `
                    -ParameterFilter { $Path -eq 'xCertReq-Test.inf' } `
                    -MockWith { $Global:CertInfContent = $Value }
                Mock -CommandName Get-ChildItem -Mockwith { } `
                    -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' }

                $errorRecord = New-InvalidArgumentError `
                    -ErrorId 'CertificateReqNotFoundError' `
                    -ErrorMessage ($LocalizedData.CertificateReqNotFoundError -f 'xCertReq-Test.req')

                It 'throws CertificateReqNotFoundError exception' {
                    { Set-TargetResource @ParamsKeyLength4096NoCred } | Should Throw $errorRecord
                }
                It 'xCertReq-Test.inf content is expected' {
                    $Global:CertInfContent | Should Be $CertInfKey
                }
                It 'calls expected mocks' {
                    Assert-MockCalled -CommandName Join-Path -Exactly 1
                    Assert-MockCalled -CommandName Test-Path -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.req' }
                    Assert-MockCalled -CommandName Test-Path -Exactly 0 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.cer' }
                    Assert-MockCalled -CommandName Set-Content -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.inf' }
                    Assert-MockCalled -CommandName CertReq.exe -Exactly 1
                }
            }

            Mock -CommandName Test-Path -MockWith { $true } `
                -ParameterFilter { $Path -eq 'xCertReq-Test.req' }
            Mock -CommandName Test-Path -MockWith { $false } `
                -ParameterFilter { $Path -eq 'xCertReq-Test.cer' }

            Context 'autorenew is false, credentials not passed, certificate creation failed' {
                Mock -CommandName Set-Content `
                    -ParameterFilter { $Path -eq 'xCertReq-Test.inf' } `
                    -MockWith { $Global:CertInfContent = $Value }
                Mock -CommandName Get-ChildItem -Mockwith { } `
                    -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' }

                $errorRecord = New-InvalidArgumentError `
                    -ErrorId 'CertificateCerNotFoundError' `
                    -ErrorMessage ($LocalizedData.CertificateCerNotFoundError -f 'xCertReq-Test.cer')

                It 'throws CertificateCerNotFoundError exception' {
                    { Set-TargetResource @ParamsNoCred } | Should Throw $errorRecord
                }
                It 'xCertReq-Test.inf content is expected' {
                    $Global:CertInfContent | Should Be $Certinf
                }
                It 'calls expected mocks' {
                    Assert-MockCalled -CommandName Join-Path -Exactly 1
                    Assert-MockCalled -CommandName Test-Path -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.req' }
                    Assert-MockCalled -CommandName Test-Path -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.cer' }
                    Assert-MockCalled -CommandName Set-Content -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.inf' }
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
                Mock -CommandName Set-Content `
                    -ParameterFilter { $Path -eq 'xCertReq-Test.inf' } `
                    -MockWith { $Global:CertInfContent = $Value }
                Mock -CommandName Get-ChildItem -Mockwith { } `
                    -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' }
                Mock -CommandName Get-Content -Mockwith { 'Output' } `
                    -ParameterFilter { $Path -eq 'xCertReq-Test.out' }
                Mock -CommandName Remove-Item `
                    -ParameterFilter { $Path -eq 'xCertReq-Test.out' }
                Mock -CommandName Import-Module

                function StartWin32Process { param ( $Path,$Arguments,$Credential ) }
                function WaitForWin32ProcessEnd { param ( $Path,$Arguments,$Credential ) }

                Mock -CommandName StartWin32Process -ModuleName MSFT_xCertReq
                Mock -CommandName WaitForWin32ProcessEnd -ModuleName MSFT_xCertReq

                It 'does not throw' {
                    { Set-TargetResource @Params } | Should Not Throw
                }
                It 'xCertReq-Test.inf content is expected' {
                    $Global:CertInfContent | Should Be $Certinf
                }
                It 'calls expected mocks' {
                    Assert-MockCalled -CommandName Join-Path -Exactly 1
                    Assert-MockCalled -CommandName Test-Path -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.req' }
                    Assert-MockCalled -CommandName Test-Path  -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.cer' }
                    Assert-MockCalled -CommandName Set-Content -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.inf' }
                    Assert-MockCalled -CommandName CertReq.exe -Exactly 2
                    Assert-MockCalled -CommandName StartWin32Process -ModuleName MSFT_xCertReq -Exactly 1
                    Assert-MockCalled -CommandName WaitForWin32ProcessEnd -ModuleName MSFT_xCertReq -Exactly 1
                    Assert-MockCalled -CommandName Test-Path  -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.out' }
                    Assert-MockCalled -CommandName Get-Content -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.out' }
                    Assert-MockCalled -CommandName Remove-Item -Exactly 1 `
                        -ParameterFilter { $Path -eq 'xCertReq-Test.out' }
                }
            }
        }
        # endregion

        # region Test-TargetResource
        Describe "$($script:DSCResourceName)\Test-TargetResource" {
            It 'should return a bool' {
                Test-TargetResource @Params | Should BeOfType Boolean
            }
            It 'returns false when a valid certificate does not exist' {
                Mock Get-ChildItem -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' } `
                    -Mockwith { }
                Test-TargetResource @Params | Should Be $false
            }
            It 'returns true when a valid certificate already exists and is not about to expire' {
                Mock Get-ChildItem -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' } `
                    -Mockwith { $validCert }
                Test-TargetResource @Params | Should Be $true
            }
            It 'returns true when a valid certificate already exists and is about to expire and autorenew set' {
                Mock Get-ChildItem -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' } `
                    -Mockwith { $expiringCert }
                Test-TargetResource @ParamsAutoRenew | Should Be $true
            }
            It 'returns true when a valid certificate already exists and is about to expire and autorenew set' {
                Mock Get-ChildItem -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' } `
                    -Mockwith { $expiringCert }
                Test-TargetResource @ParamsAutoRenew | Should Be $true
            }
            It 'returns false when a valid certificate already exists and is about to expire and autorenew not set' {
                Mock Get-ChildItem -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' } `
                    -Mockwith { $invalidCert }
                Test-TargetResource @Params | Should Be $false
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
