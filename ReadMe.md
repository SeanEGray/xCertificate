[![Build status](https://ci.appveyor.com/api/projects/status/0u9f8smiidg1j4kn/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/xcertificate/branch/master)

# xCertificate
The **xCertificate** module is a part of the Windows PowerShell Desired State Configuration (DSC) Resource Kit, which is a collection of DSC Resources. This module includes DSC resources that simplify administration of certificates on a Windows Server, with simple declarative language.

The **xCertificate** module contains the following resources:
* **xCertReq**
* **xPfxImport**
* **xCertificateImport**

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Contributing
Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).

## Resources

### xCertReq

- **`[String]` Subject**: Provide the text string to use as the subject of the certificate. Key.
- **`[String]` CAServerFQDN**: The FQDN of the Active Directory Certificate Authority on the local area network. Required.
- **`[String]` CARootName**: The name of the certificate authority, by default this will be in format domain-servername-ca. Required.
- **`[String]` KeyLength**: The bit length of the encryption key to be used. Optional. { *1024* | 2048 | 4096 | 8192 }. 
- **`[Boolean]` Exportable**: The option to allow the certificate to be exportable, by default it will be true. Optional. Defaults to `$true`.
- **`[String]` ProviderName**: The selection of provider for the type of encryption to be used. Optional. Defaults to `"Microsoft RSA SChannel Cryptographic Provider"`.
- **`[String]` OID**: The Object Identifier that is used to name the object. Optional. Defaults to `1.3.6.1.5.5.7.3.1`.
- **`[String]` KeyUsage**: The Keyusage is a restriction method that determines what a certificate can be used for. Optional. Defaults to `0xa0`
- **`[String]` CertificateTemplate** The template used for the definiton of the certificate. Optional. Defaults to `WebServer`   
- **`[PSCredential]` Credential**: The credentials that will be used to access the template in the Certificate Authority. Optional.
- **`[Boolean]` AutoRenew**: Determines if the resource will also renew a certificate within 7 days of expiration. Optional. 

### xPfxImport

- **`[String]` Thumbprint**: The thumbprint (unique identifier) of the PFX file you're importing. Key.
- **`[String]` Path**: The path to the PFX file you want to import. Required.
- **`[String]` Location**: The Windows Certificate Store Location to import the PFX file to. Key. { LocalMachine | CurrentUser }
- **`[String]` Store**: The Windows Certificate Store Name to import the PFX file to. Key.
- **`[Boolean]` Exportable**: Determines whether the private key is exportable from the machine after it has been imported. Optional. Defaults to `$false`.
- **`[PSCredential]` Credential**: A `[PSCredential]` object that is used to decrypt the PFX file. Only the password is used, so any user name is valid. Optional.
- **`[String]` Ensure**: Specifies whether the PFX file should be present or absent. Optional. { *Present* | Absent }.

### xCertificateImport

- **`[String]` Thumbprint**: The thumbprint (unique identifier) of the certificate you're importing. Key.
- **`[String]` Path**: The path to the CER file you want to import. Required.
- **`[String]` Location**: The Windows Certificate Store Location to import the certificate to. Key. { LocalMachine | CurrentUser }
- **`[String]` Store**: The Windows Certificate Store Name to import the certificate to. Key.
- **`[String]` Ensure**: Specifies whether the certificate should be present or absent. Optional. { *Present* | Absent }.

## Versions

### Unreleased
* Converted appveyor.yml to install Pester from PSGallery instead of from Chocolatey.
* Moved unit tests to correct folder structure.
* Changed unit tests to use standard test templates.
* Updated all resources to meet HQRM standards and style guidelines.
* Added .gitignore file
* Added .gitattributes file to force line endings to CRLF to allow unit tests to work.
* xCertificateCommon:
    - Moved common code into new module MSFT_xCertificateCommon.
    - Added standard exception code.
    - Renamed common functions Validate-* to use acceptable verb Test-*.
* xCertificateImport:
    - Fixed bug with Test-TargetResource incorrectly detecting change required.
    - Reworked unit tests for improved code coverage to meet HQRM standards.
    - Created Integration tests for both importing and removing an imported certificate.
    - Added descriptions to MOF file.
    - Removed default parameter values for parameters that are required or keys.
    - Added verbose messages.
    - Split message and error strings into localization string files.
* xPfxImport:
    - Fixed bug with Test-TargetResource incorrectly detecting change required.
    - Reworked unit tests for improved code coverage to meet HQRM standards.
    - Created Integration tests for both importing and removing an imported certificate.
    - Added descriptions to MOF file.
    - Removed default parameter values for parameters that are required or keys.
    - Added verbose messages.
    - Split message and error strings into localization string files.
* xCertReq:
    - Cleaned up descriptions in MOF file.
    - Fixed bugs generating certificate when credentials are specified.
    - Allowed output of certificate request when credentials are specified.
    - Split message and error strings into localization string files.
    - Created unit tests and integration tests.
    - Improved logging output to enable easier debugging.
* xPDT:
    - Renamed to match standard module name format (MSFT_x).
    - Modified to meet 100 characters or less line length where possible.
    - Split message and error strings into localization string files.

### 2.1.0.0
* Fixed xCertReq to support CA Root Name with spaces

### 2.0.0.0
* Breaking Change - Updated xPfxImport Store parameter is now a key value making it mandatory
* Updated xPfxImport with new Ensure support
* Updated xPfxImport with support for the CurrentUser value
* Updated xPfxImport with validationset for the Store parameter
* Added new resource: xCertificateImport

### 1.1.0.0
* Added new resource: xPfxImport

### 1.0.1.0

* Minor documentation updates

### 1.0.0.0

* Initial public release of xCertificate module with following resources
    * xCertReq

## Examples

## xCertReq

**Example 1**:  Request and Accept a certificate from an Active Directory Root Certificate Authority.

```powershell
configuration xCertReq_RequestSSL
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PsCredential] $Credential
        )
    Import-DscResource -ModuleName xCertificate
    Node 'localhost'
    {
        xCertReq SSLCert
        {
            CARootName                = 'test-dc01-ca'
            CAServerFQDN              = 'dc01.test.pha'
            Subject                   = 'foodomain.test.net'
            KeyLength                 = '1024'
            Exportable                = $true
            ProviderName              = '"Microsoft RSA SChannel Cryptographic Provider"'
            OID                       = '1.3.6.1.5.5.7.3.1'
            KeyUsage                  = '0xa0'
            CertificateTemplate       = 'WebServer'
            AutoRenew                 = $true
            Credential                = $Credential
        }
    }
}
$configData = @{
    AllNodes = @(
        @{
            NodeName                    = 'localhost';
            PSDscAllowPlainTextPassword = $true
            }
        )
    }
xCertReq_RequestSSL `
    -ConfigurationData $configData `
    -Credential (Get-Credential) `
    -OutputPath 'c:\xCertReq_RequestSSL'
Start-DscConfiguration -Wait -Force -Verbose -Path 'c:\xCertReq_RequestSSL'

# Validate results
Get-ChildItem Cert:\LocalMachine\My
```

## xPfxImport

### Simple Usage

```powershell
Configuration Sample_xPfxImport_MinimalUsage
{
    param(
        [PSCredential]
        $PfxPassword = (Get-Credential -Message 'Enter PFX extraction password.' -UserName 'Ignore')
    )

    Import-DscResource -ModuleName xCertificate

    Node $AllNodes.NodeName
    {
        xPfxImport CompanyCert
        {
            Thumbprint = 'c81b94933420221a7ac004a90242d8b1d3e5070d'
            Path       = '\\Server\Share\Certificates\CompanyCert.pfx'
            Credential = $PfxPassword
        }
    }
}
Sample_xPfxImport_MinimalUsage `
    -OutputPath 'c:\Sample_xPfxImport_MinimalUsage'
Start-DscConfiguration -Wait -Force -Verbose -Path 'c:\Sample_xPfxImport_MinimalUsage'

# Validate results
Get-ChildItem Cert:\LocalMachine\My
```

### Used with xWebAdministration Resources

```powershell
Configuration Sample_xPfxImport_IIS_WebSite
{
    param(
        [PSCredential]
        $PfxPassword = (Get-Credential -Message 'Enter PFX extraction password.' -UserName 'Ignore')
    )

    Import-DscResource -ModuleName xCertificate
    Import-DscResource -ModuleName xWebAdministration

    Node $AllNodes.NodeName
    {
        WindowsFeature IIS
        {
            Ensure = 'Present'
            Name   = 'Web-Server'
        }

        xPfxImport CompanyCert
        {
            Thumbprint = 'c81b94933420221a7ac004a90242d8b1d3e5070d'
            Path       = '\\Server\Share\Certificates\CompanyCert.pfx'
            Store      = 'WebHosting'
            Credential = $PfxPassword
            DependsOn  = '[WindowsFeature]IIS'
        }

        xWebsite CompanySite
        {
            Ensure          = 'Present'
            Name            = 'CompanySite'
            State           = 'Started'
            PhysicalPath    = "B:\Web\CompanySite"
            ApplicationPool = "CompanyPool"
            BindingInfo     =
                    MSFT_xWebBindingInformation {
                        Protocol = 'HTTPS'
                        Port = 443
                        CertificateThumbprint = 'c81b94933420221a7ac004a90242d8b1d3e5070d'
                        CertificateStoreName = 'WebHosting'
                        HostName = "www.example.com"
                    }
            DependsOn       = '[WindowsFeature]Web-Server','[xPfxImport]CompanyCert'
        }
    }
}
Sample_xPfxImport_IIS_WebSite `
    -OutputPath 'c:\Sample_xPfxImport_IIS_WebSite'
Start-DscConfiguration -Wait -Force -Verbose -Path 'c:\Sample_xPfxImport_IIS_WebSite'
```

## xCertificateImport

**Example 1**: Import public key certificate into Trusted Root store

```powershell
Configuration Sample_xCertificateImport_MinimalUsage
{
    Import-DscResource -ModuleName xCertificate

    Node $AllNodes.NodeName
    {
        xCertificateImport MyTrustedRoot
        {
            Thumbprint = 'c81b94933420221a7ac004a90242d8b1d3e5070d'
            Location   = 'LocalMachine'
            Store      = 'Root'
            Path       = '\\Server\Share\Certificates\MyTrustedRoot.cer'
        }
    }
}
Sample_xCertificateImport_MinimalUsage `
    -OutputPath 'c:\Sample_xCertificateImport_MinimalUsage'
Start-DscConfiguration -Wait -Force -Verbose -Path 'c:\Sample_xCertificateImport_MinimalUsage'

# Validate results
Get-ChildItem Cert:\LocalMachine\My
```
