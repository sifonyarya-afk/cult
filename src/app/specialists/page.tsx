"use client";

import { useRouter } from "next/navigation";
import { Chrome } from "@/components/clinic/chrome";
import { Icon } from "@/components/clinic/icon";
import { Story } from "@/components/clinic/story";
import { mediaIds } from "@/lib/catalog";
import { useClinic } from "@/components/clinic/providers";

const reviews = [
  {
    name: "Елена М.",
    stars: 5,
    text: "Клиника — настоящее святилище спокойствия. Доктор AlethiaPro уделила время тому, чтобы понять мои цели, не торопясь. Результаты деликатные, но преображающие.",
  },
  {
    name: "Юлиан В.",
    stars: 4,
    text: "Чрезвычайно профессионально и глубоко. Лучший клинический опыт за последние годы. Очень рекомендую индивидуальный план лечения.",
  },
];

export default function SpecialistsPage() {
  const router = useRouter();
  const { setInfo } = useClinic();
  return (
    <Chrome active="services" fab="none" bookBar={{ label: "Записаться", title: "Приём AlethiaPro" }}>
      <main className="px-container-margin pt-6">
        <section className="mb-10 flex flex-col items-center text-center">
          <img src={mediaIds.alethia} alt="AlethiaPro" className="mb-5 h-32 w-32 rounded-full border-4 border-white object-cover luxury-shadow" />
          <h2 className="font-headline-lg text-headline-lg-mobile mb-1">AlethiaPro</h2>
          <p className="font-label-md mb-6 tracking-widest text-primary uppercase">Специалист эстетической дерматологии</p>
          <button
            className="flex w-full items-center justify-center gap-2 rounded-lg bg-secondary-container py-4 font-label-md tracking-widest text-on-secondary-container uppercase"
            onClick={() => router.push("/chat/specialist")}
          >
            <Icon name="chat_bubble" />
            Чат с врачом
          </button>
        </section>
        <section className="mb-10">
          <h3 className="font-label-md mb-4 tracking-wider text-outline uppercase">О враче</h3>
          <Story
            title="Введение в холистическую терапию кожи"
            image={mediaIds.alethiaVideo}
            minutes="2:45"
            paragraphs={[
              "AlethiaPro начинает приём с разговора о цели, а не с прайса. Протокол собирается из диагностики, аппарата и домашнего ухода.",
              "На видео она объясняет, как выглядит первый визит и чего ждать от курса без спешки.",
            ]}
          />
        </section>
        <div className="mb-10 grid grid-cols-2 gap-4">
          <div className="flex flex-col items-center rounded-xl bg-surface-container-low p-6">
            <span className="font-headline-md text-headline-md">12+</span>
            <span className="font-label-md text-outline uppercase">лет опыта</span>
          </div>
          <div className="flex flex-col items-center rounded-xl bg-secondary-fixed p-6 text-on-secondary-fixed-variant">
            <span className="font-headline-md text-headline-md flex items-center gap-1">
              4.9 <Icon name="star" fill className="text-sm" />
            </span>
            <span className="font-label-md uppercase">Рейтинг</span>
          </div>
        </div>
        <section className="mb-8">
          <h3 className="font-label-md mb-4 flex items-center gap-2 tracking-widest text-outline uppercase">
            <Icon name="school" className="text-lg" /> Образование
          </h3>
          <ul>
            <li className="border-b border-outline-variant/40 py-4">
              <p className="font-body-lg">Доктор медицины</p>
              <p className="font-label-md text-primary">Медицинская школа Стэнфордского университета</p>
            </li>
            <li className="border-b border-outline-variant/40 py-4">
              <p className="font-body-lg">Ординатура по дерматологии</p>
              <p className="font-label-md text-primary">Высшая школа клиники Мейо</p>
            </li>
          </ul>
        </section>
        <section className="mb-8">
          <h3 className="font-label-md mb-4 flex items-center gap-2 tracking-widest text-outline uppercase">
            <Icon name="work" className="text-lg" /> Опыт работы
          </h3>
          <ul>
            <li className="border-b border-outline-variant/40 py-4">
              <p className="font-body-lg">Заведующая отделением дерматологии</p>
              <p className="font-label-md text-primary">Институт Elite Wellness (2018 — наст. время)</p>
            </li>
            <li className="border-b border-outline-variant/40 py-4">
              <p className="font-body-lg">Старший научный сотрудник</p>
              <p className="font-label-md text-primary">Исследовательская лаборатория кожи Lumina (2014 — 2018)</p>
            </li>
          </ul>
        </section>
        <section>
          <div className="mb-4 flex items-baseline justify-between">
            <h3 className="font-label-md flex items-center gap-2 tracking-widest text-outline uppercase">
              <Icon name="reviews" className="text-lg" /> Отзывы пациентов
            </h3>
            <button className="font-label-md text-primary underline" onClick={() => setInfo({ title: "Все отзывы", body: reviews.map((item) => `${item.name}: ${item.text}`).join(" ") })}>
              Все отзывы
            </button>
          </div>
          <div className="space-y-4">
            {reviews.map((review) => (
              <article key={review.name} className="rounded-xl border border-surface-container bg-white p-5 luxury-shadow">
                <div className="mb-2 flex justify-between">
                  <span className="font-label-md font-bold">{review.name}</span>
                  <span className="flex text-secondary-container">
                    {Array.from({ length: 5 }).map((_, index) => (
                      <Icon key={index} name="star" fill={index < review.stars} className="text-sm" />
                    ))}
                  </span>
                </div>
                <p className="text-on-surface-variant italic">«{review.text}»</p>
              </article>
            ))}
          </div>
        </section>
      </main>
    </Chrome>
  );
}
