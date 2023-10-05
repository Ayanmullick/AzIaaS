# Azure PowerShell to deploy Win11 Arm VM
<script>
  let fetchRes = fetch("https://raw.githubusercontent.com/Ayanmullick/AzIaaS/master/AzVM.ps1")

  fetchRes.then(response => response.clone().text()).then(data => {const lines = data.split("\n");
    const regexPattern =
      /#region(?<variableName>.*|\n)(?<content>[\s\S]*?)(#endregion)/g;
    const matches = [];
    while ((match = regexPattern.exec(data)) !== null) {
      const variableName = match.groups.variableName.trim();
      const content = match.groups.content.trim();

      matches.push({
        variableName,
        content,
      });
    }
    matches.forEach(function (item, index) {
      let variableNameBlock = document.getElementById(`variable{index + 1}`);
      let codeBlock = document.getElementById("code" + (index + 1));
      codeBlock.textContent = item.content;
      variableNameBlock.textContent = item.variableName;
    });
   /* hljs.highlightElement(document.getElementById("code1"));
    hljs.highlightElement(document.getElementById("code2"));
    hljs.highlightElement(document.getElementById("code3"));*/
  })
</script>

<p>I wanted to explore the benefits of [Azure ARM VMs that run on Arm-based processors][1]. They offer outstanding price-performance and power-efficiency for various workloads. In this snippet, I show how to deploy a [Generation 2][2] Windows 11 ARM virtual machine with basic [naming standard][11] and diagnostics using PowerShell cmdlets.</p>

This stores the name in a variable, creates a resource group and parameterizes the location and Resource Group name for [splatting][3].

<a href="https://shell.azure.com/powershell" target="_blank">
   <img align="right" src="https://learn.microsoft.com/azure/cloud-shell/media/embed-cloud-shell/launch-cloud-shell-1.png" alt="Launch Cloud Shell">
</a>
<br><br>

<img align="right" src="https://dev-to-uploads.s3.amazonaws.com/uploads/articles/9ki4cvu8jf2i1r0v9f7l.png" width="30%"  border="3"/>

<details open>
  <summary><u id="variable1"></u></summary>

<pre class="powershell" id="code1"></pre>

</details>

This is the network configuration to create an NSG allowing remote desktop connections and a public IP address pointing to the [accelerated networking][4] enabled network card that the virtual machine would use. Add the IP where the RDP connection would come from.

<pre id="code2" class="powershell clear"></pre>

The virtual machine configuration specifies the name, [size][5], credentials, time zone, [image details][10], [update behavior][6] and [diagnostics configuration][7] of the VM. Add your password.

<pre id="code3" class="powershell"></pre>

**Output**

```
RequestId IsSuccessStatusCode StatusCode ReasonPhrase
--------- ------------------- ---------- ------------
                         True         OK OK
```



The Windows ARM image is still in preview and doesn't support [Trusted Launch][8] or [Secure Boot][9] yet and it's for validation purposes only.

[1]:  <https://azure.microsoft.com/en-us/blog/azure-virtual-machines-with-ampere-altra-arm-based-processors-generally-available/>
[2]:  <https://learn.microsoft.com/en-us/azure/virtual-machines/generation-2#features-and-capabilities>
[3]:  <https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_splatting>
[4]:  <https://learn.microsoft.com/en-us/azure/virtual-network/accelerated-networking-overview>
[5]:  <https://learn.microsoft.com/en-us/azure/virtual-machines/epsv5-epdsv5-series>
[6]:  <https://learn.microsoft.com/en-us/azure/virtual-machines/automatic-vm-guest-patching#azure-powershell-when-creating-a-windows-vm>
[7]:  <https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/boot-diagnostics>
[8]:  <https://learn.microsoft.com/en-us/azure/virtual-machines/trusted-launch>
[9]:  <https://learn.microsoft.com/en-us/azure/security/fundamentals/secure-boot>
[10]: <https://azuremarketplace.microsoft.com/en-us/marketplace/apps/microsoftwindowsdesktop.windows11preview-arm64>
[11]: <https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming>
