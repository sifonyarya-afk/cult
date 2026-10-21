"use client";

import { useState } from "react";
import { Chrome } from "@/components/clinic/chrome";
import { certificateDesigns, certificateNominals } from "@/lib/catalog";
import { useClinic } from "@/components/clinic/providers";
import { Button } from "@/components/ui/button";

export default function CertificatesPage() {
  const { gifts, buyGift, balance, spendBonus } = useClinic();
  const [nominal, setNominal] = useState(certificateNominals[1]);
  const [design, setDesign] = useState(certificateDesigns[0].id);
  const [pay, setPay] = useState<"card" | "bonus">("card");
  const [error, setError] = useState("");
  const [code, setCode] = useState("");
  const look = certificateDesigns.find((item) => item.id === design) ?? certificateDesigns[0];

  return (
    <Chrome active="profile" fab="none">
      <main className="px-container-margin pt-6">
        <p className="font-label-md mb-2 tracking-[0.2em] text-primary uppercase">Подарок</p>
        <h1 className="font-headline-lg text-headline-lg-mobile mb-4">Сертификаты</h1>
        <div className={`mb-6 rounded-xl p-6 ${look.className}`}>
          <p className="text-xs tracking-[0.25em] uppercase">CULT</p>
          <p className="font-headline-md mt-6">{nominal.toLocaleString("ru-RU")} ₽</p>
          <p className="mt-1 text-sm opacity-80">{look.name}</p>
        </div>
        <p className="mb-2 text-sm">Номинал</p>
        <div className="mb-4 flex gap-2">
          {certificateNominals.map((value) => (
            <button
              key={value}
              className={`rounded-full px-4 py-2 text-sm ${nominal === value ? "bg-on-background text-white" : "bg-surface-container"}`}
              onClick={() => setNominal(value)}
            >
              {value.toLocaleString("ru-RU")}
            </button>
          ))}
        </div>
        <p className="mb-2 text-sm">Дизайн</p>
        <div className="mb-4 flex gap-2">
          {certificateDesigns.map((item) => (
            <button
              key={item.id}
              className={`rounded-full px-4 py-2 text-sm ${design === item.id ? "bg-primary text-white" : "bg-surface-container"}`}
              onClick={() => setDesign(item.id)}
            >
              {item.name}
            </button>
          ))}
        </div>
        <fieldset className="mb-4 space-y-2 text-sm">
          <label className="flex gap-2">
            <input type="radio" checked={pay === "card"} onChange={() => setPay("card")} /> Картой
          </label>
          <label className="flex gap-2">
            <input type="radio" checked={pay === "bonus"} onChange={() => setPay("bonus")} /> Бонусами, баланс {balance.toLocaleString("ru-RU")} ₽
          </label>
        </fieldset>
        {error ? <p className="mb-3 text-sm text-error">{error}</p> : null}
        {code ? <p className="mb-3 rounded-xl bg-secondary-container px-4 py-3">Код отправлен в WhatsApp и на почту: {code}</p> : null}
        <Button
          className="h-12 w-full bg-on-background text-white"
          onClick={() => {
            if (pay === "bonus" && !spendBonus(nominal)) {
              setError("Бонусов не хватает на этот номинал.");
              return;
            }
            setError("");
            setCode(buyGift(nominal, look.name));
          }}
        >
          Оплатить сертификат
        </Button>
        <h2 className="font-headline-sm mt-10 mb-3">Уже купленные</h2>
        {gifts.length === 0 ? (
          <p className="text-on-surface-variant">Активных сертификатов нет.</p>
        ) : (
          <ul className="space-y-3">
            {gifts.map((gift) => (
              <li key={gift.id} className="rounded-xl bg-white p-4">
                <p className="font-medium">
                  {gift.nominal.toLocaleString("ru-RU")} ₽ · {gift.design}
                </p>
                <p className="text-sm text-primary">{gift.code}</p>
                <p className="text-xs uppercase text-outline">{gift.status === "active" ? "Активен" : "Использован"}</p>
              </li>
            ))}
          </ul>
        )}
      </main>
    </Chrome>
  );
}
