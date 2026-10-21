"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { mediaIds } from "@/lib/catalog";
import { useClinic } from "@/components/clinic/providers";
import { Icon } from "@/components/clinic/icon";

export default function SplashPage() {
  const router = useRouter();
  const { setGender, gender } = useClinic();
  const [picked, setPicked] = useState<"m" | "f" | null>(gender);

  useEffect(() => {
    const timer = window.setTimeout(() => router.replace("/welcome"), 2600);
    return () => window.clearTimeout(timer);
  }, [router]);

  function go(next?: "m" | "f") {
    if (next) {
      setGender(next);
      setPicked(next);
    }
    router.replace("/welcome");
  }

  return (
    <main className="relative flex min-h-dvh flex-col items-center justify-between overflow-hidden py-16">
      <div className="absolute inset-0">
        <img src={mediaIds.splash} alt="" className="h-full w-full object-cover" />
        <div className="luxury-overlay absolute inset-0" />
      </div>
      <header className="fade-in relative z-10 px-container-margin">
        <h1 className="font-headline-lg text-headline-lg tracking-[0.3em] text-white uppercase text-shadow-sm">
          CULT
        </h1>
      </header>
      <div className="relative z-10 flex flex-1 items-center px-container-margin text-center">
        <p
          className="fade-in font-headline-md text-headline-md text-white italic text-shadow-sm"
          style={{ animationDelay: "0.3s" }}
        >
          Ваш путь к совершенству начинается в CULT
        </p>
      </div>
      <div className="fade-in relative z-10 flex w-full flex-col items-center px-container-margin" style={{ animationDelay: "0.6s" }}>
        <div className="mb-12 flex gap-8">
          <button className="flex flex-col items-center gap-3" onClick={() => go("m")}>
            <span
              className={`flex h-16 w-16 items-center justify-center rounded-full border border-white/30 bg-white/10 backdrop-blur-sm ${picked === "m" ? "bg-white/30" : ""}`}
            >
              <Icon name="male" className="text-3xl text-white" />
            </span>
            <span className="font-label-md text-label-md tracking-widest text-white uppercase">Мужчина</span>
          </button>
          <button className="flex flex-col items-center gap-3" onClick={() => go("f")}>
            <span
              className={`flex h-16 w-16 items-center justify-center rounded-full border border-white/30 bg-white/10 backdrop-blur-sm ${picked === "f" ? "bg-white/30" : ""}`}
            >
              <Icon name="female" className="text-3xl text-white" />
            </span>
            <span className="font-label-md text-label-md tracking-widest text-white uppercase">Женщина</span>
          </button>
        </div>
        <button
          className="bg-[#1b1c1c] px-16 py-5 font-label-md text-label-md tracking-widest text-white uppercase shadow-xl"
          onClick={() => go()}
        >
          Начать
        </button>
        <p className="mt-8 font-headline-sm text-white/80 italic text-shadow-sm">
          Персональная косметология для каждого
        </p>
      </div>
    </main>
  );
}
