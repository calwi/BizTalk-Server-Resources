######################################################### #
#                                                         #
# Disable Tracking Settings in BizTalk Server Environment #
# Created by: Sandro Pereira                              #
# Organisation: DevScope                                  #
# Date: 30 October 2014	                                  #
# Version: 1.0                                            #
#                                                         #
###########################################################

########################################################### 
# SQL Settings
########################################################### 
$BTSSQLInstance = get-wmiobject MSBTS_GroupSetting -namespace root\MicrosoftBizTalkServer | 
					select-object -expand MgmtDbServerName
$BizTalkManagementDb = get-wmiobject MSBTS_GroupSetting -namespace root\MicrosoftBizTalkServer | 
						select-object -expand MgmtDbName

###########################################################
# Connect the BizTalk Management database
########################################################### 
[void] [System.reflection.Assembly]::LoadWithPartialName("Microsoft.BizTalk.ExplorerOM")
$BTSCatalog = New-Object Microsoft.BizTalk.ExplorerOM.BtsCatalogExplorer
$BTSCatalog.ConnectionString = "SERVER=$BTSSQLInstance;DATABASE=$BizTalkManagementDb;Integrated Security=SSPI"

###########################################################
# Get all BizTalk applications
###########################################################
$BTSApplications = $BTSCatalog.Applications 

Echo "Start disabling trackings settings"
###########################################################
# Disable tracking setting for all artifacts 
# inside BizTalk Applications
###########################################################
foreach ($Application in $BTSApplications)
{
    Echo "Disabling tracking for application: $($Application.name)"
    # Disable tracking settings in orchestrations    
	$Application.orchestrations | 
	%{ $_.Tracking = [Microsoft.BizTalk.ExplorerOM.OrchestrationTrackingTypes]::None }
    
	# Disable tracking settings in Send ports       
	$disablePortsTracking = New-Object Microsoft.BizTalk.ExplorerOM.TrackingTypes
	$Application.SendPorts | 
	%{ $_.Tracking = $disablePortsTracking }
	
	# Disable tracking settings in Receive ports
	$Application.ReceivePorts | 
	%{ $_.Tracking = $disablePortsTracking }
	
    # Disable tracking settings in pipelines        
	$Application.Pipelines | 
	%{ $_.Tracking = [Microsoft.BizTalk.ExplorerOM.PipelineTrackingTypes]::None }
	
	# Disable tracking settings in Schemas
	$Application.schemas | 
		?{ $_ -ne $null } |
		?{ $_.type -eq "document" } |
		%{ $_.AlwaysTrackAllProperties = $false }
}
# Save tracking settings changes
$BTSCatalog.SaveChanges()
Echo "Finished disable trackings settings"