import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { ThemeProvider, themeInitScript } from "@/design/ThemeProvider";
import { AuthProvider } from "@/auth/AuthContext";
import SkipLink from "@/components/ui/SkipLink";

// Design-system type (design.md §2): Inter — the family the Figma library
// renders — self-hosted via next/font (variable font, so the ramp's
// 400/600/700 are all real weights, no synthetic bolding). Exposed as a CSS
// variable consumed by the token layer (--ap-font-sans), which keeps the
// system stack as fallback.
const inter = Inter({ subsets: ["latin"], variable: "--font-inter" });

export const metadata: Metadata = {
  // Absolute base for og/twitter images, canonicals and other metadata
  // URLs (SEO plumbing, fleet canon).
  metadataBase: new URL("https://apparule.cuesoft.io"),
  title: "Apparule",
  description:
    "Precision measurement meets social fashion — capture your measurements, discover designers, commission outfits.",
  // Every route's canonical is its own path, resolved against metadataBase.
  alternates: { canonical: "./" },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    // suppressHydrationWarning: the pre-paint script may set data-theme
    // before React hydrates the <html> element.
    <html
      lang="en"
      className={`${inter.variable} h-full antialiased`}
      suppressHydrationWarning
    >
      <head>
        {/* Apply the persisted manual theme override before first paint. */}
        <script dangerouslySetInnerHTML={{ __html: themeInitScript }} />
      </head>
      <body className="min-h-full flex flex-col bg-bg text-text">
        {/* P15 fleet canon: first focusable on every route; targets the
            route's single <main id="main">. */}
        <SkipLink />
        <ThemeProvider>
          <AuthProvider>{children}</AuthProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
