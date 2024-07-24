import type { Metadata } from 'next';
import './globals.css';
import AuthProvider from '../context/AuthProvider';
import { Toaster } from '@/components/ui/toaster';
export const metadata: Metadata = {
  title: 'TruVoice',
  description: 'Real feedback from real people.',
};

interface RootLayoutProps {
  children: React.ReactNode;
}

export default function RootLayout({ children }: RootLayoutProps) {
  return (
    <>
      <html lang="en">
        {/* <head>
          <link rel="icon" href="/favicon.ico" />
        </head> */}
        <body>
          <AuthProvider>
            {children}
            <Toaster />
          </AuthProvider>
        </body>
      </html>
    </>
  );
}
