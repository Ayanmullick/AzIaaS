document.addEventListener("DOMContentLoaded", function () {
  marked.use({ break: true });

  function renderFileContent(markdownFileUrl) {
    renderMarkDownFile(markdownFileUrl);
  }

  function renderMarkDownFile(fileUrl) {
    return fetch(fileUrl)
      .then((response) => cleanDateTime(response.text()) )
      .then((markdown) => {
        markdown = marked.parse(replaceGroups(markdown))
        completeStepContent = markdown.substring(markdown.indexOf('Post job'))
        .split('\n')
        .map((text,index) => `<div class='js-check-step-line CheckStep-line d-flex log-line-plain'>
          <a class="CheckStep-line-number color-fg-muted d-inline-block text-mono text-normal flex-shrink-0">${index + 1}</a>
          <span class="CheckStep-line-content d-inline-block flex-auto ml-3 js-check-line-content">
          <span class="" style=""> ${text} </span>
          </span>
         </div>`)
        .join('');
        console.log(markdown);
        setupStepContent = markdown.substring(0,markdown.indexOf("set up to track &#39;origin/main&#39;."))
        .split('\n')
        .map((text,index) => 
             text.trim()
          )
      .join('');

        
        document.getElementById("completeStep").innerHTML = completeStepContent;
        document.getElementById("setupStep").innerHTML = setupStepContent;

        document.getElementById("content").innerHTML = marked.parse(markdown);

        var scriptTags = document.querySelectorAll("#content script");

        try {
          scriptTags.forEach(function (scriptTag) {
            if (scriptTag.src) {
              var externalScript = document.createElement("script");
              externalScript.src = scriptTag.src;
              document.getElementById("content").removeChild(scriptTag);
              document.getElementById("content").appendChild(externalScript);
            } else {
              eval(scriptTag.innerText);
            }
          });
        } catch (error) {
          console.log(error);
        }
        let links = document.querySelectorAll("a");
        for (let i = 0; i < links.length; i++) {
          links[i].setAttribute("target", "_blank");
        }
      });
  }


  const urlParams = new URLSearchParams(window.location.search);
  const path = urlParams.get("path");
  if (path !== "" && path !== null) {
    renderFileContent(path);
  } 

});

var findBlocks = function (data, variableNames) {
  const matches = [];
  variableNames.forEach(function (variable) {
    const regexPattern = `#region(?<variableName> ${variable})(?<content>[\\s\\S]*?)(#endregion)`;
    let regex = new RegExp(regexPattern, "g");
    for (const match of data.matchAll(regex)) {
      const variableName = match.groups.variableName.trim();
      if (variableNames.includes(variableName)) {
        const content = match.groups.content.trim();

        matches.push({
          variableName,
          content,
        });
      }
    }
  });
  return matches;
};
function showBlocks(data, variableNames) {
  var blocks = findBlocks(data, variableNames);
  blocks.forEach(function (item, index) {
    let variableNameBlock = document.getElementById(item.variableName);
    let codeBlock = document.getElementById("code" + index);
    if (codeBlock !== null) {
      codeBlock.textContent = item.content;
      hljs.highlightElement(codeBlock);
    }
    if (variableNameBlock !== null) {
      variableNameBlock.textContent = item.variableName;
    }
  });
}

function handleDocumentWrite(content) {
  var contentPlaceholder = document.getElementById("content");
  contentPlaceholder.innerHTML += content}
  window.document.write = handleDocumentWrite;


  function replaceGroups(input) {
    const groupRegex = /##\[\s*group\s*\](.*?)##\[\s*endgroup\s*\]/gs;
    const result = input.replace(groupRegex, (match, content) => {;
        // Extract the summary and the list items
        const lines = content.trim().split('\n').map(line => line.trim()).filter(line => line);
        const summary = lines.shift();
        lines.pop();
        const lists =  lines;

        if(lines.length > 0) {
          return `<details><summary><u id="Variables">${summary}</u></summary>
          ${lists.map(text => text.trim()).join('<br/>')}
        </details>`;
        } else {
          return content;
        }


    });
    return content;
}

const cleanDateTime = (result) => result.replaceAll(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{7}Z/g, '');

