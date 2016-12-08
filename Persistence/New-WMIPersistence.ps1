function New-WMIPersistence {
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