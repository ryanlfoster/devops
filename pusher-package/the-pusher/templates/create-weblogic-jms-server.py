
adminURL="t3://$server:7001"
adminUserName="weblogic"
adminPassword="test4admin"

connect(adminUserName, adminPassword, adminURL)

edit()

startEdit()

cd('/')
cmo.createJMSServer('Weblogic-JMS-Server')

cd('/Deployments/Weblogic-JMS-Server')
set('Targets',jarray.array([ObjectName('com.bea:Name=AdminServer,Type=Server')], ObjectName))

cd('/')
cmo.createJMSSystemResource('Weblogic-JMS-Module')

cd('/SystemResources/Weblogic-JMS-Module')
set('Targets',jarray.array([ObjectName('com.bea:Name=AdminServer,Type=Server')], ObjectName))
cmo.createSubDeployment('Weblogic-JMS-Subdeployment')

cd('/SystemResources/Weblogic-JMS-Module/SubDeployments/Weblogic-JMS-Subdeployment')
set('Targets',jarray.array([ObjectName('com.bea:Name=AdminServer,Type=Server')], ObjectName))

cd('/JMSSystemResources/Weblogic-JMS-Module/JMSResource/Weblogic-JMS-Module')
cmo.createConnectionFactory('Weblogic-Connection-Factory')

cd('/JMSSystemResources/Weblogic-JMS-Module/JMSResource/Weblogic-JMS-Module/ConnectionFactories/Weblogic-Connection-Factory')
cmo.setJNDIName('jms/JMSConnectionFactory')

cd('/JMSSystemResources/Weblogic-JMS-Module/JMSResource/Weblogic-JMS-Module/ConnectionFactories/Weblogic-Connection-Factory/SecurityParams/Weblogic-Connection-Factory')
cmo.setAttachJMSXUserId(false)

cd('/JMSSystemResources/Weblogic-JMS-Module/JMSResource/Weblogic-JMS-Module/ConnectionFactories/Weblogic-Connection-Factory/ClientParams/Weblogic-Connection-Factory')
cmo.setClientIdPolicy('Restricted')
cmo.setSubscriptionSharingPolicy('Exclusive')
cmo.setMessagesMaximum(10)

cd('/JMSSystemResources/Weblogic-JMS-Module/JMSResource/Weblogic-JMS-Module/ConnectionFactories/Weblogic-Connection-Factory/TransactionParams/Weblogic-Connection-Factory')
cmo.setXAConnectionFactoryEnabled(false)

cd('/SystemResources/Weblogic-JMS-Module/SubDeployments/Weblogic-JMS-Subdeployment')
set('Targets',jarray.array([ObjectName('com.bea:Name=AdminServer,Type=Server')], ObjectName))

cd('/JMSSystemResources/Weblogic-JMS-Module/JMSResource/Weblogic-JMS-Module/ConnectionFactories/Weblogic-Connection-Factory')
cmo.setSubDeploymentName('Weblogic-JMS-Subdeployment')


cd('/JMSSystemResources/Weblogic-JMS-Module/JMSResource/Weblogic-JMS-Module')
cmo.createTopic('ep.orders')

cd('/JMSSystemResources/Weblogic-JMS-Module/JMSResource/Weblogic-JMS-Module/Topics/ep.orders')
cmo.setJNDIName('jms/ep.orders')
cmo.setSubDeploymentName('Weblogic-JMS-Subdeployment')

cd('/JMSSystemResources/Weblogic-JMS-Module/JMSResource/Weblogic-JMS-Module')
cmo.createTopic('ep.changesets')

cd('/JMSSystemResources/Weblogic-JMS-Module/JMSResource/Weblogic-JMS-Module/Topics/ep.changesets')
cmo.setJNDIName('jms/ep.changesets')
cmo.setSubDeploymentName('Weblogic-JMS-Subdeployment')

cd('/JMSSystemResources/Weblogic-JMS-Module/JMSResource/Weblogic-JMS-Module')
cmo.createQueue('ep.emails')

cd('/JMSSystemResources/Weblogic-JMS-Module/JMSResource/Weblogic-JMS-Module/Queues/ep.emails')
cmo.setJNDIName('jms/ep.emails')
cmo.setSubDeploymentName('Weblogic-JMS-Subdeployment')

cd('/JMSSystemResources/Weblogic-JMS-Module/JMSResource/Weblogic-JMS-Module')
cmo.createQueue('ep.emailsdlq')

cd('/JMSSystemResources/Weblogic-JMS-Module/JMSResource/Weblogic-JMS-Module/Queues/ep.emailsdlq')
cmo.setJNDIName('jms/ep.emailsdlq')
cmo.setSubDeploymentName('Weblogic-JMS-Subdeployment')

cd('/JMSSystemResources/Weblogic-JMS-Module/JMSResource/Weblogic-JMS-Module')
cmo.createTopic('ep.giftcertificates')

cd('/JMSSystemResources/Weblogic-JMS-Module/JMSResource/Weblogic-JMS-Module/Topics/ep.giftcertificates')
cmo.setJNDIName('jms/ep.giftcertificates')
cmo.setSubDeploymentName('Weblogic-JMS-Subdeployment')

cd('/JMSSystemResources/Weblogic-JMS-Module/JMSResource/Weblogic-JMS-Module')
cmo.createTopic('ep.customers')

cd('/JMSSystemResources/Weblogic-JMS-Module/JMSResource/Weblogic-JMS-Module/Topics/ep.customers')
cmo.setJNDIName('jms/ep.customers')
cmo.setSubDeploymentName('Weblogic-JMS-Subdeployment')


cd('/JMSSystemResources/Weblogic-JMS-Module/JMSResource/Weblogic-JMS-Module')
cmo.createTopic('ep.dataimport')

cd('/JMSSystemResources/Weblogic-JMS-Module/JMSResource/Weblogic-JMS-Module/Topics/ep.dataimport')
cmo.setJNDIName('jms/ep.dataimport')
cmo.setSubDeploymentName('Weblogic-JMS-Subdeployment')


cd('/JMSSystemResources/Weblogic-JMS-Module/JMSResource/Weblogic-JMS-Module')
cmo.createTopic('ep.cmusers')

cd('/JMSSystemResources/Weblogic-JMS-Module/JMSResource/Weblogic-JMS-Module/Topics/ep.cmusers')
cmo.setJNDIName('jms/ep.cmusers')
cmo.setSubDeploymentName('Weblogic-JMS-Subdeployment')

cd('/SystemResources/Weblogic-JMS-Module/SubDeployments/Weblogic-JMS-Subdeployment')
set('Targets',jarray.array([ObjectName('com.bea:Name=Weblogic-JMS-Server,Type=JMSServer')], ObjectName))

activate()
