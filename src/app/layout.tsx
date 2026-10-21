import type { Metadata } from "next";
import { Bodoni_Moda, Cormorant_Garamond, Source_Sans_3 } from "next/font/google";
import "./globals.css";
import { Providers } from "@/components/clinic/providers";

const bodoni = Bodoni_Moda({
  subsets: ["latin"],
  weight: ["500", "600", "700"],
  style: ["normal", "italic"],
  variable: "--font-bodoni",
  display: "swap",
});

const cormorant = Cormorant_Garamond({
  subsets: ["cyrillic", "latin"],
  weight: ["500", "600", "700"],
  style: ["normal", "italic"],
  variable: "--font-cormorant",
  display: "swap",
});

const source = Source_Sans_3({
  subsets: ["cyrillic", "latin"],
  weight: ["400", "500", "600", "700"],
  variable: "--font-source",
  display: "swap",
});

export const metadata: Metadata = {
  title: "CULT Clinic",
  description: "Персональная косметология и биохакинг клиники CULT.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ru">
      <head>
        <link
          rel="stylesheet"
          href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24,300,0..1,0&display=swap"
        />
      </head>
      <body className={`${bodoni.variable} ${cormorant.variable} ${source.variable} antialiased`}>
        <Providers>
          <div className="phone-shell">{children}</div>
        </Providers>
      </body>
    </html>
  );
}
