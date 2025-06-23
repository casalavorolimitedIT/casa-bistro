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
        price: 0,
        items: [
          {
            id: 1,
            name: "Yamarita",
            price: 6000,
            description: "Yam coated in egg and bell pepper",
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
            id: 6,
            name: "Noodles and Eggs",
            price: 6000,
            description: "Noodles and Eggs",
          },
          {
            id: 7,
            name: "Custard with Akara",
            price: 6000,
            description: "Warm custard served with bean cakes",
          },
          {
            id: 8,
            name: "Sweet Potato with Egg Sauce",
            price: 6000,
            description: "Boiled or fried sweet potato with savory egg sauce",
          },
        ],
      },
      {
        id: 4,
        name: "Club Sandwich",
        price: 6000,
      },
    ],
  },

  // (unchanged MainCourse and others)

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
        price: 0,
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
          {
            id: 6,
            name: "Plantain",
            price: 3200,
          },
          {
            id: 7,
            name: "Extra Plantain",
            price: 1500,
          },
          {
            id: 8,
            name: "Spring Roll & Samosa",
            price: 4000,
            description: "Crispy spring roll and samosa mix",
          },
          {
            id: 9,
            name: "Tofu",
            price: 4000,
            description: "Lightly fried tofu cubes",
          },
        ],
      },
    ],
  },

  // (no changes to other categories)
};
