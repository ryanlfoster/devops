print 'Connecting to admin server....'
connect( 'weblogic', 'test4admin', 't3://$server:7001', adminServerName='AdminServer' )

currentAppDeployments=cmo.getAppDeployments()

for app in currentAppDeployments:
    stopApplication(app.getApplicationName())
    undeploy(app.getApplicationName())

disconnect()
exit()
