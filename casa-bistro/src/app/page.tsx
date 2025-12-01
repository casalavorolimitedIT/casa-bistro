"use client";
import React, {useState} from "react";
import Image from "next/image";
import { menuData } from "./MenuData"; // Make sure this path is correct for your project
import ChristmasMenu from "./components/ChristmasMenu";
export default function Home() {
   const [showChristmasMenu, setShowChristmasMenu] = useState(false);
  return (
    <>
      <>
     
      
      {showChristmasMenu ? <ChristmasMenu /> : <div></div>}
    </>
      <div className="min-h-screen p-6 sm:p-10 font-sans text-gray-800 dark:text-gray-800 relative overflow-hidden">
        {/* Background Image */}
        <div className="fixed inset-0 z-0">
          <Image
            src="/banner3.jpg" // **Add your image path here**
            alt="Kubwa Market Background"
            layout="fill"
            objectFit="cover"
            quality={80}
            className="filter blur-sm" // Apply a subtle blur to the background image
          />
          {/* Transparent Overlay */}
          <div className="absolute inset-0 bg-black opacity-70"></div> {/* Adjust opacity as needed */}
        </div>

        {/* Glassmorphism Background - Adjusted for less white on bright screens */}
        <div
          className="fixed inset-0 z-0 backdrop-filter backdrop-blur-lg bg-white/5 dark:bg-gray-900/80 opacity-100 transition-opacity duration-300"
        />

        {/* Header Section */}
        <header className="relative z-10 flex flex-col items-center justify-center pt-8 pb-12">
          {/* Logo Image */}
          <Image
            src="/casalogo.png" // Ensure this image path is correct in your 'public' folder
            alt="Casa-Bistro Logo"
            width={120}
            height={120}
            className="mb-4 rounded-full shadow-lg"
          />
          {/* Title - Changed text color for light mode */}
          <h1 className="text-4xl sm:text-5xl font-extrabold text-gray-50 dark:text-white tracking-tight leading-tight text-center">
            Casa-Bistro
          </h1>
          {/* Tagline - Changed text color for light mode */}
          <p className="text-gray-200 dark:text-white text-lg mt-2 text-center max-w-prose">
            Experience culinary excellence with our carefully crafted dishes.
          </p>
        </header>

        {/* Promotional Image */}
         <div className="relative z-10 my-12">
          <Image
            src="/christmas.png" // Ensure this image path is correct in your 'public' folder
            alt="Special Offer"
            width={1200}
            height={600}
            className="w-full max-w-4xl mx-auto rounded-lg shadow-xl"
          />
        </div> 

        {/* Menu Categories */}
        <main className="relative z-10 max-w-6xl mx-auto">
          {Object.keys(menuData).map((categoryKey) => {
            const category = menuData?.[categoryKey]; // Using optional chaining for safety
            return (
              <section key={category?.id} className="mb-16">
                {/* Category Title - Changed text color for light mode */}
                <h2 className="text-3xl font-bold text-gray-200 dark:text-white mb-8 border-b-2 border-orange-400 pb-2">
                  {category?.name}
                </h2>
                <ul className="grid grid-cols-1 md:grid-cols-2 gap-8">
                  {category?.items?.map((item) => (
                    <li
                      key={item.id}
                      className="bg-white/80 dark:bg-gray-800/80 p-6 rounded-lg shadow-md backdrop-filter backdrop-blur-sm hover:shadow-lg transition-shadow duration-300 transform hover:-translate-y-1"
                    >
                      <div className="flex justify-between items-start mb-2">
                        <h3 className="font-semibold text-xl text-orange-600 dark:text-orange-400">
                          {item.name}
                        </h3>
                        <span className="font-bold text-xl text-gray-900 dark:text-gray-100">
                          ₦{item.price}
                        </span>
                      </div>
                      {item.description && (
                        <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                          {item.description}
                        </p>
                      )}
                      {/* Render nested items if they exist */}
                      {item.items && (
                        <ul className="mt-6 ml-4 pl-4 border-l-2 border-gray-200 dark:border-gray-700 space-y-3">
                          {item.items.map((subItem) => (
                            <li
                              key={subItem.id}
                              className="p-3 bg-gray-100/80 dark:bg-gray-700/80 rounded-md shadow-sm backdrop-filter backdrop-blur-sm"
                            >
                              <div className="flex justify-between items-center">
                                <span className="text-base text-gray-700 dark:text-gray-300">
                                  {subItem.name}
                                </span>
                                <span className="font-semibold text-base text-gray-800 dark:text-gray-200">
                                  ₦{subItem.price}
                                </span>
                              </div>
                              {subItem.description && (
                                <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                                  {subItem.description}
                                </p>
                              )}
                            </li>
                          ))}
                        </ul>
                      )}
                    </li>
                  ))}
                </ul>
              </section>
            );
          })}
        </main>
      </div>
    </>
  );
}