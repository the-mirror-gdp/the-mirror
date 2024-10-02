'use client';
import { useState } from 'react';
import { Input } from '@/components/ui/input';
import { ScrollArea } from '@/components/ui/scroll-area';

const imagesData = [
  // Mock data for images and text (30 items for 10 rows and 3 columns)
  { src: 'https://via.placeholder.com/150', text: 'Image 1' },
  { src: 'https://via.placeholder.com/150', text: 'Image 2' },
  { src: 'https://via.placeholder.com/150', text: 'Image 3' },
  { src: 'https://via.placeholder.com/150', text: 'Image 4' },
  { src: 'https://via.placeholder.com/150', text: 'Image 5' },
  { src: 'https://via.placeholder.com/150', text: 'Image 6' },
  { src: 'https://via.placeholder.com/150', text: 'Image 7' },
  { src: 'https://via.placeholder.com/150', text: 'Image 8' },
  { src: 'https://via.placeholder.com/150', text: 'Image 9' },
  { src: 'https://via.placeholder.com/150', text: 'Image 10' },
  { src: 'https://via.placeholder.com/150', text: 'Image 11' },
  { src: 'https://via.placeholder.com/150', text: 'Image 12' },
  { src: 'https://via.placeholder.com/150', text: 'Image 13' },
  { src: 'https://via.placeholder.com/150', text: 'Image 14' },
  { src: 'https://via.placeholder.com/150', text: 'Image 15' },
  { src: 'https://via.placeholder.com/150', text: 'Image 16' },
  { src: 'https://via.placeholder.com/150', text: 'Image 17' },
  { src: 'https://via.placeholder.com/150', text: 'Image 18' },
  { src: 'https://via.placeholder.com/150', text: 'Image 19' },
  { src: 'https://via.placeholder.com/150', text: 'Image 20' },
  { src: 'https://via.placeholder.com/150', text: 'Image 21' },
  { src: 'https://via.placeholder.com/150', text: 'Image 22' },
  { src: 'https://via.placeholder.com/150', text: 'Image 23' },
  { src: 'https://via.placeholder.com/150', text: 'Image 24' },
  { src: 'https://via.placeholder.com/150', text: 'Image 25' },
  { src: 'https://via.placeholder.com/150', text: 'Image 26' },
  { src: 'https://via.placeholder.com/150', text: 'Image 27' },
  { src: 'https://via.placeholder.com/150', text: 'Image 28' },
  { src: 'https://via.placeholder.com/150', text: 'Image 29' },
  { src: 'https://via.placeholder.com/150', text: 'Image 30' },
  { src: 'https://via.placeholder.com/150', text: 'Image 11' },
  { src: 'https://via.placeholder.com/150', text: 'Image 12' },
  { src: 'https://via.placeholder.com/150', text: 'Image 13' },
  { src: 'https://via.placeholder.com/150', text: 'Image 14' },
  { src: 'https://via.placeholder.com/150', text: 'Image 15' },
  { src: 'https://via.placeholder.com/150', text: 'Image 16' },
  { src: 'https://via.placeholder.com/150', text: 'Image 17' },
  { src: 'https://via.placeholder.com/150', text: 'Image 18' },
  { src: 'https://via.placeholder.com/150', text: 'Image 19' },
  { src: 'https://via.placeholder.com/150', text: 'Image 20' },
  { src: 'https://via.placeholder.com/150', text: 'Image 21' },
  { src: 'https://via.placeholder.com/150', text: 'Image 22' },
  { src: 'https://via.placeholder.com/150', text: 'Image 23' },
  { src: 'https://via.placeholder.com/150', text: 'Image 24' },
  { src: 'https://via.placeholder.com/150', text: 'Image 25' },
  { src: 'https://via.placeholder.com/150', text: 'Image 26' },
  { src: 'https://via.placeholder.com/150', text: 'Image 27' },
  { src: 'https://via.placeholder.com/150', text: 'Image 28' },
  { src: 'https://via.placeholder.com/150', text: 'Image 29' },
  { src: 'https://via.placeholder.com/150', text: 'Image 30' }

];

export default function Assets() {
  const [searchTerm, setSearchTerm] = useState('');

  const filteredImages = imagesData.filter((image) =>
    image.text.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="flex flex-col h-screen">
      {/* Search bar */}
      <Input
        type="text"
        placeholder="Search"
        value={searchTerm}
        onChange={(e) => setSearchTerm(e.target.value)}
        className="mb-4 w-full"
      />

      {/* Scrollable area that takes up remaining space */}
      <div className="flex-1 overflow-auto">
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4 p-4 pb-16">
          {filteredImages.map((image, index) => (
            <div key={index} className="text-center ">
              <img
                src={image.src}
                alt={image.text}
                className="w-full h-auto rounded-lg mb-2"
              />
              <p>{image.text}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
