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
};

module.exports = nextConfig;
