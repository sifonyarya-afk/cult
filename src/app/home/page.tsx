"use client";

import Link from "next/link";
import { Chrome } from "@/components/clinic/chrome";
import { Icon } from "@/components/clinic/icon";
import { useClinic } from "@/components/clinic/providers";
import { mediaIds } from "@/lib/catalog";

export default function HomePage() {
  const { openBooking } = useClinic();
  return (
    <Chrome active="home" brand="logo" fab="add">
      <main>
        <section className="mb-10 px-container-margin pt-8">
          <div className="ambient-card relative overflow-hidden rounded-2xl border border-outline-variant bg-surface-container-low p-8">
            <div className="relative z-10">
              <div className="mb-4 flex items-center gap-2">
                <span className="h-2 w-2 rounded-full bg-secondary" />
                <span className="font-label-md text-label-md tracking-widest text-secondary uppercase">
                  Ваш статус: Platinum
                </span>
              </div>
              <h2 className="font-headline-lg text-headline-lg mb-2">Юлия, доброго дня!</h2>
              <p className="font-label-md text-on-surface-variant">
                Рады видеть вас снова в CULT Clinic. Ваша следующая процедура запланирована на завтра.
              </p>
            </div>
          </div>
        </section>
        <section className="mb-10 grid grid-cols-2 gap-4 px-container-margin">
          <button
            className="ambient-card flex flex-col items-center rounded-xl bg-secondary-container p-6 text-on-secondary-container"
            onClick={() => openBooking("Онлайн запись")}
          >
            <Icon name="calendar_month" className="mb-3 text-3xl" />
            <span className="font-label-md text-center">Онлайн запись</span>
          </button>
          <Link href="/cabinet" className="ambient-card flex flex-col items-center rounded-xl bg-surface-container-low p-6">
            <Icon name="biotech" className="mb-3 text-3xl" />
            <span className="font-label-md text-center">Мои анализы</span>
          </Link>
          <Link href="/shop" className="ambient-card flex flex-col items-center rounded-xl bg-surface-container-low p-6">
            <Icon name="shopping_basket" className="mb-3 text-3xl" />
            <span className="font-label-md text-center">Магазин биохакинга</span>
          </Link>
          <Link href="/chat" className="ambient-card flex flex-col items-center rounded-xl bg-surface-container-low p-6">
            <Icon name="forum" className="mb-3 text-3xl" />
            <span className="font-label-md text-center">Чат с врачом</span>
          </Link>
        </section>
        <section className="mb-10 grid grid-cols-2 gap-3 px-container-margin text-center text-sm">
          {[
            ["/doctors", "Врачи"],
            ["/prices", "Прайс"],
            ["/blog", "Блог"],
            ["/cases", "Кейсы"],
            ["/about", "О клинике"],
            ["/booking", "Запись"],
          ].map(([href, label]) => (
            <Link key={href} href={href} className="rounded-xl border border-outline-variant/50 bg-white py-4">
              {label}
            </Link>
          ))}
        </section>
        <section className="mb-14 px-container-margin">
          <div className="ambient-card rounded-2xl border border-outline-variant bg-surface-container-highest p-8 text-center">
            <span className="mb-4 inline-block rounded-full bg-secondary px-3 py-1 text-[10px] font-label-md tracking-widest text-white uppercase">
              Ограниченное предложение
            </span>
            <h3 className="font-headline-lg text-headline-lg mb-4">Прецизионный анализ кожи</h3>
            <p className="font-body-md mb-6 text-on-surface-variant">
              Наша самая передовая эстетическая диагностика с использованием мультиспектральной визуализации для прогнозирования состояния кожи на 10 лет вперед.
            </p>
            <div className="flex items-center justify-center gap-4">
              <span className="font-headline-md text-headline-md text-secondary">295 ₽</span>
              <span className="text-outline line-through">450 ₽</span>
            </div>
            <button
              className="mt-8 bg-on-background px-10 py-4 font-label-md tracking-widest text-white uppercase"
              onClick={() => openBooking("Прецизионный анализ кожи")}
            >
              Получить предложение
            </button>
            <img src={mediaIds.offer} alt="Процедура омоложения" className="mx-auto mt-8 h-48 w-48 rounded-full border-8 border-white object-cover" />
          </div>
        </section>
        <section className="mb-8">
          <div className="mb-6 flex items-end justify-between px-container-margin">
            <div>
              <span className="font-label-md text-label-md tracking-widest text-secondary uppercase">CULT TV</span>
              <h2 className="font-headline-md text-headline-md">Свежие новости</h2>
            </div>
            <Link href="/tv" className="border-b border-primary font-label-md text-primary">
              Смотреть канал
            </Link>
          </div>
          <div className="hide-scrollbar flex gap-4 overflow-x-auto px-container-margin">
            {[
              { img: mediaIds.tv1, title: "Правда об инфузиях NAD+", meta: "15:20 • Д-р Джулиан Торн" },
              { img: mediaIds.tv2, title: "Оптимизация архитектуры сна", meta: "08:45 • Нутрициология и биохакинг" },
            ].map((card) => (
              <Link key={card.title} href={card.title.includes("NAD") ? "/blog/nad" : "/blog/sleep"} className="min-w-[280px] text-left">
                <div className="ambient-card relative mb-3 aspect-video overflow-hidden rounded-xl">
                  <img src={card.img} alt="" className="h-full w-full object-cover" />
                  <div className="absolute inset-0 flex items-center justify-center">
                    <span className="flex h-12 w-12 items-center justify-center rounded-full border border-white/40 bg-white/20 backdrop-blur-md">
                      <Icon name="play_arrow" className="text-white" />
                    </span>
                  </div>
                </div>
                <h4 className="font-body-md font-semibold">{card.title}</h4>
                <p className="font-label-md text-on-surface-variant">{card.meta}</p>
              </Link>
            ))}
          </div>
        </section>
      </main>
    </Chrome>
  );
}
