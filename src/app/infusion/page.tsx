"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Chrome } from "@/components/clinic/chrome";
import { Icon } from "@/components/clinic/icon";
import { infusions } from "@/lib/catalog";
import { useClinic } from "@/components/clinic/providers";

const chips = ["Energy", "Detox", "Longevity", "Beauty"];

export default function InfusionPage() {
  const router = useRouter();
  const { openBooking } = useClinic();
  const [chip, setChip] = useState<string | null>(null);
  const list = infusions.filter((item) => !chip || chip === "Energy" && item.chip === "Energy" || item.chip === chip);
  const shown = chip === "Detox" ? [] : chip ? list : infusions;

  return (
    <Chrome active="services" nav="english" fab="none" brand="infusion">
      <main className="px-container-margin pt-6">
        <header className="mb-8 text-center">
          <h1 className="font-headline-xl text-[40px] leading-tight mb-3">Инфузионная терапия</h1>
          <p className="font-body-lg text-on-surface-variant">
            Персонализированные коктейли из нутриентов для мгновенного восстановления и клеточного здоровья.
          </p>
        </header>
        <div className="hide-scrollbar mb-8 flex gap-6 overflow-x-auto border-b border-outline-variant/40">
          {chips.map((item) => {
            const active = chip === item || (chip === null && item === "Energy");
            return (
              <button
                key={item}
                className={`pb-3 font-label-md tracking-wider uppercase whitespace-nowrap ${active ? "border-b-2 border-primary text-primary" : "text-on-surface-variant/60"}`}
                onClick={() => setChip(item)}
              >
                {item}
              </button>
            );
          })}
        </div>
        {shown.length === 0 ? (
          <div className="rounded-xl border border-dashed border-outline-variant px-6 py-16 text-center">
            <p className="font-headline-sm mb-2">Detox сейчас недоступен</p>
            <p className="text-on-surface-variant">Коктейли этой группы на паузе. Выберите Energy, Longevity или Beauty.</p>
          </div>
        ) : (
          <div className="space-y-6">
            {shown.map((item) => (
              <article key={item.id} className="overflow-hidden rounded-xl bg-white luxury-shadow">
                <img src={item.image} alt={item.title} className="aspect-[4/3] w-full object-cover" />
                <div className="p-6">
                  <div className="mb-3 flex items-start justify-between gap-3">
                    <h2 className="font-headline-md">{item.title}</h2>
                    <span className="font-headline-sm text-primary">{item.price}</span>
                  </div>
                  <p className="mb-5 text-on-surface-variant">{item.text}</p>
                  <div className="flex items-center justify-between">
                    <span className="flex items-center gap-2 text-outline">
                      <Icon name="schedule" className="text-[18px]" />
                      <span className="font-label-md">{item.minutes}</span>
                    </span>
                    <button
                      className="rounded-full bg-on-background px-6 py-3 font-label-md text-white"
                      onClick={() => openBooking(item.title)}
                    >
                      ЗАБРОНИРОВАТЬ
                    </button>
                  </div>
                </div>
              </article>
            ))}
          </div>
        )}
        <div className="mt-10 rounded-xl border border-secondary-container/50 bg-secondary-container/20 p-6 text-center">
          <h3 className="font-headline-sm mb-2">Нужна консультация?</h3>
          <p className="mb-4 text-on-surface-variant">Наши эксперты помогут подобрать идеальный коктейль под ваши задачи.</p>
          <button className="border-b border-primary font-label-md text-primary" onClick={() => router.push("/chat/specialist")}>
            НАПИСАТЬ СПЕЦИАЛИСТУ
          </button>
        </div>
      </main>
    </Chrome>
  );
}
