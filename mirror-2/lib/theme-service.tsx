import Image from 'next/image'

// function that returns the app name by checking the environment variable
export const appName = () => {
  const appName = process.env.NEXT_PUBLIC_APP_NAME;
  if (appName === "Reflekt") {
    return <>Reflekt</>;
  } else {
    return <>The&nbsp;Mirror</>;
  }
};

export const appLogoImageSmall = () => {
  const appName = process.env.NEXT_PUBLIC_APP_NAME;

  if (appName === "Reflekt") {
    return <Image src="/reflekt_logo_with_text_sm.png" width={159} height={40} alt="Reflekt Logo" />;
  } else {
    return <Image src="/mirror_logo_white_sm.png" width={159} height={40} alt="Mirror Logo" />;
  }
};
