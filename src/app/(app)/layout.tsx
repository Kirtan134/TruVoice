import Navbar from '@/components/Navbar';
import { SpeedInsights } from "@vercel/speed-insights/next"

interface RootLayoutProps {
  children: React.ReactNode;
}


export default async function RootLayout({ children }: RootLayoutProps) {
  return (
    <div className="flex flex-col min-h-screen">
      <Navbar />
      {children}
      <SpeedInsights />
    </div>
  );
}
