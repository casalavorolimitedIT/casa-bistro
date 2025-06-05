import './globals.css'
import { Poppins } from 'next/font/google' // Import Poppins instead of Inter

const poppins = Poppins({
  subsets: ['latin'],
  display: 'swap',
  weight: ['400', '500', '600', '700'], // Specify the weights you want to use
  variable: '--font-poppins', // Define a CSS variable for easier use in Tailwind CSS
})

export const metadata = {
  title: "Casa Bistro",
  description: "Menu bistro ",
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <head>
        {/* Consider using a single favicon and let CSS handle dark/light mode if applicable */}
        <link rel="icon" type="image/png" href="/casalogo.png" />
      </head>
      <body className={`${poppins.variable} font-sans`}> {/* Apply the font variable and a fallback */}
        {children}
      </body>
    </html>
  )
}