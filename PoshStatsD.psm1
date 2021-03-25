using namespace System.Net
using namespace System.Net.Sockets
using namespace System.Text

function Send-StatsD {
    <#
    .SYNOPSIS
        Send a message to StatsD.

    .EXAMPLE
        Send-StatsD localhost "foo:1|c"

    .EXAMPLE
        Send-StatsD localhost -Port 8125 "foo:1|c"
    #>
    [CmdletBinding()]
    param (
        # The address of the StatsD server.
        [Parameter(Position = 0, Mandatory = $true)]
        [String]
        $Address,

        # The listening port for StatsD.
        [Double]
        $Port = 8125,
        
        # The message to send.
        [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $Message
    )
    process {
        $addressFamily = [AddressFamily]::InterNetwork
        $socketType = [SocketType]::Dgram
        $protocolType = [ProtocolType]::Udp
        $socket = New-Object Socket $addressFamily, $socketType, $protocolType

        # Ignore name resolution failures and fail silently.
        try {
            $ip = [Dns]::GetHostAddresses($Address) | Select-Object -First 1
        } catch {
            return
        }

        $endpoint = New-Object IPEndPoint $ip, $Port

        $encoding = [Encoding]::ASCII
        $buffer = $encoding.GetBytes($Message)

        $socket.SendTo($buffer, $endpoint) | Out-Null
    } 
}

function Send-StatsDAll {
    param (
        [String]$Address,
        [Double]$Port,
        [String]$Stat,
        [String]$Value,
        [String]$Type,
        [Double]$SampleRate,
        [Array]$Tags
    )
    process {
        $message = "${Stat}:$Value|$Type"
        
        if ($SampleRate -gt 0 -and $SampleRate -lt 1) {
            $message = "$message|@$SampleRate"
        }

        if ($Tags -ne $null -and $Tags.Count -gt 0) {
            $combinedTags = [String]::Join($Tags, ",")
            $message = "$message|#$combinedTags"
        }

        Send-StatsD -Address $Address -Port $Port -Message $message
    }    
}

function Send-StatsDTiming {
    <#
    .SYNOPSIS
        Send a timing metric to StatsD.

    .EXAMPLE
        Send-StatsDTiming localhost "glork" 320

    .EXAMPLE
        Send-StatsDTiming localhost -Port 8125 "glork" 320 -SampleRate 0.1
    #>
    [CmdletBinding()]
    param (
        # The address of the StatsD server.
        [Parameter(Position = 0, Mandatory = $true)]
        [String]
        $Address,

        # The listening port for StatsD.
        [Double]
        $Port = 8125,
        
        # The name of the metric bucket.
        [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $Stat,
        
        # The time taken by the operation in milliseconds.
        [Parameter(Position = 2, Mandatory = $true)]
        [Double]
        $Time,
        
        # The percentage from 0-1.0 of the time that are events are being recorded.
        [Double]
        $SampleRate = 1
    )
    process {
        Send-StatsDAll -Address $Address -Stat $Stat -Value $Time -Type "ms" -SampleRate $SampleRate
    }    
}

function Send-StatsDIncrement {
    <#
    .SYNOPSIS
        Increment a StatsD counter by a specified amount.

    .EXAMPLE
        Send-StatsDIncrement localhost "glork"

    .EXAMPLE
        Send-StatsDIncrement localhost -Port 8125 "glork" -Value 2 -SampleRate 0.1
    #>
    [CmdletBinding()]
    param (
        # The address of the StatsD server.
        [Parameter(Position = 0, Mandatory = $true)]
        [String]
        $Address,

        # The listening port for StatsD.
        [Double]
        $Port = 8125,
        
        # The name of the metric bucket.
        [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $Stat,
        
        # The amount to increment the counter.
        [Double]
        $Value = 1,
        
        # The percentage from 0-1.0 of the time that the counter is sampled.
        [Double]
        $SampleRate = 1
    )
    process {
        Send-StatsDAll -Address $Address -Stat $Stat -Value $Value -Type "c" -SampleRate $SampleRate
    }    
}

function Send-StatsDDecrement {
    <#
    .SYNOPSIS
        Increment a StatsD counter by a specified amount.

    .EXAMPLE
        Send-StatsDDecrement localhost "glork"

    .EXAMPLE
        Send-StatsDDecrement localhost -Port 8125 "glork" -Value 2 -SampleRate 0.1
    #>
    [CmdletBinding()]
    param (
        # The address of the StatsD server.
        [Parameter(Position = 0, Mandatory = $true)]
        [String]
        $Address,

        # The listening port for StatsD.
        [Double]
        $Port = 8125,
        
        # The name of the metric bucket.
        [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $Stat,
        
        # The amount to decrement the counter.
        [Double]
        $Value = 1,
        
        # The percentage from 0-1.0 of the time that the counter is sampled.
        [Double]
        $SampleRate = 1
    )
    process {
        Send-StatsDAll -Address $Address -Stat $Stat -Value (-1 * $Value) -Type "c" -SampleRate $SampleRate
    }    
}

function Send-StatsDGauge {
    <#
    .SYNOPSIS
        Set a StatsD gague to the specified amount.

    .EXAMPLE
        Send-StatsDGauge localhost "glork"

    .EXAMPLE
        Send-StatsDGauge localhost -Port 8125 "glork" -Value 85 -SampleRate 0.1
    #>
    [CmdletBinding()]
    param (
        # The address of the StatsD server.
        [Parameter(Position = 0, Mandatory = $true)]
        [String]
        $Address,

        # The listening port for StatsD.
        [Double]
        $Port = 8125,
        
        # The name of the metric bucket.
        [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $Stat,
        
        # The current value of the gauge.
        [Parameter(Position = 2, Mandatory = $true)]
        [Double]
        $Value,
        
        # The percentage from 0-1.0 of the time that the gauge is sampled.
        [Double]
        $SampleRate = 1
    )
    process {
        Send-StatsDAll -Address $Address -Stat $Stat -Value $Value -Type "g" -SampleRate $SampleRate
    }    
}

Export-ModuleMember Send-StatsD
Export-ModuleMember Send-StatsDTiming
Export-ModuleMember Send-StatsDIncrement
Export-ModuleMember Send-StatsDDecrement
Export-ModuleMember Send-StatsDGauge