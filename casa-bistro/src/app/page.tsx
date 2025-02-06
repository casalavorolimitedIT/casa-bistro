// pages/index.tsx

import React from "react";
import Image from "next/image";

// Define interfaces for a menu item and menu category
interface MenuItem {
  id: number;
  name: string;
  price: number;
  description?: string;
  items?: MenuItem[]; // For nested items (e.g., Complimentary Breakfast)
}

interface MenuCategory {
  id: number;
  name: string;
  items: MenuItem[];
}

// Your JSON data converted to a TypeScript object
const data: { [key: string]: MenuCategory } = {
  Breakfast: {
    id: 1,
    name: "Breakfast",
    items: [
      {
        id: 1,
        name: "Full English Breakfast",
        price: 12000,
      },
      {
        id: 2,
        name: "American Breakfast",
        price: 12000,
      },
      {
        id: 3,
        name: "Complimentary Breakfast",
        price: 0, // You can set a price of 0 or any value if needed
        items: [
          {
            id: 1,
            name: "Yamarita",
            price: 6000,
            description: "Yam coated in egg and bell pepper",
          },
          {
            id: 2,
            name: "Masa",
            price: 6000,
            description: "with masa sauce",
          },
          {
            id: 3,
            name: "Pancakes",
            price: 6000,
            description: "Pancakes",
          },
          {
            id: 4,
            name: "Plantain or Yam With Egg Sauce",
            price: 6000,
            description: "fried or boiled",
          },
          {
            id: 5,
            name: "Club Sandwich",
            price: 6000,
            description: "club sandwich",
          },
          {
            id: 6,
            name: "Noodles and Eggs",
            price: 6000,
            description: "Noodles and Eggs",
          },
        ],
      },
    ],
  },
  MainCourse: {
    id: 2,
    name: "Main Course",
    items: [
      {
        id: 1,
        name: "White Rice",
        price: 3000,
        description: "White Rice",
      },
      {
        id: 2,
        name: "Jollof Rice",
        price: 4500,
        description: "Jollof Rice",
      },
      {
        id: 3,
        name: "Local Jollof Rice and Beans",
        price: 5500,
        description: "With dried fish & Kpomo",
      },
      {
        id: 4,
        name: "Caribbean Rice",
        price: 7000,
        description: "With sliced plantain & diced chicken thighs",
      },
      {
        id: 5,
        name: "Turkish Suya Rice",
        price: 6500,
        description: "With diced beef",
      },
      {
        id: 6,
        name: "Egg Fried Rice",
        price: 6500,
        description: "With scrambled eggs",
      },
      {
        id: 7,
        name: "Korean Rice",
        price: 6500,
        description: "With broccoli, cauliflower & sausage",
      },
      {
        id: 8,
        name: "Casa Special Fried Rice",
        price: 7500,
        description: "With diced chicken, beef and sausage",
      },
      {
        id: 9,
        name: "Sea Food Fried Rice",
        price: 7000,
        description: "With shrimps",
      },
    ],
  },
  Protein: {
    id: 3,
    name: "Protein",
    items: [
      {
        id: 1,
        name: "Grilled Chicken",
        price: 6000,
        description: "with ketchup or barbecue",
      },
      {
        id: 2,
        name: "Lemon Garlic Butter Lamb Chops",
        price: 12000,
        description: "with mashed potatoes",
      },
      {
        id: 3,
        name: "Honey Glazed Chicken",
        price: 7000,
        description: "with honey, suya sauce & sesame seeds",
      },
      {
        id: 4,
        name: "Surf and Turf",
        price: 15000,
        description: "Chicken & shrimp",
      },
      {
        id: 5,
        name: "Crispy Chicken",
        price: 6500,
        description: "crispy chicken",
      },
      {
        id: 6,
        name: "Chicken Tikka",
        price: 7000,
        description: "Cubes of chicken breasts",
      },
      {
        id: 7,
        name: "Sweet and Sour Chicken",
        price: 8000,
        description: "with pineapple and bell peppers",
      },
      {
        id: 8,
        name: "Chicken Skewer",
        price: 6000,
        description: "Chicken Skewer",
      },
      {
        id: 9,
        name: "Chicken Vegetable",
        price: 7000,
        description: "Green vegetables",
      },
      {
        id: 10,
        name: "Beef Vegetable",
        price: 7000,
        description: "Beef Vegetable",
      },
      {
        id: 11,
        name: "Turkey",
        price: 7000,
        description: "Turkey",
      },
      {
        id: 12,
        name: "Goat Meat",
        price: 5500,
        description: "Goat Meat",
      },
      {
        id: 13,
        name: "Beef",
        price: 7000,
        description: "Cow Meat",
      },
      {
        id: 14,
        name: "Fried Chicken",
        price: 7000,
        description: "Fried Chicken",
      },
      {
        id: 15,
        name: "Peppered Snail",
        price: 10000,
        description: "Peppered Snail",
      },
    ],
  },
};

export default function Home() {
  return (
    <div className="min-h-screen p-8 pb-20 gap-16 sm:p-20 font-[family-name:var(--font-geist-sans)]">
      <h1 className="text-2xl font-bold mb-8 text-center flex justify-start items-center w-full">
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
      {Object.keys(data).map((categoryKey) => {
        const category = data[categoryKey];
        return (
          <div key={category.id} className="mb-12">
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
