/** @type {import('next').NextConfig} */
const nextConfig = {
  redirects: () => [
    {
      source: "/",
      destination: "/build",
      permanent: false,
    },
  ],
};

module.exports = nextConfig;
