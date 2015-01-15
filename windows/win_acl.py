#!/usr/bin/python
# -*- coding: utf-8 -*-

# (c) 2014, Phil Schwartz <schwartzmx@gmail.com>
#
# This file is part of Ansible
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

# this is a windows documentation stub.  actual code lives in the .ps1
# file of the same name

DOCUMENTATION = '''
---
module: win_acl
version_added: ""
short_description: Set file/directory permissions for a system user or group.
description:
     - Add or remove rights/permissions for a given user or group for the specified src file or folder.
options:
  src:
    description:
      - File or Directory
    required: yes
    default: none
    aliases: []
  type:
    description:
      - Specify whether to allow or deny the rights specified
    required: yes
    choices:
      - allow
      - deny
    default: none
    aliases: []
  rights:
    description:
      - The rights/permissions that are to be allowed/denyed for the specified user or group for the given src file or directory.  Can be entered as a comma separated list (Ex. "Modify, Delete, ExecuteFile").  For more information on the choices see MSDN FileSystemRights Enumeration.
    required: yes
    choices:
      - AppendData
      - ChangePermissions
      - Delete
      - DeleteSubdirectoriesAndFiles
      - ExecuteFile
      - FullControl
      - ListDirectory
      - Modify
      - Read
      - ReadAndExecute
      - ReadAttributes
      - ReadData
      - ReadExtendedAttributes
      - ReadPermissions
      - Synchronize
      - TakeOwnership
      - Traverse
      - Write
      - WriteAttributes
      - WriteData
      - WriteExtendedAttributes
    default: none
    aliases: []
  inherit:
    description:
      - Inherit flags on the ACL rules.  Can be specified as a comma separated list (Ex. "ContainerInherit, ObjectInherit").  For more information on the choices see MSDN InheritanceFlags Enumeration.
    required: no
    choices:
      - ContainerInherit
      - ObjectInherit
      - None
    default: ContainerInherit, ObjectInherit
    aliases: []
  propagation:
    description:
      - Propagation flag on the ACL rules.  For more information on the choices see MSDN PropagationFlags Enumeration.
    required: no
    choices:
      - None
      - NoPropagateInherit
      - InheritOnly
    default: "None"
    aliases: []
author: Phil Schwartz
'''

EXAMPLES = '''
# Change Hostname and Timezone
$ ansible -i hosts -m win_host -a "hostname=MyNewComp timezone='Eastern Standard Time'" all
# Add hostnames to domain
$ ansible -i hosts -m win_host -a "hostname=Comp1,Comp2,Comp3 timezone='Central Standard Time' domain=host.com state=present server=xyz.host.com user=Admin pass=Secret restart=true" all

# Playbook example
# Configure a new machine
---
- name: config machine
  hosts: all
  gather_facts: false
  roles:
    - initRole
    - anotherRole

  tasks:
    - name: Rename host, change timezone, and add to domain
      win_host:
        hostname: "NewComputerName"
        domain: "domainName.com"
        workgroup: "WORKGROUP"
        restart: "yes"
        state: "present"
        user: "domainName\Administrator"
        pass: "SecretPassword"
        timezone: "Central Standard Time"
        server: "domaincontroller.domainName.com"
    - name: Wait for reboot
      local_action:
        module: wait_for
        host: "{{ inventory_hostname }}"
        port: "{{ansible_ssh_port|default(5986)}}"
        delay: "15"
        timeout: "10000"
        state: "started"
      sudo: yes
'''