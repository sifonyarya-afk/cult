"use client";

import { useState } from "react";
import { Chrome } from "@/components/clinic/chrome";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

export default function TransferPage() {
  const [from, setFrom] = useState("");
  const [when, setWhen] = useState("");
  const [time, setTime] = useState("10:00");
  const [note, setNote] = useState("");
  const [error, setError] = useState("");
  const [done, setDone] = useState(false);

  return (
    <Chrome active="profile" fab="none">
      <main className="px-container-margin pt-6">
        <p className="font-label-md mb-2 tracking-[0.2em] text-primary uppercase">Консьерж</p>
        <h1 className="font-headline-lg text-headline-lg-mobile mb-2">Заказ трансфера</h1>
        <p className="mb-6 text-on-surface-variant">Такси до клиники и обратно. Водитель встретит у подъезда.</p>
        {done ? (
          <div className="rounded-xl bg-white p-6 luxury-shadow">
            <h2 className="font-headline-sm mb-2">Трансфер заказан</h2>
            <p className="text-on-surface-variant">
              Подача {when} в {time}, адрес: {from}. Администратор подтвердит машину в чате.
            </p>
          </div>
        ) : (
          <form
            className="space-y-4"
            onSubmit={(event) => {
              event.preventDefault();
              if (from.trim().length < 5 || !when) {
                setError("Укажите адрес подачи и дату.");
                return;
              }
              setError("");
              setDone(true);
            }}
          >
            <label className="block text-sm">
              Откуда забрать
              <Input value={from} onChange={(event) => setFrom(event.target.value)} placeholder="Улица, дом" className="mt-1 h-11" />
            </label>
            <label className="block text-sm">
              Куда
              <Input value="CULT Clinic, ресепшен" readOnly className="mt-1 h-11" />
            </label>
            <label className="block text-sm">
              Дата
              <Input type="date" value={when} onChange={(event) => setWhen(event.target.value)} className="mt-1 h-11" />
            </label>
            <label className="block text-sm">
              Время
              <select value={time} onChange={(event) => setTime(event.target.value)} className="mt-1 h-11 w-full rounded-lg border border-input bg-transparent px-3">
                {["09:00", "10:00", "12:30", "15:00", "18:00"].map((item) => (
                  <option key={item}>{item}</option>
                ))}
              </select>
            </label>
            <label className="block text-sm">
              Комментарий
              <Input value={note} onChange={(event) => setNote(event.target.value)} placeholder="Детское кресло, багаж" className="mt-1 h-11" />
            </label>
            {error ? <p className="text-sm text-error">{error}</p> : null}
            <Button type="submit" className="h-12 w-full bg-on-background text-white tracking-[0.14em] uppercase">
              Заказать такси
            </Button>
          </form>
        )}
      </main>
    </Chrome>
  );
}
