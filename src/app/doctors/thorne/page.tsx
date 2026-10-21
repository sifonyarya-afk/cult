"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { Chrome } from "@/components/clinic/chrome";
import { Icon } from "@/components/clinic/icon";
import { mediaIds } from "@/lib/catalog";
import { useClinic } from "@/components/clinic/providers";

const reviews = [
  { name: "Сара Дженкинс", role: "Программа долголетия", text: "За три месяца усталость отступила сильнее, чем за годы других протоколов.", image: mediaIds.reviewA },
  { name: "Дэвид Локвуд", role: "Корпоративный велнес", text: "Лаборатории и режим собраны так, что результат чувствуется сразу.", image: mediaIds.reviewB },
  { name: "Елена Моретти", role: "Гормональный баланс", text: "Снова есть силы. Здоровье здесь — это жизненная сила.", image: mediaIds.reviewC },
];

export default function ThornePage() {
  const router = useRouter();
  const { openBooking, setPlayTitle, setInfo } = useClinic();
  return (
    <Chrome active="health" nav="thorne" fab="none" brand="thorne">
      <main>
        <div className="flex justify-center gap-4 px-container-margin py-3 text-sm">
          <Link href="/specialists" className="text-primary">
            Специалисты
          </Link>
          <Link href="/services" className="text-primary">
            Услуги
          </Link>
          <Link href="/science" className="text-primary">
            Программы
          </Link>
        </div>
        <section className="relative">
          <img src={mediaIds.thorne} alt="Д-р Элара Торн" className="h-[420px] w-full object-cover object-top" />
          <div className="absolute bottom-6 left-6 right-6 bg-black/40 p-4 text-white backdrop-blur-md">
            <p className="text-sm">Директор по холистическому здоровью</p>
            <p className="font-headline-sm">Д-р Элара Торн, MD</p>
          </div>
        </section>
        <div className="px-container-margin py-8">
          <p className="font-label-md mb-2 tracking-widest text-primary uppercase">Специализация: Регенеративная витальность</p>
          <h2 className="font-headline-md mb-3">Клиническая точность и живое благополучие.</h2>
          <p className="mb-6 text-on-surface-variant">
            Пятнадцать лет в ведущих клиниках. В CULT ведёт долголетие и гормональный баланс.
          </p>
          <div className="mb-8 flex flex-col gap-3">
            <button className="flex items-center justify-center gap-2 bg-secondary-container py-4 font-label-md text-on-secondary-container" onClick={() => router.push("/chat/specialist")}>
              <Icon name="chat_bubble" /> Чат с доктором
            </button>
            <button className="border border-on-background py-4 font-label-md" onClick={() => openBooking("Консультация д-ра Торн")}>
              Запись на консультацию
            </button>
          </div>
          <div className="mb-8 grid grid-cols-3 gap-2 text-center">
            {[
              ["15+", "Лет опыта"],
              ["2k+", "Пациентов"],
              ["4.9", "Рейтинг"],
            ].map(([value, label]) => (
              <div key={label} className="rounded-xl bg-surface-container-low py-4">
                <p className="font-headline-md">{value}</p>
                <p className="text-xs text-outline">{label}</p>
              </div>
            ))}
          </div>
          <h3 className="font-label-md mb-3 flex items-center gap-2 tracking-widest uppercase">
            <Icon name="school" /> Образование
          </h3>
          <ul className="mb-8 space-y-3">
            <li>
              <p className="font-medium">Гарвардская медицинская школа</p>
              <p className="text-sm text-primary">Доктор медицины (MD)</p>
            </li>
            <li>
              <p className="font-medium">Стэнфордский университет</p>
              <p className="text-sm text-primary">Интегративная биология</p>
            </li>
            <li>
              <p className="font-medium">Институт функциональной медицины</p>
              <p className="text-sm text-primary">Сертифицированный специалист</p>
            </li>
          </ul>
          <h3 className="font-label-md mb-3 flex items-center gap-2 tracking-widest uppercase">
            <Icon name="history_edu" /> Клинический опыт
          </h3>
          <ul className="mb-8 space-y-4">
            <li>
              <p className="text-xs text-outline">2018 — наст. вр.</p>
              <p className="font-medium">Директор, CULT Wellness Sanctuary</p>
              <p className="text-sm text-on-surface-variant">Персональные ретриты долголетия.</p>
            </li>
            <li>
              <p className="text-xs text-outline">2012 — 2018</p>
              <p className="font-medium">Старший врач, клиника Мэйо</p>
              <p className="text-sm text-on-surface-variant">Внутренняя медицина и питание.</p>
            </li>
          </ul>
          <button className="relative mb-10 aspect-video w-full overflow-hidden rounded-xl" onClick={() => setPlayTitle("Послание от доктора Торн")}>
            <img src={mediaIds.thorneVideo} alt="" className="h-full w-full object-cover" />
            <span className="absolute inset-0 flex items-center justify-center bg-black/20 text-white">
              <Icon name="play_arrow" fill className="text-4xl" />
            </span>
            <span className="absolute bottom-3 left-3 text-sm text-white">Смотреть: Послание от доктора Торн</span>
          </button>
          <h3 className="font-headline-sm mb-1">Отзывы пациентов</h3>
          <p className="mb-4 text-sm text-outline">Голоса трансформации</p>
          <div className="hide-scrollbar mb-10 flex gap-3 overflow-x-auto">
            {reviews.map((review) => (
              <article key={review.name} className="min-w-[260px] rounded-xl bg-white p-4 luxury-shadow">
                <div className="mb-2 flex gap-3">
                  <img src={review.image} alt="" className="h-10 w-10 rounded-full object-cover" />
                  <div>
                    <p className="font-medium">{review.name}</p>
                    <p className="text-xs text-outline">{review.role}</p>
                  </div>
                </div>
                <p className="text-sm italic text-on-surface-variant">«{review.text}»</p>
              </article>
            ))}
          </div>
          <div className="rounded-xl bg-primary p-6 text-center text-white">
            <h3 className="font-headline-sm mb-2">Начните свой персональный путь</h3>
            <p className="mb-4 text-sm opacity-90">Доктор Торн принимает ограниченное число новых пациентов.</p>
            <div className="flex flex-col gap-3">
              <button className="bg-white py-3 font-label-md text-on-background" onClick={() => openBooking("Заявка к д-ру Торн")}>
                Подать заявку
              </button>
              <button
                className="border border-white py-3 font-label-md"
                onClick={() =>
                  setInfo({
                    title: "Брошюра CULT",
                    body: "Короткий гид: консультация, диагностика, программа на 90 дней. Файл откроется у администратора.",
                  })
                }
              >
                Скачать брошюру
              </button>
            </div>
          </div>
        </div>
      </main>
    </Chrome>
  );
}
