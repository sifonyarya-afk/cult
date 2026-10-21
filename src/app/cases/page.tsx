"use client";

import Link from "next/link";
import { Chrome } from "@/components/clinic/chrome";
import { cases } from "@/lib/catalog";

export default function CasesPage() {
  return (
    <Chrome active="gallery" nav="device" fab="none" brand="infusion">
      <main className="px-container-margin pt-6">
        <p className="font-label-md mb-2 tracking-[0.2em] text-primary uppercase">Результаты</p>
        <h1 className="font-headline-lg text-headline-lg-mobile mb-6">Кейсы</h1>
        <div className="space-y-6">
          {cases.map((item) => (
            <Link key={item.slug} href={`/cases/${item.slug}`} className="block overflow-hidden rounded-xl bg-white luxury-shadow">
              <img src={item.image} alt="" className="h-44 w-full object-cover" />
              <div className="p-4">
                <p className="text-xs tracking-widest text-primary uppercase">{item.procedure}</p>
                <h2 className="font-headline-sm">{item.title}</h2>
                <p className="text-sm text-on-surface-variant">{item.doctor}</p>
              </div>
            </Link>
          ))}
        </div>
      </main>
    </Chrome>
  );
}
