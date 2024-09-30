// function that returns the app name by checking the environment variable
export const appName = () => {
  const appName = process.env.NEXT_PUBLIC_APP_NAME;
  if (appName === "Reflekt") {
    return <>Reflekt</>;
  } else {
    return <>The&nbsp;Mirror</>;
  }
};
