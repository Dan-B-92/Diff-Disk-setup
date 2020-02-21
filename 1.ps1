<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2020 v5.7.172
	 Created on:   	13/02/2020 10:58
	 Created by:   	DanB
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		
#>

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }


$VHDPath = "C:\VMTemp\VHD\"
$VMPath = "C:\VMTemp\VM"
$ISOLocation = "C:\OS\SW_DVD9_Win_Svr_STD_Core_and_DataCtr_Core_2016_64Bit_English_-3_MLF_X21-30350.ISO"
$SizeBytes = 30GB
$VirtualSwitchName = "VSwitch1"
$StartupMemory = 1GB
$VMGeneration = 2



function Show-Menu
{
	param (
		[string]$Title = 'Please select an option from the list'
	)
	Clear-Host
	Write-Host "==========VM Creation========="
	Write-Host "1:  Set up a Child VHD + VM"
	Write-Host "2:  Set up a Parent VHD + VM"
	Write-Host "Q:  Quit"
}


do
{
	Show-Menu -Title "Restart VSS Writers"
	$Selection = Read-Host "Select an option fron the list"
	
	switch ($Selection)
	{
		'1'	{
			$CVMName = Read-Host -Prompt "Please enter a name for your Child VM"
			$Parentname = Read-Host -Prompt "Enter the name of your parent VM"
			$FullCVHDPath = "$VHDPath" + "\$CVMName\" + $CVMName + ".vhdx"
			$ChildVMHash = @{
				VMName			   = $CVMName
				Path			   = $VMPath
				Generation		   = $VMGeneration
				MemoryStartupBytes = $StartupMemory
				Switchname		   = $VirtualSwitchName
			}
			New-VM @ChildVMHash -Verbose
			$ParentVHDPath = Get-VMHardDiskDrive -VMName $Parentname | select Path -ExpandProperty Path| Out-String
			New-VHD -ParentPath $ParentVHDPath -Path $FullCVHDPath -Differencing
			Add-VMHardDiskDrive -VMName $CVMName -ControllerType SCSI -Path $FullCVHDPath
			Pause
		}'2'{
			$PVMName = Read-Host -Prompt "Please enter a name for your Parent VM"
			$FullPVHDPath = "$VHDPath"+"\$PVMName\"+$PVMName+".vhdx"
			$ParentVMHash = @{
				VMName 				= $PVMName
				Path  				= $VMPath
				Generation	   		= $VMGeneration
				MemoryStartupBytes 	= $StartupMemory
				NewVHDPath 			= $FullPVHDPath
				NewVHDSizeBytes 	= $SizeBytes
				Switchname 			= $VirtualSwitchName
			}
			New-VM @ParentVMHash
			Add-VMDvdDrive -VMName $PVMName -ControllerLocation 1 -Path $ISOLocation
			
			$PDVD = Get-VMDvdDrive Parent
			$PHD = Get-VMHardDiskDrive Parent
			Set-VMFirmware Parent -BootOrder $PDVD, $PHD
		}'Q' {
			return
		}
		


		
	}
}
until ($selection -eq 'q')



help New-VM -Full