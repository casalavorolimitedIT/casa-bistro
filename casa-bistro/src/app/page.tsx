// pages/index.tsx

import React from "react";
import Image from "next/image";

// Define interfaces for a menu item and menu category


import { menuData } from "./MenuData";
 
export default function Home() {
  return (
    <div className="min-h-screen p-8 pb-20 gap-16 sm:p-20 font-[family-name:var(--font-geist-sans)]">
      <div
        className="fixed inset-0 z-0 imageDark"
        style={{
          backgroundImage: "url('/banner.png')", // Replace with your image path
          backgroundSize: "cover",
          backgroundPosition: "center",
        }}
      >
        {/* Shadow overlay */}
        <div className="absolute inset-0 bg-black/50"></div>
      </div>
      <div
        className="fixed inset-0 z-0 imageLight"
        style={{
          backgroundImage: "url('/banner2.png')", // Replace with your image path
          backgroundSize: "cover",
          backgroundPosition: "center",
        }}
      >
        
      </div>
      <h1 className="text-2xl font-bold mb-8 text-center flex justify-start items-center w-full relative z-10">
        <Image
          src="/casalogo2.png"
          alt="logo"
          width={100}
          height={100}
          className="self-start imageDark"
        />
        <Image
          src="/casalogo.png"
          alt="logo"
          width={100}
          height={100}
          className="self-start imageLight"
        />
        <span className="inline-block">Casa-Bistro</span>
      </h1>

      {/* Loop through each category in the data object */}
      {Object.keys(menuData).map((categoryKey) => {
        const category = menuData[categoryKey];
        return (
          <div key={category.id} className="mb-12 relative z-10 ">
            <h2 className="text-xl font-semibold mb-4 ">{category.name}</h2>
            <ul className="space-y-4">
              {category.items.map((item) => (
                <li key={item.id} className="border p-4 rounded shadow ">
                  <div className="flex justify-between items-center">
                    <span className="font-medium text-[#FFA500]">
                      {item.name}
                    </span>
                    <span className="font-bold">₦{item.price}</span>
                  </div>
                  {item.description && (
                    <p className="text-sm text-gray-600 mt-1">
                      {item.description}
                    </p>
                  )}
                  {/* Render nested items if they exist */}
                  {item.items && (
                    <ul className="mt-4 ml-4 border-l pl-4 space-y-2">
                      {item.items.map((subItem) => (
                        <li key={subItem.id} className="border p-2 rounded">
                          <div className="flex justify-between items-center">
                            <span>{subItem.name}</span>
                            <span className="font-bold">₦{subItem.price}</span>
                          </div>
                          {subItem.description && (
                            <p className="text-xs text-gray-500">
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
          </div>
        );
      })}
    </div>
  );
}
