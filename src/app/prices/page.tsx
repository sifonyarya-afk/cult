"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { Chrome } from "@/components/clinic/chrome";
import { devices, infusions, services } from "@/lib/catalog";
import { Input } from "@/components/ui/input";

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
  const [query, setQuery] = useState("");
  const [chip, setChip] = useState("Все");
  const needle = query.trim().toLowerCase();
  const visible = useMemo(
    () =>
      groups
        .filter((group) => chip === "Все" || group.title === chip)
        .map((group) => ({
          ...group,
          rows: group.rows.filter((row) => !needle || row.name.toLowerCase().includes(needle) || row.meta.toLowerCase().includes(needle)),
        }))
        .filter((group) => group.rows.length > 0),
    [chip, needle],
  );

  return (
    <Chrome active="services" fab="calendar">
      <main className="px-container-margin pt-6">
        <p className="font-label-md mb-2 tracking-[0.2em] text-primary uppercase">Клиника</p>
        <h1 className="font-headline-lg text-headline-lg-mobile mb-2">Прайс</h1>
        <p className="mb-4 text-on-surface-variant">Интерактивный список. Точная сумма подтверждается на консультации.</p>
        <Input
          value={query}
          onChange={(event) => setQuery(event.target.value)}
          placeholder="Найти услугу"
          aria-label="Найти услугу"
          className="mb-4 h-11 bg-white"
        />
        <div className="mb-8 flex gap-2 overflow-x-auto">
          {["Все", ...groups.map((group) => group.title)].map((title) => (
            <button
              key={title}
              className={`shrink-0 rounded-full px-4 py-2 text-sm ${chip === title ? "bg-on-background text-white" : "bg-white text-on-surface"}`}
              onClick={() => setChip(title)}
            >
              {title}
            </button>
          ))}
        </div>
        {visible.length === 0 ? (
          <p className="rounded-xl border border-dashed border-outline-variant px-4 py-12 text-center text-on-surface-variant">
            Ничего не найдено. Сбросьте фильтр или измените запрос.
          </p>
        ) : (
          <div className="space-y-8">
            {visible.map((group) => (
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
        )}
      </main>
    </Chrome>
  );
}
