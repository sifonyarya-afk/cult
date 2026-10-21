"use client";

import Link from "next/link";
import { Chrome } from "@/components/clinic/chrome";
import { devices, infusions, services } from "@/lib/catalog";

const groups = [
  {
    title: "Эстетика и уход",
    rows: services
      .filter((item) => item.filter !== "Инъекции")
      .map((item) => ({ href: `/services/${item.slug}`, name: item.title, meta: item.duration, price: item.price })),
  },
  {
    title: "Инъекции",
    rows: services
      .filter((item) => item.filter === "Инъекции")
      .map((item) => ({ href: `/services/${item.slug}`, name: item.title, meta: item.duration, price: item.price })),
  },
  {
    title: "Оборудование",
    rows: devices.map((item) => ({ href: `/devices/${item.slug}`, name: item.title, meta: item.duration, price: item.price })),
  },
  {
    title: "Инфузии",
    rows: infusions.map((item) => ({ href: "/infusion", name: item.title, meta: item.minutes, price: item.price })),
  },
];

export default function PricesPage() {
  return (
    <Chrome active="services" fab="calendar">
      <main className="px-container-margin pt-6">
        <p className="font-label-md mb-2 tracking-[0.2em] text-primary uppercase">Клиника</p>
        <h1 className="font-headline-lg text-headline-lg-mobile mb-2">Прайс</h1>
        <p className="mb-8 text-on-surface-variant">Стоимость услуг. Точная сумма подтверждается на консультации.</p>
        <div className="space-y-8">
          {groups.map((group) => (
            <section key={group.title}>
              <h2 className="font-headline-sm mb-3">{group.title}</h2>
              <ul className="divide-y divide-outline-variant/40 rounded-xl bg-white">
                {group.rows.map((row) => (
                  <li key={row.name}>
                    <Link href={row.href} className="flex items-baseline justify-between gap-3 px-4 py-4">
                      <span>
                        <span className="block font-medium">{row.name}</span>
                        <span className="text-xs text-outline uppercase">{row.meta}</span>
                      </span>
                      <span className="font-headline-sm whitespace-nowrap text-primary">{row.price}</span>
                    </Link>
                  </li>
                ))}
              </ul>
            </section>
          ))}
        </div>
      </main>
    </Chrome>
  );
}
