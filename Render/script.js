document.addEventListener("DOMContentLoaded", function () {
  const themeSwitchButton = document.getElementById("switch-theme");
  const inverseCollapseButton = document.getElementById("inverse-collapses");
  themeSwitchButton.addEventListener("click", () => {
    const highlightjsThemeElement = document.getElementById('highlightjs-theme');
    if(document.body.classList.contains("dark-theme")) {
      document.body.classList.remove("dark-theme");
      document.body.classList.add("white-theme");
      highlightjsThemeElement.href = highlightjsThemeElement.href
          .replace('atom-one-dark-reasonable.min.css','atom-one-light.min.css');
    } else {
      document.body.classList.remove("white-theme");
      document.body.classList.add("dark-theme");
      highlightjsThemeElement.href = highlightjsThemeElement.href
          .replace('atom-one-light.min.css','atom-one-dark-reasonable.min.css');
    }
  });
  inverseCollapseButton.dataset.open = 'true';
  inverseCollapseButton.addEventListener('click', function (e)  {
    let button = e.target;
    document.querySelectorAll('details').forEach((item) => {
      if(button.dataset.open === 'true') {
        item.open = true;
      } else {
        item.open = false;
      }
    });
    button.dataset.open = (button.dataset.open === 'true') ? 'false' : 'true';
  });

  marked.use({ break: true });

  function renderFileContent(markdownFileUrl) {
    renderMarkDownFile(markdownFileUrl);
  }

  async function renderMarkDownFile(fileUrl) {
    return fetch(fileUrl).then(response => response.text()).then(markdown => {
      const contentIncludesInfo = [], regexPattern = `\\[(.*)\\].+\\(% include(.+)%\\)(\\s*\\[open\\])?`, regex = new RegExp(regexPattern, "g");
      let groupIndex = 0;
      markdown = markdown.replaceAll(regex, (...groups) => {
        let detailsBlock = '<details ';
        groupIndex++;
        const title = groups[1], path = groups[2].trim(), blockId = path.replace('.md', '') + groupIndex;
        const includeInfo = { filePath: path, blockId: blockId };
        if(groups[3]) detailsBlock+= "open";

        contentIncludesInfo.push(includeInfo);
        return `${detailsBlock}  id="${blockId}"><summary><strong><u>${title}</u></strong></summary></details>`;
      });

      document.getElementById("content").innerHTML = marked.parse(markdown);
      const titleElement = document.querySelector("h1");

      if(titleElement) {
        document.title = titleElement.textContent;
      }
      document.querySelectorAll("#content script").forEach(scriptTag => {
        if (scriptTag.src) {
          const externalScript = document.createElement("script");
          externalScript.src = scriptTag.src;
          document.getElementById("content").removeChild(scriptTag);
          document.getElementById("content").appendChild(externalScript);
        } else {
          eval(scriptTag.innerText);
        }
      });

      document.querySelectorAll("a").forEach(link => link.setAttribute("target", "_blank"));
      return contentIncludesInfo;
    }).then(contentIncludesInfo => {
      contentIncludesInfo.forEach(async includeInfo => {
        let blockWrapper = '<div';
        const fileContent = await getMarkdownFileContent(includeInfo.filePath.trim());
        document.getElementById(includeInfo.blockId).innerHTML += `${blockWrapper}>
          ${marked.parse(fileContent)}
        </div>`;
      });
    });
  }

  const urlParams = new URLSearchParams(window.location.search), path = urlParams.get("path");
  if (path !== "" && path !== null) renderFileContent(path);
});

var findBlocks = function (data, variableNames) {
  const matches = [];
  let variables = [];

  for (const [index, variable] of Object.entries(variableNames)) {
    variables.push(variable);
    const regexPattern = `#region(?<variableName> ${variable})(?<content>[\\s\\S]*?)(#endregion)`;
    let regex = new RegExp(regexPattern, "g");
    for (const match of data.matchAll(regex)) {
      const variableName = match.groups.variableName.trim();
      if (variables.includes(variableName)) {
        matches.push({ variableName, content: match.groups.content.trim(), blockId:index });
      }
    }
  }
  return matches;
};

function showBlocks(data, variableNames) {
  findBlocks(data, variableNames).forEach((item) => {
    let variableNameBlock = document.getElementById(item.variableName), codeBlock = document.getElementById(item.blockId);
    if (codeBlock !== null) {
      codeBlock.textContent = item.content;
      hljs.highlightElement(codeBlock);
    }
    if (variableNameBlock !== null) variableNameBlock.textContent = item.variableName;
  });
}

function handleDocumentWrite(content) {
  document.getElementById("content").innerHTML += content;
}
window.document.write = handleDocumentWrite;

async function getMarkdownFileContent(markdownFileUrl) {
  return fetch(markdownFileUrl).then(response => response.text());
}