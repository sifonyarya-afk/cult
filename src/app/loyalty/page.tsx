"use client";

import Link from "next/link";
import { Chrome } from "@/components/clinic/chrome";
import { loyaltyLedger } from "@/lib/catalog";
import { useClinic } from "@/components/clinic/providers";

const rules = [
  "Платина: до 30% чека можно закрыть бонусами.",
  "Начисление — 10% от оплаченных услуг, не от товаров со скидкой.",
  "Бонус новым клиентам 3 000 ₽ действует 12 месяцев.",
  "Статус не сгорает, пока есть визит раз в 18 месяцев.",
];

export default function LoyaltyPage() {
  const { balance, bonusClaimed } = useClinic();
  return (
    <Chrome active="profile" fab="none">
      <main className="px-container-margin pt-6">
        <p className="font-label-md mb-2 tracking-[0.2em] text-secondary uppercase">Клуб</p>
        <h1 className="font-headline-lg text-headline-lg-mobile mb-4">Система лояльности</h1>
        <div className="gold-card-gradient mb-8 rounded-xl p-6 text-on-secondary-fixed">
          <p className="font-label-md uppercase opacity-80">Бонусный баланс</p>
          <p className="font-headline-xl text-headline-xl">{balance.toLocaleString("ru-RU")} ₽</p>
          <p className="mt-2 font-label-md uppercase">Платиновый статус{bonusClaimed ? " · бонус 3 000 ₽ начислен" : ""}</p>
        </div>
        <h2 className="font-headline-sm mb-3">Правила</h2>
        <ul className="mb-8 space-y-3">
          {rules.map((rule) => (
            <li key={rule} className="rounded-xl bg-white px-4 py-3">
              {rule}
            </li>
          ))}
        </ul>
        <h2 className="font-headline-sm mb-3">Движение бонусов</h2>
        <ul className="divide-y divide-outline-variant/40 rounded-xl bg-white">
          {loyaltyLedger.map((row) => (
            <li key={row.title} className="flex items-center justify-between px-4 py-3">
              <span>
                <span className="block font-medium">{row.title}</span>
                <span className="text-xs text-outline">{row.date}</span>
              </span>
              <span className="text-primary">{row.points}</span>
            </li>
          ))}
        </ul>
        <Link href="/prices" className="mt-6 block text-center text-primary underline">
          На что списать: прайс
        </Link>
      </main>
    </Chrome>
  );
}
