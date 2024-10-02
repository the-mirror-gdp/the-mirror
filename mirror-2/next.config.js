/** @type {import('next').NextConfig} */
const nextConfig = {
  redirects: () => [
    {
      source: "/sign-in",
      destination: "/login",
      permanent: true,
    },
    {
      source: "/sign-up",
      destination: "/create-account",
      permanent: true,
    }
  ],
  images: {
    domains: ['images.unsplash.com'],
  },
};

module.exports = nextConfig;
