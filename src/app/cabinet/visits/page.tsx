"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { Chrome } from "@/components/clinic/chrome";
import { pastVisits } from "@/lib/catalog";
import { Icon } from "@/components/clinic/icon";

export default function VisitsPage() {
  const [loading, setLoading] = useState(true);
  useEffect(() => {
    const timer = window.setTimeout(() => setLoading(false), 700);
    return () => window.clearTimeout(timer);
  }, []);

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
              <div className="rounded-xl border border-dashed border-outline-variant bg-white p-6 text-center">
                <Icon name="event_busy" className="mb-2 text-outline" />
                <p className="font-medium">Предстоящих визитов нет</p>
                <p className="mt-1 text-sm text-on-surface-variant">Запишитесь онлайн — слот появится здесь.</p>
              </div>
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
                  </li>
                ))}
              </ul>
            </section>
          </>
        )}
      </main>
    </Chrome>
  );
}
