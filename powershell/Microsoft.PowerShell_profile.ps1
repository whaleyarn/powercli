# use vi to edit files
function vi ($File){
    $File = $File -replace “\\”, “/” -replace “ “, “\ “
    bash -c “vim $File”
    }

# auto complete name 
$VM_NAME = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    Get-VM -Name ${wordToComplete}* | Select-Object -ExpandProperty "Name" | Sort-Object
    }
Register-ArgumentCompleter -CommandName Pre-UpgradeVM, Post-UpgradeVM, Restore-UpgradeVM -ParameterName Name -ScriptBlock $VM_NAME
Register-ArgumentCompleter -CommandName Restart-VM, Restart-VMGuest, Start-VM, Stop-VM, Stop-VMGuest -ParameterName VM -ScriptBlock $VM_NAME

# bash style complete
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

# Define a function to get snapshot names
function Get-SnapshotNames {
    param(
        $VMName
    )

    # Get all snapshots for the given VM and sort them by creation date in descending order
    # Select only the Name property and return the list of names
    Get-Snapshot -VM $VMName | Sort-Object -Property Created -Descending | Select-Object -ExpandProperty Name
}

# Register argument completer for the Restore-UpgradeVM command and the SnapshotName parameter
Register-ArgumentCompleter -CommandName Restore-UpgradeVM -ParameterName SnapshotName -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    # Get the list of snapshot names for the VM specified by the Name parameter
    $snapshotNames = Get-SnapshotNames -VMName $fakeBoundParameters['Name']

    # Filter the snapshot names based on the current word being typed for auto-completion
    # Return the filtered list of snapshot names
    $snapshotNames | Where-Object { $_ -like "$wordToComplete*" }
}
