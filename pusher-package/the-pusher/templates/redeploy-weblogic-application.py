print 'Connecting to admin server....'
connect( 'weblogic', 'test4admin', 't3://$server:7001', adminServerName='AdminServer' )
print 'Deploying....'
redeploy('$currentContextPath', '$baseDirectory/$appServer/webapps/$currentContextPath/', targets='AdminServer')
startApplication('$currentContextPath')
print 'Disconnecting from admin server....'
disconnect()
exit()
