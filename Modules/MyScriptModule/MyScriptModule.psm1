function Login-VIServer {

    <#
    .SYNOPSIS
        Import PSCredential Then connect to VIServer

    .DESCRIPTION
        Import PSCredential Then connect to VIServer

    .PARAMETER Name
        The XML file Name

    .PARAMETER Server
        Which to connect , default is $Name.home.org

    .EXAMPLE
        Login-VIServer -Name vc -Server 192.168.20.231

    .EXAMPLE
        Login-VIServer -Name v1

    .INPUTS
        String

    .OUTPUTS
        PSCustomObject

    .NOTES
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String]
        $Name,

        [string]$Server = $Name + ".home.arpa",
        $XMLFile = "/script/$Name.xml"
    )
    $VICredential = Import-CliXml -Path $XMLFile
    Connect-VIServer -Server $Server -Credential $VICredential

}

# manage snapshot for upgrade vm
function Pre-UpgradeVM {

    <#
    .SYNOPSIS
        Make a snapshot for update VM

    .DESCRIPTION
        Make a snapshot for update VM

    .PARAMETER Name
        The VM Name

    .EXAMPLE
        Pre-UpgradeVM -Name gitlab

    .INPUTS
        String

    .OUTPUTS
        PSCustomObject

    .NOTES
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String]
        $Name,

        [String]$SnapName = $(Get-Date -Format "yyyy-MM-dd")
    )
    New-Snapshot -Name $SnapName -VM $Name

}

function Post-UpgradeVM {

    <#
    .SYNOPSIS
        Delete snapshot for update VM

    .DESCRIPTION
        Delete a snapshot for update VM

    .PARAMETER Name
        The VM Name

    .EXAMPLE
        Post-UpgradeVM -Name gitlab

    .INPUTS
        String

    .OUTPUTS
        PSCustomObject

    .NOTES
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String]
        $Name
    )
    $snap = Get-Snapshot -VM $Name
    Remove-Snapshot -Snapshot $snap -Confirm:$false
}

function Restore-UpgradeVM {

    <#
    .SYNOPSIS
        Restore a snapshot for update VM
    
    .DESCRIPTION
        Restore a snapshot for update VM
    
    .PARAMETER Name
        The VM Name
    
    .EXAMPLE
        Post-UpgradeVM -Name gitlab
    
    .INPUTS
        String
    
    .OUTPUTS
        PSCustomObject
    
    .NOTES
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String]
        $Name,
        $SnapshotName
    )

    $vm = Get-VM -Name $Name

    # Get the snapshot to restore based on the input parameter or the most recent snapshot by default
    if ($SnapshotName) {
        $snap = $SnapshotName
    } else {
        $snap = Get-Snapshot -VM $vm | Sort-Object -Property Created -Descending | Select -First 1
    }

    # Restore the VM to the specified snapshot and start it
    Set-VM -VM $vm -Snapshot $snap -Confirm:$false
    Start-VM $Name
    }
    
function Get-SortedVMSnapshots {
    <#
    .SYNOPSIS
    Retrieves all snapshots for all VMs and sorts them by VM name.

    .DESCRIPTION
    This function gets all virtual machines, retrieves their snapshots, and returns a sorted list of snapshots based on VM name.

    .EXAMPLE
    $snapshots = Get-SortedVMSnapshots
    $snapshots | Format-Table -AutoSize

    This example retrieves all VM snapshots, sorts them by VM name, and displays the result in a table format.

    .EXAMPLE
    Get-SortedVMSnapshots | Export-Csv -Path "VMSnapshots.csv" -NoTypeInformation

    This example retrieves all VM snapshots, sorts them by VM name, and exports the result to a CSV file.

    .EXAMPLE
    Get-SortedVMSnapshots | Where-Object { $_.SizeMB -gt 1000 } | Format-Table -AutoSize

    This example retrieves all VM snapshots, sorts them by VM name, filters for snapshots larger than 1GB, and displays the result in a table format.

    .NOTES
    Requires an active connection to a vCenter server before running this function.
    #>

    [CmdletBinding()]
    param()

    # Get all virtual machines
    $vms = Get-VM

    # Create an empty array to store results
    $results = @()

    # Iterate through each virtual machine
    foreach ($vm in $vms) {
        # Get all snapshots for the virtual machine
        $snapshots = Get-Snapshot -VM $vm

        # If the VM has snapshots, add them to the results array
        if ($snapshots) {
            foreach ($snapshot in $snapshots) {
                $results += [PSCustomObject]@{
                    VMName = $vm.Name
                    SnapshotName = $snapshot.Name
                    Created = $snapshot.Created
                    SizeMB = [math]::Round($snapshot.SizeMB, 2)
                }
            }
        }
    }

    # Sort results by VM name
    $sortedResults = $results | Sort-Object VMName

    # Return the sorted results
    return $sortedResults
}

function Get-SortedVMStorage {
    [CmdletBinding()]
    param ()

    Write-Verbose "Retrieving all VMs..."

    $vms = Get-VM

    Write-Verbose "Processing each VM..."

    $results = foreach ($vm in $vms) {
        try {
            $vmView = Get-View $vm.Id -ErrorAction Stop
            $vmUsageGB = [math]::Round($vm.UsedSpaceGB, 2)

            [PSCustomObject]@{
                VMName      = $vm.Name
                UsedSpaceGB = $vmUsageGB
                VMXPath     = $vmView.Config.Files.VmPathName
            }
        } catch {
            Write-Error "Failed to process VM '$($vm.Name)': $_"
        }
    }

    Write-Verbose "Sorting results by UsedSpaceGB..."

    $results | Sort-Object -Property UsedSpaceGB -Descending
}
