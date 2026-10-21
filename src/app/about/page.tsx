"use client";

import Link from "next/link";
import { Chrome } from "@/components/clinic/chrome";
import { mediaIds } from "@/lib/catalog";

const facts = [
  ["Адрес", "Клинический переулок, 7"],
  ["Часы", "Ежедневно 9:00–21:00"],
  ["Телефон", "+7 495 000-00-07"],
];

export default function AboutPage() {
  return (
    <Chrome active="home" fab="calendar">
      <main className="px-container-margin pt-4">
        <img src={mediaIds.injectionHero} alt="Интерьер CULT" className="mb-5 h-52 w-full rounded-xl object-cover" />
        <p className="font-label-md mb-2 tracking-[0.2em] text-primary uppercase">Exclusive Clinical Sanctuary</p>
        <h1 className="font-headline-lg text-headline-lg-mobile mb-3">О клинике</h1>
        <p className="mb-4 text-on-surface-variant">
          CULT — клиническое святилище: диагностика, аппараты, инъекции и инфузии в одном протоколе. Здесь не собирают «процедуру на час», а ведут кожу и самочувствие как одну историю.
        </p>
        <p className="mb-6 text-on-surface-variant">
          Врачи высшей категории, сертифицированные препараты и аппараты с визуализацией. Запись, трансфер и чат — в этом приложении.
        </p>
        <ul className="mb-8 divide-y divide-outline-variant/40 rounded-xl bg-white">
          {facts.map(([label, value]) => (
            <li key={label} className="flex justify-between gap-4 px-4 py-4">
              <span className="text-outline">{label}</span>
              <span className="text-right font-medium">{value}</span>
            </li>
          ))}
        </ul>
        <div className="grid grid-cols-2 gap-3 text-center text-sm">
          <Link href="/doctors" className="rounded-xl bg-surface-container-low py-4">
            Врачи
          </Link>
          <Link href="/hardware" className="rounded-xl bg-surface-container-low py-4">
            Оборудование
          </Link>
          <Link href="/prices" className="rounded-xl bg-surface-container-low py-4">
            Прайс
          </Link>
          <Link href="/chat" className="rounded-xl bg-surface-container-low py-4">
            Чат клиники
          </Link>
        </div>
      </main>
    </Chrome>
  );
}
