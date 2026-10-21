"use client";

import Link from "next/link";
import { Chrome } from "@/components/clinic/chrome";
import { mediaIds } from "@/lib/catalog";

const facts = [
  ["Адрес", "Клинический переулок, 7"],
  ["Часы", "Ежедневно 9:00–21:00"],
  ["Телефон", "+7 495 000-00-07"],
];

export default function AboutPage() {
  return (
    <Chrome active="home" fab="calendar">
      <main className="px-container-margin pt-4">
        <img src={mediaIds.injectionHero} alt="Интерьер CULT" className="mb-5 h-52 w-full rounded-xl object-cover" />
        <p className="font-label-md mb-2 tracking-[0.2em] text-primary uppercase">Exclusive Clinical Sanctuary</p>
        <h1 className="font-headline-lg text-headline-lg-mobile mb-3">О клинике</h1>
        <p className="mb-4 text-on-surface-variant">
          CULT — клиническое святилище: диагностика, аппараты, инъекции и инфузии в одном протоколе. Здесь не собирают «процедуру на час», а ведут кожу и самочувствие как одну историю.
        </p>
        <p className="mb-6 text-on-surface-variant">
          Врачи высшей категории, сертифицированные препараты и аппараты с визуализацией. Запись, трансфер и чат — в этом приложении.
        </p>
        <ul className="mb-6 divide-y divide-outline-variant/40 rounded-xl bg-white">
          {facts.map(([label, value]) => (
            <li key={label} className="flex justify-between gap-4 px-4 py-4">
              <span className="text-outline">{label}</span>
              <span className="text-right font-medium">{value}</span>
            </li>
          ))}
        </ul>
        <section className="mb-6 rounded-xl bg-white p-4">
          <h2 className="font-headline-sm mb-2">Как добраться</h2>
          <p className="text-on-surface-variant">
            От метро «Кропоткинская» семь минут пешком по Клиническому переулку. Въезд во двор со стороны переулка, парковка для гостей у ресепшен.
          </p>
        </section>
        <section className="mb-8">
          <h2 className="font-headline-sm mb-3">Документы</h2>
          <ul className="divide-y divide-outline-variant/40 rounded-xl bg-white text-sm">
            {[
              ["Публичная оферта", "Услуги и товары оформляются по оферте клиники. Актуальный текст выдают на ресепшен и дублируют в чат по запросу."],
              ["Согласие на процедуры", "Перед инъекцией, аппаратом или инфузией подписывается информированное согласие."],
              ["Политика данных", "Имя, визиты и анализы в этом приложении хранятся только на устройстве."],
            ].map(([title, text]) => (
              <li key={title} className="px-4 py-4">
                <p className="font-medium">{title}</p>
                <p className="mt-1 text-on-surface-variant">{text}</p>
              </li>
            ))}
          </ul>
        </section>
        <div className="grid grid-cols-2 gap-3 text-center text-sm">
          <Link href="/doctors" className="rounded-xl bg-surface-container-low py-4">
            Врачи
          </Link>
          <Link href="/hardware" className="rounded-xl bg-surface-container-low py-4">
            Оборудование
          </Link>
          <Link href="/prices" className="rounded-xl bg-surface-container-low py-4">
            Прайс
          </Link>
          <Link href="/chat" className="rounded-xl bg-surface-container-low py-4">
            Чат клиники
          </Link>
        </div>
      </main>
    </Chrome>
  );
}
