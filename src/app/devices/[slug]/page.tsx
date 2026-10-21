"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { Chrome } from "@/components/clinic/chrome";
import { Icon } from "@/components/clinic/icon";
import { deviceBySlug, mediaIds } from "@/lib/catalog";
import { useClinic } from "@/components/clinic/providers";

export default function DevicePage() {
  const params = useParams<{ slug: string }>();
  const device = deviceBySlug(params.slug);
  const { openBooking } = useClinic();

  if (!device) {
    return (
      <Chrome active="services" nav="device" fab="none" brand="infusion">
        <main className="px-container-margin py-12 text-center">
          <p className="mb-3">Аппарат не найден.</p>
          <Link href="/hardware" className="text-primary underline">
            К аппаратной косметологии
          </Link>
        </main>
      </Chrome>
    );
  }

  return (
    <Chrome active="services" nav="device" fab="none" brand="infusion">
      <main>
        <img src={device.hero} alt={device.title} className="h-64 w-full object-cover" />
        <div className="px-container-margin pt-6">
          <span className="font-label-md tracking-widest text-primary uppercase">Advanced Hardware</span>
          <h1 className="font-headline-xl text-[40px] leading-none">{device.title}</h1>
          <p className="font-headline-sm mb-4 italic text-on-surface-variant">{device.italic}</p>
          <div className="mb-6 flex flex-wrap gap-4 text-sm">
            <span className="flex items-center gap-1">
              <Icon name="schedule" className="text-primary" /> {device.duration.toUpperCase()}
            </span>
            <span className="flex items-center gap-1">
              <Icon name="location_on" className="text-primary" /> {device.zone}
            </span>
            <span className="flex items-center gap-1">
              <Icon name="payments" className="text-primary" /> {device.price}
            </span>
          </div>
          <h2 className="font-headline-sm mb-3">О процедуре</h2>
          {device.about.map((paragraph) => (
            <p key={paragraph} className="mb-3 text-on-surface-variant">
              {paragraph}
            </p>
          ))}
          <button className="my-6 w-full bg-on-background py-4 font-label-md tracking-widest text-white uppercase" onClick={() => openBooking(device.title)}>
            Записаться на процедуру
          </button>
          <h2 className="font-headline-sm mb-3">Показания</h2>
          <ul className="mb-6 space-y-2">
            {device.indications.map((item) => (
              <li key={item} className="border-b border-outline-variant/30 py-2">
                {item}
              </li>
            ))}
          </ul>
          <blockquote className="mb-8 border-l-2 border-secondary-container pl-4 italic text-on-surface-variant">
            «{device.quote}»
          </blockquote>
          <h2 className="font-headline-sm mb-3">Результаты</h2>
          <div className="mb-4 grid grid-cols-2 gap-3">
            <figure>
              <img src={mediaIds.deviceAfter} alt="После" className="h-36 w-full rounded-lg object-cover" />
              <figcaption className="mt-1 text-xs uppercase">После</figcaption>
            </figure>
            <figure>
              <img src={mediaIds.deviceBefore} alt="До" className="h-36 w-full rounded-lg object-cover" />
              <figcaption className="mt-1 text-xs uppercase">До</figcaption>
            </figure>
          </div>
          <h3 className="font-headline-sm mb-2">Преображение кожи</h3>
          <p className="mb-4 text-on-surface-variant">
            Наши пациенты отмечают значительное улучшение плотности кожи уже после первого сеанса. Полный курс позволяет достичь эффекта сопоставимого с хирургической подтяжкой.
          </p>
          <div className="mb-4 grid grid-cols-2 gap-3 text-center">
            <div className="rounded-xl bg-surface-container-low p-4">
              <p className="font-headline-md">98%</p>
              <p className="text-xs">Довольных пациентов</p>
            </div>
            <div className="rounded-xl bg-surface-container-low p-4">
              <p className="font-headline-md">2-3 года</p>
              <p className="text-xs">Стойкий эффект</p>
            </div>
          </div>
          <ul className="space-y-3">
            {device.checks.map((item) => (
              <li key={item} className="flex items-start gap-2">
                <Icon name="check_circle" className="text-primary" />
                <span>{item}</span>
              </li>
            ))}
          </ul>
        </div>
      </main>
    </Chrome>
  );
}
