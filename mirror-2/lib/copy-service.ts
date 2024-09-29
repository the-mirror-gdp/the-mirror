// function that returns the app name by checking the environment variable
export const appName = () => {
  const appName = process.env.NEXT_PUBLIC_APP_NAME;
  if (appName) {
    return appName;
  } else {
    return "The Mirror";
  }
};

// app full name with brief tagline
export const appFullName = () => {
  const name = appName()
  if (name === "Reflekt") {
    return `${name}: Web3 Game Engine`;
  } else {
    return `${name}: Game Development Platform`;
  }
};
