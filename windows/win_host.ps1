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

# Will use: Add-Computer and Remove-Computer
# NOTE: Cannot have both Workgroup and Domain set.
# Also specify state: to either join or unjoin
# options (-Options <JoinOptions>) can only be set with Domain and not Workgroup
# hostname (optional), can get current hostname and use that
# domain (optional), people could want to just rename hostname
# server (optional), specify name of a domain controller, default none
# user (optional) required if adding to domain
# pass (optional) required if adding to domain
# timezone (optional), could keep as is.  Determine how we should accept input,  Central Standard Time or CST (also case sensitive?)
# options (optional), Join options Ex. -Options "One, Or, More, Values"
# oupath (optional), Specifies an organizational unit for the domain account
# restart (optional), default not
# unsecure (optional), unsecure join (use -UnjoinDomainCredential instead of Local or Credential)
# workgroup (optional), default WORKGROUP
# -FORCE may be required to supresss user confirmation prompt
# MAYBE USE -WhatIf to test if command would pass or fail, then run.

$restart = $false
$domain = $false
$workgroup = $false

$params = Parse-Args $args;

$result = New-Object psobject @{
    win_host = New-Object psobject
    changed = $false
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
    $   oupath = ""
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
        $pass = $params.pass.toString() | ConvertTo-SecureString -asPlainText -Force
        $creds = New-Object System.Management.Automation.PSCredential($user, $pass)
        $credential = "-Credential $creds"
        $unjoincredential = "-UnjoinDomainCredential $creds"
    }
    Catch {
        Fail-Json $result "error creating PSCredential object from provided credentials, User: $user Password: $params.pass"
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
