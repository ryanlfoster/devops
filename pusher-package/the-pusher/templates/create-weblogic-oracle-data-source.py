domainName="EP"
adminURL="t3://$server:7001"
adminUserName="weblogic"
adminPassword="test4admin"

dsName="$dbVendor-data-source"
dsFileName="$dbVendor-data-source.xml"
datasourceTarget="AdminServer"
dsJNDIName="jdbc/epjndi"
dsDriverName="${epdb_jdbc_driver_class}"
dsURL="${epdb_connection_url}"
dsUserName="$epDbUser"
dsPassword="$epDbPassword"
dsTestQuery="SELECT 1 FROM DUAL"


connect(adminUserName, adminPassword, adminURL)

edit()

dsname=dsName
server=datasourceTarget
cd("Servers/"+server)
target=cmo
cd("../..")

startEdit()

print 'Creating JDBCSystemResource with name '+dsname
jdbcSR = create(dsname,"JDBCSystemResource")
theJDBCResource = jdbcSR.getJDBCResource()
theJDBCResource.setName(dsname)

connectionPoolParams = theJDBCResource.getJDBCConnectionPoolParams()
connectionPoolParams.setConnectionReserveTimeoutSeconds(25)
connectionPoolParams.setMaxCapacity(100)

dsParams = theJDBCResource.getJDBCDataSourceParams()
dsParams.addJNDIName(dsJNDIName)

driverParams = theJDBCResource.getJDBCDriverParams()
driverParams.setUrl(dsURL)
driverParams.setDriverName(dsDriverName)

driverParams.setPassword(dsPassword)
driverProperties = driverParams.getProperties()

proper = driverProperties.createProperty("user")
proper.setName("user")
proper.setValue(dsUserName)

jdbcSR.addTarget(target)

save()

try:
    activate(block="true")
except:
    dumpStack()

print 'Done configuring the data source'
