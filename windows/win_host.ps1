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

$restart = $false
$domain = $false
$workgroup = $false

$params = Parse-Args $args;

$result = New-Object psobject @{
    win_host = New-Object psobject
    changed = $false
}

If ($PSVersionTable.PSVersion.Major -lt 4) {
    Fail-Json $result "Module win_host requires Powershell 4.0 or greater."
}

If ($params.timezone) {
    Try {
        C:\Windows\System32\tzutil /s $params.timezone.toString()
        $result.changed = $true
    }
    Catch {
        Fail-Json $result "Error setting timezone to: $params.timezone : Example: Central Standard Time"
    }
}

# Can enter just one, or as a comma seperated list
If ($params.hostname) {
    $hostname = $params.hostname.toString().split(",")
    Set-Attr $result.win_host "hostname" $hostname.toString()
    $computername = "-ComputerName $hostname"
}

If ($params.domain -and (-Not($params.workgroup))) {
    $domain = "-DomainName $params.domain.toString()"
    Set-Attr $result.win_host "domain" $domain.toString()

    If ($params.server) {
        $server = "-Server $params.server.toString()"
        Set-Attr $result.win_host "server" $server.toString()
    }
    Else {
        $server = ""
    }

    If ($params.options) {
        $options = "-Options $params.options.toString()"
        Set-Attr $result.win_host "options" $options.toString()
    }
    Else {
        $options = ""
    }

    If ($params.oupath) {
        $oupath = "-OUPath $params.oupath.toString()"
        Set-Attr $result.win_host "oupath" $oupath.toString()
    }
    Else {
        $oupath = ""
    }

    If (($params.unsecure -eq "true") -or ($params.unsecure -eq "yes")) {
        $unsecure = "-Unsecure"
        Set-Attr $result.win_host "unsecure" $unsecure.toString()
    }
    Else {
        $unsecure = ""
    }
}

If ($params.workgroup -and (-Not($params.domain))) {
    $workgroup = "-WorkgroupName $params.workgroup.toString()"
}

If ($params.user -and $params.pass) {
    Try {
        $user = $params.user.toString()
        $pass = $params.pass.toString()
        $spass = $pass | ConvertTo-SecureString -asPlainText -Force
        $creds = New-Object System.Management.Automation.PSCredential($user, $spass)
        $credential = "-Credential $creds"
        $unjoincredential = "-UnjoinDomainCredential $creds"
    }
    Catch {
        Fail-Json $result "error creating PSCredential object from provided credentials, User: $user Password: $pass"
    }
}

If (($params.restart -eq "true") -or ($params.restart -eq "yes")) {
    $restart = "-Restart"
    Set-Attr $result.win_host "restart" $restart.toString()
}
Else {
    Set-Attr $result.win_host "restart" $restart.toString()
    $restart = ""
}

If ($params.state -eq "present") {
    $params.state = $true
}
ElseIf ($params.state -eq "absent") {
    $params.state = $false
}

# If just hostname was provided and not a user and pass and there was only one hostname just rename computer
If ($hostname -and -Not ($user -and $pass) -and $hostname.length -eq 1) {
    Rename-Computer $hostname[0]
    $result.changed = $true
    If ($restart) {
        Restart-Computer -Force
    }
}
# Domain
ElseIf ($hostname -and $domain){
    If ($credential) {
        If ($state) {
            Try{
                $cmd = "Add-Computer $computername $domain $credential $server $options $oupath $unsecure $restart -Force"
                Invoke-Expression $cmd
                $result.changed = $true
            }
            Catch {
                Fail-Json $result "an error occured when adding $computername to $domain.  command attempted --> $cmd"
            }
        }
        ElseIf (-Not $state) {
            Try {
                $cmd = "Remove-Computer $computername $unjoincredential $restart -Force"
                Invoke-Expression $cmd
                $result.changed = $true
            }
            Catch {
                Fail-Json $result "an error occured when unjoining $hostname from domain. command attempted --> $cmd"
            }
        }
        Else {
            Fail-Json $result "missing a required argument for domain joining/unjoining: state"
        }
    }
    Else {
        Fail-Json $result "missing a required argument for domain joining/unjoining: user or pass"
    }
}
# Workgroup
ElseIf ($hostname -and $workgroup){
    If ($credential) {
        If ($state) {
            Try{
                $cmd = "Add-Computer $computername $workgroup $credential $restart -Force"
                Invoke-Expression $cmd
                $result.changed = $true
            }
            Catch {
                Fail-Json $result "an error occured when adding $computername to $workgroup.  command attempted --> $cmd"
            }
        }
        ElseIf (-Not $state) {
            Try {
                $cmd = "Remove-Computer $computername $workgroup $unjoincredential $restart -Force"
                Invoke-Expression $cmd
                $result.changed = $true
            }
            Catch {
                Fail-Json $result "an error occured when unjoining $computername and moving to $workgroup.  command attempted --> $cmd"
            }
        }
        Else {
            Fail-Json $result "missing a required argument for workgroup joining/unjoining: state"
        }
    }
    Else {
        Fail-Json $result "missing a required argument for workgroup joining: user or pass"
    }
}
Else {
    Fail-Json $result "An error occured, and no commands were ever executed"
}


Exit-Json $result;
