"use client";

import Link from "next/link";
import { Chrome } from "@/components/clinic/chrome";
import { doctors } from "@/lib/catalog";

export default function DoctorsPage() {
  return (
    <Chrome active="services" fab="none">
      <main className="px-container-margin pt-6">
        <p className="font-label-md mb-2 tracking-[0.2em] text-primary uppercase">Команда</p>
        <h1 className="font-headline-lg text-headline-lg-mobile mb-6">Врачи</h1>
        <div className="space-y-4">
          {doctors.map((doctor) => (
            <Link key={doctor.slug} href={doctor.href} className="flex gap-4 rounded-xl bg-white p-4 luxury-shadow">
              <img src={doctor.image} alt="" className="h-20 w-20 rounded-full object-cover" />
              <span>
                <span className="font-headline-sm block">{doctor.name}</span>
                <span className="mt-1 block text-sm text-on-surface-variant">{doctor.role}</span>
                <span className="mt-2 block font-label-md text-primary">{doctor.exp}</span>
              </span>
            </Link>
          ))}
        </div>
      </main>
    </Chrome>
  );
}
