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
    $computername = "-ComputerName '$hostname'"

    If ($hostname.length -eq 1) {
        $newname = "-NewName '$hostname'"
    }
}

If ($params.domain) {
    $domain = $params.domain.toString()
    Set-Attr $result.win_host "domain" $domain
    $domain = "-DomainName '$domain'"

    If ($params.server) {
        $server = $params.server.toString()
        Set-Attr $result.win_host "server" $server
        $server = "-Server '$server'"
    }
    Else {
        $server = ""
    }

    If ($params.options) {
        $options = $params.options.toString()
        Set-Attr $result.win_host "options" $options
        $options = "-Options '$options'"
    }
    Else {
        $options = ""
    }

    If ($params.oupath) {
        $oupath = $params.oupath.toString()
        Set-Attr $result.win_host "oupath" $oupath
        $oupath = "-OUPath '$oupath'"
    }
    Else {
        $oupath = ""
    }

    If (($params.unsecure -eq "true") -or ($params.unsecure -eq "yes")) {
        $unsecure = $params.unsecure.toString()
        Set-Attr $result.win_host "unsecure" $unsecure
        $unsecure = "-Unsecure"
    }
    Else {
        $unsecure = ""
    }
}
Else {
    $domain = ""
}

If ($params.workgroup) {
    $workgroup = $params.workgroup.toString()
    Set-Attr $result.win_host "workgroup" $workgroup
    $workgroup = "-WorkgroupName '$workgroup'"
}
Else {
    $workgroup = ""
}

If ($params.user -and $params.pass) {
    Try {
        $user = $params.user.toString()
        $pass = $params.pass.toString()
        $credential = "-Credential"
        $unjoincredential = "-UnjoinDomainCredential"
        $local = "-LocalCredential"
    }
    Catch {
        Fail-Json $result "error creating PSCredential object from provided credentials, User: $user Password: $pass"
    }
}

If (($params.restart -eq "true") -or ($params.restart -eq "yes")) {
    $restart = "-Restart"
    Set-Attr $result.win_host "restart" "true"
}
Else {
    Set-Attr $result.win_host "restart" "false"
    $restart = ""
}

If ($params.state -eq "present") {
    $state = $true
    Set-Attr $result.win_host "state" "present"
}
ElseIf ($params.state -eq "absent") {
    $state = $false
    Set-Attr $result.win_host "state" "absent"
}

# If just hostname was provided and not credentials and there was only one hostname just rename computer
If ($hostname -and -Not ($credential) -and -Not ($domain -Or $workgroup) -and $hostname.length -eq 1) {
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
            # Check if already a member of the domain
            If ((gwmi win32_computersystem).domain -eq $domain) {
                Set-Attr $result "The computer(s) $hostname is already a member of $domain."
                $member = $true
            }
            If ($workgroup -and -Not ($member)) {
                Try {
                    # If only one hostname was entered, use the new computer parameter to do a rename and domain join in one step
                    If ($newname) {
                        $computername = $newname
                    }
                    $cmd = "Add-Computer $computername $workgroup $credential (New-Object System.Management.Automation.PSCredential $($user),(convertto-securestring $($pass) -asplaintext -force)) $restart -Force"
                    Invoke-Expression $cmd
                    $cmd = "Add-Computer $computername $domain $credential (New-Object System.Management.Automation.PSCredential $($user),(convertto-securestring $($pass) -asplaintext -force)) $server $options $oupath $unsecure $restart -Force"
                    Invoke-Expression $cmd
                    $result.changed = $true
                }
                Catch {
                    Fail-Json $result "an error occured when adding $hostname to $workgroup, and then adding to $domain. command attempted --> $cmd"
                }
            }
            Else {
                Try{
                    If (-Not ($member)) {
                        # If only one hostname was entered, use the new computer parameter to do a rename and domain join in one step
                        If ($newname) {
                            $computername = $newname
                        }
                        $cmd = "Add-Computer $computername $domain $credential (New-Object System.Management.Automation.PSCredential $($user),(convertto-securestring $($pass) -asplaintext -force)) $server $options $oupath $unsecure $restart -Force"
                        Invoke-Expression $cmd
                        $result.changed = $true
                    }
                }
                Catch {
                    Fail-Json $result "an error occured when adding $computername to $domain.  command attempted --> $cmd"
                }
            }
        }
        ElseIf (-Not ($state)) {
            If ($workgroup) {
                Try {
                    $cmd = "Remove-Computer $computername $workgroup $unjoincredential (New-Object System.Management.Automation.PSCredential $($user),(convertto-securestring $($pass) -asplaintext -force)) $restart -Force"
                    Invoke-Expression $cmd
                    $result.changed = $true
                }
                Catch {
                    Fail-Json $result "an error occured when unjoining $hostname from domain. command attempted --> $cmd"
                }
            }
            Else {
                Fail-Json $result "missing required param: workgroup.  A workgroup must be specified to join after unjoining $domain"
            }
        }
        Else {
            Fail-Json $result "missing a required argument for domain joining/unjoining: state"
        }
    }
    Else {
        Fail-Json $result "missing a required argument for domain joining/unjoining: user and/or pass"
    }
}
# Workgroup change only
ElseIf ($hostname -and $workgroup -and (-Not $domain)){
    If ($credential) {
        Try{
            $cmd = "Add-Computer $computername $workgroup $credential (New-Object System.Management.Automation.PSCredential $($user),(convertto-securestring $($pass) -asplaintext -force)) $restart -Force"
            Invoke-Expression $cmd
             $result.changed = $true
        }
        Catch {
            Fail-Json $result "an error occured when adding $computername to $workgroup.  command attempted --> $cmd"
        }
    }
    Else {
        Fail-Json $result "missing a required argument for workgroup joining/unjoining: user or pass"
    }
}
Else {
    Fail-Json $result "An error occured, and no commands were ever executed."
}


Exit-Json $result;
