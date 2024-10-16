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
    },
  ],
  images: {
    domains: ["images.unsplash.com", "127.0.0.1", "localhost", "picsum.photos"],
  },
};

module.exports = nextConfig;
