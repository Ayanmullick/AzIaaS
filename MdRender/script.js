document.addEventListener("DOMContentLoaded", function () {
  marked.use({ breaks: true });

  function renderFileContent(markdownFileUrl) {
    renderMarkDownFile(markdownFileUrl);
  }

  function renderMarkDownFile(fileUrl) {
    return fetch(fileUrl)
      .then((response) => response.text() ) 
      .then((markdown) => {
        markdown = cleanDateTime(replaceGroups(markdown));
        completeStepContent = markdown.substring(markdown.indexOf('Post job'))
        .split('\n')
        .map((text,index) => `<div class='js-check-step-line CheckStep-line d-flex log-line-plain'>
          <a class="CheckStep-line-number color-fg-muted d-inline-block text-mono text-normal flex-shrink-0"></a>
          <span class="CheckStep-line-content d-inline-block flex-auto ml-3 js-check-line-content">
          <span class="" style=""> ${text} </span>
          </span>
         </div>`)
        .join('');


        setupStepContent = markdown.substring(0,markdown.indexOf("'origin/main'."));

        betweenContent = markdown.substring(
          markdown.indexOf("[command]/usr/bin/git"),
          markdown.indexOf('Post job')
        );

        document.getElementById("setupStep").innerHTML = marked.parse(setupStepContent);
        document.getElementById("completeStep").innerHTML = marked.parse(completeStepContent);
        document.getElementById('betweenContent').innerHTML = betweenContent;

        //document.getElementById("content").innerHTML = marked.parse(markdown);

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
    const result = input.replace(groupRegex, (match, content) => {
        // Extract the summary and the list items
        const lines = content.trim().split('\n').map(line => line.trim()).filter(line => line);
        const summary = lines.shift();
        lines.pop();
        const lists =  lines;

        if(lines.length > 0) {
          return `<details><summary><u>${summary}</u></summary>
          ${lists.map((text,index) => {
            return `<div class='js-check-step-line CheckStep-line d-flex log-line-plain'>
          <a class="CheckStep-line-number color-fg-muted d-inline-block text-mono text-normal flex-shrink-0"></a>
          <span class="CheckStep-line-content d-inline-block flex-auto ml-3 js-check-line-content">
          <span class="" style=""> ${text} </span>
          </span>
         </div>`;
            
          }).join('')}
        </details>`;
        } else {
          return content;
        }


    });

    return result;
}

const cleanDateTime = (result) => result.replaceAll(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{7}Z/g, '');



function createStepDetails(stepId,stepText) {

  let detailsElement = document.createElement('details');
  detailsElement.className = 'Details-element CheckStep rounded-2 details-reset js-checks-log-details px-2 border';

 detailsElement.innerHTML = `
  <summary class="CheckStep-header p-2 mb-1 rounded-2 js-check-step-summary uxr_CheckStep-header mx-2" style="top: 88px;">
    <div class="d-flex flex-items-center">

      <svg class="octicon octicon-chevron-right js-check-step-chevron mr-2 flex-shrink-0 CheckStep-chevron" viewBox="0 0 16 16" version="1.1" width="16" height="16" aria-hidden="false" style="">
          <path fill-rule="evenodd" d="M6.22 3.22a.75.75 0 011.06 0l4.25 4.25a.75.75 0 010 1.06l-4.25 4.25a.75.75 0 01-1.06-1.06L9.94 8 6.22 4.28a.75.75 0 010-1.06z"></path>
      </svg>

      <svg class="octicon octicon-check-circle-fill mr-3 flex-shrink-0 ml-1" title="This step passed" viewBox="0 0 16 16" version="1.1" width="16" height="16" aria-hidden="true">
      <path d="M8 16A8 8 0 1 1 8 0a8 8 0 0 1 0 16Zm3.78-9.72a.751.751 0 0 0-.018-1.042.751.751 0 0 0-1.042-.018L6.75 9.19 5.28 7.72a.751.751 0 0 0-1.042.018.751.751 0 0 0-.018 1.042l2 2a.75.75 0 0 0 1.06 0Z"></path>
      </svg>

      <span class="flex-1 ml-n1 mr-1 css-truncate css-truncate-overflow user-select-none"> ${stepText} </span>

      <div class="text-mono text-normal text-small float-right">s</div>
    </div>
  </summary>

  <div class="text-mono text-small py-1 my-2 js-checks-log-display-container ml-5 pl-3" id="${stepId}">
  </div>
  `;

   return detailsElement;
}

document.getElementById('betweenContent').before(createStepDetails('setupStep','Setup, Checkout'));
document.getElementById('betweenContent').after(createStepDetails('completeStep','Checkout, Complete'));
