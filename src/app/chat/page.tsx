"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Chrome } from "@/components/clinic/chrome";
import { Icon } from "@/components/clinic/icon";
import { contacts } from "@/lib/catalog";
import { useClinic } from "@/components/clinic/providers";

export default function ChatPage() {
  const router = useRouter();
  const { setInfo } = useClinic();
  const [loading, setLoading] = useState(true);
  const hour = new Date().getHours();
  const closed = hour < 9 || hour >= 21;

  useEffect(() => {
    const timer = window.setTimeout(() => setLoading(false), 500);
    return () => window.clearTimeout(timer);
  }, []);

  return (
    <Chrome active="chat" fab="none">
      <main className="px-container-margin pt-6">
        <div className="mb-6 rounded-xl bg-primary-container/60 px-4 py-4 text-sm">
          <p className="font-medium">{closed ? "Клиника сейчас закрыта" : "Если линия занята"}</p>
          <p className="mt-1 text-on-surface-variant">
            {closed
              ? "До 9:00 и после 21:00 первым отвечает ИИ-бот. Врач увидит переписку утром."
              : "При нагрузке первым отвечает ИИ-бот, затем подключается администратор или врач."}
          </p>
          <Link href="/chat/bot" className="mt-2 inline-block font-label-md text-primary">
            Написать боту
          </Link>
        </div>
        <div className="mb-8 text-center">
          <h2 className="font-headline-xl text-[40px] leading-tight mb-4">Центр поддержки</h2>
          <p className="font-body-lg text-on-surface-variant">
            Наша команда готова сделать ваш путь безупречным. Выберите специалиста для начала консультации.
          </p>
        </div>
        <div className="space-y-4">
          {loading ? (
            <div className="space-y-3" aria-busy="true">
              <div className="h-24 animate-pulse rounded-xl bg-surface-container" />
              <div className="h-24 animate-pulse rounded-xl bg-surface-container" />
            </div>
          ) : contacts.map((contact) => (
            <button
              key={contact.id}
              className="flex w-full items-start gap-4 rounded-xl bg-white p-5 text-left luxury-shadow"
              onClick={() => router.push(`/chat/${contact.id}`)}
            >
              <span className="relative shrink-0">
                {contact.image ? (
                  <img src={contact.image} alt="" className="h-16 w-16 rounded-full object-cover" />
                ) : (
                  <span className="flex h-16 w-16 items-center justify-center rounded-full bg-primary-container text-primary">
                    <Icon name="smart_toy" className="text-3xl" />
                  </span>
                )}
                <span className="absolute right-0 bottom-0 h-3.5 w-3.5 rounded-full border-2 border-white bg-green-500" />
              </span>
              <span className="min-w-0 flex-1">
                <span className="mb-1 flex items-center justify-between">
                  <span className="font-headline-sm">{contact.name}</span>
                  <Icon name="chevron_right" className="text-outline-variant" />
                </span>
                <span className="font-label-md mb-1 block text-primary uppercase">{contact.role}</span>
                <span className="block text-sm text-on-surface-variant">{contact.text}</span>
              </span>
            </button>
          ))}
        </div>
        <div className="mt-12 text-center">
          <p className="font-label-md mb-4 text-outline uppercase">Альтернативная поддержка</p>
          <div className="flex justify-center gap-6">
            <button
              className="text-primary underline"
              onClick={() =>
                setInfo({
                  title: "Часто задаваемые вопросы",
                  body: "Клиника открыта ежедневно с 9:00 до 21:00. Отмена визита — за 24 часа. Бонусы списываются до 30% чека.",
                })
              }
            >
              Часто задаваемые вопросы
            </button>
          </div>
          <button
            className="mt-3 text-primary underline"
            onClick={() =>
              setInfo({
                title: "Экстренные протоколы",
                body: "При отёке, сыпи или боли после процедуры напишите специалисту в чат и не наносите активные средства до ответа.",
              })
            }
          >
            Экстренные протоколы
          </button>
        </div>
      </main>
    </Chrome>
  );
}
