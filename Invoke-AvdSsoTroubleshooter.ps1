<# .SYNOPSIS Wrapper for the AVD SSO cloud and session-host diagnostics. #>
[CmdletBinding(DefaultParameterSetName='Cloud')]
param(
    [Parameter(Mandatory,ParameterSetName='Cloud')] [string] $ResourceGroupName,
    [Parameter(Mandatory,ParameterSetName='Cloud')] [string] $HostPoolName,
    [Parameter(ParameterSetName='Cloud')] [string] $SubscriptionId,
    [Parameter(ParameterSetName='Cloud')] [switch] $IncludeEntraChecks,
    [Parameter(Mandatory,ParameterSetName='SessionHost')] [switch] $SessionHost,
    [string] $OutputDirectory = (Get-Location),
    [switch] $Markdown,
    [switch] $VerboseIdentity
)
$ErrorActionPreference='Stop'; $root=Split-Path -Parent $MyInvocation.MyCommand.Path
if(-not (Test-Path $OutputDirectory)){ New-Item -ItemType Directory -Path $OutputDirectory | Out-Null }
if($PSCmdlet.ParameterSetName -eq 'Cloud'){
    $out=Join-Path $OutputDirectory ("avd-sso-cloud-{0}.json" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
    & (Join-Path $root 'Test-AvdSsoCloud.ps1') -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName -SubscriptionId $SubscriptionId -OutputPath $out -Markdown:$Markdown -IncludeEntraChecks:$IncludeEntraChecks -VerboseIdentity:$VerboseIdentity
} else {
    $out=Join-Path $OutputDirectory ("avd-sso-sessionhost-{0}.json" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
    & (Join-Path $root 'Test-AvdSsoSessionHost.ps1') -OutputPath $out -Markdown:$Markdown -VerboseIdentity:$VerboseIdentity
}
