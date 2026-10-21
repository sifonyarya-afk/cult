"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Chrome } from "@/components/clinic/chrome";
import { Icon } from "@/components/clinic/icon";
import { useClinic } from "@/components/clinic/providers";
import { analyses, formatVisitDate, labVisits, mediaIds } from "@/lib/catalog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";

const statusTone: Record<string, string> = {
  Назначен: "text-outline",
  Сдан: "text-secondary",
  Готов: "text-primary",
};

export default function CabinetPage() {
  const router = useRouter();
  const clinic = useClinic();
  const [openAnalyses, setOpenAnalyses] = useState(true);
  const [edit, setEdit] = useState(false);
  const [name, setName] = useState(clinic.profileName);
  const [pdf, setPdf] = useState<string | null>(null);
  const [pdfFailed, setPdfFailed] = useState<Record<string, boolean>>({});
  const [pdfOk, setPdfOk] = useState<string | null>(null);
  const [infoTitle, setInfoTitle] = useState<string | null>(null);
  const [logout, setLogout] = useState(false);
  const upcoming = clinic.appointments.filter((visit) => visit.status === "upcoming");
  const nextVisit = upcoming[0];
  const rows: { href?: string; icon: string; title: string; note?: string; action?: "analyses" | "info" }[] = [
    {
      href: "/cabinet/visits",
      icon: "calendar_today",
      title: "Мои записи",
      note: nextVisit ? `След: ${formatVisitDate(nextVisit.date)}, ${nextVisit.time}` : "Предстоящих нет",
    },
    { href: "/cabinet/visits", icon: "history", title: "История визитов" },
    { icon: "lab_research", title: "Мои анализы", action: "analyses" },
    { href: "/pharmacy", icon: "medication", title: "Аптечка", note: "Рекомендации врача" },
    { href: "/cabinet/orders", icon: "shopping_bag", title: "Мои заказы" },
    { href: "/certificates", icon: "card_giftcard", title: "Сертификаты" },
    { href: "/cabinet/favorites", icon: "favorite", title: "Избранное" },
    { href: "/cabinet/settings", icon: "notifications", title: "Уведомления" },
    { href: "/chat/specialist", icon: "chat_bubble", title: "Чат с доктором" },
    { href: "/chat", icon: "forum", title: "Чат с клиникой" },
    { href: "/loyalty", icon: "rule", title: "Бонусы и правила" },
    { href: "/transfer", icon: "directions_car", title: "Заказ трансфера" },
    { icon: "description", title: "Юридические документы", action: "info" },
  ];

  function openPdf(id: string, file: string) {
    if (!pdfFailed[id]) {
      setPdfFailed((current) => ({ ...current, [id]: true }));
      setPdf(file);
      return;
    }
    setPdfOk(file);
  }

  return (
    <Chrome active="profile" fab="none">
      <main className="px-container-margin pt-6">
        <section className="mb-8 text-center">
          <div className="relative mb-4 inline-block">
            <img src={mediaIds.avatar} alt="Профиль" className="h-24 w-24 rounded-full border-2 border-surface-variant object-cover p-1" />
            <button
              aria-label="Изменить профиль"
              className="absolute right-0 bottom-0 flex h-8 w-8 items-center justify-center rounded-full border-2 border-surface bg-primary text-white"
              onClick={() => {
                setName(clinic.profileName);
                setEdit(true);
              }}
            >
              <Icon name="edit" className="text-[18px]" />
            </button>
          </div>
          <h2 className="font-headline-md text-headline-md">{clinic.profileName}</h2>
          <p className="font-label-md mt-1 tracking-widest text-on-surface-variant uppercase">Платиновый статус</p>
        </section>
        <section className="gold-card-gradient relative mb-10 overflow-hidden rounded-xl p-8 text-on-secondary-fixed shadow-xl">
          <div className="relative z-10">
            <div className="mb-10 flex items-start justify-between">
              <div>
                <span className="font-label-md text-label-md uppercase opacity-80">Бонусный баланс</span>
                <div className="font-headline-xl text-headline-xl mt-1">
                  {clinic.balance.toLocaleString("ru-RU")} <span className="text-headline-sm">₽</span>
                </div>
              </div>
              <div className="glass-effect rounded-full px-4 py-2">
                <span className="font-label-md text-label-md uppercase">VIP Статус</span>
              </div>
            </div>
            <div className="flex items-end justify-between">
              <div>
                <span className="font-label-md block opacity-80">В клубе с</span>
                <span className="font-bold uppercase">ЯНВ 2023</span>
              </div>
              <Icon name="auto_awesome" className="text-4xl opacity-40" />
            </div>
          </div>
        </section>
        <p className="font-label-md mb-4 px-2 tracking-widest text-on-surface-variant uppercase">Обзор аккаунта</p>
        <div className="overflow-hidden rounded-xl bg-white">
          {rows.map((row, index) => {
            const inner = (
              <div className="flex items-center justify-between px-4 py-5">
                <div className="flex items-center gap-4">
                  <Icon name={row.icon} className="text-primary" />
                  <div className="text-left">
                    <span className="font-medium">{row.title}</span>
                    {row.note ? (
                      <p className={`text-xs ${row.title.startsWith("Рекомен") ? "font-bold text-secondary" : "text-on-surface-variant"}`}>
                        {row.note}
                      </p>
                    ) : null}
                  </div>
                </div>
                <Icon name={row.action === "analyses" ? "expand_more" : "chevron_right"} className={row.action === "analyses" && openAnalyses ? "rotate-180 text-outline-variant" : "text-outline-variant"} />
              </div>
            );
            if (row.href) {
              return (
                <Link key={row.title} href={row.href} className="block border-b border-surface-container">
                  {inner}
                </Link>
              );
            }
            return (
              <div key={row.title} className={index === rows.length - 1 ? "" : "border-b border-surface-container"}>
                <button
                  className="w-full"
                  onClick={() => {
                    if (row.action === "analyses") setOpenAnalyses((value) => !value);
                    else setInfoTitle(row.title);
                  }}
                >
                  {inner}
                </button>
                {row.action === "analyses" && openAnalyses ? (
                  <div className="space-y-3 px-4 pb-4">
                    {labVisits.map((visit) => (
                      <div key={visit.id} className="flex items-center justify-between rounded border border-outline-variant/40 bg-surface p-3">
                        <div>
                          <p className="text-sm font-medium">{visit.title}</p>
                          <p className="text-xs text-outline">{visit.date}</p>
                        </div>
                        <span className={`text-xs font-bold tracking-wider uppercase ${statusTone[visit.status] ?? ""}`}>{visit.status}</span>
                      </div>
                    ))}
                    {analyses.map((file) => (
                      <div key={file.id} className="flex items-center justify-between rounded border border-outline-variant/40 bg-surface p-3">
                        <div className="flex items-center gap-3">
                          <Icon name="picture_as_pdf" className="text-error" />
                          <span className="text-sm font-medium">{file.name}</span>
                        </div>
                        <button className="text-sm font-bold text-primary uppercase" onClick={() => openPdf(file.id, file.name)}>
                          Открыть
                        </button>
                      </div>
                    ))}
                    <Link href="/booking?service=Анализ%20крови" className="block text-center text-sm text-primary underline">
                      Записать анализ
                    </Link>
                  </div>
                ) : null}
              </div>
            );
          })}
        </div>
        <div className="mt-12 mb-6 text-center">
          <button className="rounded border border-error/20 px-6 py-2 font-label-md tracking-widest text-error uppercase" onClick={() => setLogout(true)}>
            Выйти
          </button>
        </div>
      </main>

      <Dialog open={edit} onOpenChange={setEdit}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className="font-headline-sm">Профиль</DialogTitle>
            <DialogDescription>Имя в кабинете. Приветствие на главной остаётся как в макете.</DialogDescription>
          </DialogHeader>
          <form
            className="space-y-3"
            onSubmit={(event) => {
              event.preventDefault();
              if (name.trim().length < 2) return;
              clinic.setProfileName(name.trim());
              setEdit(false);
            }}
          >
            <Input value={name} onChange={(event) => setName(event.target.value)} aria-label="Имя" className="h-11" />
            <Button type="submit" className="h-11 w-full bg-on-background text-white">
              Сохранить
            </Button>
          </form>
        </DialogContent>
      </Dialog>

      <Dialog open={Boolean(pdf)} onOpenChange={(open) => !open && setPdf(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className="font-headline-sm">Не удалось открыть</DialogTitle>
            <DialogDescription>Файл {pdf} сейчас недоступен. Повторите попытку.</DialogDescription>
          </DialogHeader>
          <Button
            className="h-11 bg-on-background text-white"
            onClick={() => {
              const file = pdf;
              setPdf(null);
              if (file) setPdfOk(file);
            }}
          >
            Повторить
          </Button>
        </DialogContent>
      </Dialog>

      <Dialog open={Boolean(pdfOk)} onOpenChange={(open) => !open && setPdfOk(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className="font-headline-sm">{pdfOk}</DialogTitle>
            <DialogDescription>
              Заключение: показатели в референсе. Врач оставил рекомендацию продолжить текущий протокол.
            </DialogDescription>
          </DialogHeader>
        </DialogContent>
      </Dialog>

      <Dialog open={Boolean(infoTitle)} onOpenChange={(open) => !open && setInfoTitle(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className="font-headline-sm">{infoTitle}</DialogTitle>
            <DialogDescription>
              {infoTitle === "Рекомендации врача"
                ? "Три новых: SPF каждое утро, пауза с кислотами 5 дней, контроль визита через месяц."
                : infoTitle === "Правила лояльности"
                  ? "Платиновый статус: 10% бонусами, приоритетная запись и трансфер по запросу."
                  : infoTitle === "Юридические документы"
                    ? "Оферта, согласие на процедуры и политика данных доступны на ресепшен."
                    : "Заявка уйдёт консьержу. Напишите в чат администратору, если нужно сегодня."}
            </DialogDescription>
          </DialogHeader>
          {infoTitle === "Юридические документы" ? (
            <Button className="h-11 bg-on-background text-white" onClick={() => router.push("/about")}>
              Открыть на странице клиники
            </Button>
          ) : null}
        </DialogContent>
      </Dialog>

      <Dialog open={logout} onOpenChange={setLogout}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className="font-headline-sm">Выйти из кабинета?</DialogTitle>
            <DialogDescription>Корзина и переписка останутся на этом устройстве.</DialogDescription>
          </DialogHeader>
          <Button
            className="h-11 bg-on-background text-white"
            onClick={() => {
              setLogout(false);
              router.push("/welcome");
            }}
          >
            Выйти
          </Button>
        </DialogContent>
      </Dialog>
    </Chrome>
  );
}
