print 'Connecting to admin server....'
connect( 'weblogic', 'test4admin', 't3://$server:7001', adminServerName='AdminServer' )

print 'Deploying $currentContextPath...'
deploy('$currentContextPath', '$baseDirectory/$appServer/webapps/$currentContextPath/', targets='AdminServer', timeout=0)

print 'Starting $currentContextPath...'
startApplication('$currentContextPath')

print 'Disconnecting from admin server....'
disconnect()
exit()
