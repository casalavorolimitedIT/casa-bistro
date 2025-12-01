"use client";
import React from "react";

interface ChristmasCombo {
  id: string;
  name: string;
  description: string;
  items: {
    category: string;
    details: string[];
  }[];
  price: number;
  featured?: boolean;
}

const christmasCombos: ChristmasCombo[] = [
  {
    id: "combo-1",
    name: "The Nigerian Feast",
    description: "Rich, traditional Nigerian flavors for a festive celebration",
    price: 57600,
    featured: true,
    items: [
      {
        category: "Appetizer",
        details: ["Spicy Pepper Soup (fish, goat meat, or chicken)", "Fresh Fruit Salad"]
      },
      {
        category: "Main Course",
        details: ["Smokey Jollof Rice", "Poundo Yam with Egusi or Efo Riro or Oha Soup"]
      },
      {
        category: "Protein",
        details: ["Asun Goat Meat", "Grilled Cat Fish with Salad"]
      },
      {
        category: "Sides",
        details: ["Spicy Puff", "Plantain Skewers"]
      },
      {
        category: "Drinks",
        details: ["Natural Hibiscus Juice (Zobo)", "Fresh Juice"]
      }
    ]
  },
  {
    id: "combo-2",
    name: "The Continental",
    description: "Popular continental festive meal choices with international flair",
    price: 65500,
    items: [
      {
        category: "Main Course",
        details: ["Casa Special Rice", "Chinese Rice"]
      },
      {
        category: "Appetizer",
        details: ["Samosa Spring Roll"]
      },
      {
        category: "Protein",
        details: ["Grilled Spicy Croaker Atlanta", "Spicy Chicken Skewers", "Honey Glazed Chicken Skewers"]
      },
      {
        category: "Sides",
        details: ["Classic Chef Salad"]
      },
      {
        category: "Drinks",
        details: ["Apple Date Milkshake", "Fruit Parfait"]
      }
    ]
  },
  {
    id: "combo-3",
    name: "Afro Continental Fusion",
    description: "Blends popular local dishes with continental fusion",
    price: 73500,
    items: [
      {
        category: "Rice Selection",
        details: ["Chinese Rice or Biryani Rice", "Coconut Rice or Local Jollof"]
      },
      {
        category: "Appetizers",
        details: ["Samosa & Spring Rolls", "Spicy Puff"]
      },
      {
        category: "Protein",
        details: ["Grilled Spicy Cat Fish", "Chicken Skewers", "Peppered Snail"]
      },
      {
        category: "Sides & Salads",
        details: ["Ceasar Salad"]
      },
      {
        category: "Drinks",
        details: ["Zobo Frappe", "Fruit Parfait"]
      }
    ]
  },
  {
    id: "combo-4",
    name: "The Natural",
    description: "Nature's Delight - The Ultimate Natural Fruit Meal",
    price: 20000,
    items: [
      {
        category: "Main Feature",
        details: ["Premium Fruit Platter"]
      }
    ]
  }
];

export default function ChristmasMenu() {
  return (
    <div className="min-h-screen p-6 sm:p-10 font-sans text-gray-800 relative overflow-hidden">
      {/* Christmas-themed Background */}
      <div className="fixed inset-0 z-0 bg-gradient-to-br from-red-900 via-green-900 to-red-800">
        <div className="absolute inset-0 bg-[url('/christmas-pattern.png')] opacity-10"></div>
        {/* Christmas decoration elements */}
        <div className="absolute top-10 left-10 w-8 h-8 bg-red-500 rounded-full animate-pulse"></div>
        <div className="absolute top-20 right-20 w-6 h-6 bg-green-500 rounded-full animate-pulse delay-300"></div>
        <div className="absolute bottom-20 left-20 w-7 h-7 bg-gold-500 rounded-full animate-pulse delay-700"></div>
      </div>

      {/* Glassmorphism Overlay */}
      <div className="fixed inset-0 z-0 backdrop-filter backdrop-blur-lg bg-white/5" />

      {/* Header Section */}
      <header className="relative z-10 flex flex-col items-center justify-center pt-8 pb-12">
        <div className="text-center mb-6">
          <div className="w-16 h-16 bg-red-600 rounded-full flex items-center justify-center mx-auto mb-4">
            <span className="text-white text-2xl">🎄</span>
          </div>
          <h1 className="text-4xl sm:text-5xl font-extrabold text-white tracking-tight leading-tight text-center">
            Casa Classic Christmas Menu
          </h1>
          <p className="text-gold-200 text-xl mt-4 text-center max-w-prose">
            Festive Combos for a Memorable Celebration
          </p>
          <div className="mt-2 flex justify-center space-x-2">
            <span className="text-red-300">✨</span>
            <span className="text-green-300">🎅</span>
            <span className="text-gold-300">🌟</span>
          </div>
        </div>
      </header>

      {/* Christmas Combos */}
      <main className="relative z-10 max-w-6xl mx-auto">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {christmasCombos.map((combo) => (
            <div
              key={combo.id}
              className={`bg-white/90 backdrop-blur-sm rounded-2xl shadow-2xl p-8 hover:shadow-2xl transition-all duration-300 transform hover:-translate-y-2 border-2 ${
                combo.featured 
                  ? 'border-red-500 ring-4 ring-red-200 ring-opacity-50' 
                  : 'border-green-300'
              }`}
            >
              {/* Combo Header */}
              <div className="text-center mb-6">
                <h2 className="text-2xl font-bold text-red-700 mb-2">
                  {combo.name}
                </h2>
                <p className="text-gray-600 mb-4">{combo.description}</p>
                {combo.featured && (
                  <span className="inline-block bg-red-600 text-white px-4 py-1 rounded-full text-sm font-semibold mb-4">
                    🎁 Featured Combo
                  </span>
                )}
                <div className="text-3xl font-bold text-green-700">
                  ₦{combo.price.toLocaleString()}
                </div>
              </div>

              {/* Combo Items */}
              <div className="space-y-4">
                {combo.items.map((itemGroup, index) => (
                  <div key={index} className="border-l-4 border-green-500 pl-4">
                    <h3 className="font-semibold text-green-700 text-lg mb-2">
                      {itemGroup.category}
                    </h3>
                    <ul className="space-y-1">
                      {itemGroup.details.map((detail, detailIndex) => (
                        <li key={detailIndex} className="text-gray-700 flex items-start">
                          <span className="text-green-500 mr-2">•</span>
                          {detail}
                        </li>
                      ))}
                    </ul>
                  </div>
                ))}
              </div>

              {/* Order Button */}
              <div className="mt-6 text-center">
                <button className="bg-gradient-to-r from-red-600 to-green-600 text-white px-8 py-3 rounded-full font-semibold hover:from-red-700 hover:to-green-700 transition-all duration-300 transform hover:scale-105 shadow-lg">
                  Order {combo.name}
                </button>
              </div>
            </div>
          ))}
        </div>

        {/* Special Christmas Note */}
        {/* <div className="mt-12 text-center bg-white/80 backdrop-blur-sm rounded-2xl p-8 border-2 border-gold-300">
          <h3 className="text-2xl font-bold text-red-700 mb-4">
            🎅 Christmas Special Notes
          </h3>
          <p className="text-gray-700 mb-4">
            All combos serve 4-6 people. Pre-orders recommended for Christmas Eve and Christmas Day.
          </p>
          <div className="flex justify-center space-x-4 text-sm text-gray-600">
            <span>📞 080-CASA-BISTRO</span>
            <span>📍 Kubwa, Abuja</span>
            <span>🕒 24/7 Christmas Service</span>
          </div>
        </div> */}
      </main>
    </div>
  );
}