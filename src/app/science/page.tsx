"use client";

import Link from "next/link";
import { Chrome } from "@/components/clinic/chrome";
import { Icon } from "@/components/clinic/icon";
import { mediaIds } from "@/lib/catalog";
import { useClinic } from "@/components/clinic/providers";

const studies = [
  {
    title: "Терапия удлинения теломер",
    text: "Последние результаты лонгитюдного исследования 2024 года по нуклеотидным добавкам и маркерам биологического старения.",
    image: mediaIds.scienceA,
  },
  {
    title: "Микродозы пептидов",
    text: "Понимание эффективности биоидентичных пептидов в локальном восстановлении тканей и синтезе коллагена.",
    image: mediaIds.scienceB,
  },
  {
    title: "Ось микробиом-кожа",
    text: "Новые взгляды на то, как внутреннее здоровье пробиотиков проявляется во внешней эстетической долговечности.",
    image: mediaIds.scienceC,
  },
];

const protocols = [
  { level: "Уровень 01", title: "Циркадная перезагрузка", text: "Оптимизация циклов кортизола и мелатонина с помощью светотерапии и режима питания.", href: "" },
  { level: "Уровень 02", title: "Обогащение NAD+", text: "Золотой стандарт во внутриклеточном восстановлении энергии и оптимизации митохондрий.", href: "/infusion" },
  { level: "Уровень 03", title: "Сенолитическое очищение", text: "Таргетирование «зомби-клеток» для уменьшения системного воспаления и ускорения обновления тканей.", href: "" },
  { level: "Золотой уровень", title: "Генная модуляция", text: "Эксклюзивные протоколы с использованием технологий CRISPR и мРНК для оптимизации фенотипа.", href: "" },
];

export default function SciencePage() {
  const { setInfo } = useClinic();
  return (
    <Chrome active="science" nav="science" fab="none" brand="wordmark">
      <main className="px-container-margin pt-4">
        <p className="font-label-md mb-2 tracking-widest text-secondary uppercase">Актуальное</p>
        <img src={mediaIds.scienceHero} alt="" className="mb-4 h-48 w-full rounded-xl object-cover" />
        <h2 className="font-headline-lg text-headline-lg-mobile mb-3">Будущее клеточной регенерации</h2>
        <p className="mb-5 text-on-surface-variant">
          Исследование пересечения эпигенетики и клинической эстетики для радикального долголетия.
        </p>
        <button
          className="mb-10 bg-on-background px-8 py-4 font-label-md tracking-widest text-white uppercase"
          onClick={() =>
            setInfo({
              title: "Будущее клеточной регенерации",
              body: "Обзор 2024 года: теломеры, NAD+ и кожный барьер. Полный текст выдаётся на консультации.",
            })
          }
        >
          Читать исследование
        </button>
        <div className="mb-4 flex items-end justify-between">
          <h3 className="font-headline-sm">Клинические исследования</h3>
          <button className="font-label-md text-xs tracking-widest" onClick={() => setInfo({ title: "Все исследования", body: studies.map((item) => item.title).join(" · ") })}>
            СМОТРЕТЬ ВСЕ
          </button>
        </div>
        <div className="mb-10 space-y-5">
          {studies.map((study) => (
            <button key={study.title} className="w-full text-left" onClick={() => setInfo({ title: study.title, body: study.text })}>
              <img src={study.image} alt="" className="mb-2 h-36 w-full rounded-lg object-cover" />
              <p className="font-headline-sm">{study.title}</p>
              <p className="text-sm text-on-surface-variant">{study.text}</p>
            </button>
          ))}
        </div>
        <h3 className="font-headline-sm mb-1">Новые технологии</h3>
        <p className="mb-4 text-sm text-outline">Инструменты нового поколения</p>
        <div className="mb-10 space-y-4">
          {[
            { title: "Квантовое био-сканирование", text: "Неинвазивные диагностические инструменты, картирующие более 10 000 биомаркеров в реальном времени.", image: mediaIds.scienceD },
            { title: "Скульптурирование под управлением ИИ", text: "Роботизированная точность в сочетании с эстетической интуицией для омоложения лица.", image: mediaIds.scienceE },
          ].map((item) => (
            <div key={item.title} className="overflow-hidden rounded-xl bg-white luxury-shadow">
              <img src={item.image} alt="" className="h-36 w-full object-cover" />
              <div className="p-4">
                <p className="font-headline-sm">{item.title}</p>
                <p className="mb-3 text-sm text-on-surface-variant">{item.text}</p>
                <button className="font-label-md text-primary" onClick={() => setInfo({ title: item.title, body: item.text })}>
                  Открыть
                </button>
              </div>
            </div>
          ))}
        </div>
        <h3 className="font-headline-sm">Протоколы долголетия</h3>
        <p className="mb-4 text-sm text-outline">Подписки</p>
        <div className="space-y-3">
          {protocols.map((item) => {
            const body = (
              <div className="flex items-center justify-between gap-3 rounded-xl bg-white p-4 luxury-shadow">
                <div>
                  <p className="text-xs tracking-widest text-secondary uppercase">{item.level}</p>
                  <p className="font-headline-sm">{item.title}</p>
                  <p className="text-sm text-on-surface-variant">{item.text}</p>
                </div>
                <Icon name="arrow_forward" className="text-primary" />
              </div>
            );
            return item.href ? (
              <Link key={item.title} href={item.href}>
                {body}
              </Link>
            ) : (
              <button key={item.title} className="w-full text-left" onClick={() => setInfo({ title: item.title, body: item.text })}>
                {body}
              </button>
            );
          })}
        </div>
      </main>
    </Chrome>
  );
}
