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

# Will use: Add-Computer
# NOTE: Cannot have both Workgroup and Domain set.
# Also specify action: unjoin to use -UnjoinDomainCredential, also this can only be used with Domain set and not Workgroup, "Use this parameter when you are moving computers to a different domain"
# Also options (-Options <JoinOptions>) can only be set with Domain and not Workgroup
# host (optional), can get current hostname and use that
# domain (optional), people could want to just rename host
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
    win_join = New-Object psobject
    changed = $false
}

If ($params.timezone) {
    Try {
        C:\Windows\System32\tzutil /s $params.timezone.toString()
    }
    Catch {
        Fail-Json $result "Error setting timezone to: $params.timezone : Example: Central Standard Time"
    }
}

If ($params.host) {
    $hostname = $params.host.toString()
    Set-Attr $result.win_join "host" $host.toString()
}

If ($params.domain -and (-Not($params.workgroup))) {
    $domain = $params.domain.toString()
    Set-Attr $result.win_join "domain" $domain.toString()
}
ElseIf ($params.workgroup -and (-Not($params.domain))) {
    $workgroup = $params.workgroup.toString()
}
Else {
    Fail-Json $result "Error with domain/workgroup params. Either both were found or neither were specified."
}

If ($params.server) {
    $server = $params.server.toString()
    Set-Attr $result.win_join "server" $server.toString()
}

If ($params.user -and $params.pass) {
    Try {
        $pass = $params.pass.toString() | ConvertTo-SecureString -asPlainText -Force
        $creds = New-Object System.Management.Automation.PSCredential($user, $pass)
    }
    Catch {
        Fail-Json $result "error creating PSCredential object from provided credentials, User: $user Password: $params.pass"
    }
}

If ($params.options) {
    $options = $params.options.toString()
    Set-Attr $result.win_join "options" $options.toString()
}

If ($params.oupath) {
    $oupath = $params.oupath.toString()
    Set-Attr $result.win_join "oupath" $oupath.toString()
}

If (($params.unsecure -eq "true") -or ($params.unsecure -eq "yes")) {
    $unsecure = $true
    Set-Attr $result.win_join "unsecure" $unsecure.toString()
}

# Concat correct flags and options to Add-Computer command











If (($params.restart -eq "true") -or ($params.restart -eq "yes")) {
    Restart-Computer -Force
}

Set-Attr $result.win_join "restart" $restart.toString()

Exit-Json $result;