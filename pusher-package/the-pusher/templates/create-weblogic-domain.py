#!/usr/bin/python
import os, sys
readTemplate('$baseDirectory/$appServer/wlserver_$appServerVersion/common/templates/domains/wls.jar')
cd('/Security/base_domain/User/weblogic')
cmo.setPassword('test4admin')
cd('/Server/AdminServer')
cmo.setName('AdminServer')
writeDomain('$baseDirectory/$appServer/EP')
closeTemplate()
exit()
