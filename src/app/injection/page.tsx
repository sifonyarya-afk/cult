"use client";

import { useState } from "react";
import Link from "next/link";
import { Chrome } from "@/components/clinic/chrome";
import { Icon } from "@/components/clinic/icon";
import { mediaIds, services } from "@/lib/catalog";

const cards = services.filter((service) => service.filter === "Инъекции");

export default function InjectionPage() {
  const [zone, setZone] = useState<"face" | "body">("face");
  return (
    <Chrome active="services" nav="english" fab="book">
      <main>
        <section className="relative flex h-[420px] flex-col justify-end overflow-hidden px-container-margin pb-8">
          <img src={mediaIds.injectionHero} alt="" className="absolute inset-0 h-full w-full object-cover" />
          <div className="absolute inset-0 bg-gradient-to-t from-surface via-transparent to-transparent" />
          <div className="relative text-center">
            <h1 className="font-headline-xl text-[40px] leading-tight mb-3">
              Инъекционная
              <br />
              косметология
            </h1>
            <p className="font-body-lg text-on-surface-variant">
              Искусство естественного преображения через научный подход и медицинскую точность.
            </p>
          </div>
        </section>
        <div className="mb-6 flex justify-center gap-3 px-container-margin">
          <button className={`rounded-full px-8 py-2 font-label-md tracking-widest uppercase ${zone === "face" ? "bg-primary text-white" : "bg-surface-container-high"}`} onClick={() => setZone("face")}>
            Лицо
          </button>
          <button className={`rounded-full px-8 py-2 font-label-md tracking-widest uppercase ${zone === "body" ? "bg-primary text-white" : "bg-surface-container-high"}`} onClick={() => setZone("body")}>
            Тело
          </button>
        </div>
        <section className="mb-8 px-container-margin">
          <div className="flex gap-4 rounded-xl border border-outline-variant/20 bg-surface-container-low p-5">
            <Icon name="verified_user" className="text-primary" />
            <div>
              <h3 className="font-label-md mb-1">Стандарт безопасности CULT</h3>
              <p className="text-sm text-on-surface-variant">Только сертифицированные препараты и врачи высшей категории.</p>
            </div>
          </div>
        </section>
        <section className="space-y-10 px-container-margin">
          <h2 className="font-headline-md border-b border-outline-variant/40 pb-3">Услуги</h2>
          {zone === "body" ? (
            <div className="rounded-xl border border-dashed border-outline-variant px-6 py-14 text-center">
              <p className="font-headline-sm mb-2">Протоколы для тела готовятся</p>
              <p className="text-on-surface-variant">Сейчас в инъекциях открыты процедуры для лица.</p>
            </div>
          ) : (
            cards.map((service) => (
              <Link key={service.slug} href={`/services/${service.slug}`} className="block">
                <div className="relative mb-4 aspect-[4/3] overflow-hidden rounded-lg luxury-shadow">
                  <img src={service.image} alt={service.title} className="h-full w-full object-cover" />
                  {service.badge ? (
                    <span className="absolute bottom-4 left-4 bg-white/90 px-3 py-1 text-xs tracking-wider text-primary uppercase">{service.badge}</span>
                  ) : null}
                </div>
                <div className="mb-2 flex items-baseline justify-between gap-3">
                  <h3 className="font-headline-sm">{service.title}</h3>
                  <span className="font-headline-sm text-primary">{service.price}</span>
                </div>
                <div className="mb-2 flex gap-4 text-xs text-on-surface-variant">
                  <span className="flex items-center gap-1">
                    <Icon name="schedule" className="text-[16px]" /> {service.duration}
                  </span>
                  <span className="flex items-center gap-1">
                    <Icon name={service.chipIcon} className="text-[16px]" /> {service.chip}
                  </span>
                </div>
                <p className="text-on-surface-variant">{service.blurb}</p>
              </Link>
            ))
          )}
        </section>
      </main>
    </Chrome>
  );
}
