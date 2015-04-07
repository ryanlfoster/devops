import sys, traceback

domainName="EP"
adminURL="t3://$server:7001"
adminUserName="weblogic"
adminPassword="test4admin"
customIdentityKeyStoreFileName="$appServerKeyStoreFileName"
customTrustKeyStoreFileName="$appServerTrustStoreFileName"
keyStorePassword="$appServerKeyStorePassword"

connect(adminUserName,adminPassword,adminURL)
edit()
startEdit()
cd('/Servers/AdminServer')
cmo.setCustomIdentityKeyStoreFileName(customIdentityKeyStoreFileName)
set('CustomIdentityKeyStorePassPhrase', keyStorePassword)
cmo.setCustomTrustKeyStoreFileName(customTrustKeyStoreFileName)
set('CustomTrustKeyStorePassPhrase', keyStorePassword)
cmo.setKeyStores('CustomIdentityAndCustomTrust')
cmo.setCustomIdentityKeyStoreType('JKS')
cmo.setCustomTrustKeyStoreType('JKS')
cd('/Servers/AdminServer/SSL/AdminServer')
cmo.setServerPrivateKeyAlias('epnet')
set('ServerPrivateKeyPassPhrase', keyStorePassword)
cd('/Servers/AdminServer/SSL/AdminServer')
cmo.setEnabled(true)
save()
try:
	activate()
except:
	apply(traceback.print_exception, sys.exc_info())
	dumpStack()
exit()
