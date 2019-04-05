Install-Module -Name DataProtectionManagerCX -Force

Get-Command -Module DataProtectionManagerCX

$ComputerName = 'DEMODC03'

Test-DPMCXComputer -ComputerName $ComputerName

Get-DPMCXAgent -ComputerName $ComputerName
Get-DPMCXAgentOwner -ComputerName $ComputerName

# Get active computer accounts from Active Directory who is running a server operating system
  $Date = Get-Date
  $InactiveComputerObjectThresholdInDays = '15'
  $Servers =  Get-ADComputer -LDAPFilter "(&(objectCategory=computer)(operatingSystem=Windows Server*)(!serviceprincipalname=*MSClusterVirtualServer*))" -Properties description,lastlogontimestamp,operatingsystem | 
  Where-Object {[datetime]::FromFileTime($_.lastlogontimestamp) -gt $Date.AddDays(-$InactiveComputerObjectThresholdInDays)} |  
  Select-Object -Property @{name='computername';e={$_.name}},operatingsystem |
  Sort-Object -Property computername
  
# Retrieve all computers who has DPM installed
  $DPMComputers = $Servers | Test-DPMCXComputer | Where-Object IsInstalled

  # Inspect the output
  $DPMComputers | Out-GridView

  $DPMComputers | group FriendlyVersionName -NoElement | sort count -Descending | ft -AutoSize

  $DPMComputers | Where-Object IsDPMServer

  # Get owner information from the DPM agents
  $DPMComputers | Where-Object IsDPMServer -eq $false | Get-DPMCXAgentOwner


$DPMServer = 'DEMODPM02'

Get-DPMCXAlert -DpmServerName $DPMServer

Get-DPMCXSizingBaseline

Get-DPMCXVersion -ListVersion
Get-DPMCXVersion -ListVersion | Out-GridView

Get-DPMCXServerConfiguration -DpmServerName $DPMServer

Get-DPMCXRecoveryPointStatus -DpmServerName $DPMServer

Get-DPMCXRecoveryPointStatus -DpmServerName $DPMServer -OlderThan (Get-Date).AddDays(-2)

$DPMServerADSecurityGroup = 'DPM_Servers'
$DPMServers = Get-ADGroupMember -Identity $DPMServerADSecurityGroup | Select-Object -ExpandProperty name
$DPMRecoveryPointStatus = Get-DPMCXRecoveryPointStatus -DpmServerName $DPMServers -Verbose
$DPMRecoveryPointStatus | ogv

$DPMServerConfigurationStatus = Get-DPMCXServerConfiguration -DpmServerName $DPMServers -Verbose
$DPMServerConfigurationStatus | ogv

New-DPMCXRecoveryPointStatusReport -DpmServerName $DPMServers -OlderThan (Get-Date).AddDays(-1) -MailFrom 'DPM Servers <dpm@firma.no>' -MailTo jan.egil.ring@crayon.com -SMTPServer mail.firma.no

Get-DPMCXMARSVersion -ListVersion | fl
Get-DPMCXMARSVersion -ListVersion | ogv
Get-DPMCXMARSAgent -ComputerName $DPMServers

New-DPMCXServerConfigurationReport -DpmServerName $DPMServers -MailFrom 'DPM Servers <dpm@firma.no>' -MailTo jan.egil.ring@crayon.com -SMTPServer mail.firma.no -Verbose

New-DPMCXServerConfigurationReport -DpmServerName $DPMServers -MailFrom 'DPM Servers <dpm@firma.no>' -MailTo jan.egil.ring@crayon.com -SMTPServer mail.firma.no -Verbose


#region Tips and tricks

# Clear "A new version of Windows Azure Backup Agent is available"-events to remove notification in the DPM console about a new version og the Azure Backup Agent being available, even though the latest version is installed.
Invoke-Command -ComputerName $DPMServers -ScriptBlock {wevtutil cl CloudBackup}

#endregion