export const lightModeQuery = window.matchMedia('(prefers-color-scheme: light)');
export const darkModeQuery = window.matchMedia('(prefers-color-scheme: dark)');

export const applyColorScheme = (handleThemeChange) => {
    if (window.matchMedia) {
        handleThemeChange(lightModeQuery,darkModeQuery);
        lightModeQuery.addEventListener('change', handleThemeChange);
        darkModeQuery.addEventListener('change', handleThemeChange);
    }
};


export const handleDocRenderThemeChange = () => {
    if (lightModeQuery.matches) {
        document.body.classList.remove('dark-theme');
        document.body.classList.add('white-theme');
    } else if (darkModeQuery.matches) {
        document.body.classList.remove('white-theme');
        document.body.classList.add('dark-theme');
    } else {
        document.body.classList.remove('white-theme', 'dark-theme');
    }
};

export const handleLogPageThemeChange = () => {
    const htmlElementDataSet = document.documentElement.dataset;
    if (lightModeQuery.matches) {
        htmlElementDataSet.colorMode = "light";
        delete htmlElementDataSet.darkTheme;
        htmlElementDataSet.lightTheme = "light";
    } else if (darkModeQuery.matches) {
        htmlElementDataSet.colorMode = "dark";
        delete htmlElementDataSet.lightTheme;
        htmlElementDataSet.darkTheme = "dark";
    }
}