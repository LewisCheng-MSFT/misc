###############################################################################
# ChangeLog
#
# v2014-05-06
#	  - No need to update this section as it is added into TFS now.
#
# v2013-12-10
#     - First Version, modify from the jumpbox setup ps
#
###############################################################################

###############################################################################
# Parameters
###############################################################################

param(
    # Mandatory ones:
    [Parameter(Mandatory = $true, HelpMessage = "Service Name")]
    [ValidateNotNullOrEmpty()]
    [string]$ServiceName,
    
    [Parameter(Mandatory = $true, HelpMessage = "List of Wadi environments seperated by comma.")]
    [ValidateNotNullOrEmpty()]
    [string]$WadiEnvironmentList,

    [Parameter(Mandatory = $true, HelpMessage = "List of service environments (config) seperated by comma. Should match WadiEnvironmentList.")]
    [ValidateNotNullOrEmpty()]
    [string]$ServiceEnvironmentList,

    [Parameter(Mandatory = $true, HelpMessage = "Path to build drop folder")]
    [ValidateNotNullOrEmpty()]
    [string]$DropFolderPath,

    # Not mandatory ones:
    [Parameter(Mandatory = $false, HelpMessage = "Service version. Must be in the format 'Major.Minor.Revision'.")]
    [ValidateNotNullOrEmpty()]
    [string]$ServiceVersion = '1.0.0',

    [Parameter(Mandatory = $false, HelpMessage = "Equal to your vector name")]
    [ValidateSet('DataTransfer')] # We only work on DataTransfer so far.
    [string]$WadiComponent = 'DataTransfer',

    [Parameter(Mandatory = $false, HelpMessage = "The work item number of the relevant Release Signoff Record (RSR)")]
    [string]$WadiRSR = "0",

    [Parameter(Mandatory = $false, HelpMessage = "Full-qualified build name")]
    [string]$Fqbn = "free-form-value",
	
	[Parameter(Mandatory = $false, HelpMessage = "Which secret to be rotate, e.g. Primary, Secondary, NULL")]
	[ValidateSet('Primary', 'Secondary', '')]
    [string]$SecretRotate = '',
	
	[Parameter(Mandatory = $false, HelpMessage = "Email Address for receiving deployment log")]
    [string]$EmailTo = $null,
	
	[Parameter(Mandatory = $false, HelpMessage = "The one to be notified when problem arises")]
    [ValidateNotNullOrEmpty()]
    [string]$WadiIncidentOwner = 'FAREAST\jolu'
)

###############################################################################
# Functions
###############################################################################

Function Write-ErrorExit
{
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$str
    )

    Write-Host -ForegroundColor Red $str;
        
    exit -1;
}

Function Write-StepSeperator
{
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$str
    )

    Write-Host -ForegroundColor Green $str;
}

Function Write-StepOK
{
    Write-Host -ForegroundColor Cyan "OK!";
}

Function Generate-DeploymentSpecFileName
{
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$compName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$svcEnv
    )

    $fileName = [System.String]::Concat($compName, "_", $ServiceName ,"_DeploymentSpec_", $svcEnv, ".xml");
    return $fileName;
}

Function String-Replace
{
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$str,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$key,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [string]$value
    )

    return $str.Replace($key, $value);
}

Function Xml-NodeValueReplace
{
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Xml.XmlNode]$node,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$key,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [string]$value
    )
    
    if([System.Xml.XmlNodeType]::Text -eq $node.NodeType){
        $node.Value = String-Replace $node.Value $key $value
    }else{
        
    }

    if($null -ne $node.Attributes){
        foreach ($attr in $node.Attributes)
        {
            $attr.value = String-Replace $attr.value $key $value 
        }
    }

    if($null -ne $node.ChildNodes){
        foreach($child in $node.ChildNodes)
        {
            Xml-NodeValueReplace $child $key $value
        }
    }
}

Function Update-XmlFile
{
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [string]$xmlFile,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $kvMap,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$destPath
    )

    $xml = [xml](get-content $xmlFile)
    if($null -eq $xml)
    {
        Write-ErrorExit "can't find the xml file: $xmlFile"
        return -1;
    }

    foreach($key in $kvMap.Keys)
    {
        $keyTemp = [System.String]::Concat("##", $key, "##")
        Xml-NodeValueReplace $xml.DocumentElement  $keyTemp $kvMap[$key]
    }

    $xml.Save($destPath);

    return 1;
}

Function Copy-Files
{
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$source,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$dest
    )

    # Try to create destination folder if not exists.
    if(![System.IO.Directory]::Exists($dest))
    {
        New-Item -path $dest -type directory -Force | Out-Null
    }

    $libFiles = Get-ChildItem -Path $source

    foreach($libFile in $libFiles)
    {
        $fileFullName = [System.IO.Path]::Combine($source, $libFile.ToString());
        Copy-Item -Path $fileFullName -Destination $dest -Force -Recurse
    }
}

Function Generate-SettingsFileName
{
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$compName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$svcEnv
    )

    $fileName = [System.String]::Concat("Settings_", $compName, "_", $svcEnv, ".xml");
    return $fileName;
}


Function Generate-DeploymentSpecFile
{
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [int]$Index,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [string]$WadiEnvironment,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [string]$ServiceEnvironment
    )
	
    $deploymentSpecFile = Generate-DeploymentSpecFileName $WadiComponent $ServiceEnvironment
    $deploymentSpecFilePath = [System.IO.Path]::Combine($deployInstancePath, $deploymentSpecFile)
    Write-Host "DeploymentSpec File $Index = $deploymentSpecFilePath"

    $DeploymentSpecTemplateFilePath = [System.IO.Path]::Combine($WadiShare, $DeploymentSpecTemplateFileName)

    if(![System.IO.File]::Exists($DeploymentSpecTemplateFilePath))
    {
        Write-ErrorExit "Deployment Specification Template File $DeploymentSpecTemplateFilePath does not exist."
    }

    # Whether we are doing test
    $testLocal = "Test" -eq $WadiEnvironment

    $kvMapDeploymentSpec = @{}

    # In CreateTFSItems: true <=> not Test
    if ($testLocal) {
        $kvMapDeploymentSpec["UseTfs"] = "false"
    } else {
        $kvMapDeploymentSpec["UseTfs"] = "true"
    }

    # In ReleaseSignoffRecordId: 0 for Test
    if ($testLocal) {
        $kvMapDeploymentSpec["RSR"] = "0"
    } else {
	    if ($WadiRSR -eq "0")
		{
			Write-ErrorExit "The RSR must be set for the prod/stage deployment."
		}
        $kvMapDeploymentSpec["RSR"] = $WadiRSR
    }

    # In Environment
    $kvMapDeploymentSpec["WadiEnvironment"] = $WadiEnvironment

    # In Component
    $kvMapDeploymentSpec["Component"] = $WadiComponent

    # In MajorVersion, MinorVersion, RevisionVersion
    $versions = $ServiceVersion.Split('.')
    if ($versions.Count -lt 3) {
        Write-ErrorExit "Service Version must be in the format 'Major.Minor.Revision'."
    }

    $kvMapDeploymentSpec["MajorVersion"] = $versions[0]
    $kvMapDeploymentSpec["MinorVersion"] = $versions[1]
    $kvMapDeploymentSpec["RevisionVersion"] = $versions[2]

    # In DeploymentPlan/Name
    if ($testLocal) {
        $kvMapDeploymentSpec["TestLocal"] = "deploy_only_test_local"
    } else {
        $kvMapDeploymentSpec["TestLocal"] = "deploy_only"
    }

    # In DeploymentPlan/ComponentBranch
    $kvMapDeploymentSpec["ComponentBranch"] = "ext_dpgdt"

    # In DeploymentPlan/BuildPath
    $kvMapDeploymentSpec["BuildPath"] = $DropFolderPath

    # In DeploymentPlan/BuildFQBN
    $kvMapDeploymentSpec["Fqbn"] = $Fqbn
	
    # In InitialState: Run for Test and Pause for Prod/Stage
    if ($testLocal) {
        $kvMapDeploymentSpec["InitialState"] = "Run"
    } else {
        $kvMapDeploymentSpec["InitialState"] = "Pause"
    }

    # In TemplateName
    $kvMapDeploymentSpec["Workflow"] = $WorkFlowFileName

    # In SettingsFilePath
    $kvMapDeploymentSpec["ServiceEnvironment"] = $ServiceEnvironment

    # In Toolset
    $rnd = Get-Random -minimum 10000 -maximum 99999
    $kvMapDeploymentSpec["BranchVersion"] = $rnd.ToString()
    $kvMapDeploymentSpec["ToolsetPath"] = $DropFolderPath

    # In DIEngine
    $kvMapJumpboxDE = @{}
    $kvMapJumpboxDE['RR1AppTest'] = "https://rr1cisappde01.redmond.corp.microsoft.com/wadi/v107/de/rr1apptest"
    $kvMapJumpboxDE['RR1AppTest2'] = "https://rr1cisappde02.redmond.corp.microsoft.com/wadi/v107/de/rr1apptest2"
    $kvMapJumpboxDE['RR1AppTest3'] = "https://rr1cisappde03.redmond.corp.microsoft.com/wadi/v107/de/rr1apptest3"
    $kvMapJumpboxDE['SN1ProdDpg'] = "https://sn1cisutld10.corp.microsoft.com/wadi/v107/de/sn1proddpg"
    if ($testLocal) {
        $jumpboxTag = 'RR1AppTest'
    } else {
        $jumpboxTag = 'SN1ProdDpg'
    }
    $jumpboxURL = $kvMapJumpboxDE[$jumpboxTag]
    $kvMapDeploymentSpec["Jumpbox"] = $jumpboxURL
    Write-Host "Jumpbox for $WadiEnvironment = $jumpboxURL"

    $updateResult = Update-XmlFile $DeploymentSpecTemplateFilePath $kvMapDeploymentSpec $deploymentSpecFilePath

    if(-1 -eq $updateResult)
    {    
        Write-ErrorExit "Failed to assemble Deployment Specification File: $deploymentSpecFilePath"
        exit;
    }

    return $deploymentSpecFilePath
}

Function Generate-SettingsFile
{
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [int]$Index,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [string]$ServiceEnvironment
    )

    $settingsFile = Generate-SettingsFileName $WadiComponent $ServiceEnvironment
    $settingsFilePath = [System.IO.Path]::Combine($settingInstancePath, $RDToolsFolderName, $RDToolsDeployFolderName, $settingsFile)
	Write-Host "Settings File $Index = $settingsFilePath"

    $settingsTemplateFilePath = [System.IO.Path]::Combine($WadiShare, $SettingsTemplateFileName)

    if(![System.IO.File]::Exists($settingsTemplateFilePath))
    {
        Write-ErrorExit "Settings Template File $settingsTemplateFilePath does not exist."
    }

    $kvMapSettings = @{}

    # EmailTo
    $kvMapSettings["EmailTo"] = $EmailTo

    # IncidentOwner
    $kvMapSettings["IncidentOwner"] = $WadiIncidentOwner

    # Environment
    $kvMapSettings["ServiceEnvironment"] = $ServiceEnvironment

    # ResumePoint
    $kvMapSettings["ResumePoint"] = $ResumePoint

    $updateResult = Update-XmlFile $SettingsTemplateFilePath $kvMapSettings $settingsFilePath

    if($updateResult -eq -1)
    {    
        Write-ErrorExit "Failed to assemble Settings File: $settingsFilePath"
        exit;
    }
}

###############################################################################
# Main Entry
###############################################################################

Write-StepSeperator '###################################################################################################'
Write-StepSeperator '#'
Write-StepSeperator '# 1. Preparing some script variables'
Write-StepSeperator '#'
Write-StepSeperator '###################################################################################################'

if([string]::IsNullOrEmpty($EmailTo))
{
    $EmailTo = $env:username
}


# DM side started the secrets rotation from April for secondary secrets.
# So general rule is
# Primary secrets shall be rotated in odd month
# Secondary secrets shall be rotated in even month

$month = Get-Date -Format "%M"

# Enforce SecretRotate to be NULL if it is not Primary or Secondary
if ($SecretRotate -ieq "Primary")
{
	$ResumePoint = "RotatePrimary"
	if ($month % 2 -eq 0)
	{
		Write-ErrorExit "Primary secrets shall be rotated in odd Month"
	}
}
elseif ($SecretRotate -ieq "Secondary")
{
	$ResumePoint = "RotateSecondary"
	if ($month % 2 -eq 1)
	{
		Write-ErrorExit "Secondary secrets shall be rotated in even Month"
	}
}
else
{
	$SecretRotate = '';
}


# WadiShare Folder Tree

if ($SecretRotate -eq '')
{
	$WadiShare = "\\csitrmtdev35\JumpboxDeployTools\JumpBoxBase"
	$WorkFlowFileName = "DMDeployWorkflow.xaml"
} 
else
{
	# Use secret rotation related configuration
	$WadiShare = "\\csitrmtdev35\JumpboxDeployTools\SecretBase"
	$WorkFlowFileName = "DMSecretRotateWorkflow.xaml"
}


Write-Host "WadiShare = $WadiShare"
Write-Host "WorkFlow = $WorkFlowFileName"

$RDToolsFolderName = "RDTools"
$RDToolsDeployFolderName = "Deploy"
$RDToolsToolsFolderName = "Tools"
$SettingsTemplateFileName = "SettingsTemplate.xml"
$DeploymentSpecTemplateFileName = "DeploymentSpecTemplate.xml"

# Deployment Instance path
$Guid = [System.Guid]::NewGuid().ToString()
$DeployInstanceName = [System.String]::Concat($ServiceName ,"_", $Guid)
$deployInstancePath = [System.IO.Path]::Combine("C:\DmDeplRoot", $DeployInstanceName)
Write-Host "Deployment Instance Folder = $deployInstancePath"
New-Item -path $deployInstancePath -type directory -Force
if(![System.IO.Directory]::Exists($deployInstancePath))
{
    Write-ErrorExit "Failed to create staging folder: $deployInstancePath. Please check whether you have access right."
}

# Setting Instance path if necessary
if ($SecretRotate -ne '')
{
	$SettingInstanceName = [System.String]::Concat($ServiceName ,"_", $Guid)
	$settingInstancePath = [System.IO.Path]::Combine("\\scratch2\scratch\jolu\SecretRotation", $SettingInstanceName)
	Write-Host "Setting Instance Folder = $settingInstancePath"
	New-Item -path $settingInstancePath -type directory -Force
	if(![System.IO.Directory]::Exists($settingInstancePath))
	{
		Write-ErrorExit "Failed to create staging folder: $settingInstancePath. Please check whether you have access right."
	}
}

Write-StepOK

Write-StepSeperator '###################################################################################################'
Write-StepSeperator '#'
Write-StepSeperator '# 2. Validating the script inputs'
Write-StepSeperator '#'
Write-StepSeperator '###################################################################################################'

# Wadi Environments, Service Environments, Resume Points
$WadiEnvironments = $WadiEnvironmentList.Split(",")
$ServiceEnvironments = $ServiceEnvironmentList.Split(",")

if ($WadiEnvironments.Length -ne $ServiceEnvironments.Length)
{
    Write-ErrorExit "WadiEnvironmentList and ServiceEnvironmentList are not match."
}

for ($i = 0; $i -lt $WadiEnvironments.Length; $i++)
{
    $WadiEnvironment = $WadiEnvironments[$i]

    # Check if WadiEnvironment is within a validation set
    if ($WadiEnvironment -ne "Test" -and $WadiEnvironment -ne "Stage" -and $WadiEnvironment -ne "Production")
    {
        Write-ErrorExit "WadiEnvironment must be one of Test, Stage and Production."
    }

    Write-Host "Wadi Environment $i = $WadiEnvironment"

    $ServiceEnvironment = $ServiceEnvironments[$i]
    Write-Host "Service Environment $i = $ServiceEnvironment"
}

Write-Host "ServiceVersion = $ServiceVersion"
Write-Host "WadiComponent = $WadiComponent"
Write-Host "WadiRSR = $WadiRSR"
Write-Host "Fqbn = $Fqbn"

Write-StepSeperator '###################################################################################################'
Write-StepSeperator '#'
Write-StepSeperator '# 3. Creating the spec/setting files and deploy'
Write-StepSeperator '#'
Write-StepSeperator '###################################################################################################'

if ($SecretRotate -ne '')
{
	# Prepare new RDTools directory
	# First is the SecretBase
	$source = "\\csitrmtdev35\JumpboxDeployTools\SecretBase\RDTools"
	$dest = [System.IO.Path]::Combine($settingInstancePath, $RDToolsFolderName)
	Write-Host "Copying $source to $dest ..."
	Copy-Files $source $dest
	
	# Next is the configuration files
	foreach ($folder in "Config","RotateSqlAccountPS","RotateStorageKeyPS")
	{
		$source = [System.IO.Path]::Combine($DropFolderPath, $RDToolsFolderName, $folder)
		$dest = [System.IO.Path]::Combine($settingInstancePath, $RDToolsFolderName, $folder)
		Write-Host "Copying $source to $dest ..."
		Copy-Files $source $dest
	}
	
	$DropFolderPath = $settingInstancePath
}	


for ($i = 0; $i -lt $WadiEnvironments.Length; $i++) {
    $WadiEnvironment = $WadiEnvironments[$i]
    $ServiceEnvironment = $ServiceEnvironments[$i]
	
	$deploymentSpecFilePath = Generate-DeploymentSpecFile $i $WadiEnvironment $ServiceEnvironment
	
	if ($SecretRotate -ne '')
	{	
		# Setting is not prepared in secret rotation
    	Generate-SettingsFile $i $ServiceEnvironment
	}

	$InvokerExe = "DeploymentReq"
	$InvokeArgument = "-DeploymentSpec $deploymentSpecFilePath"
	Write-Host "$InvokerExe $InvokeArgument"	
	
	$procErrorFile = "deployOutput.txt"
    $proc = Start-Process -FilePath $InvokerExe -ArgumentList @($InvokeArgument) -NoNewWindow -Wait -RedirectStandardError $procErrorFile -PassThru
    $proc.WaitForExit()	
	$errorout = Get-Content -Path $procErrorFile
	if($proc.ExitCode -ne 0)
	{
		Write-Error "Deployment failed: $errorout."
		exit -1;
	}
}

exit;