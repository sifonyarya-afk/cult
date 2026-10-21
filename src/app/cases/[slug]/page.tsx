"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { Chrome } from "@/components/clinic/chrome";
import { Story } from "@/components/clinic/story";
import { caseBySlug } from "@/lib/catalog";
import { useClinic } from "@/components/clinic/providers";

export default function CasePage() {
  const params = useParams<{ slug: string }>();
  const item = caseBySlug(params.slug);
  const { openBooking } = useClinic();

  if (!item) {
    return (
      <Chrome active="gallery" nav="device" fab="none">
        <main className="px-container-margin py-12 text-center">
          <p className="mb-3">Кейс не найден.</p>
          <Link href="/cases" className="text-primary underline">
            Все кейсы
          </Link>
        </main>
      </Chrome>
    );
  }

  return (
    <Chrome active="gallery" nav="device" fab="none" brand="infusion">
      <main className="px-container-margin pt-4">
        <Link href="/cases" className="text-sm text-primary">
          Кейсы
        </Link>
        <p className="mt-4 text-xs tracking-widest text-primary uppercase">{item.procedure}</p>
        <h1 className="font-headline-md mb-1">{item.title}</h1>
        <p className="mb-4 text-sm text-outline">{item.doctor}</p>
        <div className="mb-4 grid grid-cols-2 gap-3">
          <figure>
            <img src={item.before} alt="До" className="h-36 w-full rounded-lg object-cover" />
            <figcaption className="mt-1 text-xs uppercase">До</figcaption>
          </figure>
          <figure>
            <img src={item.after} alt="После" className="h-36 w-full rounded-lg object-cover" />
            <figcaption className="mt-1 text-xs uppercase">После</figcaption>
          </figure>
        </div>
        <Story title={item.title} image={item.after} paragraphs={[item.text, item.quote]} />
        <button className="mt-8 w-full bg-on-background py-4 font-label-md tracking-widest text-white uppercase" onClick={() => openBooking(item.procedure)}>
          Записаться на {item.procedure}
        </button>
      </main>
    </Chrome>
  );
}
