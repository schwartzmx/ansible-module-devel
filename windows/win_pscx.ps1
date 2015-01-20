#!powershell
# This file is part of Ansible
#
# Copyright 2014, Phil Schwartz <schwartzmx@gmail.com>
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

# WANT_JSON
# POWERSHELL_COMMON

$params = Parse-Args $args;

$result = New-Object psobject @{
    win_pscx = New-Object psobject
    changed = $false
}

# Requires PSCX, will be installed if it isn't found
# Pscx-3.2.0.msi
$url = "http://download-codeplex.sec.s-msft.com/Download/Release?ProjectName=pscx&DownloadId=923562&FileTime=130585918034470000&Build=20959"
$dest = "C:\Pscx-3.2.0.msi"
$version = "3.2.0"

# Check if PSCX is installed
$list = Get-Module -ListAvailable
# If not download it and install
If (-Not ($list -match "PSCX")) {
    # Try install with chocolatey
    Try {
        cinst -force PSCX
        $choco = $true
        # Give it a chance to install, so that it can be imported
        sleep 10
    }
    Catch {
        $choco = $false
    }
    # install from downloaded msi if choco failed or is not present
    If ($choco -eq $false) {
        Try {
            $client = New-Object System.Net.WebClient
            $client.DownloadFile($url, $dest)
        }
        Catch {
            Fail-Json $result "Error downloading PSCX from $url and saving as $dest"
        }
        Try {
            msiexec.exe /i $dest /qb
            # Give it a chance to install, so that it can be imported
            sleep 10
        }
        Catch {
            Fail-Json $result "Error installing $dest"
        }
    }
    Set-Attr $result.win_zip "pscx_status" "pscx was installed"
    $installed = $true
}
Else {
    Set-Attr $result.win_zip "pscx_status" "present"
}

# Import
Try {
    If ($installed) {
        Import-Module 'C:\Program Files (x86)\Powershell Community Extensions\pscx3\pscx\pscx.psd1'
    }
    Else {
        Import-Module PSCX
    }
}
Catch {
    Fail-Json $result "Error importing module PSCX"
}

If ($params.cmd) {
    $cmdlet = $params.cmd.split(" ")[$params.cmd.length - 1]
    # Check that it is a valid cmdlet
    $list = Get-Command -Module PSCX
    $match = $list -match $cmdlet
    If (-Not ($match)) {
        Fail-Json $result "The provided cmdlet/function: $cmdlet was not found in module PSCX $version."
        $response = "No command executed"
    }
    $response = Invoke-Expression $cmd
    $result.changed = $true
}
Else {
    $response = "No command executed"
}

If ($response) {
    Set-Attr $result.win_pscx "response" $response.toString()
}


Exit-Json $result;


