"use client";

import { useState } from "react";
import Link from "next/link";
import { Chrome } from "@/components/clinic/chrome";
import { Icon } from "@/components/clinic/icon";
import { devices, mediaIds } from "@/lib/catalog";
import { useClinic } from "@/components/clinic/providers";

export default function HardwarePage() {
  const { openBooking } = useClinic();
  const [zone, setZone] = useState<"face" | "body">("face");
  return (
    <Chrome active="services" nav="pill" fab="dual" brand="wordmark">
      <main>
        <section className="px-container-margin pt-6 text-center">
          <img src={mediaIds.hardwareHero} alt="" className="mb-6 h-[280px] w-full rounded-xl object-cover" />
          <h2 className="font-headline-xl text-[40px] leading-tight">
            Аппаратная
            <br />
            Косметология
          </h2>
          <div className="mt-6 mb-6 flex justify-center gap-3">
            <button
              className={`rounded-full px-8 py-2 font-label-md tracking-widest uppercase ${zone === "face" ? "bg-primary text-white" : "bg-surface-container-high text-on-surface-variant"}`}
              onClick={() => setZone("face")}
            >
              Лицо
            </button>
            <button
              className={`rounded-full px-8 py-2 font-label-md tracking-widest uppercase ${zone === "body" ? "bg-primary text-white" : "bg-surface-container-high text-on-surface-variant"}`}
              onClick={() => setZone("body")}
            >
              Тело
            </button>
          </div>
          <p className="font-body-lg mx-auto max-w-md text-on-surface-variant">
            Синтез медицинских инноваций и эстетического совершенства. Мы используем передовые технологии мирового уровня для мгновенного и долгосрочного преображения.
          </p>
        </section>
        <section className="mt-10 space-y-8 px-container-margin">
          <h3 className="font-headline-md text-center tracking-[0.2em] text-primary uppercase">Процедуры</h3>
          {zone === "body" ? (
            <div className="rounded-xl border border-dashed border-outline-variant bg-white px-6 py-14 text-center">
              <p className="font-headline-sm mb-2">Для тела пока нет программ</p>
              <p className="text-on-surface-variant">В этом сезоне аппаратные протоколы собраны для лица и шеи.</p>
            </div>
          ) : (
            devices.map((device) => (
              <Link key={device.slug} href={`/devices/${device.slug}`} className="block overflow-hidden rounded-xl border border-outline-variant/20 bg-white luxury-shadow">
                <div className="relative h-52">
                  <img src={device.image} alt="" className="h-full w-full object-cover" />
                  <span className={`absolute top-4 left-4 rounded-full px-4 py-1 font-label-md text-[11px] tracking-wider uppercase ${device.badgeClass}`}>
                    {device.badge}
                  </span>
                </div>
                <div className="p-6">
                  <div className="mb-3 flex items-start justify-between gap-3">
                    <h4 className="font-headline-md">{device.title}</h4>
                    <span className="font-headline-sm text-primary">{device.priceShort}</span>
                  </div>
                  <p className="mb-4 text-on-surface-variant">{device.blurb}</p>
                  <div className="flex gap-4 border-t border-outline-variant/30 pt-4 font-label-md text-on-surface-variant uppercase">
                    <span className="flex items-center gap-1">
                      <Icon name="schedule" className="text-[20px]" /> {device.duration}
                    </span>
                    <span>{device.zoneLabel}</span>
                  </div>
                </div>
              </Link>
            ))
          )}
        </section>
        <section className="mt-10 px-container-margin">
          <div className="rounded-xl bg-primary p-8 text-center text-white">
            <h3 className="font-headline-lg text-headline-lg-mobile mb-4">Готовы к преображению?</h3>
            <p className="mb-6 opacity-90">Запишитесь на консультацию к нашим экспертам сегодня.</p>
            <button className="rounded-full bg-white px-10 py-4 font-label-md tracking-widest text-on-background uppercase" onClick={() => openBooking("Аппаратная косметология")}>
              Записаться
            </button>
          </div>
        </section>
      </main>
    </Chrome>
  );
}
