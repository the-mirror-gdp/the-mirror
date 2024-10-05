
import React, { useEffect, useState } from 'react';
import Image from 'next/image';

interface AssetThumbnailProps {
  imageUrl: string;
  name: string;
  size?: number;
}

const AssetThumbnail: React.FC<AssetThumbnailProps> = ({ imageUrl, name, size = 64 }) => {
  // primarily used for dev since haven't up storage on seed data 2024-10-04 21:58:50
  const [devImgSrc, setDevImgSrc] = useState(imageUrl);
  useEffect(() => {
    if (process.env.NODE_ENV === 'development') {
      setDevImgSrc("/dev/150.jpg")
    }
  }, [])
  return (
    <div className="text-center">
      <Image
        src={imageUrl || devImgSrc}
        alt={name}
        className="w-full h-auto rounded-lg mb-2"
        width={150}
        height={150}
      />
      <p>{name}</p>
    </div>
  )
};

export default AssetThumbnail;
