import type { Metadata } from "next";
import "./globals.css";
import { ThemeProvider, themeInitScript } from "@/design/ThemeProvider";
import { AuthProvider } from "@/controllers/auth/AuthContext";

export const metadata: Metadata = {
  title: "Apparule",
  description:
    "Precision measurement meets social fashion — capture your measurements, discover designers, commission outfits.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    // suppressHydrationWarning: the pre-paint script may set data-theme
    // before React hydrates the <html> element.
    <html lang="en" className="h-full antialiased" suppressHydrationWarning>
      <head>
        {/* Apply the persisted manual theme override before first paint. */}
        <script dangerouslySetInnerHTML={{ __html: themeInitScript }} />
      </head>
      <body className="min-h-full flex flex-col bg-bg text-text">
        <ThemeProvider>
          <AuthProvider>{children}</AuthProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
