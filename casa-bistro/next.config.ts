import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  /* config options here */
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: process.env.NEXT_PUBLIC_IMAGE_SUPABASE_URL || "",
        port: "",
        pathname: "/storage/v1/object/public/**",
      },
    ],
  },
};

export default nextConfig;
