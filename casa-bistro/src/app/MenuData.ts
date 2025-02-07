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
export const menuData: { [key: string]: MenuCategory } = {

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
          {
            id: 16,
            name: "Sides",
            price: 0, // You can set a price of 0 or any value if needed
            items: [
              {
                id: 1,
                name: "Beef Skewer",
                price: 6000,
              },
              {
                id: 2,
                name: "Asun",
                price: 7000,
              },
              {
                id: 3,
                name: "Peppered Kpomo",
                price: 4000,
              },
              {
                id: 4,
                name: "GizzDodo",
                price: 7000,
              },
              {
                id: 5,
                name: "Sharwama",
                price: 6000,
              },
            ],
          },
        ],
      },
      Perppersoup: {
        id: 4,
        name: "Perppersoup",
        items: [
          {
            id: 1,
            name: "Catfish Peppersoup",
            price: 6500,
            description: "A cut of cat fish in spicy broth",
          },
          {
            id: 2,
            name: "Chicken Peppersoup",
            price: 7000,
          },
          {
            id: 3,
            name: "Goat Meat Peppersoup",
            price: 7000,
          },
        ],
      },
      MoreCourses: {
        id: 5,
        name: "More Courses",
        items: [
          {
            id: 1,
            name: "Spaghetti Bolognese",
            price: 9000,
            description: "With plum tomatoes and minced beef ",
          },
          {
            id: 2,
            name: "Coconut Rice",
            price: 7000,
          },
          {
            id: 3,
            name: "Goat Meat Peppersoup",
            price: 4500,
          },
          {
            id: 4,
            name: "Local Jollof",
            price: 7000,
            description: "With dried fish & Kpomo",
          },
          {
            id: 5,
            name: "Chicken Briyani Rice ",
            price: 12000,
            description: "with a serving of chicken",
          },
          {
            id: 6,
            name: "Chinese Rice ",
            price: 6500,
            description: "With diced chicken and scrambled eggs ",
          },
          {
            id: 7,
            name: "Beef Briyani",
            price: 12000,
            description: "With beef serving",
          },
          {
            id: 8,
            name: "Porrige Beans",
            price: 6500,
            description: "with dried fish ",
          },
          {
            id: 9,
            name: "Creamy Shrimp Alfredo pasta",
            price: 12000,
            description: "With shrimp and Mozarella cheese/parmesan cheese",
          },
          {
            id: 10,
            name: "Peri Peri Jollof Rice",
            price: 5500,
          },
          {
            id: 11,
            name: "Teriyaki Madness Bowl",
            price: 10000,
            description: "With chinese noodle, vegetables and diced proteins",
          },
          {
            id: 12, 
            name: "Jambalaya Rice",
            price: 7000,
            
          },
        ],
      },
      Soup: {
        id: 6,
        name: "Soup",
        items: [
          {
            id: 1,
            name: "Egusi",
            price: 2000,
          },
          {
            id: 2,
            name: "Ogbono",
            price: 2000,
          },
          {
            id: 3,
            name: "Sea Food Okra",
            price: 15000,
          },
          {
            id: 4,
            name: "Fisherman Soup",
            price: 18000,
          },
          {
            id: 5,
            name: "Vegetable Soup",
            price: 2000,
          },
          {
            id: 6,
            name: "Ewedu & Gbegiri",
            price: 3000,
          },
          {
            id: 7,
            name: "Oha",
            price: 2000,
          },
          {
            id: 8,
            name: "Miyan Gravy",
            price: 5000,
            description: "All soups are served with either poundo, eba, semo , wheat, amala, tuwo shinkafa",
          },
          {
            id: 9,
            name: "Afang",
            price: 4000,
          },
          {
            id: 10,
            name: "Tomatoe Stew",
            price: 2000,
          },
       
        ],
      },
      Salads: {
        id: 7,
        name: "Salads",
        items: [
          {
            id: 1,
            name: "Harvest Salad",
            price: 18000,
          },
          {
            id: 2,
            name: "Ceasar Salad",
            price: 18000,
          },
          {
            id: 3,
            name: "Local Salad",
            price: 18000,
          },
          {
            id: 4,
            name: "Market salad",
            price: 18000,
          },
          {
            id: 5,
            name: "Coleslaw",
            price: 18000,
          },
          {
            id: 6,
            name: "Chef salad",
            price: 18000,
          },
          {
            id: 7,
            name: "seasonal salad",
            price: 18000,
          },
          {
            id: 8,
            name: "Casa Special Salad",
            price: 18000,
          }
        ],
      },
      Drinks: {
        id: 8,
        name: "Drinks",
        items: [
          {
            id: 1,
            name: "Smoothies",
            price: 6000,
            description: "Banana, Strawberry, Watermelon, Apple Mint, bluespid",
          },
          {
            id: 2,
            name: "Fresh Juice",
            price: 5000,
            description: "Orange, Pineapple, Watermelon",
          },
          {
            id: 3,
            name: "Mixed juice",
            price: 6000,
          },
          {
            id: 4,  
            name: "Packet Juice",
            price: 3000,
          },
          {
            id: 5,
            name: "Casa Special Juice",
            price: 700,
            description: "water",
          }
        ],
      },
    };
    
