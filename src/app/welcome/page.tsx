"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Icon } from "@/components/clinic/icon";
import { useClinic } from "@/components/clinic/providers";

export default function WelcomePage() {
  const router = useRouter();
  const { claimBonus, setMenuOpen } = useClinic();
  const [phone, setPhone] = useState("");
  const [error, setError] = useState("");
  const [done, setDone] = useState(false);
  const [legal, setLegal] = useState<"bonus" | "data" | null>(null);

  function submit(event: React.FormEvent) {
    event.preventDefault();
    const digits = phone.replace(/\D/g, "");
    if (digits.length < 11) {
      setError("Введите номер в формате +7 и 10 цифр.");
      return;
    }
    setError("");
    claimBonus();
    setDone(true);
  }

  return (
    <div className="flex min-h-dvh flex-col">
      <header className="sticky top-0 z-40 flex h-16 items-center justify-between bg-background px-container-margin">
        <button aria-label="Меню" onClick={() => setMenuOpen(true)}>
          <Icon name="menu" className="text-primary" />
        </button>
        <span className="font-headline-lg text-[28px] tracking-[0.28em]">CULT</span>
        <Link href="/cabinet" aria-label="Кабинет">
          <Icon name="account_circle" className="text-primary" />
        </Link>
      </header>
      <main className="flex flex-1 flex-col justify-center px-container-margin py-10">
        <div className="luxury-shadow rounded-xl border border-surface-variant/40 bg-white p-8">
          {done ? (
            <div className="py-6 text-center">
              <div className="mx-auto mb-8 flex h-20 w-20 items-center justify-center rounded-full bg-secondary-container">
                <Icon name="check_circle" className="text-4xl text-on-secondary-container" />
              </div>
              <h2 className="font-headline-md text-headline-md mb-4">Бонус начислен!</h2>
              <p className="font-body-md text-on-surface-variant mb-8">
                Ваш баланс пополнен на 3 000 ₽. Мы отправили SMS-код для подтверждения входа.
              </p>
              <button
                className="w-full border border-on-background py-4 font-label-md text-label-md tracking-widest uppercase"
                onClick={() => router.push("/cabinet")}
              >
                Перейти в личный кабинет
              </button>
            </div>
          ) : (
            <>
              <div className="mb-10 text-center">
                <span className="font-label-md text-label-md mb-4 block tracking-widest text-secondary uppercase">
                  Welcome Bonus
                </span>
                <h1 className="font-headline-lg text-headline-lg-mobile mb-6">Подарок для новых клиентов</h1>
                <p className="font-body-lg text-on-surface-variant leading-relaxed">
                  Зарегистрируйтесь по номеру телефона и получите{" "}
                  <span className="font-bold text-primary">3 000 ₽</span> на бонусный счет для оплаты услуг клиники
                </p>
              </div>
              <form className="space-y-8" onSubmit={submit}>
                <div>
                  <label className="font-label-md text-label-md mb-2 block text-outline" htmlFor="phone">
                    Номер телефона
                  </label>
                  <div className="flex items-center border-b border-outline-variant py-2 focus-within:border-primary">
                    <Icon name="phone" className="mr-3 text-outline" />
                    <Input
                      id="phone"
                      type="tel"
                      inputMode="tel"
                      placeholder="+7 (___) ___-__-__"
                      value={phone}
                      onChange={(event) => setPhone(event.target.value)}
                      className="h-10 border-0 px-0 shadow-none focus-visible:ring-0"
                    />
                  </div>
                  {error ? <p className="mt-2 text-sm text-error">{error}</p> : null}
                </div>
                <Button
                  type="submit"
                  className="h-auto w-full rounded-none bg-on-background py-5 font-label-md text-label-md tracking-widest text-white uppercase hover:bg-on-background/90"
                >
                  Получить бонус
                </Button>
                <p className="text-center text-[12px] leading-snug text-outline">
                  Нажимая кнопку, вы соглашаетесь с{" "}
                  <button type="button" className="underline" onClick={() => setLegal("bonus")}>
                    правилами бонусной программы
                  </button>{" "}
                  и{" "}
                  <button type="button" className="underline" onClick={() => setLegal("data")}>
                    обработкой персональных данных
                  </button>
                </p>
              </form>
            </>
          )}
        </div>
      </main>
      <footer className="py-4 text-center opacity-40">
        <p className="text-[10px] font-bold tracking-[0.2em] text-outline uppercase">Exclusive Clinical Sanctuary</p>
      </footer>
      <div className="px-container-margin pb-8">
        <Link href="/home" className="block text-center font-label-md text-primary underline">
          Продолжить без бонуса
        </Link>
      </div>
      <Dialog open={Boolean(legal)} onOpenChange={(open) => !open && setLegal(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className="font-headline-sm">
              {legal === "bonus" ? "Правила бонусной программы" : "Персональные данные"}
            </DialogTitle>
            <DialogDescription>
              {legal === "bonus"
                ? "3 000 ₽ начисляются один раз на бонусный счёт и списываются при оплате услуг клиники. Срок — 12 месяцев."
                : "Номер нужен, чтобы начислить бонус и подтвердить вход. Мы не передаём его третьим лицам в этом демо."}
            </DialogDescription>
          </DialogHeader>
        </DialogContent>
      </Dialog>
    </div>
  );
}
