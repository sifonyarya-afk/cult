"use client";

import { useRouter } from "next/navigation";
import { Chrome } from "@/components/clinic/chrome";
import { Story } from "@/components/clinic/story";
import { Icon } from "@/components/clinic/icon";
import { mediaIds } from "@/lib/catalog";
import { useClinic } from "@/components/clinic/providers";

export default function JulianPage() {
  const router = useRouter();
  const { openBooking } = useClinic();
  return (
    <Chrome active="services" fab="none" bookBar={{ label: "Записаться", title: "Приём д-ра Джулиана Торна" }}>
      <main className="px-container-margin pt-6">
        <img src={mediaIds.tv1} alt="Д-р Джулиан Торн" className="mb-5 h-56 w-full rounded-xl object-cover" />
        <h1 className="font-headline-lg text-headline-lg-mobile">Д-р Джулиан Торн</h1>
        <p className="font-label-md mb-4 tracking-widest text-primary uppercase">Инфузии и нутрициология</p>
        <p className="mb-6 text-on-surface-variant">
          Ведёт протоколы NAD+, сна и клеточной энергии. Объясняет курс так, чтобы его можно было и прочитать, и посмотреть.
        </p>
        <button
          className="mb-8 flex w-full items-center justify-center gap-2 bg-secondary-container py-4 font-label-md text-on-secondary-container"
          onClick={() => router.push("/chat/specialist")}
        >
          <Icon name="chat_bubble" /> Чат с доктором
        </button>
        <Story
          title="Правда об инфузиях NAD+"
          image={mediaIds.tv1}
          minutes="15:20"
          paragraphs={[
            "Джулиан собирает инфузию после короткого разбора сна, нагрузки и анализов. Одинаковой капельницы на всех в CULT нет.",
            "На видео он показывает, чем NAD+ отличается от витаминного коктейля и когда лучше начать с добавки, а не с кресла.",
          ]}
        />
        <button className="mt-8 text-primary underline" onClick={() => openBooking("Приём д-ра Джулиана Торна")}>
          Запись на консультацию
        </button>
      </main>
    </Chrome>
  );
}
