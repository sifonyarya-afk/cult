"use client";

import Link from "next/link";
import { Chrome } from "@/components/clinic/chrome";
import { messengers } from "@/lib/catalog";

const links = [
  ["/about", "О клинике"],
  ["/hardware", "Оборудование"],
  ["/cases", "Кейсы"],
  ["/blog", "Блог и новости"],
  ["/science", "Новые технологии"],
  ["/prices", "Прайс-лист"],
  ["/tv", "YouTube-канал"],
];

export default function MorePage() {
  return (
    <Chrome active="home" fab="none">
      <main className="px-container-margin pt-6">
        <h1 className="font-headline-lg text-headline-lg-mobile mb-6">Клиника</h1>
        <ul className="mb-8 divide-y divide-outline-variant/40 rounded-xl bg-white">
          {links.map(([href, label]) => (
            <li key={href}>
              <Link href={href} className="block px-4 py-4">
                {label}
              </Link>
            </li>
          ))}
        </ul>
        <h2 className="font-headline-sm mb-3">Мессенджеры</h2>
        <div className="flex flex-col gap-3">
          {messengers.map((item) => (
            <a key={item.name} href={item.href} target="_blank" rel="noreferrer" className="rounded-xl border border-outline-variant px-4 py-3 text-center">
              {item.name}
            </a>
          ))}
        </div>
      </main>
    </Chrome>
  );
}
