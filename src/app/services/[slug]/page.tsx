"use client";

import { useParams } from "next/navigation";
import Link from "next/link";
import { Chrome } from "@/components/clinic/chrome";
import { Icon } from "@/components/clinic/icon";
import { Story } from "@/components/clinic/story";
import { contraindications, mediaIds, serviceBySlug, youtubeFor } from "@/lib/catalog";
import { useClinic } from "@/components/clinic/providers";

export default function ServicePage() {
  const params = useParams<{ slug: string }>();
  const service = serviceBySlug(params.slug);
  const { openBooking } = useClinic();

  if (!service) {
    return (
      <Chrome active="services" nav="english" fab="none">
        <main className="px-container-margin py-16 text-center">
          <h1 className="font-headline-md mb-3">Услуга не найдена</h1>
          <Link href="/services" className="text-primary underline">
            К каталогу
          </Link>
        </main>
      </Chrome>
    );
  }

  const hero = service.slug === "sculpt" ? mediaIds.sculpt : service.image;

  return (
    <Chrome active="services" nav="english" fab="none">
      <main>
        <section className="relative h-[420px] overflow-hidden">
          <img src={hero} alt="" className="h-full w-full object-cover" />
          <div className="absolute inset-0 bg-gradient-to-t from-surface via-transparent to-transparent" />
        </section>
        <article className="relative z-10 -mt-20 px-container-margin">
          <div className="luxury-shadow rounded-lg border border-outline-variant/20 bg-surface p-6">
            <Link
              href={`/booking?service=${encodeURIComponent(service.title)}`}
              className="mb-5 block bg-on-background py-4 text-center font-label-md tracking-widest text-white uppercase"
            >
              Записаться
            </Link>
            <div className="mb-4 flex items-start justify-between gap-3">
              <div>
                <p className="font-label-md mb-1 tracking-widest text-primary uppercase">{service.category}</p>
                <h1 className="font-headline-md text-[28px] leading-tight">{service.title}</h1>
              </div>
              <p className="font-label-md text-on-surface-variant">{service.duration}</p>
            </div>
            <p className="font-body-lg mb-6 text-on-surface-variant">{service.long}</p>
            <div className="mb-8">
              <Story title={service.title} image={hero} minutes={service.duration} paragraphs={[service.long, ...service.steps]} />
            </div>
            <div className="mb-8 space-y-8">
              <div>
                <h3 className="font-headline-sm mb-4 border-b border-outline-variant pb-2">Результат</h3>
                <ul className="space-y-3">
                  {service.results.map((item) => (
                    <li key={item} className="flex items-center gap-3">
                      <Icon name="check_circle" className="text-primary-container" />
                      <span>{item}</span>
                    </li>
                  ))}
                </ul>
              </div>
              <div>
                <h3 className="font-headline-sm mb-4 border-b border-outline-variant pb-2">Как проходит</h3>
                <div className="space-y-4">
                  {service.steps.map((step, index) => (
                    <div key={step} className="flex gap-4">
                      <span className="font-headline-sm text-primary opacity-30">0{index + 1}</span>
                      <p>{step}</p>
                    </div>
                  ))}
                </div>
              </div>
            </div>
            <div className="mb-8">
              <h3 className="font-headline-sm mb-3">Противопоказания</h3>
              <ul className="space-y-2">
                {(contraindications[service.slug] ?? ["Индивидуально на консультации"]).map((item) => (
                  <li key={item} className="text-on-surface-variant">
                    {item}
                  </li>
                ))}
              </ul>
              <a href={youtubeFor(service.title)} target="_blank" rel="noreferrer" className="mt-4 inline-block text-primary underline">
                Видео процедуры на YouTube
              </a>
            </div>
            <div className="border-t border-outline-variant/40 pt-6">
              <p className="font-label-md mb-1 text-on-surface-variant">Стоимость процедуры</p>
              <p className="font-headline-md mb-4">{service.price}</p>
              <button
                className="w-full bg-on-background py-5 font-label-md tracking-widest text-white uppercase"
                onClick={() => openBooking(service.title)}
              >
                Записаться
              </button>
            </div>
          </div>
        </article>
        <section className="mt-12 px-container-margin pb-6 text-center opacity-40">
          <Icon name="spa" className="text-4xl" />
          <p className="font-headline-sm mt-4 italic">Experience the art of manual transformation</p>
        </section>
      </main>
    </Chrome>
  );
}
