"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { Chrome } from "@/components/clinic/chrome";
import { formatVisitDate, pastVisits } from "@/lib/catalog";
import { Icon } from "@/components/clinic/icon";
import { useClinic } from "@/components/clinic/providers";

export default function VisitsPage() {
  const { appointments, cancelVisit } = useClinic();
  const [loading, setLoading] = useState(true);
  const [receipt, setReceipt] = useState<(typeof pastVisits)[number] | null>(null);
  useEffect(() => {
    const timer = window.setTimeout(() => setLoading(false), 700);
    return () => window.clearTimeout(timer);
  }, []);

  const upcoming = appointments.filter((visit) => visit.status === "upcoming");

  return (
    <Chrome active="profile" fab="none">
      <main className="px-container-margin pt-6">
        <Link href="/cabinet" className="mb-4 inline-flex items-center gap-1 text-primary">
          <Icon name="arrow_back" />
          Кабинет
        </Link>
        <h1 className="font-headline-lg text-headline-lg-mobile mb-6">Визиты</h1>
        {loading ? (
          <div className="space-y-3" aria-busy="true">
            <div className="h-24 animate-pulse rounded-xl bg-surface-container" />
            <div className="h-24 animate-pulse rounded-xl bg-surface-container" />
            <div className="h-24 animate-pulse rounded-xl bg-surface-container" />
          </div>
        ) : (
          <>
            <section className="mb-8">
              <h2 className="font-label-md mb-3 tracking-widest text-outline uppercase">Предстоящие</h2>
              {upcoming.length === 0 ? (
                <div className="rounded-xl border border-dashed border-outline-variant bg-white p-6 text-center">
                  <Icon name="event_busy" className="mb-2 text-outline" />
                  <p className="font-medium">Предстоящих визитов нет</p>
                  <Link href="/booking" className="mt-2 inline-block text-sm text-primary underline">
                    Записаться
                  </Link>
                </div>
              ) : (
                <ul className="space-y-3">
                  {upcoming.map((visit) => (
                    <li key={visit.id} className="rounded-xl bg-white p-4 luxury-shadow">
                      <p className="text-sm text-outline">
                        {formatVisitDate(visit.date)} · {visit.time}
                      </p>
                      <p className="font-headline-sm">{visit.service}</p>
                      <p className="text-sm text-on-surface-variant">{visit.doctor}</p>
                      <button className="mt-3 text-sm font-bold text-error uppercase" onClick={() => cancelVisit(visit.id)}>
                        Отменить
                      </button>
                    </li>
                  ))}
                </ul>
              )}
            </section>
            <section>
              <h2 className="font-label-md mb-3 tracking-widest text-outline uppercase">История</h2>
              <ul className="space-y-3">
                {pastVisits.map((visit) => (
                  <li key={visit.date} className="rounded-xl bg-white p-4 luxury-shadow">
                    <p className="text-sm text-outline">{visit.date}</p>
                    <p className="font-headline-sm">{visit.title}</p>
                    <p className="text-sm text-on-surface-variant">
                      {visit.doctor} · {visit.place}
                    </p>
                    <button className="mt-2 text-sm font-bold text-primary uppercase" onClick={() => setReceipt(visit)}>
                      Чек {visit.receipt}
                    </button>
                  </li>
                ))}
              </ul>
            </section>
          </>
        )}
        {receipt ? (
          <div className="mt-4 rounded-xl border border-outline-variant bg-white p-4">
            <p className="font-label-md uppercase">Чек</p>
            <p className="mt-1">{receipt.title}</p>
            <p className="text-sm text-on-surface-variant">
              {receipt.date} · {receipt.doctor}
            </p>
            <p className="font-headline-sm mt-2">{receipt.receipt}</p>
            <button className="mt-3 text-sm text-primary" onClick={() => setReceipt(null)}>
              Закрыть
            </button>
          </div>
        ) : null}
      </main>
    </Chrome>
  );
}
