function main {
    param (
        [Parameter(Mandatory = $true)]
        [string]$availableActionsFile,

        [Parameter(Mandatory = $true)]
        [string]$usedActionsFile
    )

    Write-Host "Running script.ps1 with parameters:"
    Write-Host "- availableActionsFile: [$availableActionsFile]"
    Write-Host "- usedActionsFile: [$usedActionsFile]"


    $availableActions = Get-Content $availableActionsFile | ConvertFrom-Json
    Write-Host "Found [$($availableActions.actions.Length)] available actions"
    Write-Host "Found [$($availableActions.workflows.Length)] available reusable workflows"

    $usedActionsInfo = Get-Content $usedActionsFile | ConvertFrom-Json
    Write-Host "Found [$($usedActionsInfo.actions.Length)] available actions and reusable workflows"

    $usedReusableWorkflows = $usedActionsInfo | Where-Object {$_.type -eq "reusable workflow"}
    $usedActions = $usedActionsInfo | Where-Object {$_.type -eq "action"}

    Write-Host "Found [$($usedReusableWorkflows.Length)] used reusable workflows"
    Write-Host "Found [$($usedActions.Length)] used actions"

    # search for this reusable workflow:
    $reusableworkflow_input = "devops-actions/.github/.github/workflows/rw-ossf-scorecard.yml"
    $usedReusableWorkflow = $usedReusableWorkflows | Where-Object {$_.actionLink -eq $reusableworkflow_input}

    if ($null -eq $usedReusableWorkflow) {
    Write-Error "Cound not find used reusable workflow with name [$reusableworkflow_input]"
    exit 1
    }

    # get the owner/repo and workflowname from the $reusableworkflow_input
    $reusableworkflow_input_split = $reusableworkflow_input.Split("/")
    $reusableworkflow_input_owner_repo = "$($reusableworkflow_input_split[0])/$($reusableworkflow_input_split[1])"
    $reusableworkflow_input_workflowname = $reusableworkflow_input_split[4]

    # search for the actions used in the reusable workflow
    $usedActionsInReusableWorkflow = $usedActions | Where-Object {$_.workflows | Where-Object {$_.repo -eq $reusableworkflow_input_owner_repo -And $_.workflowFileName -eq $reusableworkflow_input_workflowname}}
        Write-Host "Found [$($usedActionsInReusableWorkflow.Length)] used actions in the reusable workflow [$reusableworkflow_input]"
        foreach ($usedAction in $usedActionsInReusableWorkflow) {
        Write-Host "  - [$($usedAction.actionLink)]"
    }

    # Show where this reusable workflow is reused in a mermaid diagram in the GITHUB_STEP_SUMMARY
    # create array of strings to store the output
    $summary = @()
    $summary += '```mermaid'
    $summary += "flowchart LR"
    $usedByChar = "B"
    foreach ($usedByWorkflow in $usedReusableWorkflow.workflows) {
        $summary += "  A[$reusableworkflow_input]-->$usedByChar[$($usedByWorkflow.repo)]"
        # go to the next usedByChar
        $usedByChar = [char]([int]$usedByChar[0] + 1)
    }

    foreach ($usedAction in $usedActionsInReusableWorkflow) {
        $summary += "  $usedByChar[$($usedAction.actionLink)]-->A[$reusableworkflow_input]"

        # find if this is a composite action
        $actionInfo = $availableActions.actions | Where-Object {$_.actionLink -eq $usedAction.actionLink.Split("/")[1]}
        if ($null -ne $actionInfo) {
            Write-Host "Could not find action with link [$($usedAction.actionLink)]"
        }
        else {
            # if this action is not from the current org, then we do no have the action info
            Write-Host "Found action info [$($actionInfo.using)] and [$($actionInfo.downloadUrl)]"
        }
        $usedAction.actionLink
        $usedByChar = [char]([int]$usedByChar[0] + 1)
    }s
    $summary += '```'

    # write the summary to the $GITHUB_STEP_SUMMARY file
    Set-Content -Path $env:GITHUB_STEP_SUMMARY -Value $summary
}