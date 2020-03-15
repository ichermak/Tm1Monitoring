$Tm1MailConfigPath = "$PSScriptRoot\MailConfig.JSON"
$Tm1MailFrom = (Get-Content $Tm1MailConfigPath | ConvertFrom-Json).from
$Tm1MailTo = (Get-Content $Tm1MailConfigPath | ConvertFrom-Json).to
$Tm1MailPriority = (Get-Content $Tm1MailConfigPath | ConvertFrom-Json).priority
$Tm1MailSmtpServer = (Get-Content $Tm1MailConfigPath | ConvertFrom-Json).smtpserver
$Tm1MailPort = [int](Get-Content $Tm1MailConfigPath | ConvertFrom-Json).port
$Tm1MailUseSsl = (Get-Content $Tm1MailConfigPath | ConvertFrom-Json).usessl | % {if($_ -eq "True"){$true} else{$false}}
$Tm1MailUser = (Get-Content $Tm1MailConfigPath | ConvertFrom-Json).user
$Tm1MailPassword = ConvertTo-SecureString (Get-Content $Tm1MailConfigPath | ConvertFrom-Json).password -AsPlainText -Force 
$Tm1MailCredential = New-Object System.Management.Automation.PSCredential ($Tm1MailUser, $Tm1MailPassword)
$Tm1MailSubject = "[ALERT] - Tm1Monitoring - An issue occurred with the memory use"

$Tm1sServiceKeyWord = 'IBM Cognos TM1 Server'
$Tm1MemoryThreshold = 20/100

$Tm1sProcessTotalMemory = 0
$Tm1SendAlerte = $false
try {
    $Tm1sServices = Get-CimInstance -ClassName Win32_Service -Filter "DisplayName LIKE '$Tm1sServiceKeyWord%'"
    $Tm1sProcessIds = $Tm1sServices | Select-Object -ExpandProperty ProcessId
    foreach ($Tm1sProcessId in $Tm1sProcessIds) {
        $Tm1sProcess = Get-Process -Id $Tm1sProcessId
        $Tm1sServiceName = $Tm1sServices.Name
        $Tm1sProcessMemory = $Tm1sProcess.WorkingSet
        $Tm1sProcessTotalMemory = $Tm1sProcessTotalMemory + $Tm1sProcessMemory
        $Tm1MailSubBody01 = "
        $Tm1MailSubBody01 
        <tr>
            <td> $Tm1sServiceName </td>
            <td> $Tm1sProcessId </td>
            <td> $($Tm1sProcessMemory / 1MB) </td>
        </tr>
        "
    }
    $Tm1FreeMemory = (Get-CimInstance -ClassName Win32_OperatingSystem).FreePhysicalMemory
    $Tm1FreeMemoryRate = $Tm1FreeMemory / $Tm1sProcessTotalMemory
    if($Tm1FreeMemoryRate -lt $Tm1MemoryThreshold){
        $Tm1SendAlerte = $true
    }
    if($Tm1SendAlerte){
        $Tm1MailBodyAsHtml = $true
        $Tm1MailBody = "
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset='utf-8' />
                <style>
                    table
                    {
                        border-collapse: collapse;
                    }
                    td, th
                    {
                        border: 1px solid black;
                    }
                </style>
            </head>
            <body>
                <p>
                    Free memory rate ($($Tm1FreeMemoryRate.tostring('P'))) is below the tolerated threshold ($($Tm1MemoryThreshold.tostring('P'))): <br/>
                </p>
                <table>
                    <thead>
                        <tr>
                            <th> Service Name </th>
                            <th> Process Id </th>
                            <th> Process Memory (MB) </th>
                        </tr>
                    </thead>
                    <tbody>
                        $Tm1MailSubBody01
                    </tbody>
                </table>
            </body>
            "
    }
}

catch {
    $Tm1SendAlerte = $true
    $Tm1MailBodyAsHtml = $false
    $Tm1MailBody = "$($_.Exception.Message)`n$($_.ErrorDetails.Message)"
    Write-Error "$($_.Exception.Message)`n$($_.ErrorDetails.Message)"
}

finally{
    If($Tm1SendAlerte){
        $Tm1Params = @{
            From = $Tm1MailFrom
            To = $Tm1MailTo
            Subject = $Tm1MailSubject
            Priority = $Tm1MailPriority
            Body = $Tm1MailBody
            BodyAsHtml = $Tm1MailBodyAsHtml
            SmtpServer = $Tm1MailSmtpServer
            Port = $Tm1MailPort
            UseSsl = $Tm1MailUseSsl
            Credential = $Tm1MailCredential
        }
        Send-MailMessage @Tm1Params
    }
}