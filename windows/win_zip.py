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
module: win_zip
version_added: ""
short_description: Zips file or directory on the Windows node
description:
     - Zips the specified local file or directory on the Windows node. Depends on PSCX (PowerShell Community Extensions).  PSCX is downloaded and installed if it is not found.  If found it imports the module and continues. For information on PSCX visit https://pscx.codeplex.com/.
options:
  src:
    description:
      - Local file or directory (provide absolute path)
    required: true
    default: null
    aliases: []
  dest:
    description:
      - Destination of compressed zip file (provide absolute path) and name of desired output file.  If a .zip extension is not present, it will be detected and added automatically. The path specified must exist, the basename doesn't need to exist.
    required: true
    default: null
    aliases: []
  rm:
    description:
      - Remove the (unzipped) src file, after zipping
    required: no
    choices:
      - true
      - false
      - yes
      - no
    default: false
    aliases: []
author: Phil Schwartz
'''

EXAMPLES = '''
# Zips directory on Windows Host and saves as SRC.zip
$ ansible -i hosts -m win_zip -a "src=C:\\Users\Administrator\SRC dest=C:\\Users\Administrator\SRC.zip rm=true" all
# Zips a file on Windows Host and saves as test.txt.zip
$ ansible -i hosts -m win_zip -a "src=C:\\Users\Phil\xfile.txt dest=C:\\xfile" all
# Playbook example
---
- name: Zip Logs
  hosts: all
  gather_facts: false
  tasks:
  - name: win_zip the inet log directory and then remove the src directory after completion
    win_zip:
      src: 'C:\\inetpub\wwwroot\Logs'
      dest: 'C:\\Logs\1-1-15.ServerLogs.zip'
      rm: true
'''
