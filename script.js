document.addEventListener("DOMContentLoaded", function () {
  marked.use({ break: true });

  function renderFileContent(markdownFileUrl) {
    renderMarkDownFile(markdownFileUrl);
  }

  function renderMarkDownFile(fileUrl) {
    return fetch(fileUrl)
      .then((response) => response.text())
      .then((markdown) => {
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
      });
  }


  const urlParams = new URLSearchParams(window.location.search);
  const path = urlParams.get("path");
  if (path !== "" && path !== null) {
    renderFileContent(path);
  } 

});

  var findBlocks = function (data) {
      const regexPattern =/#region(?<variableName>.*|\n)(?<content>[\s\S]*?)(#endregion)/g;
    const matches = [];
    while ((match = regexPattern.exec(data)) !== null) {
      const variableName = match.groups.variableName.trim();
      const content = match.groups.content.trim();

      matches.push({
        variableName,
        content,
      });
    }
    return matches;
  }
  function showBlocks(data) {
        var blocks = findBlocks(data);
    blocks.forEach(function (item, index) {
      let variableNameBlock = document.getElementById(
        `variableName${index + 1}`
      );

      let codeBlock = document.getElementById("code" + (index + 1));
      if (codeBlock !== null) {
        codeBlock.textContent = item.content;
        hljs.highlightElement(codeBlock);
      }
  
    });
  }  
