# Three Tier Applicaiton Infrastructure deployment in Azure


This is deploying a [three-tier application architecture][1] on virtual machines in Azure.


<details>
<summary><u>Naming Standard</u></summary>
<div style="display:flex;gap:3rem">
<div style="width: 80%">
[Naming Convention] (% include https://raw.githubusercontent.com/Ayanmullick/AzIaaS/refs/heads/main/3TierApp/NamingConvention.md %)
</div>
[Abbreviatons] (% include https://raw.githubusercontent.com/Ayanmullick/AzIaaS/refs/heads/main/3TierApp/Abbreviations.md %) 
</div>
</details>


<div style="float: right">
[Virtual Machines] (% include https://raw.githubusercontent.com/Ayanmullick/AzIaaS/refs/heads/main/3TierApp/VMs.md %) [open]
</div>

Currently the 'Sparse checkout' feature is blocked by bug.
[sparse-checkout not working when running in a container. · Issue #1602 · actions/checkout][4]


One could get more detailed in their implementation of the code.
Potential Tables: vNet details, NSG rules, VM details, storage account restrictions
Potential environment variables: RG name, KV, Sa, secret, admin name,

One could put all tabularizable configuration in a markdown table and the other configurations in a hash table.

This gives you a single source of truth for configuration and documentation unlike other declarative methods that could result in a doc-config mismatch.
And adding to configuration doesn't require you to add to the code. One could also parameterize the table paths once the table data has been validated.

The tables could be generated with proper Excel formulas.

<br><br>

These are the NSG rules to allow SSL and Windows Admin Center traffic.

<div style="width: 80%">
[Network Security Group Rules] (% include https://raw.githubusercontent.com/Ayanmullick/AzIaaS/refs/heads/main/3TierApp/NsgRules.md %) 
</div>

<figure style="float:right; margin:0; max-width: 20%;">
  <img src="https://ayanmullick.github.io/AzIaaS/3TierApp/3TierApp.jpg" width="100%" alt="Visio diagram for output resources"/>
  <figcaption style="text-decoration: underline">Visio diagram for output resources</figcaption>
</figure>




<script>
  fetch("https://raw.githubusercontent.com/Ayanmullick/AzIaaS/refs/heads/main/3TierApp/GovResource.ps1").then(response => response.clone().text()).then(data => {
    showBlocks(data,{ code0 : "GovernanceResources", code1 : "NetworkResources", code2 : "OutputForNextJob"});
  });

   fetch("https://raw.githubusercontent.com/Ayanmullick/AzIaaS/refs/heads/main/3TierApp/VMs.ps1").then(response => response.clone().text()).then(data => {
    showBlocks(data,{ code3 : "VirtualMachineCreation"});
  })
</script>


This prestages the governance resources in Azure for the VMs' Deployment job.


<details>
<summary><u id="GovernanceResources"></u></summary> <pre class="powershell" id="code0"></pre>
</details>

This prestages the Network resources in Azure for the VMs' Deployment job.


<details>
<summary><u id="NetworkResources"></u></summary> <pre class="powershell" id="code1"></pre>
</details>


This passes the resources' details between the Governance resources and the VM deployment jobs in the GitHub Actions workflow.

<details open>
<summary><u id="OutputForNextJob"></u></summary> <pre class="powershell" id="code2"></pre>
</details>


Here is a link to the [Governance resources deployment execution][2]


This deploys the required virtual machines in the same resource group using the previously prestaged governance resources.


<details close>
<summary><u id="VirtualMachineCreation"></u></summary> <pre class="powershell" id="code3"></pre>
</details>


Here is a link to the [VM deployment execution][3]




<details>
<summary><u>Azure portal screenshots</u></summary>
<div style="display:flex;">
  <div>
      <img width="100%" src="https://raw.githubusercontent.com/Ayanmullick/AzIaaS/refs/heads/main/3TierApp/PortalClip1.jpg"> 
  </div>
  <div style="display:flex;flex-direction:column">
    <img height="300" src="https://raw.githubusercontent.com/Ayanmullick/AzIaaS/refs/heads/main/3TierApp/PortalClip2.jpg"> 
    <img height="300" src="https://raw.githubusercontent.com/Ayanmullick/AzIaaS/refs/heads/main/3TierApp/PortalClip3.jpg"> 
    <img height="300" src="https://raw.githubusercontent.com/Ayanmullick/AzIaaS/refs/heads/main/3TierApp/PortalClip4.jpg"> 
  </div>
</div>
</details>


<br>

<details>
  <summary><u>Essential characteristics</u></summary>

Correct, Deterministic, Efficient, Robust, Maintainable, Testable, Reliable, Reusable, Flexible, Scalable, Secure, BAU\BC lang parity

https://www.geeksforgeeks.org/software-engineering-characteristics-of-good-software
https://biosistemika.com/blog/dont-save-on-quality-key-attributes-of-software

≠ Idempotent\Incremental,Stateless  #How many orders of magnitude more lines of code just for this
</details>

[1]: <https://learn.microsoft.com/en-us/azure/architecture/guide/architecture-styles/#n-tier>
[2]: <https://ayanmullick.github.io/AzIaaS/Render/LogRender.html?path=https://raw.githubusercontent.com/Ayanmullick/AzIaaS/refs/heads/main/3TierApp/AzPSImageInfraDeploymentWithApproval%20GovernanceResourcesJob.log>
[3]: <https://ayanmullick.github.io/AzIaaS/Render/LogRender.html?path=https://raw.githubusercontent.com/Ayanmullick/AzIaaS/refs/heads/main/3TierApp/AzPSImageInfraDeploymentWithApproval%20DeployVirtualMachines.log>
[4]: <https://github.com/actions/checkout/issues/1602#issuecomment-2048656906>