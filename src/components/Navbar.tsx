"use client";

import { User } from "next-auth";
import { signOut, useSession } from "next-auth/react";
import Image from "next/image";
import Link from "next/link";
import { useState } from "react";
import logo from "../../public/github.png";
import { Button } from "./ui/button";

function Navbar() {
  const { data: session } = useSession();
  const user: User = session?.user;
  const [isOpen, setIsOpen] = useState(false);

  return (
    <nav className="p-4 md:p-6 shadow-md bg-white text-black">
      <div className="container mx-auto flex justify-between items-center">
        <div className="flex items-center">
          <a href="#" className="text-3xl font-bold font-Audiowide tracking-wide">
            TruVoice
          </a>
        </div>
        <div className="md:hidden">
        </div>
        <div className="hidden md:flex md:items-center md:space-x-6">
          {session ? (
            <>
              <span className="text-xl font-serif">
                Welcome, {user.username || user.email}
              </span>
              <a
                href="https://github.com/Kirtan134/TruVoice"
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center text-black bg-white border border-black rounded-full p-2 hover:bg-gray-100 transition duration-300"
              >
                <Image
                  src={logo}
                  alt="github logo"
                  width={30}
                  height={30}
                />
                <span className="font-bold px-2">Github</span>
              </a>
              <Button
                onClick={() => signOut()}
                className="bg-white text-black border border-black hover:bg-gray-100 transition duration-300"
                variant="outline"
              >
                Logout
              </Button>
            </>
          ) : (
            <Link href="/sign-in">
              <Button
                className="bg-white text-black border border-black hover:bg-gray-100 transition duration-300"
                variant="outline"
              >
                Login
              </Button>
            </Link>
          )}
        </div>
        <div className={` md:hidden`}>
          {session ? (
            <Button
              onClick={() => signOut()}
              className="w-full bg-white text-black border border-black hover:bg-gray-100 transition duration-300 mt-4 md:mt-0"
              variant="outline"
            >
              Logout
            </Button>
          ) : (
            <Link href="/sign-in">
              <Button
                className="w-full bg-white text-black border border-black hover:bg-gray-100 transition duration-300 mt-4 md:mt-0"
                variant="outline"
              >
                Login
              </Button>
            </Link>
          )}
        </div>
      </div>
    </nav>
  );
}

export default Navbar;
