"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { Chrome } from "@/components/clinic/chrome";
import { Icon } from "@/components/clinic/icon";
import { services } from "@/lib/catalog";
import { useClinic } from "@/components/clinic/providers";
import { Input } from "@/components/ui/input";

const chips = ["Все услуги", "Эстетика", "Инъекции", "Велнес"];

export default function ServicesPage() {
  const { openBooking } = useClinic();
  const [loading, setLoading] = useState(true);
  const [query, setQuery] = useState("");
  const [chip, setChip] = useState("Все услуги");
  const [more, setMore] = useState(false);

  useEffect(() => {
    const timer = window.setTimeout(() => setLoading(false), 500);
    return () => window.clearTimeout(timer);
  }, []);

  const list = useMemo(() => {
    return services.filter((service) => {
      if (service.hiddenUntilMore && !more && chip === "Все услуги") return false;
      if (chip !== "Все услуги" && service.filter !== chip) return false;
      if (query.trim() && !service.title.toLowerCase().includes(query.trim().toLowerCase())) return false;
      return true;
    });
  }, [chip, more, query]);

  return (
    <Chrome active="services" fab="event" servicesIcon="spa">
      <main className="px-container-margin pt-6">
        <div className="mb-10 text-center">
          <p className="font-label-md mb-4 tracking-[0.2em] text-primary uppercase">Индивидуальный подход</p>
          <h2 className="font-headline-md text-[32px] leading-tight mb-4">
            Консультация, диагностика и персональные программы
          </h2>
          <p className="font-body-lg mb-8 text-on-surface-variant">
            Мы создаем уникальные протоколы ухода, основанные на глубокой диагностике состояния вашей кожи и индивидуальных потребностях организма.
          </p>
          <button className="bg-on-background px-12 py-4 font-label-md tracking-widest text-white uppercase" onClick={() => openBooking("Консультация")}>
            Записаться
          </button>
        </div>
        <div className="mb-8">
          <div className="relative mb-4">
            <Icon name="search" className="absolute top-1/2 left-0 -translate-y-1/2 text-outline-variant" />
            <Input
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="Поиск процедур..."
              className="h-12 rounded-none border-0 border-b border-outline-variant pl-10 shadow-none focus-visible:ring-0"
            />
          </div>
          <div className="hide-scrollbar flex gap-3 overflow-x-auto pb-2">
            {chips.map((item) => (
              <button
                key={item}
                className={`rounded-full px-5 py-2 font-label-md whitespace-nowrap ${item === chip ? "bg-on-background text-white" : "bg-surface-container text-on-surface-variant"}`}
                onClick={() => setChip(item)}
              >
                {item}
              </button>
            ))}
          </div>
        </div>
        {loading ? (
          <div className="space-y-6" aria-busy="true">
            <div className="aspect-[4/5] animate-pulse rounded-lg bg-surface-container" />
            <div className="h-6 w-2/3 animate-pulse bg-surface-container" />
          </div>
        ) : list.length === 0 ? (
          <div className="rounded-xl border border-dashed border-outline-variant py-16 text-center">
            <p className="font-headline-sm">Ничего не найдено</p>
            <p className="mt-2 text-on-surface-variant">Измените запрос или выберите другой фильтр.</p>
          </div>
        ) : (
          <div className="space-y-12">
            {list.map((service) => (
              <Link key={service.slug} href={`/services/${service.slug}`} className="group block">
                <div className="relative mb-4 aspect-[4/5] overflow-hidden rounded-lg">
                  <img src={service.image} alt={service.title} className="h-full w-full object-cover grayscale-[0.3]" />
                  {service.badge ? (
                    <span className="absolute top-4 right-4 bg-on-background/80 px-3 py-1 text-[10px] tracking-widest text-white uppercase">
                      {service.badge}
                    </span>
                  ) : null}
                </div>
                <div className="mb-2 flex items-start justify-between gap-3">
                  <h3 className="font-headline-sm text-headline-sm">{service.title}</h3>
                  <span className="font-headline-sm text-primary whitespace-nowrap">{service.price}</span>
                </div>
                <div className="flex gap-4 font-label-md text-on-surface-variant uppercase">
                  <span className="flex items-center gap-1">
                    <Icon name="schedule" className="text-[18px]" /> {service.duration}
                  </span>
                  <span className="flex items-center gap-1">
                    <Icon name={service.chipIcon} className="text-[18px]" /> {service.chip}
                  </span>
                </div>
                <p className="font-body-md mt-3 line-clamp-2 text-on-surface-variant">{service.blurb}</p>
              </Link>
            ))}
            {chip === "Все услуги" ? (
              <div className="flex aspect-[4/5] flex-col items-center justify-center rounded-lg bg-secondary-container/20 p-8 text-center">
                <Icon name="workspace_premium" className="mb-4 text-5xl text-secondary" />
                <h3 className="font-headline-sm mb-3">Индивидуальный протокол</h3>
                <p className="font-body-md mb-6 text-on-surface-variant">
                  Персональная диагностика и план лечения, разработанный специально под уникальные потребности вашей кожи.
                </p>
                <button className="bg-on-background px-8 py-3 font-label-md tracking-widest text-white uppercase" onClick={() => openBooking("Индивидуальный протокол")}>
                  Записаться на консультацию
                </button>
              </div>
            ) : null}
          </div>
        )}
        <div className="mt-12 text-center">
          <button
            className="border border-outline px-10 py-4 font-label-md tracking-widest text-on-surface-variant uppercase"
            onClick={() => {
              setMore(true);
              setChip("Все услуги");
              setQuery("");
            }}
          >
            Показать все услуги
          </button>
        </div>
      </main>
    </Chrome>
  );
}
