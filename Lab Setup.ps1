﻿<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2020 v5.7.172
	 Created on:   	22/02/2020 15:50
	 Created by:   	Dan
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }
[CmdletBinding]

$VHDPath = "D:\Hyper-V\VHD"
$VMPath = "D:\Hyper-V\VM"
$ISOLocation = "X:\ISO\Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO"
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
	Write-Host "1:  Set up a Parent VHD + VM"
	Write-Host "2:  Set up a Child VHD + VM"
	Write-Host "3:	Delete VM"
	Write-Host "4:	Delete ALL VMs"
	Write-Host "Q:  Quit"
}


do
{
	Show-Menu -Title "Restart VSS Writers"
	$Selection = Read-Host "Select an option fron the list"
	
	switch ($Selection)
	{
		'1'	{
			$PVMName = Read-Host -Prompt "Please enter a name for your Parent VM"
			$FullPVHDPath = "$VHDPath" + "\$PVMName\" + $PVMName + ".vhdx"
			$ParentVMHash = @{
				VMName			   = $PVMName
				Path			   = $VMPath
				Generation		   = $VMGeneration
				MemoryStartupBytes = $StartupMemory
				NewVHDPath		   = $FullPVHDPath
				NewVHDSizeBytes    = $SizeBytes
				Switchname		   = $VirtualSwitchName
			}
			New-VM @ParentVMHash
			Add-VMDvdDrive -VMName $PVMName -ControllerLocation 1 -Path $ISOLocation
			
			
		}'2'{
			$PDVD = Get-VMDvdDrive Parent
			$PHD = Get-VMHardDiskDrive Parent
			Set-VMFirmware Parent -BootOrder $PDVD, $PHD
			
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
			$ParentVHDPath = Get-VMHardDiskDrive -VMName $Parentname | select Path -ExpandProperty Path | Out-String
			New-VHD -ParentPath $ParentVHDPath -Path $FullCVHDPath -Differencing
			Add-VMHardDiskDrive -VMName $CVMName -ControllerType SCSI -Path $FullCVHDPath
			Pause
		}'3'{
			Write-Verbose "This will delete a single VM including VHD." -Verbose
			$DeleteSVM = Read-Host -Prompt "Enter the name of the VM that you want to delete"
			Write-Verbose "=====Files to be deleted======" -Verbose
			Get-ChildItem ($VHDPath + "\" + $DeleteSVM) | select Directory,Name 
			Get-ChildItem ($VMPath + "\" + $DeleteSVM) | select Directory,Name 
			pause
			$DeleteSVMConfirm = Read-Host -Prompt "Are you sure you want to delete $DeleteSVM? This will remove all files under $VHDPath and $VMPath for this VM. Type DELETE to confirm."
			pause
			if
			($DeleteSVMConfirm -eq "DELETE")
			{
				Remove-Item  ($VHDPath + "\" + $DeleteSVM),($VMPath + "\" + $DeleteSVM)  -Recurse -Verbose
			}
			else
			{
				Continue
			}
			
			
			
			
			
			
			
			
			
			
			
		
	}'Q' {
			return
		}
		
		
		
		
	}
}
until ($selection -eq 'q')
