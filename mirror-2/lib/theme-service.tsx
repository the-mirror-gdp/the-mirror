import { Metadata } from 'next';
import Image from 'next/image'

// function that returns the app name by checking the environment variable
export const appName = () => {
  const appName = process.env.NEXT_PUBLIC_APP_NAME;
  if (appName === "Reflekt") {
    return "Reflekt"
  } else {
    return "The Mirror"
  }
};

export const appDescription = () => {
  const appName = process.env.NEXT_PUBLIC_APP_NAME;
  if (appName === "Reflekt") {
    return "Web3 Game Engine"
  } else {
    return "All-in-One Game Development Platform"
  }
};

export const faviconPath = () => {
  const appName = process.env.NEXT_PUBLIC_APP_NAME;
  if (appName === "Reflekt") {
    return "/favicon-reflekt.ico"
  } else {
    return "/favicon.ico"
  }
}


interface ImageProps {
  width?: number
  height?: number
  className?: any
}

export const AppLogoImageSmall = ({ width = 159, height = 49, ...props }: ImageProps) => {
  const appName = process.env.NEXT_PUBLIC_APP_NAME;

  if (appName === "Reflekt") {
    return <Image src="/reflekt_logo_with_text_sm.png" width={width} height={height} alt="Reflekt Logo" {...props} />;
  } else {
    return <Image src="/mirror_logo_white_sm.png" width={width} height={height} alt="Mirror Logo" {...props} />;
  }
};


export const AppLogoImageMedium = ({ width = 300, height = 40, ...props }: ImageProps) => {
  const appName = process.env.NEXT_PUBLIC_APP_NAME;

  if (appName === "Reflekt") {
    return <Image src="/reflekt_logo_with_text_md.png" width={width} height={height} alt="Reflekt Logo" {...props} />;
  } else {
    return <Image src="/mirror_logo_white_sm.png" width={width} height={height} alt="Mirror Logo" {...props} />;
  }
};
